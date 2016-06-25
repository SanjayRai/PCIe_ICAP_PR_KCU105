# Variables
device="0"
device=$1

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
  :
else
  echo "ERROR: Device was not specified. Please specify on the command line."
  echo "       <ScriptName> <Device>"
  echo "       Valid Devices 325, 485, 690, us."  
  exit
fi

#==================================================================================

# Script Start
# Get the PCIe Base Address
pcieLowAddr=`cat /proc/iomem | grep 'PCI Bus 0000:02' | sed 's/[ ]*\([a-z0-9]*\).*/\1/'`
if [ "$pcieLowAddr" == "" ] 
then
  echo "ERROR: PCIe Low Address did not get set. pcieLowAddr(${pcieLowAddr})"
  exit
else 
  echo "Info: PCIe Low Address = ${pcieLowAddr}"
fi

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

if [ "$device" == "us" ] || [ "$device" == "US" ]
then
  # Load MCAP registers Checking Script
  cd Uscale/bash_database
  source header.sh

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

  cd ../..
fi

#==================================================================================

# Print feel good message if everything worked as expected
echo "Info: Stage2 completed successfully."

