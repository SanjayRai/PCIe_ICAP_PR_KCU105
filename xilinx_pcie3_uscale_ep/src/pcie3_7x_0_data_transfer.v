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
// File       : pcie3_7x_0_data_transfer.v
// Version    : 4.2
//-----------------------------------------------------------------------------
//
// Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
// File       : pcie3_7x_0_data_transfer.v
// Version    : 1.4
//
//---------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 1ns / 1ns
//---------------------------------------------------------------------------------------------------------------------------------------------//
module pcie3_7x_0_data_transfer (
   input          trn_clk,
   input          conf_clk,
   input          trn_reset_n,
   // Test-Signals for analysing incoming data-stream
   input          dis_data_trf_conf,
   input          conf_FIFO_clr,
   // Interface to APP_BDG(driven by trn_clk)
   input          wr_rqst,
   input [31:0]   wr_data,
   output reg     pause,
   // Interface to ICAP_ACC(driven by conf_clk)
   output [31:0]  conf_data,
   output reg     conf_enable,
   output         pr_done
);

   wire             FIFO_empty;
   reg              FIFO_rd_en;
   reg              FIFO_rd_en_prev;
   wire             FIFO_prog_full;
   reg              start_config;
   reg              end_config;

   parameter [31:0] SOC_1 = 32'h53545254;   //"STRT"
   parameter [31:0] EOC_1 = 32'h454E445F;   //"END_"
   parameter [31:0] WOC_2 = 32'h434F4E46;   //"CONF"
   parameter [31:0] WOC_3 = 32'h50434965;   //"PCIe"

   reg              soc_1_fd;
   reg              soc_1_fd_1dly;
   reg              soc_1_fd_2dly;
   reg              eoc_1_fd;
   reg              eoc_1_fd_1dly;
   reg              eoc_1_fd_2dly;
   reg              soc_2_fd, eoc_2_fd;
   reg              soc_2_fd_1dly, eoc_2_fd_1dly;
   reg              soc_3_fd, eoc_3_fd;
   reg [4:0]        entries;
   reg              pr_done_c;
   reg              purge;
   reg              conf_FIFO_clr_sync, conf_FIFO_clr_sync1;

   wire [31:0]      conf_data_fifo;
  //----------------------------------------------------------------------------------------------------------------//
   always @(posedge conf_clk) begin
      conf_FIFO_clr_sync = conf_FIFO_clr;
      conf_FIFO_clr_sync1 = conf_FIFO_clr_sync;
   end
//---------------------------------------------------------------------------------------------------------------------------------------------//
// FIFO For Storing Configuration Data
//---------------------------------------------------------------------------------------------------------------------------------------------//
   pcie3_7x_0_fastConfigFIFO fastConfigFIFO_i (
      .rst       (conf_FIFO_clr_sync1),
      .wr_clk    (trn_clk),
      .rd_clk    (conf_clk),
      .din       (wr_data),
      .wr_en     (wr_rqst),
      .rd_en     (FIFO_rd_en),
      .dout      (conf_data_fifo),
      .full      (),
      .empty     (FIFO_empty),
      .prog_full (FIFO_prog_full)
   );
  //----------------------------------------------------------------------------------------------------------------//
   always @(posedge trn_clk or negedge trn_reset_n) begin
      if (!trn_reset_n) entries <= 5'b0;
      else if (FIFO_empty) begin
         entries <= 5'b0;
      end else if (wr_rqst) entries <= entries + 1;
   end
  //----------------------------------------------------------------------------------------------------------------//
   assign conf_data = !dis_data_trf_conf ? conf_data_fifo : 32'b0;
  //----------------------------------------------------------------------------------------------------------------//
   /////////////////////////////////////////////////////////////////////////////
   //  Detect start_of_config and end_of_config-pattern
   //  "STRTCONFPCIe" and "END_CONF_PCIe"
   /////////////////////////////////////////////////////////////////////////////
   always @(posedge trn_clk or negedge trn_reset_n) begin
      if (!trn_reset_n) begin
         soc_1_fd <= 1'b0;
         soc_1_fd_1dly <= 1'b0;
         soc_1_fd_2dly <= 1'b0;
         soc_2_fd <= 1'b0;
         soc_2_fd_1dly <= 1'b0;
         soc_3_fd <= 1'b0;
      end else if (wr_rqst) begin
         soc_1_fd <= 1'b0;
         if (wr_data == SOC_1) soc_1_fd <= 1'b1;
         soc_1_fd_1dly <= soc_1_fd;
         soc_1_fd_2dly <= soc_1_fd_1dly;

         soc_2_fd <= 1'b0;
         if (wr_data == WOC_2) soc_2_fd <= 1'b1;
         soc_2_fd_1dly <= soc_2_fd;

         soc_3_fd <= 1'b0;
         if (wr_data == WOC_3) soc_3_fd <= 1'b1;
      end
   end
  //----------------------------------------------------------------------------------------------------------------//
   always @(posedge conf_clk) begin
      if (FIFO_rd_en_prev == 1'b1) begin
         eoc_2_fd <= 1'b0;
         if (conf_data_fifo == WOC_2) eoc_2_fd <= 1'b1;
         eoc_2_fd_1dly <= eoc_2_fd;

         eoc_3_fd <= 1'b0;
         if (conf_data_fifo == WOC_3) eoc_3_fd <= 1'b1;

         eoc_1_fd <= 1'b0;
         if (conf_data_fifo == EOC_1) eoc_1_fd <= 1'b1;
         eoc_1_fd_1dly <= eoc_1_fd;
         eoc_1_fd_2dly <= eoc_1_fd_1dly;
      end
   end
  //----------------------------------------------------------------------------------------------------------------//
   always @(posedge trn_clk or negedge trn_reset_n) begin
      if (!trn_reset_n) begin
         end_config <= 1'b0;
         start_config <= 1'b0;
      end else begin
         if (soc_1_fd_2dly && soc_2_fd_1dly && soc_3_fd) start_config <= 1'b1;
         else if (end_config) start_config <= 1'b0;

         if (eoc_1_fd_2dly && eoc_2_fd_1dly && eoc_3_fd) end_config <= 1'b1;
         if (!start_config) end_config <= 1'b0;
      end
   end
  //----------------------------------------------------------------------------------------------------------------//
   /////////////////////////////////////////////////////////////////////////////
   // Signal the completion of the configuration to reconfigurable module
   /////////////////////////////////////////////////////////////////////////////
  //----------------------------------------------------------------------------------------------------------------//
   always @(posedge trn_clk or negedge trn_reset_n) begin
      if (!trn_reset_n) pr_done_c <= 1'b0;
      else if (end_config) pr_done_c <= 1'b1;
   end
  //----------------------------------------------------------------------------------------------------------------//
   assign pr_done = pr_done_c;
  //----------------------------------------------------------------------------------------------------------------//
   /////////////////////////////////////////////////////////////////////////////
   // Back-pressure of the FIFO, request to stop FIFO-writing
   /////////////////////////////////////////////////////////////////////////////
  //----------------------------------------------------------------------------------------------------------------//
   always @(posedge trn_clk or negedge trn_reset_n) begin
      if (!trn_reset_n) pause <= 1'b0;
      else if (FIFO_prog_full) pause <= 1'b1;
      else pause <= 1'b0;
   end
  //----------------------------------------------------------------------------------------------------------------//
   /////////////////////////////////////////////////////////////////////////////
   // Interface to ICAP_ACC
   /////////////////////////////////////////////////////////////////////////////
  //----------------------------------------------------------------------------------------------------------------//
   always @(posedge conf_clk) begin
      FIFO_rd_en_prev <= FIFO_rd_en;
      conf_enable <= FIFO_rd_en;
   end
  //----------------------------------------------------------------------------------------------------------------//
   always @(FIFO_empty) begin
      if (!FIFO_empty) FIFO_rd_en <= 1'b1;
      else FIFO_rd_en <=  1'b0;
   end
  //----------------------------------------------------------------------------------------------------------------//
endmodule
