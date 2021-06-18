#!/bin/bash

# Install dependencies for  the Intel Realsense library librealsense2 on a Jetson Board
# Copyright (c) 2016-19 Jetsonhacks 
# Rearranged by Fabrizio Romanelli, Roberto Masocco, June 2021
# MIT License

# Output colors.
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

# Generic stuff.
echo "${green}Adding Universe repository and updating...${reset}"
sudo apt-add-repository universe
sudo apt-get update
echo "${green}Adding dependencies, graphics libraries and tools...${reset}"
sudo apt-get install libssl-dev libusb-1.0-0-dev pkg-config -y
sudo apt-get install build-essential cmake cmake-curses-gui -y

# Graphics libraries - for SDK's OpenGL-enabled examples.
sudo apt-get install libgtk-3-dev libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev -y

# Add Python 3 support.
sudo apt-get install -y python3 python3-dev
