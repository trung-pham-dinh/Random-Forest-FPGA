`timescale 1ns / 1ps

module attribute_ram #(
     parameter ATTR_WIDTH        = 16
    ,parameter ATTR_ABIT         = 5
    ,parameter N_DTPS            = 4
    ,parameter POP_AMOUNT        = 4 // unit: attributes/sample
    ,localparam RAM_DEPTH        = 2**ATTR_ABIT
    ,localparam STATE_FIFO_WIDTH = 2
) (
     input                              clk
    ,input                              rst_n
    
    ,input                              i_att_ram_start
    ,input                              i_att_ram_end

    ,input  [ATTR_WIDTH-1:0]            i_fifo_front
    ,input                              i_fifo_vld
    ,input                              i_fifo_is_empty
    ,output logic                       o_fifo_pop
    
    ,output [N_DTPS*ATTR_WIDTH-1:0]     o_attr_ram_dout
    ,input  [N_DTPS*ATTR_ABIT-1:0]      i_attr_ram_sel
    ,input  [N_DTPS-1:0]                i_att_ram_switch
    ,output                             o_is_att_ram_avai
    ,output                             o_is_sample_done // active when both FIFO and 2 RAMs are empty
    // simulation
    ,output [RAM_DEPTH*ATTR_WIDTH-1:0]  att_ram_0_sim
    ,output [RAM_DEPTH*ATTR_WIDTH-1:0]  att_ram_1_sim
    ,output                             cur_att_ram_write_sim
    ,output [STATE_FIFO_WIDTH-1:0]      state_fifo_sim
    ,output                             use_done_sim
    ,output                             fill_done_sim
    ,output [ATTR_ABIT-1:0]             pop_amount_sim
    ,output [ATTR_ABIT-1:0]             recv_amount_sim
    ,output                             cur_att_ram_read_combine_sim
);
    enum logic [STATE_FIFO_WIDTH-1:0] {STATE_FIFO_IDLE   = STATE_FIFO_WIDTH'('d0),
                                       STATE_FIFO_RST    = STATE_FIFO_WIDTH'('d1),
                                       STATE_FIFO_FILL   = STATE_FIFO_WIDTH'('d2),
                                       STATE_FIFO_DONE   = STATE_FIFO_WIDTH'('d3)} state_fifo, state_fifo_next;


    logic [ATTR_WIDTH-1:0] att_ram_0 [0:RAM_DEPTH-1];
    logic [ATTR_WIDTH-1:0] att_ram_1 [0:RAM_DEPTH-1];

    logic [ATTR_ABIT-1:0]           pop_amount,recv_amount;

    logic                           cur_att_ram_write;

    logic [1:0]                     is_att_ram_avai_read;
    logic [N_DTPS-1:0]              cur_att_ram_read;
    logic                           cur_att_ram_read_combine;
    logic                           is_all_switch;

    logic                           fill_done,use_done;
    logic                           pop_start;

    logic                           fifo_is_empty;
//----------------------------------------------------------------------------------------
// Simulation logic
//---------------------------------------------------------------------------------------

    generate
        for(genvar i=0; i<RAM_DEPTH; i=i+1) begin
            assign att_ram_0_sim[i*ATTR_WIDTH +: ATTR_WIDTH] = att_ram_0[i];
            assign att_ram_1_sim[i*ATTR_WIDTH +: ATTR_WIDTH] = att_ram_1[i];
        end
    endgenerate
    
    assign cur_att_ram_write_sim = cur_att_ram_write;
    assign state_fifo_sim = state_fifo;
    assign fill_done_sim = fill_done;
    assign use_done_sim = use_done;
    assign recv_amount_sim = recv_amount;
    assign pop_amount_sim = pop_amount;
    assign cur_att_ram_read_combine_sim = cur_att_ram_read_combine;
//----------------------------------------------------------------------------------------
// RAM
//---------------------------------------------------------------------------------------

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            for(integer i=0; i<RAM_DEPTH; i=i+1) begin
                att_ram_0[i] <= ATTR_WIDTH'('d0);
                att_ram_1[i] <= ATTR_WIDTH'('d0);
            end
        end
        else begin
            if(i_fifo_vld) begin
                if(cur_att_ram_write == 0)
                    att_ram_0[recv_amount] <= i_fifo_front;
                else
                    att_ram_1[recv_amount] <= i_fifo_front;
            end
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            recv_amount <= ATTR_ABIT'('d0);
        end
        else begin
            if(fill_done | i_att_ram_end)
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
                if(i_att_ram_start & ~i_fifo_is_empty)
                    state_fifo_next = STATE_FIFO_RST;
                else
                    state_fifo_next = state_fifo;
            end
            STATE_FIFO_RST: begin
                if(i_fifo_is_empty | i_att_ram_end)
                    state_fifo_next = STATE_FIFO_IDLE;
                else if(!is_att_ram_avai_read[cur_att_ram_write])
                    state_fifo_next = STATE_FIFO_FILL;
                else
                    state_fifo_next = STATE_FIFO_DONE;
            end
            STATE_FIFO_FILL: begin
                if(i_att_ram_end)
                    state_fifo_next = STATE_FIFO_IDLE;
                else if(fill_done)
                    state_fifo_next = STATE_FIFO_DONE;
                else
                    state_fifo_next = state_fifo;
            end
            STATE_FIFO_DONE: begin
                if(i_fifo_is_empty | i_att_ram_end)
                    state_fifo_next = STATE_FIFO_IDLE;
                else if(!is_att_ram_avai_read[cur_att_ram_write])
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
            cur_att_ram_write <= 0;
        end
        else if((state_fifo == STATE_FIFO_RST) || i_att_ram_end) begin
            cur_att_ram_write <= 0;
        end
        else begin
            if(fill_done) begin
                cur_att_ram_write <= ~cur_att_ram_write;
            end
            else begin
                cur_att_ram_write <= cur_att_ram_write;
            end
        end
    end

    always_ff@(posedge clk) begin
        if(~rst_n) begin
            is_att_ram_avai_read <= 2'b00;
            fifo_is_empty <= 1'b1;
        end
        else if((state_fifo == STATE_FIFO_RST || state_fifo == STATE_FIFO_IDLE) || i_att_ram_end) begin
            is_att_ram_avai_read <= 2'b00;
            fifo_is_empty <= i_fifo_is_empty;
        end
        else begin
            if(fill_done) begin
                is_att_ram_avai_read[cur_att_ram_write] <= 1'b1;
                fifo_is_empty <= i_fifo_is_empty;
            end
            else if(use_done) begin
                is_att_ram_avai_read[cur_att_ram_read_combine] <= 1'b0;
                fifo_is_empty <= fifo_is_empty;
            end
            else begin
                is_att_ram_avai_read <= is_att_ram_avai_read;
                fifo_is_empty <= fifo_is_empty;
            end
        end
    end

    assign fill_done = (state_fifo==STATE_FIFO_FILL) && (recv_amount==POP_AMOUNT-1);
    assign use_done = (cur_att_ram_read_combine ^ cur_att_ram_read[0]) & is_all_switch;

//                             ___     ___     ___     ___     ___     ___  
//clk                      ___|   |___|   |___|   |___|   |___|   |___|   |
//                                     ___________________________________
//cur_att_ram_read[0]      ___________|   
//                                             ___________________________
//cur_att_ram_read[1]      ___________________|
//
//...
//                                                     ___________________
//cur_att_ram_read[n]      ___________________________|
//                                                             ___________
//cur_att_ram_read_combine ___________________________________|
//                         ___________                 ___________________ 
//is_all_switch                       |_______________|
//                                                     _______
//use_done                 ___________________________|       |___________

    assign pop_start = (state_fifo==STATE_FIFO_RST || state_fifo==STATE_FIFO_DONE) & !is_att_ram_avai_read[cur_att_ram_write];
    always_ff@(posedge clk) begin
        if(~rst_n) begin
            pop_amount <= ATTR_ABIT'('d0);
            o_fifo_pop <= 1'b0;
        end
        else begin
            if(pop_start) begin
                pop_amount <= ATTR_ABIT'('d0);
                o_fifo_pop <= 1;
            end
            else if ((state_fifo==STATE_FIFO_FILL) && (pop_amount!=POP_AMOUNT-1)) begin
                pop_amount <= pop_amount + 1;
                o_fifo_pop <= 1;
            end
            else begin
                pop_amount <= pop_amount;
                o_fifo_pop <= 0;
            end
        end
    end

//    assign o_fifo_pop = (state_fifo == STATE_FIFO_FILL);

//----------------------------------------------------------------------------------------
// READ SIDE
//----------------------------------------------------------------------------------------
    generate
        for(genvar i=0; i<N_DTPS; i=i+1) begin
            assign o_attr_ram_dout[i*ATTR_WIDTH +: ATTR_WIDTH] = 
                                (cur_att_ram_read[0]==1'b0)? 
                                att_ram_0[i_attr_ram_sel[i*ATTR_ABIT +: ATTR_ABIT]]
                              : att_ram_1[i_attr_ram_sel[i*ATTR_ABIT +: ATTR_ABIT]];
        end
    endgenerate

    always_ff@(posedge clk) begin
        if(~rst_n) begin
            cur_att_ram_read <= N_DTPS'('d0);
        end
        else begin
            for(integer i=0; i<N_DTPS; i=i+1) begin
                if((state_fifo == STATE_FIFO_RST) || i_att_ram_end)
                    cur_att_ram_read[i] <= 1'b0;
                else
                    cur_att_ram_read[i] <= (i_att_ram_switch[i])? ~cur_att_ram_read[i]:cur_att_ram_read[i];
            end
        end
    end

    assign is_all_switch = (cur_att_ram_read=={N_DTPS{1'b1}}) || (cur_att_ram_read=={N_DTPS{1'b0}}); // check if all DTPs agree to switch to an Attribute RAM

    assign o_is_att_ram_avai = is_att_ram_avai_read[cur_att_ram_read[0]] & is_all_switch; // if all DTPs agree, check if the switched RAM avai (cur_att_ram_read[arbitary_idx])
    
    assign o_is_sample_done = (is_att_ram_avai_read == 2'b00) && fifo_is_empty; // we need this signal because there is a case when DTPs have not agreed to switch and FIFO is empty (while at least 1 att ram has data)

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            cur_att_ram_read_combine <= 0;
        end
        else if((state_fifo == STATE_FIFO_RST) || i_att_ram_end) begin
            cur_att_ram_read_combine <= 0;
        end
        else begin
            cur_att_ram_read_combine <= (is_all_switch)? cur_att_ram_read[0]:cur_att_ram_read_combine;
        end
    end

endmodule
