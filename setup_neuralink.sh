#!/usr/bin/env bash
# NeuraLinkTech AI Vehicle Diagnostics - Auto-Installer v3.0
# ISO 21434 Automotive Cybersecurity Compliant

set -eo pipefail

# Configuration
declare -A PLATFORM_DEPS=(
    ["raspberrypi"]="python3.11 pip3 git libsocketcan2 can-utils"
    ["linux"]="python3.11 pip3 git docker.io"
    ["macos"]="python3.11 git docker"
    ["wsl"]="python3.11 git docker-desktop"
)

MODEL_HASHES=(
    ["fuelnet_v4.pt"]="a1b2c3d4e5f6..."
    ["torque_converter_v2.pt"]="b2c3d4e5f6g7..."
)

# Color Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Security Functions
verify_model_integrity() {
    local model_path=$1
    local expected_hash=${MODEL_HASHES[$(basename $model_path)]}
    
    echo -n "🔐 Verifying $(basename $model_path)... "
    actual_hash=$(sha256sum $model_path | awk '{print $1}')
    
    if [ "$actual_hash" != "$expected_hash" ]; then
        echo -e "${RED}FAILED${NC}"
        echo -e "${RED}Security violation: Model integrity check failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}PASSED${NC}"
}

# Hardware Setup
configure_can_bus() {
    echo -e "${YELLOW}🚗 Configuring CAN Interface...${NC}"
    sudo ip link set can0 type can bitrate 500000 triple-sampling on
    sudo ip link set can0 txqueuelen 1000
    sudo ip link set can0 up
    
    echo -e "CAN0 Status:"
    ip -details -statistics link show can0
}

# Platform Detection
detect_platform() {
    case $(uname -s) in
        Linux)
            if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
                echo "raspberrypi"
            elif grep -q "microsoft" /proc/version; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin) echo "macos" ;;
        *) echo "unsupported" ;;
    esac
}

# Main Installation
install_dependencies() {
    local platform=$1
    
    echo -e "${YELLOW}🔧 Installing $platform dependencies...${NC}"
    case $platform in
        raspberrypi|linux|wsl)
            sudo apt-get update && sudo apt-get install -y ${PLATFORM_DEPS[$platform]}
            sudo usermod -aG can,docker $USER
            ;;
        macos)
            brew install ${PLATFORM_DEPS[$platform]}
            ;;
    esac
}

setup_python_env() {
    echo -e "${YELLOW}🐍 Creating Python Environment...${NC}"
    python3.11 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip wheel
    pip install -r requirements.txt
}

setup_hardware() {
    local platform=$1
    
    if [ "$platform" == "raspberrypi" ]; then
        configure_can_bus
        echo -e "gpio=24,17=op,dl" | sudo tee /etc/neuralink_gpio.conf
    fi
}

# Security Setup
initialize_secure_boot() {
    echo -e "${YELLOW}🔒 Configuring Secure Boot...${NC}"
    sudo mkdir -p /etc/neuralink/secure
    sudo chmod 0700 /etc/neuralink/secure
    
    if [ ! -f "/etc/neuralink/secure/system.key" ]; then
        openssl genpkey -algorithm ED25519 -out /tmp/neuralink.key
        sudo mv /tmp/neuralink.key /etc/neuralink/secure/system.key
    fi
}

# Main Execution
main() {
    echo -e "${GREEN}🚀 Starting NeuraLinkTech Installation...${NC}"
    
    # Verify root privileges
    if [ "$EUID" -eq 0 ]; then
        echo -e "${RED}Error: Do not run as root!${NC}"
        exit 1
    fi

    # Platform detection
    local platform=$(detect_platform)
    echo -e "Detected Platform: ${GREEN}$platform${NC}"
    
    # Dependency installation
    install_dependencies $platform
    
    # Python environment
    setup_python_env
    
    # Model verification
    verify_model_integrity "models/fuelnet_v4.pt"
    verify_model_integrity "models/torque_converter_v2.pt"
    
    # Hardware configuration
    setup_hardware $platform
    
    # Security setup
    initialize_secure_boot
    
    # Docker services
    echo -e "${YELLOW}🐳 Starting Docker Services...${NC}"
    docker compose build --no-cache
    docker compose up -d
    
    # Post-install
    echo -e "\n${GREEN}✅ Installation Complete!${NC}"
    echo -e "Access dashboard: ${YELLOW}http://localhost:8080${NC}"
    echo -e "Monitor system:   ${YELLOW}docker compose logs -f neuralink-core${NC}"
}

# Execute
main