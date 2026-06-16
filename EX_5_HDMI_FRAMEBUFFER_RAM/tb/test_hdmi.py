import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def test_video(dut):

    clock = Clock(dut.clk_27MHz, 37, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0

    for _ in range(10):
        await RisingEdge(dut.clk_27MHz)

    dut.rst_n.value = 1

    for _ in range(1000):
        await RisingEdge(dut.clk_27MHz)

    print("SIMULATION OK")