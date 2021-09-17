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
        input  wire                                        kg_clk,
        input  wire                                        kg_rst,

        // axi lite for configuration purposes
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

        // port from IO to kugelblitz
        input  wire [PORT_COUNT*AXIS_ETH_DATA_WIDTH-1:0]   kg_s_port_rx_axis_tdata,
        input  wire [PORT_COUNT*AXIS_ETH_KEEP_WIDTH-1:0]   kg_s_port_rx_axis_tkeep,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_rx_axis_tvalid,
        output wire [PORT_COUNT-1:0]                       kg_s_port_rx_axis_tready,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_rx_axis_tlast,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_rx_axis_tuser,

        // port from kugelblitz to corundum
        input  wire [PORT_COUNT*AXIS_ETH_DATA_WIDTH-1:0]   kg_s_port_tx_axis_tdata,
        input  wire [PORT_COUNT*AXIS_ETH_KEEP_WIDTH-1:0]   kg_s_port_tx_axis_tkeep,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_tx_axis_tvalid,
        output wire [PORT_COUNT-1:0]                       kg_s_port_tx_axis_tready,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_tx_axis_tlast,
        input  wire [PORT_COUNT-1:0]                       kg_s_port_tx_axis_tuser,

        // port from kugelblitz to corundum
        output wire [PORT_COUNT*AXIS_ETH_DATA_WIDTH-1:0]   kg_m_port_rx_axis_tdata,
        output wire [PORT_COUNT*AXIS_ETH_KEEP_WIDTH-1:0]   kg_m_port_rx_axis_tkeep,
        output wire [PORT_COUNT-1:0]                       kg_m_port_rx_axis_tvalid,
        input  wire [PORT_COUNT-1:0]                       kg_m_port_rx_axis_tready,
        output wire [PORT_COUNT-1:0]                       kg_m_port_rx_axis_tlast,
        output wire [PORT_COUNT-1:0]                       kg_m_port_rx_axis_tuser
    );

    wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0] kg_address_valid_int;
    wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0] kg_address_int;
    wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0] kg_data_valid_int;
    wire [PORT_COUNT*AXIL_DATA_WIDTH-1:0] kg_data_int;

    generate
        genvar n;

        for (n = 0; n < PORT_COUNT; n = n + 1) begin : iaxil
        /*
            axil_kg_regfile #(
                .DATA_WIDTH(AXIL_DATA_WIDTH),
                .ADDR_WIDTH(AXIL_ADDR_WIDTH),
                .STRB_WIDTH(AXIL_STRB_WIDTH)
            )
            kg_axil_regfile_inst (
                .clk(kg_clk),
                .rst(kg_rst),

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
*/
            CpltSpatial complete_spatial_inst (
              .clock                  ( kg_clk                           ),
              .reset                  ( kg_rst                           ),
              .sio_readAddr           (                                  ),
              .sio_readData           (                                  ),
              .sio_readEnable         (                                  ),
              .sio_readValid          (                                  ),
              .sio_writeAddr          (                                  ),
              .sio_writeData          (                                  ),
              .sio_writeEnable        (                                  ),
              .io_netClock            ( kg_clk                           ),
              .io_opaque_in_op_1      (                                  ),
              .io_opaque_in_op_0      (                                  ),
              .io_opaque_out_op_1     (                                  ),
              .io_opaque_out_op_0     (                                  ),
              .io_axisIn0_tvalid      ( kg_s_port_rx_axis_tvalid[n]                                           ),
              .io_axisIn0_tready      ( kg_s_port_rx_axis_tready[n]                                           ),
              .io_axisIn0_tdata       ( kg_s_port_rx_axis_tdata[n*AXIS_ETH_DATA_WIDTH +: AXIS_ETH_DATA_WIDTH] ),
              .io_axisIn0_tkeep       ( kg_s_port_rx_axis_tkeep[n*AXIS_ETH_KEEP_WIDTH +: AXIS_ETH_KEEP_WIDTH] ),
              .io_axisIn0_tlast       ( kg_s_port_rx_axis_tlast[n]                                            ),
              .io_axisIn1_tvalid      ( kg_s_port_tx_axis_tvalid[n]                                           ),
              .io_axisIn1_tready      ( kg_s_port_tx_axis_tready[n]                                           ),
              .io_axisIn1_tdata       ( kg_s_port_tx_axis_tdata[n*AXIS_ETH_DATA_WIDTH +: AXIS_ETH_DATA_WIDTH] ),
              .io_axisIn1_tkeep       ( kg_s_port_tx_axis_tkeep[n*AXIS_ETH_KEEP_WIDTH +: AXIS_ETH_KEEP_WIDTH] ),
              .io_axisIn1_tlast       ( kg_s_port_tx_axis_tlast[n]                                            ),
              .io_axisOut0_tvalid     ( kg_m_port_rx_axis_tvalid[n]                                           ),
              .io_axisOut0_tready     ( kg_m_port_rx_axis_tready[n]                                           ),
              .io_axisOut0_tdata      ( kg_m_port_rx_axis_tdata[n*AXIS_ETH_DATA_WIDTH +: AXIS_ETH_DATA_WIDTH] ),
              .io_axisOut0_tkeep      ( kg_m_port_rx_axis_tkeep[n*AXIS_ETH_KEEP_WIDTH +: AXIS_ETH_KEEP_WIDTH] ),
              .io_axisOut0_tlast      ( kg_m_port_rx_axis_tlast[n]                                            ),
              .io_axisOut1_tvalid     ( kg_m_port_tx_axis_tvalid[n]                                           ),
              .io_axisOut1_tready     ( kg_m_port_tx_axis_tready[n]                                           ),
              .io_axisOut1_tdata      ( kg_m_port_tx_axis_tdata[n*AXIS_ETH_DATA_WIDTH +: AXIS_ETH_DATA_WIDTH] ),
              .io_axisOut1_tkeep      ( kg_m_port_tx_axis_tkeep[n*AXIS_ETH_KEEP_WIDTH +: AXIS_ETH_KEEP_WIDTH] ),
              .io_axisOut1_tlast      ( kg_m_port_tx_axis_tlast[n]                                            ),
              .io_axil_awaddr         ( kg_s_axil_awaddr[n*AXIL_ADDR_WIDTH +: AXIL_ADDR_WIDTH]   ),
              .io_axil_awprot         ( kg_s_axil_awprot[n*3 +: 3]                               ),
              .io_axil_awvalid        ( kg_s_axil_awvalid[n]                                     ),
              .io_axil_awready        ( kg_s_axil_awready[n]                                     ),
              .io_axil_wdata          ( kg_s_axil_wdata[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]    ),
              .io_axil_wstrb          ( kg_s_axil_wstrb[n*AXIL_STRB_WIDTH +: AXIL_STRB_WIDTH]    ),
              .io_axil_wvalid         ( kg_s_axil_wvalid[n]                                      ),
              .io_axil_wready         ( kg_s_axil_wready[n]                                      ),
              .io_axil_bresp          ( kg_s_axil_bresp[n*2 +: 2]                                ),
              .io_axil_bvalid         ( kg_s_axil_bvalid[n]                                      ),
              .io_axil_bready         ( kg_s_axil_bready[n]                                      ),
              .io_axil_araddr         ( kg_s_axil_araddr[n*AXIL_ADDR_WIDTH +: AXIL_ADDR_WIDTH]   ),
              .io_axil_arprot         ( kg_s_axil_arprot[n*3 +: 3]                               ),
              .io_axil_arvalid        ( kg_s_axil_arvalid[n]                                     ),
              .io_axil_arready        ( kg_s_axil_arready[n]                                     ),
              .io_axil_rdata          ( kg_s_axil_rdata[n*AXIL_DATA_WIDTH +: AXIL_DATA_WIDTH]    ),
              .io_axil_rresp          ( kg_s_axil_rresp[n*2 +: 2]                                ),
              .io_axil_rvalid         ( kg_s_axil_rvalid[n]                                      ),
              .io_axil_rready         ( kg_s_axil_rready[n]                                      ),
              .io_dbg_CamOut          (                                  ),
              .io_dbg_CamIn           (                                  ),
              .io_dbg_ParOut          (                                  ),
              .io_dbg_StateROut       (                                  ),
              .io_dbg_StateWOut       (                                  ),
              .io_dbg_Deparser        (                                  ),
              .io_dbg_PacketOut       (                                  ),
              .io_dbg_PacketBuff      (                                  ),
              .io_dbg_valids          (                                  ),
              .io_dbg_stalls          (                                  ),
              .io_dbg_others          (                                  )
            );
        end
    endgenerate

/*
    assign kg_m_port_tx_axis_tdata  = kg_s_port_tx_axis_tdata;
    assign kg_m_port_tx_axis_tkeep  = kg_s_port_tx_axis_tkeep;
    assign kg_m_port_tx_axis_tvalid = kg_s_port_tx_axis_tvalid;
    assign kg_s_port_tx_axis_tready = kg_m_port_tx_axis_tready;
    assign kg_m_port_tx_axis_tlast  = kg_s_port_tx_axis_tlast;
    assign kg_m_port_tx_axis_tuser  = kg_s_port_tx_axis_tuser;

    assign kg_m_port_rx_axis_tdata  = kg_s_port_rx_axis_tdata;
    assign kg_m_port_rx_axis_tkeep  = kg_s_port_rx_axis_tkeep;
    assign kg_m_port_rx_axis_tvalid = kg_s_port_rx_axis_tvalid;
    assign kg_s_port_rx_axis_tready = kg_m_port_rx_axis_tready;
    assign kg_m_port_rx_axis_tlast  = kg_s_port_rx_axis_tlast;
*/
    assign kg_m_port_rx_axis_tuser  = kg_s_port_rx_axis_tuser;
endmodule
