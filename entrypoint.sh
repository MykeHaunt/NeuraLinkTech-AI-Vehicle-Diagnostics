#!/bin/bash

# Detect platform if set to auto
if [ "$PLATFORM_TYPE" == "auto" ]; then
    if grep -q "Raspberry Pi" /proc/device-tree/model; then
        export PLATFORM_TYPE=raspberry
    else
        export PLATFORM_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
fi

# Configure CAN interface if needed
if [ "$PLATFORM_TYPE" == "raspberry" ]; then
    sudo ip link set $CAN_INTERFACE type can bitrate 500000
    sudo ifconfig $CAN_INTERFACE up
fi

# Start main application
python3 -u neura_link_core.py