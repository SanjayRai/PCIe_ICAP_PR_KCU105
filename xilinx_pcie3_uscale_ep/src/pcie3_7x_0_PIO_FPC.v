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
// File       : pcie3_7x_0_PIO_FPC.v
// Version    : 4.2
//-----------------------------------------------------------------------------
//
// Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
// File       : pcie3_7x_0_PIO_FPC.v
// Version    : 1.4
//

`timescale 1ps/1ps

module pcie3_7x_0_PIO_FPC #(
  parameter        TCQ = 1,
  parameter [1:0]  AXISTEN_IF_WIDTH               = 00,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG   = 0,
  parameter        AXISTEN_IF_RQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_MC_RX_STRADDLE      = 0,
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC = 0,
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF,

  //Do not modify the parameters below this line
  parameter        C_DATA_WIDTH = (AXISTEN_IF_WIDTH[1]) ? 256 : (AXISTEN_IF_WIDTH[0]) ? 128 : 64,
  parameter        PARITY_WIDTH = C_DATA_WIDTH /8,
  parameter        KEEP_WIDTH   = C_DATA_WIDTH /32
)(
  input                            sys_clk,
  input                            sys_rst_n,
  input                            user_lnk_up,

  // AXI-S Completer Competion Interface from  PIO TX Engine
  output wire [C_DATA_WIDTH-1:0]   s_axis_cc_tdata,
  output wire   [KEEP_WIDTH-1:0]   s_axis_cc_tkeep,
  output wire                      s_axis_cc_tlast,
  output wire                      s_axis_cc_tvalid,
  output wire             [32:0]   s_axis_cc_tuser,
  input                            s_axis_cc_tready,

  // AXI-S Requester Request Interface ( Left OPEN )
  output wire [C_DATA_WIDTH-1:0]   s_axis_rq_tdata,
  output wire   [KEEP_WIDTH-1:0]   s_axis_rq_tkeep,
  output wire                      s_axis_rq_tlast,
  output wire                      s_axis_rq_tvalid,
  output wire             [59:0]   s_axis_rq_tuser,
  input                            s_axis_rq_tready,

  // AXI-S Completer Request Interface to PIO RX Engine
  input       [C_DATA_WIDTH-1:0]   m_axis_cq_tdata,
  input                            m_axis_cq_tlast,
  input                            m_axis_cq_tvalid,
  input                   [84:0]   m_axis_cq_tuser,
  input         [KEEP_WIDTH-1:0]   m_axis_cq_tkeep,
  output wire                      m_axis_cq_tready,
  input                    [5:0]   pcie_cq_np_req_count,
  output wire                      pcie_cq_np_req,

  // AXI-S Requester Completion Interface ( Left OPEN )
  input       [C_DATA_WIDTH-1:0]   m_axis_rc_tdata,
  input                            m_axis_rc_tlast,
  input                            m_axis_rc_tvalid,
  input                   [74:0]   m_axis_rc_tuser,
  input         [KEEP_WIDTH-1:0]   m_axis_rc_tkeep,
  output wire                      m_axis_rc_tready,

  input                            cfg_power_state_change_interrupt,
  output                           cfg_power_state_change_ack,

  // Signals to ensure the swtich to stage2 does not happen during a PCIe transaction
  input  wire                   user_app_rdy_req,   // Request switch to stage2
  output wire                   user_app_rdy_gnt,   // Grant switch to stage2

  // I/O for FPC
  output wire                      pr_done,
  output wire                      ICAP_ceb,
  output wire                      ICAP_wrb,
  output wire [31:0]               ICAP_din_bs,
  input wire                       conf_clk

); // synthesis syn_hier = "hard"

  wire          req_completion;
  wire          completion_done;
  wire          pio_reset_n = sys_rst_n;

  // PIO instance
  pcie3_7x_0_PIO_EP_FPC  #(
    .TCQ                                     ( TCQ ),
    .AXISTEN_IF_WIDTH                        ( AXISTEN_IF_WIDTH ),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE            ( AXISTEN_IF_RQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_CC_ALIGNMENT_MODE            ( AXISTEN_IF_CC_ALIGNMENT_MODE ),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE            ( AXISTEN_IF_CQ_ALIGNMENT_MODE ),
    .AXISTEN_IF_RC_ALIGNMENT_MODE            ( AXISTEN_IF_RC_ALIGNMENT_MODE ),
    .AXISTEN_IF_ENABLE_CLIENT_TAG            ( AXISTEN_IF_ENABLE_CLIENT_TAG ),
    .AXISTEN_IF_RQ_PARITY_CHECK              ( AXISTEN_IF_RQ_PARITY_CHECK ),
    .AXISTEN_IF_CC_PARITY_CHECK              ( AXISTEN_IF_CC_PARITY_CHECK ),
    .AXISTEN_IF_ENABLE_RX_MSG_INTFC          ( AXISTEN_IF_ENABLE_RX_MSG_INTFC ),
    .AXISTEN_IF_ENABLE_MSG_ROUTE             ( AXISTEN_IF_ENABLE_MSG_ROUTE )
  ) PIO_EP_FPC_inst (

    .user_clk                                ( sys_clk ),
    .reset_n                                 ( pio_reset_n ),

    .s_axis_cc_tdata                         ( s_axis_cc_tdata ),
    .s_axis_cc_tkeep                         ( s_axis_cc_tkeep ),
    .s_axis_cc_tlast                         ( s_axis_cc_tlast ),
    .s_axis_cc_tvalid                        ( s_axis_cc_tvalid ),
    .s_axis_cc_tuser                         ( s_axis_cc_tuser ),
    .s_axis_cc_tready                        ( s_axis_cc_tready ),

    .s_axis_rq_tdata                         ( s_axis_rq_tdata ),
    .s_axis_rq_tkeep                         ( s_axis_rq_tkeep ),
    .s_axis_rq_tlast                         ( s_axis_rq_tlast ),
    .s_axis_rq_tvalid                        ( s_axis_rq_tvalid ),
    .s_axis_rq_tuser                         ( s_axis_rq_tuser ),
    .s_axis_rq_tready                        ( s_axis_rq_tready ),

    .m_axis_cq_tdata                         ( m_axis_cq_tdata ),
    .m_axis_cq_tlast                         ( m_axis_cq_tlast ),
    .m_axis_cq_tvalid                        ( m_axis_cq_tvalid ),
    .m_axis_cq_tuser                         ( m_axis_cq_tuser ),
    .m_axis_cq_tkeep                         ( m_axis_cq_tkeep ),
    .m_axis_cq_tready                        ( m_axis_cq_tready ),
    .pcie_cq_np_req                          ( pcie_cq_np_req ),
    .pcie_cq_np_req_count                    ( pcie_cq_np_req_count ),

    .m_axis_rc_tdata                         ( m_axis_rc_tdata ),
    .m_axis_rc_tlast                         ( m_axis_rc_tlast ),
    .m_axis_rc_tvalid                        ( m_axis_rc_tvalid ),
    .m_axis_rc_tuser                         ( m_axis_rc_tuser ),
    .m_axis_rc_tkeep                         ( m_axis_rc_tkeep ),
    .m_axis_rc_tready                        ( m_axis_rc_tready ),

    .req_completion                          ( req_completion ),
    .completion_done                         ( completion_done ),

    // New I/O for FPC
    .pr_done                                 ( pr_done ),
    .ICAP_ceb                                ( ICAP_ceb ),
    .ICAP_wrb                                ( ICAP_wrb ),
    .ICAP_din_bs                             ( ICAP_din_bs ),
    .conf_clk                                ( conf_clk )
  );

  // Turn-Off controller
  pcie3_7x_0_PIO_TO_CTRL_FPC PIO_TO_FPC_inst  (
    .clk                                     ( sys_clk ),
    .rst_n                                   ( pio_reset_n ),

    .req_compl                               ( req_completion ),
    .compl_done                              ( completion_done ),

    .cfg_power_state_change_interrupt        ( cfg_power_state_change_interrupt ),
    .cfg_power_state_change_ack              ( cfg_power_state_change_ack )
  );

  // Grants User App control when no transactions are in progress
  pcie3_7x_0_tandem_cpler_ctl_arb #(
    .TCQ( TCQ ),
    .C_DATA_WIDTH                            ( C_DATA_WIDTH )
  ) tandem_ctl_arb_i (
    .user_clk                                ( sys_clk ),                    // Clock Input
    .reset_n                                 ( sys_rst_n ),                  // Reset input (asserted-high) - link-up is not required for switch to stage2

    // Target Request Interface
    .m_axis_cq_tvalid                        ( m_axis_cq_tvalid ),           // I AXI Master interface monitoring
    .m_axis_cq_tready                        ( m_axis_cq_tready ),           // I AXI Master interface monitoring

    // Completion Interface
    .req_completion                          ( req_completion ),             // I AXI Master interface monitoring
    .completion_done                         ( completion_done ),            // I AXI Master interface monitoring

    // user app signals
    .user_app_rdy_req                        ( user_app_rdy_req ),           // Request user_app_rdy input
    .user_app_rdy_gnt                        ( user_app_rdy_gnt )            // Grant user_app_rdy output
  );

endmodule // PIO

