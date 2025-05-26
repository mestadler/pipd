# PIPD Installation Guide

## System Requirements

- Debian-based Linux distribution (Debian 11+, Ubuntu 20.04+)
- Python 3.8 or higher
- Root access for system-wide installation

## Installation Methods

### 1. Automated Installation (Recommended)

```bash
git clone https://github.com/yourusername/pipd.git
cd pipd
sudo ./install-pipd.sh
```

### 2. Manual Installation

#### Step 1: Install System Dependencies

```bash
sudo apt update
sudo apt install -y \
    python3 python3-pip python3-apt \
    python3-venv python3-dev \
    python3-stdeb python3-requests \
    python3-toml build-essential \
    dh-python debhelper fakeroot
```

#### Step 2: Install Python Dependencies

```bash
# Create virtual environment for PIPD tools
sudo python3 -m venv /opt/pipd-venv
source /opt/pipd-venv/bin/activate
pip install click stdeb py2deb
deactivate
```

#### Step 3: Install PIPD

```bash
# Copy the script
sudo cp pipd /usr/local/bin/pipd
sudo chmod +x /usr/local/bin/pipd

# Create directories
sudo mkdir -p /etc/pipd /var/log/pipd /var/cache/pipd

# Create log file with proper permissions
sudo touch /var/log/pipd.log
sudo chmod 666 /var/log/pipd.log
```

#### Step 4: Configure

```bash
# Copy example configuration
sudo cp examples/config.toml.example /etc/pipd/config.toml
```

## Python Version Selection

PIPD works best with Python 3.12. If you have multiple Python versions:

```bash
# Set Python version for installation
export PIPD_PYTHON=python3.12
sudo -E ./install-pipd.sh
```

## Troubleshooting Installation

### Python 3.13 Issues

Python 3.13 has compatibility issues with some tools. We recommend Python 3.12:

```bash
# Install Python 3.12 on Ubuntu
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.12 python3.12-venv python3.12-dev
```

### Permission Errors

If you encounter permission errors with logging:

```bash
sudo touch /var/log/pipd.log
sudo chmod 666 /var/log/pipd.log
```

### PEP 668 Errors

PIPD is designed to work with PEP 668. If you see "externally-managed-environment" errors, ensure you're using PIPD instead of pip for system-wide installations.

## Uninstalling

```bash
sudo pipd-uninstall
```

Or manually:

```bash
sudo rm -f /usr/local/bin/pipd
sudo rm -rf /etc/pipd /var/log/pipd* /var/cache/pipd
sudo rm -rf /opt/pipd-venv
```
