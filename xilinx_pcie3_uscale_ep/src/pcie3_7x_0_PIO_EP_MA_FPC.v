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
// File       : pcie3_7x_0_PIO_EP_MA_FPC.v
// Version    : 4.2
//-----------------------------------------------------------------------------
//
// Project    : Virtex-7 FPGA Gen3 Integrated Block for PCI Express
// File       : pcie3_7x_0_PIO_EP_MA_FPC.v
// Version    : 1.4
//

`timescale 1ps/1ps

module pcie3_7x_0_PIO_EP_MA_FPC #(
  parameter TCQ = 1
  )(
  input                user_clk,
  input                reset_n,

  //  Read Port
  input      [10:0]    rd_addr,
  input      [3:0]     rd_be,
  input                trn_sent,
  output     [31:0]    rd_data,

  //  Write Port
  input      [10:0]    wr_addr,
  input      [7:0]     wr_be,
  input      [63:0]    wr_data,
  input                wr_en,
  output               wr_busy,

  // Payload info
  input                payload_len
  );

  localparam PIO_MEM_ACCESS_WR_RST     = 3'b000;
  localparam PIO_MEM_ACCESS_WR_WAIT    = 3'b001;
  localparam PIO_MEM_ACCESS_WR_READ    = 3'b010;
  localparam PIO_MEM_ACCESS_WR_WRITE   = 3'b100;

  localparam PIO_MRD_TR_GEN_REG = 11'h3AA;
  localparam PIO_INTR_GEN_REG   = 11'h3BB;

  reg   [31:0]     rd_data_raw_o;

  reg   [1:0]      dword_count;
  reg   [10:0]     wr_addr_inc;

  wire  [31:0]     rd_data0_o, rd_data1_o, rd_data2_o, rd_data3_o;

  reg              write_en;
  reg   [31:0]     post_wr_data;
  reg   [31:0]     w_pre_wr_data;

  reg   [2:0]      wr_mem_state;

  reg   [31:0]     pre_wr_data;
  wire  [31:0]     w_pre_wr_data0;
  wire  [31:0]     w_pre_wr_data1;
  wire  [31:0]     w_pre_wr_data2;
  wire  [31:0]     w_pre_wr_data3;

  // Memory Write Process
  wire  [7:0]      w_pre_wr_data_b3 = pre_wr_data[31:24];
  wire  [7:0]      w_pre_wr_data_b2 = pre_wr_data[23:16];
  wire  [7:0]      w_pre_wr_data_b1 = pre_wr_data[15:08];
  wire  [7:0]      w_pre_wr_data_b0 = pre_wr_data[07:00];

  wire  [7:0]      w_wr_data_b3;
  wire  [7:0]      w_wr_data_b2;
  wire  [7:0]      w_wr_data_b1;
  wire  [7:0]      w_wr_data_b0;

  wire  [3:0]      w_wr_be;

  assign w_wr_data_b3 = (dword_count == 0)? wr_data[31:24] : wr_data[63:56];
  assign w_wr_data_b2 = (dword_count == 0)? wr_data[23:16] : wr_data[55:48];
  assign w_wr_data_b1 = (dword_count == 0)? wr_data[15:08] : wr_data[47:40];
  assign w_wr_data_b0 = (dword_count == 0)? wr_data[07:00] : wr_data[39:32];

  assign w_wr_be = (dword_count == 0)? wr_be[3:0] : wr_be[7:4];

  always @(posedge user_clk ) begin

      if ( !reset_n ) begin

        pre_wr_data  <= #TCQ 32'b0;
        post_wr_data <= #TCQ 32'b0;
        write_en     <= #TCQ 1'b0;

        wr_mem_state <= #TCQ PIO_MEM_ACCESS_WR_RST;

        dword_count <= #TCQ 2'b00;
        wr_addr_inc <= #TCQ 11'b0;

      end else begin

      if(dword_count <= payload_len) begin

        if(dword_count == 0)
          wr_addr_inc    <= #TCQ wr_addr;
        else if (dword_count == 1)
          wr_addr_inc <= #TCQ wr_addr + 1'b1; // One Dword Increment

        case ( wr_mem_state )

          PIO_MEM_ACCESS_WR_RST : begin

            if (wr_en) begin // read state

              wr_mem_state <= #TCQ PIO_MEM_ACCESS_WR_WAIT; //Pipelining happens in RAM's internal output reg.

            end else begin

              write_en <= #TCQ 1'b0;

              wr_mem_state <= #TCQ PIO_MEM_ACCESS_WR_RST;

            end

          end

          PIO_MEM_ACCESS_WR_WAIT : begin


             //Pipeline B port data before processing. Virtex 5 Block RAMs have internal
             //  output register enabled.

            write_en <= #TCQ 1'b0;

            wr_mem_state <= #TCQ PIO_MEM_ACCESS_WR_READ ;

          end

          PIO_MEM_ACCESS_WR_READ : begin


              // Now save the selected BRAM B port data out


              pre_wr_data <= #TCQ w_pre_wr_data;
              write_en <= #TCQ 1'b0;

              wr_mem_state <= #TCQ PIO_MEM_ACCESS_WR_WRITE;

          end

          PIO_MEM_ACCESS_WR_WRITE : begin


            //Merge new enabled data and write target BlockRAM location


            post_wr_data <= #TCQ {{w_wr_be[3] ? w_wr_data_b3 : w_pre_wr_data_b3},
                                  {w_wr_be[2] ? w_wr_data_b2 : w_pre_wr_data_b2},
                                  {w_wr_be[1] ? w_wr_data_b1 : w_pre_wr_data_b1},
                                  {w_wr_be[0] ? w_wr_data_b0 : w_pre_wr_data_b0}};
            write_en     <= #TCQ 1'b1;

            wr_mem_state <= #TCQ PIO_MEM_ACCESS_WR_RST;
             
            if (payload_len == 0)
              dword_count <=#TCQ 1'b0;
            else
              dword_count <=#TCQ dword_count + 1'b1;

          end

        endcase

      end

      else write_en  <= #TCQ 1'b0;

      end

  end

  // Write controller busy
    assign wr_busy = wr_en | (wr_mem_state != PIO_MEM_ACCESS_WR_RST) ;

  //  Select BlockRAM output based on higher 2 address bits
  always @* 
   begin
    case ({wr_addr[10:9]}) // synthesis parallel_case full_case
      2'b00 : w_pre_wr_data = w_pre_wr_data0;
      2'b01 : w_pre_wr_data = w_pre_wr_data1;
      2'b10 : w_pre_wr_data = w_pre_wr_data2;
      2'b11 : w_pre_wr_data = w_pre_wr_data3;
    endcase
  end

  //  Memory Read Controller
  wire        rd_data0_en = {rd_addr[10:9]  == 2'b00};
  wire        rd_data1_en = {rd_addr[10:9]  == 2'b01};
  wire        rd_data2_en = {rd_addr[10:9]  == 2'b10};
  wire        rd_data3_en = {rd_addr[10:9]  == 2'b11};

  always @(rd_addr or rd_data0_o or rd_data1_o or rd_data2_o or rd_data3_o)
    begin
    case ({rd_addr[10:9]}) // synthesis parallel_case full_case
      2'b00 : rd_data_raw_o = rd_data0_o;
      2'b01 : rd_data_raw_o = rd_data1_o;
      2'b10 : rd_data_raw_o = rd_data2_o;
      2'b11 : rd_data_raw_o = rd_data3_o;
    endcase
  end

  // Handle Read byte enables
    assign rd_data = {{rd_be[3] ? rd_data_raw_o[31:24] : 8'h0},
                      {rd_be[2] ? rd_data_raw_o[23:16] : 8'h0},
                      {rd_be[1] ? rd_data_raw_o[15:08] : 8'h0},
                      {rd_be[0] ? rd_data_raw_o[07:00] : 8'h0}};

  // Instead of writing to EP_MEM, control signals go out to data_transfer block
  // Tie off the signals that would have been driven by the EP_MEM and are now undriven

    assign rd_data0_o = 32'h0;
    assign rd_data1_o = 32'h0;
    assign rd_data2_o = 32'h0;
    assign rd_data3_o = 32'h0;
    assign w_pre_wr_data0 = 32'h0;
    assign w_pre_wr_data1 = 32'h0;
    assign w_pre_wr_data2 = 32'h0;
    assign w_pre_wr_data3 = 32'h0;

  // synthesis translate_off
  reg  [8*20:1] state_ascii;
  always @(wr_mem_state)
  begin
    case (wr_mem_state)
      PIO_MEM_ACCESS_WR_RST     : state_ascii <= #TCQ "PIO_MEM_WR_RST";
      PIO_MEM_ACCESS_WR_WAIT    : state_ascii <= #TCQ "PIO_MEM_WR_WAIT";
      PIO_MEM_ACCESS_WR_READ    : state_ascii <= #TCQ "PIO_MEM_WR_READ";
      PIO_MEM_ACCESS_WR_WRITE   : state_ascii <= #TCQ "PIO_MEM_WR_WRITE";
      default                   : state_ascii <= #TCQ "PIO MEM STATE ERR";
    endcase
  end
  // synthesis translate_on

endmodule

