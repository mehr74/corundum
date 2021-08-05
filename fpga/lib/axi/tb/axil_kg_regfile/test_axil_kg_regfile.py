import logging
import os
import random

import cocotb
import cocotb_test.simulator
import pytest
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge
from cocotbext.axi import AxiLiteMaster, AxiLiteBus


class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.fork(Clock(dut.clk, 10, units="ns").start())

        self.axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axil"), dut.clk, dut.rst)

    def set_idle_generator(self, generator=None):
        if generator:
            self.axil_master.write_if.aw_channel.set_pause_generator(generator())
            self.axil_master.write_if.w_channel.set_pause_generator(generator())
            self.axil_master.read_if.ar_channel.set_pause_generator(generator())
            self.axil_master.write_if.b_channel.set_pause_generator(generator())
            self.axil_master.read_if.r_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.axil_master.write_if.b_channel.set_pause_generator(generator())
            self.axil_master.read_if.r_channel.set_pause_generator(generator())
            self.axil_ram.write_if.aw_channel.set_pause_generator(generator())
            self.axil_ram.write_if.w_channel.set_pause_generator(generator())
            self.axil_ram.read_if.ar_channel.set_pause_generator(generator())

    async def cycle_reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst <= 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst <= 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)


async def run_test_write(dut, idle_inserter=None, backpressure_inserter=None):
    tb = TB(dut)

    byte_lanes = tb.axil_master.write_if.byte_lanes
    tb.log.info("byte_lanes : %d", byte_lanes)
    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for length in range(1, byte_lanes+1):
        tb.log.info("length %d", length)
        test_kg_address_valid = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_address = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_data_valid = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_data = bytearray([random.randint(0, 255) for x in range(length)])
        await tb.axil_master.write(0, test_kg_address_valid)
        await tb.axil_master.write(4, test_kg_address)
        await tb.axil_master.write(8, test_kg_data_valid)
        await tb.axil_master.write(12, test_kg_data)
        tb.log.info("kg_address_valid (w: %d ,a:%d)",
                    int.from_bytes(test_kg_address_valid, "little"),
                    tb.dut.kg_address_valid)
        tb.log.info("kg_address       (w: %d ,a:%d)",
                    int.from_bytes(test_kg_address, "little"),
                    tb.dut.kg_address)
        tb.log.info("kg_data_valid    (w: %d ,a:%d)",
                    int.from_bytes(test_kg_data_valid, "little"),
                    tb.dut.kg_data_valid)
        tb.log.info("kg_data          (w: %d ,a:%d)",
                    int.from_bytes(test_kg_data, "little"),
                    tb.dut.kg_data)
        assert tb.dut.kg_address_valid == int.from_bytes(test_kg_address_valid, "little")
        assert tb.dut.kg_address == int.from_bytes(test_kg_address, "little")
        assert tb.dut.kg_data_valid == int.from_bytes(test_kg_data_valid, "little")
        assert tb.dut.kg_data == int.from_bytes(test_kg_data, "little")


async def run_test_read(dut, idle_inserter=None, backpressure_inserter=None):
    tb = TB(dut)

    byte_lanes = tb.axil_master.write_if.byte_lanes
    tb.log.info("byte_lanes : %d", byte_lanes)
    await tb.cycle_reset()

    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)

    for length in range(1, byte_lanes+1):
        tb.log.info("length %d", length)
        test_kg_address_valid = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_address = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_data_valid = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_data = bytearray([random.randint(0, 255) for x in range(length)])
        await tb.axil_master.write(0, test_kg_address_valid)
        await tb.axil_master.write(4, test_kg_address)
        await tb.axil_master.write(8, test_kg_data_valid)
        await tb.axil_master.write(12, test_kg_data)

        test_kg_address_valid_check = await tb.axil_master.read(0, 4)
        test_kg_address_check = await tb.axil_master.read(4, 4)
        test_kg_data_valid_check = await tb.axil_master.read(8, 4)
        test_kg_data_check = await tb.axil_master.read(12, 4)

        tb.log.info("kg_address_valid (w: %d, r: %d)",
                    int.from_bytes(test_kg_address_valid, "little"),
                    int.from_bytes(test_kg_address_valid_check.data, "little"))
        tb.log.info("kg_address       (w: %d, r: %d)",
                    int.from_bytes(test_kg_address, "little"),
                    int.from_bytes(test_kg_address_check.data, "little"))
        tb.log.info("kg_data_valid    (w: %d, r: %d)",
                    int.from_bytes(test_kg_data_valid, "little"),
                    int.from_bytes(test_kg_data_valid_check.data, "little"))
        tb.log.info("kg_data          (w: %d, r: %d)",
                    int.from_bytes(test_kg_data, "little"),
                    int.from_bytes(test_kg_data_check.data, "little"))

        assert int.from_bytes(test_kg_address_valid_check.data, "little") == \
               int.from_bytes(test_kg_address_valid, "little")
        assert int.from_bytes(test_kg_address_check.data, "little") == int.from_bytes(test_kg_address, "little")
        assert int.from_bytes(test_kg_data_valid_check.data, "little") == int.from_bytes(test_kg_data_valid, "little")
        assert int.from_bytes(test_kg_data_check.data, "little") == int.from_bytes(test_kg_data, "little")


if cocotb.SIM_NAME:
    for test in [run_test_write, run_test_read]:
        factory = TestFactory(test)
        factory.generate_tests()

    factory.generate_tests()

# cocotb-test
tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))


@pytest.mark.parametrize("data_width", [32])
def test_axil_kg_regfile(request, data_width):
    dut = "axil_kg_regfile"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.v")
    ]

    parameters = {}

    parameters['DATA_WIDTH'] = data_width
    parameters['ADDR_WIDTH'] = 32
    parameters['STRB_WIDTH'] = parameters['DATA_WIDTH'] // 8

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build",
                             request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env
    )
