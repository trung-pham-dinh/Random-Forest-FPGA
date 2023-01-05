`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2022 10:07:10 AM
// Design Name: 
// Module Name: vote_bram_test_38
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


module vote_bram_test_38(
  // Uncomment the following to set interface specific parameter on the bus interface.
  (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 64,MEM_SIZE 131072,READ_WRITE_MODE READ_WRITE" *)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A EN" *)
  input bram_ena, // Chip Enable Signal (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A DOUT" *)
  output [63 : 0] bram_douta, // Data Out Bus (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A DIN" *)
  input [63 : 0]  bram_dina, // Data In Bus (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A WE" *)
  input [7 : 0]   bram_wea, // Byte Enables (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A ADDR" *)
  input [16 : 0]  bram_addra, // Address Signal (required)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A CLK" *)
  input bram_clka, // Clock Signal (required)
  (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_A RST" *)
  input bram_rsta // Reset Signal (required)
    );
    wire wea;
    
    assign wea = |bram_wea;
    
    bram_38 your_instance_name (
      .clka(bram_clka),    // input wire clka
      .rsta(bram_rsta),            // input wire rsta
      .ena(bram_ena),      // input wire ena
      .wea(wea),      // input wire [0 : 0] wea
      .addra(bram_addra[16:3]),  // input wire [13 : 0] addra
      .dina(bram_dina[37:0]),    // input wire [37 : 0] dina
      .douta(bram_douta[37:0])  // output wire [37 : 0] douta
    );
endmodule
