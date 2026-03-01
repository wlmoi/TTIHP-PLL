# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
import os
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


def read_bit(vector_handle, bit_index):
    try:
        value = int(vector_handle.value)
    except ValueError:
        return None
    return (value >> bit_index) & 1


async def detect_rising_bit_within_cycles(clk_handle, vector_handle, bit_index, cycles):
    prev_bit = read_bit(vector_handle, bit_index)
    for _ in range(cycles):
        await RisingEdge(clk_handle)
        curr_bit = read_bit(vector_handle, bit_index)
        if prev_bit == 0 and curr_bit == 1:
            return True
        prev_bit = curr_bit
    return False


def is_gate_level_run():
    value = os.getenv("GATES", "").strip().lower()
    return value in ("yes", "1", "true", "on")


@cocotb.test()
async def test_project(dut):
    gates = is_gate_level_run()
    dut._log.info("Start PLL enable/disable behavior test")

    # 13.56MHz reference clock
    clock = Clock(dut.clk, 73.746, unit="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Apply reset and keep PLL disabled")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 20)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 20)

    # While disabled, output clock should not toggle (~5us ~= 68 ref cycles)
    disabled_rise = await detect_rising_bit_within_cycles(dut.clk, dut.uo_out, 4, 80)
    assert not disabled_rise, "PLL output toggled while disabled"
    dut._log.info("No clock toggles while disabled: PASS")

    dut._log.info("Enable PLL intentionally")
    dut.ui_in.value = 0x40 | 0x01  # div ratio nibble = 4, enable bit = 1

    # Once enabled, output clock should toggle in RTL; GL may be non-oscillating
    # under functional netlist simulation. Use ~220us window to match prior behavior.
    enabled_rise = await detect_rising_bit_within_cycles(dut.clk, dut.uo_out, 4, 3000)

    if gates:
        if not enabled_rise:
            dut._log.warning("No clk_out toggle observed in GL run within window; continuing with enable-path check")
        assert int(dut.uo_out.value) & (1 << 7), "PLL enable status bit did not assert in GL run"
    else:
        assert enabled_rise, "PLL did not produce output toggles after enable"

    dut._log.info("Disable PLL intentionally")
    dut.ui_in.value = 0x40
    await ClockCycles(dut.clk, 20)

    disabled_again_rise = await detect_rising_bit_within_cycles(dut.clk, dut.uo_out, 4, 80)
    assert not disabled_again_rise, "PLL output still toggles after disable"
    dut._log.info("Clock stopped after disable: PASS")
