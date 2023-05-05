`timescale 1ns / 1ps

module sample_fifo #(
     parameter FIFO_WIDTH = 16
    ,parameter FIFO_DEPTH_BIT = 5 // number of label for classification problem
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

    logic   [FIFO_WIDTH-1:0]            data_in_bram;
    logic   [FIFO_DEPTH_BIT-1:0]        mark_ptr;
    
    logic   [FIFO_DEPTH_BIT:0]          sub_wptr, wptr;
    logic   [FIFO_DEPTH_BIT:0]          sub_rptr, rptr;
    
    logic                               fbit_comp, pointer_equal;    
    logic                               push, count_push;
    
    logic                               almost_full, almost_empty;                      
    logic                               we_counter, we_counter_pipe, re, re_pipe, we_bram;
    logic                               empty_fbit_comp, full_fbit_comp;
    logic                               empty_pointer_equal, full_pointer_equal;
    
    logic   [FIFO_DEPTH_BIT-1:0]        mark_pipe;
    
    c_addsub_0 sub_wpointer (
      .A(wptr),      // input wire [11 : 0] A
      .B(1),      // input wire [11 : 0] B
      .CLK(clk),  // input wire CLK
      .S(sub_wptr)      // output wire [11 : 0] S
    );
    
    c_addsub_0 sub_rpointer (
      .A(rptr),      // input wire [11 : 0] A
      .B(1),      // input wire [11 : 0] B
      .CLK(clk),  // input wire CLK
      .S(sub_rptr)      // output wire [11 : 0] S
    );
    assign empty_fbit_comp = sub_wptr[FIFO_DEPTH_BIT] ^ rptr[FIFO_DEPTH_BIT];  
    assign empty_pointer_equal = (sub_wptr[FIFO_DEPTH_BIT-1:0] ^ rptr[FIFO_DEPTH_BIT-1:0])   ? 0:1;   

    assign full_fbit_comp = wptr[FIFO_DEPTH_BIT] ^ sub_rptr[FIFO_DEPTH_BIT];  
    assign full_pointer_equal = (wptr[FIFO_DEPTH_BIT-1:0] ^ sub_rptr[FIFO_DEPTH_BIT-1:0]) ? 0:1; 
    
    assign fbit_comp = wptr[FIFO_DEPTH_BIT] ^ rptr[FIFO_DEPTH_BIT];  
    assign pointer_equal = (wptr[FIFO_DEPTH_BIT-1:0] ^ rptr[FIFO_DEPTH_BIT-1:0]) ? 0:1; 
    
    always @(*)
    begin
        almost_full = (full_fbit_comp & full_pointer_equal & we_counter_pipe) || (fbit_comp & pointer_equal);
        almost_empty = ((~empty_fbit_comp) & empty_pointer_equal & re_pipe) || ((~fbit_comp) & pointer_equal);
        o_is_full = (fbit_comp & pointer_equal);
        o_empty = ((~fbit_comp) & pointer_equal);
    end
    
    assign re = (~almost_empty) & i_pop;
    assign we_counter = (~almost_full) & i_push;
    assign we_bram = we_counter | push;

    
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
        
    pipeline #(.STAGES(1), .DWIDTH(1), .RST_VAL(1'('d0)))
    we_counter_pipe_inst0
    (
    .clk(clk), 
    .rst_n(rst_n), 
    .in_data(we_counter), 
    .out_data_lst(we_counter_pipe)
    );   
    
    pipeline #(.STAGES(1), .DWIDTH(1), .RST_VAL(1'('d0)))
    re_pipe_inst0
    (
    .clk(clk), 
    .rst_n(rst_n), 
    .in_data(re), 
    .out_data_lst(re_pipe)
    );     

    
    always @(posedge clk)
    begin
        if (!rst_n)
        begin
            push <= 0;
        end
        else
        begin
            push <= i_push;
        end
    end
    
    pipeline #(.STAGES(1), .DWIDTH(FIFO_WIDTH), .RST_VAL(1'('d0)))
    data_pipe_inst0
    (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_rear), 
        .out_data_lst(data_in_bram)
    );
    
    //mark
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            mark_pipe <= 0;
            mark_ptr <= 0;
        end
        else
        begin 
            mark_pipe <= rptr;
            if (i_mark_read_rst)
                mark_ptr <= mark_pipe;
            else
                mark_ptr <= mark_ptr;
        end
    end
endmodule