`timescale 1ns/1ps

module pipeline #(
    parameter STAGES  = 1, // STAGES >= 1
    parameter DWIDTH  = 1,
    parameter RST_VAL = 1'b0
) (
    input                       clk,
    input                       rst_n,
    input  [DWIDTH-1:0]         in_data,
    output [DWIDTH*STAGES-1:0]  out_data,
    output [DWIDTH-1:0]         out_data_lst
);
    logic [DWIDTH*STAGES-1:0] pipe_data;
    
    
    assign out_data = pipe_data;
    assign out_data_lst = pipe_data[(STAGES-1)*DWIDTH +: DWIDTH];

    always_ff @(posedge clk) begin
        if(!rst_n) begin: PIPE_RST
            for(integer i=0; i<STAGES; i=i+1) begin
                pipe_data[i*DWIDTH +: DWIDTH] <= RST_VAL;
            end
        end
        else begin: PIPE_ASSIGN
            pipe_data[0 +: DWIDTH] <= in_data;
            for(integer i=0; i<STAGES-1; i=i+1) begin
                pipe_data[(i+1)*DWIDTH +: DWIDTH] <= pipe_data[i*DWIDTH +: DWIDTH];
            end
        end
    end
endmodule