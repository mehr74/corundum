import logging
import os
import subprocess
from random import random

import cocotb
import cocotb_test.simulator
import pytest
from cocotb.clock import Clock
from cocotb.regression import TestFactory
from cocotb.triggers import RisingEdge

from cocotbext.axi import AxiBus, AxiStreamSource, AxiStreamBus, AxiStreamSink, AxiLiteBus, AxiLiteMaster


class TB(object):
    def __init__(self, dut):
        self.dut = dut
        
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        
        cocotb.fork(Clock(dut.s_axil_clk, 10, units="ns").start())
        cocotb.fork(Clock(dut.qsfp0_tx_clk, 10, units="ns").start())
        cocotb.fork(Clock(dut.qsfp0_rx_clk, 10, units="ns").start())
        cocotb.fork(Clock(dut.qsfp1_tx_clk, 10, units="ns").start())
        cocotb.fork(Clock(dut.qsfp1_rx_clk, 10, units="ns").start())

        # tx from cmac_pad (originally fpga_core)
        self.qsfp0_tx_s_axis = AxiStreamSource(
            AxiStreamBus.from_prefix(dut, "qsfp0_tx_s_axis"), 
            dut.qsfp0_tx_clk, 
            dut.qsfp0_tx_rst
        )

        # rx to fpag_core
        self.qsfp0_rx_m_axis = AxiStreamSink(
            AxiStreamBus.from_prefix(dut, "qsfp0_rx_m_axis"),
            dut.qsfp0_rx_clk,
            dut.qsfp0_rx_rst
        )

        # tx to cmac
        self.qsfp0_tx_m_axis = AxiStreamSink(
            AxiStreamBus.from_prefix(dut, "qsfp0_tx_m_axis"),
            dut.qsfp0_tx_clk,
            dut.qsfp0_tx_rst
        )

        # rx from cmac
        self.qsfp0_rx_s_axis = AxiStreamSource(
            AxiStreamBus.from_prefix(dut, "qsfp0_rx_m_axis"),
            dut.qsfp0_rx_clk,
            dut.qsfp0_rx_rst
        )

        # tx from cmac_pad (originally fpga_core)
        self.qsfp1_tx_s_axis = AxiStreamSource(
            AxiStreamBus.from_prefix(dut, "qsfp1_tx_s_axis"),
            dut.qsfp1_tx_clk,
            dut.qsfp1_tx_rst
        )

        # rx to fpag_core
        self.qsfp1_rx_m_axis = AxiStreamSink(
            AxiStreamBus.from_prefix(dut, "qsfp1_rx_m_axis"),
            dut.qsfp1_rx_clk,
            dut.qsfp1_rx_rst
        )

        # tx to cmac
        self.qsfp1_tx_m_axis = AxiStreamSink(
            AxiStreamBus.from_prefix(dut, "qsfp0_tx_m_axis"),
            dut.qsfp1_tx_clk,
            dut.qsfp1_tx_rst
        )

        # rx from cmac
        self.qsfp1_rx_s_axis = AxiStreamSource(
            AxiStreamBus.from_prefix(dut, "qsfp1_rx_m_axis"),
            dut.qsfp1_rx_clk,
            dut.qsfp1_rx_rst
        )

        s_axil_count = len(dut.axil_kugelblitz_offload_inst.s_axil_awvalid)
        self.log.info("len : %d", s_axil_count)

        self.axil_master = [AxiLiteMaster(
            AxiLiteBus.from_prefix(dut, f"s{k:02d}_axil"),
            dut.s_axil_clk,
            dut.s_axil_rst
        ) for k in range(1)]

    async def cycle_reset(self):
        self.dut.s_axil_rst.setimmediatevalue(0)
        await RisingEdge(self.dut.s_axil_clk)
        await RisingEdge(self.dut.s_axil_clk)
        self.dut.s_axil_rst <= 1
        await RisingEdge(self.dut.s_axil_clk)
        await RisingEdge(self.dut.s_axil_clk)
        self.dut.s_axil_rst <= 0
        await RisingEdge(self.dut.s_axil_clk)
        await RisingEdge(self.dut.s_axil_clk)

async def run_test_kugelblitz_axil_write(dut):
    tb = TB(dut)

    byte_lanes = tb.axil_master.write_if.byte_lanes
    tb.log.info("axil byte lanes : %d", byte_lanes)
    await tb.cycle_reset()

    for length in range(1, byte_lanes+1):
        tb.log.info("length %d", length)
        test_kg_address_valid = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_address = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_data_valid = bytearray([random.randint(0, 255) for x in range(length)])
        test_kg_data = bytearray([random.randint(0, 255) for x in range(length)])
        await tb.axil_master[0].write(0, test_kg_address_valid)
        await tb.axil_master[0].write(4, test_kg_address)
        await tb.axil_master[0].write(8, test_kg_data_valid)
        await tb.axil_master[0].write(12, test_kg_data)

        test_kg_address_valid_check = await tb.axil_master[0].read(0, 4)
        test_kg_address_check = await tb.axil_master[0].read(4, 4)
        test_kg_data_valid_check = await tb.axil_master[0].read(8, 4)
        test_kg_data_check = await tb.axil_master[0].read(12, 4)



        assert tb.dut.kg_address_valid == int.from_bytes(test_kg_address_valid, "little")
        assert tb.dut.kg_address == int.from_bytes(test_kg_address, "little")
        assert tb.dut.kg_data_valid == int.from_bytes(test_kg_data_valid, "little")
        assert tb.dut.kg_data == int.from_bytes(test_kg_data, "little")

if cocotb.SIM_NAME:
    for test in [run_test_kugelblitz_axil_write]:
        factory = TestFactory(test)
        factory.generate_tests()

    factory.generate_tests()

tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))

@pytest.mark.parametrize("data_width", [32])
@pytest.mark.parametrize("axil_count", [2, 4])
def test_kugelblitz_offload(request, data_width, axil_count):
    dut = "kugelblitz_offload"
    wrapper = f"{dut}_wrap_{axil_count}"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = wrapper

    wrapper_file = os.path.join(tests_dir, f"{wrapper}.v")
    if not os.path.exists(wrapper_file):
        subprocess.Popen(
            [os.path.join(rtl_dir, f"{dut}_wrap.py"), "-p", f"{axil_count}"],
            cwd=tests_dir
        ).wait()

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.v"),
        os.path.join(rtl_dir, f"axil_kg_regfile.v")
    ]

    parameters = {}

    parameters['AXIL_DATA_WIDTH'] = data_width
    parameters['AXIL_ADDR_WIDTH'] = 32
    parameters['AXIL_STRB_WIDTH'] = parameters['AXIL_DATA_WIDTH'] // 8

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