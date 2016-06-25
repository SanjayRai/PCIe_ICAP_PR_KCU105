//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
// File       : pcie3_7x_0_PIO_EP_FPC.v
// Version    : 4.2
//-----------------------------------------------------------------------------
//
// Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
// File       : pcie3_7x_0_PIO_EP_FPC.v
// Version    : 1.4
//

`timescale 1ps/1ps

module pcie3_7x_0_PIO_EP_FPC #(
  parameter        TCQ = 1,
  parameter [1:0]  AXISTEN_IF_WIDTH = 00,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE    = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE    = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE    = 0,
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE    = 0,
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG    = 0,
  parameter        AXISTEN_IF_RQ_PARITY_CHECK      = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK      = 0,
  parameter        AXISTEN_IF_RC_STRADDLE          = 0,
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC  = 0,
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE     = 18'h2FFFF,

  //Do not modify the parameters below this line
  parameter        C_DATA_WIDTH = (AXISTEN_IF_WIDTH[1]) ? 256 : (AXISTEN_IF_WIDTH[0]) ? 128 : 64,
  parameter        PARITY_WIDTH = C_DATA_WIDTH /8,
  parameter        KEEP_WIDTH   = C_DATA_WIDTH /32
) (
  input                            user_clk,
  input                            reset_n,

  // AXI-S Completer Competion Interface
  output wire [C_DATA_WIDTH-1:0]   s_axis_cc_tdata,
  output wire   [KEEP_WIDTH-1:0]   s_axis_cc_tkeep,
  output wire                      s_axis_cc_tlast,
  output wire                      s_axis_cc_tvalid,
  output wire             [32:0]   s_axis_cc_tuser,
  input                            s_axis_cc_tready,

  // AXI-S Requester Request Interface
  output wire [C_DATA_WIDTH-1:0]   s_axis_rq_tdata,
  output wire   [KEEP_WIDTH-1:0]   s_axis_rq_tkeep,
  output wire                      s_axis_rq_tlast,
  output wire                      s_axis_rq_tvalid,
  output wire             [59:0]   s_axis_rq_tuser,
  input                            s_axis_rq_tready,

  // AXI-S Completer Request Interface
  input       [C_DATA_WIDTH-1:0]   m_axis_cq_tdata,
  input                            m_axis_cq_tlast,
  input                            m_axis_cq_tvalid,
  input                   [84:0]   m_axis_cq_tuser,
  input         [KEEP_WIDTH-1:0]   m_axis_cq_tkeep,
  output wire                      m_axis_cq_tready,

  input                    [5:0]   pcie_cq_np_req_count,
  output wire                      pcie_cq_np_req,

  // AXI-S Requester Completion Interface
  input       [C_DATA_WIDTH-1:0]   m_axis_rc_tdata,
  input                            m_axis_rc_tlast,
  input                            m_axis_rc_tvalid,
  input         [KEEP_WIDTH-1:0]   m_axis_rc_tkeep,
  input                   [74:0]   m_axis_rc_tuser,
  output wire                      m_axis_rc_tready,

  output                           req_completion,
  output                           completion_done,

  // I/O for FPC
  output wire                      pr_done,
  output wire                      ICAP_ceb,
  output wire                      ICAP_wrb,
  output wire [31:0]               ICAP_din_bs,
  input wire                       conf_clk
);

  // Local wires
  wire  [10:0]      rd_addr;
  wire  [3:0]       rd_be;
  wire  [31:0]      rd_data;

  wire  [10:0]      wr_addr;
  wire  [7:0]       wr_be;
  wire              wr_busy;

  wire              req_compl;
  wire              req_compl_wd;
  wire              req_compl_ur;
  wire              compl_done;

  wire  [2:0]       req_tc;
  wire  [2:0]       req_attr;
  wire  [10:0]      req_len;
  wire  [15:0]      req_rid;
  wire  [7:0]       req_tag;
  wire  [7:0]       req_be;
  wire  [12:0]      req_addr;
  wire  [1:0]       req_at;
  wire              trn_sent;

  wire [63:0]       req_des_qword0;
  wire [63:0]       req_des_qword1;
  wire              req_des_tph_present;
  wire [1:0]        req_des_tph_type;
  wire [7:0]        req_des_tph_st_tag;

  wire              req_mem_lock;
  wire              req_mem;

  wire              payload_len;

  wire              gen_leg_intr;
  wire              gen_msi_intr;
  wire              gen_msix_intr;

  wire [31:0]       conf_data, wr_data_conf_dw1,wr_data_conf_dw2;
  wire              conf_enable, write_en;
  wire              conf_pause;
  wire [31:0]       wr_data_conf_byteswap;

  pcie3_7x_0_ICAP_access ICAP_ACC (
//  .PCIe_CLK                       ( user_clk ),
    .CONF_CLK                       ( conf_clk ),
    .reset_n                        ( 1'b1 ),
    .CONF_DATA                      ( conf_data ),
    .CONF_ENABLE                    ( conf_enable ),
    .ICAP_ceb                       ( ICAP_ceb ),
    .ICAP_wrb                       ( ICAP_wrb ),
    .ICAP_din_bs                    ( ICAP_din_bs )
  );

  pcie3_7x_0_data_transfer data_transfer_i (
    .trn_clk                        ( user_clk ),
    .conf_clk                       ( conf_clk ),
    .trn_reset_n                    ( reset_n ),
    .dis_data_trf_conf              ( 1'b0 ),
    .conf_FIFO_clr                  ( 1'b0 ),
    .wr_rqst                        ( write_en ),
    .wr_data                        ( wr_data_conf_byteswap ),
    .pause                          ( conf_pause ),
    .conf_data                      ( conf_data ),
    .conf_enable                    ( conf_enable ),
    .pr_done                        ( pr_done )
  );


  pcie3_7x_0_PIO_EP_MA_FPC EP_MEM_FPC_inst (
    .user_clk                       ( user_clk ),    
    .reset_n                        ( reset_n ),    

    // Read Port
    .rd_addr                        ( rd_addr ),     
    .rd_be                          ( rd_be ),         
    .rd_data                        ( rd_data ),     
    .trn_sent                       ( trn_sent ),

    // Write Port
    .wr_addr                        ( wr_addr ),     
    .wr_be                          ( wr_be ),         
    .wr_data                        ( {wr_data_conf_dw2,wr_data_conf_dw1} ),     
    .wr_en                          ( write_en ),         
    .wr_busy                        ( wr_busy ),     

    .payload_len                    ( payload_len )
  );

//
// Local-Link Receive Controller
//

  pcie3_7x_0_PIO_RX_ENG_FPC #(
    .TCQ(TCQ),
    .AXISTEN_IF_WIDTH               ( AXISTEN_IF_WIDTH ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE   ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE   ( AXISTEN_IF_RC_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_STRADDLE         ( AXISTEN_IF_RC_STRADDLE ),
    .AXISTEN_IF_ENABLE_RX_MSG_INTFC ( AXISTEN_IF_ENABLE_RX_MSG_INTFC ),
    .AXISTEN_IF_ENABLE_MSG_ROUTE    ( AXISTEN_IF_ENABLE_MSG_ROUTE )
  ) EP_RX_FPC_inst (
    .user_clk                       ( user_clk ),
    .reset_n                        ( reset_n ),

    // Target Request Interface
    .m_axis_cq_tdata                ( m_axis_cq_tdata ),
    .m_axis_cq_tlast                ( m_axis_cq_tlast ),
    .m_axis_cq_tvalid               ( m_axis_cq_tvalid ),
    .m_axis_cq_tuser                ( m_axis_cq_tuser ),
    .m_axis_cq_tkeep                ( m_axis_cq_tkeep ),
    .m_axis_cq_tready               ( m_axis_cq_tready ),
    .pcie_cq_np_req_count           ( pcie_cq_np_req_count ),
    .pcie_cq_np_req                 ( pcie_cq_np_req ),

    // Master Completion Interface
    .m_axis_rc_tdata                ( m_axis_rc_tdata ),
    .m_axis_rc_tkeep                ( m_axis_rc_tkeep ),
    .m_axis_rc_tlast                ( m_axis_rc_tlast ),
    .m_axis_rc_tvalid               ( m_axis_rc_tvalid ),
    .m_axis_rc_tuser                ( m_axis_rc_tuser ),
    .m_axis_rc_tready               ( m_axis_rc_tready ),

    //RX Message Interface
    .req_compl                      ( req_compl ),
    .req_compl_wd                   ( req_compl_wd ),
    .req_compl_ur                   ( req_compl_ur ),
    .compl_done                     ( compl_done ),

    .req_tc                         ( req_tc ),
    .req_attr                       ( req_attr ),
    .req_len                        ( req_len ),
    .req_rid                        ( req_rid ),
    .req_tag                        ( req_tag ),
    .req_be                         ( req_be ),
    .req_addr                       ( req_addr ),
    .req_at                         ( req_at ),

    .req_des_qword0                 ( req_des_qword0 ),
    .req_des_qword1                 ( req_des_qword1 ),
    .req_des_tph_present            ( req_des_tph_present ),
    .req_des_tph_type               ( req_des_tph_type ),
    .req_des_tph_st_tag             ( req_des_tph_st_tag ),
    .req_mem_lock                   ( req_mem_lock ),
    .req_mem                        ( req_mem ),

    .wr_addr                        ( wr_addr ),
    .wr_be                          ( wr_be ),
    .wr_data                        ( {wr_data_conf_dw2,wr_data_conf_dw1} ),
    .wr_en                          ( write_en ),
    .payload_len                    ( payload_len ),
    .wr_busy                        ( conf_pause)
  );

//
// Local-Link Transmit Controller
//

  pcie3_7x_0_PIO_TX_ENG_FPC #(
    .TCQ( TCQ ),
    .AXISTEN_IF_WIDTH               ( AXISTEN_IF_WIDTH ),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE   ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_CC_ALIGNMENT_MODE   ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXISTEN_IF_ENABLE_CLIENT_TAG   ( AXISTEN_IF_ENABLE_CLIENT_TAG ),
    .AXISTEN_IF_RQ_PARITY_CHECK     ( AXISTEN_IF_RQ_PARITY_CHECK ),
    .AXISTEN_IF_CC_PARITY_CHECK     ( AXISTEN_IF_CC_PARITY_CHECK )
  )EP_TX_FPC_inst(
    .user_clk                       ( user_clk ),
    .reset_n                        ( reset_n ),

    // AXI-S Target Competion Interface
    .s_axis_cc_tdata                ( s_axis_cc_tdata ),
    .s_axis_cc_tkeep                ( s_axis_cc_tkeep ),
    .s_axis_cc_tlast                ( s_axis_cc_tlast ),
    .s_axis_cc_tvalid               ( s_axis_cc_tvalid ),
    .s_axis_cc_tuser                ( s_axis_cc_tuser ),
    .s_axis_cc_tready               ( s_axis_cc_tready ),

    // AXI-S Master Request Interface
    .s_axis_rq_tdata                ( s_axis_rq_tdata ),
    .s_axis_rq_tkeep                ( s_axis_rq_tkeep ),
    .s_axis_rq_tlast                ( s_axis_rq_tlast ),
    .s_axis_rq_tvalid               ( s_axis_rq_tvalid ),
    .s_axis_rq_tuser                ( s_axis_rq_tuser ),
    .s_axis_rq_tready               ( s_axis_rq_tready ),

    // PIO RX Engine Interface
    .req_compl                      ( req_compl ),
    .req_compl_wd                   ( req_compl_wd ),
    .req_compl_ur                   ( req_compl_ur ),
    .payload_len                    ( payload_len ),
    .compl_done                     ( compl_done ),

    .req_tc                         ( req_tc ),
    .req_td                         ( ),
    .req_ep                         ( ),
    .req_attr                       ( req_attr[1:0] ),
    .req_len                        ( req_len ),
    .req_rid                        ( req_rid ),
    .req_tag                        ( req_tag ),
    .req_be                         ( req_be ),
    .req_addr                       ( req_addr ),
    .req_at                         ( req_at ),

    .req_des_qword0                 ( req_des_qword0 ),
    .req_des_qword1                 ( req_des_qword1 ),
    .req_des_tph_present            ( req_des_tph_present ),
    .req_des_tph_type               ( req_des_tph_type ),
    .req_des_tph_st_tag             ( req_des_tph_st_tag ),
    .req_mem_lock                   ( req_mem_lock ),
    .req_mem                        ( req_mem ),

    // PIO Memory Access Control Interface
    .rd_addr                        ( rd_addr ),
    .rd_be                          ( rd_be ),
    .rd_data                        ( rd_data ),
    .trn_sent                       ( trn_sent ),
    .gen_transaction                ( 1'b0 )
    );

  assign req_completion = req_compl ;
  assign completion_done = compl_done ;

  assign wr_data_conf_byteswap = {wr_data_conf_dw1[7:0], wr_data_conf_dw1[15:8],
                                  wr_data_conf_dw1[23:16], wr_data_conf_dw1[31:24]};

endmodule // PIO_EP_FPC



