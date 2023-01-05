module edge_detector #(
    parameter IS_POS = 1
) (
     input  clk
    ,input  rst_n
    ,input  din
    ,output eout
);
    logic pipe;

    generate
        if(IS_POS==1) begin
            assign eout = ~pipe & din;
        end
        else begin
            assign eout = pipe & ~din;
        end
    endgenerate

    always_ff @(posedge clk) begin
        if(!rst_n)
            pipe <= 0;
        else
            pipe <= din;
    end
    
endmodule