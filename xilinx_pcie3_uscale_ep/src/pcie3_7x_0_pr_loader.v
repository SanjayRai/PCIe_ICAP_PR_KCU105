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
// File       : pcie3_7x_0_pr_loader.v
// Version    : 4.2
//-----------------------------------------------------------------------------
//
// Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
// File       : pcie3_7x_0_pr_loader.v
// Version    : 1.4
//
//---------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 1ns / 1ps
//---------------------------------------------------------------------------------------------------------------------------------------------//
module  pcie3_7x_0_pr_loader #(
  parameter TCQ                                   = 1,
  parameter C_DATA_WIDTH                          = 64,            // RX/TX interface data width
  // Do not override parameters below this line
  parameter KEEP_WIDTH                            = C_DATA_WIDTH / 32,
  parameter [1:0]  AXISTEN_IF_WIDTH               = (C_DATA_WIDTH == 256) ? 2'b10 : (C_DATA_WIDTH == 128) ? 2'b01 : 2'b00,
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG   = 0,
  parameter        AXISTEN_IF_RQ_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_CC_PARITY_CHECK     = 0,
  parameter        AXISTEN_IF_MC_RX_STRADDLE      = 0,
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC = 0,
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF
)(
  //----------------------------------------------------------------------------------------------------------------//
  input                                      sys_clk,
  input                                      sys_rst_n,
  input                                      user_lnk_up,
  input                                      conf_clk,
  //----------------------------------------------------------------------------------------------------------------//
  //  AXI Interface                                                                                                 //
  //----------------------------------------------------------------------------------------------------------------//
  output                                     s_axis_rq_tlast,
  output              [C_DATA_WIDTH-1:0]     s_axis_rq_tdata,
  output                          [59:0]     s_axis_rq_tuser,
  output                [KEEP_WIDTH-1:0]     s_axis_rq_tkeep,
  input                            [3:0]     s_axis_rq_tready,
  output                                     s_axis_rq_tvalid,

  input               [C_DATA_WIDTH-1:0]     m_axis_rc_tdata,
  input                           [74:0]     m_axis_rc_tuser,
  input                                      m_axis_rc_tlast,
  input                 [KEEP_WIDTH-1:0]     m_axis_rc_tkeep,
  input                                      m_axis_rc_tvalid,
  output                                     m_axis_rc_tready,

  input               [C_DATA_WIDTH-1:0]     m_axis_cq_tdata,
  input                           [84:0]     m_axis_cq_tuser,
  input                                      m_axis_cq_tlast,
  input                 [KEEP_WIDTH-1:0]     m_axis_cq_tkeep,
  input                                      m_axis_cq_tvalid,
  output                                     m_axis_cq_tready,
  input                            [5:0]     pcie_cq_np_req_count,
  output wire                                pcie_cq_np_req,

  output              [C_DATA_WIDTH-1:0]     s_axis_cc_tdata,
  output                          [32:0]     s_axis_cc_tuser,
  output                                     s_axis_cc_tlast,
  output                [KEEP_WIDTH-1:0]     s_axis_cc_tkeep,
  output                                     s_axis_cc_tvalid,
  input                            [3:0]     s_axis_cc_tready,
  //----------------------------------------------------------------------------------------------------------------//
  output                                     cfg_power_state_change_ack,
  input                                      cfg_power_state_change_interrupt,
  input                                      cfg_msg_received,
  input                            [7:0]     cfg_msg_received_data,
  input                            [4:0]     cfg_msg_received_type,
  output                                     cfg_msg_transmit,
  output                           [2:0]     cfg_msg_transmit_type,
  output                          [31:0]     cfg_msg_transmit_data,
  input                                      cfg_msg_transmit_done,
  input  wire                      [3:0]     cfg_flr_in_process,
  output wire                      [3:0]     cfg_flr_done,
  input  wire                      [7:0]     cfg_vf_flr_in_process,
  output wire                      [7:0]     cfg_vf_flr_done,
  // Interrupt Interface Signals
  output                           [3:0]     cfg_interrupt_int,
  output wire                      [3:0]     cfg_interrupt_pending,
  input                                      cfg_interrupt_sent,
  input                            [3:0]     cfg_interrupt_msi_enable,
  input                            [7:0]     cfg_interrupt_msi_vf_enable,
  input                            [11:0]    cfg_interrupt_msi_mmenable,
  input                                      cfg_interrupt_msi_mask_update,
  input                           [31:0]     cfg_interrupt_msi_data,
  output wire                      [3:0]     cfg_interrupt_msi_select,
  output                          [31:0]     cfg_interrupt_msi_int,
  output wire                     [31:0]     cfg_interrupt_msi_pending_status,
  input                                      cfg_interrupt_msi_sent,
  input                                      cfg_interrupt_msi_fail,
  output wire                      [2:0]     cfg_interrupt_msi_attr,
  output wire                                cfg_interrupt_msi_tph_present,
  output wire                      [1:0]     cfg_interrupt_msi_tph_type,
  output wire                      [8:0]     cfg_interrupt_msi_tph_st_tag,
  output wire                      [3:0]     cfg_interrupt_msi_function_number,
  
  //----------------------------------------------------------------------------------------------------------------//
  // Signals to ensure the swtich to stage2 does not happen during a PCIe transaction
  input  wire                                user_app_rdy_req,   // Request switch to stage2
  output wire                                user_app_rdy_gnt,   // Grant switch to stage2
  //----------------------------------------------------------------------------------------------------------------//
  output wire                                pr_done,
  output wire                                ICAP_ceb,
  output wire                                ICAP_wrb,
  output wire [31:0]                         ICAP_din_bs          // bitswapped version of ICAP_din
  //----------------------------------------------------------------------------------------------------------------//
);
  //----------------------------------------------------------------------------------------------------------------//
  wire     m_axis_rc_tready_bit;
  reg                       [3:0]     cfg_flr_done_reg0;
  reg                       [7:0]     cfg_vf_flr_done_reg0;
  reg                       [3:0]     cfg_flr_done_reg1;
  reg                       [7:0]     cfg_vf_flr_done_reg1;
  //----------------------------------------------------------------------------------------------------------------//

  // tie-off interfaces that are not implemented.
  assign cfg_msg_transmit = 1'b0;
  assign cfg_msg_transmit_type = 3'b0;
  assign cfg_msg_transmit_data = 32'b0;
  // Interrupt Interface Signals
  assign cfg_interrupt_int = 4'h0;
  assign cfg_interrupt_pending = 4'h0;
  assign cfg_interrupt_msi_select = 4'h0;
  assign cfg_interrupt_msi_int = 32'h00000000;
  assign cfg_interrupt_msi_pending_status = 32'h00000000;
  assign cfg_interrupt_msi_attr = 3'b000;
  assign cfg_interrupt_msi_tph_present = 1'b0;
  assign cfg_interrupt_msi_tph_type = 2'b00;
  assign cfg_interrupt_msi_tph_st_tag = 9'b000000000;
  assign cfg_interrupt_msi_function_number = 4'b000;

  assign m_axis_rc_tready                    = {22{m_axis_rc_tready_bit}};

  // FLR place-holder registers
  always @(posedge sys_clk) begin
      if (sys_rst_n) begin
        cfg_flr_done_reg0       <= 4'h0;
        cfg_vf_flr_done_reg0    <= 8'h00;
        cfg_flr_done_reg1       <= 4'h0;
        cfg_vf_flr_done_reg1    <= 8'h00;
      end else begin
        cfg_flr_done_reg0       <= cfg_flr_in_process;
        cfg_vf_flr_done_reg0    <= cfg_vf_flr_in_process;
        cfg_flr_done_reg1       <= cfg_flr_done_reg0;
        cfg_vf_flr_done_reg1    <= cfg_vf_flr_done_reg0;
      end
  end
  assign cfg_flr_done[0] = ~cfg_flr_done_reg1[0] && cfg_flr_done_reg0[0];
  assign cfg_flr_done[1] = ~cfg_flr_done_reg1[1] && cfg_flr_done_reg0[1];
  assign cfg_flr_done[3:2] = 2'b0;
  assign cfg_vf_flr_done[0] = ~cfg_vf_flr_done_reg1[0] && cfg_vf_flr_done_reg0[0];
  assign cfg_vf_flr_done[1] = ~cfg_vf_flr_done_reg1[1] && cfg_vf_flr_done_reg0[1];
  assign cfg_vf_flr_done[2] = ~cfg_vf_flr_done_reg1[2] && cfg_vf_flr_done_reg0[2];
  assign cfg_vf_flr_done[3] = ~cfg_vf_flr_done_reg1[3] && cfg_vf_flr_done_reg0[3];
  assign cfg_vf_flr_done[4] = ~cfg_vf_flr_done_reg1[4] && cfg_vf_flr_done_reg0[4];
  assign cfg_vf_flr_done[5] = ~cfg_vf_flr_done_reg1[5] && cfg_vf_flr_done_reg0[5];
  assign cfg_vf_flr_done[7:6] = 2'b0;

//---------------------------------------------------------------------------------------------------------------------------------------------//
//                                               Programmable I/O Module                                                                       //
//---------------------------------------------------------------------------------------------------------------------------------------------//
pcie3_7x_0_PIO_FPC #(
  .TCQ                                    ( TCQ                            ),
  .AXISTEN_IF_WIDTH                       ( AXISTEN_IF_WIDTH               ),
  .AXISTEN_IF_RQ_ALIGNMENT_MODE           ( AXISTEN_IF_RQ_ALIGNMENT_MODE   ),
  .AXISTEN_IF_CC_ALIGNMENT_MODE           ( AXISTEN_IF_CC_ALIGNMENT_MODE   ),
  .AXISTEN_IF_CQ_ALIGNMENT_MODE           ( AXISTEN_IF_CQ_ALIGNMENT_MODE   ),
  .AXISTEN_IF_RC_ALIGNMENT_MODE           ( AXISTEN_IF_RC_ALIGNMENT_MODE   ),
  .AXISTEN_IF_ENABLE_CLIENT_TAG           ( AXISTEN_IF_ENABLE_CLIENT_TAG   ),
  .AXISTEN_IF_RQ_PARITY_CHECK             ( AXISTEN_IF_RQ_PARITY_CHECK     ),
  .AXISTEN_IF_CC_PARITY_CHECK             ( AXISTEN_IF_CC_PARITY_CHECK     ),
  .AXISTEN_IF_MC_RX_STRADDLE              ( AXISTEN_IF_MC_RX_STRADDLE      ),
  .AXISTEN_IF_ENABLE_RX_MSG_INTFC         ( AXISTEN_IF_ENABLE_RX_MSG_INTFC ),
  .AXISTEN_IF_ENABLE_MSG_ROUTE            ( AXISTEN_IF_ENABLE_MSG_ROUTE    )

) PIO_FPC_i (
  .sys_clk                                        ( sys_clk ),
  .sys_rst_n                                      ( sys_rst_n ),
  .user_lnk_up                                    ( user_lnk_up ),

  .s_axis_cc_tdata                                ( s_axis_cc_tdata ),
  .s_axis_cc_tkeep                                ( s_axis_cc_tkeep ),
  .s_axis_cc_tlast                                ( s_axis_cc_tlast ),
  .s_axis_cc_tvalid                               ( s_axis_cc_tvalid ),
  .s_axis_cc_tuser                                ( s_axis_cc_tuser ),
  .s_axis_cc_tready                               ( s_axis_cc_tready[0] ),

  .s_axis_rq_tdata                                ( s_axis_rq_tdata ),
  .s_axis_rq_tkeep                                ( s_axis_rq_tkeep ),
  .s_axis_rq_tlast                                ( s_axis_rq_tlast ),
  .s_axis_rq_tvalid                               ( s_axis_rq_tvalid ),
  .s_axis_rq_tuser                                ( s_axis_rq_tuser ),
  .s_axis_rq_tready                               ( s_axis_rq_tready[0] ),

  .m_axis_cq_tdata                                ( m_axis_cq_tdata ),
  .m_axis_cq_tlast                                ( m_axis_cq_tlast ),
  .m_axis_cq_tvalid                               ( m_axis_cq_tvalid ),
  .m_axis_cq_tuser                                ( m_axis_cq_tuser ),
  .m_axis_cq_tkeep                                ( m_axis_cq_tkeep ),
  .m_axis_cq_tready                               ( m_axis_cq_tready ),
  .pcie_cq_np_req                                 ( pcie_cq_np_req ),
  .pcie_cq_np_req_count                           ( pcie_cq_np_req_count ),

  .m_axis_rc_tdata                                ( m_axis_rc_tdata ),
  .m_axis_rc_tlast                                ( m_axis_rc_tlast ),
  .m_axis_rc_tvalid                               ( m_axis_rc_tvalid ),
  .m_axis_rc_tuser                                ( m_axis_rc_tuser ),
  .m_axis_rc_tkeep                                ( m_axis_rc_tkeep ),
  .m_axis_rc_tready                               ( m_axis_rc_tready_bit ),

  .cfg_power_state_change_interrupt               ( cfg_power_state_change_interrupt ),
  .cfg_power_state_change_ack                     ( cfg_power_state_change_ack ),

  // Signals to ensure the swtich to stage2 does not happen during a PCIe transaction
  .user_app_rdy_req                               ( user_app_rdy_req ),        // Request switch to stage2
  .user_app_rdy_gnt                               ( user_app_rdy_gnt ),        // Grant switch to stage2

  .pr_done                                        ( pr_done     ),                // output
  .ICAP_ceb                                       ( ICAP_ceb    ),               // output
  .ICAP_wrb                                       ( ICAP_wrb    ),               // output
  .ICAP_din_bs                                    ( ICAP_din_bs ),            // output [31:0]
  .conf_clk                                       ( conf_clk    )
 );

//---------------------------------------------------------------------------------------------------------------------------------------------//
endmodule
