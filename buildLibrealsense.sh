#!/bin/bash

# Builds the Intel Realsense library librealsense on a Jetson board.
# Copyright (c) 2016-19 Jetsonhacks
# Rearranged by Fabrizio Romanelli, Roberto Masocco, June 2021
# MIT License

LIBREALSENSE_DIRECTORY=$1/Tools_Workspace/librealsense
LIBREALSENSE_VERSION=v2.43.0
INIT_DIR=$1
INSTALL_DIR=$PWD
NVCC_PATH=/usr/local/cuda/bin/nvcc

USE_CUDA=true

# Shows help text.
function usage
{
    echo "usage: ./buildLibrealsense.sh ROOT_DIR [[-c ] | [-h]]"
    echo "-nc | --no-cuda  Build without CUDA support"
    echo "-h | --help Display this message"
}

# Iterate through command line inputs
while [ "$1" != "" ]; do
    case $1 in
        -nc | --no-cuda )  USE_CUDA=false
                                ;;
        -h | --help )           usage
                                exit
    esac
    shift
done

echo "Build with CUDA: "$USE_CUDA

# Output colors.
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo ""
echo "Please make sure that no RealSense cameras are currently attached"
echo ""
read -n 1 -s -r -p "Press any key to continue"
echo ""

if [[ ! -d "$LIBREALSENSE_DIRECTORY" ]]; then
  # Clone librealsense.
  cd $INIT_DIR/Tools_Workspace
  echo "${green}Cloning librealsense${reset}"
  git clone https://github.com/IntelRealSense/librealsense.git
fi

# Is the version of librealsense correct?
cd $LIBREALSENSE_DIRECTORY
VERSION_TAG=$(git tag -l $LIBREALSENSE_VERSION)
if [[ ! $VERSION_TAG  ]]; then
  echo ""
  tput setaf 1
  echo "==== librealsense Version Mismatch! ============="
  tput sgr0
  echo ""
  echo "The installed version of librealsense is not current enough for these scripts."
  echo "This script needs librealsense tag version: "$LIBREALSENSE_VERSION "but it is not available."
  echo "Please upgrade librealsense or remove the librealsense folder before attempting to install again."
  echo ""
  exit 1
fi

# Checkout version the last tested version of librealsense
git checkout $LIBREALSENSE_VERSION

# Install the dependencies
cd $INSTALL_DIR
./scripts/installDependencies.sh

cd $LIBREALSENSE_DIRECTORY

# Now compile librealsense and install
mkdir build 
cd build
# Build examples, including graphical ones
echo "${green}Configuring build system...${reset}"
# Build with CUDA (default), the CUDA flag is USE_CUDA, ie -DUSE_CUDA=true
export CUDACXX=$NVCC_PATH
export PATH=${PATH}:/usr/local/cuda/bin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/lib64

cmake ../ -DBUILD_EXAMPLES=true -DFORCE_LIBUVC=true -DBUILD_WITH_CUDA="$USE_CUDA" -DCMAKE_BUILD_TYPE=release -DBUILD_PYTHON_BINDINGS=bool:true

# The library will be installed in /usr/local/lib, header files in /usr/local/include
# The demos, tutorials and tests will located in /usr/local/bin.
echo "${green}Building librealsense, headers, tools and demos${reset}"
echo "${green}Leaving one CPU out to avoid blocking the system...${reset}"

NUM_CPU=$(nproc --all)
time make -j$(($NUM_CPU - 1))
if [[ $? -eq 0 ]]; then
  echo "${green}librealsense build successful!${reset}"
else
  # Try to make again; Sometimes there are issues with the build
  # because of lack of resources or concurrency issues
  echo "${red}librealsense did not build${reset}" 1>&2
  echo "Retrying..."
  # Single thread this time
  time make 
  if [[ $? -eq 0 ]]; then
    echo "${green}librealsense build successful!${reset}"
  else
    # Try one last time
    echo "${red}librealsense did not successfully build${reset}" 1>&2
    echo "${red}Please fix issues and retry build${reset}" 1>&2
    exit 1
  fi
fi
echo "${green}Installing librealsense, headers, tools and demos...${reset}"
sudo make install

# Add Python wrapper to PATH.
if grep -Fxq 'export PYTHONPATH=$PYTHONPATH:/usr/local/lib' ~/.bashrc ; then
    echo "PYTHONPATH already exists in .bashrc file!"
else
   echo 'export PYTHONPATH=$PYTHONPATH:/usr/local/lib' >> ~/.bashrc 
   echo "PYTHONPATH added to ~/.bashrc. Pyhon wrapper is now available for importing pyrealsense2"
fi

# Copy over the udev rules so that camera can be run from user space
cd $LIBREALSENSE_DIRECTORY
echo "${green}Applying udev rules${reset}"
sudo cp config/99-realsense-libusb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && udevadm trigger

echo "${green}Library Installed${reset}"
echo " "
echo " -----------------------------------------"
echo "The library is installed in /usr/local/lib"
echo "The header files are in /usr/local/include"
echo "The demos and tools are located in /usr/local/bin"
echo " "
echo " -----------------------------------------"
echo " "
