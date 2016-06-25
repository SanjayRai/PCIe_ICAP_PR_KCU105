# Variables
device="0"
device=$1

#==================================================================================

# Check to see if Device is valid
# Set the stage2BinFile name
if [ "$device" == "325" ] 
then
 :
elif [ "$device" == "485" ]
then
 :
elif [ "$device" == "690" ]
then
 :
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

if [ "$device" == "us" ] || [ "$device" == "US" ]
then
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

  cd ../..
fi

#==================================================================================

# Print feel good message if everything worked as expected
echo "Info: Stage1 Testing Completed Successfully."


