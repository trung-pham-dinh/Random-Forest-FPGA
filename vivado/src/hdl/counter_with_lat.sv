module counter_with_lat #(
    parameter WIDTH = 13
) (
     input                    clk
    ,input                    rst_n
    
    ,input                    inc // output counter plus 1 when this signal active

    ,input [WIDTH-1:0]        set_val // value to be set on output counter
    ,input                    set_val_vld // output counter will be set to set_val when this signal active

    ,input                    clear // output counter will be 0 if this signal active

    ,output logic [WIDTH-1:0] dout
);
    logic [WIDTH-1:0] accum_val;
    logic bypass;
    logic [15:0] accum_out;

    always_comb begin
        if(!rst_n | clear) begin
            accum_val = WIDTH'('d0);
            bypass = 1;
        end
        else begin
            if(set_val_vld) begin
                accum_val = set_val;
                bypass = 1;
            end
            else if(inc) begin
                accum_val = WIDTH'('d1);
                bypass = 0;
            end
            else begin
                accum_val = WIDTH'('d0);
                bypass = 0;
            end
        end
    end
    
    accum_16 accum_inst (
        .B     (16'(accum_val)),  // input wire [15 : 0] B
        .CLK   (clk      ),  // input wire CLK
        .BYPASS(bypass   ),  // input wire BYPASS
        .Q     (accum_out)   // output wire [15 : 0] Q
    );
    
    assign dout = WIDTH'(accum_out);
endmodule