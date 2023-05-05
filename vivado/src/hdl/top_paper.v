`timescale 1ns / 1ps
// Change number of DTPs: N_DTPS, DTP_BRAM_AWIDTH(also change BRAM config), DTP_BRAM_PORT, MEM_SIZE(=2^(DTP_BRAM_AWIDTH+2)), i_in_fifo_rear(Accumulator), Case N_DTPS=1(in Accumulator)
// Simulation:
// + Comment: I/O, REGISTERS BANK
// + Uncomment: SIMULATION LOGIC, SIMULATION_ON

module top_paper #(
     localparam DTP_PIPE_STAGES      = 5
    ,localparam ATTR_WIDTH           = 16
    ,localparam ATTR_SEL_WIDTH       = 5
    
    ,localparam RES_WIDTH            = 16
    
    ,localparam STATE_CTRL_WIDTH     = 2 // SIMULATION
    ,localparam STATE_DTP_WIDTH      = 2
    ,localparam STATE_FIFO_WIDTH     = 2

    ,localparam N_DTPS               = 15 // edit when changing N_DTPs
    ,localparam DTP_BRAM_AWIDTH      = 13 // edit when changing N_DTPs
    ,localparam IS_INT               = 0
    ,localparam POP_AMOUNT           = 8 // unit: attributes/sample (just for simulation)
    ,localparam N_LABELS             = 2 // number of labels for classification
    ,localparam IS_CLF               = 0 // just for simulation

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
    ,localparam CTRL_REG_IS_PS_READ_IDX     = 5 // READ signal to read vote bram
    ,localparam CTRL_REG_IS_CLF_IDX         = 6 // signal to indicate if it is classification

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
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *) 
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

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
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

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
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

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
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

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
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

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_5 EN" *)
    input                           bram_en_5, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_5 DOUT" *)
    output [31 : 0]                 bram_dout_5, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_5 DIN" *)
    input [31 : 0]                  bram_din_5, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_5 WE" *)
    input [3 : 0]                   bram_we_5, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_5 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_5, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_5 CLK" *)
    input                           bram_clk_5, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_5 RST" *)
    input                           bram_rst_5, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_6 EN" *)
    input                           bram_en_6, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_6 DOUT" *)
    output [31 : 0]                 bram_dout_6, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_6 DIN" *)
    input [31 : 0]                  bram_din_6, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_6 WE" *)
    input [3 : 0]                   bram_we_6, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_6 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_6, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_6 CLK" *)
    input                           bram_clk_6, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_6 RST" *)
    input                           bram_rst_6, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_7 EN" *)
    input                           bram_en_7, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_7 DOUT" *)
    output [31 : 0]                 bram_dout_7, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_7 DIN" *)
    input [31 : 0]                  bram_din_7, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_7 WE" *)
    input [3 : 0]                   bram_we_7, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_7 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_7, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_7 CLK" *)
    input                           bram_clk_7, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_7 RST" *)
    input                           bram_rst_7, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_8 EN" *)
    input                           bram_en_8, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_8 DOUT" *)
    output [31 : 0]                 bram_dout_8, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_8 DIN" *)
    input [31 : 0]                  bram_din_8, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_8 WE" *)
    input [3 : 0]                   bram_we_8, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_8 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_8, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_8 CLK" *)
    input                           bram_clk_8, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_8 RST" *)
    input                           bram_rst_8, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_9 EN" *)
    input                           bram_en_9, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_9 DOUT" *)
    output [31 : 0]                 bram_dout_9, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_9 DIN" *)
    input [31 : 0]                  bram_din_9, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_9 WE" *)
    input [3 : 0]                   bram_we_9, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_9 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_9, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_9 CLK" *)
    input                           bram_clk_9, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_9 RST" *)
    input                           bram_rst_9, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_10 EN" *)
    input                           bram_en_10, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_10 DOUT" *)
    output [31 : 0]                 bram_dout_10, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_10 DIN" *)
    input [31 : 0]                  bram_din_10, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_10 WE" *)
    input [3 : 0]                   bram_we_10, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_10 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_10, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_10 CLK" *)
    input                           bram_clk_10, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_10 RST" *)
    input                           bram_rst_10, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_11 EN" *)
    input                           bram_en_11, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_11 DOUT" *)
    output [31 : 0]                 bram_dout_11, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_11 DIN" *)
    input [31 : 0]                  bram_din_11, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_11 WE" *)
    input [3 : 0]                   bram_we_11, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_11 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_11, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_11 CLK" *)
    input                           bram_clk_11, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_11 RST" *)
    input                           bram_rst_11, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_12 EN" *)
    input                           bram_en_12, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_12 DOUT" *)
    output [31 : 0]                 bram_dout_12, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_12 DIN" *)
    input [31 : 0]                  bram_din_12, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_12 WE" *)
    input [3 : 0]                   bram_we_12, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_12 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_12, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_12 CLK" *)
    input                           bram_clk_12, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_12 RST" *)
    input                           bram_rst_12, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_13 EN" *)
    input                           bram_en_13, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_13 DOUT" *)
    output [31 : 0]                 bram_dout_13, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_13 DIN" *)
    input [31 : 0]                  bram_din_13, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_13 WE" *)
    input [3 : 0]                   bram_we_13, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_13 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_13, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_13 CLK" *)
    input                           bram_clk_13, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_13 RST" *)
    input                           bram_rst_13, // Reset Signal (required)

    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_14 EN" *)
    input                           bram_en_14, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_14 DOUT" *)
    output [31 : 0]                 bram_dout_14, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_14 DIN" *)
    input [31 : 0]                  bram_din_14, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_14 WE" *)
    input [3 : 0]                   bram_we_14, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_14 ADDR" *)
    input [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_14, // Address Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_14 CLK" *)
    input                           bram_clk_14, // Clock Signal (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 DTP_BRAM_PORT_14 RST" *)
    input                           bram_rst_14, // Reset Signal (required)

// VOTE BUFFER----------------------------------------------------------------------     
    (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL,MEM_ECC NONE,MEM_WIDTH 32,MEM_SIZE 32768,READ_WRITE_MODE READ_WRITE" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT EN" *)
    input                                 bram_en_vote, // Chip Enable Signal (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT DOUT" *)
    output [31 : 0]                       bram_dout_vote, // Data Out Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT DIN" *)
    input [31 : 0]                        bram_din_vote, // Data In Bus (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT WE" *)
    input [3 : 0]                         bram_we_vote, // Byte Enables (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 VOTE_BRAM_PORT ADDR" *)
    input [SAMPLE_FIFO_DEPTH_BIT+2-1 : 0] bram_addr_vote, // Address Signal (required)
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

    wire                             attr_ram_is_all_dtp_switch;
//---------------------------------------------------------------------------
    wire                             dtp_tree_ram_is_ready;

    wire [N_DTPS-1:0]                res_fifo_we;
    wire [RES_WIDTH-1:0]             res_fifo_dout [0:N_DTPS-1];
    wire [N_DTPS-1:0]                res_fifo_is_full;

    wire                             dtp_start;
    wire                             dtp_end;
    wire [N_DTPS-1:0]                dtp_is_fin;
//----------------------------------------------------------------------------------------
    wire                             rst_core;
    wire                             start_core;
    wire                             is_ps_read;
    wire                             is_clf;
//----------------------------------------------------------------------------------------
    wire                             is_system_fin;
    reg                              is_system_fin_reg;

//----------------------------------------------------------------------------------------
// SIMULATION LOGIC
//----------------------------------------------------------------------------------------
    // reg                             clk_sim = 0;
    // reg                             rst_n_sim = 0;
    // reg                             start_core_sim = 0;
    // reg                             rst_core_sim = 0;
    // reg [SAMPLE_FIFO_DEPTH_BIT-1:0] sample_fifo_thsh_val_sim = (POP_AMOUNT*4)-1; // 4 samples to be popped out
    // reg                             sample_fifo_thsh_vld_sim = 1;
    // reg [ATTR_SEL_WIDTH-1:0]        attr_ram_pop_amount_sim = POP_AMOUNT-1;
    // reg                             dtp_tree_ram_is_ready_sim = 1;
    // reg                             is_ps_read_sim=0;
    // reg                             is_clf_sim=IS_CLF;

    // reg                                     bram_en_vote_sim=0;  
    // wire [31 : 0]                           bram_dout_vote_sim;
    // reg  [31 : 0]                           bram_din_vote_sim = 0; 
    // reg  [3 : 0]                            bram_we_vote_sim = 0;  
    // reg  [SAMPLE_FIFO_DEPTH_BIT+2-1 : 0]    bram_addr_vote_sim = 0;
    // reg                                     bram_rst_vote_sim = 0; 


    // wire [DTP_BRAM_AWIDTH*DTP_PIPE_STAGES-1:0]  bram_addr_pipe_sim [0:N_DTPS-1];
    // wire [STATE_CTRL_WIDTH*DTP_PIPE_STAGES-1:0] state_ctrl_pipe_sim [0:N_DTPS-1]; 

    // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp0 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp1 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp2 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp3 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp4 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp5 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp6 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp7 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp8 [0:DTP_PIPE_STAGES-1];
    // // wire [DTP_BRAM_AWIDTH-1:0]               bram_addr_pipe_dtp9 [0:DTP_PIPE_STAGES-1];

    // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp0 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp1 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp2 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp3 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp4 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp5 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp6 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp7 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp8 [0:DTP_PIPE_STAGES-1];
    // // wire [STATE_CTRL_WIDTH-1:0]              state_ctrl_pipe_dtp9 [0:DTP_PIPE_STAGES-1];

    // wire [ATTR_WIDTH-1:0]                    attr_ram_dout_sim [0:N_DTPS-1];
    // wire [ATTR_SEL_WIDTH-1:0]                attr_ram_sel_sim [0:N_DTPS-1];
    // wire [15:0]                              thsh_sim [0:N_DTPS-1];

    // wire [RES_WIDTH*N_LABELS-1:0]            clf_accum_out_sim;
    // wire [RES_WIDTH-1:0]                     clf_accum_out_s [0:N_LABELS-1];

    // // wire                                     res_vld_sim;
    // // wire [RES_WIDTH-1:0]                     res_val_sim;
    // // wire [SAMPLE_FIFO_DEPTH_BIT-1:0]         vote_slot_sim;

    // wire [15:0]                                 write_bram_din_sim;
    // wire [SAMPLE_FIFO_DEPTH_BIT-1:0]            write_bram_addr_sim;
    // wire                                        write_bram_we_sim; 
    // wire [RES_WIDTH-1:0]                         accum_res_sim, accum_res_pipe_sim;

    // assign clk                  = clk_sim;
    // assign rst_n                = rst_n_sim;
    // assign start_core           = start_core_sim;
    // assign rst_core             = rst_core_sim;
    // assign sample_fifo_thsh_vld = sample_fifo_thsh_vld_sim;
    // assign dtp_tree_ram_is_ready= dtp_tree_ram_is_ready_sim;
    // assign sample_fifo_thsh_val = sample_fifo_thsh_val_sim;
    // assign attr_ram_pop_amount  = attr_ram_pop_amount_sim;
    // assign is_ps_read           = is_ps_read_sim;
    // assign is_clf               = is_clf_sim;

    // generate
    //     for(genvar d=0; d<N_DTPS; d=d+1) begin
    //         assign attr_ram_dout_sim[d] = attr_ram_dout[d*ATTR_WIDTH +: ATTR_WIDTH];
    //         assign attr_ram_sel_sim[d] = attr_ram_sel[d*ATTR_SEL_WIDTH +: ATTR_SEL_WIDTH];
    //     end
    // endgenerate 

    // generate
    //     for(genvar l=0; l<N_LABELS; l=l+1) begin
    //         assign clf_accum_out_s[l] = clf_accum_out_sim[l*RES_WIDTH +: RES_WIDTH];
    //     end
    // endgenerate
    
    // generate
    //     for(genvar p=0; p<DTP_PIPE_STAGES; p=p+1) begin
    //             assign bram_addr_pipe_dtp0[p] = bram_addr_pipe_sim[0][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp1[p] = bram_addr_pipe_sim[1][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp2[p] = bram_addr_pipe_sim[2][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp3[p] = bram_addr_pipe_sim[3][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp4[p] = bram_addr_pipe_sim[4][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp5[p] = bram_addr_pipe_sim[5][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp6[p] = bram_addr_pipe_sim[6][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp7[p] = bram_addr_pipe_sim[7][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp8[p] = bram_addr_pipe_sim[8][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];
    //             // assign bram_addr_pipe_dtp9[p] = bram_addr_pipe_sim[9][p*DTP_BRAM_AWIDTH +: DTP_BRAM_AWIDTH];

    //             assign state_ctrl_pipe_dtp0[p] = state_ctrl_pipe_sim[0][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp1[p] = state_ctrl_pipe_sim[1][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp2[p] = state_ctrl_pipe_sim[2][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp3[p] = state_ctrl_pipe_sim[3][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp4[p] = state_ctrl_pipe_sim[4][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp5[p] = state_ctrl_pipe_sim[5][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp6[p] = state_ctrl_pipe_sim[6][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp7[p] = state_ctrl_pipe_sim[7][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp8[p] = state_ctrl_pipe_sim[8][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //             // assign state_ctrl_pipe_dtp9[p] = state_ctrl_pipe_sim[9][p*STATE_CTRL_WIDTH +: STATE_CTRL_WIDTH];
    //     end
    // endgenerate

    // always #5 clk_sim = ~clk_sim;
    
    // integer i_read=0,i_check=0;
    // initial begin: INIT_BLOCK
    //     #50;
    //     rst_n_sim <= 1;
    //     start_core_sim <= 1;
    //     #10;
    //     start_core_sim <= 0;

    //     // // regression
    //     // // #8800; // 5 dtp
    //     // // #10800; // 4 dtp
    //     // // #14800; // 3 dtp
    //     // // #22800; // 2 dtp
    //     // // #40800; // 1 dtp

    //     // // classification
    //     // // #16650; // 5 dtp
    //     // // rst_core_sim <= 1;
    //     // // #10;
    //     // // rst_core_sim <= 0;
    //     // // #10; // minimum delay
    //     // // start_core_sim <= 1;
    //     // // #10;
    //     // // start_core_sim <= 0;

    //     // classification readout vote bram
    //     #240000; // 5 dtp

    //     is_ps_read_sim <= 1;
    //     bram_en_vote_sim <= 1;
    //     bram_addr_vote_sim <= 0;
    //     #10;

    //     // for(i_read=0; i_read<4; i_read=i_read+1) begin: LOOP_READ
    //     for(i_read=0; i_read<4*POP_AMOUNT; i_read=i_read+1) begin: LOOP_READ
    //         bram_addr_vote_sim <= bram_addr_vote_sim + 4;
    //         #10;
    //     end
    //     // check if vote bram is clear
    //     bram_addr_vote_sim <= 0;
    //     #10;
    //     // for(i_check=0; i_check<4; i_check=i_check+1) begin: LOOP_CHECK
    //     for(i_check=0; i_check<4*POP_AMOUNT; i_check=i_check+1) begin: LOOP_CHECK
    //         bram_addr_vote_sim <= bram_addr_vote_sim + 4;
    //         #10;
    //     end
    //     is_ps_read_sim <= 0;
    //     bram_en_vote_sim <= 0;
     
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
        // .bram_en_ps  (0), // SIMULATION_ON
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
        .o_is_sample_done      (attr_ram_is_done    ),
        
        .o_is_all_dtp_switch   (attr_ram_is_all_dtp_switch)
    );
//----------------------------------------------------------------------------------------
// DTPs BRAM INTERFACES
//----------------------------------------------------------------------------------------

    wire                           bram_en_dtp [0:N_DTPS-1];
    wire [31 : 0]                  bram_dout_dtp [0:N_DTPS-1];
    wire [31 : 0]                  bram_din_dtp [0:N_DTPS-1];
    wire [3 : 0]                   bram_we_dtp [0:N_DTPS-1];
    wire [DTP_BRAM_AWIDTH+2-1 : 0] bram_addr_dtp [0:N_DTPS-1];
    wire                           bram_clk_dtp [0:N_DTPS-1];
    wire                           bram_rst_dtp [0:N_DTPS-1];

    assign bram_en_dtp  [0] = bram_en_0;
    assign bram_dout_dtp[0] = bram_dout_0;
    assign bram_din_dtp [0] = bram_din_0;
    assign bram_we_dtp  [0] = bram_we_0;
    assign bram_addr_dtp[0] = bram_addr_0;
    assign bram_clk_dtp [0] = bram_clk_0;
    assign bram_rst_dtp [0] = bram_rst_0;

    assign bram_en_dtp  [1] = bram_en_1;
    assign bram_dout_dtp[1] = bram_dout_1;
    assign bram_din_dtp [1] = bram_din_1;
    assign bram_we_dtp  [1] = bram_we_1;
    assign bram_addr_dtp[1] = bram_addr_1;
    assign bram_clk_dtp [1] = bram_clk_1;
    assign bram_rst_dtp [1] = bram_rst_1;

    assign bram_en_dtp  [2] = bram_en_2;
    assign bram_dout_dtp[2] = bram_dout_2;
    assign bram_din_dtp [2] = bram_din_2;
    assign bram_we_dtp  [2] = bram_we_2;
    assign bram_addr_dtp[2] = bram_addr_2;
    assign bram_clk_dtp [2] = bram_clk_2;
    assign bram_rst_dtp [2] = bram_rst_2;

    assign bram_en_dtp  [3] = bram_en_3;
    assign bram_dout_dtp[3] = bram_dout_3;
    assign bram_din_dtp [3] = bram_din_3;
    assign bram_we_dtp  [3] = bram_we_3;
    assign bram_addr_dtp[3] = bram_addr_3;
    assign bram_clk_dtp [3] = bram_clk_3;
    assign bram_rst_dtp [3] = bram_rst_3;

    assign bram_en_dtp  [4] = bram_en_4;
    assign bram_dout_dtp[4] = bram_dout_4;
    assign bram_din_dtp [4] = bram_din_4;
    assign bram_we_dtp  [4] = bram_we_4;
    assign bram_addr_dtp[4] = bram_addr_4;
    assign bram_clk_dtp [4] = bram_clk_4; 
    assign bram_rst_dtp [4] = bram_rst_4;

    assign bram_en_dtp  [5] = bram_en_5;
    assign bram_dout_dtp[5] = bram_dout_5;
    assign bram_din_dtp [5] = bram_din_5;
    assign bram_we_dtp  [5] = bram_we_5;
    assign bram_addr_dtp[5] = bram_addr_5;
    assign bram_clk_dtp [5] = bram_clk_5;
    assign bram_rst_dtp [5] = bram_rst_5;

    assign bram_en_dtp  [6] = bram_en_6;
    assign bram_dout_dtp[6] = bram_dout_6;
    assign bram_din_dtp [6] = bram_din_6;
    assign bram_we_dtp  [6] = bram_we_6;
    assign bram_addr_dtp[6] = bram_addr_6;
    assign bram_clk_dtp [6] = bram_clk_6;
    assign bram_rst_dtp [6] = bram_rst_6;

    assign bram_en_dtp  [7] = bram_en_7;
    assign bram_dout_dtp[7] = bram_dout_7;
    assign bram_din_dtp [7] = bram_din_7;
    assign bram_we_dtp  [7] = bram_we_7;
    assign bram_addr_dtp[7] = bram_addr_7;
    assign bram_clk_dtp [7] = bram_clk_7;
    assign bram_rst_dtp [7] = bram_rst_7;

    assign bram_en_dtp  [8] = bram_en_8;
    assign bram_dout_dtp[8] = bram_dout_8;
    assign bram_din_dtp [8] = bram_din_8;
    assign bram_we_dtp  [8] = bram_we_8;
    assign bram_addr_dtp[8] = bram_addr_8;
    assign bram_clk_dtp [8] = bram_clk_8;
    assign bram_rst_dtp [8] = bram_rst_8;

    assign bram_en_dtp  [9] = bram_en_9;
    assign bram_dout_dtp[9] = bram_dout_9;
    assign bram_din_dtp [9] = bram_din_9;
    assign bram_we_dtp  [9] = bram_we_9;
    assign bram_addr_dtp[9] = bram_addr_9;
    assign bram_clk_dtp [9] = bram_clk_9;
    assign bram_rst_dtp [9] = bram_rst_9;

    assign bram_en_dtp  [10] = bram_en_10;
    assign bram_dout_dtp[10] = bram_dout_10;
    assign bram_din_dtp [10] = bram_din_10;
    assign bram_we_dtp  [10] = bram_we_10;
    assign bram_addr_dtp[10] = bram_addr_10;
    assign bram_clk_dtp [10] = bram_clk_10;
    assign bram_rst_dtp [10] = bram_rst_10;

    assign bram_en_dtp  [11] = bram_en_11;
    assign bram_dout_dtp[11] = bram_dout_11;
    assign bram_din_dtp [11] = bram_din_11;
    assign bram_we_dtp  [11] = bram_we_11;
    assign bram_addr_dtp[11] = bram_addr_11;
    assign bram_clk_dtp [11] = bram_clk_11;
    assign bram_rst_dtp [11] = bram_rst_11;

    assign bram_en_dtp  [12] = bram_en_12;
    assign bram_dout_dtp[12] = bram_dout_12;
    assign bram_din_dtp [12] = bram_din_12;
    assign bram_we_dtp  [12] = bram_we_12;
    assign bram_addr_dtp[12] = bram_addr_12;
    assign bram_clk_dtp [12] = bram_clk_12;
    assign bram_rst_dtp [12] = bram_rst_12;

    assign bram_en_dtp  [13] = bram_en_13;
    assign bram_dout_dtp[13] = bram_dout_13;
    assign bram_din_dtp [13] = bram_din_13;
    assign bram_we_dtp  [13] = bram_we_13;
    assign bram_addr_dtp[13] = bram_addr_13;
    assign bram_clk_dtp [13] = bram_clk_13;
    assign bram_rst_dtp [13] = bram_rst_13;

    assign bram_en_dtp  [14] = bram_en_14;
    assign bram_dout_dtp[14] = bram_dout_14;
    assign bram_din_dtp [14] = bram_din_14;
    assign bram_we_dtp  [14] = bram_we_14;
    assign bram_addr_dtp[14] = bram_addr_14;
    assign bram_clk_dtp [14] = bram_clk_14;
    assign bram_rst_dtp [14] = bram_rst_14;

//----------------------------------------------------------------------------------------
// DTPs
//----------------------------------------------------------------------------------------

    generate
        for (genvar i_dtp = 0; i_dtp < N_DTPS; i_dtp=i_dtp+1) begin
            dtp_paper #(
                .DTP_IDX(i_dtp),
                .BRAM_AWIDTH(DTP_BRAM_AWIDTH),
                .IS_INT(IS_INT)
            )dtp_inst(
                .clk                 (clk                                                  ),
                .rst_n               (rst_n                                                ),

                .i_attr_ram_dout     (attr_ram_dout[i_dtp*ATTR_WIDTH +: ATTR_WIDTH]        ),    
                .o_attr_ram_sel      (attr_ram_sel[i_dtp*ATTR_SEL_WIDTH +: ATTR_SEL_WIDTH] ),    
                .o_attr_ram_switch   (attr_ram_switch[i_dtp]                               ),    
                .i_is_attr_ram_avai  (attr_ram_is_avai                                     ),    
                .i_is_sample_done    (attr_ram_is_done                                     ),  
                
                .i_tree_ram_ready    (dtp_tree_ram_is_ready                                ),  
                
                .i_res_fifo_is_full  (res_fifo_is_full[i_dtp]                              ),    
                .o_res_fifo_we       (res_fifo_we[i_dtp]                                   ),
                .o_res_fifo_dout     (res_fifo_dout[i_dtp]                                 ),
                                        
                .i_dtp_start         (dtp_start                                            ),    
                .i_dtp_end           (dtp_end                                              ),    
                .o_dtp_fin           (dtp_is_fin[i_dtp]                                    ),   
                                
                .bram_en_ps          (bram_en_dtp[i_dtp]                                ),  
                .bram_dout_ps        (bram_dout_dtp[i_dtp]                              ),      
                .bram_din_ps         (bram_din_dtp[i_dtp]                               ),      
                .bram_we_ps          (bram_we_dtp[i_dtp]                                ),  
                .bram_addr_ps        (bram_addr_dtp[i_dtp]                              ),  
                .bram_clk_ps         (bram_clk_dtp[i_dtp]                               ),  
                .bram_rst_ps         (bram_rst_dtp[i_dtp]                               )
                // .bram_en_ps          (0                              ), // SIMULATION_ON
                // .bram_dout_ps        (                               ),
                // .bram_din_ps         (0                              ),
                // .bram_we_ps          (0                              ),
                // .bram_addr_ps        (0                              ),
                // .bram_clk_ps         (clk                            ),
                // .bram_rst_ps         (0                              ),
                // .bram_addr_pipe_sim  (bram_addr_pipe_sim[i_dtp]      ),
                // .state_ctrl_pipe_sim (state_ctrl_pipe_sim[i_dtp]     ),
                // .thsh_sim            (thsh_sim[i_dtp]                )
            );
        end
    endgenerate

//----------------------------------------------------------------------------------------
// REGISTERS BANK
//----------------------------------------------------------------------------------------

    wire [C_S_AXI_DATA_WIDTH-1:0] ctrl_reg;
    wire [C_S_AXI_DATA_WIDTH-1:0] stt_reg;
    wire [C_S_AXI_DATA_WIDTH-1:0] samp_thsh_reg;
    wire [C_S_AXI_DATA_WIDTH-1:0] n_attrs_reg;

    reg sample_fifo_thsh_done_reg;

    // Control register
    edge_detector #(.IS_POS(1)
    ) edge_detector_inst0 (
    .clk  (clk),  
    .rst_n(rst_n),  
    .din  (ctrl_reg[CTRL_REG_START_CORE_IDX]),  
    .eout (start_core)
    );

    edge_detector #(.IS_POS(1)
    ) edge_detector_inst1 (
    .clk  (clk),  
    .rst_n(rst_n),  
    .din  (ctrl_reg[CTRL_REG_END_CORE_IDX]),  
    .eout (rst_core)
    );

    edge_detector #(.IS_POS(1)
    ) edge_detector_inst2 (
    .clk  (clk),  
    .rst_n(rst_n),  
    .din  (ctrl_reg[CTRL_REG_THSH_VLD_IDX]),  
    .eout (sample_fifo_thsh_vld)
    );

    assign dtp_tree_ram_is_ready = ctrl_reg[CTRL_REG_TREE_RAM_READY_IDX];
    assign is_ps_read = ctrl_reg[CTRL_REG_IS_PS_READ_IDX];
    assign is_clf = ctrl_reg[CTRL_REG_IS_CLF_IDX];


    // Sample FIFO threshold register
    assign sample_fifo_thsh_val = samp_thsh_reg[SAMPLE_FIFO_DEPTH_BIT-1:0];

    // Number of attributes register
    assign attr_ram_pop_amount = n_attrs_reg[ATTR_SEL_WIDTH-1:0];


    // Status register
    assign stt_reg[STT_REG_DTP_FIN_IDX]    = is_system_fin_reg;
    assign stt_reg[STT_REG_THSH_DONE_IDX]  = sample_fifo_thsh_done_reg;
    assign stt_reg[C_S_AXI_DATA_WIDTH-1:2] = {(C_S_AXI_DATA_WIDTH-2){1'b0}};
    
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



    regs_bank #(
            .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
        ) regs_bank_inst_0 (
            // Users to add ports here
            .ctrl_reg       (ctrl_reg     ),// reg0
            .stt_reg        (stt_reg      ),// reg1
            .samp_thsh_reg  (samp_thsh_reg),// reg2
            .n_attrs_reg    (n_attrs_reg  ),// reg3


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
// ACCUMULATOR
//----------------------------------------------------------------------------------------
    wire [N_LABELS*RES_WIDTH-1:0]   clf_accum_reg;
    wire [RES_WIDTH-1:0]            rgs_accum_reg;
    wire                            accum_reg_vld;

    wire [N_DTPS*RES_WIDTH-1:0]     res_fifo_dout_all;

    generate
        for(genvar i=0; i<N_DTPS; i=i+1) begin
            assign res_fifo_dout_all[i*RES_WIDTH +: RES_WIDTH] = res_fifo_dout[i];
        end
    endgenerate

    accumulator_paper #(
        .N_DTPS     (N_DTPS    ),
        .FIFO_WIDTH (RES_WIDTH ),
        .FIFO_ABIT  (3         ),
        .N_LABELS   (N_LABELS  )
    ) accumulator_inst (
        .clk              (clk              ),      
        .rst_n            (rst_n            ),      
        .i_is_clf         (is_clf           ),      
        .i_dtp_fin        (attr_ram_is_all_dtp_switch),  
        .o_is_accum_avai  (                 ),      
        .i_in_fifo_push   (res_fifo_we      ),      
        // .i_in_fifo_rear   ({res_fifo_dout[8],res_fifo_dout[7],res_fifo_dout[6],res_fifo_dout[5],res_fifo_dout[4],res_fifo_dout[3],res_fifo_dout[2],res_fifo_dout[1],res_fifo_dout[0]}),  // edit when changing N_DTPs
        .i_in_fifo_rear   (res_fifo_dout_all),  
        .o_in_fifo_is_full(res_fifo_is_full ),  
        .i_in_fifo_flush  (0                ),  
        .o_clf_accum_reg  (clf_accum_reg    ),  
        .o_rgs_accum_reg  (rgs_accum_reg    ),  
        .o_accum_reg_vld  (accum_reg_vld    ) // remember to remove comma here

        // Simulation
        // .clf_accum_out_sim(clf_accum_out_sim) // SIMULATION_ON
    );

//----------------------------------------------------------------------------------------
// VOTE BUFFER
//----------------------------------------------------------------------------------------

    vote_buffer #(
        .N_LABELS       (N_LABELS),  // maximum N_LABELS
        .N_LABELS_WIDTH (4), // maximum N_LABELS bit
        .RES_WIDTH      (RES_WIDTH),
        .BRAM_AWIDTH    (SAMPLE_FIFO_DEPTH_BIT),
        .BRAM_DWIDTH    (16)
    ) vote_buffer_inst(
        .clk              (clk),  
        .rst_n            (rst_n),  
        .i_vote_slot_rst  (rst_core),  
        .i_n_labels       (N_LABELS),  
        .i_is_clf         (is_clf),  
        .i_is_ps_read     (is_ps_read),  
        .i_clf_accum      (clf_accum_reg),  
        .i_rgs_accum      (rgs_accum_reg),  
        .i_accum_vld      (accum_reg_vld),  

        
        .bram_en_ps   (bram_en_vote  ),
        .bram_dout_ps (bram_dout_vote),
        .bram_din_ps  (bram_din_vote ),
        .bram_we_ps   (bram_we_vote  ),
        .bram_addr_ps (bram_addr_vote),
        .bram_clk_ps  (bram_clk_vote ),
        .bram_rst_ps  (bram_rst_vote )

        // .bram_en_ps   (bram_en_vote_sim  ), // SIMULATION_ON
        // .bram_dout_ps (bram_dout_vote_sim),
        // .bram_din_ps  (bram_din_vote_sim ),
        // .bram_we_ps   (bram_we_vote_sim  ),
        // .bram_addr_ps (bram_addr_vote_sim),
        // .bram_clk_ps  (clk ),
        // .bram_rst_ps  (bram_rst_vote_sim ),

        // // simulation
        // // .vld_sim             (),   
        // // .reg_idx_sim         (),   
        // // .clf_res_sim         (),   
        // // .clf_addr_sim        (),   
        // .accum_res_sim       (accum_res_sim),   
        // // .read_addr_sim       (),   
        // // .read_addr_vld_sim   (),       
        // .accum_res_pipe_sim  (accum_res_pipe_sim),       
        // .write_bram_din_sim  (write_bram_din_sim ),   
        // .write_bram_addr_sim (write_bram_addr_sim),     
        // .write_bram_we_sim   (write_bram_we_sim  )   
        // // .read_bram_addr_sim  ()
        // // .write_res_sim       ()
    );
//----------------------------------------------------------------------------------------
// SYSTEM DONE SIGNAL
//----------------------------------------------------------------------------------------

    reg [N_DTPS-1:0] is_dtp_fin_lv;
    wire is_dtp_fin_pulse, is_system_done_clf, is_system_done_rgs;
   
    always @(posedge clk) begin
        if(!rst_n) begin
            is_dtp_fin_lv <= 0;
        end
        else begin: FIN_PULSE2LEVEL
            integer d_idx;
            for(d_idx=0; d_idx<N_DTPS; d_idx=d_idx+1) begin
                if(dtp_is_fin[d_idx])
                    is_dtp_fin_lv[d_idx] <= 1;
                else if(rst_core)
                    is_dtp_fin_lv[d_idx] <= 0;
                else
                    is_dtp_fin_lv[d_idx] <= is_dtp_fin_lv[d_idx];
            end
        end
    end 

    edge_detector #(.IS_POS(1)
    ) edge_detector_fin_inst (
    .clk  (clk),  
    .rst_n(rst_n),  
    .din  (&is_dtp_fin_lv),  
    .eout (is_dtp_fin_pulse)
    );


// These latencies is not precisely calculated but they will have some residual cycles:

// Accumulater latency:
// + classification: 3{reading data} + 1{register} + N_DTPS{count1bit} + 2{accumulator} + 1{register}
//                  = N_DTPS + 7
// + regression: 3{reading data} + 2{accumulator} + (N_DTPS-1)*2{sequence of adders} + 1{register}
//               = 2*N_DTPS + 4

// Vote buffer latency:
// + classification: 1{reading data} + N_LABELS{read all labels} + 3{multiplier+adder} + 3{read bram+adder} + 1{write bram}
//                  = N_LABELS + 8
// + regression: 1{reading data} + 3{read bram+adder} + 1{write bram}
//               = 5


    pipeline #(.STAGES(N_DTPS + 7 + N_LABELS + 8), .DWIDTH(1), .RST_VAL(1'd0)
    ) system_done_clf_pipe_inst (
        .clk(clk), .rst_n(rst_n), 
        .in_data(is_dtp_fin_pulse), 
        .out_data(),
        .out_data_lst(is_system_done_clf)
        );

    pipeline #(.STAGES(2*N_DTPS + 4 + 5), .DWIDTH(1), .RST_VAL(1'd0)
    ) system_done_rgs_pipe_inst (
        .clk(clk), .rst_n(rst_n), 
        .in_data(is_dtp_fin_pulse), 
        .out_data(),
        .out_data_lst(is_system_done_rgs)
    );

    assign is_system_fin = (is_clf)? is_system_done_clf : is_system_done_rgs;

    always @(posedge clk) begin
        if(!rst_n) begin
            is_system_fin_reg <= 0;
        end
        else begin
            if(rst_core)
                is_system_fin_reg <= 0;
            else if(is_system_fin)
                is_system_fin_reg <= 1;
            else
                is_system_fin_reg <= is_system_fin_reg;
        end
    end



endmodule