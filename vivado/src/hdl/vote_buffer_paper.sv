`timescale 1ns / 1ps

module vote_buffer_paper #(
     parameter N_DTPS    = 5
    ,parameter RES_WIDTH = 16
    ,parameter DEPTH_BIT = 10
) (
     input                          clk
    ,input                          rst_n
    ,input                          buffer_rst

    ,input [N_DTPS-1:0]             onehot_sel
    ,input [N_DTPS-1:0]             res_vld
    ,input [N_DTPS*RES_WIDTH-1:0]   res_val

    ,input                          bram_en_ps   // Chip Enable Signal (optional)
    ,output [31 : 0]                bram_dout_ps // Data Out Bus (optional)
    ,input  [31 : 0]                bram_din_ps  // Data In Bus (optional)
    ,input  [3 : 0]                 bram_we_ps   // Byte Enables (optional)
    ,input  [DEPTH_BIT+2-1 : 0]     bram_addr_ps // Address Signal (required)
    ,input                          bram_clk_ps  // Clock Signal (required)
    ,input                          bram_rst_ps  // Reset Signal (required)

    // simulation
    ,output                         res_vld_mux_sim
    ,output [RES_WIDTH-1:0]         res_val_mux_sim
    ,output [DEPTH_BIT-1:0]         waddr_sim
); 

    logic                   res_vld_mux;
    logic [RES_WIDTH-1:0]   res_val_mux;
    logic [DEPTH_BIT-1:0]   waddr;
    
//----------------------------------------------------------------------------------------
// SIMULATION LOGIC
//----------------------------------------------------------------------------------------
    assign res_vld_mux_sim = res_vld_mux;
    assign res_val_mux_sim = res_val_mux;
    assign waddr_sim = waddr;

//----------------------------------------------------------------------------------------
// VOTE BUFFER
//----------------------------------------------------------------------------------------

    always_comb begin
        res_vld_mux = 0;
        res_val_mux = RES_WIDTH'(0);
        for(integer i = 0; i < N_DTPS; i++) begin
            if (onehot_sel == (1 << i)) begin
                res_vld_mux = res_vld[i];
                res_val_mux = res_val[i*RES_WIDTH +: RES_WIDTH];
            end
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            waddr <= DEPTH_BIT'(0);
        end
        else begin
            if(buffer_rst)
                waddr <= DEPTH_BIT'(0);
            else if(res_vld_mux)
                waddr <= waddr + DEPTH_BIT'(1);
            else
                waddr <= waddr;
        end
    end


    vote_bram_paper your_instance_name (
    .clka (clk ),    // input wire clka
    .rsta (1'b0 ),    // input wire rsta
    .ena  (1'b1  ),      // input wire ena
    .wea  (res_vld_mux),      // input wire [0 : 0] wea
    .addra(waddr),  // input wire [9 : 0] addra
    .dina (32'(res_val_mux)),    // input wire [31 : 0] dina
    .douta(),  // output wire [31 : 0] douta

    .clkb (bram_clk_ps                    ),  // input wire clkb
    .rstb (bram_rst_ps                    ),  // input wire rstb
    .enb  (bram_en_ps                     ),  // input wire enb
    .web  (|bram_we_ps                    ),  // input wire [0 : 0] web
    .addrb(bram_addr_ps[DEPTH_BIT+2-1 : 2]),  // input wire [9 : 0] addrb
    .dinb (bram_din_ps                    ),  // input wire [31 : 0] dinb
    .doutb(bram_dout_ps                   )   // output wire [31 : 0] doutb
    );

endmodule