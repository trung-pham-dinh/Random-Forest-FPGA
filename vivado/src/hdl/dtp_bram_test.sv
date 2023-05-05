module dtp_bram_test #(
    // parameters
    localparam DTP_BRAM_AWIDTH      = 14
) (
    input                           bram_en_0, // Chip Enable Signal (optional)
    output [31 : 0]                 bram_dout_0, // Data Out Bus (optional)
    input [31 : 0]                  bram_din_0, // Data In Bus (optional)
    input [3 : 0]                   bram_we_0, // Byte Enables (optional)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_0, // Address Signal (required)
    input                           bram_clk_0, // Clock Signal (required)
    input                           bram_rst_0 // Reset Signal (required)
);

    dtp_bram_paper_test your_instance_name (
      .clka (bram_clk_0),    // input wire clka
      .rsta (0),    // input wire rsta
      .ena  (0),      // input wire ena
      .wea  (0),      // input wire [0 : 0] wea
      .addra(0),  // input wire [13 : 0] addra
      .dina (0),    // input wire [31 : 0] dina
      .douta(),  // output wire [31 : 0] douta
      
      .clkb (bram_clk_0),    // input wire clka
      .rstb (bram_rst_0),    // input wire rsta
      .enb  (bram_en_0),      // input wire ena
      .web  (|bram_we_0),      // input wire [0 : 0] wea
      .addrb(bram_addr_0[DTP_BRAM_AWIDTH+2-1:2]),  // input wire [13 : 0] addra
      .dinb (bram_din_0),    // input wire [31 : 0] dina
      .doutb(bram_dout_0)  // output wire [31 : 0] douta
    );
endmodule