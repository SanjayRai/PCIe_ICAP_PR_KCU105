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
// Project    : 
// File       : 
// Version    : 
//-----------------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module pcie_interface_multiplexer #(
  parameter C_DATA_WIDTH               = 256, // RX/TX interface data width
  parameter KEEP_WIDTH                 = C_DATA_WIDTH / 32
) (
  input wire         inft_sel,
  
  // PCIe Interface Signals
  // PCIe CQ signals
  input  wire [C_DATA_WIDTH-1:0] s_axis_pcie_cq_tdata,
  input  wire [KEEP_WIDTH-1:0]   s_axis_pcie_cq_tkeep,
  input  wire                    s_axis_pcie_cq_tlast,
  output wire                    s_axis_pcie_cq_tready,
  input  wire  [84:0]            s_axis_pcie_cq_tuser,
  input  wire                    s_axis_pcie_cq_tvalid,
  input  wire  [5:0]             s_axis_pcie_cq_np_req_count,
  output wire                    s_axis_pcie_cq_np_req,
  // PCIe CC signals
  output wire [C_DATA_WIDTH-1:0] m_axis_pcie_cc_tdata,
  output wire [KEEP_WIDTH-1:0]   m_axis_pcie_cc_tkeep,
  output wire                    m_axis_pcie_cc_tlast,
  input  wire   [3:0]            m_axis_pcie_cc_tready,
  output wire  [32:0]            m_axis_pcie_cc_tuser,
  output wire                    m_axis_pcie_cc_tvalid,
  // PCIe RQ signals
  output wire [C_DATA_WIDTH-1:0] m_axis_pcie_rq_tdata,
  output wire [KEEP_WIDTH-1:0]   m_axis_pcie_rq_tkeep,
  output wire                    m_axis_pcie_rq_tlast,
  input  wire   [3:0]            m_axis_pcie_rq_tready,
  output wire  [59:0]            m_axis_pcie_rq_tuser,
  output wire                    m_axis_pcie_rq_tvalid,
  // PCIe RC signals
  input  wire [C_DATA_WIDTH-1:0] s_axis_pcie_rc_tdata,
  input  wire [KEEP_WIDTH-1:0]   s_axis_pcie_rc_tkeep,
  input  wire                    s_axis_pcie_rc_tlast,
  output wire                    s_axis_pcie_rc_tready,
  input  wire  [74:0]            s_axis_pcie_rc_tuser,
  input  wire                    s_axis_pcie_rc_tvalid,
  // Other interface signals
  output wire                    pcie_power_state_change_ack,
  input  wire                    pcie_power_state_change_interrupt,
  input  wire                    pcie_msg_received,
  input  wire   [7:0]            pcie_msg_received_data,
  input  wire   [4:0]            pcie_msg_received_type,
  output wire                    pcie_msg_transmit,
  output wire   [2:0]            pcie_msg_transmit_type,
  output wire   [31:0]           pcie_msg_transmit_data,
  input  wire                    pcie_msg_transmit_done,
  input  wire [3:0]              pcie_flr_in_process,
  output wire [3:0]              pcie_flr_done,
  input  wire [7:0]              pcie_vf_flr_in_process,
  output wire [7:0]              pcie_vf_flr_done,
  // Interrupt Interface Signals
  output                           [3:0]     pcie_interrupt_int,
  output wire                      [3:0]     pcie_interrupt_pending,
  input                                      pcie_interrupt_sent,

  input                            [3:0]     pcie_interrupt_msi_enable,
  input                            [7:0]     pcie_interrupt_msi_vf_enable,
  input                            [11:0]    pcie_interrupt_msi_mmenable,
  input                                      pcie_interrupt_msi_mask_update,
  input                           [31:0]     pcie_interrupt_msi_data,
  output wire                      [3:0]     pcie_interrupt_msi_select,
  output                          [31:0]     pcie_interrupt_msi_int,
  output wire                     [31:0]     pcie_interrupt_msi_pending_status,
  input                                      pcie_interrupt_msi_sent,
  input                                      pcie_interrupt_msi_fail,
  output wire                      [2:0]     pcie_interrupt_msi_attr,
  output wire                                pcie_interrupt_msi_tph_present,
  output wire                      [1:0]     pcie_interrupt_msi_tph_type,
  output wire                      [8:0]     pcie_interrupt_msi_tph_st_tag,
  output wire                      [3:0]     pcie_interrupt_msi_function_number,
  
  // User 0 signals
  // User 0 CQ signals
  output wire [C_DATA_WIDTH-1:0] m_axis0_cq_tdata,
  output wire [KEEP_WIDTH-1:0]   m_axis0_cq_tkeep,
  output wire                    m_axis0_cq_tlast,
  input  wire                    m_axis0_cq_tready,
  output wire  [84:0]            m_axis0_cq_tuser,
  output wire                    m_axis0_cq_tvalid,
  output wire  [5:0]             m_axis0_cq_np_req_count,
  input  wire                    m_axis0_cq_np_req,
  // User 0 CC signals
  input  wire [C_DATA_WIDTH-1:0] s_axis0_cc_tdata,
  input  wire [KEEP_WIDTH-1:0]   s_axis0_cc_tkeep,
  input  wire                    s_axis0_cc_tlast,
  output wire   [3:0]            s_axis0_cc_tready,
  input  wire  [32:0]            s_axis0_cc_tuser,
  input  wire                    s_axis0_cc_tvalid,
  // User 0 RQ signals
  input  wire [C_DATA_WIDTH-1:0] s_axis0_rq_tdata,
  input  wire [KEEP_WIDTH-1:0]   s_axis0_rq_tkeep,
  input  wire                    s_axis0_rq_tlast,
  output wire   [3:0]            s_axis0_rq_tready,
  input  wire  [59:0]            s_axis0_rq_tuser,
  input  wire                    s_axis0_rq_tvalid,
  // User 0 RC signals
  output wire [C_DATA_WIDTH-1:0] m_axis0_rc_tdata,
  output wire [KEEP_WIDTH-1:0]   m_axis0_rc_tkeep,
  output wire                    m_axis0_rc_tlast,
  input  wire                    m_axis0_rc_tready,
  output wire  [74:0]            m_axis0_rc_tuser,
  output wire                    m_axis0_rc_tvalid,
  // Other interface signals
  input  wire                    intf0_power_state_change_ack,
  output wire                    intf0_power_state_change_interrupt,
  output wire                    intf0_msg_received,
  output wire   [7:0]            intf0_msg_received_data,
  output wire   [4:0]            intf0_msg_received_type,
  input  wire                    intf0_msg_transmit,
  input  wire   [2:0]            intf0_msg_transmit_type,
  input  wire   [31:0]           intf0_msg_transmit_data,
  output wire                    intf0_msg_transmit_done,
  output wire [3:0]              intf0_flr_in_process,
  input  wire [3:0]              intf0_flr_done,
  output wire [7:0]              intf0_vf_flr_in_process,
  input  wire [7:0]              intf0_vf_flr_done,
  // Interrupt Interface Signals
  input     [3:0]                                 intf0_interrupt_int,
  input     [3:0]                                 intf0_interrupt_pending,
  output                                          intf0_interrupt_sent,
  output    [3:0]                                 intf0_interrupt_msi_enable,
  output    [7:0]                                 intf0_interrupt_msi_vf_enable,
  output   [11:0]                                 intf0_interrupt_msi_mmenable,
  output                                          intf0_interrupt_msi_mask_update,
  output   [31:0]                                 intf0_interrupt_msi_data,
  input     [3:0]                                 intf0_interrupt_msi_select,
  input    [31:0]                                 intf0_interrupt_msi_int,
  input    [31:0]                                 intf0_interrupt_msi_pending_status,
  output                                          intf0_interrupt_msi_sent,
  output                                          intf0_interrupt_msi_fail,
  input     [2:0]                                 intf0_interrupt_msi_attr,
  input                                           intf0_interrupt_msi_tph_present,
  input     [1:0]                                 intf0_interrupt_msi_tph_type,
  input     [8:0]                                 intf0_interrupt_msi_tph_st_tag,
  input     [3:0]                                 intf0_interrupt_msi_function_number,
  
  // User 0 signals
  // User 1 CQ signals
  output wire [C_DATA_WIDTH-1:0] m_axis1_cq_tdata,
  output wire [KEEP_WIDTH-1:0]   m_axis1_cq_tkeep,
  output wire                    m_axis1_cq_tlast,
  input  wire                    m_axis1_cq_tready,
  output wire  [84:0]            m_axis1_cq_tuser,
  output wire                    m_axis1_cq_tvalid,
  output wire  [5:0]             m_axis1_cq_np_req_count,
  input  wire                    m_axis1_cq_np_req,
  // User 1 CC signals
  input  wire [C_DATA_WIDTH-1:0] s_axis1_cc_tdata,
  input  wire [KEEP_WIDTH-1:0]   s_axis1_cc_tkeep,
  input  wire                    s_axis1_cc_tlast,
  output wire   [3:0]            s_axis1_cc_tready,
  input  wire  [32:0]            s_axis1_cc_tuser,
  input  wire                    s_axis1_cc_tvalid,
  // User 1 RQ signals
  input  wire [C_DATA_WIDTH-1:0] s_axis1_rq_tdata,
  input  wire [KEEP_WIDTH-1:0]   s_axis1_rq_tkeep,
  input  wire                    s_axis1_rq_tlast,
  output wire   [3:0]            s_axis1_rq_tready,
  input  wire  [59:0]            s_axis1_rq_tuser,
  input  wire                    s_axis1_rq_tvalid,
  // User 1 RC signals
  output wire [C_DATA_WIDTH-1:0] m_axis1_rc_tdata,
  output wire [KEEP_WIDTH-1:0]   m_axis1_rc_tkeep,
  output wire                    m_axis1_rc_tlast,
  input  wire                    m_axis1_rc_tready,
  output wire  [74:0]            m_axis1_rc_tuser,
  output wire                    m_axis1_rc_tvalid,
  // Other interface signals
  input  wire                    intf1_power_state_change_ack,
  output wire                    intf1_power_state_change_interrupt,
  output wire                    intf1_msg_received,
  output wire   [7:0]            intf1_msg_received_data,
  output wire   [4:0]            intf1_msg_received_type,
  input  wire                    intf1_msg_transmit,
  input  wire   [2:0]            intf1_msg_transmit_type,
  input  wire   [31:0]           intf1_msg_transmit_data,
  output wire                    intf1_msg_transmit_done,
  output wire [3:0]              intf1_flr_in_process,
  input  wire [3:0]              intf1_flr_done,
  output wire [7:0]              intf1_vf_flr_in_process,
  input  wire [7:0]              intf1_vf_flr_done,
  // Interrupt Interface Signals
  input     [3:0]                                 intf1_interrupt_int,
  input     [3:0]                                 intf1_interrupt_pending,
  output                                          intf1_interrupt_sent,
  output    [3:0]                                 intf1_interrupt_msi_enable,
  output    [7:0]                                 intf1_interrupt_msi_vf_enable,
  output   [11:0]                                 intf1_interrupt_msi_mmenable,
  output                                          intf1_interrupt_msi_mask_update,
  output   [31:0]                                 intf1_interrupt_msi_data,
  input     [3:0]                                 intf1_interrupt_msi_select,
  input    [31:0]                                 intf1_interrupt_msi_int,
  input    [31:0]                                 intf1_interrupt_msi_pending_status,
  output                                          intf1_interrupt_msi_sent,
  output                                          intf1_interrupt_msi_fail,
  input     [2:0]                                 intf1_interrupt_msi_attr,
  input                                           intf1_interrupt_msi_tph_present,
  input     [1:0]                                 intf1_interrupt_msi_tph_type,
  input     [8:0]                                 intf1_interrupt_msi_tph_st_tag,
  input     [3:0]                                 intf1_interrupt_msi_function_number
);

  // Multiplex the signals. For short term use and testing this will
  // just be a switch input. We can update this with something a little
  // different later if needed.
  // Muxing for the CQ interface
  assign m_axis0_cq_tdata   = s_axis_pcie_cq_tdata; // no muxing required on output data lines
  assign m_axis1_cq_tdata   = s_axis_pcie_cq_tdata; // no muxing required on output data lines
  assign m_axis0_cq_tkeep   = (inft_sel) ? 'h0 : s_axis_pcie_cq_tkeep;
  assign m_axis1_cq_tkeep   = (inft_sel) ? s_axis_pcie_cq_tkeep : 'h0;
  assign m_axis0_cq_tlast   = (inft_sel) ? 'h0 : s_axis_pcie_cq_tlast;
  assign m_axis1_cq_tlast   = (inft_sel) ? s_axis_pcie_cq_tlast : 'h0;
  assign s_axis_pcie_cq_tready = (inft_sel) ? m_axis1_cq_tready : m_axis0_cq_tready;
  assign m_axis0_cq_tuser  = (inft_sel) ? 'h0 : s_axis_pcie_cq_tuser;
  assign m_axis1_cq_tuser  = (inft_sel) ? s_axis_pcie_cq_tuser : 'h0;
  assign m_axis0_cq_tvalid = (inft_sel) ? 'h0 : s_axis_pcie_cq_tvalid;
  assign m_axis1_cq_tvalid = (inft_sel) ? s_axis_pcie_cq_tvalid : 'h0;
  assign m_axis0_cq_np_req_count = (inft_sel) ? 'h0 : s_axis_pcie_cq_np_req_count;
  assign m_axis1_cq_np_req_count = (inft_sel) ? s_axis_pcie_cq_np_req_count : 'h0;
  assign s_axis_pcie_cq_np_req = (inft_sel) ? m_axis1_cq_np_req : m_axis0_cq_np_req;  
  // Muxing for the CC interface
  assign m_axis_pcie_cc_tdata  = (inft_sel) ? s_axis1_cc_tdata       : s_axis0_cc_tdata;
  assign m_axis_pcie_cc_tkeep  = (inft_sel) ? s_axis1_cc_tkeep       : s_axis0_cc_tkeep;
  assign m_axis_pcie_cc_tlast  = (inft_sel) ? s_axis1_cc_tlast       : s_axis0_cc_tlast;
  assign s_axis0_cc_tready     = (inft_sel) ? 'h0 : m_axis_pcie_cc_tready;
  assign s_axis1_cc_tready     = (inft_sel) ? m_axis_pcie_cc_tready  : 'h0; 
  assign m_axis_pcie_cc_tuser  = (inft_sel) ? s_axis1_cc_tuser       : s_axis0_cc_tuser;
  assign m_axis_pcie_cc_tvalid = (inft_sel) ? s_axis1_cc_tvalid      : s_axis0_cc_tvalid;
  // Muxing for the RQ interface
  assign m_axis_pcie_rq_tdata  = (inft_sel) ? s_axis1_rq_tdata       : s_axis0_rq_tdata;
  assign m_axis_pcie_rq_tkeep  = (inft_sel) ? s_axis1_rq_tkeep       : s_axis0_rq_tkeep;
  assign m_axis_pcie_rq_tlast  = (inft_sel) ? s_axis1_rq_tlast       : s_axis0_rq_tlast;
  assign s_axis0_rq_tready     = (inft_sel) ? 0 : m_axis_pcie_rq_tready;
  assign s_axis1_rq_tready     = (inft_sel) ? m_axis_pcie_rq_tready  : 0; 
  assign m_axis_pcie_rq_tuser  = (inft_sel) ? s_axis1_rq_tuser       : s_axis0_rq_tuser;
  assign m_axis_pcie_rq_tvalid = (inft_sel) ? s_axis1_rq_tvalid      : s_axis1_rq_tvalid;  
  // Muxing for the RC interface
  assign m_axis0_rc_tdata   = s_axis_pcie_rc_tdata; // no muxing required on output data lines
  assign m_axis1_rc_tdata   = s_axis_pcie_rc_tdata; // no muxing required on output data lines.
  assign m_axis0_rc_tkeep   = (inft_sel) ? 'h0 : s_axis_pcie_rc_tkeep;
  assign m_axis1_rc_tkeep   = (inft_sel) ? s_axis_pcie_rc_tkeep : 'h0;
  assign m_axis0_rc_tlast   = (inft_sel) ? 'h0 : s_axis_pcie_rc_tlast;
  assign m_axis1_rc_tlast   = (inft_sel) ? s_axis_pcie_rc_tlast : 'h0;
  assign s_axis_pcie_rc_tready = (inft_sel) ? m_axis1_rc_tready : m_axis0_rc_tready;
  assign m_axis0_rc_tuser  = (inft_sel) ? 'h0 : s_axis_pcie_rc_tuser;
  assign m_axis1_rc_tuser  = (inft_sel) ? s_axis_pcie_rc_tuser : 'h0;
  assign m_axis0_rc_tvalid = (inft_sel) ? 'h0 : s_axis_pcie_rc_tvalid;
  assign m_axis1_rc_tvalid = (inft_sel) ? s_axis_pcie_rc_tvalid : 'h0;

  // Muxing of other interface signals
  assign pcie_power_state_change_ack = (inft_sel) ? intf1_power_state_change_ack : intf0_power_state_change_ack;
  assign intf0_power_state_change_interrupt  = (inft_sel) ? 'h0 : pcie_power_state_change_interrupt;
  assign intf1_power_state_change_interrupt  = (inft_sel) ? pcie_power_state_change_interrupt : 'h0;  
  assign intf0_msg_received  = (inft_sel) ? 'h0 : pcie_msg_received;
  assign intf1_msg_received  = (inft_sel) ? pcie_msg_received : 'h0;  
  assign intf0_msg_received_data  = pcie_msg_received_data; // no muxing required on output data lines.
  assign intf1_msg_received_data  = pcie_msg_received_data; // no muxing required on output data lines.  
  assign intf0_msg_received_type  = pcie_msg_received_type; // no muxing required on output data lines.
  assign intf1_msg_received_type  = pcie_msg_received_type; // no muxing required on output data lines.
  assign pcie_msg_transmit = (inft_sel) ? intf1_msg_transmit : intf0_msg_transmit;
  assign pcie_msg_transmit_type = (inft_sel) ? intf1_msg_transmit_data : intf0_msg_transmit_data;
  assign pcie_msg_transmit_data = (inft_sel) ? intf1_msg_transmit_data : intf0_power_state_change_ack;
  assign intf0_msg_transmit_done  = (inft_sel) ? 'h0 : pcie_msg_transmit_done;
  assign intf1_msg_transmit_done  = (inft_sel) ? pcie_msg_transmit_done : 'h0;

  assign intf0_flr_in_process  = (inft_sel) ? 'h0 : pcie_flr_in_process;
  assign intf1_flr_in_process  = (inft_sel) ? pcie_flr_in_process : 'h0;
  assign pcie_flr_done = (inft_sel) ? intf1_flr_done : intf0_flr_done;
  assign intf0_vf_flr_in_process  = (inft_sel) ? 'h0 : pcie_vf_flr_in_process;
  assign intf1_vf_flr_in_process  = (inft_sel) ? pcie_vf_flr_in_process : 'h0;
  assign pcie_vf_flr_done = (inft_sel) ? intf1_vf_flr_done : intf0_vf_flr_done;
  
    // Interrupt Interface Signals
  assign pcie_interrupt_int = (inft_sel) ? intf1_interrupt_int : intf0_interrupt_int;  
  assign pcie_interrupt_pending = (inft_sel) ? intf1_interrupt_pending: intf0_interrupt_pending;
  assign intf0_interrupt_sent  = (inft_sel) ? 'h0 : pcie_interrupt_sent;
  assign intf1_interrupt_sent  = (inft_sel) ? pcie_interrupt_sent : 'h0;
  assign intf0_interrupt_msi_enable  = (inft_sel) ? 'h0 : pcie_interrupt_msi_enable;
  assign intf1_interrupt_msi_enable  = (inft_sel) ? pcie_interrupt_msi_enable : 'h0;
  assign intf0_interrupt_msi_vf_enable  = (inft_sel) ? 'h0 : pcie_interrupt_msi_vf_enable;
  assign intf1_interrupt_msi_vf_enable  = (inft_sel) ? pcie_interrupt_msi_vf_enable : 'h0;
  assign intf0_interrupt_msi_mmenable  = (inft_sel) ? 'h0 : pcie_interrupt_msi_mmenable;
  assign intf1_interrupt_msi_mmenable  = (inft_sel) ? pcie_interrupt_msi_mmenable : 'h0;
  assign intf0_interrupt_msi_mask_update  = (inft_sel) ? 'h0 : pcie_interrupt_msi_mask_update;
  assign intf1_interrupt_msi_mask_update  = (inft_sel) ? pcie_interrupt_msi_mask_update : 'h0;
  assign intf0_interrupt_msi_data  = pcie_interrupt_msi_data; // no muxing required on output data lines
  assign intf1_interrupt_msi_data  = pcie_interrupt_msi_data; // no muxing required on output data lines.
  assign pcie_interrupt_msi_select = (inft_sel) ? intf1_interrupt_msi_select : intf0_interrupt_msi_select;
  assign pcie_interrupt_msi_int = (inft_sel) ? intf1_interrupt_msi_int : intf0_interrupt_msi_int;
  assign pcie_interrupt_msi_pending_status = (inft_sel) ? intf1_interrupt_msi_pending_status : intf0_interrupt_msi_pending_status;
  assign intf0_interrupt_msi_sent  = (inft_sel) ? 'h0 : pcie_interrupt_msi_sent;
  assign intf1_interrupt_msi_sent  = (inft_sel) ? pcie_interrupt_msi_sent : 'h0;
  assign intf0_interrupt_msi_fail  = (inft_sel) ? 'h0 : pcie_interrupt_msi_fail;
  assign intf1_interrupt_msi_fail  = (inft_sel) ? pcie_interrupt_msi_fail : 'h0;
  assign pcie_interrupt_msi_attr = (inft_sel) ? intf1_interrupt_msi_attr : intf0_interrupt_msi_attr;
  assign pcie_interrupt_msi_tph_present = (inft_sel) ? intf1_interrupt_msi_tph_present : intf0_interrupt_msi_tph_present;
  assign pcie_interrupt_msi_tph_type = (inft_sel) ? intf1_interrupt_msi_tph_type : intf0_interrupt_msi_tph_type;
  assign pcie_interrupt_msi_tph_st_tag = (inft_sel) ? intf1_interrupt_msi_tph_st_tag : intf0_interrupt_msi_tph_st_tag;
  assign pcie_interrupt_msi_function_number = (inft_sel) ? intf1_interrupt_msi_function_number : intf0_interrupt_msi_function_number;

endmodule
