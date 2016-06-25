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
// File       : pcie3_ultrascale_0_design_switch.v
// Version    : 4.2 
//-----------------------------------------------------------------------------
//--
//-- Description: This logic uses the EOS pin of the STARUP primitive to detect
//--              when the stage2 logic has completed configuration.
//--
//--              When the stage2 logic has been completed design_switch
//--              will assert.
//--              The clock is used for the clock domain crossing registers
//--              and to generate the reset_pulse prior to design_switch assertion.
//--              The reset (active high) will cause the design_switch signal
//--              to de-assert and wait for a stage2 bitstream; at which point
//--              design_switch will again become asserted. This will also trigger
//--              the reset_pulse to be asserted again.
//--              the reset_pulse will be 0 until, then high for 4 clock cylces,
//--              then low prior to the assertion of the design_switch.
//--
//------------------------------------------------------------------------------
`timescale 1ps/1ps

module pcie3_ultrascale_0_design_switch #(
  parameter MCAP_ENABLEMENT  = "NONE",   // Values (TANDEM, TANDEM_FIELD_UPDATE, PR, NONE) Tandem modes add a register to detect the start of stage2 loading
  parameter TCQ              = 1
) (
  // Tandem Stage2 Detect Interface
  input            clk,                // Clock for design_switch and reset_pulse synchronization
  input            rst,                // Reset (active-high) deasserts design_switch, it will assert after another bitstream is loaded
  input            startup_eos_in,     // 1-bit input: This signal should be driven by the EOS output of the STARTUP primitive.
  output wire      reset_pulse,        // Pulse to generate a rising and falling reset edge prior to design_switch assertion.
  output wire      design_switch       // Asserts when stage2 has been fully programmed 
);

// Wire declarations
// stage2_start reg must have a zero initialization value to prevent optimization of this logic
reg stage2_start_reg = 1'b0;
(* dont_touch = "TRUE" *) 
wire stage2_start;
reg stage2_end = 1'b0;
// Clock Domain Crossing registers should be marked as ASYNC_REG to prevent optimizations and
// encourage desirable floor planning
(* ASYNC_REG = "TRUE" *)
reg cdc_reg1 = 1'b0;
(* ASYNC_REG = "TRUE" *)
reg cdc_reg2 = 1'b0;
(* ASYNC_REG = "TRUE" *)
reg cdc_reg3 = 1'b0;
(* ASYNC_REG = "TRUE" *)
reg cdc_reg4 = 1'b0;
reg [7:0] design_switch_delay = 1'b0;
reg reset_pulse_reg = 1'b0;

  generate if (MCAP_ENABLEMENT == "TANDEM" || MCAP_ENABLEMENT == "TANDEM_FIELD_UPDATE") 
    begin
      // Start of stage2 detect register w/o Reset:
      // This register does not have a reset because the reset
      // for this design happens after eos has alredy dropped
      // low for a second configuration.
      always @ (negedge startup_eos_in ) begin
        stage2_start_reg <= #TCQ 1'b1;
      end
      assign stage2_start = stage2_start_reg;
    end 
  else 
    begin
      // Since Tandem is not enabled we do not need to detect the start of stage2 loading
      // Tie this signal to logic 1.
      assign stage2_start = 1'b1;
    end
  endgenerate

  // End of stage2 detect register w/ Axync Reset:
  // Register is driven 1 at the rising edge of eos (after
  // stage2_start is asserted) which marks the end of the
  // stage2 bitstream.
  always @ (posedge startup_eos_in or posedge rst) begin
    if (rst) begin
      stage2_end <= #TCQ 1'b0;
    end else begin
      stage2_end <= #TCQ (stage2_start || stage2_end);
    end
  end

  // Clock Domain Crossing registers w/ Sync Reset
  always @ (posedge clk) begin
    if (rst) begin
      cdc_reg1 <= #TCQ 1'b0;
      cdc_reg2 <= #TCQ 1'b0;
      cdc_reg3 <= #TCQ 1'b0;
      cdc_reg4 <= #TCQ 1'b0;
    end else begin
      cdc_reg1 <= stage2_end;
      cdc_reg2 <= cdc_reg1;
      cdc_reg3 <= cdc_reg2;
      cdc_reg4 <= cdc_reg3;
    end
  end

  // Generate a reset pulse prior to the design_switch assertion
  always @ (posedge clk) begin
    if (rst) begin
      design_switch_delay <= #TCQ 1'b0;
      reset_pulse_reg <= #TCQ 1'b0;
    end else begin
      design_switch_delay <= {design_switch_delay[6:0], cdc_reg4};
      reset_pulse_reg <= cdc_reg4 & (~design_switch_delay[3]);
    end
  end  

  // assign the output
  assign design_switch = design_switch_delay[7];
  assign reset_pulse = reset_pulse_reg;

endmodule
