# File        : options.mk
# Description : Make options for the Xilinx PCI FPC test application

# Define and export toolchain environment settings
export LINUX_PATH = /usr/src/linux-source-3.0.0
export CROSS      = 
export CPPFLAGS   = -O2
export LINUX_INC  = $(LINUX_PATH)/include
export CCFRONT    = 
export CXXFRONT   = 
