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

        input  wire [S_COUNT*AXIL_ADDR_WIDTH-1:0]   s_axil_awaddr,
        input  wire [S_COUNT*3-1:0]                 s_axil_awprot,
        input  wire [S_COUNT-1:0]                   s_axil_awvalid,
        output wire [S_COUNT-1:0]                   s_axil_awready,
        input  wire [S_COUNT*AXIL_DATA_WIDTH-1:0]   s_axil_wdata,
        input  wire [S_COUNT*AXIL_STRB_WIDTH-1:0]   s_axil_wstrb,
        input  wire [S_COUNT-1:0]                   s_axil_wvalid,
        output wire [S_COUNT-1:0]                   s_axil_wready,
        output wire [S_COUNT*2-1:0]                 s_axil_bresp,
        output wire [S_COUNT-1:0]                   s_axil_bvalid,
        input  wire [S_COUNT-1:0]                   s_axil_bready,
        input  wire [S_COUNT*AXIL_ADDR_WIDTH-1:0]   s_axil_araddr,
        input  wire [S_COUNT*3-1:0]                 s_axil_arprot,
        input  wire [S_COUNT-1:0]                   s_axil_arvalid,
        output wire [S_COUNT-1:0]                   s_axil_arready,
        output wire [S_COUNT*AXIL_DATA_WIDTH-1:0]   s_axil_rdata,
        output wire [S_COUNT*2-1:0]                 s_axil_rresp,
        output wire [S_COUNT-1:0]                   s_axil_rvalid,
        input  wire [S_COUNT-1:0]                   s_axil_rready
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

    wire [S_COUNT-1:0] kg_address_valid_int;
    wire [S_COUNT-1:0] kg_address_int;
    wire [S_COUNT-1:0] kg_data_valid_int;
    wire [S_COUNT-1:0] kg_data_int;

    generate
        genvar n;
        for (n = 0; n < S_COUNT; n = n + 1) begin : iaxil
            kugelblitz_axil_regfile #(
                .DATA_WIDTH(AXIL_DATA_WIDTH),
                .ADDR_WIDTH(AXIL_ADDR_WIDTH),
                .STRB_WIDTH(AXIL_STRB_WIDTH)
            )
                kg_axil_regfile_inst (
                    .clk(s_axil_clk),
                    .rst(s_axil_rst),
                    .s_axil_awaddr(s_axil_awaddr[n*AXIL_ADDR_WIDTH +: AXIL_ADDR_WIDTH]),
                    .s_axil_awprot(s_axil_awprot[n*3 +: 3]),
                    .s_axil_awvalid(s_axil_awvalid[n]),
                    .s_axil_awready(s_axil_awready[n]),
                    .s_axil_wdata(s_axil_wdata[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]),
                    .s_axil_wstrb(s_axil_wstrb[n*AXIL_STRB_WIDTH +: AXIL_STRB_WIDTH]),
                    .s_axil_wvalid(s_axil_wvalid[n]),
                    .s_axil_wready(s_axil_wready[n]),
                    .s_axil_bresp(s_axil_bresp[n*2 +: 2]),
                    .s_axil_bvalid(s_axil_bvalid[n]),
                    .s_axil_bready(s_axil_bready[n]),
                    .s_axil_araddr(s_axil_araddr[n*AXIL_ADDR_WIDTH +: AXIL_ADDR_WIDTH]),
                    .s_axil_arprot(s_axil_arprot[n*3 +: 3]),
                    .s_axil_arvalid(s_axil_arvalid[n]),
                    .s_axil_arready(s_axil_arready[n]),
                    .s_axil_rdata(s_axil_rdata[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]),
                    .s_axil_rresp(s_axil_rresp[n*2 +: 2]),
                    .s_axil_rvalid(s_axil_rvalid[n]),
                    .s_axil_rready(s_axil_rready[n]),
                    .kg_address(kg_address_int[n]),
                    .kg_address_valid(kg_address_valid_int[n]),
                    .kg_data(kg_data_int[n]),
                    .kg_data_valid(kg_data_valid_int[n])
                );
        end
    endgenerate

    generate
        genvar k;
        for (k = 0; k < KEEP_WIDTH; k = k + 1) begin
            assign qsfp0_tx_m_axis_tdata[k*8 +: 8] = !qsfp0_tx_s_axis_tkeep[k] ? 8'd0 :
                (kg_address_valid_int[0] == 1'b1) && (kg_address_int[0] == k) ? kg_data_int[0] :
                    qsfp0_tx_s_axis_tdata[k*8 +: 8];
       
            assign qsfp0_rx_m_axis_tdata[k*8 +: 8] = !qsfp0_rx_s_axis_tkeep[k] ? 8'd0 :
                (kg_address_valid_int[0] == 1'b1) && (kg_address_int[0] == k) ? kg_data_int[0] :
                    qsfp0_rx_s_axis_tdata[k*8 +: 8];
            assign qsfp1_tx_m_axis_tdata[k*8 +: 8] = !qsfp1_tx_s_axis_tkeep[k] ? 8'd0 :
                (kg_address_valid_int[1] == 1'b1) && (kg_address_int[1] == k) ? kg_data_int[1] :
                    qsfp1_tx_s_axis_tdata[k*8 +: 8];
            assign qsfp1_rx_m_axis_tdata[k*8 +: 8] = !qsfp1_rx_s_axis_tkeep[k] ? 8'd0 :
                (kg_address_valid_int[1] == 1'b1) && (kg_address_int[1] == k) ? kg_data_int[1] :
                    qsfp1_rx_s_axis_tdata[k*8 +: 8];
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