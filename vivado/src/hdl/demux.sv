module demux#(
     parameter SEL_BIT = 3
    ,parameter WIDTH   = 1
    ,localparam N_OUTPUTS = 2**SEL_BIT
)(
     input [WIDTH-1:0]                  din
    ,input [SEL_BIT-1:0]                sel
    ,output logic [N_OUTPUTS*WIDTH-1:0] dout
);
    always_comb begin
        dout = ((N_OUTPUTS*WIDTH)'(din))<<sel;
    end
endmodule