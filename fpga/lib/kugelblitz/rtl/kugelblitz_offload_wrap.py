#!/usr/bin/env python
"""
Generates an AXI lite interconnect wrapper with the specified number of ports
"""

import argparse
from jinja2 import Template


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip())
    parser.add_argument('-p', '--ports',  type=int, default=[2], nargs='+', help="number of ports")
    parser.add_argument('-n', '--name',   type=str, help="module name")
    parser.add_argument('-o', '--output', type=str, help="output file name")

    args = parser.parse_args()

    try:
        generate(**args.__dict__)
    except IOError as ex:
        print(ex)
        exit(1)


def generate(ports=2, name=None, output=None):
    if type(ports) is int:
        m = ports
    elif len(ports) == 1:
        m = ports[0]

    if name is None:
        name = "kugelblitz_offload_wrap_{0}".format(m)

    if output is None:
        output = name + ".v"

    print("Generating {0} port AXI lite kugelblitz wrapper {1}...".format(m, name))

    cm = (m-1).bit_length()

    t = Template(u"""/*

*/

// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * kugelblitz offload {{n}} (wrapper)
 */
module {{name}} #
(
    parameter AXIS_ETH_DATA_WIDTH = 512,
    parameter AXIS_ETH_KEEP_WIDTH = (AXIS_ETH_DATA_WIDTH/8),
    parameter USER_WIDTH = 1,
    parameter AXIL_DATA_WIDTH = 32,
    
    parameter AXIL_STRB_WIDTH = (AXIL_DATA_WIDTH/8),
    
    parameter AXIL_ADDR_WIDTH = 32
)
(
    input wire                                                  s_axil_clk,
    input wire                                                  s_axil_rst,
    
{%- for p in range(m) %}
    input wire                                                  qsfp{{'%01d'%p}}_tx_clk,
    input wire                                                  qsfp{{'%01d'%p}}_tx_rst,
    input wire                                                  qsfp{{'%01d'%p}}_rx_clk,
    input wire                                                  qsfp{{'%01d'%p}}_rx_rst,

    // tx from cmac_pad (originally from fpga core)
    input  wire [AXIS_ETH_DATA_WIDTH-1:0]                                s_qsfp{{'%01d'%p}}_tx_axis_tdata,
    input  wire [AXIS_ETH_KEEP_WIDTH-1:0]                                s_qsfp{{'%01d'%p}}_tx_axis_tkeep,
    input  wire                                                 s_qsfp{{'%01d'%p}}_tx_axis_tvalid,
    output wire                                                 s_qsfp{{'%01d'%p}}_tx_axis_tready,
    input  wire                                                 s_qsfp{{'%01d'%p}}_tx_axis_tlast,
    input  wire [USER_WIDTH-1:0]                                s_qsfp{{'%01d'%p}}_tx_axis_tuser,

    // rx to fpga core
    output wire [AXIS_ETH_DATA_WIDTH-1:0]                                m_qsfp{{'%01d'%p}}_rx_axis_tdata,
    output wire [AXIS_ETH_KEEP_WIDTH-1:0]                                m_qsfp{{'%01d'%p}}_rx_axis_tkeep,
    output wire                                                 m_qsfp{{'%01d'%p}}_rx_axis_tvalid,
    output wire                                                 m_qsfp{{'%01d'%p}}_rx_axis_tlast,
    output wire [81-1:0]                                m_qsfp{{'%01d'%p}}_rx_axis_tuser,

    // tx to cmac
    output wire [AXIS_ETH_DATA_WIDTH-1:0]                                m_qsfp{{'%01d'%p}}_tx_axis_tdata,
    output wire [AXIS_ETH_KEEP_WIDTH-1:0]                                m_qsfp{{'%01d'%p}}_tx_axis_tkeep,
    output wire                                                 m_qsfp{{'%01d'%p}}_tx_axis_tvalid,
    input  wire                                                 m_qsfp{{'%01d'%p}}_tx_axis_tready,
    output wire                                                 m_qsfp{{'%01d'%p}}_tx_axis_tlast,
    output wire [USER_WIDTH-1:0]                                m_qsfp{{'%01d'%p}}_tx_axis_tuser,

    // rx from cmac
    input  wire [AXIS_ETH_DATA_WIDTH-1:0]                                s_qsfp{{'%01d'%p}}_rx_axis_tdata,
    input  wire [AXIS_ETH_KEEP_WIDTH-1:0]                                s_qsfp{{'%01d'%p}}_rx_axis_tkeep,
    input  wire                                                 s_qsfp{{'%01d'%p}}_rx_axis_tvalid,
    input  wire                                                 s_qsfp{{'%01d'%p}}_rx_axis_tlast,
    input  wire [81-1:0]                                s_qsfp{{'%01d'%p}}_rx_axis_tuser,

    input  wire [AXIL_ADDR_WIDTH-1:0]                           s{{'%02d'%p}}_axil_awaddr,
    input  wire [2:0]                                           s{{'%02d'%p}}_axil_awprot,
    input  wire                                                 s{{'%02d'%p}}_axil_awvalid,
    output wire                                                 s{{'%02d'%p}}_axil_awready,
    input  wire [AXIL_DATA_WIDTH-1:0]                           s{{'%02d'%p}}_axil_wdata,
    input  wire [AXIL_STRB_WIDTH-1:0]                           s{{'%02d'%p}}_axil_wstrb,
    input  wire                                                 s{{'%02d'%p}}_axil_wvalid,
    output wire                                                 s{{'%02d'%p}}_axil_wready,
    output wire [1:0]                                           s{{'%02d'%p}}_axil_bresp,
    output wire                                                 s{{'%02d'%p}}_axil_bvalid,
    input  wire                                                 s{{'%02d'%p}}_axil_bready,
    input  wire [AXIL_ADDR_WIDTH-1:0]                           s{{'%02d'%p}}_axil_araddr,
    input  wire [2:0]                                           s{{'%02d'%p}}_axil_arprot,
    input  wire                                                 s{{'%02d'%p}}_axil_arvalid,
    output wire                                                 s{{'%02d'%p}}_axil_arready,
    output wire [AXIL_DATA_WIDTH-1:0]                           s{{'%02d'%p}}_axil_rdata,
    output wire [1:0]                                           s{{'%02d'%p}}_axil_rresp,
    output wire                                                 s{{'%02d'%p}}_axil_rvalid,
    input  wire                                                 s{{'%02d'%p}}_axil_rready{% if not loop.last %}, {% endif %}
{% endfor %}
);

    localparam PORT_COUNT = {{m}};

    kugelblitz_offload #(
        .AXIS_ETH_DATA_WIDTH(AXIS_ETH_DATA_WIDTH),
        .AXIS_ETH_KEEP_WIDTH(AXIS_ETH_KEEP_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
        .AXIL_STRB_WIDTH(AXIL_STRB_WIDTH),
        .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
        .PORT_COUNT(PORT_COUNT)
    )
    kugelblitz_offload_inst (
            .kg_axil_clk(s_axil_clk),
            .kg_axil_rst(s_axil_rst),
            .kg_port_tx_clk          ( { {% for p in range(m-1,-1,-1) %} qsfp{{'%01d'%p}}_tx_clk{% if not loop.last %}, {% endif %}{% endfor %} }                                 ),
            .kg_port_tx_rst          ( { {% for p in range(m-1,-1,-1) %} qsfp{{'%01d'%p}}_tx_rst{% if not loop.last %}, {% endif %}{% endfor %} }                              ),
            .kg_port_rx_clk          ( { {% for p in range(m-1,-1,-1) %} qsfp{{'%01d'%p}}_rx_clk{% if not loop.last %}, {% endif %}{% endfor %} }                              ),
            .kg_port_rx_rst          ( { {% for p in range(m-1,-1,-1) %} qsfp{{'%01d'%p}}_rx_rst{% if not loop.last %}, {% endif %}{% endfor %} }                              ),
            
            .kg_s_axil_awaddr({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_awaddr{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_awprot({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_awprot{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_awvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_awvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_awready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_awready{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_wdata({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_wdata{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_wstrb({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_wstrb{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_wvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_wvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_wready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_wready{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_bresp({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_bresp{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_bvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_bvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_bready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_bready{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_araddr({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_araddr{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_arprot({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_arprot{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_arvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_arvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_arready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_arready{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_rdata({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_rdata{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_rresp({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_rresp{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_rvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_rvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
            .kg_s_axil_rready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_rready{% if not loop.last %}, {% endif %}{% endfor %} }),
            
            // port from IO to kugelblitz
            .kg_m_port_tx_axis_tdata   ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_tx_axis_tdata{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_m_port_tx_axis_tkeep   ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_tx_axis_tkeep{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_m_port_tx_axis_tvalid  ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_tx_axis_tvalid{% if not loop.last %}, {% endif %}{% endfor %} }                      ),
            .kg_m_port_tx_axis_tready  ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_tx_axis_tready{% if not loop.last %}, {% endif %}{% endfor %} }                      ),
            .kg_m_port_tx_axis_tlast   ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_tx_axis_tlast{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_m_port_tx_axis_tuser   ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_tx_axis_tuser{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_m_port_tx_ptp_ts       ( ),
            .kg_m_port_tx_ptp_ts_valid ( ),

            // port from IO to kugelblitz
            .kg_s_port_rx_axis_tdata   ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_rx_axis_tdata{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_s_port_rx_axis_tkeep   ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_rx_axis_tkeep{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_s_port_rx_axis_tvalid  ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_rx_axis_tvalid{% if not loop.last %}, {% endif %}{% endfor %} }                      ),
            .kg_s_port_rx_axis_tlast   ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_rx_axis_tlast{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_s_port_rx_axis_tuser   ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_rx_axis_tuser{% if not loop.last %}, {% endif %}{% endfor %} }                       ),

            // port from kugelblitz to corundum
            .kg_s_port_tx_axis_tdata   ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_tx_axis_tdata{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_s_port_tx_axis_tkeep   ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_tx_axis_tkeep{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_s_port_tx_axis_tvalid  ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_tx_axis_tvalid{% if not loop.last %}, {% endif %}{% endfor %} }                      ),
            .kg_s_port_tx_axis_tready  ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_tx_axis_tready{% if not loop.last %}, {% endif %}{% endfor %} }                      ),
            .kg_s_port_tx_axis_tlast   ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_tx_axis_tlast{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_s_port_tx_axis_tuser   ( { {% for p in range(m-1,-1,-1) %} s_qsfp{{'%01d'%p}}_tx_axis_tuser{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_s_port_tx_ptp_ts       ( ),
            .kg_s_port_tx_ptp_ts_valid ( ),

            // port from kugelblitz to corundum
            .kg_m_port_rx_axis_tdata   ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_rx_axis_tdata{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_m_port_rx_axis_tkeep   ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_rx_axis_tkeep{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_m_port_rx_axis_tvalid  ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_rx_axis_tvalid{% if not loop.last %}, {% endif %}{% endfor %} }                      ),
            .kg_m_port_rx_axis_tlast   ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_rx_axis_tlast{% if not loop.last %}, {% endif %}{% endfor %} }                       ),
            .kg_m_port_rx_axis_tuser   ( { {% for p in range(m-1,-1,-1) %} m_qsfp{{'%01d'%p}}_rx_axis_tuse{% if not loop.last %}, {% endif %}{% endfor %} }                        )
    );

endmodule

""")

    print(f"Writing file '{output}'...")

    with open(output, 'w') as f:
        f.write(t.render(
            m=m,
            cm=cm,
            name=name
        ))
        f.flush()

    print("Done")


if __name__ == "__main__":
    main()
