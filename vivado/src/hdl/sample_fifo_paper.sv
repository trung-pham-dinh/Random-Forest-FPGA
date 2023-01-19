module sample_fifo_paper #(
     parameter WIDTH = 16
    ,parameter DEPTH_BIT = 13
) (
     input                      clk
    ,input                      rst_n
  
    ,input                      i_pop
    ,output logic [WIDTH-1:0]   o_front
    ,output                     o_vld
    ,output logic               o_is_empty
  
    ,input                      i_ptr_rst
  
    ,input [DEPTH_BIT-1:0]      i_thsh_val // = number of elements - 1
    ,input                      i_thsh_vld
    ,output                     o_thsh_done

    ,input                      bram_en_ps   // Chip Enable Signal (optional)
    ,output [31 : 0]            bram_dout_ps // Data Out Bus (optional)
    ,input  [31 : 0]            bram_din_ps  // Data In Bus (optional)
    ,input  [3 : 0]             bram_we_ps   // Byte Enables (optional)
    ,input  [DEPTH_BIT+2-1 : 0] bram_addr_ps // Address Signal (required)
    ,input                      bram_clk_ps  // Clock Signal (required)
    ,input                      bram_rst_ps  // Reset Signal (required)

    // simulation
    // ,output [DEPTH_BIT-1:0]     rptr_sim
);
    logic [DEPTH_BIT-1:0] rptr;
    logic [WIDTH-1:0]   bram_dout;
    logic               data_vld;
    logic [3:0]         vld_pipe;

//----------------------------------------------------------------------------------------
// Simulation logic
//----------------------------------------------------------------------------------------

    // assign rptr_sim = rptr;

//----------------------------------------------------------------------------------------
// MEMORY
//----------------------------------------------------------------------------------------

    logic [WIDTH-1:0] bram_dout_ps_temp;

    sample_bram sample_bram_inst0 (
    .clka (clk        ),    // input wire clka
    .rsta (1'b0       ),    // input wire rsta
    .ena  (1'b1       ),    // input wire ena
    .wea  (1'b0       ),    // input wire [0 : 0] wea
    .addra(rptr       ),    // input wire [12 : 0] addra
    .dina (WIDTH'('d0)),    // input wire [15 : 0] dina
    .douta(bram_dout  ),    // output wire [15 : 0] douta

    .clkb (bram_clk_ps ),    // input wire clkb
    .rstb (bram_rst_ps ),    // input wire rstb
    .enb  (bram_en_ps  ),    // input wire enb
    .web  (|bram_we_ps ),    // input wire [0 : 0] web
    .addrb(bram_addr_ps[DEPTH_BIT+2-1 : 2]),    // input wire [12 : 0] addrb
    .dinb (bram_din_ps[WIDTH-1:0]),    // input wire [15 : 0] dinb
    .doutb(bram_dout_ps_temp)     // output wire [15 : 0] doutb
    );
    assign bram_dout_ps = 32'(bram_dout_ps_temp);

    always_ff @( posedge clk ) begin
        if(!rst_n)
            o_front <= 0;
        else
            o_front <= (i_ptr_rst)? 0:bram_dout;
    end
//----------------------------------------------------------------------------------------
// COUNTER
//----------------------------------------------------------------------------------------
    assign data_vld = i_pop & !o_is_empty;
    
    counter_with_lat #(
        .WIDTH(DEPTH_BIT)
    ) counter_inst(
        .clk         (clk        ),   
        .rst_n       (rst_n      ),   
        .inc         (data_vld),   
        .set_val     (0          ),   
        .set_val_vld (0          ),       
        .clear       (i_ptr_rst  ),   
        .dout        (rptr       )   
    );

    pipeline #(.STAGES(4), .DWIDTH(1), .RST_VAL(1'('d0)))
        vld_pipe_inst0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(data_vld), 
        .out_data(vld_pipe),
        .out_data_lst(o_vld)
        );



//----------------------------------------------------------------------------------------
// EMPTY LOGIC
//----------------------------------------------------------------------------------------
    logic [16:0] thsh_sub_1;
    logic empty_cond;

    sample_int_sub sub_1_inst (
    .A  (17'(i_thsh_val)),      // input wire [16 : 0] A
    .B  (17'd1),      // input wire [16 : 0] B
    .CLK(clk),  // input wire CLK
    .S  (thsh_sub_1)      // output wire [16 : 0] S
    );

    pipeline #(.STAGES(2), .DWIDTH(1), .RST_VAL(1'('d0)))
        thsh_vld_pipe
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_thsh_vld), 
        .out_data(),
        .out_data_lst(o_thsh_done)
    );

    assign empty_cond = (rptr == (DEPTH_BIT)'(thsh_sub_1) && (vld_pipe[0] & data_vld))
                     || (rptr == (DEPTH_BIT)'(i_thsh_val) && (!vld_pipe[0] & data_vld));

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            o_is_empty <= 0;
        end
        else begin
            if(i_ptr_rst)
                o_is_empty <= 0;
            else if(empty_cond)
                o_is_empty <= 1;
            else
                o_is_empty <= o_is_empty;
        end
    end
endmodule