/**
 * File        - XilinxFpcDevice.cpp
 * Description - See header of ./XilinxFpcDevice.h
 *
 * Copyright (c) 2012, Xilinx
 * All rights reserved.
 */

// Class header
#include "XilinxFpcDevice.h"

// STL headers
#include <iomanip>
#include <iostream>
#include <sstream>

// Standard library headers
#include <errno.h>
#include <fcntl.h>
#include <fstream>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <sys/mman.h>
#include <immintrin.h>
#include <emmintrin.h>



// Linux headers
#include "../linux_driver/xilinx_pci_fpc.h"

// Namespace using directives
using std::cerr;
using std::cout;
using std::dec;
using std::endl;
using std::filebuf;
using std::fstream;
using std::hex;
using std::ifstream;
using std::ios;
using std::list;
using std::make_pair;
using std::map;
using std::setfill;
using std::setw;
using std::string;

// Constant used to make note of an invalid node handle
#define INVALID_NODE_HANDLE (-1)
#define PAGE_SIZE 4096
#define handle_error(msg)  \
    do { perror(msg); exit (EXIT_FAILURE); } while (0)

extern bool burst;
extern uint32_t burst_size;

// Implementation of class XilinxFpcDevice

// Static member initialization

const string XilinxFpcDevice::FpcDeviceRootPrefix = "pci_fpc";

const string XilinxFpcDevice::FpcDeviceNodeBase = "/tmp/pci_fpc";

// Virtual Destructor

XilinxFpcDevice::~XilinxFpcDevice(void) {
}

// Public interface methods

list<XilinxFpcDevice*> XilinxFpcDevice::getInstances(void) {
  list<XilinxFpcDevice*> returnDevices;

  // Dynamically scan for devices in sysfs by class and name
  uint32_t instanceCount = 0;
  bool instanceFound;

  // Increment the instance number until no more device records are found
  do {
    char instanceChar = static_cast<char>('0' + instanceCount);
    string devName  = FpcDeviceRootPrefix + instanceChar;
    string nodeName = FpcDeviceNodeBase + instanceChar;

    // Try to create a node for the next device
    instanceFound = createNode(devName, nodeName);
    if(instanceFound) {
      // Attempt to polymorphically create an instance to abstract the device
      XilinxFpcDevice *newDevice = XilinxFpcDevice::abstractDevice(nodeName);

      // Add the object instance to the collection being returned, if one was
      // created, and unconditionally advance to the next instance number
      if(newDevice != NULL) returnDevices.push_back(newDevice);
      instanceCount++;
    }

  } while(instanceFound);

  return(returnDevices);
}

// Protected constructor

XilinxFpcDevice::XilinxFpcDevice(const string &nodeName, int32_t nodeHandle) :
  nodeName(nodeName),
  nodeHandle(nodeHandle) {
}

// Protected helper methods

void XilinxFpcDevice::configUserPartition(const std::string &binFilename) {

  struct fpc_data_block dataBlock;
  uint32_t wordsLeft; 
  __m256i write_data;
  uint32_t pad_0;
  filebuf *bufPtr;
  int32_t ret;
  uint32_t fileSize;
  uint32_t fileWords;
  uint32_t fileBlocks;
  ifstream bitstreamInput;

  // Open the bitstream input file
  bitstreamInput.open(binFilename.c_str());
  if(bitstreamInput.fail()) {
    cout << "Unable to open bitstream file \"" << binFilename << "\" for reading" << endl;
    return;
  }

  // Compute the file size and the consequent number of blocks
  bufPtr = bitstreamInput.rdbuf();
  bufPtr->pubseekpos(0, ios::in);
  fileSize   = bufPtr->pubseekoff(0, ios::end, ios::in);
  fileWords  = ((fileSize / FPC_BYTES_PER_WORD) + ((fileSize % FPC_BYTES_PER_WORD) ? 1 : 0));
  fileBlocks = ((fileWords / MAX_CONFIG_BLOCK_SIZE) + ((fileWords % MAX_CONFIG_BLOCK_SIZE) ? 1 : 0));

  cout << "Configuring user partition with \"" 
       << binFilename 
       << "\": size "
       << fileSize
       << ", "
       << fileWords
       << " words, "
       << fileBlocks
       << " blocks" 
       << endl;

  // Reset the input buffer position to the beginning
  bufPtr->pubseekpos(0, ios::in);

  // Initiate a partial configuration cycle with the driver
  if((ret = ioctl(nodeHandle, IOC_INIT_CONFIG, fileWords)) != 0) {
    cerr << "Failed to complete config init I/O control to \""
         << nodeName
         << "\", error " 
         << errno
         << endl;
  }

  // Map BAR to userspace virtual address. 
  char * addr = (char *) mmap (NULL, PAGE_SIZE, PROT_WRITE | PROT_READ, MAP_SHARED, nodeHandle, 0);
  if (addr == MAP_FAILED)
    handle_error ("mmap");
  else if ((uint64_t)addr % 256)
    handle_error ("BAR address must be 32 bytes aligned.");
 
  wordsLeft = fileWords;

  if (burst == false) {

    while(wordsLeft > 0) {
      dataBlock.num_words = 1;
      bitstreamInput.read(reinterpret_cast<char*>(dataBlock.block_words), 
                         (dataBlock.num_words * FPC_BYTES_PER_WORD));
   
      memcpy (addr, &dataBlock.block_words, dataBlock.num_words*FPC_BYTES_PER_WORD);
      _mm_mfence(); 
      // Decrement the words remaining
      wordsLeft -= dataBlock.num_words;
    }
  }
  else if (burst == true && burst_size == 128) {

    while(wordsLeft > 0) {
      dataBlock.num_words = ((wordsLeft >= 4) ? 4 : wordsLeft);
      bitstreamInput.read(reinterpret_cast<char*>(dataBlock.block_words), 
                         (dataBlock.num_words * FPC_BYTES_PER_WORD));
   
      memcpy (addr, &dataBlock.block_words, dataBlock.num_words*FPC_BYTES_PER_WORD);
      _mm_mfence(); 
      // Decrement the words remaining
      wordsLeft -= dataBlock.num_words;
    }
  }
  else if ((burst == true) && (burst_size == 256))
  {
    while(wordsLeft > 0) {
      // Write maximum-sized blocks until the last one
      if (wordsLeft >= 8) {
        dataBlock.num_words = 8;
        bitstreamInput.read(reinterpret_cast<char*>(dataBlock.block_words), 32);
      }
      else { // pad 0 if the last write is less than 256 bytes
        bitstreamInput.read(reinterpret_cast<char*>(dataBlock.block_words), 
                           (wordsLeft * FPC_BYTES_PER_WORD));
        dataBlock.num_words = wordsLeft;
        pad_0 = 8 - wordsLeft;
        for (int i = wordsLeft; i < pad_0; i ++)
          dataBlock.block_words[i] = 0; 
      }

      write_data = _mm256_set_epi32 (dataBlock.block_words[7], dataBlock.block_words[6], dataBlock.block_words[5], dataBlock.block_words[4], 
                                     dataBlock.block_words[3], dataBlock.block_words[2], dataBlock.block_words[1], dataBlock.block_words[0] 
                                    );
  
      _mm256_store_si256((__m256i *) addr, write_data);
      _mm_mfence();
      // Decrement the words remaining
      wordsLeft -= dataBlock.num_words;
    }//end while
  }// end if  
}

// Private helper methods

const bool XilinxFpcDevice::createNode(const string &devName, const string &nodeName) {
  int32_t major = 0;
  int32_t minor = 0;
  bool success;

  // Locate the device by its miscellaneous device class, returning failure
  // if the misc device does not exist.
  string devPath = "/sys/class/misc/" + devName + "/dev";
  char buf[16];
  int32_t fd = ::open(devPath.c_str(), O_RDONLY);
  if(fd < 0) return(false);

  // Create the device node pathname
  ssize_t read_bytes;

  memset(buf, 0, sizeof(buf));
  if((read_bytes = read(fd, buf, sizeof(buf))) == 0) {
    cerr << "Unable to read from sysfs entry for \""
         << devName
         << "\""
         << endl;
  }
  close(fd);
  buf[sizeof(buf)-1] = 0;
  sscanf(buf, "%d:%d", &major, &minor);
    
  // First attempt to unlink any stale node from a previous run.
  int32_t returnCode = ::unlink(nodeName.c_str());
  success = ((returnCode >= 0) | (errno == ENOENT));

  // Create the device node
  if(success) {
    returnCode = ::mknod(nodeName.c_str(), S_IFCHR | 0777, (major<<8) | minor);
    if(returnCode < 0) {
      cerr << "Error creating device node \""
           << nodeName
           << "\" at major / minor ("
           << major
           << ", "
           << minor
           << ") : "
           << strerror(errno)
           << endl;
      success = false;
    }
  }

  return(success);
}

XilinxFpcDevice*
XilinxFpcDevice::abstractDevice(const std::string &nodeName) {
  XilinxFpcDevice *retInstance = NULL;
  int32_t nodeHandle;
  int32_t retValue;

  // Open the device node for use
  if((nodeHandle = ::open(nodeName.c_str(), O_RDWR)) > 0) {
    // Opened successfully, perform an I/O control operation to obtain the
    // vendor and product ID for the board
    struct fpc_board_id board_id;

    if(ioctl(nodeHandle, IOC_GET_BOARD_ID, &board_id) != 0) {
      retValue = errno;
      cerr << "Failed to complete I/O control to \""
           << nodeName
           << "\", error "
           << retValue
           << endl;
    }

    // Construct a 32-bit tag from the two identifying values and use it to
    // locate a factory creator for an appropriate instance
    uint32_t boardTag = ((board_id.vendor << 16) | board_id.device);
    map<uint32_t, Creator*> &factoryMap(getFactoryMap());
    map<uint32_t, Creator*>::iterator findIter = factoryMap.find(boardTag);
    if(findIter != factoryMap.end()) {
      retInstance = findIter->second->createInstance(nodeName, nodeHandle);
    } else {
      cout << "Unable to locate board abstraction class for vendor 0x"
           << setfill('0') << setw(4) << hex 
           << board_id.vendor
           << ", product 0x" << board_id.device
           << dec << endl;
    }
  }

  // Return the instance, or NULL if a failure occured
  return(retInstance);
}

map<uint32_t, XilinxFpcDevice::Creator*>& XilinxFpcDevice::getFactoryMap(void) {
  static map<uint32_t, Creator*> factoryMap;

  // Return the static instance, which is implicitly created upon the
  // first invocation of the method
  return(factoryMap);
}

// Protected type implementations

// Class XilinxFpcDevice::Creator

// Public interface

XilinxFpcDevice::Creator::Creator(uint16_t boardVendor, uint16_t boardDevice) {
  // Register the instance as the creator for the passed board info
  uint32_t boardTag = ((boardVendor << 16) | boardDevice);
  XilinxFpcDevice::getFactoryMap().insert(make_pair(boardTag, this));
}

XilinxFpcDevice::Creator::~Creator(void) {
}
