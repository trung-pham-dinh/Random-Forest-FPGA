`timescale 1ns/1ps

module pulse2level (
    input clk,rst_n,
    input start_pulse,
    input end_pulse,
    output logic level
);
    logic toggle;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            toggle <= 0;
        end
        else begin
            if(start_pulse & !toggle)
                toggle <= 1;
            else if(end_pulse & toggle)
                toggle <= 0;
            else
                toggle <= toggle;
        end
    end

    always_comb begin 
        if(start_pulse & !toggle)
            level = 1;
        else if(end_pulse & toggle)
            level = 0;
        else
            level = toggle;
    end
endmodule