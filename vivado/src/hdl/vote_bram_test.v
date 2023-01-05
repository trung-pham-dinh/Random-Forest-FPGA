`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2022 08:47:41 PM
// Design Name: 
// Module Name: vote_bram_test
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


module vote_bram_test#(
    parameter C_S_AXI_ADDR_WIDTH = 7,
    parameter C_S_AXI_DATA_WIDTH = 32
)(
  // Uncomment the following to set interface specific parameter on the bus interface.
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A EN" *)
  input bram_ena, // Chip Enable Signal (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A DOUT" *)
  output [31 : 0] bram_douta, // Data Out Bus (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A DIN" *)
  input [31 : 0]  bram_dina, // Data In Bus (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A WE" *)
  input [3 : 0]   bram_wea, // Byte Enables (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A ADDR" *)
  input [31 : 0]  bram_addra, // Address Signal (required)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A CLK" *)
  input bram_clka // Clock Signal (required)
//  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A RST" *)
//  input bram_rsta, // Reset Signal (required)
    );
    
    
    reg [15:0] addr;
    wire wea;
    
    assign wea = |bram_wea;
    
    vote_bram your_instance_name (
      .clka(bram_clka),    // input wire clka
      .ena(bram_ena),      // input wire ena
      .wea(wea),      // input wire [0 : 0] wea
      .addra(bram_addra[15:2]),  // input wire [13 : 0] addra
      .dina(bram_dina),    // input wire [31 : 0] dina
      .douta(bram_douta)  // output wire [31 : 0] douta
    );
endmodule
