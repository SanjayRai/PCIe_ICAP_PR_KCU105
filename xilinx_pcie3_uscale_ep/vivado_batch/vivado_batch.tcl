# Created : 9:31:38, Tue Jun 21, 2016 : Sanjay Rai

source ../device_type.tcl


set TOP_module xilinx_pcie3_uscale_ep

create_project -in_memory -part [DEVICE_TYPE] 

read_ip {
../IP/ila_ICAP/ila_ICAP.xci
../IP/vio_x8/vio_x8.xci
../IP/pcie3_7x_0_fastConfigFIFO/pcie3_7x_0_fastConfigFIFO.xci
../IP/pcie3_ultrascale_0/pcie3_ultrascale_0.xci
}

read_verilog {
../src/pcie3_7x_0_PIO_EP_FPC.v
../src/pcie3_7x_0_PIO_EP_MA_FPC.v
../src/pcie3_7x_0_PIO_FPC.v
../src/pcie3_7x_0_PIO_RX_ENG_FPC.v
../src/pcie3_7x_0_PIO_TO_CTRL_FPC.v
../src/pcie3_7x_0_PIO_TX_ENG_FPC.v
../src/pcie3_7x_0_data_transfer.v
../src/pcie3_7x_0_icap_access.v
../src/pcie3_7x_0_pr_loader.v
../src/pcie3_7x_0_tandem_cpler_ctl_arb.v
../src/pcie_interface_multiplexer.v
../src/example_design/ep_mem.v
../src/example_design/pcie_app_uscale.v
../src/example_design/pio.v
../src/example_design/pio_ep.v
../src/example_design/pio_ep_mem_access.v
../src/example_design/pio_intr_ctrl.v
../src/example_design/pio_rx_engine.v
../src/example_design/pio_to_ctrl.v
../src/example_design/pio_tx_engine.v
../src/example_design/support/pcie3_ultrascale_0_support.v
../src/example_design/xilinx_pcie_uscale_ep.v
}

read_xdc {
../src/xdc/xilinx_pcie3_uscale_ep_x8g3.xdc
../src/xdc/pcie3_ultrascale_0_tandem.xdc
}

synth_design -top $TOP_module -part [DEVICE_TYPE] 
opt_design -verbose -directive Explore
write_checkpoint -force $TOP_module.post_synth_opt.dcp
if (1) {
place_design -verbose -directive Explore
write_checkpoint -force $TOP_module.post_place.dcp
phys_opt_design  -verbose -directive Explore
write_checkpoint -force $TOP_module.post_place_phys_opt.dcp
set_property HD.NO_ROUTE_CONTAINMENT 1 [get_nets pcie3_ultrascale_0_support_i/icap_clk]
route_design  -verbose -directive Explore
write_checkpoint -force $TOP_module.post_route.dcp
phys_opt_design  -verbose -directive Explore
write_checkpoint -force $TOP_module.post_route_phys_opt.dcp
report_timing_summary -file $TOP_module.timing_summary.rpt
report_drc -file $TOP_module.drc.rpt
set_property config_mode SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
write_bitstream -bin_file $TOP_module.bit      
# Write the Debug Probes
write_debug_probes -force ${TOP_module}.ltx
# __SRAI   # Write Tandem PCIe bitstreams
# __SRAI   set_property HD.OVERRIDE_PERSIST False [current_design]
# __SRAI   set_property HD.TANDEM_BITSTREAMS Separate [current_design]
# __SRAI   write_bitstream -force -bin_file -file ${TOP_module}_tpcie.bit
# __SRAI   # Write Tandem PROM bitstreams
# __SRAI   set_property HD.OVERRIDE_PERSIST True [current_design]
# __SRAI   set_property HD.TANDEM_BITSTREAMS Combined [current_design]
# __SRAI   write_bitstream -force -bin_file -file ${TOP_module}_tprom.bit
}
