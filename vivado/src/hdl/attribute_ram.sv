`timescale 1ns / 1ps

module attribute_ram #(
     parameter ATTR_WIDTH        = 16
    ,parameter ATTR_ABIT         = 5
    ,parameter N_DTPS            = 4
    ,localparam RAM_DEPTH        = 2**ATTR_ABIT
    ,localparam STATE_FIFO_WIDTH = 2
) (
     input                              clk
    ,input                              rst_n
    
    ,input                              i_attr_ram_start
    ,input                              i_attr_ram_end

    ,input  [ATTR_WIDTH-1:0]            i_fifo_front
    ,input                              i_fifo_vld
    ,input                              i_fifo_is_empty
    ,input  [ATTR_ABIT-1:0]             i_pop_amount   // i_pop_amount = number of attributes - 1
    ,output logic                       o_fifo_pop
    
    ,output [N_DTPS*ATTR_WIDTH-1:0]     o_attr_ram_dout
    ,input  [N_DTPS*ATTR_ABIT-1:0]      i_attr_ram_sel
    ,input  [N_DTPS-1:0]                i_attr_ram_switch
    ,output                             o_is_attr_ram_avai
    ,output                             o_is_sample_done // active when both FIFO and 2 RAMs are empty
    // simulation
    // ,output [RAM_DEPTH*ATTR_WIDTH-1:0]  attr_ram_0_sim
    // ,output [RAM_DEPTH*ATTR_WIDTH-1:0]  attr_ram_1_sim
    // ,output                             cur_attr_ram_write_sim
    // ,output [STATE_FIFO_WIDTH-1:0]      state_fifo_sim
    // ,output                             use_done_sim
    // ,output                             fill_done_sim
    // ,output [ATTR_ABIT-1:0]             pop_amount_sim
    // ,output [ATTR_ABIT-1:0]             recv_amount_sim
    // ,output                             cur_attr_ram_read_combine_sim
    // ,output [1:0]                       is_attr_ram_avai_read_sim
);
    enum logic [STATE_FIFO_WIDTH-1:0] {STATE_FIFO_IDLE   = STATE_FIFO_WIDTH'('d0),
                                       STATE_FIFO_RST    = STATE_FIFO_WIDTH'('d1),
                                       STATE_FIFO_FILL   = STATE_FIFO_WIDTH'('d2),
                                       STATE_FIFO_DONE   = STATE_FIFO_WIDTH'('d3)} state_fifo, state_fifo_next;


    logic [ATTR_WIDTH-1:0] attr_ram_0 [0:RAM_DEPTH-1];
    logic [ATTR_WIDTH-1:0] attr_ram_1 [0:RAM_DEPTH-1];

    logic [ATTR_ABIT-1:0]           pop_amount,recv_amount;

    logic                           cur_attr_ram_write;

    logic [1:0]                     is_attr_ram_avai_read;
    logic [N_DTPS-1:0]              cur_attr_ram_read;
    logic                           cur_attr_ram_read_combine;
    logic                           is_all_switch;

    logic                           fill_done,use_done;
    logic                           pop_start;

    logic                           fifo_is_empty;
//----------------------------------------------------------------------------------------
// Simulation logic
//----------------------------------------------------------------------------------------

    // generate
    //     for(genvar i=0; i<RAM_DEPTH; i=i+1) begin
    //         assign attr_ram_0_sim[i*ATTR_WIDTH +: ATTR_WIDTH] = attr_ram_0[i];
    //         assign attr_ram_1_sim[i*ATTR_WIDTH +: ATTR_WIDTH] = attr_ram_1[i];
    //     end
    // endgenerate
    
    // assign cur_attr_ram_write_sim = cur_attr_ram_write;
    // assign state_fifo_sim = state_fifo;
    // assign fill_done_sim = fill_done;
    // assign use_done_sim = use_done;
    // assign recv_amount_sim = recv_amount;
    // assign pop_amount_sim = pop_amount;
    // assign cur_attr_ram_read_combine_sim = cur_attr_ram_read_combine;
    // assign is_attr_ram_avai_read_sim = is_attr_ram_avai_read;
//----------------------------------------------------------------------------------------
// RAM
//---------------------------------------------------------------------------------------

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            for(integer i=0; i<RAM_DEPTH; i=i+1) begin
                attr_ram_0[i] <= ATTR_WIDTH'('d0);
                attr_ram_1[i] <= ATTR_WIDTH'('d0);
            end
        end
        else begin
            if(i_fifo_vld) begin
                if(cur_attr_ram_write == 0)
                    attr_ram_0[recv_amount] <= i_fifo_front;
                else
                    attr_ram_1[recv_amount] <= i_fifo_front;
            end
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            recv_amount <= ATTR_ABIT'('d0);
        end
        else begin
            if(fill_done | i_attr_ram_end)
                recv_amount <= ATTR_ABIT'('d0);
            else if(i_fifo_vld)
                recv_amount <= recv_amount + ATTR_ABIT'('d1);
            else
                recv_amount <= recv_amount;
        end
    end



//----------------------------------------------------------------------------------------
// WRITE SIDE
//----------------------------------------------------------------------------------------

    always_ff@(posedge clk) begin
        if(!rst_n) begin
            state_fifo <= STATE_FIFO_IDLE;
        end
        else begin
            state_fifo <= state_fifo_next;
        end
    end

    always_comb begin
        case (state_fifo)
            STATE_FIFO_IDLE: begin
                if(i_attr_ram_start & ~i_fifo_is_empty)
                    state_fifo_next = STATE_FIFO_RST;
                else
                    state_fifo_next = state_fifo;
            end
            STATE_FIFO_RST: begin
                if(i_fifo_is_empty | i_attr_ram_end)
                    state_fifo_next = STATE_FIFO_IDLE;
                else if(!is_attr_ram_avai_read[cur_attr_ram_write])
                    state_fifo_next = STATE_FIFO_FILL;
                else
                    state_fifo_next = STATE_FIFO_DONE;
            end
            STATE_FIFO_FILL: begin
                if(i_attr_ram_end)
                    state_fifo_next = STATE_FIFO_IDLE;
                else if(fill_done)
                    state_fifo_next = STATE_FIFO_DONE;
                else
                    state_fifo_next = state_fifo;
            end
            STATE_FIFO_DONE: begin
                if(o_is_sample_done | i_attr_ram_end) // o_is_sample_done instead of i_fifo_is_empty to prevent FSM go to idle early
                    state_fifo_next = STATE_FIFO_IDLE;
                else if(!is_attr_ram_avai_read[cur_attr_ram_write])
                    state_fifo_next = STATE_FIFO_FILL;
                else
                    state_fifo_next = state_fifo;
            end 
            default: begin
                state_fifo_next = STATE_FIFO_IDLE;
            end
        endcase
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            cur_attr_ram_write <= 0;
        end
        else if((state_fifo == STATE_FIFO_RST) || i_attr_ram_end) begin
            cur_attr_ram_write <= 0;
        end
        else begin
            if(fill_done) begin
                cur_attr_ram_write <= ~cur_attr_ram_write;
            end
            else begin
                cur_attr_ram_write <= cur_attr_ram_write;
            end
        end
    end

    always_ff@(posedge clk) begin
        if(~rst_n) begin
            is_attr_ram_avai_read <= 2'b00;
            fifo_is_empty <= 1'b0;
        end
        else if((state_fifo == STATE_FIFO_RST || state_fifo == STATE_FIFO_IDLE) || i_attr_ram_end) begin
            is_attr_ram_avai_read <= 2'b00;
            fifo_is_empty <= i_fifo_is_empty;
        end
        else begin
            if(fill_done) begin
                is_attr_ram_avai_read[cur_attr_ram_write] <= 1'b1;
                fifo_is_empty <= i_fifo_is_empty;
            end
            else if(use_done) begin
                is_attr_ram_avai_read[cur_attr_ram_read_combine] <= 1'b0;
                fifo_is_empty <= fifo_is_empty;
            end
            else begin
                is_attr_ram_avai_read <= is_attr_ram_avai_read;
                fifo_is_empty <= fifo_is_empty;
            end
        end
    end

    assign fill_done = (state_fifo==STATE_FIFO_FILL) && (recv_amount==i_pop_amount);
    assign use_done = (cur_attr_ram_read_combine ^ cur_attr_ram_read[0]) & is_all_switch;

//                             ___     ___     ___     ___     ___     ___  
//clk                      ___|   |___|   |___|   |___|   |___|   |___|   |
//                                     ___________________________________
//cur_attr_ram_read[0]      ___________|   
//                                             ___________________________
//cur_attr_ram_read[1]      ___________________|
//
//...
//                                                     ___________________
//cur_attr_ram_read[n]      ___________________________|
//                                                             ___________
//cur_attr_ram_read_combine ___________________________________|
//                         ___________                 ___________________ 
//is_all_switch                       |_______________|
//                                                     _______
//use_done                 ___________________________|       |___________

    assign pop_start = (state_fifo==STATE_FIFO_RST || state_fifo==STATE_FIFO_DONE) & !is_attr_ram_avai_read[cur_attr_ram_write];
    
    always_ff@(posedge clk) begin
        if(~rst_n) begin
            o_fifo_pop <= 1'b0;
        end
        else if(i_attr_ram_end)
            o_fifo_pop <= 1'b0;
        else begin
            if(pop_start) begin
                o_fifo_pop <= 1'b1;
            end
            else if (pop_amount == i_pop_amount) begin
                o_fifo_pop <= 1'b0;
            end
            else begin
                o_fifo_pop <= o_fifo_pop;
            end
        end
    end
    always_ff@(posedge clk) begin
        if(~rst_n) begin
            pop_amount <= ATTR_ABIT'('d0);
        end
        else if(i_attr_ram_end)
            pop_amount <= ATTR_ABIT'('d0);
        else begin
            if(o_fifo_pop) begin
                pop_amount <= pop_amount + ATTR_ABIT'('d1);
            end
            else begin
                pop_amount <= ATTR_ABIT'('d0);
            end
        end
    end

//----------------------------------------------------------------------------------------
// READ SIDE
//----------------------------------------------------------------------------------------
    generate
        for(genvar i=0; i<N_DTPS; i=i+1) begin
            assign o_attr_ram_dout[i*ATTR_WIDTH +: ATTR_WIDTH] = 
                                (cur_attr_ram_read[0]==1'b0)? 
                                attr_ram_0[i_attr_ram_sel[i*ATTR_ABIT +: ATTR_ABIT]]
                              : attr_ram_1[i_attr_ram_sel[i*ATTR_ABIT +: ATTR_ABIT]];
        end
    endgenerate

    always_ff@(posedge clk) begin
        if(~rst_n) begin
            cur_attr_ram_read <= N_DTPS'('d0);
        end
        else begin
            for(integer i=0; i<N_DTPS; i=i+1) begin
                if((state_fifo == STATE_FIFO_RST) || i_attr_ram_end)
                    cur_attr_ram_read[i] <= 1'b0;
                else
                    cur_attr_ram_read[i] <= (i_attr_ram_switch[i])? ~cur_attr_ram_read[i]:cur_attr_ram_read[i];
            end
        end
    end

    assign is_all_switch = (cur_attr_ram_read=={N_DTPS{1'b1}}) || (cur_attr_ram_read=={N_DTPS{1'b0}}); // check if all DTPs agree to switch to an Attribute RAM

    assign o_is_attr_ram_avai = is_attr_ram_avai_read[cur_attr_ram_read[0]] & is_all_switch; // if all DTPs agree, check if the switched RAM avai (cur_attr_ram_read[arbitary_idx])
    
    assign o_is_sample_done = (is_attr_ram_avai_read == 2'b00) && fifo_is_empty; // we need this signal because there is a case when DTPs have not agreed to switch and FIFO is empty (while at least 1 att ram has data)

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            cur_attr_ram_read_combine <= 0;
        end
        else if((state_fifo == STATE_FIFO_RST) || i_attr_ram_end) begin
            cur_attr_ram_read_combine <= 0;
        end
        else begin
            cur_attr_ram_read_combine <= (is_all_switch)? cur_attr_ram_read[0]:cur_attr_ram_read_combine;
        end
    end

endmodule
