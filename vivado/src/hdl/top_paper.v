`timescale 1ns / 1ps

module top_paper #(
     localparam DTP_PIPE_STAGES      = 5
    ,localparam ATTR_WIDTH           = 16
    ,localparam ATTR_SEL_WIDTH       = 5
    ,localparam DTP_BRAM_AWIDTH      = 14
    
    ,localparam RES_WIDTH            = 16
    
     ,localparam STATE_CTRL_WIDTH     = 2 // SIMULATION
     ,localparam STATE_DTP_WIDTH      = 2
     ,localparam STATE_FIFO_WIDTH     = 2

    ,localparam N_DTPS               = 5
    ,localparam POP_AMOUNT           = 8 // unit: attributes/sample

    ,localparam SAMPLE_FIFO_DEPTH_BIT= 13
    ,localparam VOTE_DEPTH_BIT       = 10
//--------------------------------------------
    ,localparam integer C_S_AXI_DATA_WIDTH  = 32
    ,localparam integer C_S_AXI_ADDR_WIDTH	= 7

    ,localparam CTRL_REG_START_CORE_IDX     = 0 // start the core. Converted to POSEDGE PULSE
    ,localparam CTRL_REG_END_CORE_IDX       = 1 // end the core, clear DTP_FIN bit in STT_REG. Converted to POSEDGE PULSE
    ,localparam CTRL_REG_THSH_VLD_IDX       = 2 // VLD signal with SAMP_THSH_REG. Converted to POSEDGE PULSE
    ,localparam CTRL_REG_THSH_CLR_IDX       = 3 // CLEAR signal for THSH_DONE bit in STT_REG
    ,localparam CTRL_REG_TREE_RAM_READY_IDX = 4 // READY signal for DTP Tree RAM

    ,localparam STT_REG_DTP_FIN_IDX         = 0 // 1: core is finish
    ,localparam STT_REG_THSH_DONE_IDX       = 1 // 1: threshold in sample FIFO is completely set
) (
     input clk
    ,input rst_n,

// BRAM SAMPLE FIFO----------------------------------------------------------------------     
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 SAMPLE_BRAM_PORT EN" *)
    input                                 bram_en_samp, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 SAMPLE_BRAM_PORT DOUT" *)
    output [31 : 0]                       bram_dout_samp, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 SAMPLE_BRAM_PORT DIN" *)
    input [31 : 0]                        bram_din_samp, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 SAMPLE_BRAM_PORT WE" *)
    input [3 : 0]                         bram_we_samp, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 SAMPLE_BRAM_PORT ADDR" *)
    input [SAMPLE_FIFO_DEPTH_BIT+2-1 : 0] bram_addr_samp, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 SAMPLE_BRAM_PORT CLK" *)
    input                                 bram_clk_samp, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 SAMPLE_BRAM_PORT RST" *)
    input                                 bram_rst_samp, // Reset Signal (required)

// BRAM DTP----------------------------------------------------------------------
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 EN" *)
    input                           bram_en_0, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 DOUT" *)
    output [31 : 0]                 bram_dout_0, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 DIN" *)
    input [31 : 0]                  bram_din_0, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 WE" *)
    input [3 : 0]                   bram_we_0, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_0, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 CLK" *)
    input                           bram_clk_0, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_0 RST" *)
    input                           bram_rst_0, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_1 EN" *)
    input                           bram_en_1, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_1 DOUT" *)
    output [31 : 0]                 bram_dout_1, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_1 DIN" *)
    input [31 : 0]                  bram_din_1, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_1 WE" *)
    input [3 : 0]                   bram_we_1, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_1 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_1, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_1 CLK" *)
    input                           bram_clk_1, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_1 RST" *)
    input                           bram_rst_1, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_2 EN" *)
    input                           bram_en_2, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_2 DOUT" *)
    output [31 : 0]                 bram_dout_2, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_2 DIN" *)
    input [31 : 0]                  bram_din_2, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_2 WE" *)
    input [3 : 0]                   bram_we_2, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_2 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_2, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_2 CLK" *)
    input                           bram_clk_2, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_2 RST" *)
    input                           bram_rst_2, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_3 EN" *)
    input                           bram_en_3, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_3 DOUT" *)
    output [31 : 0]                 bram_dout_3, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_3 DIN" *)
    input [31 : 0]                  bram_din_3, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_3 WE" *)
    input [3 : 0]                   bram_we_3, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_3 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_3, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_3 CLK" *)
    input                           bram_clk_3, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_3 RST" *)
    input                           bram_rst_3, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 65536,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_4 EN" *)
    input                           bram_en_4, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_4 DOUT" *)
    output [31 : 0]                 bram_dout_4, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_4 DIN" *)
    input [31 : 0]                  bram_din_4, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_4 WE" *)
    input [3 : 0]                   bram_we_4, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_4 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_4, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_4 CLK" *)
    input                           bram_clk_4, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_4 RST" *)
    input                           bram_rst_4, // Reset Signal (required)

// VOTE BUFFER BRAM----------------------------------------------------------------------     
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 4096,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT EN" *)
    input                                 bram_en_vote, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT DOUT" *)
    output [31 : 0]                       bram_dout_vote, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT DIN" *)
    input [31 : 0]                        bram_din_vote, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT WE" *)
    input [3 : 0]                         bram_we_vote, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT ADDR" *)
    input [VOTE_DEPTH_BIT+2-1 : 0]        bram_addr_vote, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT CLK" *)
    input                                 bram_clk_vote, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT RST" *)
    input                                 bram_rst_vote, // Reset Signal (required)


// REG_BANK_AXI----------------------------------------------------------------------
    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
    input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
    output wire  S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.    
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    output wire  S_AXI_WREADY,
    // Write response. This signal indicates the status
    // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
    output wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input wire  S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
    input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
    output wire  S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
    // read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
    output wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    input wire  S_AXI_RREADY
);

//----------------------------------------------------------------------------------------
// Parameters
//----------------------------------------------------------------------------------------


//----------------------------------------------------------------------------------------
// Signals
//----------------------------------------------------------------------------------------
    wire                             sample_fifo_pop;
    wire [ATTR_WIDTH-1:0]            sample_fifo_front;
    wire                             sample_fifo_vld;
    wire                             sample_fifo_is_empty;
    wire                             sample_fifo_ptr_rst;

    wire[SAMPLE_FIFO_DEPTH_BIT-1:0]  sample_fifo_thsh_val;
    wire                             sample_fifo_thsh_vld;
    wire                             sample_fifo_thsh_done;
//-------------------------------------------------------------------

    wire                             attr_ram_start;
    wire                             attr_ram_end;

    wire [ATTR_SEL_WIDTH-1:0]        attr_ram_pop_amount;

    wire [N_DTPS*ATTR_WIDTH-1:0]     attr_ram_dout;
    wire [N_DTPS*ATTR_SEL_WIDTH-1:0] attr_ram_sel;
    wire [N_DTPS-1:0]                attr_ram_switch;
    wire                             attr_ram_is_avai;
    wire                             attr_ram_is_done;
//---------------------------------------------------------------------------
    wire                             dtp_tree_ram_is_ready;

    wire                             res_fifo_we [0:N_DTPS-1];
    wire [RES_WIDTH-1:0]             res_fifo_dout [0:N_DTPS-1];

    wire                             dtp_start;
    wire                             dtp_end;
    wire [N_DTPS-1:0]                dtp_is_fin;
//----------------------------------------------------------------------------------------
    wire                             rst_core;
    wire                             start_core;
//----------------------------------------------------------------------------------------
    wire [N_DTPS-1:0]                vote_onehot_sel;

//----------------------------------------------------------------------------------------
// Simulation logic
//----------------------------------------------------------------------------------------
    // reg                             clk_sim = 0;
    // reg                             rst_n_sim = 0;
    // reg                             start_core_sim = 0;
    // reg                             rst_core_sim = 0;
    // reg [SAMPLE_FIFO_DEPTH_BIT-1:0] sample_fifo_thsh_val_sim = (POP_AMOUNT*4)-1;
    // reg                             sample_fifo_thsh_vld_sim = 1;
    // reg [ATTR_SEL_WIDTH-1:0]        attr_ram_pop_amount_sim = POP_AMOUNT-1;
    // reg                             dtp_tree_ram_is_ready_sim = 1;
    // reg [N_DTPS-1:0]                vote_onehot_sel_sim = 5'b00001;

    // wire                            res_vld_mux_sim;
    // wire [RES_WIDTH-1:0]            res_val_mux_sim;
    // wire [VOTE_DEPTH_BIT-1:0]       waddr_sim;


    // wire [DTP_BRAM_AWIDTH*DTP_PIPE_STAGES-1:0]  bram_addr_pipe_sim [0:N_DTPS-1];
    // wire [STATE_CTRL_WIDTH*DTP_PIPE_STAGES-1:0] state_ctrl_pipe_sim [0:N_DTPS-1]; 

    // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp0 [0:DTP_PIPE_STAGES-1];
    // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp1 [0:DTP_PIPE_STAGES-1];
    // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp2 [0:DTP_PIPE_STAGES-1];
    // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp3 [0:DTP_PIPE_STAGES-1];
    // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp4 [0:DTP_PIPE_STAGES-1];

    // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp0 [0:DTP_PIPE_STAGES-1];
    // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp1 [0:DTP_PIPE_STAGES-1];
    // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp2 [0:DTP_PIPE_STAGES-1];
    // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp3 [0:DTP_PIPE_STAGES-1];
    // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp4 [0:DTP_PIPE_STAGES-1];

    // assign clk                  = clk_sim;
    // assign rst_n                = rst_n_sim;
    // assign start_core           = start_core_sim;
    // assign rst_core             = rst_core_sim;
    // assign sample_fifo_thsh_vld = sample_fifo_thsh_vld_sim;
    // assign dtp_tree_ram_is_ready= dtp_tree_ram_is_ready_sim;
    // assign sample_fifo_thsh_val = sample_fifo_thsh_val_sim;
    // assign attr_ram_pop_amount  = attr_ram_pop_amount_sim;
    // assign vote_onehot_sel      = vote_onehot_sel_sim;

    // generate
    //     for(genvar p=0; p<DTP_PIPE_STAGES; p=p+1) begin
    //             assign bram_addr_pipe_dtp0[p] = bram_addr_pipe_sim[0][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             assign bram_addr_pipe_dtp1[p] = bram_addr_pipe_sim[1][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             assign bram_addr_pipe_dtp2[p] = bram_addr_pipe_sim[2][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             assign bram_addr_pipe_dtp3[p] = bram_addr_pipe_sim[3][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             assign bram_addr_pipe_dtp4[p] = bram_addr_pipe_sim[4][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];

    //             assign state_ctrl_pipe_dtp0[p] = state_ctrl_pipe_sim[0][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             assign state_ctrl_pipe_dtp1[p] = state_ctrl_pipe_sim[1][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             assign state_ctrl_pipe_dtp2[p] = state_ctrl_pipe_sim[2][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             assign state_ctrl_pipe_dtp3[p] = state_ctrl_pipe_sim[3][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             assign state_ctrl_pipe_dtp4[p] = state_ctrl_pipe_sim[4][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //     end
    // endgenerate

    // always #5 clk_sim = ~clk_sim;

    // initial begin
    //     #50;
    //     rst_n_sim <= 1;
    //     start_core_sim <= 1;
    //     #10;
    //     start_core_sim <= 0;

    //     #8800;
    //     rst_core_sim <= 1;
    //     #10;
    //     rst_core_sim <= 0;
    //     #10; // minimum delay
    //     start_core_sim <= 1;
    //     #10;
    //     start_core_sim <= 0;
    // end

//----------------------------------------------------------------------------------------
// TOP
//----------------------------------------------------------------------------------------


    assign sample_fifo_ptr_rst = rst_core;
    assign dtp_end             = rst_core;
    assign attr_ram_end        = rst_core;

    assign dtp_start           = start_core;
    assign attr_ram_start      = start_core;


    sample_fifo_paper #(
        .WIDTH    (ATTR_WIDTH),
        .DEPTH_BIT(SAMPLE_FIFO_DEPTH_BIT )
    ) sample_fifo_paper_inst0 (
        .clk         (clk                  ),
        .rst_n       (rst_n                ),
        .i_pop       (sample_fifo_pop      ),
        .o_front     (sample_fifo_front    ),    
        .o_vld       (sample_fifo_vld      ),
        .o_is_empty  (sample_fifo_is_empty ),
        .i_ptr_rst   (sample_fifo_ptr_rst  ),
         
        .i_thsh_val  (sample_fifo_thsh_val ),
        .i_thsh_vld  (sample_fifo_thsh_vld ),
        .o_thsh_done (sample_fifo_thsh_done),

        .bram_en_ps  (bram_en_samp         ),
        .bram_dout_ps(bram_dout_samp       ),
        .bram_din_ps (bram_din_samp        ),
        .bram_we_ps  (bram_we_samp         ),
        .bram_addr_ps(bram_addr_samp       ),
        .bram_clk_ps (bram_clk_samp        ),
        .bram_rst_ps (bram_rst_samp        )
        // .bram_en_ps  (0), // SIMULATION
        // .bram_dout_ps( ),
        // .bram_din_ps (0),
        // .bram_we_ps  (0),
        // .bram_addr_ps(0),
        // .bram_clk_ps (clk),
        // .bram_rst_ps (0)

    );
    
    
    attribute_ram #(
        .ATTR_WIDTH(ATTR_WIDTH),
        .ATTR_ABIT (ATTR_SEL_WIDTH),
        .N_DTPS    (N_DTPS )
    ) attribute_ram_inst0 (
        .clk                   (clk                 ),
        .rst_n                 (rst_n               ),    
        .i_attr_ram_start      (attr_ram_start      ),    
        .i_attr_ram_end        (attr_ram_end        ),
        
        .i_fifo_front          (sample_fifo_front   ),
        .i_fifo_vld            (sample_fifo_vld     ),
        .i_fifo_is_empty       (sample_fifo_is_empty), 
        .i_pop_amount          (attr_ram_pop_amount ),   
        .o_fifo_pop            (sample_fifo_pop     ),    
        
        .o_attr_ram_dout       (attr_ram_dout       ),    
        .i_attr_ram_sel        (attr_ram_sel        ),
        .i_attr_ram_switch     (attr_ram_switch     ),    
        .o_is_attr_ram_avai    (attr_ram_is_avai    ),
        .o_is_sample_done      (attr_ram_is_done    )
    );
//----------------------------------------------------------------------------------------
// DTPs
//----------------------------------------------------------------------------------------


    dtp_paper #(
        .DTP_IDX(0)
    )dtp_inst_0(
        .clk                 (clk                                              ),
        .rst_n               (rst_n                                            ),

        .i_attr_ram_dout     (attr_ram_dout[0*ATTR_WIDTH +: ATTR_WIDTH]        ),    
        .o_attr_ram_sel      (attr_ram_sel[0*ATTR_SEL_WIDTH +: ATTR_SEL_WIDTH] ),    
        .o_attr_ram_switch   (attr_ram_switch[0]                               ),    
        .i_is_attr_ram_avai  (attr_ram_is_avai                                 ),    
        .i_is_sample_done    (attr_ram_is_done                                 ),  
        
        .i_tree_ram_ready    (dtp_tree_ram_is_ready                            ),  
        
        .i_res_fifo_is_full  (1'b0                                             ),    
        .o_res_fifo_we       (res_fifo_we[0]                                   ),
        .o_res_fifo_dout     (res_fifo_dout[0]                                 ),
                                
        .i_dtp_start         (dtp_start                                        ),    
        .i_dtp_end           (dtp_end                                          ),    
        .o_dtp_fin           (dtp_is_fin[0]                                    ),   
                        
        .bram_en_ps          (bram_en_0                                ),  
        .bram_dout_ps        (bram_dout_0                              ),      
        .bram_din_ps         (bram_din_0                               ),      
        .bram_we_ps          (bram_we_0                                ),  
        .bram_addr_ps        (bram_addr_0                              ),  
        .bram_clk_ps         (bram_clk_0                               ),  
        .bram_rst_ps         (bram_rst_0                               )
        // .bram_en_ps          (0                              ), // SIMULATION
        // .bram_dout_ps        (                               ),
        // .bram_din_ps         (0                              ),
        // .bram_we_ps          (0                              ),
        // .bram_addr_ps        (0                              ),
        // .bram_clk_ps         (clk                              ),
        // .bram_rst_ps         (0                              ),
        // .bram_addr_pipe_sim  (bram_addr_pipe_sim[0]          ),
        // .state_ctrl_pipe_sim (state_ctrl_pipe_sim[0]         )
    );

    dtp_paper #(
        .DTP_IDX(1)
    )dtp_inst_1(
        .clk                 (clk                                              ),
        .rst_n               (rst_n                                            ),

        .i_attr_ram_dout     (attr_ram_dout[1*ATTR_WIDTH +: ATTR_WIDTH]        ),    
        .o_attr_ram_sel      (attr_ram_sel[1*ATTR_SEL_WIDTH +: ATTR_SEL_WIDTH] ),    
        .o_attr_ram_switch   (attr_ram_switch[1]                               ),    
        .i_is_attr_ram_avai  (attr_ram_is_avai                                 ),    
        .i_is_sample_done    (attr_ram_is_done                                 ),  
        
        .i_tree_ram_ready    (dtp_tree_ram_is_ready                            ),  
        
        .i_res_fifo_is_full  (1'b0                                             ),    
        .o_res_fifo_we       (res_fifo_we[1]                                   ),
        .o_res_fifo_dout     (res_fifo_dout[1]                                 ), 
                                
        .i_dtp_start         (dtp_start                                        ),    
        .i_dtp_end           (dtp_end                                          ),    
        .o_dtp_fin           (dtp_is_fin[1]                                    ),   
                        
        .bram_en_ps          (bram_en_1                                ),
        .bram_dout_ps        (bram_dout_1                              ),
        .bram_din_ps         (bram_din_1                               ),
        .bram_we_ps          (bram_we_1                                ),
        .bram_addr_ps        (bram_addr_1                              ),
        .bram_clk_ps         (bram_clk_1                               ),
        .bram_rst_ps         (bram_rst_1                               )
        // .bram_en_ps          (0                              ), // SIMULATION
        // .bram_dout_ps        (                               ),
        // .bram_din_ps         (0                              ),
        // .bram_we_ps          (0                              ),
        // .bram_addr_ps        (0                              ),
        // .bram_clk_ps         (clk                              ),
        // .bram_rst_ps         (0                              ),
        // .bram_addr_pipe_sim  (bram_addr_pipe_sim[1]          ),
        // .state_ctrl_pipe_sim (state_ctrl_pipe_sim[1]         )
    );

    dtp_paper #(
        .DTP_IDX(2)
    )dtp_inst_2(
        .clk                 (clk                                              ),
        .rst_n               (rst_n                                            ),
        
        .i_attr_ram_dout     (attr_ram_dout[2*ATTR_WIDTH +: ATTR_WIDTH]        ),    
        .o_attr_ram_sel      (attr_ram_sel[2*ATTR_SEL_WIDTH +: ATTR_SEL_WIDTH] ),    
        .o_attr_ram_switch   (attr_ram_switch[2]                               ),    
        .i_is_attr_ram_avai  (attr_ram_is_avai                                 ),    
        .i_is_sample_done    (attr_ram_is_done                                 ),  
        
        .i_tree_ram_ready    (dtp_tree_ram_is_ready                            ),  
        
        .i_res_fifo_is_full  (1'b0                                             ),    
        .o_res_fifo_we       (res_fifo_we[2]                                   ),
        .o_res_fifo_dout     (res_fifo_dout[2]                                 ), 
                                
        .i_dtp_start         (dtp_start                                        ),    
        .i_dtp_end           (dtp_end                                          ),    
        .o_dtp_fin           (dtp_is_fin[2]                                    ),   
                        
        .bram_en_ps          (bram_en_2                                ),
        .bram_dout_ps        (bram_dout_2                              ),
        .bram_din_ps         (bram_din_2                               ),
        .bram_we_ps          (bram_we_2                                ),
        .bram_addr_ps        (bram_addr_2                              ),
        .bram_clk_ps         (bram_clk_2                               ),
        .bram_rst_ps         (bram_rst_2                               )
        // .bram_en_ps          (0                              ), // SIMULATION
        // .bram_dout_ps        (                               ),
        // .bram_din_ps         (0                              ),
        // .bram_we_ps          (0                              ),
        // .bram_addr_ps        (0                              ),
        // .bram_clk_ps         (clk                              ),
        // .bram_rst_ps         (0                              ),
        // .bram_addr_pipe_sim  (bram_addr_pipe_sim[2]          ),
        // .state_ctrl_pipe_sim (state_ctrl_pipe_sim[2]         )
    );

    dtp_paper #(
        .DTP_IDX(3)
    )dtp_inst_3(
        .clk                 (clk                                              ),
        .rst_n               (rst_n                                            ),
        
        .i_attr_ram_dout     (attr_ram_dout[3*ATTR_WIDTH +: ATTR_WIDTH]        ),    
        .o_attr_ram_sel      (attr_ram_sel[3*ATTR_SEL_WIDTH +: ATTR_SEL_WIDTH] ),    
        .o_attr_ram_switch   (attr_ram_switch[3]                               ),    
        .i_is_attr_ram_avai  (attr_ram_is_avai                                 ),    
        .i_is_sample_done    (attr_ram_is_done                                 ),  
        
        .i_tree_ram_ready    (dtp_tree_ram_is_ready                            ),  
        
        .i_res_fifo_is_full  (1'b0                                             ),    
        .o_res_fifo_we       (res_fifo_we[3]                                   ),
        .o_res_fifo_dout     (res_fifo_dout[3]                                 ),   
                                
        .i_dtp_start         (dtp_start                                        ),    
        .i_dtp_end           (dtp_end                                          ),    
        .o_dtp_fin           (dtp_is_fin[3]                                    ),   
                        
        .bram_en_ps          (bram_en_3                                ),
        .bram_dout_ps        (bram_dout_3                              ),
        .bram_din_ps         (bram_din_3                               ),
        .bram_we_ps          (bram_we_3                                ),
        .bram_addr_ps        (bram_addr_3                              ),
        .bram_clk_ps         (bram_clk_3                               ),
        .bram_rst_ps         (bram_rst_3                               )
        // .bram_en_ps          (0                              ), // SIMULATION
        // .bram_dout_ps        (                               ),
        // .bram_din_ps         (0                              ),
        // .bram_we_ps          (0                              ),
        // .bram_addr_ps        (0                              ),
        // .bram_clk_ps         (clk                              ),
        // .bram_rst_ps         (0                              ),
        // .bram_addr_pipe_sim  (bram_addr_pipe_sim[3]          ),
        // .state_ctrl_pipe_sim (state_ctrl_pipe_sim[3]         )
    );

    dtp_paper #(
        .DTP_IDX(4)
    )dtp_inst_4(
        .clk                 (clk                                              ),
        .rst_n               (rst_n                                            ),
        
        .i_attr_ram_dout     (attr_ram_dout[4*ATTR_WIDTH +: ATTR_WIDTH]        ),    
        .o_attr_ram_sel      (attr_ram_sel[4*ATTR_SEL_WIDTH +: ATTR_SEL_WIDTH] ),    
        .o_attr_ram_switch   (attr_ram_switch[4]                               ),    
        .i_is_attr_ram_avai  (attr_ram_is_avai                                 ),    
        .i_is_sample_done    (attr_ram_is_done                                 ),  
        
        .i_tree_ram_ready    (dtp_tree_ram_is_ready                            ),  
        
        .i_res_fifo_is_full  (1'b0                                             ),    
        .o_res_fifo_we       (res_fifo_we[4]                                   ),
        .o_res_fifo_dout     (res_fifo_dout[4]                                 ),   
                                
        .i_dtp_start         (dtp_start                                        ),    
        .i_dtp_end           (dtp_end                                          ),    
        .o_dtp_fin           (dtp_is_fin[4]                                    ),   
                        
        .bram_en_ps          (bram_en_4                                ),
        .bram_dout_ps        (bram_dout_4                              ),
        .bram_din_ps         (bram_din_4                               ),
        .bram_we_ps          (bram_we_4                                ),
        .bram_addr_ps        (bram_addr_4                              ),
        .bram_clk_ps         (bram_clk_4                               ),
        .bram_rst_ps         (bram_rst_4                               )
        // .bram_en_ps          (0                              ), // SIMULATION
        // .bram_dout_ps        (                               ),
        // .bram_din_ps         (0                              ),
        // .bram_we_ps          (0                              ),
        // .bram_addr_ps        (0                              ),
        // .bram_clk_ps         (clk                              ),
        // .bram_rst_ps         (0                              ),
        // .bram_addr_pipe_sim  (bram_addr_pipe_sim[4]          ),
        // .state_ctrl_pipe_sim (state_ctrl_pipe_sim[4]         )
    );
    
//----------------------------------------------------------------------------------------
// REGISTERS BANK
//----------------------------------------------------------------------------------------

    wire [C_S_AXI_DATA_WIDTH-1:0] ctrl_reg;
    wire [C_S_AXI_DATA_WIDTH-1:0] stt_reg;
    wire [C_S_AXI_DATA_WIDTH-1:0] samp_thsh_reg;
    wire [C_S_AXI_DATA_WIDTH-1:0] n_attrs_reg;
    wire [C_S_AXI_DATA_WIDTH-1:0] vote_reg;

    reg dtp_is_fin_reg;
    reg sample_fifo_thsh_done_reg;

    // Control register
    edge_detector #(.IS_POS(1)) 
    (
    .clk  (clk),  
    .rst_n(rst_n),  
    .din  (ctrl_reg[CTRL_REG_START_CORE_IDX]),  
    .eout (start_core)
    );

    edge_detector #(.IS_POS(1)) 
    (
    .clk  (clk),  
    .rst_n(rst_n),  
    .din  (ctrl_reg[CTRL_REG_END_CORE_IDX]),  
    .eout (rst_core)
    );

    edge_detector #(.IS_POS(1)) 
    (
    .clk  (clk),  
    .rst_n(rst_n),  
    .din  (ctrl_reg[CTRL_REG_THSH_VLD_IDX]),  
    .eout (sample_fifo_thsh_vld)
    );

    assign dtp_tree_ram_is_ready = ctrl_reg[CTRL_REG_TREE_RAM_READY_IDX];


    // Sample FIFO threshold register
    assign sample_fifo_thsh_val = samp_thsh_reg[SAMPLE_FIFO_DEPTH_BIT-1:0];

    // Number of attributes register
    assign attr_ram_pop_amount = n_attrs_reg[ATTR_SEL_WIDTH-1:0];


    // Status register
    assign stt_reg[STT_REG_DTP_FIN_IDX]    = dtp_is_fin_reg;
    assign stt_reg[STT_REG_THSH_DONE_IDX]  = sample_fifo_thsh_done_reg;
    assign stt_reg[C_S_AXI_DATA_WIDTH-1:2] = {(C_S_AXI_DATA_WIDTH-2){1'b0}};

    always @(posedge clk) begin
        if(!rst_n) begin
            dtp_is_fin_reg <= 0;
        end
        else begin
            if(dtp_is_fin == {N_DTPS{1'b1}})
                dtp_is_fin_reg <= 1;
            else if(rst_core)
                dtp_is_fin_reg <= 0;
            else
                dtp_is_fin_reg <= dtp_is_fin_reg;
        end
    end
    
    always @(posedge clk) begin
        if(!rst_n) begin
            sample_fifo_thsh_done_reg <= 0;
        end
        else begin
            if(sample_fifo_thsh_done)
                sample_fifo_thsh_done_reg <= 1;
            else if(ctrl_reg[CTRL_REG_THSH_CLR_IDX])
                sample_fifo_thsh_done_reg <= 0;
            else
                sample_fifo_thsh_done_reg <= sample_fifo_thsh_done_reg;
        end
    end

    // VOTE REG
    assign vote_onehot_sel = vote_reg[N_DTPS-1:0];


    regs_bank #(
            .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
        ) regs_bank_inst_0 (
            // Users to add ports here
            .ctrl_reg       (ctrl_reg     ),// reg0
            .stt_reg        (stt_reg      ),// reg1
            .samp_thsh_reg  (samp_thsh_reg),// reg2
            .n_attrs_reg    (n_attrs_reg  ),// reg3
            .vote_reg       (vote_reg     ),// reg4


            .S_AXI_ACLK     (S_AXI_ACLK   ),
            .S_AXI_ARESETN  (S_AXI_ARESETN),
            .S_AXI_AWADDR   (S_AXI_AWADDR ),
            .S_AXI_AWPROT   (S_AXI_AWPROT ),
            .S_AXI_AWVALID  (S_AXI_AWVALID),
            .S_AXI_AWREADY  (S_AXI_AWREADY),
            .S_AXI_WDATA    (S_AXI_WDATA  ),
            .S_AXI_WSTRB    (S_AXI_WSTRB  ),
            .S_AXI_WVALID   (S_AXI_WVALID ),
            .S_AXI_WREADY   (S_AXI_WREADY ),
            .S_AXI_BRESP    (S_AXI_BRESP  ),
            .S_AXI_BVALID   (S_AXI_BVALID ),
            .S_AXI_BREADY   (S_AXI_BREADY ),
            .S_AXI_ARADDR   (S_AXI_ARADDR ),
            .S_AXI_ARPROT   (S_AXI_ARPROT ),
            .S_AXI_ARVALID  (S_AXI_ARVALID),
            .S_AXI_ARREADY  (S_AXI_ARREADY),
            .S_AXI_RDATA    (S_AXI_RDATA  ),
            .S_AXI_RRESP    (S_AXI_RRESP  ),
            .S_AXI_RVALID   (S_AXI_RVALID ),
            .S_AXI_RREADY   (S_AXI_RREADY )
        );


//----------------------------------------------------------------------------------------
// VOTE BUFFER
//----------------------------------------------------------------------------------------

    vote_buffer_paper #(
        .N_DTPS   (N_DTPS        ),
        .RES_WIDTH(RES_WIDTH     ),
        .DEPTH_BIT(VOTE_DEPTH_BIT)
    ) vote_inst_0 (
        .clk          (clk),  
        .rst_n        (rst_n),  
        .buffer_rst   (rst_core),  

        .onehot_sel   (vote_onehot_sel),  
        .res_vld      ({res_fifo_we[4],res_fifo_we[3],res_fifo_we[2],res_fifo_we[1],res_fifo_we[0]}),  
//        .res_val      ({res_fifo_dout[4],res_fifo_dout[3],res_fifo_dout[2],res_fifo_dout[1],res_fifo_dout[0]}),
        .res_val      ({{RES_WIDTH{1'b1}},{RES_WIDTH{1'b1}},{RES_WIDTH{1'b1}},{RES_WIDTH{1'b1}},{RES_WIDTH{1'b1}}}),  

       .bram_en_ps   (bram_en_vote  ),
       .bram_dout_ps (bram_dout_vote),
       .bram_din_ps  (bram_din_vote ),
       .bram_we_ps   (bram_we_vote  ),
       .bram_addr_ps (bram_addr_vote),
       .bram_clk_ps  (bram_clk_vote ),
       .bram_rst_ps  (bram_rst_vote )
        // .res_vld_mux_sim(res_vld_mux_sim), // SIMULATION
        // .res_val_mux_sim(res_val_mux_sim),
        // .waddr_sim      (waddr_sim      ),

        // .bram_en_ps   (0  ),
        // .bram_dout_ps (),
        // .bram_din_ps  (0 ),
        // .bram_we_ps   (0  ),
        // .bram_addr_ps (0),
        // .bram_clk_ps  (clk ),
        // .bram_rst_ps  (0 )

    ); 


endmodule