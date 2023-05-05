`timescale 1ns / 1ps

module vote_buffer_paper #(
     parameter RES_WIDTH = 16
    ,parameter DEPTH_BIT = 13
) (
     input                          clk
    ,input                          rst_n
    ,input                          i_buffer_rst

    ,input                          i_res_vld
    ,input [RES_WIDTH-1:0]          i_res_val

    ,input                          bram_en_ps   // Chip Enable Signal (optional)
    ,output [31 : 0]                bram_dout_ps // Data Out Bus (optional)
    ,input  [31 : 0]                bram_din_ps  // Data In Bus (optional)
    ,input  [3 : 0]                 bram_we_ps   // Byte Enables (optional)
    ,input  [DEPTH_BIT+2-1 : 0]     bram_addr_ps // Address Signal (required)
    ,input                          bram_clk_ps  // Clock Signal (required)
    ,input                          bram_rst_ps  // Reset Signal (required)

    // simulation
    ,output                         res_vld_sim
    ,output [RES_WIDTH-1:0]         res_val_sim
    ,output [DEPTH_BIT-1:0]         vote_slot_sim
); 

    logic [DEPTH_BIT-1:0]   vote_slot;
    logic                   res_vld;
    logic [RES_WIDTH-1:0]   res_val;
//----------------------------------------------------------------------------------------
// SIMULATION LOGIC
//----------------------------------------------------------------------------------------

    assign res_vld_sim = res_vld;
    assign res_val_sim = res_val;
    assign vote_slot_sim = vote_slot;

//----------------------------------------------------------------------------------------
// VOTE BUFFER
//----------------------------------------------------------------------------------------


    counter_with_lat #(
        .WIDTH(DEPTH_BIT)
    ) counter_inst (
        .clk         (clk            ),   
        .rst_n       (rst_n          ),   
        .inc         (i_res_vld      ),   
        .set_val     (0              ),   
        .set_val_vld (0              ),       
        .clear       (i_buffer_rst   ),   
        .dout        (vote_slot      )   
    );

    pipeline #(.STAGES(1), .DWIDTH(1), .RST_VAL(1'('d0))) 
        res_vld_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_res_vld), 
        .out_data(),
        .out_data_lst(res_vld)
        );
    pipeline #(.STAGES(1), .DWIDTH(RES_WIDTH), .RST_VAL(RES_WIDTH'('d0))) 
        res_val_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_res_val), 
        .out_data(),
        .out_data_lst(res_val)
        );


    vote_bram_paper vote_bram_inst (
    .clka (clk             ),    // input wire clka
    .rsta (1'b0            ),    // input wire rsta
    .ena  (1'b1            ),      // input wire ena
    .wea  (res_vld         ),      // input wire [0 : 0] wea
    .addra(vote_slot       ),  // input wire [12 : 0] addra
    .dina (32'(res_val)    ),    // input wire [31 : 0] dina
    .douta(),  // output wire [31 : 0] douta

    .clkb (bram_clk_ps                    ),  // input wire clkb
    .rstb (bram_rst_ps                    ),  // input wire rstb
    .enb  (bram_en_ps                     ),  // input wire enb
    .web  (|bram_we_ps                    ),  // input wire [0 : 0] web
    .addrb(bram_addr_ps[DEPTH_BIT+2-1 : 2]),  // input wire [12 : 0] addrb
    .dinb (bram_din_ps                    ),  // input wire [31 : 0] dinb
    .doutb(bram_dout_ps                   )   // output wire [31 : 0] doutb
    );

endmodule