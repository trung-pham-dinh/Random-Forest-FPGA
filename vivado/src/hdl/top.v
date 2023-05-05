`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2022 09:10:28 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top #(
     localparam THSH_WIDTH       = 16
    ,localparam ATTR_WIDTH       = 5
    ,localparam RES_WIDTH        = 16
)(
     input                                     clk
    ,input                                     rst_n
          
//    ,input  [THSH_WIDTH-1:0]                   i_attr_ram_dout
    ,input                                     i_attr_ram_dout
//    ,output [ATTR_WIDTH-1:0]                   o_attr_ram_sel 
    ,output                                    o_attr_ram_sel 
    ,output                                    o_att_ram_switch
    ,input                                     i_is_att_ram_avai
    ,input                                     i_is_sample_done

    ,input                                     i_tree_ram_ready
       
    ,input                                     i_res_fifo_is_full
    ,output                                    o_res_fifo_we
//    ,output [RES_WIDTH-1:0]                    o_res_fifo_dout
    ,output                                    o_res_fifo_dout
     
    ,input                                     i_dtp_start
    ,input                                     i_dtp_end
    ,output                                    o_dtp_fin
    );

dtp dtp_inst_0 (
        .clk                (clk                          ),
        .rst_n              (rst_n                        ),
        .i_attr_ram_dout    ({THSH_WIDTH{i_attr_ram_dout}}),    
        .o_attr_ram_sel     (o_attr_ram_sel               ),    
        .o_att_ram_switch   (o_att_ram_switch             ),    
        .i_is_att_ram_avai  (i_is_att_ram_avai            ),    
        .i_is_sample_done   (i_is_sample_done             ),    
        .i_tree_ram_ready   (i_tree_ram_ready             ),    
        .i_res_fifo_is_full (i_res_fifo_is_full           ),    
        .o_res_fifo_we      (o_res_fifo_we                ),
        .o_res_fifo_dout    (o_res_fifo_dout              ),    
        .i_dtp_start        (i_dtp_start                  ),    
        .i_dtp_end          (i_dtp_end                    ),    
        .o_dtp_fin          (o_dtp_fin                    ),

        .bram_en_ps         (1'b0),
        .bram_dout_ps       (),
        .bram_din_ps        (),
        .bram_we_ps         (7'b0),
        .bram_addr_ps       (),
        .bram_clk_ps        (clk),
        .bram_rst_ps        (1'b0)  
    );
    
endmodule



//module top #(
//    parameter C_S_AXI_ADDR_WIDTH = 7,
//    parameter C_S_AXI_DATA_WIDTH = 32
//)(
//    input          clk
//    ,input         rst_n,
    
    
//      // Uncomment the following to set interface specific parameter on the bus interface.
//    //  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
//      (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A EN" *)
//      output bram_ena, // Chip Enable Signal (optional)
//      (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A DOUT" *)
//      input [31 : 0] bram_douta, // Data Out Bus (optional)
//      (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A DIN" *)
//      output [31 : 0]  bram_dina, // Data In Bus (optional)
//      (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A WE" *)
//      output [3 : 0]   bram_wea, // Byte Enables (optional)
//      (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A ADDR" *)
//      output [31 : 0]  bram_addra, // Address Signal (required)
//      (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A CLK" *)
//      output bram_clka, // Clock Signal (required)
//      (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A RST" *)
//      output bram_rsta, // Reset Signal (required)
    
    
    
    
//        input wire  S_AXI_ACLK,
//		// Global Reset Signal. This Signal is Active LOW
//		input wire  S_AXI_ARESETN,
//		// Write address (issued by master, acceped by Slave)
//		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
//		// Write channel Protection type. This signal indicates the
//    		// privilege and security level of the transaction, and whether
//    		// the transaction is a data access or an instruction access.
//		input wire [2 : 0] S_AXI_AWPROT,
//		// Write address valid. This signal indicates that the master signaling
//    		// valid write address and control information.
//		input wire  S_AXI_AWVALID,
//		// Write address ready. This signal indicates that the slave is ready
//    		// to accept an address and associated control signals.
//		output wire  S_AXI_AWREADY,
//		// Write data (issued by master, acceped by Slave) 
//		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
//		// Write strobes. This signal indicates which byte lanes hold
//    		// valid data. There is one write strobe bit for each eight
//    		// bits of the write data bus.    
//		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
//		// Write valid. This signal indicates that valid write
//    		// data and strobes are available.
//		input wire  S_AXI_WVALID,
//		// Write ready. This signal indicates that the slave
//    		// can accept the write data.
//		output wire  S_AXI_WREADY,
//		// Write response. This signal indicates the status
//    		// of the write transaction.
//		output wire [1 : 0] S_AXI_BRESP,
//		// Write response valid. This signal indicates that the channel
//    		// is signaling a valid write response.
//		output wire  S_AXI_BVALID,
//		// Response ready. This signal indicates that the master
//    		// can accept a write response.
//		input wire  S_AXI_BREADY,
//		// Read address (issued by master, acceped by Slave)
//		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
//		// Protection type. This signal indicates the privilege
//    		// and security level of the transaction, and whether the
//    		// transaction is a data access or an instruction access.
//		input wire [2 : 0] S_AXI_ARPROT,
//		// Read address valid. This signal indicates that the channel
//    		// is signaling valid read address and control information.
//		input wire  S_AXI_ARVALID,
//		// Read address ready. This signal indicates that the slave is
//    		// ready to accept an address and associated control signals.
//		output wire  S_AXI_ARREADY,
//		// Read data (issued by slave)
//		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
//		// Read response. This signal indicates the status of the
//    		// read transfer.
//		output wire [1 : 0] S_AXI_RRESP,
//		// Read valid. This signal indicates that the channel is
//    		// signaling the required read data.
//		output wire  S_AXI_RVALID,
//		// Read ready. This signal indicates that the master can
//    		// accept the read data and response information.
//		input wire  S_AXI_RREADY
		
//    );
    
//    wire           samp_fifo_request;
//    wire           samp_fifo_rst_front;
//    wire           samp_fifo_vld;
//    wire [15:0]    samp_fifo_front;
//    wire           samp_fifo_is_front_fin;
    
//    wire [15:0]    res_fifo_dout;
//    wire           res_fifo_we;
    
//    wire           start_p;
    
//    reg [9:0]addr;
    
//    wire           is_dtp_done;
//    wire [C_S_AXI_DATA_WIDTH-1:0]    start_reg;
//    wire [C_S_AXI_DATA_WIDTH-1:0]    end_reg;
//    wire [C_S_AXI_DATA_WIDTH-1:0]    done_reg;
    
    
//    edge_detector #(
//        .IS_POS(1)
//    ) start_edge(
//        .clk  (clk),
//        .rst_n(rst_n),
//        .din  (start_reg[0]),
//        .eout (start_p)
//    );

//sample_fifo  sample_fifo_inst_0(
//        .clk                        (clk                     ),
//        .rst_n                      (rst_n                   ),
//        .i_samp_fifo_request        (samp_fifo_request       ),
//        .i_samp_fifo_rst_front      (samp_fifo_rst_front     ),
//        .o_samp_fifo_vld            (samp_fifo_vld           ),
//        .o_samp_fifo_front          (samp_fifo_front         ),
//        .o_samp_fifo_is_front_fin   (samp_fifo_is_front_fin  )
//    );

//dtp dtp_inst_0 (
//        .clk                        (clk                     ),
//        .rst_n                      (rst_n                   ),
//        .i_tree_ram_wea             (1'b0                    ),
//        .i_tree_ram_addr            (0                       ),
//        .i_tree_ram_din             (0                       ),
//        .i_tree_ram_ready           (1'b1                    ), 
//        .i_samp_fifo_front          (samp_fifo_front         ),    
//        .i_res_fifo_is_full         (1'b0                    ),
//        .o_res_fifo_we              (res_fifo_we             ),
//        .o_res_fifo_dout            (res_fifo_dout           ),
//        .i_dtp_start                (start_p                 ),
//        .i_dtp_end                  (end_reg[0]              ),
//        .o_is_dtp_done              (is_dtp_done             ),
//        .i_samp_fifo_is_empty       (1'b0                    ),
//        .i_samp_fifo_vld            (samp_fifo_vld           ),
//        .i_samp_fifo_is_front_fin   (samp_fifo_is_front_fin  ),
//        .o_samp_fifo_rst_front      (samp_fifo_rst_front     ),
//        .o_samp_fifo_request        (samp_fifo_request       )
//    );
    
//    assign bram_clka  = clk;
//    assign bram_ena   = 1'b1;
//    assign bram_wea   = {4{res_fifo_we}};
//    assign bram_rsta  = 1'b0;
//    assign bram_dina  = {16'b0, res_fifo_dout};
//    assign bram_addra = {22'b0, addr}<<2;
    
    
//    always@(posedge clk) begin
//        if(!rst_n) begin
//            addr <= 0;
//        end
//        else begin
//            if(start_p | end_reg[0])
//                addr <= 0;
//            else if(res_fifo_we)
//                addr <= addr + 1;
//        end
//    end
    
//    assign done_reg = {31'b0, is_dtp_done};
    
//    regs_bank #(
//		.C_S_AXI_DATA_WIDTH(32),
//		.C_S_AXI_ADDR_WIDTH(7)
//	) reg_bank_inst_0 (
//		.S_AXI_ACLK     (S_AXI_ACLK   ),
//		.S_AXI_ARESETN  (S_AXI_ARESETN),
//		.S_AXI_AWADDR   (S_AXI_AWADDR ),
//		.S_AXI_AWPROT   (S_AXI_AWPROT ),
//		.S_AXI_AWVALID  (S_AXI_AWVALID),
//		.S_AXI_AWREADY  (S_AXI_AWREADY),
//		.S_AXI_WDATA    (S_AXI_WDATA  ),
//		.S_AXI_WSTRB    (S_AXI_WSTRB  ),
//		.S_AXI_WVALID   (S_AXI_WVALID ),
//		.S_AXI_WREADY   (S_AXI_WREADY ),
//		.S_AXI_BRESP    (S_AXI_BRESP  ),
//		.S_AXI_BVALID   (S_AXI_BVALID ),
//		.S_AXI_BREADY   (S_AXI_BREADY ),
//		.S_AXI_ARADDR   (S_AXI_ARADDR ),
//		.S_AXI_ARPROT   (S_AXI_ARPROT ),
//		.S_AXI_ARVALID  (S_AXI_ARVALID),
//		.S_AXI_ARREADY  (S_AXI_ARREADY),
//		.S_AXI_RDATA    (S_AXI_RDATA  ),
//		.S_AXI_RRESP    (S_AXI_RRESP  ),
//		.S_AXI_RVALID   (S_AXI_RVALID ),
//		.S_AXI_RREADY   (S_AXI_RREADY ),
		
//		.start_reg      (start_reg    ),
//		.end_reg        (end_reg      ),
//		.done_reg       (done_reg     )
//	);
    
//endmodule


