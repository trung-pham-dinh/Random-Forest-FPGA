`timescale 1ns / 1ps

module accumulator_paper #(
     parameter N_DTPS     = 5 // number of DTPs (in other word, number of input FIFO)
    ,parameter FIFO_WIDTH = 16
    ,parameter FIFO_ABIT  = 5
    ,parameter N_LABELS   = 10 // number of label for classification problem
) (
     input                                  clk
    ,input                                  rst_n

    ,input                                  i_is_clf // is classification ?
    ,input                                  i_dtp_fin // this signal is a pulse. When active, accumulation results will be pushed into clf or rgs FIFOs
    ,output                                 o_is_accum_avai

    // input FIFOs      
    ,input  [N_DTPS-1:0]                    i_in_fifo_push // each bit corresponding to an input FIFO
    ,input  [N_DTPS*FIFO_WIDTH-1:0]         i_in_fifo_rear // each FIFO_WIDTH bits corresponding to an input FIFO
    ,output [N_DTPS-1:0]                    o_in_fifo_is_full // each bit indicates if coressponding input FIFO is full
    ,input                                  i_in_fifo_flush


    // output classification registers
    ,output logic [N_LABELS*FIFO_WIDTH-1:0] o_clf_accum_reg // each FIFO_WIDTH bits corresponding to a classification register
    // output regression register
    ,output logic [FIFO_WIDTH-1:0]          o_rgs_accum_reg
    ,output                                 o_accum_reg_vld


    // Simulation
    ,output [FIFO_WIDTH*N_LABELS-1:0]       clf_accum_out_sim
);

    logic [FIFO_WIDTH-1:0]         in_fifo_front [0:N_DTPS-1];
    logic [N_DTPS-1:0]             in_fifo_front_vld;
    logic [N_DTPS-1:0]             in_fifo_pop;
    logic [N_DTPS-1:0]             in_fifo_is_empty;

    logic [16-1:0]                 vote_loc [0:N_DTPS-1];

    logic [N_DTPS-1:0]             vote_indices [0:N_LABELS-1];
    logic [N_DTPS-1:0]             vote_indices_reg [0:N_LABELS-1];

    logic [2:0]                    vote_amount [0:N_LABELS-1];
    logic [FIFO_WIDTH-1:0]         clf_accum_out [0:N_LABELS-1];

    logic                          clf_accum_reg_vld, rgs_accum_reg_vld;
//----------------------------------------------------------------------------------------
// Simulation logic
//----------------------------------------------------------------------------------------

    // logic                           clk=0;
    // logic                           rst_n=0;

    // logic                           i_is_clf=1;

    // logic                           i_dtp_fin=0;
    // logic                           o_is_accum_avai;

    // logic [N_DTPS-1:0]              i_in_fifo_push=0;
    // logic [N_DTPS*FIFO_WIDTH-1:0]   i_in_fifo_rear=0;
    // logic [N_DTPS-1:0]              o_in_fifo_is_full;
    // logic                           i_in_fifo_flush=0;
    
    // logic [N_LABELS*FIFO_WIDTH-1:0] o_clf_accum_reg;
    // logic [FIFO_WIDTH-1:0]          o_rgs_accum_reg;
    // logic                           o_accum_reg_vld;

    
    
    // logic [FIFO_WIDTH-1:0]          o_clf_accum_reg_sim [0:N_LABELS-1];

    generate
        for(genvar l=0; l<N_LABELS; l=l+1) begin
            assign clf_accum_out_sim[l*FIFO_WIDTH+:FIFO_WIDTH] = clf_accum_out[l];
        end
    endgenerate

    // generate
    //     for(genvar l=0; l<N_LABELS; l=l+1) begin
    //         assign o_clf_accum_reg_sim[l] = o_clf_accum_reg[l*FIFO_WIDTH +: FIFO_WIDTH];
    //     end
    // endgenerate
    
    // always #5 clk=~clk;

    // logic [FIFO_WIDTH-1:0] clf_accum_sim [0:N_LABELS-1];
    // logic [FIFO_WIDTH-1:0] rgs_accum_sim;

    // initial begin
    //     #50;
    //     rst_n <= 1;
    //     #10;

    //     for (integer s=0; s <4; s=s+1) begin
    //         for(integer k=0; k<N_LABELS; k=k+1) begin
    //             clf_accum_sim[k] <= 0;
    //         end
    //         rgs_accum_sim <= 0;

    //         for(integer i=0; i<10; i=i+1) begin
    //             i_in_fifo_push <= {N_DTPS{1'b1}};

    //             for(integer j=0; j<N_DTPS; j=j+1) begin
    //                 i_in_fifo_rear[j*FIFO_WIDTH +: FIFO_WIDTH] <= $urandom_range(0,N_LABELS-1);
    //             end
    //             #1;

    //             for(integer k=0; k<N_DTPS; k=k+1) begin
    //                 if(i_is_clf)
    //                     clf_accum_sim[i_in_fifo_rear[k*FIFO_WIDTH +: FIFO_WIDTH]] = clf_accum_sim[i_in_fifo_rear[k*FIFO_WIDTH +: FIFO_WIDTH]] + 1;
    //                 else
    //                     rgs_accum_sim = rgs_accum_sim + i_in_fifo_rear[k*FIFO_WIDTH +: FIFO_WIDTH];
    //             end

    //             #9;
    //         end
    //         i_in_fifo_push <= {N_DTPS{1'b0}};
    //         i_dtp_fin <= 1;
    //         #10;
    //         i_dtp_fin <= 0;
    //         #20; 
    //     end

    // end

//----------------------------------------------------------------------------------------
// N_DTPs x FIFOs
//----------------------------------------------------------------------------------------
    generate
        for(genvar i=0; i<N_DTPS; i=i+1) begin
            fifo #(
                .WIDTH(FIFO_WIDTH),
                .ABIT (FIFO_ABIT)
            ) fifo_inst (
                .clk        (clk                                       ),    
                .rst_n      (rst_n                                     ),    

                .i_flush    (i_in_fifo_flush                           ), 

                .i_rear     (i_in_fifo_rear[i*FIFO_WIDTH +: FIFO_WIDTH]),    
                .i_push     (i_in_fifo_push[i]                         ),
                .o_is_full  (o_in_fifo_is_full[i]                      ), 

                .o_front    (in_fifo_front[i]                          ),    
                .i_pop      (in_fifo_pop[i]                            ),    
                .o_front_vld(in_fifo_front_vld[i]                      ),
                .o_is_empty (in_fifo_is_empty[i]                       )
            );

            assign in_fifo_pop[i] = !in_fifo_is_empty[i];
        end
    endgenerate

    logic is_dtp_fin;
    logic upd_and_rst;

    assign upd_and_rst = is_dtp_fin & (in_fifo_is_empty == {N_DTPS{1'b1}}) & (in_fifo_front_vld == N_DTPS'(0)); // DTPs are finish and Accumulator has popout all data in fifo
    assign o_is_accum_avai = upd_and_rst;

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            is_dtp_fin <= 0;
        end
        else begin
            if(upd_and_rst)
                is_dtp_fin <= 0;
            else if(i_dtp_fin)
                is_dtp_fin <= 1;
            else
                is_dtp_fin <= is_dtp_fin;
        end
    end
//------------------------------------------------------
    logic clf_bypass_pipe, upd_clf_reg;

    generate
        if(N_DTPS == 1) begin
            pipeline #(.STAGES(1+0), .DWIDTH(1), .RST_VAL(1'('d0))) // clf_bypass will reach output of accumulator after 1+0 + 2(accumulator latency) cycles
                clf_bypass_pipe_inst
                (
                .clk(clk), .rst_n(rst_n), 
                .in_data(upd_and_rst), 
                .out_data(),
                .out_data_lst(clf_bypass_pipe)
                );
            pipeline #(.STAGES(1+0+1), .DWIDTH(1), .RST_VAL(1'('d0))) // upd will reach output of accumulator after 1+0+1 cycles. upd is faster than clf_bypass 1 cycle to update registers before accumulators are reset
                upd_clf_reg_pipe_inst
                (
                .clk(clk), .rst_n(rst_n), 
                .in_data(upd_and_rst), 
                .out_data(),
                .out_data_lst(upd_clf_reg)
                );
        end
        else begin
            pipeline #(.STAGES(1+(N_DTPS-2)), .DWIDTH(1), .RST_VAL(1'('d0))) // clf_bypass will reach output of accumulator after 1+(N_DTPS-2) + 2(accumulator latency) cycles
                clf_bypass_pipe_inst
                (
                .clk(clk), .rst_n(rst_n), 
                .in_data(upd_and_rst), 
                .out_data(),
                .out_data_lst(clf_bypass_pipe)
                );
            pipeline #(.STAGES(1+(N_DTPS-2)+1), .DWIDTH(1), .RST_VAL(1'('d0))) // upd will reach output of accumulator after 1+(N_DTPS-2)+1 cycles. upd is faster than clf_bypass 1 cycle to update registers before accumulators are reset
                upd_clf_reg_pipe_inst
                (
                .clk(clk), .rst_n(rst_n), 
                .in_data(upd_and_rst), 
                .out_data(),
                .out_data_lst(upd_clf_reg)
                );
        end
    endgenerate

//------------------------------------------------------
    logic rgs_bypass_pipe, upd_rgs_reg;

    pipeline #(.STAGES(1), .DWIDTH(1), .RST_VAL(1'('d0))) // rgs_bypass will reach output of accumulator after 1 + 2(accumulator latency) cycles
        rgs_bypass_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(upd_and_rst), 
        .out_data(),
        .out_data_lst(rgs_bypass_pipe)
        );

    pipeline #(.STAGES(2+2*(N_DTPS-1)), .DWIDTH(1), .RST_VAL(1'('d0))) // upd will reach output of accumulator after 2 cycles. upd is faster than rgs_bypass 1 cycle to update registers before accumulators are reset
        upd_rgs_reg_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(upd_and_rst), 
        .out_data(),
        .out_data_lst(upd_rgs_reg)
        );

    assign o_accum_reg_vld = (i_is_clf)? clf_accum_reg_vld : rgs_accum_reg_vld;

//----------------------------------------------------------------------------------------
// 
//----------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------
// CLASSIFICATION SIDE
//----------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------
// 
//----------------------------------------------------------------------------------------




//----------------------------------------------------------------------------------------
// N_DTPS x DEMUXs
//----------------------------------------------------------------------------------------

    generate
        for(genvar i=0; i<N_DTPS; i=i+1) begin
            demux#(
                .SEL_BIT  (4),
                .WIDTH    (1)
            )demux_inst(
                .din (in_fifo_front_vld[i]  ),
                .sel (in_fifo_front[i][3:0] ),
                .dout(vote_loc[i]           )
            );
        end
    endgenerate
//----------------------------------------------------------------------------------------
// N_LABELS x VOTE_INDICES: 1 cycle
//----------------------------------------------------------------------------------------
    generate
        for(genvar l=0; l<N_LABELS; l=l+1) begin
            for(genvar d=0; d<N_DTPS; d=d+1) begin
                assign vote_indices[l][d] = vote_loc[d][l];
            end
        end
    endgenerate


    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            for(integer l=0; l<N_LABELS; l=l+1) begin
                vote_indices_reg[l] <= 0;
            end
        end
        else begin
            for(integer l=0; l<N_LABELS; l=l+1) begin
                vote_indices_reg[l] <= vote_indices[l];
            end
        end
    end

//----------------------------------------------------------------------------------------
// N_LABELS x COUNT1bit: N_DTPS-2 cycles
//----------------------------------------------------------------------------------------

    generate
        for(genvar l=0; l<N_LABELS; l=l+1) begin
            if(N_DTPS == 1) begin
                assign vote_amount[l] = 3'(vote_indices_reg[l][0]);
            end
            else if(N_DTPS == 2) begin
                assign vote_amount[l] = 3'(vote_indices_reg[l][0]) + 3'(vote_indices_reg[l][1]);
            end
            else begin
                count1bit #( // this module can not run if DATA_WIDTH <= 2
                    .DATA_WIDTH(N_DTPS),
                    .COUNT_BIT (3)
                ) count1bit_inst (
                    .clk     (clk                ),   
                    .rst_n   (rst_n              ),   
                    .din     (vote_indices_reg[l]),   
                    .din_vld (                   ),       
                    .dout    (vote_amount[l]     ),   
                    .dout_vld(                   )
                );
            end
        end
    endgenerate

//----------------------------------------------------------------------------------------
// N_LABELS x ACCUMULATOR: 2+1 cycles
//----------------------------------------------------------------------------------------
    logic clf_bypass;
    
    assign clf_bypass = (!rst_n)? 1:clf_bypass_pipe;
    generate
        for (genvar l = 0; l<N_LABELS; l=l+1) begin
            accum_16 clf_accum_inst (
                .B     (16'(vote_amount[l])),  // input wire [15 : 0] B
                .CLK   (clk                ),  // input wire CLK
                .BYPASS(clf_bypass         ),  // input wire BYPASS
                .Q     (clf_accum_out[l]   )   // output wire [15 : 0] Q
            );
        end
    endgenerate

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            for(integer l=0; l<N_LABELS; l=l+1) begin
                o_clf_accum_reg <= 0;
            end
        end
        else begin
            for(integer l=0; l<N_LABELS; l=l+1) begin
                if(upd_clf_reg) begin
                    o_clf_accum_reg[l*FIFO_WIDTH +: FIFO_WIDTH] <= clf_accum_out[l];
                end
                else begin
                    o_clf_accum_reg <= o_clf_accum_reg;
                end
            end
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            clf_accum_reg_vld <= 0;
        end
        else begin
            clf_accum_reg_vld <= upd_clf_reg;
        end
    end




//----------------------------------------------------------------------------------------
// 
//----------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------
// REGRESSION SIDE
//----------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------
// 
//----------------------------------------------------------------------------------------
    logic [FIFO_WIDTH-1:0]  rgs_res [0:N_DTPS-1];
    logic [FIFO_WIDTH-1:0]  rgs_accum_out [0:N_DTPS-1];
    logic rgs_bypass;
    
    assign rgs_bypass = (!rst_n)? 1 : rgs_bypass_pipe;

    generate
        for(genvar d=0; d<N_DTPS; d=d+1) begin
            assign rgs_res[d] = (in_fifo_front_vld[d])? in_fifo_front[d] : 16'd0;

            accum_16 rgs_accum_inst (
                .B     (16'(rgs_res[d]) ),  // input wire [15 : 0] B
                .CLK   (clk             ),  // input wire CLK
                .BYPASS(rgs_bypass      ),  // input wire BYPASS
                .Q     (rgs_accum_out[d])   // output wire [15 : 0] Q
            );
        end
    endgenerate

    logic [FIFO_WIDTH-1:0]  add_out [0:N_DTPS-2];
    logic [FIFO_WIDTH-1:0]  rgs_accum_out_pipe [0:N_DTPS-3];

    generate
        for(genvar d=0; d<N_DTPS-2; d=d+1) begin
            pipeline #(.STAGES(2*(d+1)), .DWIDTH(FIFO_WIDTH), .RST_VAL(FIFO_WIDTH'('d0)))
                rgs_accum_out_pipe_inst
                (
                .clk(clk), .rst_n(rst_n), 
                .in_data(rgs_accum_out[d+2]), 
                .out_data(),
                .out_data_lst(rgs_accum_out_pipe[d])
                );
        end
    endgenerate

    accumulator_int_add first_adder_inst (
        .A  (rgs_accum_out[0]),      // input wire [15 : 0] A
        .B  (rgs_accum_out[1]),      // input wire [15 : 0] B
        .CLK(clk             ),  // input wire CLK
        .S  (add_out[0]      )      // output wire [15 : 0] S
    );

    generate
        for(genvar d=0; d<N_DTPS-2; d=d+1) begin
            accumulator_int_add adder_inst (
                .A  (add_out[d]           ),      // input wire [15 : 0] A
                .B  (rgs_accum_out_pipe[d]),      // input wire [15 : 0] B
                .CLK(clk                  ),  // input wire CLK
                .S  (add_out[d+1]         )      // output wire [15 : 0] S
            );
        end
    endgenerate

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            o_rgs_accum_reg <= 0;
        end
        else begin
            if(upd_rgs_reg)
                o_rgs_accum_reg <= add_out[N_DTPS-2];
            else
                o_rgs_accum_reg <= o_rgs_accum_reg;
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            rgs_accum_reg_vld <= 0;
        end
        else begin
            rgs_accum_reg_vld <= upd_rgs_reg;
        end
    end
    
    // Case N_DTPS=1-------------------------------------------------------------------------------------

    // logic [FIFO_WIDTH-1:0]  rgs_res;
    // logic [FIFO_WIDTH-1:0]  rgs_accum_out;
    // logic rgs_bypass;
    
    // assign rgs_bypass = (!rst_n)? 1 : rgs_bypass_pipe;

    // assign rgs_res = (in_fifo_front_vld[0])? in_fifo_front[0] : 16'd0;

    // accum_16 rgs_accum_inst (
    //     .B     (16'(rgs_res) ),  // input wire [15 : 0] B
    //     .CLK   (clk             ),  // input wire CLK
    //     .BYPASS(rgs_bypass      ),  // input wire BYPASS
    //     .Q     (rgs_accum_out)   // output wire [15 : 0] Q
    // );

    // always_ff @( posedge clk ) begin
    //     if(!rst_n) begin
    //         o_rgs_accum_reg <= 0;
    //     end
    //     else begin
    //         if(upd_rgs_reg)
    //             o_rgs_accum_reg <= rgs_accum_out;
    //         else
    //             o_rgs_accum_reg <= o_rgs_accum_reg;
    //     end
    // end

    // always_ff @( posedge clk ) begin
    //     if(!rst_n) begin
    //         rgs_accum_reg_vld <= 0;
    //     end
    //     else begin
    //         rgs_accum_reg_vld <= upd_rgs_reg;
    //     end
    // end
endmodule