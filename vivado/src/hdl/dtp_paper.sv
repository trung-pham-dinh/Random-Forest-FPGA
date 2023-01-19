`timescale 1ns/1ps

module dtp_paper #(
     parameter DTP_IDX = 0
    ,localparam PIPE_STAGES      = 5
    ,localparam BRAM_AWIDTH      = 14
    ,localparam BRAM_DWIDTH      = 32
    ,localparam TREE_RAM_STAGES  = 2
    ,localparam COMPARE_STAGES   = 2
    
// Internal node:           |--RCHLD--|--ATTR--|--THSH--|--LEAF--|
//                BRAM_DWIDTH        22       17        1        0
// Leaf node:               |--TREE--|--RES--|--LAST--|--LEAF--|
//                BRAM_DWIDTH       18       2        1        0
// Aboslute node:           |--AB_TREE--|--LAST_AB--|
//                BRAM_DWIDTH           1           0  

    ,localparam TREE_DEPTH       = 10 // number of levels

    ,localparam LEAF_IDX         = 0
    ,localparam THSH_IDX         = 1
    ,localparam THSH_WIDTH       = 16
    ,localparam ATTR_IDX         = 17
    ,localparam ATTR_WIDTH       = 5
    ,localparam RCHLD_IDX        = 22
    ,localparam RCHLD_WIDTH      = TREE_DEPTH-1

    ,localparam LAST_IDX         = 1
    ,localparam RES_IDX          = 2
    ,localparam RES_WIDTH        = 16
    ,localparam TREE_IDX         = 18
    ,localparam TREE_WIDTH       = TREE_DEPTH

    ,localparam LAST_AB_IDX      = 0
    ,localparam AB_TREE_IDX      = 1
    ,localparam AB_TREE_WIDTH    = BRAM_AWIDTH

    ,localparam UPD_WIDTH        = 2
    ,localparam STATE_CTRL_WIDTH = 2
    ,localparam INIT_ADDR_WIDTH  = 3
    ,localparam STATE_DTP_WIDTH  = 2
) (
     input                                     clk
    ,input                                     rst_n
          
    ,input  [THSH_WIDTH-1:0]                   i_attr_ram_dout
    ,output [ATTR_WIDTH-1:0]                   o_attr_ram_sel 
    ,output                                    o_attr_ram_switch
    ,input                                     i_is_attr_ram_avai
    ,input                                     i_is_sample_done

    ,input                                     i_tree_ram_ready
       
    ,input                                     i_res_fifo_is_full
    ,output                                    o_res_fifo_we
    ,output [RES_WIDTH-1:0]                    o_res_fifo_dout
     
    ,input                                     i_dtp_start
    ,input                                     i_dtp_end
    ,output                                    o_dtp_fin,
    

    input                                      bram_en_ps, // Chip Enable Signal (optional)
    output [31 : 0]                            bram_dout_ps, // Data Out Bus (optional)
    input  [31 : 0]                            bram_din_ps, // Data In Bus (optional)
    input  [3 : 0]                             bram_we_ps, // Byte Enables (optional)
    input  [BRAM_AWIDTH+2-1 : 0]               bram_addr_ps, // Address Signal (required)
    input                                      bram_clk_ps, // Clock Signal (required)
    input                                      bram_rst_ps // Reset Signal (required)

    // simulation output
    
    //  ,output [BRAM_AWIDTH*PIPE_STAGES-1:0]      bram_addr_pipe_sim  
    //  ,output [STATE_CTRL_WIDTH*PIPE_STAGES-1:0] state_ctrl_pipe_sim 
    //  ,output [BRAM_DWIDTH-1:0]                  tree_ram_dout_sim
    // ,output [THSH_WIDTH-1:0]                   attr_ram_dout_sim   

    //  ,output [INIT_ADDR_WIDTH-1:0]              init_node_sim    
    //  ,output                                    init_sel_sim
    //  ,output                                    init_end_sim    
    //  ,output [PIPE_STAGES-1:0]                  flush_sim


    //  ,output                                    init_proc_sim
    //  ,output [BRAM_AWIDTH-1:0]                  bram_addr_upd_sim
    //  ,output [BRAM_AWIDTH-1:0]                  next_tree_addr_sim
    //  ,output [BRAM_AWIDTH-1:0]                  tree_addr_mux_a_sim
    //  ,output [UPD_WIDTH-1:0]                    upd_pipe_lst_sim
    //  ,output                                    compare_out_sim
    //  ,output [STATE_DTP_WIDTH-1:0]              state_dtp_sim
    // ,output                                    pipeline_start_sim
);
    localparam STATE_DTP_IDLE       = STATE_DTP_WIDTH'('d0);
    localparam STATE_DTP_RST        = STATE_DTP_WIDTH'('d1);
    localparam STATE_DTP_ATT_LOAD   = STATE_DTP_WIDTH'('d2);
    localparam STATE_DTP_PROC       = STATE_DTP_WIDTH'('d3);

    localparam UPD_HOLD             = UPD_WIDTH'('d0);
    localparam UPD_CHILD            = UPD_WIDTH'('d1);
    localparam UPD_TREE             = UPD_WIDTH'('d2);

    localparam STATE_CTRL_IDLE      = STATE_CTRL_WIDTH'('d0);
    localparam STATE_CTRL_INIT      = STATE_CTRL_WIDTH'('d1);
    localparam STATE_CTRL_INTERNAL  = STATE_CTRL_WIDTH'('d2);

    
//----------------------------------------------------------------------------------------
    logic [STATE_DTP_WIDTH-1:0]         state_dtp_next,state_dtp;
    logic [UPD_WIDTH-1:0]               upd,upd_pipe_lst,upd_pipe2;
    logic [STATE_CTRL_WIDTH-1:0]        state_ctrl,state_ctrl_pre,state_ctrl_next;
    logic [STATE_CTRL_WIDTH-1:0]        state_ctrl_pipe[0:PIPE_STAGES-1];

    logic [BRAM_AWIDTH-1:0]             bram_addr, hold_addr,bram_addr_add_1,bram_addr_add_1_pipe2,bram_addr_upd,absolute_addr;
    logic [BRAM_AWIDTH*PIPE_STAGES-1:0] bram_addr_pipe;
    logic [BRAM_DWIDTH-1:0]             bram_dout_ps_temp;

    logic [BRAM_DWIDTH-1:0]             tree_ram_dout,tree_ram_dout_pipe2;
    logic [THSH_WIDTH-1:0]              attr_ram_dout_pipe2;



    logic [BRAM_AWIDTH-1:0]             left_child_addr, right_child_addr, next_tree_addr;

    logic [7:0]                         compare_out;

    logic                               init_sel,init_end,init_proc,tree_addr_vld,init_proc_rst;
    logic [INIT_ADDR_WIDTH-1:0]         init_node,cur_node;
    
    logic [PIPE_STAGES-1:0]             flush;
    
    logic [BRAM_AWIDTH-1:0]             tree_addr_mux_a,tree_addr_mux_b,tree_addr_mux_a_pipe2,tree_addr_mux_b_pipe2;
    
    logic                               dtp_fin,pipeline_start,pipe_flush,core_start;
//----------------------------------------------------------------------------------------
// Simulation logic
//----------------------------------------------------------------------------------------

    //  assign bram_addr_pipe_sim   = bram_addr_pipe;
    //  assign tree_ram_dout_sim    = tree_ram_dout;
    // assign attr_ram_dout_sim    = attr_ram_dout;
    //  assign init_node_sim        = init_node;
    //  assign init_sel_sim         = init_sel;
    //  assign flush_sim            = flush;
    //  assign init_end_sim         = init_end;
    //  assign init_proc_sim        = init_proc;
    //  assign bram_addr_upd_sim    = bram_addr_upd;
    //  assign next_tree_addr_sim   = next_tree_addr;
    //  assign tree_addr_mux_a_sim  = tree_addr_mux_a;
    //  assign state_ctrl_pre_sim   = state_ctrl_pre;
    //  assign upd_pipe_lst_sim     = upd_pipe_lst;
    //  assign compare_out_sim      =compare_out[0];
    // assign state_dtp_sim        = state_dtp;
    // assign pipeline_start_sim   = pipeline_start;


    // generate
    //     for(genvar i=0; i<PIPE_STAGES; i=i+1) begin
    //         assign state_ctrl_pipe_sim[i*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH] = state_ctrl_pipe[i];
    //     end
    // endgenerate
    
//----------------------------------------------------------------------------------------
// PIPELINE PATH
//----------------------------------------------------------------------------------------
    assign bram_addr  = (init_sel)? BRAM_AWIDTH'(init_node):bram_addr_upd;
    assign state_ctrl = (init_sel)? STATE_CTRL_INIT:state_ctrl_pipe[PIPE_STAGES-1];

    pipeline #(.STAGES(PIPE_STAGES), .DWIDTH(BRAM_AWIDTH), .RST_VAL(BRAM_AWIDTH'('d0))) 
            pipe_bram_addr_inst_0
            (
            .clk(clk), .rst_n(rst_n), 
            .in_data(bram_addr), 
            .out_data(bram_addr_pipe),
            .out_data_lst(hold_addr)
            );


    assign state_ctrl_pre = state_ctrl_pipe[1];
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            for(integer i=0; i<PIPE_STAGES; i=i+1) begin
                state_ctrl_pipe[i] <= STATE_CTRL_IDLE;    
            end
        end
        else begin
            state_ctrl_pipe[0] <= (flush[0])? STATE_CTRL_IDLE : state_ctrl;
            for(integer i=1; i<=TREE_RAM_STAGES-1; i=i+1) begin
                state_ctrl_pipe[i] <= (flush[i])? STATE_CTRL_IDLE : state_ctrl_pipe[i-1];    
            end
            
            // there is a CTRL FSM between the pipeline of state_ctrl_pipe registers

            state_ctrl_pipe[TREE_RAM_STAGES] <= (flush[TREE_RAM_STAGES])? STATE_CTRL_IDLE : state_ctrl_next;
            for(integer i=TREE_RAM_STAGES+1; i<=PIPE_STAGES-1; i=i+1) begin
                state_ctrl_pipe[i] <= (flush[i])? STATE_CTRL_IDLE : state_ctrl_pipe[i-1];    
            end
        end
    end
    
    
   
//----------------------------------------------------------------------------------------
// TREE ACCESS
//---------------------------------------------------------------------------------------- 
    logic [15:0] bram_addr_add_1_temp;

    dtp_int_add_paper add_1_inst_0 (
    .A(16'(bram_addr)),      // input wire [15 : 0] A
    .B(16'd1),      // input wire [15 : 0] B
    .CLK(clk),  // input wire CLK
    .S(bram_addr_add_1_temp)      // output wire [15 : 0] S
    );

    assign bram_addr_add_1 = BRAM_AWIDTH'(bram_addr_add_1_temp);
//----------------------------------------------------------------------------------------
    generate
        if(DTP_IDX==0) begin
            dtp_bram_paper tree_ram_inst_0 (
                // DTP
            .clka (clk),    // input wire clka
            .rsta (1'b0),    // input wire rsta
            .ena  (1'b1),      // input wire ena
            .wea  (1'b0),      // input wire [0 : 0] wea
            .addra(bram_addr),  // input wire [13 : 0] addra
            .dina (BRAM_DWIDTH'('d0)),    // input wire [31 : 0] dina
            .douta(tree_ram_dout),  // output wire [31 : 0] douta

                // PS
            .clkb (bram_clk_ps),    // input wire clkb
            .rstb (bram_rst_ps),    // input wire rstb
            .enb  (bram_en_ps),      // input wire enb
            .web  (|bram_we_ps),      // input wire [0 : 0] web
            .addrb(bram_addr_ps[BRAM_AWIDTH+2-1 : 2]),  // input wire [13 : 0] addrb
            .dinb (bram_din_ps[BRAM_DWIDTH-1:0]),    // input wire [31 : 0] dinb
            .doutb(bram_dout_ps_temp)  // output wire [31 : 0] doutb
            );
        end
        else if(DTP_IDX==1) begin
            dtp_bram_paper_1 tree_ram_inst_1 (
                // DTP
            .clka (clk),    // input wire clka
            .rsta (1'b0),    // input wire rsta
            .ena  (1'b1),      // input wire ena
            .wea  (1'b0),      // input wire [0 : 0] wea
            .addra(bram_addr),  // input wire [13 : 0] addra
            .dina (BRAM_DWIDTH'('d0)),    // input wire [31 : 0] dina
            .douta(tree_ram_dout),  // output wire [31 : 0] douta

                // PS
            .clkb (bram_clk_ps),    // input wire clkb
            .rstb (bram_rst_ps),    // input wire rstb
            .enb  (bram_en_ps),      // input wire enb
            .web  (|bram_we_ps),      // input wire [0 : 0] web
            .addrb(bram_addr_ps[BRAM_AWIDTH+2-1 : 2]),  // input wire [13 : 0] addrb
            .dinb (bram_din_ps[BRAM_DWIDTH-1:0]),    // input wire [31 : 0] dinb
            .doutb(bram_dout_ps_temp)  // output wire [31 : 0] doutb
            );
        end
        else if(DTP_IDX==2) begin
            dtp_bram_paper_2 tree_ram_inst_2 (
                // DTP
            .clka (clk),    // input wire clka
            .rsta (1'b0),    // input wire rsta
            .ena  (1'b1),      // input wire ena
            .wea  (1'b0),      // input wire [0 : 0] wea
            .addra(bram_addr),  // input wire [13 : 0] addra
            .dina (BRAM_DWIDTH'('d0)),    // input wire [31 : 0] dina
            .douta(tree_ram_dout),  // output wire [31 : 0] douta

                // PS
            .clkb (bram_clk_ps),    // input wire clkb
            .rstb (bram_rst_ps),    // input wire rstb
            .enb  (bram_en_ps),      // input wire enb
            .web  (|bram_we_ps),      // input wire [0 : 0] web
            .addrb(bram_addr_ps[BRAM_AWIDTH+2-1 : 2]),  // input wire [13 : 0] addrb
            .dinb (bram_din_ps[BRAM_DWIDTH-1:0]),    // input wire [31 : 0] dinb
            .doutb(bram_dout_ps_temp)  // output wire [31 : 0] doutb
            );
        end
        else if(DTP_IDX==3) begin
            dtp_bram_paper_3 tree_ram_inst_3 (
                // DTP
            .clka (clk),    // input wire clka
            .rsta (1'b0),    // input wire rsta
            .ena  (1'b1),      // input wire ena
            .wea  (1'b0),      // input wire [0 : 0] wea
            .addra(bram_addr),  // input wire [13 : 0] addra
            .dina (BRAM_DWIDTH'('d0)),    // input wire [31 : 0] dina
            .douta(tree_ram_dout),  // output wire [31 : 0] douta

                // PS
            .clkb (bram_clk_ps),    // input wire clkb
            .rstb (bram_rst_ps),    // input wire rstb
            .enb  (bram_en_ps),      // input wire enb
            .web  (|bram_we_ps),      // input wire [0 : 0] web
            .addrb(bram_addr_ps[BRAM_AWIDTH+2-1 : 2]),  // input wire [13 : 0] addrb
            .dinb (bram_din_ps[BRAM_DWIDTH-1:0]),    // input wire [31 : 0] dinb
            .doutb(bram_dout_ps_temp)  // output wire [31 : 0] doutb
            );
        end
        else if(DTP_IDX==4) begin
            dtp_bram_paper_4 tree_ram_inst_4 (
                // DTP
            .clka (clk),    // input wire clka
            .rsta (1'b0),    // input wire rsta
            .ena  (1'b1),      // input wire ena
            .wea  (1'b0),      // input wire [0 : 0] wea
            .addra(bram_addr),  // input wire [13 : 0] addra
            .dina (BRAM_DWIDTH'('d0)),    // input wire [31 : 0] dina
            .douta(tree_ram_dout),  // output wire [31 : 0] douta

                // PS
            .clkb (bram_clk_ps),    // input wire clkb
            .rstb (bram_rst_ps),    // input wire rstb
            .enb  (bram_en_ps),      // input wire enb
            .web  (|bram_we_ps),      // input wire [0 : 0] web
            .addrb(bram_addr_ps[BRAM_AWIDTH+2-1 : 2]),  // input wire [13 : 0] addrb
            .dinb (bram_din_ps[BRAM_DWIDTH-1:0]),    // input wire [31 : 0] dinb
            .doutb(bram_dout_ps_temp)  // output wire [31 : 0] doutb
            );
        end
    endgenerate

    assign bram_dout_ps = 32'(bram_dout_ps_temp);

//----------------------------------------------------------------------------------------
// ATTRIBUTE ACCESS
//---------------------------------------------------------------------------------------- 
    assign o_attr_ram_sel = tree_ram_dout[ATTR_IDX +: ATTR_WIDTH];
    
    assign o_res_fifo_we = (state_ctrl_pre == STATE_CTRL_INTERNAL) & (tree_ram_dout[LEAF_IDX] & !i_res_fifo_is_full);
    assign o_res_fifo_dout = tree_ram_dout[RES_IDX +: RES_WIDTH];
    // assign o_res_fifo_dout = 16'(bram_addr_pipe[(TREE_RAM_STAGES-1)*BRAM_AWIDTH +:BRAM_AWIDTH]); // for debug
    
    always_comb begin : CTRL_FSM
        case (state_ctrl_pre)
            STATE_CTRL_IDLE: begin
                state_ctrl_next = STATE_CTRL_IDLE;
                upd = UPD_HOLD;
            end
            STATE_CTRL_INIT: begin
                state_ctrl_next = STATE_CTRL_INTERNAL;
                upd = UPD_TREE;
            end
            STATE_CTRL_INTERNAL: begin
                if(tree_ram_dout[LEAF_IDX] & i_res_fifo_is_full) begin
                    upd = UPD_HOLD;
                    state_ctrl_next = STATE_CTRL_INTERNAL;
                end
                else if(tree_ram_dout[LEAF_IDX] & !i_res_fifo_is_full & tree_ram_dout[LAST_IDX]) begin
                    upd = UPD_HOLD;
                    state_ctrl_next = STATE_CTRL_IDLE;
                end
                else if(tree_ram_dout[LEAF_IDX] & !i_res_fifo_is_full) begin
                    upd = UPD_TREE;
                    state_ctrl_next = STATE_CTRL_INTERNAL;
                end
                else begin
                    upd = UPD_CHILD;
                    state_ctrl_next = STATE_CTRL_INTERNAL;
                end
            end
            default: begin
                upd = UPD_HOLD;
                state_ctrl_next = STATE_CTRL_IDLE;
            end
        endcase
    end
//----------------------------------------------------------------------------------------
// PIPE BEFORE COMPARE
//----------------------------------------------------------------------------------------
    assign tree_addr_mux_a = (state_ctrl_pre==STATE_CTRL_INIT)? BRAM_AWIDTH'(tree_ram_dout[AB_TREE_IDX +: AB_TREE_WIDTH]):BRAM_AWIDTH'(tree_ram_dout[TREE_IDX +: TREE_WIDTH]);
    assign tree_addr_mux_b = (state_ctrl_pre==STATE_CTRL_INIT)? BRAM_AWIDTH'('d0):bram_addr_pipe[(TREE_RAM_STAGES-1)*BRAM_AWIDTH +:BRAM_AWIDTH];
    
    pipeline #(.STAGES(1), .DWIDTH(THSH_WIDTH), .RST_VAL(THSH_WIDTH'('d0))) 
        attr_ram_dout_pipe2_inst_0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_attr_ram_dout), 
        .out_data(),
        .out_data_lst(attr_ram_dout_pipe2)
        );

    pipeline #(.STAGES(1), .DWIDTH(BRAM_DWIDTH), .RST_VAL(BRAM_DWIDTH'('d0))) 
        tree_ram_dout_pipe2_inst_0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(tree_ram_dout), 
        .out_data(),
        .out_data_lst(tree_ram_dout_pipe2)
        );
    pipeline #(.STAGES(1), .DWIDTH(BRAM_AWIDTH), .RST_VAL(BRAM_AWIDTH'('d0))) 
        bram_addr_add_1_pipe2_inst_0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(bram_addr_add_1), 
        .out_data(),
        .out_data_lst(bram_addr_add_1_pipe2)
        );

    pipeline #(.STAGES(1), .DWIDTH(BRAM_AWIDTH), .RST_VAL(BRAM_AWIDTH'('d0))) 
        tree_addr_mux_a_pipe2_inst_0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(tree_addr_mux_a), 
        .out_data(),
        .out_data_lst(tree_addr_mux_a_pipe2)
        );
    pipeline #(.STAGES(1), .DWIDTH(BRAM_AWIDTH), .RST_VAL(BRAM_AWIDTH'('d0))) 
        tree_addr_mux_b_pipe2_inst_0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(tree_addr_mux_b), 
        .out_data(),
        .out_data_lst(tree_addr_mux_b_pipe2)
        );

    pipeline #(.STAGES(1), .DWIDTH(UPD_WIDTH), .RST_VAL(UPD_WIDTH'(UPD_HOLD))) 
        UPD_WIDTH_pipe2_inst_0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(upd), 
        .out_data(),
        .out_data_lst(upd_pipe2)
        );

//----------------------------------------------------------------------------------------
// COMPARE
//----------------------------------------------------------------------------------------


    dtp_flt_comp flt_comp_inst_0 (
    .aclk(clk),                                  // input wire aclk
    .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
    .s_axis_a_tdata(attr_ram_dout_pipe2),              // input wire [15 : 0] s_axis_a_tdata
    .s_axis_b_tvalid(1'b1),            // input wire s_axis_b_tvalid
    .s_axis_b_tdata(tree_ram_dout_pipe2[THSH_IDX +: THSH_WIDTH]),              // input wire [15 : 0] s_axis_b_tdata
    .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
    .m_axis_result_tdata(compare_out)    // output wire [7 : 0] m_axis_result_tdata
    );

    pipeline #(.STAGES(COMPARE_STAGES), .DWIDTH(BRAM_AWIDTH), .RST_VAL(BRAM_AWIDTH'('d0))) 
        left_child_pipe_inst_0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(bram_addr_add_1_pipe2), 
        .out_data(),
        .out_data_lst(left_child_addr)
        );

    logic [15 : 0] right_child_addr_temp;
    logic [15 : 0] next_tree_addr_temp;
    dtp_int_add_paper right_child_adder (
    .A(16'(tree_ram_dout_pipe2[RCHLD_IDX +: RCHLD_WIDTH])),      // input wire [15 : 0] A
    .B(16'(bram_addr_add_1_pipe2)),      // input wire [15 : 0] B
    .CLK(clk),  // input wire CLK
    .S(right_child_addr_temp)      // output wire [15 : 0] S
    );
    assign right_child_addr = BRAM_AWIDTH'(right_child_addr_temp);

    dtp_int_add_paper next_tree_adder (
    .A(16'(tree_addr_mux_a_pipe2)),      // input wire [15 : 0] A
    .B(16'(tree_addr_mux_b_pipe2)),      // input wire [15 : 0] B
    .CLK(clk),  // input wire CLK
    .S(next_tree_addr_temp)      // output wire [15 : 0] S
    );
    assign next_tree_addr = BRAM_AWIDTH'(next_tree_addr_temp);

    pipeline #(.STAGES(COMPARE_STAGES), .DWIDTH(UPD_WIDTH), .RST_VAL(UPD_WIDTH'(UPD_HOLD))) 
        upd_sel_inst_0
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(upd_pipe2), 
        .out_data(),
        .out_data_lst(upd_pipe_lst)
        );

//----------------------------------------------------------------------------------------
// WRITE BACK
//----------------------------------------------------------------------------------------
    always_comb begin
        case(upd_pipe_lst)
            UPD_HOLD:
                bram_addr_upd = hold_addr;
            UPD_TREE:
                bram_addr_upd = next_tree_addr;
            UPD_CHILD:
                bram_addr_upd = (compare_out[0])? left_child_addr:right_child_addr;
            default:
                bram_addr_upd = 0;
        endcase
    end
    
//----------------------------------------------------------------------------------------
// CONTROL LOGIC
//----------------------------------------------------------------------------------------
    logic [PIPE_STAGES-1:0] is_ctrl_idle;

    assign dtp_fin = (is_ctrl_idle == {PIPE_STAGES{1'b1}}) & ~init_proc; // all pipeline stages go to IDLE and not in init process
    // assign o_dtp_fin = (state_dtp==STATE_DTP_PROC) & dtp_fin;
    assign o_dtp_fin = (state_dtp==STATE_DTP_ATT_LOAD) & i_is_sample_done;
    assign o_attr_ram_switch = (state_dtp==STATE_DTP_PROC) & dtp_fin;

    generate
        for(genvar i=0; i<PIPE_STAGES; i=i+1) begin
           assign is_ctrl_idle[i] = state_ctrl_pipe[i] == STATE_CTRL_IDLE;
        end
    endgenerate

    assign core_start = i_dtp_start & i_tree_ram_ready & ~i_is_sample_done; // start the dtp core

    // core reset signals
    assign init_proc_rst            = ((state_dtp==STATE_DTP_IDLE) & core_start) | i_dtp_end;
    assign pipe_flush               = ((state_dtp==STATE_DTP_IDLE) & core_start) | i_dtp_end;

    // core start signals
    assign pipeline_start = (state_dtp==STATE_DTP_ATT_LOAD) & i_is_attr_ram_avai;

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            state_dtp <= STATE_DTP_IDLE;
        end
        else begin
            state_dtp <= state_dtp_next;
        end
    end
    
    always_comb begin
        case (state_dtp)
            STATE_DTP_IDLE: begin
                if(core_start)
                    state_dtp_next = STATE_DTP_RST;
                else
                    state_dtp_next = state_dtp;
            end
            STATE_DTP_RST: begin
                if(i_dtp_end)
                    state_dtp_next = STATE_DTP_IDLE;
                else
                    state_dtp_next = STATE_DTP_ATT_LOAD;
            end
            STATE_DTP_ATT_LOAD: begin
                if(i_dtp_end | i_is_sample_done)
                    state_dtp_next = STATE_DTP_IDLE;
                else if(i_is_attr_ram_avai)
                    state_dtp_next = STATE_DTP_PROC;
                else
                    state_dtp_next = state_dtp;
            end
            STATE_DTP_PROC: begin
                if(i_dtp_end)
                    state_dtp_next = STATE_DTP_IDLE;
                else if(dtp_fin)
                    state_dtp_next = STATE_DTP_ATT_LOAD;
                else
                    state_dtp_next = state_dtp;
            end
            default: begin
                state_dtp_next = STATE_DTP_IDLE;
            end
        endcase
    end
//----------------------------------------------------------------------------------------
// INITIALIZATION LOGIC
//----------------------------------------------------------------------------------------

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            init_proc <= 0;
        end
        else begin
            if(~init_proc & pipeline_start)
                init_proc <= 1;
            else if((init_proc & init_end) | init_proc_rst)
                init_proc <= 0;
            else
                init_proc <= init_proc;
        end 
    end
    
    // init_end active when it loads the last node to the pipeline or detect last node during loading
    assign init_end = tree_addr_vld & (init_node==INIT_ADDR_WIDTH'(PIPE_STAGES-1) || tree_ram_dout[LAST_AB_IDX]);

    // It costs TREE_RAM_STAGES cycles to know if current loading node is last -> have pipelines of TREE_RAM_STAGES cycles for vld and node address
    pipeline #(.STAGES(TREE_RAM_STAGES), .DWIDTH(1), .RST_VAL(1'd0)) 
        tree_addr_vld_pipe
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(init_sel), 
        .out_data(),
        .out_data_lst(tree_addr_vld)
        );
    pipeline #(.STAGES(TREE_RAM_STAGES), .DWIDTH(INIT_ADDR_WIDTH), .RST_VAL(INIT_ADDR_WIDTH'('d0))) 
        init_node_pipe
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(init_node), 
        .out_data(),
        .out_data_lst(cur_node)
        );

    assign init_sel = init_proc; // gain permission to drive input of pipeline
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            init_node <= INIT_ADDR_WIDTH'('d0);
        end
        else begin
            init_node <= (init_proc)? (init_node + INIT_ADDR_WIDTH'('d1)) : INIT_ADDR_WIDTH'('d0);
        end
    end
//----------------------------------------------------------------------------------------
// FLUSH LOGIC
//----------------------------------------------------------------------------------------
    // it costs TREE_RAM_STAGES cycles to exactly know if last node -> when we know, we have fed to pipeline redundant nodes -> need to flush
    always_comb begin
        if(pipe_flush) begin
            flush = PIPE_STAGES'('b11111);
        end
        else if(tree_addr_vld & tree_ram_dout[LAST_AB_IDX]) begin
            if(cur_node == INIT_ADDR_WIDTH'(PIPE_STAGES-1))
                flush = PIPE_STAGES'('b00000);
            else if(cur_node == INIT_ADDR_WIDTH'(PIPE_STAGES-2))
                flush = PIPE_STAGES'('b00010);
            else
                flush = PIPE_STAGES'('b00011);
        end
        else begin
            flush = PIPE_STAGES'('b00000);
        end
    end

endmodule
