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
## File       : pcie3_ultrascale_0_tandem.xdc
## Version    : 4.2 
##-----------------------------------------------------------------------------
#
###############################################################################
# Enable Tandem PCIE Bitstream Generation 
###############################################################################
# Uncomment the following two constraints to generate Tandem PCIe Bitstreams. 
# Without these constraints Tandem PROM bitstreams will be generated.
#set_property HD.OVERRIDE_PERSIST FALSE [current_design]
#set_property HD.TANDEM_BITSTREAMS Separate [current_design]

###############################################################################
# Tandem Pblocks for the Example Design:
# All Stage1 primitives must be in a PBlock that is aligned to a Programmable
# Unit boundary. This PBlock must have exclude placement to prevent other 
# primitives from being included in the region boundary.
###############################################################################
## Since required logic was generated external to the IP this logic must be
## added to the main pblock that was created by the IP Solution.
## Get the additional Share Logic primitives
set sharedLogicCells [get_cells -hierarchical -filter { \
              NAME =~ pcie3_ultrascale_0_support_i* && \
              IS_PRIMITIVE && \
              PRIMITIVE_TYPE != OTHERS.others.GND && \
              PRIMITIVE_TYPE != OTHERS.others.VCC && \
              PRIMITIVE_TYPE !~ CONFIGURATION.*.* }]
## Assign the primitives to the Stage1_Main pblock 
set_property HD.TANDEM_IP_PBLOCK Stage1_Main $sharedLogicCells
set_property HD.TANDEM_IP_PBLOCK Stage1_Main [get_cells -hierarchical -filter {NAME =~ *u_vio_x8*}]
set_property HD.TANDEM_IP_PBLOCK Stage1_Main [get_cells -hierarchical -filter {NAME =~ *dbg_hub*}]
## Get the additional Share Logic primitives
set startupCell [get_cells pcie3_ultrascale_0_support_i/startup_i]
## Assign the primitives to the Stage1_Main pblock 
set_property HD.TANDEM_IP_PBLOCK Stage1_Main $startupCell

## Since the reset pin is within the config IO Bank, add the Reset IOB to the
## config IO Bank pblock that is already created by the solution IP
set_property HD.TANDEM_IP_PBLOCK Stage1_Config_IO [get_cells sys_reset_n_ibuf]

## Since the refclk is within the range of the main pblock, add the refclk IBUF 
## and its BUFG_GT to the main pblock.
set_property HD.TANDEM_IP_PBLOCK Stage1_Main [get_cells refclk_ibuf]

###############################################################################
# The following constraints can be used to demonstrate Tandem with 
# Field-Updates. For this example the user_application will be setup
# for field updates. The required steps are below to enable this.
###############################################################################
## Store the sites for existing stage1 pblocks so that they can be removed 
## from the Update Region Pblock.
set existingStage1Sites [get_sites -of_objects [get_pblocks -filter { \
    NAME =~ *_pcie3_ultrascale_0_Stage1_main || \
    NAME =~ *_Stage1_cfgiob \
}]]

## Set the module as reconfigurable
set_property HD.RECONFIGURABLE 1 [get_cells pcie_app_uscale_i]
## Create the Update Region PBlock
set updatePblock [create_pblock -quiet update_region]
## Add the reconfigurable module to the update region pblock
add_cells_to_pblock -quiet $updatePblock [get_cells pcie_app_uscale_i]
## Resize the Update Region PBlock to include the entire device (excluding
## configuration sites that are not reconfigurable).
# resize_pblock -quiet $updatePblock -add {SLICE_X0Y0:SLICE_X139Y479 \
#                                   DSP48E2_X0Y0:DSP48E2_X3Y191 \
#                                   RAMB18_X0Y0:RAMB18_X17Y191 \
#                                   RAMB36_X0Y0:RAMB36_X17Y95 \
#                                   GTHE3_CHANNEL_X0Y0:GTHE3_CHANNEL_X0Y31 \
#                                   GTHE3_COMMON_X0Y0:GTHE3_COMMON_X0Y7 \
#                                   PCIE_3_1_X0Y0:PCIE_3_1_X0Y3 \
#                                   MMCME3_ADV_X0Y0:MMCME3_ADV_X1Y7 \
#                                   PLLE3_ADV_X0Y0:PLLE3_ADV_X1Y15 \
#                                   RIU_OR_X0Y0:RIU_OR_X1Y31 \
#                                   PLL_SELECT_SITE_X0Y0:PLL_SELECT_SITE_X1Y63 \
#                                   BITSLICE_CONTROL_X0Y0:BITSLICE_CONTROL_X1Y63 \
#                                   BITSLICE_TX_X0Y0:BITSLICE_TX_X1Y63 \
#                                   BITSLICE_RX_TX_X0Y0:BITSLICE_RX_TX_X1Y415 \
#                                   IOB_X0Y0:IOB_X1Y415 \
#                                   XIPHY_FEEDTHROUGH_X0Y0:XIPHY_FEEDTHROUGH_X7Y7 \
#                                   SYSMONE1_X0Y0 \
#                                   ILKN_SITE_X0Y0:ILKN_SITE_X1Y4 \
#                                   CMAC_SITE_X0Y0:CMAC_SITE_X0Y3 \
#                                   GTYE3_CHANNEL_X0Y0:GTYE3_CHANNEL_X0Y31 \
#                                   GTYE3_COMMON_X0Y0:GTYE3_COMMON_X0Y7 \
# }

resize_pblock -quiet $updatePblock -add {CLOCKREGION_X0Y2:CLOCKREGION_X3Y4 CLOCKREGION_X0Y1:CLOCKREGION_X1Y1 CLOCKREGION_X0Y0:CLOCKREGION_X2Y0}
## Resize the Update PBlock to remove sites already associated with Stage1
resize_pblock -quiet $updatePblock -remove $existingStage1Sites

## Increase the partition pin density near the PCIe core. This is done to improve timing
## accross the PR boundary. If the design is unable to place partition pins and/or route 
## the design due to congestion, this number should be decreased.
set_property PARTPIN_SPREADING 8 [get_pblocks update_region]
add_cells_to_pblock pcie3_ultrascale_0_support_i_pcie3_ultrascale_0_i_inst_pcie3_ultrascale_0_Stage1_main [get_cells [list dbg_hub]] -clear_locs
add_cells_to_pblock pcie3_ultrascale_0_support_i_pcie3_ultrascale_0_i_inst_pcie3_ultrascale_0_Stage1_main [get_cells [list u_vio_x8]] -clear_locs
add_cells_to_pblock pcie3_ultrascale_0_support_i_pcie3_ultrascale_0_i_inst_pcie3_ultrascale_0_Stage1_main [get_cells [list pcie3_ultrascale_0_support_i]] -clear_locs
## Set the Part Pin Range to improve the placement of the RM Partition Pins.
#set_property HD.PARTPIN_RANGE {SLICE_X40Y0:SLICE_X48Y119} [get_pins -of_objects [get_cells pcie_app_uscale_i]]
set_property HD.PARTPIN_RANGE {SLICE_X64Y0:SLICE_X75Y59} [get_pins -of_objects [get_cells pcie_app_uscale_i]]
#resize_pblock pcie3_ultrascale_0_support_i_pcie3_ultrascale_0_i_inst_pcie3_ultrascale_0_Stage1_main -add {BUFGCE_X1Y24:BUFGCE_X1Y25}
#set_property BEL BUFCE [get_cells dbg_hub/inst/N_EXT_BSCAN.u_bufg_icon]
#set_property LOC BUFGCE_X1Y24 [get_cells dbg_hub/inst/N_EXT_BSCAN.u_bufg_icon]
#set_property BEL BUFCE [get_cells dbg_hub/inst/N_EXT_BSCAN.u_bufg_icon_update]
#set_property LOC BUFGCE_X1Y25 [get_cells dbg_hub/inst/N_EXT_BSCAN.u_bufg_icon_update]
