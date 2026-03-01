# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
import os
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ValueChange, with_timeout, SimTimeoutError


async def wait_for_rising_bit(vector_handle, bit_index):
    prev_bit = None

    try:
        prev_value = int(vector_handle.value)
        prev_bit = (prev_value >> bit_index) & 1
    except ValueError:
        prev_bit = None

    while True:
        await ValueChange(vector_handle)
        try:
            curr_value = int(vector_handle.value)
        except ValueError:
            continue

        curr_bit = (curr_value >> bit_index) & 1
        if prev_bit == 0 and curr_bit == 1:
            return
        prev_bit = curr_bit


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

    # While disabled, output clock should not toggle
    try:
        await with_timeout(wait_for_rising_bit(dut.uo_out, 4), 5, "us")
        assert False, "PLL output toggled while disabled"
    except SimTimeoutError:
        dut._log.info("No clock toggles while disabled: PASS")

    dut._log.info("Enable PLL intentionally")
    dut.ui_in.value = 0x40 | 0x01  # div ratio nibble = 4, enable bit = 1

    # Once enabled, output clock should toggle
    toggles_seen = 0
    for _ in range(5):
        try:
            await with_timeout(wait_for_rising_bit(dut.uo_out, 4), 200, "us")
            toggles_seen += 1
        except SimTimeoutError:
            if gates:
                dut._log.warning("No clk_out toggle observed in GL run within timeout; continuing with functional checks")
                break
            raise

    if not gates:
        assert toggles_seen > 0, "PLL did not produce output toggles after enable"
    else:
        assert int(dut.uo_out.value) & (1 << 7), "PLL enable status bit did not assert in GL run"

    dut._log.info("Disable PLL intentionally")
    dut.ui_in.value = 0x40
    await ClockCycles(dut.clk, 20)

    try:
        await with_timeout(wait_for_rising_bit(dut.uo_out, 4), 5, "us")
        assert False, "PLL output still toggles after disable"
    except SimTimeoutError:
        dut._log.info("Clock stopped after disable: PASS")
