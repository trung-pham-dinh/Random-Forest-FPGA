// In classification, least cycles between two valid signals is 5
// In regression, least cycles between two valid signals is 3 (same vote slot), 1 (different vote slot)

`timescale 1ns/1ps

module vote_buffer #(
     parameter N_LABELS        = 10  // maximum N_LABELS
    ,parameter N_LABELS_WIDTH  = 4  // maximum N_LABELS bit
    ,parameter RES_WIDTH       = 16
    ,parameter BRAM_AWIDTH     = 14
    ,parameter BRAM_DWIDTH     = 16
    ,localparam BRAM_AWIDTH_32 = BRAM_AWIDTH+2
) (
     input                           clk
    ,input                           rst_n

    ,input                           i_vote_slot_rst

    ,input [N_LABELS_WIDTH-1:0]      i_n_labels // current n_labels
    ,input                           i_is_clf
    ,input                           i_is_ps_read

    // input classification label result
    ,input [N_LABELS*RES_WIDTH-1:0]  i_clf_accum
    // input regression register result
    ,input [RES_WIDTH-1:0]           i_rgs_accum
    ,input                           i_accum_vld,

    
    // Uncomment the following to set interface specific parameter on the bus interface.
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_PS EN" *)
    input bram_en_ps, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_PS DOUT" *)
    output [31 : 0] bram_dout_ps, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_PS DIN" *)
    input [31 : 0]  bram_din_ps, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_PS WE" *)
    input [3 : 0]   bram_we_ps, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_PS ADDR" *)
    input [BRAM_AWIDTH_32-1 : 0]  bram_addr_ps, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_PS CLK" *)
    input bram_clk_ps, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT_PS RST" *)
    input bram_rst_ps // Reset Signal (required)

    // simulation
    ,output                      vld_sim           
    ,output [N_LABELS_WIDTH-1:0] reg_idx_sim       
    ,output [RES_WIDTH-1:0]      clf_rgs_res_sim   
    ,output [21 : 0]             clf_addr_sim      
    ,output [RES_WIDTH-1:0]      accum_res_sim     
    ,output [BRAM_AWIDTH-1:0]    read_addr_sim     
    ,output                      read_addr_vld_sim 
    ,output [RES_WIDTH-1:0]      accum_res_pipe_sim
    ,output [BRAM_DWIDTH-1:0]    write_bram_din_sim     
    ,output [BRAM_AWIDTH-1:0]    write_bram_addr_sim    
    ,output                      write_bram_we_sim
    ,output [BRAM_AWIDTH-1:0]    read_bram_addr_sim
);
    localparam MUL_ADD_N_STAGES      = 3;
    localparam READ_BRAM_STAGES      = 1;
    localparam ADDER_STAGES          = 2;

    logic                            accum_vld;
    logic [BRAM_AWIDTH-1:0]          vote_slot_reg,vote_slot;
    logic [N_LABELS_WIDTH-1:0]       clf_label,clf_label_pipe;
    logic [RES_WIDTH-1:0]            clf_rgs_res,clf_res,accum_res,accum_res_pipe;

    logic [21 : 0]                   clf_addr;
    logic                            vld, vld_mul_add, write_addr_vld;

    logic [BRAM_AWIDTH-1:0]          read_addr, write_addr;
    logic                            read_addr_vld;
    logic [BRAM_DWIDTH-1:0]          read_bram_dout,write_res;


    logic                            read_bram_en;
    logic                            read_bram_rst;
    logic [BRAM_AWIDTH-1:0]          read_bram_addr;

    logic                            write_bram_we;
    logic [BRAM_AWIDTH-1:0]          write_bram_addr;
    logic [BRAM_DWIDTH-1:0]          write_bram_din;

    logic                            clear_bram_we;
    logic [BRAM_AWIDTH-1:0]          clear_bram_addr;
    logic                            is_ps_read_pipe;

    logic [N_LABELS_WIDTH-1:0]       reg_idx;
//----------------------------------------------------------------------------------------
// Simulation logic
//----------------------------------------------------------------------------------------

    assign vld_sim            = vld;
    assign reg_idx_sim        = reg_idx;
    assign clf_rgs_res_sim    = clf_rgs_res;
    assign clf_addr_sim       = clf_addr;
    assign accum_res_sim      = accum_res;
    assign read_addr_sim      = read_addr;
    assign read_addr_vld_sim  = read_addr_vld;
    assign accum_res_pipe_sim = accum_res_pipe;
    assign write_bram_din_sim = write_bram_din;
    assign write_bram_addr_sim= write_bram_addr;
    assign write_bram_we_sim  = write_bram_we;
    assign read_bram_addr_sim = read_bram_addr;

//----------------------------------------------------------------------------------------
// Scan result registers
//----------------------------------------------------------------------------------------

    counter_with_lat #(
        .WIDTH(BRAM_AWIDTH)
    ) counter_inst(
        .clk         (clk            ),   
        .rst_n       (rst_n          ),   
        .inc         (i_accum_vld    ),   
        .set_val     (0              ),   
        .set_val_vld (0              ),       
        .clear       (i_vote_slot_rst),   
        .dout        (vote_slot      )   
    );
    pipeline #(.STAGES(1), .DWIDTH(1), .RST_VAL(1'('d0))) 
        accum_vld_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_accum_vld), 
        .out_data(),
        .out_data_lst(accum_vld)
        );
//-----------------------------------------------------------



    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            vld <= 0;
        end
        else begin
            if(i_is_clf & accum_vld)
                vld <= 1;
            else if(reg_idx == i_n_labels-N_LABELS_WIDTH'('d1)) // vld will active for i_n_labels cycles
                vld <= 0;
            else
                vld <= vld;
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            vote_slot_reg <= BRAM_AWIDTH'(0);
        end
        else begin
            if(i_is_clf & accum_vld)
                vote_slot_reg <= vote_slot;
            else
                vote_slot_reg <= vote_slot_reg;
        end
    end

    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            reg_idx <= N_LABELS_WIDTH'('d0);
        end
        else begin
//            if(vld)
//                reg_idx <= reg_idx + 1;
//            else
//                reg_idx <= N_LABELS_WIDTH'('d0);

            if(reg_idx == i_n_labels-N_LABELS_WIDTH'('d1))
                reg_idx <= N_LABELS_WIDTH'('d0);
            else if(vld)
                reg_idx <= reg_idx + 1;
            else 
                reg_idx <= reg_idx;
        end
    end
    assign clf_label = reg_idx;

    always_comb begin
        case (reg_idx)
            N_LABELS_WIDTH'('d0): begin
                clf_rgs_res = i_clf_accum[0*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d1): begin
                clf_rgs_res = i_clf_accum[1*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d2): begin
                clf_rgs_res = i_clf_accum[2*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d3): begin
                clf_rgs_res = i_clf_accum[3*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d4): begin
                clf_rgs_res = i_clf_accum[4*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d5): begin
                clf_rgs_res = i_clf_accum[5*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d6): begin
                clf_rgs_res = i_clf_accum[6*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d7): begin
                clf_rgs_res = i_clf_accum[7*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d8): begin
                clf_rgs_res = i_clf_accum[8*RES_WIDTH +: RES_WIDTH];
            end
            N_LABELS_WIDTH'('d9): begin
                clf_rgs_res = i_clf_accum[9*RES_WIDTH +: RES_WIDTH];
            end
            default: begin
                clf_rgs_res = i_clf_accum[0*RES_WIDTH +: RES_WIDTH];
            end
        endcase
    end

//----------------------------------------------------------------------------------------
// MULTIPLICATION & ADDITION stage
//----------------------------------------------------------------------------------------

    pipeline #(.STAGES(1), .DWIDTH(N_LABELS_WIDTH), .RST_VAL(N_LABELS_WIDTH'('d0))) 
        clf_label_pipe_inst
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(clf_label), 
        .out_data(),
        .out_data_lst(clf_label_pipe) // mul_add IP has 3 cycles latency for MUL and 2 cycles latency for ADD. Therefore, adder is added a pipeline stage to compatible with multiplier
        );
    vote_mul_add mul_add_inst ( // A*B+C
        .CLK      (clk               ),  // input wire CLK
        .CE       (1'b1              ),  // input wire CE
        .SCLR     (1'b0              ),  // input wire SCLR
        .A        (5'(i_n_labels)    ),  // input wire [4 : 0] A
        .B        (16'(vote_slot_reg)),  // input wire [15 : 0] B
        .C        (5'(clf_label_pipe)),  // input wire [4 : 0] C
        .SUBTRACT (1'b0              ),  // input wire SUBTRACT
        .P        (clf_addr          ),  // output wire [21 : 0] P
        .PCOUT    (                  )   // output wire [47 : 0] PCOUT
    );

    pipeline #(.STAGES(MUL_ADD_N_STAGES), .DWIDTH(1), .RST_VAL(1'('d0))) 
        vld_pipe_mul_add_stage
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(vld), 
        .out_data(),
        .out_data_lst(vld_mul_add)
        );
    
    pipeline #(.STAGES(MUL_ADD_N_STAGES), .DWIDTH(RES_WIDTH), .RST_VAL(RES_WIDTH'('d0))) 
        res_pipe_mul_add_stage
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(clf_rgs_res), 
        .out_data(),
        .out_data_lst(clf_res)
        );
    
    assign accum_res     = (i_is_clf)? clf_res                  : i_rgs_accum;
    assign read_addr     = (i_is_clf)? BRAM_AWIDTH'(clf_addr)   : BRAM_AWIDTH'(vote_slot);
    assign read_addr_vld = (i_is_clf)? vld_mul_add              : accum_vld;

//----------------------------------------------------------------------------------------
// BRAM 
//----------------------------------------------------------------------------------------
    assign read_bram_rst  = (i_is_ps_read)? bram_rst_ps                        : 1'b0;
    assign read_bram_en   = (i_is_ps_read)? bram_en_ps                         : 1'b1;
    assign read_bram_addr = (i_is_ps_read)? bram_addr_ps[BRAM_AWIDTH_32-1 : 2] : read_addr;

    assign bram_dout_ps   = 32'(read_bram_dout);

    assign write_bram_we   = (is_ps_read_pipe)? clear_bram_we                  : write_addr_vld;
    assign write_bram_addr = (is_ps_read_pipe)? clear_bram_addr                : write_addr;
    assign write_bram_din  = (is_ps_read_pipe)? BRAM_DWIDTH'('d0)              : write_res;

    vote_bram vote_bram_inst (
        // VOTE BUFFER READ, PS READ
        .clka (clk           ),  // input wire clka
        .rsta (read_bram_rst ),  // input wire rsta
        .ena  (read_bram_en  ),  // input wire ena
        .wea  (1'b0          ),  // input wire [0 : 0] wea
        .addra(read_bram_addr),  // input wire [13 : 0] addra
        .dina (),                // input wire [15 : 0] dina
        .douta(read_bram_dout),  // output wire [15 : 0] douta
        
        // VOTE BUFFER WRITE, PS WRITE
        .clkb (clk            ),    // input wire clkb
        .rstb (1'b0           ),    // input wire rstb
        .enb  (1'b1           ),      // input wire enb
        .web  (write_bram_we  ),      // input wire [0 : 0] web
        .addrb(write_bram_addr),  // input wire [13 : 0] addrb
        .dinb (write_bram_din ),    // input wire [15 : 0] dinb
        .doutb()  // output wire [15 : 0] doutb
    );


//----------------------------------------------------------------------------------------
// BRAM stage 
//----------------------------------------------------------------------------------------

    pipeline #(.STAGES(READ_BRAM_STAGES), .DWIDTH(RES_WIDTH), .RST_VAL(RES_WIDTH'('d0))) 
        result_pipe_read_bram_stage
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(accum_res), 
        .out_data(),
        .out_data_lst(accum_res_pipe)
        );

    vote_int_add accum_adder_inst (
        .A  (accum_res_pipe),      // input wire [15 : 0] A
        .B  (read_bram_dout),      // input wire [15 : 0] B
        .CLK(clk),  // input wire CLK
        .S  (write_res)      // output wire [15 : 0] S
    );

    pipeline #(.STAGES(READ_BRAM_STAGES+ADDER_STAGES), .DWIDTH(BRAM_AWIDTH), .RST_VAL(BRAM_AWIDTH'('d0))) 
        addr_pipe_stage
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(read_addr), 
        .out_data(),
        .out_data_lst(write_addr)
        );

    pipeline #(.STAGES(READ_BRAM_STAGES+ADDER_STAGES), .DWIDTH(1), .RST_VAL(1'('d0))) 
        addr_vld_pipe_stage
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(read_addr_vld), 
        .out_data(),
        .out_data_lst(write_addr_vld)
        );

//----------------------------------------------------------------------------------------
// Clear on Read
//----------------------------------------------------------------------------------------

    pipeline #(.STAGES(2), .DWIDTH(BRAM_AWIDTH), .RST_VAL(BRAM_AWIDTH'('d0))) 
        clear_addr_pipe_stage
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(bram_addr_ps[BRAM_AWIDTH_32-1 : 2]), 
        .out_data(),
        .out_data_lst(clear_bram_addr)
        );
    pipeline #(.STAGES(2), .DWIDTH(1), .RST_VAL(1'('d0))) 
        clear_bram_we_pipe_stage
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(bram_en_ps & !(|bram_we_ps)), 
        .out_data(),
        .out_data_lst(clear_bram_we)
        );

    pipeline #(.STAGES(2), .DWIDTH(1), .RST_VAL(1'('d0))) 
        i_is_ps_read_pipe_stage
        (
        .clk(clk), .rst_n(rst_n), 
        .in_data(i_is_ps_read), 
        .out_data(),
        .out_data_lst(is_ps_read_pipe)
        );

endmodule