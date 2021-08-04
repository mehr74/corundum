// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * CMAC frame pad module
 */
module kugelblitz_offload #
(
    // Width of AXI stream interfaces in bits
    parameter DATA_WIDTH = 512,
    // tkeep signal width (words per cycle)
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    // tuser signal width
    parameter USER_WIDTH = 1,
    
    parameter AXIL_DATA_WIDTH = 32,
    
    parameter AXIL_STRB_WIDTH = (AXIL_DATA_WIDTH/8),
    
    parameter AXIL_ADDR_WIDTH = 32,

    parameter S_COUNT = 2
)
    (
        input wire                    qsfp0_tx_clk,
        input wire                    qsfp0_tx_rst,
        input wire                    qsfp0_rx_clk,
        input wire                    qsfp0_rx_rst,
        input wire                    qsfp1_tx_clk,
        input wire                    qsfp1_tx_rst,
        input wire                    qsfp1_rx_clk,
        input wire                    qsfp1_rx_rst,

        /*
         * AXI input qsfp0
         */
        input  wire [DATA_WIDTH-1:0]  qsfp0_tx_s_axis_tdata,
        input  wire [KEEP_WIDTH-1:0]  qsfp0_tx_s_axis_tkeep,
        input  wire                   qsfp0_tx_s_axis_tvalid,
        output wire                   qsfp0_tx_s_axis_tready,
        input  wire                   qsfp0_tx_s_axis_tlast,
        input  wire [USER_WIDTH-1:0]  qsfp0_tx_s_axis_tuser,

        output wire [DATA_WIDTH-1:0]  qsfp0_rx_m_axis_tdata,
        output wire [KEEP_WIDTH-1:0]  qsfp0_rx_m_axis_tkeep,
        output wire                   qsfp0_rx_m_axis_tvalid,
        output wire                   qsfp0_rx_m_axis_tlast,
        output wire [USER_WIDTH-1:0]  qsfp0_rx_m_axis_tuser,

        /*
         * AXI output qsfp0
         */
        output wire [DATA_WIDTH-1:0]  qsfp0_tx_m_axis_tdata,
        output wire [KEEP_WIDTH-1:0]  qsfp0_tx_m_axis_tkeep,
        output wire                   qsfp0_tx_m_axis_tvalid,
        input  wire                   qsfp0_tx_m_axis_tready,
        output wire                   qsfp0_tx_m_axis_tlast,
        output wire [USER_WIDTH-1:0]  qsfp0_tx_m_axis_tuser,

        input  wire [DATA_WIDTH-1:0]  qsfp0_rx_s_axis_tdata,
        input  wire [KEEP_WIDTH-1:0]  qsfp0_rx_s_axis_tkeep,
        input  wire                   qsfp0_rx_s_axis_tvalid,
        input  wire                   qsfp0_rx_s_axis_tlast,
        input  wire [USER_WIDTH-1:0]  qsfp0_rx_s_axis_tuser,

        /*
         * AXI input qsfp1
         */
        input  wire [DATA_WIDTH-1:0]  qsfp1_tx_s_axis_tdata,
        input  wire [KEEP_WIDTH-1:0]  qsfp1_tx_s_axis_tkeep,
        input  wire                   qsfp1_tx_s_axis_tvalid,
        output wire                   qsfp1_tx_s_axis_tready,
        input  wire                   qsfp1_tx_s_axis_tlast,
        input  wire [USER_WIDTH-1:0]  qsfp1_tx_s_axis_tuser,

        output wire [DATA_WIDTH-1:0]  qsfp1_rx_m_axis_tdata,
        output wire [KEEP_WIDTH-1:0]  qsfp1_rx_m_axis_tkeep,
        output wire                   qsfp1_rx_m_axis_tvalid,
        output wire                   qsfp1_rx_m_axis_tlast,
        output wire [USER_WIDTH-1:0]  qsfp1_rx_m_axis_tuser,

        /*
         * AXI output qsfp1
         */
        output wire [DATA_WIDTH-1:0]  qsfp1_tx_m_axis_tdata,
        output wire [KEEP_WIDTH-1:0]  qsfp1_tx_m_axis_tkeep,
        output wire                   qsfp1_tx_m_axis_tvalid,
        input  wire                   qsfp1_tx_m_axis_tready,
        output wire                   qsfp1_tx_m_axis_tlast,
        output wire [USER_WIDTH-1:0]  qsfp1_tx_m_axis_tuser,

        input  wire [DATA_WIDTH-1:0]  qsfp1_rx_s_axis_tdata,
        input  wire [KEEP_WIDTH-1:0]  qsfp1_rx_s_axis_tkeep,
        input  wire                   qsfp1_rx_s_axis_tvalid,
        input  wire                   qsfp1_rx_s_axis_tlast,
        input  wire [USER_WIDTH-1:0]  qsfp1_rx_s_axis_tuser,

        input  wire [S_COUNT*AXIL_ADDR_WIDTH-1:0]  s_axil_awaddr,
        input  wire [S_COUNT*3-1:0]           s_axil_awprot,
        input  wire [S_COUNT-1:0]             s_axil_awvalid,
        output wire [S_COUNT-1:0]             s_axil_awready,
        input  wire [S_COUNT*AXIL_DATA_WIDTH-1:0]  s_axil_wdata,
        input  wire [S_COUNT*AXIL_STRB_WIDTH-1:0]  s_axil_wstrb,
        input  wire [S_COUNT-1:0]             s_axil_wvalid,
        output wire [S_COUNT-1:0]             s_axil_wready,
        output wire [S_COUNT*2-1:0]           s_axil_bresp,
        output wire [S_COUNT-1:0]             s_axil_bvalid,
        input  wire [S_COUNT-1:0]             s_axil_bready,
        input  wire [S_COUNT*AXIL_ADDR_WIDTH-1:0]  s_axil_araddr,
        input  wire [S_COUNT*3-1:0]           s_axil_arprot,
        input  wire [S_COUNT-1:0]             s_axil_arvalid,
        output wire [S_COUNT-1:0]             s_axil_arready,
        output wire [S_COUNT*AXIL_DATA_WIDTH-1:0]  s_axil_rdata,
        output wire [S_COUNT*2-1:0]           s_axil_rresp,
        output wire [S_COUNT-1:0]             s_axil_rvalid,
        input  wire [S_COUNT-1:0]             s_axil_rready
    );

// check configuration
    initial begin
        if (DATA_WIDTH != 512) begin
            $error("Error: AXI stream data width must be 512 (instance %m)");
            $finish;
        end

        if (KEEP_WIDTH * 8 != DATA_WIDTH) begin
            $error("Error: AXI stream interface requires byte (8-bit) granularity (instance %m)");
            $finish;
        end
    end

    generate
        genvar k;

        for (k = 0; k < KEEP_WIDTH; k = k + 1) begin
            assign qsfp0_tx_m_axis_tdata[k*8 +: 8] = qsfp0_tx_s_axis_tkeep[k] ? qsfp0_tx_s_axis_tdata[k*8 +: 8] : 8'd0;
            assign qsfp0_rx_m_axis_tdata[k*8 +: 8] = qsfp0_rx_s_axis_tkeep[k] ? qsfp0_rx_s_axis_tdata[k*8 +: 8] + k : 8'd0;
            assign qsfp1_tx_m_axis_tdata[k*8 +: 8] = qsfp1_tx_s_axis_tkeep[k] ? qsfp1_tx_s_axis_tdata[k*8 +: 8] : 8'd0;
            assign qsfp1_rx_m_axis_tdata[k*8 +: 8] = qsfp1_rx_s_axis_tkeep[k] ? qsfp1_rx_s_axis_tdata[k*8 +: 8] + k : 8'd0;
        end
    endgenerate

    assign qsfp0_tx_m_axis_tkeep = qsfp0_tx_s_axis_tkeep;
    assign qsfp0_tx_m_axis_tvalid = qsfp0_tx_s_axis_tvalid;
    assign qsfp0_tx_s_axis_tready = qsfp0_tx_m_axis_tready;
    assign qsfp0_tx_m_axis_tlast = qsfp0_tx_s_axis_tlast;
    assign qsfp0_tx_m_axis_tuser = qsfp0_tx_s_axis_tuser;

    assign qsfp0_rx_m_axis_tkeep = qsfp0_rx_s_axis_tkeep;
    assign qsfp0_rx_m_axis_tvalid = qsfp0_rx_s_axis_tvalid;
    assign qsfp0_rx_m_axis_tlast = qsfp0_rx_s_axis_tlast;
    assign qsfp0_rx_m_axis_tuser = qsfp0_rx_s_axis_tuser;

    assign qsfp1_tx_m_axis_tkeep = qsfp1_tx_s_axis_tkeep;
    assign qsfp1_tx_m_axis_tvalid = qsfp1_tx_s_axis_tvalid;
    assign qsfp1_tx_s_axis_tready = qsfp1_tx_m_axis_tready;
    assign qsfp1_tx_m_axis_tlast = qsfp1_tx_s_axis_tlast;
    assign qsfp1_tx_m_axis_tuser = qsfp1_tx_s_axis_tuser;

    assign qsfp1_rx_m_axis_tkeep = qsfp1_rx_s_axis_tkeep;
    assign qsfp1_rx_m_axis_tvalid = qsfp1_rx_s_axis_tvalid;
    assign qsfp1_rx_m_axis_tlast = qsfp1_rx_s_axis_tlast;
    assign qsfp1_rx_m_axis_tuser = qsfp1_rx_s_axis_tuser;
endmodule