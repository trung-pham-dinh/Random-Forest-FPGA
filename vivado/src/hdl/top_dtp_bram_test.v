module top_dtp_bram_test #(
    localparam DTP_BRAM_AWIDTH      = 14
) (
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 EN" *)
    input                           bram_en_0, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 DOUT" *)
    output [31 : 0]                 bram_dout_0, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 DIN" *)
    input [31 : 0]                  bram_din_0, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 WE" *)
    input [3 : 0]                   bram_we_0, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_0, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 CLK" *)
    input                           bram_clk_0, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 RST" *)
    input                           bram_rst_0 // Reset Signal (required)
);

    dtp_bram_test uut (
        .bram_en_0   (bram_en_0  ),   
        .bram_dout_0 (bram_dout_0),       
        .bram_din_0  (bram_din_0 ),       
        .bram_we_0   (bram_we_0  ),   
        .bram_addr_0 (bram_addr_0),       
        .bram_clk_0  (bram_clk_0 ),   
        .bram_rst_0  (bram_rst_0 )   
    );
    
endmodule