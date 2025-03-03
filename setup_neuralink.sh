#!/usr/bin/env bash

# NeuraLinkTech AI Vehicle Diagnostics - Auto-Installer v2.1
# Supports: Linux (x86_64/ARM), macOS (Intel/Apple Silicon), Windows (WSL2)

set -eo pipefail

# Configuration
declare -A PLATFORM_DEPS=(
    ["linux"]="python3.11 pip3 git docker.io can-utils"
    ["raspberrypi"]="python3.11 pip3 git libsocketcan2"
    ["macos"]="python3.11 git docker"
    ["windows"]="python git docker-desktop"
)

NLT_ENV_FILE=".neuralink_env"
MODEL_HASH="a1b2c3d4e5f6..."

# Error handling
trap 'echo "Error at line $LINENO"; exit 1' ERR

check_privileges() {
    if [ "$EUID" -eq 0 ]; then
        echo "⚠️  Do not run as root! Requesting sudo when needed."
        exit 1
    fi
}

detect_platform() {
    case $(uname -s) in
        Linux)
            if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
                echo "raspberrypi"
            else
                echo "linux"
            fi
            ;;
        Darwin) echo "macos" ;;
        *MINGW*) echo "windows" ;;
        *) echo "unsupported" ;;
    esac
}

install_dependencies() {
    local platform=$1
    echo "🔧 Installing $platform dependencies..."
    
    case $platform in
        linux)
            sudo apt-get update && sudo apt-get install -y ${PLATFORM_DEPS[$platform]}
            sudo systemctl enable --now docker
            ;;
        raspberrypi)
            sudo apt-get update && sudo apt-get install -y ${PLATFORM_DEPS[$platform]}
            sudo usermod -aG can,spi,docker $USER
            ;;
        macos)
            brew update && brew install ${PLATFORM_DEPS[$platform]}
            ;;
        windows)
            choco install ${PLATFORM_DEPS[$platform]} -y
            ;;
    esac
}

setup_python_env() {
    echo "🐍 Configuring Python environment..."
    python3.11 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip wheel
    pip install -r requirements.txt
}

configure_can() {
    echo "🚗 Setting up CAN interface..."
    sudo ip link set can0 type can bitrate 500000
    sudo ip link set can0 txqueuelen 1000
    sudo ip link set can0 up
    sudo ifconfig can0
    
    echo "✅ CAN0 configured:"
    ip -details -statistics link show can0
}

verify_models() {
    echo "🔐 Validating AI models..."
    local model_hash=$(sha256sum models/fuelnet_v3.pt | awk '{print $1}')
    
    if [ "$model_hash" != "$MODEL_HASH" ]; then
        echo "❌ Model integrity check failed!"
        exit 1
    fi
}

setup_docker() {
    echo "🐳 Initializing Docker services..."
    docker compose build --no-cache
    docker compose up -d
    
    echo -e "\n📡 Service Status:"
    docker compose ps
}

post_install() {
    echo -e "\n🔌 Hardware Interface Permissions:"
    groups $USER | grep -E 'can|spi|docker' || echo "⚠️  Logout required for group changes"
    
    echo -e "\n✅ Installation Complete!"
    echo "   Start the system with: ./run_neuralink.sh"
}

main() {
    check_privileges
    local platform=$(detect_platform)
    
    echo "🚀 Starting NeuraLinkTech Setup on $platform..."
    
    install_dependencies $platform
    setup_python_env
    verify_models
    
    if [ "$platform" == "raspberrypi" ]; then
        configure_can
    fi
    
    setup_docker
    post_install
}

main