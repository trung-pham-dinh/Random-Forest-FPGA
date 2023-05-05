`timescale 1ns / 1ps

module count1bit #(
     parameter DATA_WIDTH = 5
    ,parameter COUNT_BIT  = 3
) (
     input clk
    ,input rst_n
    ,input  [DATA_WIDTH-1:0] din
    ,input                   din_vld
    ,output [COUNT_BIT-1:0]  dout
    ,output                  dout_vld
);

    logic [DATA_WIDTH-1:0] din_pipe [0:DATA_WIDTH-3];
    logic [COUNT_BIT-1:0]  add_pipe [0:DATA_WIDTH-3];


    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            for(integer i=0; i<DATA_WIDTH-2; i=i+1) begin
                din_pipe[i] <= DATA_WIDTH'(0);
            end
        end
        else begin
            din_pipe[0] <= din;
            for(integer i=1; i<DATA_WIDTH-2; i=i+1) begin
                din_pipe[i] <= din_pipe[i-1];
            end
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            for(integer i=0; i<DATA_WIDTH-2; i=i+1) begin
                add_pipe[i] <= COUNT_BIT'(0);
            end
        end
        else begin
            add_pipe[0] <= COUNT_BIT'(din[0]) + COUNT_BIT'(din[1]);
            for(integer i=1; i<DATA_WIDTH-2; i=i+1) begin
                add_pipe[i] <= add_pipe[i-1] + COUNT_BIT'(din_pipe[i-1][i+1]);
            end
        end        
    end

    assign dout = add_pipe[DATA_WIDTH-3] + COUNT_BIT'(din_pipe[DATA_WIDTH-3][DATA_WIDTH-1]);

    pipeline #(.STAGES(DATA_WIDTH-2), .DWIDTH(1), .RST_VAL(1'('d0))) 
        vld_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(din_vld), 
        .out_data(),
        .out_data_lst(dout_vld)
        );


    
endmodule