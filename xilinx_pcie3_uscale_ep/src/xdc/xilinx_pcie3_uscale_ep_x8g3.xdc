##-----------------------------------------------------------------------------
##
## (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##-----------------------------------------------------------------------------
##
## Project    : Ultrascale FPGA Gen3 Integrated Block for PCI Express
## File       : xilinx_pcie3_uscale_ep_x8g3.xdc
## Version    : 4.2
##-----------------------------------------------------------------------------
#
# User Configuration
# Link Width   - x8
# Link Speed   - Gen3
# Family       - virtexu
# Part         - xcvu095
# Package      - ffva2104
# Speed grade  - -2
# PCIe Block   - X0Y0
###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]

set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]



set_false_path -from [get_ports sys_rst_n]



## Since the Startup.EOS pin drives register clock pins it must be declaired a clock.
create_clock -period 1000.000 -name startupEosClk [get_pins pcie3_ultrascale_0_support_i/startup_i/EOS]
## Make the clock asynchronous
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins pcie3_ultrascale_0_support_i/startup_i/EOS]]


###############################################################################
# User Physical Constraints
###############################################################################

###############################################################################
# Pinout and Related I/O Constraints
###############################################################################
##### SYS RESET###########
set_property LOC PCIE_3_1_X0Y0 [get_cells pcie3_ultrascale_0_support_i/pcie3_ultrascale_0_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst]
set_property PACKAGE_PIN K22 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]

##### REFCLK_IBUF###########
set_property LOC GTHE3_COMMON_X0Y1 [get_cells refclk_ibuf]

##### LED OBUF LOC ###########
#  __SRAI set_property PACKAGE_PIN AP8 [get_ports {led_out[0]}]
#  __SRAI set_property PACKAGE_PIN H23 [get_ports {led_out[1]}]
#  __SRAI set_property PACKAGE_PIN P20 [get_ports {led_out[2]}]
#  __SRAI set_property PACKAGE_PIN P21 [get_ports {led_out[3]}]
#  __SRAI set_property PACKAGE_PIN N22 [get_ports {led_out[4]}]
#  __SRAI set_property PACKAGE_PIN M22 [get_ports {led_out[5]}]
#  __SRAI set_property PACKAGE_PIN R23 [get_ports {led_out[6]}]
#  __SRAI set_property PACKAGE_PIN P23 [get_ports {led_out[7]}]
#  __SRAI 
#  __SRAI set_property IOSTANDARD LVCMOS18 [get_ports {led_out[0]}]
#  __SRAI set_property IOSTANDARD LVCMOS18 [get_ports {led_out[1]}]
#  __SRAI set_property IOSTANDARD LVCMOS18 [get_ports {led_out[2]}]
#  __SRAI set_property IOSTANDARD LVCMOS18 [get_ports {led_out[3]}]
#  __SRAI set_property IOSTANDARD LVCMOS18 [get_ports {led_out[4]}]
#  __SRAI set_property IOSTANDARD LVCMOS18 [get_ports {led_out[5]}]
#  __SRAI set_property IOSTANDARD LVCMOS18 [get_ports {led_out[6]}]
#  __SRAI set_property IOSTANDARD LVCMOS18 [get_ports {led_out[7]}]

# flash settings
#set_property CONFIG_MODE BPI16 [current_design]
#set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type1 [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE 9 [current_design]
#set_property CONFIG_VOLTAGE 1.8 [current_design]
#set_property CFGBVS GND [current_design]

###############################################################################
# Flash Programming Settings: Uncomment as required by your design
# Items below between < > must be updated with correct values to work properly.
###############################################################################
# BPI Flash Programming
#set_property CONFIG_MODE <BPI8 | BPI16> [current_design]
#set_property BITSTREAM.CONFIG.BPI_SYNC_MODE <disable | Type1 | Type2> [current_design]
#set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN <Disable | div-8 | div-4 | div-2 | div-1> [current_design]
#set_property BITSTREAM.CONFIG.UNUSEDPIN <Pulldown | Pullup | Pullnone [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE <3|6|9|12|16|22|26|33|40|50|66> [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS <TRUE | FALSE> [current_design]
#set_property CONFIG_VOLTAGE <voltage> [current_design]
#set_property CFGBVS <GND | VCCO> [current_design]
# Example PROM Generation command that should be executed from the Tcl Console
#write_cfgmem -format mcs -interface bpix16 -size 256 -loadbit "up 0x0 <inputBitfile.bit>" <outputBitfile.mcs>

# SPI Flash Programming
#set_property CONFIG_MODE <SPIx1 | SPIx2 | SPIx4 | SPIx8> [current_design]
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH <NONE | 1 | 2 | 4 | 8> [current_design]
#set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN <Disable | div-48 | div-24 | div-12 | div-8 | div-4 | div-2 | div-1> [current_design]
#set_property BITSTREAM.CONFIG.SPI_FALL_EDGE <NO | YES> [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS <TRUE | FALSE> [current_design]
#set_property CONFIG_VOLTAGE <voltage> [current_design]
#set_property CFGBVS <GND | VCCO> [current_design]
# Example PROM Generation command that should be executed from the Tcl Console
#write_cfgmem -format mcs -interface spix4 -size 256 -loadbit "up 0x0 <inputBitfile.bit>" <outputBitfile.mcs>


