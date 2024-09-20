#!/bin/bash

# Update the package list
sudo apt update

# Install gcc and make
sudo apt install -y gcc make

# Run the make command
make

# Copy the librestybaseencoding.so file to the parent directory of the parent directory
cp librestyradixtree.so ../../