module comparator_int #(// din1 <= din2
    localparam WIDTH = 24
)( 
     input              clk
    ,input              rst_n
    ,input [WIDTH-1:0]  din1
    ,input [WIDTH-1:0]  din2
    ,output[7:0]        comp_out

    ,output [WIDTH-1:0] dout
);
//----------------------------------------------------------------------------------------
// Comparator
//----------------------------------------------------------------------------------------

    logic [WIDTH-1:0]    din1_pipe,din2_pipe;

    dtp_int_sub sub_inst (
        .A(din1),      // input wire [23 : 0] A
        .B(din2),      // input wire [23 : 0] B
        .CLK(clk),  // input wire CLK
        .S(dout)      // output wire [23 : 0] S
    );

    pipeline #(.STAGES(2), .DWIDTH(WIDTH), .RST_VAL(WIDTH'(0))) 
        din1_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(din1), 
        .out_data(),
        .out_data_lst(din1_pipe)
        );
    pipeline #(.STAGES(2), .DWIDTH(WIDTH), .RST_VAL(WIDTH'(0))) 
        din2_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(din2), 
        .out_data(),
        .out_data_lst(din2_pipe)
        );


    assign comp_out[0] = dout[23] || (din1_pipe==din2_pipe);
    assign comp_out[7:1] = 0;

    
endmodule