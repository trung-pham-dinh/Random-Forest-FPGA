`timescale 1ns / 1ps

module sample_fifo #(
     parameter FIFO_WIDTH = 16
    ,parameter FIFO_DEPTH_BIT = 4 // DEPTH_BIT**2 labels
) (
     input                              clk
    ,input                              rst_n

    ,input                              i_flush // empty the FIFO
    ,input                              i_read_rst // reset read pointer
    ,input                              i_mark_read_rst // mark the reset point of read pointer
    ,input                              i_pop
    ,input                              i_push
    ,input [FIFO_WIDTH-1:0]             i_rear
    ,output reg                         o_is_full
    ,output [FIFO_WIDTH-1:0]            o_front
    ,output reg                         o_vld 
    ,output reg                         o_empty
);

    logic   [FIFO_DEPTH_BIT:0]          rptr, wptr, mark_ptr;
    logic   [FIFO_WIDTH-1:0]            data_in_bram;
    
    logic                               fbit_comp, pointer_equal;    
    logic                               push;
                        
    logic                               we_counter, re, we_bram;
    logic                               almost_full, almost_empty;
    logic   [FIFO_DEPTH_BIT:0]          pointer_sub;                        
    
    localparam FIFO_DEPTH = 2**FIFO_DEPTH_BIT;
    localparam FIFO_DEPTH_SUB_1 = FIFO_DEPTH - 1;
    
    assign fbit_comp = wptr[FIFO_DEPTH_BIT] ^ rptr[FIFO_DEPTH_BIT];
    assign pointer_sub = wptr - rptr;
    assign pointer_equal = wptr[FIFO_DEPTH_BIT - 1:0] == rptr[FIFO_DEPTH_BIT - 1:0];
    
        
    always @(*)
    begin
        almost_full = pointer_sub == FIFO_DEPTH_SUB_1 | pointer_sub == FIFO_DEPTH;
        almost_empty = pointer_sub == 1 | pointer_sub == 0;
        o_is_full = fbit_comp & pointer_equal;
        o_empty = (~fbit_comp) & pointer_equal;
    end
    
    assign re = (~almost_empty) & i_pop;
    assign we_counter = (~almost_full) & i_push;
    assign we_bram = (~o_is_full) & i_push;
    
    blk_mem_gen_0 b(
        .clka       (clk),
        .clkb       (clk),
        .addra      (14'(wptr)),
        .addrb      (14'(rptr)),
        .dina       (data_in_bram),
        .doutb      (o_front),
        .wea        (we_bram)
    );
    

    
    // READ_COUNTER
    counter_with_lat #(.WIDTH(FIFO_DEPTH_BIT+1)) count_rptr (
        .clk                (clk),      
        .rst_n              (rst_n),
        .inc                (re), 
        .set_val            ((FIFO_DEPTH_BIT+1)'(mark_ptr)), 
        .set_val_vld        (i_read_rst),
        .clear              (i_flush),
        .dout               (rptr)           
    );
    
    // WRITE COUNTER
    counter_with_lat #(.WIDTH(FIFO_DEPTH_BIT+1)) count_wptr (
        .clk                (clk),       
        .rst_n              (rst_n),
        .inc                (we_counter), 
        .set_val            ((FIFO_DEPTH_BIT+1)'(0)), 
        .set_val_vld        (1'b0),
        .clear              (i_flush),
        .dout               (wptr)    
    );
    
    pipeline #(.STAGES(3), .DWIDTH(1), .RST_VAL(1'('d0)))
    vld_pipe_inst0
    (
        .clk(clk), 
        .rst_n(rst_n), 
        .in_data(re), 
        .out_data_lst(o_vld)
    );
    
    pipeline #(.STAGES(1), .DWIDTH(FIFO_WIDTH), .RST_VAL(1'('d0)))
    data_pipe_inst0
    (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_rear), 
        .out_data_lst(data_in_bram)
    );
    
    pipeline #(.STAGES(1), .DWIDTH(1), .RST_VAL(1'('d0)))
    push_pipe_inst0
    (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_push),
        .out_data_lst(push)
    );
    
    //mark
    always_ff @(posedge clk) begin
        if(!rst_n)
            mark_ptr <= 0;
        else if (i_mark_read_rst)
            mark_ptr <= rptr - 1;
        else
            mark_ptr <= mark_ptr;
    end
endmodule
