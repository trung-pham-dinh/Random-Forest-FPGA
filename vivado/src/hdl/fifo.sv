module fifo #(
     parameter WIDTH = 16
    ,parameter ABIT  = 5
) (
     input                      clk
    ,input                      rst_n
        
    ,input                      i_flush
        
    ,input [WIDTH-1:0]          i_rear
    ,input                      i_push
    ,output                     o_is_full

    ,output logic [WIDTH-1:0]   o_front
    ,input                      i_pop
    ,output logic               o_front_vld
    ,output                     o_is_empty
);
    localparam DEPTH = 2**ABIT;

    logic [ABIT:0] wptr,rptr;
    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic wvld,rvld;

//----------------------------------------------------------------------------------------
// Memory
//----------------------------------------------------------------------------------------

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            for(integer i=0; i<DEPTH; i=i+1) begin
                mem[i] <= WIDTH'(0);
            end
        end
        else begin
            if(wvld)
                mem[wptr[ABIT-1:0]] <= i_rear;
            else begin
                for(integer i=0; i<DEPTH; i=i+1) begin
                    mem[i] <= mem[i];
                end
            end
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            o_front <= WIDTH'(0);
        end
        else begin
            if(rvld)
                o_front <= mem[rptr[ABIT-1:0]];
            else begin
                o_front <= o_front;
            end
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            o_front_vld <= 0;
        end
        else begin
            o_front_vld <= rvld;
        end
    end

//----------------------------------------------------------------------------------------
// WRITE
//----------------------------------------------------------------------------------------

    assign o_is_full = ({!wptr[ABIT],wptr[ABIT-1:0]} == rptr);
    assign wvld = i_push & !o_is_full;

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            wptr <= (ABIT+1)'(0);
        end
        else begin
            if(i_flush)
                wptr <= (ABIT+1)'(0);
            else if(wvld)
                wptr <= wptr + 1;
            else
                wptr <= wptr;
        end
    end

//----------------------------------------------------------------------------------------
// READ
//----------------------------------------------------------------------------------------

    assign o_is_empty = (wptr == rptr);
    assign rvld = i_pop & !o_is_empty;

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            rptr <= (ABIT+1)'(0);
        end
        else begin
            if(i_flush)
                rptr <= (ABIT+1)'(0);
            else if(rvld)
                rptr <= rptr + 1;
            else
                rptr <= rptr;
        end
    end
    
endmodule