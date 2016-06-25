# Variables
device="0"
device=$1
type="bin"
type=$2

#==================================================================================

# Check to see if Device is valid
# Set the stage2BinFile name
if [ "$device" == "325" ] 
then 
  stage2BinFile="xilinx_pcie_2_1_ep_7x_tandem2.bin"
elif [ "$device" == "485" ]
then
  stage2BinFile="xilinx_pcie_2_1_ep_7x_tandem2.bin"
elif [ "$device" == "690" ]
then
  stage2BinFile="xilinx_pcie_3_0_7vx_ep_tandem2.bin"
elif [ "$device" == "us" ] || [ "$device" == "US" ]
then
  stage2BinFile="xilinx_pcie3_uscale_ep_tandem2"
  if [ "$type" == "bin" ]
  then
    stage2BinFile="$stage2BinFile.bin"
  elif [ "$type" == "bit" ]
  then
    stage2BinFile="$stage2BinFile.bit"
  elif [ "$type" == "rbt" ]
  then
    stage2BinFile="$stage2BinFile.rbt"
  else
    echo "ERROR: Type was not specified."
    echo "       For UltraScale devices, please specify Type on the command line."
    echo "       <ScriptName> <Device> <Type>"
    echo "       Valid Type bin, bit, rbt."  
    exit
  fi
else
  echo "ERROR: Device was not specified. Please specify on the command line."
  echo "       <ScriptName> <Device>"
  echo "       Valid Devices 325, 485, 690, us."  
  exit
fi

#==================================================================================

# Common to both 7-series and UltraScale
function st1_test {

  # Get the PCIe Base Address
  pcieLowAddr=`cat /proc/iomem | grep 'PCI Bus 0000:02' | sed 's/[ ]*\([a-z0-9]*\).*/\1/'`
  if [ "$pcieLowAddr" == "" ] 
  then
    echo "ERROR: PCIe Low Address did not get set. pcieLowAddr(${pcieLowAddr})"
    exit
  else 
    echo "Info: PCIe Low Address = ${pcieLowAddr}"
  fi

  # Expected Return Value
  if [ "$device" == "325" ] || [ "$device" == "485" ] || [ "$device" == "690" ]
  then
    # Successful Completion with Payload 0x0
    expectedReturnVal="0x00000000${pcieLowAddr} = 0x00000000"
  elif [ "$device" == "us" ] || [ "$device" == "US" ]
  then
    # Unsupported Request (UR)
    expectedReturnVal="0x00000000${pcieLowAddr} = 0xffffffff"
  else
    echo "ERROR: Something bad has happened in the script!"
    echo "       Check the code"
  fi

  # Attempt to do a stage1 read and verify return value
  returnVal=`./PCIeWriter/rwmem 0x${pcieLowAddr}`
  if [ "$returnVal" != "$expectedReturnVal" ] 
  then
    echo "ERROR: Stage1 PCIe Read(1) before write did not return correctly."
    echo "       Expected: $expectedReturnVal"
    echo "       Actual:   $returnVal"
    echo "       Command: ./PCIeWriter/rwmem 0x${pcieLowAddr}"
    exit
  fi
  # Attempt a stage1 write (it should be ignored)
  ./PCIeWriter/rwmem 0x${pcieLowAddr} 0x00123400
  returnVal=`./PCIeWriter/rwmem 0x${pcieLowAddr}`
  if [ "$returnVal" != "$expectedReturnVal" ] 
  then
    echo "ERROR: Stage1 PCIe Read(2) after write did not return correctly."
    echo "       Expected: $expectedReturnVal"
    echo "       Actual:   $returnVal"
    echo "       Command: ./PCIeWriter/rwmem 0x${pcieLowAddr}"
    exit
  fi
}

function st2_test {

  # Verify we still have a device connected
  returnVal=`lspci -v -d 10ee:* | grep "Memory at"`
  expectedReturnVal="	Memory at f7d00000 (32-bit, non-prefetchable) [size=2K]"
  if [ "$returnVal" != "$expectedReturnVal" ] 
  then
    echo "ERROR: Link was lost during Stage2 load"
    echo "       Expected: $expectedReturnVal"
    echo "       Actual  : $returnVal"
    echo "       Command: lspci -v -d 10ee:* | grep \"Memory at\""
    exit
  fi

  # Perform a stage2 read
  returnVal=`./PCIeWriter/rwmem 0x${pcieLowAddr}`
  echo "Info: PCIe read after stage2 configuration"
  echo "      $returnVal"
  # Perform a stage2 write/read to verify opperation
  ./PCIeWriter/rwmem 0x${pcieLowAddr} 0xdeadbeef
  returnVal=`./PCIeWriter/rwmem 0x${pcieLowAddr}`
  expectedReturnVal="0x00000000${pcieLowAddr} = 0xdeadbeef"
  if [ "$returnVal" != "$expectedReturnVal" ] 
  then
    echo "ERROR: Stage1 PCIe Read did not return correctly."
    echo "       Expected: $expectedReturnVal"
    echo "       Actual:   $returnVal"
    echo "       Command: ./PCIeWriter/rwmem 0x${pcieLowAddr}"
    exit
  fi

}

#==================================================================================

# Script Start For 7-series
if [ "$device" == "325" ] || [ "$device" == "485" ] || [ "$device" == "690" ]
then
  # Test stage1
  st1_test

  # Go to the correct directory, load the driver
  cd tpcie_sw_release/linux_test_app/
  #cd tpcie_sw_release_byte/linux_test_app/
  insmod ../linux_driver/xilinx_pci_fpc_main.ko

  # Copy the stage2 file to the local directory
  echo "Info: copying file ${stage2BinFile} for stage2"
  /bin/cp /run/media/xilinx/201C-5A41/${stage2BinFile} .

  # Load the stage2 file into the FPGA
  echo "Info: loading file ${stage2BinFile} for stage2"
  time ./test_fpc file=${stage2BinFile}

  # Go back to previous directory
  cd ../..

  # Test stage2
  st2_test

  # Remove the driver
  rmmod xilinx_pci_fpc_main

#==================================================================================

# Script Start For UltraScale
elif [ "$device" == "us" ] || [ "$device" == "US" ]
then

  # Test stage1
  st1_test

  # Load MCAP registers Checking Script
  cd Uscale/bash_database
  source header.sh

  # Verify MCAP Design Switch is De-Asserted
  returnVal=`do_check_registers $devID | grep "MCAP Design Switch" | sed 's/.*\([: 0-1]\).*/\1/'`
  expectedReturnVal="0"
  if [ "$returnVal" != "$expectedReturnVal" ] 
  then
    echo "ERROR: MCAP Desigh Switch is Set"
    echo "       Expected: $expectedReturnVal"
    echo "       Actual  : $returnVal"
    echo "       Command: do_check_registers $devID | grep \"MCAP Design Switch\""
    exit
  fi

  # Go to the correct directory
  cd ../../mcap_driver

  # Copy the stage2 file to the local directory
  echo "Info: copying file ${stage2BinFile} for stage2"
  /bin/cp /run/media/xilinx/201C-5A41/${stage2BinFile} .

  # Load the stage2 file into the FPGA
  echo "Info: loading file ${stage2BinFile} for stage2"
  time ./mcap -x 8038 -p ${stage2BinFile}

  # Verify MCAP Design Switch is Asserted
  returnVal=`do_check_registers $devID | grep "MCAP Design Switch" | sed 's/.*\([: 0-1]\).*/\1/'`
  expectedReturnVal="1"
  if [ "$returnVal" != "$expectedReturnVal" ] 
  then
    echo "ERROR: MCAP Desigh Switch is Not Set"
    echo "       Expected: $expectedReturnVal"
    echo "       Actual  : $returnVal"
    echo "       Command: do_check_registers $devID | grep \"MCAP Design Switch\""
    exit
  fi

  # Go back to previous directory
  cd ..

  # Test stage2
  st2_test

#==================================================================================

# Internal Error
else
  echo "ERROR: Something bad has happened in the script!"
  echo "       Check the code"
fi

#==================================================================================

# Common to both 7-series and UltraScale
# Print feel good message if everything worked as expected
echo "Info: Everything completed successfully."

