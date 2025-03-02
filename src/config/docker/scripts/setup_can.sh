```bash
#!/bin/bash

# Configure CAN interface for 2JZ-GTE systems
sudo ip link set can0 type can bitrate 500000
sudo ip link set can0 txqueuelen 1000
sudo ip link set can0 up

# Enable CAN error frames
sudo ifconfig can0 txqueuelen 1000
sudo ip -details -statistics link show can0

# Persist configuration
echo "can0" | sudo tee -a /etc/network/interfaces.d/can
```
