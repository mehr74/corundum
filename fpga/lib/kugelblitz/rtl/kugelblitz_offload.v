// Language: Verilog 2001

`timescale 1ns / 1ps

/*
 * CMAC frame pad module
 */
module kugelblitz_offload #
(
    // Width of AXI stream interfaces in bits
    parameter AXIS_ETH_DATA_WIDTH = 512,
    // tkeep signal width (words per cycle)
    parameter AXIS_ETH_KEEP_WIDTH = (AXIS_ETH_DATA_WIDTH/8),
    // tuser signal width
    parameter USER_WIDTH = 1,
    
    parameter AXIL_DATA_WIDTH = 32,
    
    parameter AXIL_STRB_WIDTH = (AXIL_DATA_WIDTH/8),
    
    parameter AXIL_ADDR_WIDTH = 32,

    parameter PORT_COUNT = 2
)
    (
        input  wire                                        kg_axil_clk,
        input  wire                                        kg_axil_rst,
        input  wire [PORT_COUNT-1:0]                       kg_port_tx_clk,
        input  wire [PORT_COUNT-1:0]                       kg_port_tx_rst,
        input  wire [PORT_COUNT-1:0]                       kg_port_rx_clk,
        input  wire [PORT_COUNT-1:0]                       kg_port_rx_rst,

        input  wire [PORT_COUNT*AXIL_ADDR_WIDTH-1:0]       kg_s_axil_awaddr,
        input  wire [PORT_COUNT*3-1:0]                     kg_s_axil_awprot,
        input  wire [PORT_COUNT-1:0]                       kg_s_axil_awvalid,
        output wire [PORT_COUNT-1:0]                       kg_s_axil_awready,
        input  wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0]       kg_s_axil_wdata,
        input  wire [PORT_COUNT*AXIL_STRB_WIDTH-1:0]       kg_s_axil_wstrb,
        input  wire [PORT_COUNT-1:0]                       kg_s_axil_wvalid,
        output wire [PORT_COUNT-1:0]                       kg_s_axil_wready,
        output wire [PORT_COUNT*2-1:0]                     kg_s_axil_bresp,
        output wire [PORT_COUNT-1:0]                       kg_s_axil_bvalid,
        input  wire [PORT_COUNT-1:0]                       kg_s_axil_bready,
        input  wire [PORT_COUNT*AXIL_ADDR_WIDTH-1:0]       kg_s_axil_araddr,
        input  wire [PORT_COUNT*3-1:0]                     kg_s_axil_arprot,
        input  wire [PORT_COUNT-1:0]                       kg_s_axil_arvalid,
        output wire [PORT_COUNT-1:0]                       kg_s_axil_arready,
        output wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0]       kg_s_axil_rdata,
        output wire [PORT_COUNT*2-1:0]                     kg_s_axil_rresp,
        output wire [PORT_COUNT-1:0]                       kg_s_axil_rvalid,
        input  wire [PORT_COUNT-1:0]                       kg_s_axil_rready,

        // port from IO to kugelblitz
        output wire [PORT_COUNT*AXIS_ETH_DATA_WIDTH-1:0]   kg_m_port_tx_axis_tdata,
        output wire [PORT_COUNT*AXIS_ETH_KEEP_WIDTH-1:0]   kg_m_port_tx_axis_tkeep,
        output wire [PORT_COUNT-1:0]                       kg_m_port_tx_axis_tvalid,
        input  wire [PORT_COUNT-1:0]                       kg_m_port_tx_axis_tready,
        output wire [PORT_COUNT-1:0]                       kg_m_port_tx_axis_tlast,
        output wire [PORT_COUNT-1:0]                       kg_m_port_tx_axis_tuser,
        input  wire [PORT_COUNT*80-1:0]                    kg_m_port_tx_ptp_ts,
        input  wire [PORT_COUNT-1:0]                       kg_m_port_tx_ptp_ts_valid,

        // port from IO to kugelblitz
        input  wire [PORT_COUNT*AXIS_ETH_DATA_WIDTH-1:0]   kg_s_port_rx_axis_tdata,
        input  wire [PORT_COUNT*AXIS_ETH_KEEP_WIDTH-1:0]   kg_s_port_rx_axis_tkeep,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_rx_axis_tvalid,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_rx_axis_tlast,
        input  wire [PORT_COUNT*81-1:0]                    kg_s_port_rx_axis_tuser,

        // port from kugelblitz to corundum
        input  wire [PORT_COUNT*AXIS_ETH_DATA_WIDTH-1:0]   kg_s_port_tx_axis_tdata,
        input  wire [PORT_COUNT*AXIS_ETH_KEEP_WIDTH-1:0]   kg_s_port_tx_axis_tkeep,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_tx_axis_tvalid,
        output wire [PORT_COUNT-1:0]                       kg_s_port_tx_axis_tready,
        output wire [PORT_COUNT-1:0]                       kg_s_port_tx_axis_tlast,
        output wire [PORT_COUNT-1:0]                       kg_s_port_tx_axis_tuser,
        input  wire [PORT_COUNT*80-1:0]                    kg_s_port_tx_ptp_ts,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_tx_ptp_ts_valid,

        // port from kugelblitz to corundum
        output wire [PORT_COUNT*AXIS_ETH_DATA_WIDTH-1:0]   kg_m_port_rx_axis_tdata,
        output wire [PORT_COUNT*AXIS_ETH_KEEP_WIDTH-1:0]   kg_m_port_rx_axis_tkeep,
        output wire [PORT_COUNT-1:0]                       kg_m_port_rx_axis_tvalid,
        output wire [PORT_COUNT-1:0]                       kg_m_port_rx_axis_tlast,
        output wire [PORT_COUNT*81-1:0]                    kg_m_port_rx_axis_tuser
    );

    // check configuration
    initial begin
        if (AXIS_ETH_DATA_WIDTH != 512) begin
            $error("Error: AXI stream data width must be 512 (instance %m)");
            $finish;
        end

        if (AXIS_ETH_KEEP_WIDTH * 8 != AXIS_ETH_DATA_WIDTH) begin
            $error("Error: AXI stream interface requires byte (8-bit) granularity (instance %m)");
            $finish;
        end
    end

    wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0] kg_address_valid_int;
    wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0] kg_address_int;
    wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0] kg_data_valid_int;
    wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0] kg_data_int;

    generate
        genvar n;
        for (n = 0; n < PORT_COUNT; n = n + 1) begin : iaxil
            axil_kg_regfile #(
                .DATA_WIDTH(AXIL_DATA_WIDTH),
                .ADDR_WIDTH(AXIL_ADDR_WIDTH),
                .STRB_WIDTH(AXIL_STRB_WIDTH)
            )
                kg_axil_regfile_inst (
                    .clk(kg_axil_clk),
                    .rst(kg_axil_rst),

                    .s_axil_awaddr      ( kg_s_axil_awaddr[n*AXIL_ADDR_WIDTH +: AXIL_ADDR_WIDTH]        ),
                    .s_axil_awprot      ( kg_s_axil_awprot[n*3 +: 3]                                    ),
                    .s_axil_awvalid     ( kg_s_axil_awvalid[n]                                          ),
                    .s_axil_awready     ( kg_s_axil_awready[n]                                          ),
                    .s_axil_wdata       ( kg_s_axil_wdata[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]         ),
                    .s_axil_wstrb       ( kg_s_axil_wstrb[n*AXIL_STRB_WIDTH +: AXIL_STRB_WIDTH]         ),
                    .s_axil_wvalid      ( kg_s_axil_wvalid[n]                                           ),
                    .s_axil_wready      ( kg_s_axil_wready[n]                                           ),
                    .s_axil_bresp       ( kg_s_axil_bresp[n*2 +: 2]                                     ),
                    .s_axil_bvalid      ( kg_s_axil_bvalid[n]                                           ),
                    .s_axil_bready      ( kg_s_axil_bready[n]                                           ),
                    .s_axil_araddr      ( kg_s_axil_araddr[n*AXIL_ADDR_WIDTH +: AXIL_ADDR_WIDTH]        ),
                    .s_axil_arprot      ( kg_s_axil_arprot[n*3 +: 3]                                    ),
                    .s_axil_arvalid     ( kg_s_axil_arvalid[n]                                          ),
                    .s_axil_arready     ( kg_s_axil_arready[n]                                          ),
                    .s_axil_rdata       ( kg_s_axil_rdata[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]         ),
                    .s_axil_rresp       ( kg_s_axil_rresp[n*2 +: 2]                                     ),
                    .s_axil_rvalid      ( kg_s_axil_rvalid[n]                                           ),
                    .s_axil_rready      ( kg_s_axil_rready[n]                                           ),

                    .kg_address         ( kg_address_int[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]          ),
                    .kg_address_valid   ( kg_address_valid_int[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]    ),
                    .kg_data            ( kg_data_int[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]             ),
                    .kg_data_valid      ( kg_data_valid_int[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]       )
                );
        end
    endgenerate

    generate
        genvar k;
        genvar i;
        for (i = 0; i < PORT_COUNT; i = i + 1) begin
            for (k = 0; k < AXIS_ETH_KEEP_WIDTH; k = k + 1) begin
                if(k == 60) begin
                    // assign constant to kg_qsfp 0
                    assign kg_m_port_tx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8] = !kg_s_port_tx_axis_tkeep[i*AXIS_ETH_KEEP_WIDTH + k] ? 8'd0 : 8'haa;
                    assign kg_m_port_rx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8] = !kg_s_port_rx_axis_tkeep[i*AXIS_ETH_KEEP_WIDTH + k] ? 8'd0 : 8'haa;
                end else if(k == 61) begin
                    // assign axil to kg_qsfp 1
                    assign kg_m_port_tx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8] = !kg_s_port_tx_axis_tkeep[i*AXIS_ETH_KEEP_WIDTH + k] ? 8'd0 : kg_data_int[0 +: 8];
                    assign kg_m_port_rx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8] = !kg_s_port_rx_axis_tkeep[i*AXIS_ETH_KEEP_WIDTH + k] ? 8'd0 : kg_data_int[0 +: 8];

                end else begin
                    assign kg_m_port_tx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8] = !kg_s_port_tx_axis_tkeep[i*AXIS_ETH_KEEP_WIDTH + k] ? 8'd0 :
                        (kg_address_valid_int[0] == 1'b1) && (kg_address_int[0] == k) ? kg_data_int[0 +: 8] :
                            kg_s_port_tx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8];

                    assign kg_m_port_rx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8] = !kg_s_port_rx_axis_tkeep[i*AXIS_ETH_KEEP_WIDTH + k] ? 8'd0 :
                        (kg_address_valid_int[0] == 1'b1) && (kg_address_int[0] == k) ? kg_data_int[0 +: 8] :
                            kg_s_port_rx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8];
                    assign kg_m_port_tx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8] = !kg_s_port_tx_axis_tkeep[i*AXIS_ETH_KEEP_WIDTH + k] ? 8'd0 :
                        (kg_address_valid_int[1] == 1'b1) && (kg_address_int[1] == k) ? kg_data_int[1*AXIL_DATA_WIDTH +: 8] :
                            kg_s_port_tx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8];
                    assign kg_m_port_rx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8] = !kg_s_port_rx_axis_tkeep[i*AXIS_ETH_KEEP_WIDTH + k] ? 8'd0 :
                        (kg_address_valid_int[1] == 1'b1) && (kg_address_int[1] == k) ? kg_data_int[1*AXIL_DATA_WIDTH +: 8] :
                            kg_s_port_rx_axis_tdata[i*AXIS_ETH_DATA_WIDTH + k*8 +: 8];
                end
            end
        end
    endgenerate

    assign kg_m_port_tx_axis_tkeep = kg_s_port_tx_axis_tkeep;
    assign kg_m_port_tx_axis_tvalid = kg_s_port_tx_axis_tvalid;
    assign kg_s_port_tx_axis_tready = kg_m_port_tx_axis_tready;
    assign kg_m_port_tx_axis_tlast = kg_s_port_tx_axis_tlast;
    assign kg_m_port_tx_axis_tuser = kg_s_port_tx_axis_tuser;

    assign kg_m_port_rx_axis_tkeep = kg_s_port_rx_axis_tkeep;
    assign kg_m_port_rx_axis_tvalid = kg_s_port_rx_axis_tvalid;
    assign kg_m_port_rx_axis_tlast = kg_s_port_rx_axis_tlast;
    assign kg_m_port_rx_axis_tuser = kg_s_port_rx_axis_tuser;
endmodule