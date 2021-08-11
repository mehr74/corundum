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

    parameter AXIL_COUNT = 2
)
    (
        input wire                    kg_s_axil_clk,
        input wire                    kg_s_axil_rst,
        input wire                    kg_qsfp0_tx_clk,
        input wire                    kg_qsfp0_tx_rst,
        input wire                    kg_qsfp0_rx_clk,
        input wire                    kg_qsfp0_rx_rst,
        input wire                    kg_qsfp1_tx_clk,
        input wire                    kg_qsfp1_tx_rst,
        input wire                    kg_qsfp1_rx_clk,
        input wire                    kg_qsfp1_rx_rst,

        // tx from cmac_pad (originally from fpga core)
        input  wire [DATA_WIDTH-1:0]  kg_qsfp0_tx_s_axis_tdata,
        input  wire [KEEP_WIDTH-1:0]  kg_qsfp0_tx_s_axis_tkeep,
        input  wire                   kg_qsfp0_tx_s_axis_tvalid,
        output wire                   kg_qsfp0_tx_s_axis_tready,
        input  wire                   kg_qsfp0_tx_s_axis_tlast,
        input  wire [USER_WIDTH-1:0]  kg_qsfp0_tx_s_axis_tuser,

        // rx to fpga core
        output wire [DATA_WIDTH-1:0]  kg_qsfp0_rx_m_axis_tdata,
        output wire [KEEP_WIDTH-1:0]  kg_qsfp0_rx_m_axis_tkeep,
        output wire                   kg_qsfp0_rx_m_axis_tvalid,
        output wire                   kg_qsfp0_rx_m_axis_tlast,
        output wire [USER_WIDTH-1:0]  kg_qsfp0_rx_m_axis_tuser,

        // tx to cmac
        output wire [DATA_WIDTH-1:0]  kg_qsfp0_tx_m_axis_tdata,
        output wire [KEEP_WIDTH-1:0]  kg_qsfp0_tx_m_axis_tkeep,
        output wire                   kg_qsfp0_tx_m_axis_tvalid,
        input  wire                   kg_qsfp0_tx_m_axis_tready,
        output wire                   kg_qsfp0_tx_m_axis_tlast,
        output wire [USER_WIDTH-1:0]  kg_qsfp0_tx_m_axis_tuser,

        // rx from cmac
        input  wire [DATA_WIDTH-1:0]  kg_qsfp0_rx_s_axis_tdata,
        input  wire [KEEP_WIDTH-1:0]  kg_qsfp0_rx_s_axis_tkeep,
        input  wire                   kg_qsfp0_rx_s_axis_tvalid,
        input  wire                   kg_qsfp0_rx_s_axis_tlast,
        input  wire [USER_WIDTH-1:0]  kg_qsfp0_rx_s_axis_tuser,

        // tx from cmac_pad (originally from fpga_core)
        input  wire [DATA_WIDTH-1:0]  kg_qsfp1_tx_s_axis_tdata,
        input  wire [KEEP_WIDTH-1:0]  kg_qsfp1_tx_s_axis_tkeep,
        input  wire                   kg_qsfp1_tx_s_axis_tvalid,
        output wire                   kg_qsfp1_tx_s_axis_tready,
        input  wire                   kg_qsfp1_tx_s_axis_tlast,
        input  wire [USER_WIDTH-1:0]  kg_qsfp1_tx_s_axis_tuser,

        // rx to fpga_core
        output wire [DATA_WIDTH-1:0]  kg_qsfp1_rx_m_axis_tdata,
        output wire [KEEP_WIDTH-1:0]  kg_qsfp1_rx_m_axis_tkeep,
        output wire                   kg_qsfp1_rx_m_axis_tvalid,
        output wire                   kg_qsfp1_rx_m_axis_tlast,
        output wire [USER_WIDTH-1:0]  kg_qsfp1_rx_m_axis_tuser,

        // tx to cmac
        output wire [DATA_WIDTH-1:0]  kg_qsfp1_tx_m_axis_tdata,
        output wire [KEEP_WIDTH-1:0]  kg_qsfp1_tx_m_axis_tkeep,
        output wire                   kg_qsfp1_tx_m_axis_tvalid,
        input  wire                   kg_qsfp1_tx_m_axis_tready,
        output wire                   kg_qsfp1_tx_m_axis_tlast,
        output wire [USER_WIDTH-1:0]  kg_qsfp1_tx_m_axis_tuser,

        // rx from cmac
        input  wire [DATA_WIDTH-1:0]  kg_qsfp1_rx_s_axis_tdata,
        input  wire [KEEP_WIDTH-1:0]  kg_qsfp1_rx_s_axis_tkeep,
        input  wire                   kg_qsfp1_rx_s_axis_tvalid,
        input  wire                   kg_qsfp1_rx_s_axis_tlast,
        input  wire [USER_WIDTH-1:0]  kg_qsfp1_rx_s_axis_tuser,

        input  wire [AXIL_COUNT*AXIL_ADDR_WIDTH-1:0]   kg_s_axil_awaddr,
        input  wire [AXIL_COUNT*3-1:0]                 kg_s_axil_awprot,
        input  wire [AXIL_COUNT-1:0]                   kg_s_axil_awvalid,
        output wire [AXIL_COUNT-1:0]                   kg_s_axil_awready,
        input  wire [AXIL_COUNT*AXIL_DATA_WIDTH-1:0]   kg_s_axil_wdata,
        input  wire [AXIL_COUNT*AXIL_STRB_WIDTH-1:0]   kg_s_axil_wstrb,
        input  wire [AXIL_COUNT-1:0]                   kg_s_axil_wvalid,
        output wire [AXIL_COUNT-1:0]                   kg_s_axil_wready,
        output wire [AXIL_COUNT*2-1:0]                 kg_s_axil_bresp,
        output wire [AXIL_COUNT-1:0]                   kg_s_axil_bvalid,
        input  wire [AXIL_COUNT-1:0]                   kg_s_axil_bready,
        input  wire [AXIL_COUNT*AXIL_ADDR_WIDTH-1:0]   kg_s_axil_araddr,
        input  wire [AXIL_COUNT*3-1:0]                 kg_s_axil_arprot,
        input  wire [AXIL_COUNT-1:0]                   kg_s_axil_arvalid,
        output wire [AXIL_COUNT-1:0]                   kg_s_axil_arready,
        output wire [AXIL_COUNT*AXIL_DATA_WIDTH-1:0]   kg_s_axil_rdata,
        output wire [AXIL_COUNT*2-1:0]                 kg_s_axil_rresp,
        output wire [AXIL_COUNT-1:0]                   kg_s_axil_rvalid,
        input  wire [AXIL_COUNT-1:0]                   kg_s_axil_rready
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

    wire [AXIL_COUNT*AXIL_DATA_WIDTH-1:0] kg_address_valid_int;
    wire [AXIL_COUNT*AXIL_DATA_WIDTH-1:0] kg_address_int;
    wire [AXIL_COUNT*AXIL_DATA_WIDTH-1:0] kg_data_valid_int;
    wire [AXIL_COUNT*AXIL_DATA_WIDTH-1:0] kg_data_int;

    generate
        genvar n;
        for (n = 0; n < AXIL_COUNT; n = n + 1) begin : iaxil
            axil_kg_regfile #(
                .DATA_WIDTH(AXIL_DATA_WIDTH),
                .ADDR_WIDTH(AXIL_ADDR_WIDTH),
                .STRB_WIDTH(AXIL_STRB_WIDTH)
            )
                kg_axil_regfile_inst (
                    .clk(kg_s_axil_clk),
                    .rst(kg_s_axil_rst),

                    .s_axil_awaddr  ( kg_s_axil_awaddr[n*AXIL_ADDR_WIDTH +: AXIL_ADDR_WIDTH] ),
                    .s_axil_awprot  ( kg_s_axil_awprot[n*3 +: 3]                             ),
                    .s_axil_awvalid ( kg_s_axil_awvalid[n]                                   ),
                    .s_axil_awready ( kg_s_axil_awready[n]                                   ),
                    .s_axil_wdata   ( kg_s_axil_wdata[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]  ),
                    .s_axil_wstrb   ( kg_s_axil_wstrb[n*AXIL_STRB_WIDTH +: AXIL_STRB_WIDTH]  ),
                    .s_axil_wvalid  ( kg_s_axil_wvalid[n]                                    ),
                    .s_axil_wready  ( kg_s_axil_wready[n]                                    ),
                    .s_axil_bresp   ( kg_s_axil_bresp[n*2 +: 2]                              ),
                    .s_axil_bvalid  ( kg_s_axil_bvalid[n]                                    ),
                    .s_axil_bready  ( kg_s_axil_bready[n]                                    ),
                    .s_axil_araddr  ( kg_s_axil_araddr[n*AXIL_ADDR_WIDTH +: AXIL_ADDR_WIDTH] ),
                    .s_axil_arprot  ( kg_s_axil_arprot[n*3 +: 3]                             ),
                    .s_axil_arvalid ( kg_s_axil_arvalid[n]                                   ),
                    .s_axil_arready ( kg_s_axil_arready[n]                                   ),
                    .s_axil_rdata   ( kg_s_axil_rdata[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]  ),
                    .s_axil_rresp   ( kg_s_axil_rresp[n*2 +: 2]                              ),
                    .s_axil_rvalid  ( kg_s_axil_rvalid[n]                                    ),
                    .s_axil_rready  ( kg_s_axil_rready[n]                                    ),

                    .kg_address(kg_address_int[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]),
                    .kg_address_valid(kg_address_valid_int[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]),
                    .kg_data(kg_data_int[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]),
                    .kg_data_valid(kg_data_valid_int[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH])
                );
        end
    endgenerate

    generate
        genvar k;
        for (k = 0; k < KEEP_WIDTH; k = k + 1) begin
            if(k == 60) begin
                // assign constant to kg_qsfp 0
                assign kg_qsfp0_tx_m_axis_tdata[k*8 +: 8] = !kg_qsfp0_tx_s_axis_tkeep[k] ? 8'd0 : 8'haa;
                assign kg_qsfp0_rx_m_axis_tdata[k*8 +: 8] = !kg_qsfp0_rx_s_axis_tkeep[k] ? 8'd0 : 8'haa;

                // assign axil to kg_qsfp 1
                assign kg_qsfp1_tx_m_axis_tdata[k*8 +: 8] = !kg_qsfp1_tx_s_axis_tkeep[k] ? 8'd0 : kg_data_int[0 +: 8];
                assign kg_qsfp1_rx_m_axis_tdata[k*8 +: 8] = !kg_qsfp1_rx_s_axis_tkeep[k] ? 8'd0 : kg_data_int[0 +: 8];

            end else begin
                assign kg_qsfp0_tx_m_axis_tdata[k*8 +: 8] = !kg_qsfp0_tx_s_axis_tkeep[k] ? 8'd0 :
                    (kg_address_valid_int[0] == 1'b1) && (kg_address_int[0] == k) ? kg_data_int[0 +: 8] :
                        kg_qsfp0_tx_s_axis_tdata[k*8 +: 8];

                assign kg_qsfp0_rx_m_axis_tdata[k*8 +: 8] = !kg_qsfp0_rx_s_axis_tkeep[k] ? 8'd0 :
                    (kg_address_valid_int[0] == 1'b1) && (kg_address_int[0] == k) ? kg_data_int[0 +: 8] :
                        kg_qsfp0_rx_s_axis_tdata[k*8 +: 8];
                assign kg_qsfp1_tx_m_axis_tdata[k*8 +: 8] = !kg_qsfp1_tx_s_axis_tkeep[k] ? 8'd0 :
                    (kg_address_valid_int[1] == 1'b1) && (kg_address_int[1] == k) ? kg_data_int[1*AXIL_DATA_WIDTH +: 8] :
                        kg_qsfp1_tx_s_axis_tdata[k*8 +: 8];
                assign kg_qsfp1_rx_m_axis_tdata[k*8 +: 8] = !kg_qsfp1_rx_s_axis_tkeep[k] ? 8'd0 :
                    (kg_address_valid_int[1] == 1'b1) && (kg_address_int[1] == k) ? kg_data_int[1*AXIL_DATA_WIDTH +: 8] :
                        kg_qsfp1_rx_s_axis_tdata[k*8 +: 8];
            end
        end
    endgenerate

    assign kg_qsfp0_tx_m_axis_tkeep = kg_qsfp0_tx_s_axis_tkeep;
    assign kg_qsfp0_tx_m_axis_tvalid = kg_qsfp0_tx_s_axis_tvalid;
    assign kg_qsfp0_tx_s_axis_tready = kg_qsfp0_tx_m_axis_tready;
    assign kg_qsfp0_tx_m_axis_tlast = kg_qsfp0_tx_s_axis_tlast;
    assign kg_qsfp0_tx_m_axis_tuser = kg_qsfp0_tx_s_axis_tuser;

    assign kg_qsfp0_rx_m_axis_tkeep = kg_qsfp0_rx_s_axis_tkeep;
    assign kg_qsfp0_rx_m_axis_tvalid = kg_qsfp0_rx_s_axis_tvalid;
    assign kg_qsfp0_rx_m_axis_tlast = kg_qsfp0_rx_s_axis_tlast;
    assign kg_qsfp0_rx_m_axis_tuser = kg_qsfp0_rx_s_axis_tuser;

    assign kg_qsfp1_tx_m_axis_tkeep = kg_qsfp1_tx_s_axis_tkeep;
    assign kg_qsfp1_tx_m_axis_tvalid = kg_qsfp1_tx_s_axis_tvalid;
    assign kg_qsfp1_tx_s_axis_tready = kg_qsfp1_tx_m_axis_tready;
    assign kg_qsfp1_tx_m_axis_tlast = kg_qsfp1_tx_s_axis_tlast;
    assign kg_qsfp1_tx_m_axis_tuser = kg_qsfp1_tx_s_axis_tuser;

    assign kg_qsfp1_rx_m_axis_tkeep = kg_qsfp1_rx_s_axis_tkeep;
    assign kg_qsfp1_rx_m_axis_tvalid = kg_qsfp1_rx_s_axis_tvalid;
    assign kg_qsfp1_rx_m_axis_tlast = kg_qsfp1_rx_s_axis_tlast;
    assign kg_qsfp1_rx_m_axis_tuser = kg_qsfp1_rx_s_axis_tuser;
endmodule