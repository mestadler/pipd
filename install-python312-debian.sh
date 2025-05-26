#!/bin/bash
# Quick Python 3.12 installation for Debian

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Python 3.12 Installation for Debian${NC}"
echo "===================================="
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Check if already installed
if command -v python3.12 &> /dev/null; then
    echo -e "${GREEN}Python 3.12 is already installed!${NC}"
    python3.12 --version
    exit 0
fi

echo "This will install Python 3.12 from source."
echo "It will take about 10-15 minutes."
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Step 1: Install build dependencies
echo -e "${GREEN}Step 1:${NC} Installing build dependencies..."
apt-get update
apt-get install -y \
    build-essential \
    gdb \
    lcov \
    pkg-config \
    libbz2-dev \
    libffi-dev \
    libgdbm-dev \
    libgdbm-compat-dev \
    liblzma-dev \
    libncurses-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    tk-dev \
    uuid-dev \
    zlib1g-dev \
    wget \
    curl \
    xz-utils

# Step 2: Download Python 3.12
echo -e "${GREEN}Step 2:${NC} Downloading Python 3.12.7 (latest stable)..."
cd /tmp
wget https://www.python.org/ftp/python/3.12.7/Python-3.12.7.tgz
tar -xf Python-3.12.7.tgz
cd Python-3.12.7

# Step 3: Configure
echo -e "${GREEN}Step 3:${NC} Configuring Python build..."
./configure --enable-optimizations --enable-shared --prefix=/usr/local

# Step 4: Build (this takes time)
echo -e "${GREEN}Step 4:${NC} Building Python (this will take 10-15 minutes)..."
make -j$(nproc)

# Step 5: Install
echo -e "${GREEN}Step 5:${NC} Installing Python..."
make altinstall

# Step 6: Update shared library cache
echo -e "${GREEN}Step 6:${NC} Updating system configuration..."
ldconfig

# Create convenient symlinks
ln -sf /usr/local/bin/python3.12 /usr/bin/python3.12
ln -sf /usr/local/bin/pip3.12 /usr/bin/pip3.12

# Step 7: Verify installation
echo -e "${GREEN}Step 7:${NC} Verifying installation..."
python3.12 --version
python3.12 -m pip --version

# Step 8: Install venv module
echo -e "${GREEN}Step 8:${NC} Ensuring venv module is available..."
python3.12 -m ensurepip
python3.12 -m pip install --upgrade pip

# Clean up
echo -e "${GREEN}Step 9:${NC} Cleaning up..."
cd /
rm -rf /tmp/Python-3.12.7*

echo
echo -e "${GREEN}✓ Python 3.12 installation complete!${NC}"
echo
echo "You can now use Python 3.12:"
echo "  python3.12 --version"
echo
echo "To install PIPD with Python 3.12:"
echo "  sudo PIPD_PYTHON=python3.12 ./install-pipd.sh"
echo
echo "Or run the installer and select python3.12 from the menu."
