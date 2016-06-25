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
// File       : pcie3_7x_0_icap_access.v
// Version    : 4.2
//-----------------------------------------------------------------------------
//
// Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
// File       : pcie3_7x_0_icap_access.v
// Version    : 1.4
//
//---------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 1ns / 1ns
//---------------------------------------------------------------------------------------------------------------------------------------------//
module pcie3_7x_0_ICAP_access (
    input              CONF_CLK,
    input              reset_n,
    // signaling from and to DAT_TRF
    input [31:0]       CONF_DATA,
    input              CONF_ENABLE,
    output reg         ICAP_ceb,
    output reg         ICAP_wrb,
    output wire [31:0] ICAP_din_bs       // bitswapped version of ICAP_din
);
  //----------------------------------------------------------------------------------------------------------------//
  // Signals directly at ICAP-module:
   reg [31:0]          ICAP_din;
  //----------------------------------------------------------------------------------------------------------------//
  // Accesses to the ICAP-module
  //----------------------------------------------------------------------------------------------------------------//
    always @(posedge CONF_CLK or negedge reset_n)
        if (!reset_n) begin
            ICAP_din <= 32'b0;
            ICAP_ceb <= 1'b1;
            ICAP_wrb <= 1'b1;
        end else begin
            ICAP_din <= CONF_DATA;

            ICAP_ceb <= ~CONF_ENABLE;
            ICAP_wrb <= 1'b0;
        end
  //----------------------------------------------------------------------------------------------------------------//
  // reverse the bits within each byte
  // generate assign statements for each bit
  //----------------------------------------------------------------------------------------------------------------//
   generate
      begin : xhdl0
         genvar j;
         for (j=0; j<=3; j=j+1) begin : mirror_j
            genvar i;
            for (i=0; i<=7; i=i+1) begin : mirror_i
               assign ICAP_din_bs[j * 8 + i] = ICAP_din[j * 8 + 7 - i];
            end
         end
      end
   endgenerate
  //----------------------------------------------------------------------------------------------------------------//
endmodule
