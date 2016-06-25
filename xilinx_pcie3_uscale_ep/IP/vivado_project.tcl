# Created : 9:31:38, Tue Jun 21, 2016 : Sanjay Rai

source ../device_type.tcl
create_project project_X project_X -part [DEVICE_TYPE] 

add_files -fileset sources_1 -norecurse {
../IP/ila_ICAP/ila_ICAP.xci
../IP/vio_x8/vio_x8.xci
../IP/pcie3_7x_0_fastConfigFIFO/pcie3_7x_0_fastConfigFIFO.xci
../IP/pcie3_ultrascale_0/pcie3_ultrascale_0.xci
}

