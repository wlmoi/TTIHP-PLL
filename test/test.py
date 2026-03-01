# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from cocotb.result import SimTimeoutError


@cocotb.test()
async def test_project(dut):
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
        await with_timeout(RisingEdge(dut.uo_out[4]), 5, "us")
        assert False, "PLL output toggled while disabled"
    except SimTimeoutError:
        dut._log.info("No clock toggles while disabled: PASS")

    dut._log.info("Enable PLL intentionally")
    dut.ui_in.value = 0x40 | 0x01  # div ratio nibble = 4, enable bit = 1

    # Once enabled, output clock should toggle
    for _ in range(5):
        await with_timeout(RisingEdge(dut.uo_out[4]), 200, "us")

    dut._log.info("Disable PLL intentionally")
    dut.ui_in.value = 0x40
    await ClockCycles(dut.clk, 20)

    try:
        await with_timeout(RisingEdge(dut.uo_out[4]), 5, "us")
        assert False, "PLL output still toggles after disable"
    except SimTimeoutError:
        dut._log.info("Clock stopped after disable: PASS")
