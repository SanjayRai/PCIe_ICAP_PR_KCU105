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
// Project    : Ultrascale FPGA Gen3 Integrated Block for PCI Express
// File       : pcie3_ultrascale_0_support.v
// Version    : 4.2 
//-----------------------------------------------------------------------------
//--
//-- Description:  PCI Express Endpoint Shared Logic Wrapper
//--
//------------------------------------------------------------------------------

`timescale 1ps / 1ps

`define PCI_EXP_EP_OUI                           24'h000A35
`define PCI_EXP_EP_DSN_1                         {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2                         32'h00000001

(* DowngradeIPIdentifiedWarnings = "yes" *)
module pcie3_ultrascale_0_support # (
  parameter PL_LINK_CAP_MAX_LINK_WIDTH = 8,  // 1- X1, 2 - X2, 4 - X4, 8 - X8
  parameter PCIE_REFCLK_FREQ           = 0,   // PCIe Reference Clock Frequency
  parameter C_DATA_WIDTH               = 256, // RX/TX interface data width
  parameter PL_UPSTREAM_FACING         = "TRUE",
  parameter DIS_GT_WIZARD              = "TRUE",
  parameter integer SHARED_LOGIC       = 0,
  parameter KEEP_WIDTH                 = C_DATA_WIDTH / 32
) (
  // Tx
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
  output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,

  // Rx
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
  input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,

  output  [((PL_LINK_CAP_MAX_LINK_WIDTH-1)>>2):0] int_qpll1lock_out,
  output  [((PL_LINK_CAP_MAX_LINK_WIDTH-1)>>2):0] int_qpll1outclk_out,
  output  [((PL_LINK_CAP_MAX_LINK_WIDTH-1)>>2):0] int_qpll1outrefclk_out,

  output                                          user_clk,
  output                                          user_reset,
  output                                          user_lnk_up,

  input   [C_DATA_WIDTH-1:0]                      s_axis_rq_tdata,
  input   [KEEP_WIDTH-1:0]                        s_axis_rq_tkeep,
  input                                           s_axis_rq_tlast,
  output    [3:0]                                 s_axis_rq_tready,
  input    [59:0]                                 s_axis_rq_tuser,
  input                                           s_axis_rq_tvalid,

  output  [C_DATA_WIDTH-1:0]                      m_axis_rc_tdata,
  output  [KEEP_WIDTH-1:0]                        m_axis_rc_tkeep,
  output                                          m_axis_rc_tlast,
  input                                           m_axis_rc_tready,
  output   [74:0]                                 m_axis_rc_tuser,
  output                                          m_axis_rc_tvalid,

  output  [C_DATA_WIDTH-1:0]                      m_axis_cq_tdata,
  output  [KEEP_WIDTH-1:0]                        m_axis_cq_tkeep,
  output                                          m_axis_cq_tlast,
  input                                           m_axis_cq_tready,
  output   [84:0]                                 m_axis_cq_tuser,
  output                                          m_axis_cq_tvalid,

  input   [C_DATA_WIDTH-1:0]                      s_axis_cc_tdata,
  input   [KEEP_WIDTH-1:0]                        s_axis_cc_tkeep,
  input                                           s_axis_cc_tlast,
  output    [3:0]                                 s_axis_cc_tready,
  input    [32:0]                                 s_axis_cc_tuser,
  input                                           s_axis_cc_tvalid,


  output    [1:0]                                 pcie_tfc_nph_av,
  output    [1:0]                                 pcie_tfc_npd_av,

  output    [3:0]                                 pcie_rq_seq_num,
  output                                          pcie_rq_seq_num_vld,
  output    [5:0]                                 pcie_rq_tag,
  output    [1:0]                                 pcie_rq_tag_av,
  output                                          pcie_rq_tag_vld,

  input                                           pcie_cq_np_req,
  output    [5:0]                                 pcie_cq_np_req_count,

  output                                          cfg_phy_link_down,
  output    [1:0]                                 cfg_phy_link_status,
  output    [3:0]                                 cfg_negotiated_width,
  output    [2:0]                                 cfg_current_speed,
  output    [2:0]                                 cfg_max_payload,
  output    [2:0]                                 cfg_max_read_req,
  output   [15:0]                                 cfg_function_status,
  output   [11:0]                                 cfg_function_power_state,
  output   [15:0]                                 cfg_vf_status,
  output   [23:0]                                 cfg_vf_power_state,
  output    [1:0]                                 cfg_link_power_state,

  // Error Reporting Interface
  output                                          cfg_err_cor_out,
  output                                          cfg_err_nonfatal_out,
  output                                          cfg_err_fatal_out,
  output                                          cfg_local_error,

  output                                          cfg_ltr_enable,
  output    [5:0]                                 cfg_ltssm_state,
  output    [3:0]                                 cfg_rcb_status,
  output    [3:0]                                 cfg_dpa_substate_change,
  output    [1:0]                                 cfg_obff_enable,
  output                                          cfg_pl_status_change,

  output    [3:0]                                 cfg_tph_requester_enable,
  output   [11:0]                                 cfg_tph_st_mode,
  output    [7:0]                                 cfg_vf_tph_requester_enable,
  output   [23:0]                                 cfg_vf_tph_st_mode,

  output                                          cfg_msg_received,
  output    [7:0]                                 cfg_msg_received_data,
  output    [4:0]                                 cfg_msg_received_type,
  input                                           cfg_msg_transmit,
  input     [2:0]                                 cfg_msg_transmit_type,
  input    [31:0]                                 cfg_msg_transmit_data,
  output                                          cfg_msg_transmit_done,

  output    [7:0]                                 cfg_fc_ph,
  output   [11:0]                                 cfg_fc_pd,
  output    [7:0]                                 cfg_fc_nph,
  output   [11:0]                                 cfg_fc_npd,
  output    [7:0]                                 cfg_fc_cplh,
  output   [11:0]                                 cfg_fc_cpld,
  input     [2:0]                                 cfg_fc_sel,

  output                                          cfg_power_state_change_interrupt,
  input                                           cfg_power_state_change_ack,

  output    [3:0]                                 cfg_flr_in_process,
  input     [3:0]                                 cfg_flr_done,
  output    [7:0]                                 cfg_vf_flr_in_process,
  input     [7:0]                                 cfg_vf_flr_done,

  output                                          cfg_ext_read_received,
  output                                          cfg_ext_write_received,
  output    [9:0]                                 cfg_ext_register_number,
  output    [7:0]                                 cfg_ext_function_number,
  output   [31:0]                                 cfg_ext_write_data,
  output    [3:0]                                 cfg_ext_write_byte_enable,

  input     [3:0]                                 cfg_interrupt_int,
  input     [3:0]                                 cfg_interrupt_pending,
  output                                          cfg_interrupt_sent,
  output    [3:0]                                 cfg_interrupt_msi_enable,
  output    [7:0]                                 cfg_interrupt_msi_vf_enable,
  output   [11:0]                                 cfg_interrupt_msi_mmenable,
  output                                          cfg_interrupt_msi_mask_update,
  output   [31:0]                                 cfg_interrupt_msi_data,
  input     [3:0]                                 cfg_interrupt_msi_select,
  input    [31:0]                                 cfg_interrupt_msi_int,
  input    [31:0]                                 cfg_interrupt_msi_pending_status,
  output                                          cfg_interrupt_msi_sent,
  output                                          cfg_interrupt_msi_fail,
  input     [2:0]                                 cfg_interrupt_msi_attr,
  input                                           cfg_interrupt_msi_tph_present,
  input     [1:0]                                 cfg_interrupt_msi_tph_type,
  input     [8:0]                                 cfg_interrupt_msi_tph_st_tag,
  input     [3:0]                                 cfg_interrupt_msi_function_number,

  output                                           mcap_design_switch,
  output                                           cap_req,
  input                                            cap_gnt,
  input                                            cap_rel,


//  input    [15:0]                                  cfg_vend_id,
//  input    [15:0]                                  cfg_dev_id,
//  input     [7:0]                                  cfg_rev_id,
//  input    [15:0]                                  cfg_subsys_id,
  input    [15:0]                                  cfg_subsys_vend_id,

  //--------------------------------------------------------------------------------------//
  // Reset Pass Through Signals
  //  - Only used for PCIe_X0Y0
  //--------------------------------------------------------------------------------------//
  output                                           pcie_perstn0_out,
  input                                            pcie_perstn1_in,
  output                                           pcie_perstn1_out,


  input                                            sys_clk,
  input                                            sys_clk_gt,
  input                                            sys_reset
);

  // Local Parameters derived from user selection
  localparam        TCQ = 1;
  localparam  [1:0] AXISTEN_IF_WIDTH           = (C_DATA_WIDTH == 256) ? 2'b10 : ((C_DATA_WIDTH == 128) ? 2'b01 : 2'b00);


  wire startup_eos_in;
  wire icap_clk;
  wire inft_sel;
  wire icap_csib;
  wire icap_rdwrb;
  wire [31:0] icap_i;
  
  
  // PCIe CQ Interface
  wire [C_DATA_WIDTH-1:0] axis_pcie_cq_tdata;
  wire [84:0] axis_pcie_cq_tuser;
  wire axis_pcie_cq_tlast;
  wire [KEEP_WIDTH-1:0] axis_pcie_cq_tkeep;
  wire axis_pcie_cq_tvalid;
  wire axis_pcie_cq_tready;
  wire [5:0] axis_pcie_cq_np_req_count;
  wire axis_pcie_cq_np_req;
  // PCIe CC Interface
  wire [C_DATA_WIDTH-1:0] axis_pcie_cc_tdata;
  wire [32:0] axis_pcie_cc_tuser;
  wire axis_pcie_cc_tlast;
  wire [KEEP_WIDTH-1:0] axis_pcie_cc_tkeep;
  wire axis_pcie_cc_tvalid;
  wire [3:0] axis_pcie_cc_tready; 
  // PCIe RQ interface 
  wire axis_pcie_rq_tlast;
  wire [C_DATA_WIDTH-1:0] axis_pcie_rq_tdata;
  wire [59:0] axis_pcie_rq_tuser;
  wire [KEEP_WIDTH-1:0] axis_pcie_rq_tkeep;
  wire [3:0] axis_pcie_rq_tready;
  wire axis_pcie_rq_tvalid;
  // PCIe RC interface
  wire [C_DATA_WIDTH-1:0] axis_pcie_rc_tdata;
  wire [74:0] axis_pcie_rc_tuser;
  wire axis_pcie_rc_tlast;
  wire [KEEP_WIDTH-1:0] axis_pcie_rc_tkeep;
  wire axis_pcie_rc_tvalid;
  wire axis_pcie_rc_tready;
  // Other switched signals
  wire pcie_power_state_change_ack;
  wire pcie_power_state_change_interrupt;
  wire pcie_msg_received;
  wire [7:0] pcie_msg_received_data;
  wire [4:0] pcie_msg_received_type;
  wire pcie_msg_transmit;
  wire [2:0] pcie_msg_transmit_type;
  wire [31:0] pcie_msg_transmit_data;
  wire pcie_msg_transmit_done;
  wire [3:0] pcie_flr_in_process;
  wire [3:0] pcie_flr_done;
  wire [7:0] pcie_vf_flr_in_process;
  wire [7:0] pcie_vf_flr_done;

  wire [3:0] pcie_interrupt_int;
  wire [3:0] pcie_interrupt_pending;
  wire  pcie_interrupt_sent;
  wire [3:0] pcie_interrupt_msi_enable;
  wire [7:0] pcie_interrupt_msi_vf_enable;
  wire [11:0] pcie_interrupt_msi_mmenable;
  wire pcie_interrupt_msi_mask_update;
  wire [31:0] pcie_interrupt_msi_data;
  wire [3:0] pcie_interrupt_msi_select;
  wire [31:0] pcie_interrupt_msi_int;
  wire [31:0] pcie_interrupt_msi_pending_status;
  wire  pcie_interrupt_msi_sent;
  wire  pcie_interrupt_msi_fail;
  wire [2:0] pcie_interrupt_msi_attr;
  wire  pcie_interrupt_msi_tph_present;
  wire [1:0] pcie_interrupt_msi_tph_type;
  wire [8:0] pcie_interrupt_msi_tph_st_tag;
  wire [3:0] pcie_interrupt_msi_function_number;

  // The user 1 interface connects to and drives the ICAP primitive
  // user 1 CQ Interface
  wire [C_DATA_WIDTH-1:0] axis_icap_cq_tdata;
  wire [84:0] axis_icap_cq_tuser;
  wire axis_icap_cq_tlast;
  wire [KEEP_WIDTH-1:0] axis_icap_cq_tkeep;
  wire axis_icap_cq_tvalid;
  wire axis_icap_cq_tready;
  wire [5:0] axis_icap_cq_np_req_count;
  wire axis_icap_cq_np_req;
  // user 1 CC Interface
  wire [C_DATA_WIDTH-1:0] axis_icap_cc_tdata;
  wire [32:0] axis_icap_cc_tuser;
  wire axis_icap_cc_tlast;
  wire [KEEP_WIDTH-1:0] axis_icap_cc_tkeep;
  wire axis_icap_cc_tvalid;
  wire [3:0] axis_icap_cc_tready; 
  // user_1 RQ interface 
  wire axis_icap_rq_tlast;
  wire [C_DATA_WIDTH-1:0] axis_icap_rq_tdata;
  wire [59:0] axis_icap_rq_tuser;
  wire [KEEP_WIDTH-1:0] axis_icap_rq_tkeep;
  wire [3:0] axis_icap_rq_tready;
  wire axis_icap_rq_tvalid;
  // user 1RC interface
  wire [C_DATA_WIDTH-1:0] axis_icap_rc_tdata;
  wire [74:0] axis_icap_rc_tuser;
  wire axis_icap_rc_tlast;
  wire [KEEP_WIDTH-1:0] axis_icap_rc_tkeep;
  wire axis_icap_rc_tvalid;
  wire axis_icap_rc_tready;
  // Other switched signals
  wire icap_power_state_change_ack;
  wire icap_power_state_change_interrupt;
  wire icap_msg_received;
  wire [7:0] icap_msg_received_data;
  wire [4:0] icap_msg_received_type;
  wire icap_msg_transmit;
  wire [2:0] icap_msg_transmit_type;
  wire [31:0] icap_msg_transmit_data;
  wire icap_msg_transmit_done;
  wire [3:0] icap_flr_in_process;
  wire [3:0] icap_flr_done;
  wire [7:0] icap_vf_flr_in_process;
  wire [7:0] icap_vf_flr_done;
  wire [3:0] icap_interrupt_int;
  wire [3:0] icap_interrupt_pending;
  wire icap_interrupt_sent;
  wire [3:0] icap_interrupt_msi_enable;
  wire [7:0] icap_interrupt_msi_vf_enable;
  wire [11:0] icap_interrupt_msi_mmenable;
  wire icap_interrupt_msi_mask_update;
  wire [31:0] icap_interrupt_msi_data;
  wire [3:0] icap_interrupt_msi_select;
  wire [31:0] icap_interrupt_msi_int;
  wire [31:0] icap_interrupt_msi_pending_status;
  wire  icap_interrupt_msi_sent;
  wire  icap_interrupt_msi_fail;
  wire [2:0] icap_interrupt_msi_attr;
  wire  icap_interrupt_msi_tph_present;
  wire [1:0] icap_interrupt_msi_tph_type;
  wire [8:0] icap_interrupt_msi_tph_st_tag;
  wire [3:0] icap_interrupt_msi_function_number;
  
  // Clock buffer for the 100MHz configuration clock
  BUFG_GT bufg_gt_icapclk (.CE (1'b1), .CEMASK (1'd0), .CLR (1'b0), .CLRMASK (1'd0), .DIV (3'd0), .I (sys_clk), .O (icap_clk));

  // tie-off values that are constant, unused, or not implemented
  wire    [18:0]                                 cfg_mgmt_addr;
  wire                                           cfg_mgmt_write;
  wire    [31:0]                                 cfg_mgmt_write_data;
  wire     [3:0]                                 cfg_mgmt_byte_enable;
  wire                                           cfg_mgmt_read;
  wire                                           cfg_mgmt_type1_cfg_reg_access; 
  wire     [2:0]                                 cfg_per_func_status_control;
  wire     [3:0]                                 cfg_per_function_number;
  wire                                           cfg_per_function_output_request;
  wire    [63:0]                                 cfg_dsn;
  wire                                           cfg_err_cor_in;
  wire                                           cfg_err_uncor_in;
  wire                                           cfg_link_training_enable;
  wire                                           cfg_config_space_enable;
  wire                                           cfg_req_pm_transition_l23_ready;
  wire                                           cfg_hot_reset_in;
  wire     [7:0]                                 cfg_ds_port_number;
  wire     [7:0]                                 cfg_ds_bus_number;
  wire     [4:0]                                 cfg_ds_device_number;
  wire     [2:0]                                 cfg_ds_function_number;
  wire    [31:0]                                 cfg_ext_read_data;
  wire                                           cfg_ext_read_data_valid;
  assign cfg_mgmt_addr                       = 19'h00000;            // Zero out CFG MGMT 19-bit address port
  assign cfg_mgmt_write                      = 1'b0;                 // Do not write CFG space
  assign cfg_mgmt_write_data                 = 32'h00000000;         // Zero out CFG MGMT input data bus
  assign cfg_mgmt_byte_enable                = 4'h0;                 // Zero out CFG MGMT byte enables
  assign cfg_mgmt_read                       = 1'b0;                 // Do not read CFG space
  assign cfg_mgmt_type1_cfg_reg_access       = 1'b0;
  assign cfg_per_func_status_control         = 3'h0;                 // Do not request per function status
  assign cfg_per_function_number             = 4'h0;                 // Zero out function num for status req
  assign cfg_per_function_output_request     = 1'b0;                 // Do not request configuration status update
  assign cfg_dsn                             = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1};  // Assign the input DSN
  assign cfg_err_cor_in                      = 1'b0;                 // Never report Correctable Error
  assign cfg_err_uncor_in                    = 1'b0;                 // Never report UnCorrectable Error
  assign cfg_link_training_enable            = 1'b1;                 // Always enable LTSSM to bring up the Link
  assign cfg_config_space_enable             = 1'b1;
  assign cfg_req_pm_transition_l23_ready     = 1'b0;
  assign cfg_hot_reset_in                    = 1'b0;
  assign cfg_ds_port_number                  = 8'h00;
  assign cfg_ds_bus_number                   = 8'h00;
  assign cfg_ds_device_number                = 5'h00;
  assign cfg_ds_function_number              = 3'h0;
  assign cfg_ext_read_data                   = 32'h00000000;         // Do not provide cfg data externally
  assign cfg_ext_read_data_valid             = 1'b0;                 // Disable external implemented reg cfg read

  // Core Top Level Wrapper
  pcie3_ultrascale_0  pcie3_ultrascale_0_i (

    //---------------------------------------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                                                      //
    //---------------------------------------------------------------------------------------//

    // Tx
    .pci_exp_txn                                    ( pci_exp_txn ),
    .pci_exp_txp                                    ( pci_exp_txp ),

    // Rx
    .pci_exp_rxn                                    ( pci_exp_rxn ),
    .pci_exp_rxp                                    ( pci_exp_rxp ),

    //---------------------------------------------------------------------------------------//
    //  AXI Interface                                                                        //
    //---------------------------------------------------------------------------------------//

    .user_clk                                       ( user_clk ),
    .user_reset                                     ( user_reset ),
    .user_lnk_up                                    ( user_lnk_up ),
    // AXI Stream RQ interface
    .s_axis_rq_tlast                                ( axis_pcie_rq_tlast ),
    .s_axis_rq_tdata                                ( axis_pcie_rq_tdata ),
    .s_axis_rq_tuser                                ( axis_pcie_rq_tuser ),
    .s_axis_rq_tkeep                                ( axis_pcie_rq_tkeep ),
    .s_axis_rq_tready                               ( axis_pcie_rq_tready ),
    .s_axis_rq_tvalid                               ( axis_pcie_rq_tvalid ),
    // AXI stream RC interface
    .m_axis_rc_tdata                                ( axis_pcie_rc_tdata ),
    .m_axis_rc_tuser                                ( axis_pcie_rc_tuser ),
    .m_axis_rc_tlast                                ( axis_pcie_rc_tlast ),
    .m_axis_rc_tkeep                                ( axis_pcie_rc_tkeep ),
    .m_axis_rc_tvalid                               ( axis_pcie_rc_tvalid ),
    .m_axis_rc_tready                               ( axis_pcie_rc_tready ),
     // AXI stream CQ interface
    .m_axis_cq_tdata                                ( axis_pcie_cq_tdata ),
    .m_axis_cq_tuser                                ( axis_pcie_cq_tuser ),
    .m_axis_cq_tlast                                ( axis_pcie_cq_tlast ),
    .m_axis_cq_tkeep                                ( axis_pcie_cq_tkeep ),
    .m_axis_cq_tvalid                               ( axis_pcie_cq_tvalid ),
    .m_axis_cq_tready                               ( axis_pcie_cq_tready ),
    // AXI stream CC interface
    .s_axis_cc_tdata                                ( axis_pcie_cc_tdata ),
    .s_axis_cc_tuser                                ( axis_pcie_cc_tuser ),
    .s_axis_cc_tlast                                ( axis_pcie_cc_tlast ),
    .s_axis_cc_tkeep                                ( axis_pcie_cc_tkeep ),
    .s_axis_cc_tvalid                               ( axis_pcie_cc_tvalid ),
    .s_axis_cc_tready                               ( axis_pcie_cc_tready ),
    .pcie_tfc_nph_av                                ( pcie_tfc_nph_av ),
    .pcie_tfc_npd_av                                ( pcie_tfc_npd_av ),
    .pcie_rq_seq_num                                ( pcie_rq_seq_num ),
    .pcie_rq_seq_num_vld                            ( pcie_rq_seq_num_vld ),
    .pcie_rq_tag                                    ( pcie_rq_tag ),
    .pcie_rq_tag_vld                                ( pcie_rq_tag_vld ),
    .pcie_rq_tag_av                                 ( pcie_rq_tag_av ),

    .pcie_cq_np_req                                 ( axis_pcie_cq_np_req ),
    .pcie_cq_np_req_count                           ( axis_pcie_cq_np_req_count ),

    //---------------------------------------------------------------------------------------//
    //  Configuration (CFG) Interface                                                        //
    //---------------------------------------------------------------------------------------//

    //-------------------------------------------------------------------------------//
    // EP and RP                                                                     //
    //-------------------------------------------------------------------------------//
    .cfg_phy_link_down                              ( cfg_phy_link_down ),
    .cfg_phy_link_status                            ( cfg_phy_link_status ),
    .cfg_negotiated_width                           ( cfg_negotiated_width ),
    .cfg_current_speed                              ( cfg_current_speed ),
    .cfg_max_payload                                ( cfg_max_payload ),
    .cfg_max_read_req                               ( cfg_max_read_req ),
    .cfg_function_status                            ( cfg_function_status ),
    .cfg_function_power_state                       ( cfg_function_power_state ),
    .cfg_vf_status                                  ( cfg_vf_status ),
    .cfg_vf_power_state                             ( cfg_vf_power_state ),
    .cfg_link_power_state                           ( cfg_link_power_state ),

    // Error Reporting Interface
    .cfg_err_cor_out                                ( cfg_err_cor_out ),
    .cfg_err_nonfatal_out                           ( cfg_err_nonfatal_out ),
    .cfg_err_fatal_out                              ( cfg_err_fatal_out ),
    .cfg_local_error                                ( cfg_local_error ),

    .cfg_ltr_enable                                 ( cfg_ltr_enable ),
    .cfg_ltssm_state                                ( cfg_ltssm_state ),
    .cfg_rcb_status                                 ( cfg_rcb_status ),
    .cfg_dpa_substate_change                        ( cfg_dpa_substate_change ),
    .cfg_obff_enable                                ( cfg_obff_enable ),
    .cfg_pl_status_change                           ( cfg_pl_status_change ),

    .cfg_tph_requester_enable                       ( cfg_tph_requester_enable ),
    .cfg_tph_st_mode                                ( cfg_tph_st_mode ),
    .cfg_vf_tph_requester_enable                    ( cfg_vf_tph_requester_enable ),
    .cfg_vf_tph_st_mode                             ( cfg_vf_tph_st_mode ),

    // Management Interface
    .cfg_mgmt_addr                                  ( cfg_mgmt_addr ),
    .cfg_mgmt_write                                 ( cfg_mgmt_write ),
    .cfg_mgmt_write_data                            ( cfg_mgmt_write_data ),
    .cfg_mgmt_byte_enable                           ( cfg_mgmt_byte_enable ),
    .cfg_mgmt_read                                  ( cfg_mgmt_read ),
    .cfg_mgmt_read_data                             ( ),
    .cfg_mgmt_read_write_done                       ( ),
    .cfg_mgmt_type1_cfg_reg_access                  ( cfg_mgmt_type1_cfg_reg_access ),

    .cfg_msg_received                               ( pcie_msg_received ),
    .cfg_msg_received_data                          ( pcie_msg_received_data ),
    .cfg_msg_received_type                          ( pcie_msg_received_type ),
    .cfg_msg_transmit                               ( pcie_msg_transmit ),
    .cfg_msg_transmit_type                          ( pcie_msg_transmit_type ),
    .cfg_msg_transmit_data                          ( pcie_msg_transmit_data ),
    .cfg_msg_transmit_done                          ( pcie_msg_transmit_done ),

    .cfg_fc_ph                                      ( cfg_fc_ph ),
    .cfg_fc_pd                                      ( cfg_fc_pd ),
    .cfg_fc_nph                                     ( cfg_fc_nph ),
    .cfg_fc_npd                                     ( cfg_fc_npd ),
    .cfg_fc_cplh                                    ( cfg_fc_cplh ),
    .cfg_fc_cpld                                    ( cfg_fc_cpld ),
    .cfg_fc_sel                                     ( cfg_fc_sel ),

    .cfg_per_func_status_control                    ( cfg_per_func_status_control ),
    .cfg_per_func_status_data                       ( ),
    .cfg_per_function_number                        ( cfg_per_function_number ),
    .cfg_per_function_output_request                ( cfg_per_function_output_request ),
    .cfg_per_function_update_done                   ( ),
    
  // EP only
    .cfg_hot_reset_out                              ( ),
    .cfg_config_space_enable                        ( cfg_config_space_enable ),
    .cfg_req_pm_transition_l23_ready                ( cfg_req_pm_transition_l23_ready ),

  // RP only
    .cfg_hot_reset_in                               ( cfg_hot_reset_in ),

    .cfg_ds_bus_number                              ( cfg_ds_bus_number ),
    .cfg_ds_device_number                           ( cfg_ds_device_number ),
    .cfg_ds_function_number                         ( cfg_ds_function_number ),
    .cfg_ds_port_number                             ( cfg_ds_port_number ),
    .cfg_dsn                                        ( cfg_dsn ),
    .cfg_power_state_change_ack                     ( pcie_power_state_change_ack ),
    .cfg_power_state_change_interrupt               ( pcie_power_state_change_interrupt ),
    .cfg_err_cor_in                                 ( cfg_err_cor_in ),
    .cfg_err_uncor_in                               ( cfg_err_uncor_in ),
    .cfg_flr_in_process                             ( pcie_flr_in_process ),
    .cfg_flr_done                                   ( pcie_flr_done ),
    .cfg_vf_flr_in_process                          ( pcie_vf_flr_in_process ),
    .cfg_vf_flr_done                                ( pcie_vf_flr_done ),
    .cfg_link_training_enable                       ( cfg_link_training_enable ),

    .cfg_ext_read_received                          ( cfg_ext_read_received ),
    .cfg_ext_write_received                         ( cfg_ext_write_received ),
    .cfg_ext_register_number                        ( cfg_ext_register_number ),
    .cfg_ext_function_number                        ( cfg_ext_function_number ),
    .cfg_ext_write_data                             ( cfg_ext_write_data ),
    .cfg_ext_write_byte_enable                      ( cfg_ext_write_byte_enable ),
    .cfg_ext_read_data                              ( cfg_ext_read_data ),
    .cfg_ext_read_data_valid                        ( cfg_ext_read_data_valid ),
    //-------------------------------------------------------------------------------//
    // EP Only                                                                       //
    //-------------------------------------------------------------------------------//

    // Interrupt Interface Signals
    .cfg_interrupt_int                              (pcie_interrupt_int ),
    .cfg_interrupt_pending                          (pcie_interrupt_pending ),
    .cfg_interrupt_sent                             (pcie_interrupt_sent ),

    .cfg_interrupt_msi_enable                       (pcie_interrupt_msi_enable ),
    .cfg_interrupt_msi_vf_enable                    (pcie_interrupt_msi_vf_enable ),
    .cfg_interrupt_msi_mmenable                     (pcie_interrupt_msi_mmenable ),
    .cfg_interrupt_msi_mask_update                  (pcie_interrupt_msi_mask_update ),
    .cfg_interrupt_msi_data                         (pcie_interrupt_msi_data ),
    .cfg_interrupt_msi_select                       (pcie_interrupt_msi_select ),
    .cfg_interrupt_msi_int                          (pcie_interrupt_msi_int ),
    .cfg_interrupt_msi_pending_status               (pcie_interrupt_msi_pending_status ),
    .cfg_interrupt_msi_pending_status_function_num  ( 4'b0 ),
    .cfg_interrupt_msi_pending_status_data_enable   ( 1'b0 ),
    .cfg_interrupt_msi_sent                         (pcie_interrupt_msi_sent ),
    .cfg_interrupt_msi_fail                         (pcie_interrupt_msi_fail ),
    .cfg_interrupt_msi_attr                         (pcie_interrupt_msi_attr ),
    .cfg_interrupt_msi_tph_present                  (pcie_interrupt_msi_tph_present ),
    .cfg_interrupt_msi_tph_type                     (pcie_interrupt_msi_tph_type ),
    .cfg_interrupt_msi_tph_st_tag                   (pcie_interrupt_msi_tph_st_tag ),
    .cfg_interrupt_msi_function_number              (pcie_interrupt_msi_function_number ),


    .mcap_design_switch                             (mcap_design_switch),
    .mcap_eos_in                                    (startup_eos_in),
    .cap_req                                        (cap_req),
    .cap_gnt                                        (cap_gnt),
    .cap_rel                                        (cap_rel),
  
//    .cfg_vend_id                                    ( cfg_vend_id ),
//    .cfg_dev_id                                     ( cfg_dev_id ),
//    .cfg_rev_id                                     ( cfg_rev_id ),
//    .cfg_subsys_id                                  ( cfg_subsys_id ),
    .cfg_subsys_vend_id                             ( cfg_subsys_vend_id ),

    //--------------------------------------------------------------------------------------//
    // Reset Pass Through Signals
    //  - Only used for PCIe_X0Y0
    //--------------------------------------------------------------------------------------//
    .pcie_perstn0_out                               ( pcie_perstn0_out ),
    .pcie_perstn1_in                                ( pcie_perstn1_in ),
    .pcie_perstn1_out                               ( pcie_perstn1_out ),


   //---------- Shared Logic Internal -------------------------
    .int_qpll1lock_out                              (int_qpll1lock_out),   
    .int_qpll1outrefclk_out                         (int_qpll1outrefclk_out),
    .int_qpll1outclk_out                            (int_qpll1outclk_out),


    //--------------------------------------------------------------------------------------//
    //  System(SYS) Interface                                                               //
    //--------------------------------------------------------------------------------------//
    .sys_clk                                        ( sys_clk ),
    .sys_clk_gt                                     ( sys_clk_gt ),
    .sys_reset                                      ( sys_reset )

  );

  // Splitter CQ, CC Spliter IP
  // This IP splits the PCIe Stream interfaces and routes them to separate IPs
  pcie_interface_multiplexer #(
    .C_DATA_WIDTH(C_DATA_WIDTH), // RX/TX interface data width
    .KEEP_WIDTH(KEEP_WIDTH)
  ) pcie_interface_multiplexer_i (  
   
    // gneral core inputs
    .inft_sel                                       ( inft_sel ),

    // PCIe CQ Interface
    .s_axis_pcie_cq_tdata                           ( axis_pcie_cq_tdata ),
    .s_axis_pcie_cq_tuser                           ( axis_pcie_cq_tuser ),
    .s_axis_pcie_cq_tlast                           ( axis_pcie_cq_tlast ),
    .s_axis_pcie_cq_tkeep                           ( axis_pcie_cq_tkeep ),
    .s_axis_pcie_cq_tvalid                          ( axis_pcie_cq_tvalid ),
    .s_axis_pcie_cq_tready                          ( axis_pcie_cq_tready ),
    .s_axis_pcie_cq_np_req_count                    ( axis_pcie_cq_np_req_count),
    .s_axis_pcie_cq_np_req                          ( axis_pcie_cq_np_req),
    // PCIe CC Interface
    .m_axis_pcie_cc_tdata                           ( axis_pcie_cc_tdata ),
    .m_axis_pcie_cc_tuser                           ( axis_pcie_cc_tuser ),
    .m_axis_pcie_cc_tlast                           ( axis_pcie_cc_tlast ),
    .m_axis_pcie_cc_tkeep                           ( axis_pcie_cc_tkeep ),
    .m_axis_pcie_cc_tvalid                          ( axis_pcie_cc_tvalid ),
    .m_axis_pcie_cc_tready                          ( axis_pcie_cc_tready ), 
    // PCIe RQ interface 
    .m_axis_pcie_rq_tlast                                ( axis_pcie_rq_tlast ),
    .m_axis_pcie_rq_tdata                                ( axis_pcie_rq_tdata ),
    .m_axis_pcie_rq_tuser                                ( axis_pcie_rq_tuser ),
    .m_axis_pcie_rq_tkeep                                ( axis_pcie_rq_tkeep ),
    .m_axis_pcie_rq_tready                               ( axis_pcie_rq_tready ),
    .m_axis_pcie_rq_tvalid                               ( axis_pcie_rq_tvalid ),
    // PCIe RC interface
    .s_axis_pcie_rc_tdata                                ( axis_pcie_rc_tdata ),
    .s_axis_pcie_rc_tuser                                ( axis_pcie_rc_tuser ),
    .s_axis_pcie_rc_tlast                                ( axis_pcie_rc_tlast ),
    .s_axis_pcie_rc_tkeep                                ( axis_pcie_rc_tkeep ),
    .s_axis_pcie_rc_tvalid                               ( axis_pcie_rc_tvalid ),
    .s_axis_pcie_rc_tready                               ( axis_pcie_rc_tready ),
    // Other switched signals
    .pcie_power_state_change_ack                   (pcie_power_state_change_ack),
    .pcie_power_state_change_interrupt             (pcie_power_state_change_interrupt),
    .pcie_msg_received                               ( pcie_msg_received ),
    .pcie_msg_received_data                          ( pcie_msg_received_data ),
    .pcie_msg_received_type                          ( pcie_msg_received_type ),
    .pcie_msg_transmit                               ( pcie_msg_transmit ),
    .pcie_msg_transmit_type                          ( pcie_msg_transmit_type ),
    .pcie_msg_transmit_data                          ( pcie_msg_transmit_data ),
    .pcie_msg_transmit_done                          ( pcie_msg_transmit_done ),

    .pcie_flr_in_process                             ( pcie_flr_in_process ),
    .pcie_flr_done                                   ( pcie_flr_done ),
    .pcie_vf_flr_in_process                          ( pcie_vf_flr_in_process ),
    .pcie_vf_flr_done                                ( pcie_vf_flr_done ),
    // Interrupt Interface Signals
    .pcie_interrupt_int                              ( pcie_interrupt_int ),
    .pcie_interrupt_pending                          ( pcie_interrupt_pending ),
    .pcie_interrupt_sent                             ( pcie_interrupt_sent ),

    .pcie_interrupt_msi_enable                       (pcie_interrupt_msi_enable ),
    .pcie_interrupt_msi_vf_enable                    (pcie_interrupt_msi_vf_enable ),
    .pcie_interrupt_msi_mmenable                     (pcie_interrupt_msi_mmenable ),
    .pcie_interrupt_msi_mask_update                  (pcie_interrupt_msi_mask_update ),
    .pcie_interrupt_msi_data                         (pcie_interrupt_msi_data ),
    .pcie_interrupt_msi_select                       (pcie_interrupt_msi_select ),
    .pcie_interrupt_msi_int                          (pcie_interrupt_msi_int ),
    .pcie_interrupt_msi_pending_status               (pcie_interrupt_msi_pending_status ),
    .pcie_interrupt_msi_sent                         (pcie_interrupt_msi_sent ),
    .pcie_interrupt_msi_fail                         (pcie_interrupt_msi_fail ),
    .pcie_interrupt_msi_attr                         (pcie_interrupt_msi_attr ),
    .pcie_interrupt_msi_tph_present                  (pcie_interrupt_msi_tph_present ),
    .pcie_interrupt_msi_tph_type                     (pcie_interrupt_msi_tph_type ),
    .pcie_interrupt_msi_tph_st_tag                   (pcie_interrupt_msi_tph_st_tag ),
    .pcie_interrupt_msi_function_number              (pcie_interrupt_msi_function_number ),
        
    // The user 0 interfaces passes to the user application
    // user 0 CQ Interface
    .m_axis0_cq_tdata                               ( m_axis_cq_tdata ),
    .m_axis0_cq_tuser                               ( m_axis_cq_tuser ),
    .m_axis0_cq_tlast                               ( m_axis_cq_tlast ),
    .m_axis0_cq_tkeep                               ( m_axis_cq_tkeep ),
    .m_axis0_cq_tvalid                              ( m_axis_cq_tvalid ),
    .m_axis0_cq_tready                              ( m_axis_cq_tready ),
    .m_axis0_cq_np_req_count                        (pcie_cq_np_req_count),
    .m_axis0_cq_np_req                              (pcie_cq_np_req),
    // user 0 CC Interface
    .s_axis0_cc_tdata                               ( s_axis_cc_tdata ),
    .s_axis0_cc_tuser                               ( s_axis_cc_tuser ),
    .s_axis0_cc_tlast                               ( s_axis_cc_tlast ),
    .s_axis0_cc_tkeep                               ( s_axis_cc_tkeep ),
    .s_axis0_cc_tvalid                              ( s_axis_cc_tvalid ),
    .s_axis0_cc_tready                              ( s_axis_cc_tready ), 
    // PCIe RQ interface 
    .s_axis0_rq_tlast                                ( s_axis_rq_tlast ),
    .s_axis0_rq_tdata                                ( s_axis_rq_tdata ),
    .s_axis0_rq_tuser                                ( s_axis_rq_tuser ),
    .s_axis0_rq_tkeep                                ( s_axis_rq_tkeep ),
    .s_axis0_rq_tready                               ( s_axis_rq_tready ),
    .s_axis0_rq_tvalid                               ( s_axis_rq_tvalid ),
    // PCIe RC interface
    .m_axis0_rc_tdata                               ( m_axis_rc_tdata ),
    .m_axis0_rc_tuser                               ( m_axis_rc_tuser ),
    .m_axis0_rc_tlast                               ( m_axis_rc_tlast ),
    .m_axis0_rc_tkeep                               ( m_axis_rc_tkeep ),
    .m_axis0_rc_tvalid                              ( m_axis_rc_tvalid ),
    .m_axis0_rc_tready                              ( m_axis_rc_tready ),
    // Other switched signals
    .intf0_power_state_change_ack                   (cfg_power_state_change_ack),
    .intf0_power_state_change_interrupt             (cfg_power_state_change_interrupt),
    .intf0_msg_received                             (cfg_msg_received ),
    .intf0_msg_received_data                        (cfg_msg_received_data ),
    .intf0_msg_received_type                        (cfg_msg_received_type ),
    .intf0_msg_transmit                             (cfg_msg_transmit ),
    .intf0_msg_transmit_type                        (cfg_msg_transmit_type ),
    .intf0_msg_transmit_data                        (cfg_msg_transmit_data ),
    .intf0_msg_transmit_done                        (cfg_msg_transmit_done ),
    
    .intf0_flr_in_process                             ( cfg_flr_in_process ),
    .intf0_flr_done                                   ( cfg_flr_done ),
    .intf0_vf_flr_in_process                          ( cfg_vf_flr_in_process ),
    .intf0_vf_flr_done                                ( cfg_vf_flr_done ),
    // Interrupt Interface Signals
    .intf0_interrupt_int                              ( cfg_interrupt_int ),
    .intf0_interrupt_pending                          ( cfg_interrupt_pending ),
    .intf0_interrupt_sent                             ( cfg_interrupt_sent ),

    .intf0_interrupt_msi_enable                       ( cfg_interrupt_msi_enable ),
    .intf0_interrupt_msi_vf_enable                    ( cfg_interrupt_msi_vf_enable ),
    .intf0_interrupt_msi_mmenable                     ( cfg_interrupt_msi_mmenable ),
    .intf0_interrupt_msi_mask_update                  ( cfg_interrupt_msi_mask_update ),
    .intf0_interrupt_msi_data                         ( cfg_interrupt_msi_data ),
    .intf0_interrupt_msi_select                       ( cfg_interrupt_msi_select ),
    .intf0_interrupt_msi_int                          ( cfg_interrupt_msi_int ),
    .intf0_interrupt_msi_pending_status               ( cfg_interrupt_msi_pending_status ),
    .intf0_interrupt_msi_sent                         ( cfg_interrupt_msi_sent ),
    .intf0_interrupt_msi_fail                         ( cfg_interrupt_msi_fail ),
    .intf0_interrupt_msi_attr                         ( cfg_interrupt_msi_attr ),
    .intf0_interrupt_msi_tph_present                  ( cfg_interrupt_msi_tph_present ),
    .intf0_interrupt_msi_tph_type                     ( cfg_interrupt_msi_tph_type ),
    .intf0_interrupt_msi_tph_st_tag                   ( cfg_interrupt_msi_tph_st_tag ),
    .intf0_interrupt_msi_function_number              ( cfg_interrupt_msi_function_number ),
    
    // The user 1 interface connects to and drives the ICAP primitive
    // user 1 CQ Interface
    .m_axis1_cq_tdata                               ( axis_icap_cq_tdata ),
    .m_axis1_cq_tuser                               ( axis_icap_cq_tuser ),
    .m_axis1_cq_tlast                               ( axis_icap_cq_tlast ),
    .m_axis1_cq_tkeep                               ( axis_icap_cq_tkeep ),
    .m_axis1_cq_tvalid                              ( axis_icap_cq_tvalid ),
    .m_axis1_cq_tready                              ( axis_icap_cq_tready ),
    .m_axis1_cq_np_req_count                        ( axis_icap_cq_np_req_count ),
    .m_axis1_cq_np_req                              ( axis_icap_cq_np_req ),
    // user 1 CC Interface
    .s_axis1_cc_tdata                               ( axis_icap_cc_tdata ),
    .s_axis1_cc_tuser                               ( axis_icap_cc_tuser ),
    .s_axis1_cc_tlast                               ( axis_icap_cc_tlast ),
    .s_axis1_cc_tkeep                               ( axis_icap_cc_tkeep ),
    .s_axis1_cc_tvalid                              ( axis_icap_cc_tvalid ),
    .s_axis1_cc_tready                              ( axis_icap_cc_tready ), 
    // user_1 RQ interface 
    .s_axis1_rq_tlast                               ( axis_icap_rq_tlast ),
    .s_axis1_rq_tdata                               ( axis_icap_rq_tdata ),
    .s_axis1_rq_tuser                               ( axis_icap_rq_tuser ),
    .s_axis1_rq_tkeep                               ( axis_icap_rq_tkeep ),
    .s_axis1_rq_tready                              ( axis_icap_rq_tready ),
    .s_axis1_rq_tvalid                              ( axis_icap_rq_tvalid ),
    // user 1RC interface
    .m_axis1_rc_tdata                               ( axis_icap_rc_tdata ),
    .m_axis1_rc_tuser                               ( axis_icap_rc_tuser ),
    .m_axis1_rc_tlast                               ( axis_icap_rc_tlast ),
    .m_axis1_rc_tkeep                               ( axis_icap_rc_tkeep ),
    .m_axis1_rc_tvalid                              ( axis_icap_rc_tvalid ),
    .m_axis1_rc_tready                              ( axis_icap_rc_tready ),
    // Other switched signals
    .intf1_power_state_change_ack                   (icap_power_state_change_ack),
    .intf1_power_state_change_interrupt             (icap_power_state_change_interrupt),
    .intf1_msg_received                               (icap_msg_received ),
    .intf1_msg_received_data                          (icap_msg_received_data ),
    .intf1_msg_received_type                          (icap_msg_received_type ),
    .intf1_msg_transmit                               (icap_msg_transmit ),
    .intf1_msg_transmit_type                          (icap_msg_transmit_type ),
    .intf1_msg_transmit_data                          (icap_msg_transmit_data ),
    .intf1_msg_transmit_done                          (icap_msg_transmit_done ),

    .intf1_flr_in_process                             (icap_flr_in_process ),
    .intf1_flr_done                                   (icap_flr_done ),
    .intf1_vf_flr_in_process                          (icap_vf_flr_in_process ),
    .intf1_vf_flr_done                                (icap_vf_flr_done ),
    // Interrupt Interface Signals
    .intf1_interrupt_int                              ( icap_interrupt_int ),
    .intf1_interrupt_pending                          ( icap_interrupt_pending ),
    .intf1_interrupt_sent                             ( icap_interrupt_sent ),

    .intf1_interrupt_msi_enable                       ( icap_interrupt_msi_enable ),
    .intf1_interrupt_msi_vf_enable                    ( icap_interrupt_msi_vf_enable ),
    .intf1_interrupt_msi_mmenable                     ( icap_interrupt_msi_mmenable ),
    .intf1_interrupt_msi_mask_update                  ( icap_interrupt_msi_mask_update ),
    .intf1_interrupt_msi_data                         ( icap_interrupt_msi_data ),
    .intf1_interrupt_msi_select                       ( icap_interrupt_msi_select ),
    .intf1_interrupt_msi_int                          ( icap_interrupt_msi_int ),
    .intf1_interrupt_msi_pending_status               ( icap_interrupt_msi_pending_status ),
    .intf1_interrupt_msi_sent                         ( icap_interrupt_msi_sent ),
    .intf1_interrupt_msi_fail                         ( icap_interrupt_msi_fail ),
    .intf1_interrupt_msi_attr                         ( icap_interrupt_msi_attr ),
    .intf1_interrupt_msi_tph_present                  ( icap_interrupt_msi_tph_present ),
    .intf1_interrupt_msi_tph_type                     ( icap_interrupt_msi_tph_type ),
    .intf1_interrupt_msi_tph_st_tag                   ( icap_interrupt_msi_tph_st_tag ),
    .intf1_interrupt_msi_function_number              ( icap_interrupt_msi_function_number )    
  );
  
  // ICAP Controller Module. This module takes data from the bus and loads it into the ICAP.
  pcie3_7x_0_pr_loader #(
    .C_DATA_WIDTH(C_DATA_WIDTH),
    .KEEP_WIDTH(KEEP_WIDTH),
    .AXISTEN_IF_WIDTH(AXISTEN_IF_WIDTH),
    .AXISTEN_IF_RQ_ALIGNMENT_MODE("FALSE"),
    .AXISTEN_IF_CC_ALIGNMENT_MODE("FALSE"),
    .AXISTEN_IF_CQ_ALIGNMENT_MODE("FALSE"),
    .AXISTEN_IF_RC_ALIGNMENT_MODE("FALSE"),
    .AXISTEN_IF_ENABLE_CLIENT_TAG(0),
    .AXISTEN_IF_RQ_PARITY_CHECK(0),
    .AXISTEN_IF_CC_PARITY_CHECK(0),
    .AXISTEN_IF_MC_RX_STRADDLE(0),
    .AXISTEN_IF_ENABLE_RX_MSG_INTFC(0),
    .AXISTEN_IF_ENABLE_MSG_ROUTE(18'h2FFFF)
  ) pr_loader_i (
    // System Ports
    .sys_clk(user_clk),
    .sys_rst_n(~user_reset),
    .user_lnk_up(user_lnk_up),
    .conf_clk(icap_clk),
    // link status signals
    .cfg_power_state_change_ack(icap_power_state_change_ack),
    .cfg_power_state_change_interrupt(icap_power_state_change_interrupt),
    .cfg_msg_received                               ( icap_msg_received ),
    .cfg_msg_received_data                          ( icap_msg_received_data ),
    .cfg_msg_received_type                          ( icap_msg_received_type ),
    .cfg_msg_transmit                               ( icap_msg_transmit ),
    .cfg_msg_transmit_type                          ( icap_msg_transmit_type ),
    .cfg_msg_transmit_data                          ( icap_msg_transmit_data ),
    .cfg_msg_transmit_done                          ( icap_msg_transmit_done ),
    .cfg_flr_in_process                             ( icap_flr_in_process ),
    .cfg_flr_done                                   ( icap_flr_done ),
    .cfg_vf_flr_in_process                          ( icap_vf_flr_in_process ),
    .cfg_vf_flr_done                                ( icap_vf_flr_done ),
    // Interrupt Interface Signals
    .cfg_interrupt_int                              ( icap_interrupt_int ),
    .cfg_interrupt_pending                          ( icap_interrupt_pending ),
    .cfg_interrupt_sent                             ( icap_interrupt_sent ),

    .cfg_interrupt_msi_enable                       ( icap_interrupt_msi_enable ),
    .cfg_interrupt_msi_vf_enable                    ( icap_interrupt_msi_vf_enable ),
    .cfg_interrupt_msi_mmenable                     ( icap_interrupt_msi_mmenable ),
    .cfg_interrupt_msi_mask_update                  ( icap_interrupt_msi_mask_update ),
    .cfg_interrupt_msi_data                         ( icap_interrupt_msi_data ),
    .cfg_interrupt_msi_select                       ( icap_interrupt_msi_select ),
    .cfg_interrupt_msi_int                          ( icap_interrupt_msi_int ),
    .cfg_interrupt_msi_pending_status               ( icap_interrupt_msi_pending_status ),
    .cfg_interrupt_msi_sent                         ( icap_interrupt_msi_sent ),
    .cfg_interrupt_msi_fail                         ( icap_interrupt_msi_fail ),
    .cfg_interrupt_msi_attr                         ( icap_interrupt_msi_attr ),
    .cfg_interrupt_msi_tph_present                  ( icap_interrupt_msi_tph_present ),
    .cfg_interrupt_msi_tph_type                     ( icap_interrupt_msi_tph_type ),
    .cfg_interrupt_msi_tph_st_tag                   ( icap_interrupt_msi_tph_st_tag ),
    .cfg_interrupt_msi_function_number              ( icap_interrupt_msi_function_number ),

    // AXI Stream Ports
    // AXI CQ interface
    .m_axis_cq_tdata      (axis_icap_cq_tdata),
    .m_axis_cq_tuser      (axis_icap_cq_tuser),
    .m_axis_cq_tlast      (axis_icap_cq_tlast),
    .m_axis_cq_tkeep      (axis_icap_cq_tkeep),
    .m_axis_cq_tvalid     (axis_icap_cq_tvalid),
    .m_axis_cq_tready     (axis_icap_cq_tready),
    .pcie_cq_np_req_count (axis_icap_cq_np_req_count),
    .pcie_cq_np_req       (axis_icap_cq_np_req),
    // AXI CC interface
    .s_axis_cc_tdata  (axis_icap_cc_tdata),
    .s_axis_cc_tuser  (axis_icap_cc_tuser),
    .s_axis_cc_tlast  (axis_icap_cc_tlast),
    .s_axis_cc_tkeep  (axis_icap_cc_tkeep),
    .s_axis_cc_tvalid (axis_icap_cc_tvalid),
    .s_axis_cc_tready (axis_icap_cc_tready),
    // AXI RQ interface
    .s_axis_rq_tlast  (axis_icap_rq_tlast),
    .s_axis_rq_tdata  (axis_icap_rq_tdata),
    .s_axis_rq_tuser  (axis_icap_rq_tuser),
    .s_axis_rq_tkeep  (axis_icap_rq_tkeep),
    .s_axis_rq_tready (axis_icap_rq_tready),
    .s_axis_rq_tvalid (axis_icap_rq_tvalid),
    // AXI RC interface
    .m_axis_rc_tdata  (axis_icap_rc_tdata),
    .m_axis_rc_tuser  (axis_icap_rc_tuser),
    .m_axis_rc_tlast  (axis_icap_rc_tlast),
    .m_axis_rc_tkeep  (axis_icap_rc_tkeep),
    .m_axis_rc_tvalid (axis_icap_rc_tvalid),
    .m_axis_rc_tready (axis_icap_rc_tready),

    // Signals to ensure the swtich to interface 1 does not happen during a PCIe transaction
    .user_app_rdy_req(cap_req),   // Request switch to stage2
    .user_app_rdy_gnt(inft_sel),  // Grant switch to stage2

    // ICAP signals
    .pr_done(),
    .ICAP_ceb(icap_csib),
    .ICAP_wrb(icap_rdwrb),
    .ICAP_din_bs(icap_i)          // bitswapped version of ICAP_din
  );
 
  ila_ICAP  u_ila_ICAP (
          .clk(icap_clk), // input wire clk
          .probe0({4'd0, cap_req, inft_sel, icap_csib, icap_rdwrb, icap_i}) // input wire [39:0] probe0
  );

  // ICAP primitive required to access the configuration logic of the FPGA
  (* dont_touch = "true" *) 
  ICAPE3 #(
    .DEVICE_ID         ( 32'h03628093 ),      // Specifies the pre-programmed Device ID value
    .ICAP_AUTO_SWITCH  ("DISABLE"),           // Enable switch ICAP using sync word
    .SIM_CFG_FILE_NAME ( "NONE" )             // Specifies the Raw Bitstream (RBT) file to be parsed by the simulation
                                              // model
  ) ICAPE3_inst (
    .AVAIL              ( ),                  // 1-bit output: Availability status of ICAP
    .PRDONE             ( ),                  // 1-bit output: Indicates completion of Partial Reconfiguration
    .PRERROR            ( ),                  // 1-bit output: Indicates Error during Partial Reconfiguration
    .CLK                ( icap_clk ),         // 1-bit input: Clock Input (100MHz)
    .CSIB               ( icap_csib ),        // 1-bit input: Active-Low ICAP Enable
    .RDWRB              ( icap_rdwrb ),       // 1-bit input: Read/Write Select input
    .I                  ( icap_i ),           // 32-bit input: Configuration data input bus
    .O                  ( )            // 32-bit output: Configuration data output bus
  );
     
  // Startup primitive. this must drive the startup_eos input to the PCIe block.
  // This signal is used for stage1/stage2 detection and thus assertion of the 
  // mcap_design_switch signal.
  STARTUPE3 startup_i (
    .CFGCLK(),          // output
    .CFGMCLK(),         // output
    .DI(),              // output
    .EOS(startup_eos_in),  // output
    .PREQ(),            // output
    .DO(4'b0000),       // input
    .DTS(4'b0000),      // input
    .FCSBO(1'b0),       // input
    .FCSBTS(1'b0),      // input
    .GSR(1'b0),         // input
    .GTS(1'b0),         // input
    .KEYCLEARB(1'b1),   // input
    .PACK(1'b0),        // input
    .USRCCLKO(1'b0),    // input
    .USRCCLKTS(1'b1),   // input
    .USRDONEO(1'b0),    // input
    .USRDONETS(1'b1)    // input
  );

endmodule


