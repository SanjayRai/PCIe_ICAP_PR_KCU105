Xilinx Fast PCIe Configuration (FPC) Example Driver and Application

Customizing:
The driver and application both utilize settings found in the common/ area. To modify design constants, please edit files in that location.


**************************************
* Linux Kernel Module Driver         *
* (see linux_driver directory)       *
**************************************

To Clean:
make clean

To Build:
make

To Use:
sudo insmod xilinx_pci_fpc_main.ko


**************************************
* FPC Test Application               *
* (see linux_test_app directory)     *
**************************************

To Clean:
make clean

To Build:
make

To Run Application:
./test_fpc [file=<file_to_send>]
If no file is specified, the default file name fpc_demo.bin will be used.

enable_ICAP / disable_ICAP
are basch scripts to enable and disable the ICAP access by settign the MCAP Extended register space (0x354).


Basic process:
1. To wtite a Partial reconfig bit file
    a. enable_ICAP
    b. ./test_fpc file=<name_of_partial_A_bit_file>
    c. disable_ICAP 
2. To wtite another Partial reconfig bit file after _partial_A_bit_file
    a. enable_ICAP
    b. ./test_fpc file=<name_of_partial_A_clear_bit_file>
    b. ./test_fpc file=<name_of_partial_B_bit_file>
    c. disable_ICAP 
