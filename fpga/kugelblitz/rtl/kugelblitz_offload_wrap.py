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
    parameter DATA_WIDTH = 512,
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    parameter USER_WIDTH = 1,
    parameter AXIL_DATA_WIDTH = 32,
    
    parameter AXIL_STRB_WIDTH = (AXIL_DATA_WIDTH/8),
    
    parameter AXIL_ADDR_WIDTH = 32,

    parameter AXIL_COUNT = 2
)
(
    input wire                    s_axil_clk,
    input wire                    s_axil_rst,
    input wire                    qsfp0_tx_clk,
    input wire                    qsfp0_tx_rst,
    input wire                    qsfp0_rx_clk,
    input wire                    qsfp0_rx_rst,
    input wire                    qsfp1_tx_clk,
    input wire                    qsfp1_tx_rst,
    input wire                    qsfp1_rx_clk,
    input wire                    qsfp1_rx_rst,
    
    // tx from cmac_pad (originally from fpga core)
    input  wire [DATA_WIDTH-1:0]  qsfp0_tx_s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  qsfp0_tx_s_axis_tkeep,
    input  wire                   qsfp0_tx_s_axis_tvalid,
    output wire                   qsfp0_tx_s_axis_tready,
    input  wire                   qsfp0_tx_s_axis_tlast,
    input  wire [USER_WIDTH-1:0]  qsfp0_tx_s_axis_tuser,

    // rx to fpga core
    output wire [DATA_WIDTH-1:0]  qsfp0_rx_m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  qsfp0_rx_m_axis_tkeep,
    output wire                   qsfp0_rx_m_axis_tvalid,
    output wire                   qsfp0_rx_m_axis_tlast,
    output wire [USER_WIDTH-1:0]  qsfp0_rx_m_axis_tuser,

    // tx to cmac
    output wire [DATA_WIDTH-1:0]  qsfp0_tx_m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  qsfp0_tx_m_axis_tkeep,
    output wire                   qsfp0_tx_m_axis_tvalid,
    input  wire                   qsfp0_tx_m_axis_tready,
    output wire                   qsfp0_tx_m_axis_tlast,
    output wire [USER_WIDTH-1:0]  qsfp0_tx_m_axis_tuser,

    // rx from cmac
    input  wire [DATA_WIDTH-1:0]  qsfp0_rx_s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  qsfp0_rx_s_axis_tkeep,
    input  wire                   qsfp0_rx_s_axis_tvalid,
    input  wire                   qsfp0_rx_s_axis_tlast,
    input  wire [USER_WIDTH-1:0]  qsfp0_rx_s_axis_tuser,

    // tx from cmac_pad (originally from fpga_core)
    input  wire [DATA_WIDTH-1:0]  qsfp1_tx_s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  qsfp1_tx_s_axis_tkeep,
    input  wire                   qsfp1_tx_s_axis_tvalid,
    output wire                   qsfp1_tx_s_axis_tready,
    input  wire                   qsfp1_tx_s_axis_tlast,
    input  wire [USER_WIDTH-1:0]  qsfp1_tx_s_axis_tuser,

    // rx to fpga_core
    output wire [DATA_WIDTH-1:0]  qsfp1_rx_m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  qsfp1_rx_m_axis_tkeep,
    output wire                   qsfp1_rx_m_axis_tvalid,
    output wire                   qsfp1_rx_m_axis_tlast,
    output wire [USER_WIDTH-1:0]  qsfp1_rx_m_axis_tuser,

    // tx to cmac
    output wire [DATA_WIDTH-1:0]  qsfp1_tx_m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  qsfp1_tx_m_axis_tkeep,
    output wire                   qsfp1_tx_m_axis_tvalid,
    input  wire                   qsfp1_tx_m_axis_tready,
    output wire                   qsfp1_tx_m_axis_tlast,
    output wire [USER_WIDTH-1:0]  qsfp1_tx_m_axis_tuser,

    // rx from cmac
    input  wire [DATA_WIDTH-1:0]  qsfp1_rx_s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  qsfp1_rx_s_axis_tkeep,
    input  wire                   qsfp1_rx_s_axis_tvalid,
    input  wire                   qsfp1_rx_s_axis_tlast,
    input  wire [USER_WIDTH-1:0]  qsfp1_rx_s_axis_tuser,
    
{%- for p in range(m) %}
    input  wire [ADDR_WIDTH-1:0]    s{{'%02d'%p}}_axil_awaddr,
    input  wire [2:0]               s{{'%02d'%p}}_axil_awprot,
    input  wire                     s{{'%02d'%p}}_axil_awvalid,
    output wire                     s{{'%02d'%p}}_axil_awready,
    input  wire [DATA_WIDTH-1:0]    s{{'%02d'%p}}_axil_wdata,
    input  wire [STRB_WIDTH-1:0]    s{{'%02d'%p}}_axil_wstrb,
    input  wire                     s{{'%02d'%p}}_axil_wvalid,
    output wire                     s{{'%02d'%p}}_axil_wready,
    output wire [1:0]               s{{'%02d'%p}}_axil_bresp,
    output wire                     s{{'%02d'%p}}_axil_bvalid,
    input  wire                     s{{'%02d'%p}}_axil_bready,
    input  wire [ADDR_WIDTH-1:0]    s{{'%02d'%p}}_axil_araddr,
    input  wire [2:0]               s{{'%02d'%p}}_axil_arprot,
    input  wire                     s{{'%02d'%p}}_axil_arvalid,
    output wire                     s{{'%02d'%p}}_axil_arready,
    output wire [DATA_WIDTH-1:0]    s{{'%02d'%p}}_axil_rdata,
    output wire [1:0]               s{{'%02d'%p}}_axil_rresp,
    output wire                     s{{'%02d'%p}}_axil_rvalid,
    input  wire                     s{{'%02d'%p}}_axil_rready,
{% endfor %}
);

localparam AXIL_COUNT = {{m}};

// parameter sizing helpers
function [ADDR_WIDTH*M_REGIONS-1:0] w_a_r(input [ADDR_WIDTH*M_REGIONS-1:0] val);
    w_a_r = val;
endfunction

function [32*M_REGIONS-1:0] w_32_r(input [32*M_REGIONS-1:0] val);
    w_32_r = val;
endfunction

function [S_COUNT-1:0] w_s(input [S_COUNT-1:0] val);
    w_s = val;
endfunction

function w_1(input val);
    w_1 = val;
endfunction

kugelblitz_offload #(
    .DATA_WIDTH(DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH),
    .USER_WIDTH(USER_WIDTH),
    .AXIL_DATA_WIDTH(AXIL_DATA_WIDTH),
    .AXIL_STRB_WIDTH(AXIL_STRB_WIDTH),
    .AXIL_ADDR_WIDTH(AXIL_ADDR_WIDTH),
    .AXIL_COUNT(AXIL_COUNT)
)
kugelblitz_offload_inst (
        .s_axil_clk(s_axil_clk),
        .s_axil_rst(s_axil_rst),
        .qsfp0_tx_clk(qsfp0_tx_clk),
        .qsfp0_tx_rst(qsfp0_tx_rst),
        .qsfp0_rx_clk(qsfp0_rx_clk),
        .qsfp0_rx_rst(qsfp0_rx_rst),
        .qsfp1_tx_clk(qsfp1_tx_clk),
        .qsfp1_tx_rst(qsfp1_tx_rst),
        .qsfp1_rx_clk(qsfp1_rx_clk),
        .qsfp1_rx_rst(qsfp1_rx_rst),

        // tx from cmac_pad (originally from fpga core)
        .qsfp0_tx_s_axis_tdata(qsfp0_tx_s_axis_tdata),
        .qsfp0_tx_s_axis_tkeep(qsfp0_tx_s_axis_tkeep),
        .qsfp0_tx_s_axis_tvalid(qsfp0_tx_s_axis_tvalid),
        .qsfp0_tx_s_axis_tready(qsfp0_tx_s_axis_tready),
        .qsfp0_tx_s_axis_tlast(qsfp0_tx_s_axis_tlast),
        .qsfp0_tx_s_axis_tuser(qsfp0_tx_s_axis_tuser),

        // rx to fpga core
        .qsfp0_rx_m_axis_tdata(qsfp0_rx_m_axis_tdata),
        .qsfp0_rx_m_axis_tkeep(qsfp0_rx_m_axis_tkeep),
        .qsfp0_rx_m_axis_tvalid(qsfp0_rx_m_axis_tvalid),
        .qsfp0_rx_m_axis_tlast(qsfp0_rx_m_axis_tlast),
        .qsfp0_rx_m_axis_tuser(qsfp0_rx_m_axis_tuser),

        // tx to cmac
        .qsfp0_tx_m_axis_tdata(qsfp0_tx_m_axis_tdata),
        .qsfp0_tx_m_axis_tkeep(qsfp0_tx_m_axis_tkeep),
        .qsfp0_tx_m_axis_tvalid(qsfp0_tx_m_axis_tvalid),
        .qsfp0_tx_m_axis_tready(qsfp0_tx_m_axis_tready),
        .qsfp0_tx_m_axis_tlast(qsfp0_tx_m_axis_tlast),
        .qsfp0_tx_m_axis_tuser(qsfp0_tx_m_axis_tuser),

        // rx from cmac
        .qsfp0_rx_s_axis_tdata(qsfp0_rx_s_axis_tdata),
        .qsfp0_rx_s_axis_tkeep(qsfp0_rx_s_axis_tkeep),
        .qsfp0_rx_s_axis_tvalid(qsfp0_rx_s_axis_tvalid),
        .qsfp0_rx_s_axis_tlast(qsfp0_rx_s_axis_tlast),
        .qsfp0_rx_s_axis_tuser(qsfp0_rx_s_axis_tuser),

        // tx from cmac_pad (originally from fpga_core)
        .qsfp1_tx_s_axis_tdata(qsfp1_tx_s_axis_tdata),
        .qsfp1_tx_s_axis_tkeep(qsfp1_tx_s_axis_tkeep),
        .qsfp1_tx_s_axis_tvalid(qsfp1_tx_s_axis_tvalid),
        .qsfp1_tx_s_axis_tready(qsfp1_tx_s_axis_tready),
        .qsfp1_tx_s_axis_tlast(qsfp1_tx_s_axis_tlast),
        .qsfp1_tx_s_axis_tuser(qsfp1_tx_s_axis_tuser),

        // rx to fpga_core
        .qsfp1_rx_m_axis_tdata(qsfp1_rx_m_axis_tdata),
        .qsfp1_rx_m_axis_tkeep(qsfp1_rx_m_axis_tkeep),
        .qsfp1_rx_m_axis_tvalid(qsfp1_rx_m_axis_tvalid),
        .qsfp1_rx_m_axis_tlast(qsfp1_rx_m_axis_tlast),
        .qsfp1_rx_m_axis_tuser(qsfp1_rx_m_axis_tuser),

        // tx to cmac
        .qsfp1_tx_m_axis_tdata(qsfp1_tx_m_axis_tdata),
        .qsfp1_tx_m_axis_tkeep(qsfp1_tx_m_axis_tkeep),
        .qsfp1_tx_m_axis_tvalid(qsfp1_tx_m_axis_tvalid),
        .qsfp1_tx_m_axis_tready(qsfp1_tx_m_axis_tready),
        .qsfp1_tx_m_axis_tlast(qsfp1_tx_m_axis_tlast),
        .qsfp1_tx_m_axis_tuser(qsfp1_tx_m_axis_tuser),

        // rx from cmac
        .qsfp1_rx_s_axis_tdata(qsfp1_rx_s_axis_tdata),
        .qsfp1_rx_s_axis_tkeep(qsfp1_rx_s_axis_tkeep),
        .qsfp1_rx_s_axis_tvalid(qsfp1_rx_s_axis_tvalid),
        .qsfp1_rx_s_axis_tlast(qsfp1_rx_s_axis_tlast),
        .qsfp1_rx_s_axis_tuser(qsfp1_rx_s_axis_tuser),

        .s_axil_awprot({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_awprot{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_awvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_awvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_awready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_awready{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_wdata({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_wdata{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_wstrb({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_wstrb{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_wvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_wvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_wready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_wready{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_bresp({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_bresp{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_bvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_bvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_bready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_bready{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_araddr({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_araddr{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_arprot({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_arprot{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_arvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_arvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_arready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_arready{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_rdata({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_rdata{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_rresp({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_rresp{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_rvalid({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_rvalid{% if not loop.last %}, {% endif %}{% endfor %} }),
        .s_axil_rready({ {% for p in range(m-1,-1,-1) %}s{{'%02d'%p}}_axil_rready{% if not loop.last %}, {% endif %}{% endfor %} }),
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
