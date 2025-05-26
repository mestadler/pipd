# PIPD - Python Package Installer for Debian

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Usage](#usage)
6. [Architecture](#architecture)
7. [Security](#security)
8. [Troubleshooting](#troubleshooting)
9. [Development](#development)
10. [API Reference](#api-reference)

## Overview

PIPD is an advanced Python package management tool designed specifically for Debian-based systems. It bridges the gap between system package management (APT) and Python package management (PyPI), prioritizing system packages when available while providing seamless fallback to PyPI.

### Why PIPD?

- **System Integration**: Leverages Debian's robust package management system
- **Dependency Safety**: Reduces dependency conflicts by preferring system packages
- **Familiar Interface**: Uses pip-like commands for ease of use
- **Transaction Support**: Rollback capability for failed installations
- **Security First**: Input validation and privilege checking

## Features

### Core Features

- ✅ **Intelligent Package Resolution**: Automatically checks Debian repositories before PyPI
- ✅ **Transaction Management**: Rollback failed installations automatically
- ✅ **Security Hardening**: Input validation, privilege checking, safe subprocess execution
- ✅ **Caching**: Reduces redundant network calls with configurable TTL
- ✅ **Comprehensive Logging**: Detailed logs with rotation support
- ✅ **Configuration Management**: Flexible configuration via TOML files
- ✅ **Multiple Output Formats**: Table, JSON, and simple text outputs

### Package Management

- Install packages from Debian repositories or PyPI
- List installed Python packages
- Show detailed package information
- Uninstall packages with cleanup
- Handle version constraints
- Process requirements files

## Installation

### Prerequisites

- Debian-based system (Debian, Ubuntu, etc.)
- Python 3.8 or higher
- Root privileges for installation
- python3-venv package (for PEP 668 compliance)

### Quick Install

```bash
# Download and run the installation script
wget https://github.com/mestadler/pipd/raw/main/install.sh
sudo bash install.sh
```

### Manual Installation

1. **Install System Dependencies**:
```bash
sudo apt update
sudo apt install -y \
    python3 python3-pip python3-apt \
    python3-setuptools python3-wheel \
    python3-venv python3-stdeb \
    python3-requests python3-toml \
    python3-dev build-essential \
    dh-python debhelper fakeroot \
    dpkg-dev
```

2. **Create Virtual Environment for PIPD Tools**:
```bash
# Create virtual environment to avoid PEP 668 restrictions
sudo python3 -m venv /opt/pipd-venv

# Activate the environment
source /opt/pipd-venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install py2deb click stdeb

# Deactivate
deactivate
```

3. **Install PIPD**:
```bash
# Copy pipd.py to /usr/local/bin/pipd
sudo cp pipd.py /usr/local/bin/pipd
sudo chmod +x /usr/local/bin/pipd

# Create directories
sudo mkdir -p /etc/pipd /var/log/pipd /var/cache/pipd
```

4. **Create Configuration**:
```bash
# Copy the default configuration
sudo cp config.toml /etc/pipd/config.toml
```

### PEP 668 Compliance

PIPD is designed to work with PEP 668 (Externally Managed Environments) by:
- Using virtual environments for package conversion
- Never installing directly to system Python with pip
- Converting all packages to .deb format for system installation
- Maintaining isolation between system and Python packages

### Verification

```bash
# Check installation
pipd --version

# List packages (should work without errors)
sudo pipd list
```

## Configuration

PIPD uses a TOML configuration file located at `/etc/pipd/config.toml` by default.

### Configuration Options

```toml
[general]
# Prefer system packages over PyPI packages
prefer_system_packages = true

# Cache TTL in seconds (1 hour default)
cache_ttl = 3600

# Enable verbose logging
verbose = false

# Maximum retry attempts for operations
max_retries = 3

[sources]
# Check Debian repositories first
check_debian_first = true

# Allow fallback to PyPI if not found in Debian
allow_pypi_fallback = true

[security]
# Allow unsigned packages (not recommended)
allow_unsigned_packages = false

# Verify package checksums
verify_checksums = true

# Safe mode - extra security checks
safe_mode = true

[paths]
# Directory for caching package information
cache_dir = "/var/cache/pipd"

# Directory for log files
log_dir = "/var/log/pipd"

# Directory for temporary files
temp_dir = "/tmp/pipd"
```

### User Configuration

Users can override system configuration:

```bash
# Create user config directory
mkdir -p ~/.config/pipd

# Create user config
cat > ~/.config/pipd/config.toml << EOF
[general]
verbose = true

[sources]
check_debian_first = false
EOF

# Use custom config
pipd --config ~/.config/pipd/config.toml install requests
```

## Usage

### Basic Commands

#### Install Packages

```bash
# Install latest version
sudo pipd install requests

# Install specific version
sudo pipd install django==3.2.0

# Install multiple packages
sudo pipd install requests flask numpy

# Install from requirements file
sudo pipd install -r requirements.txt

# Force reinstall
sudo pipd install --force-reinstall requests

# Upgrade packages
sudo pipd install --upgrade requests
```

#### List Packages

```bash
# List all Python packages
pipd list

# List specific packages
pipd list requests flask

# JSON output
pipd list --format json

# Simple output (name and version only)
pipd list --format simple
```

#### Show Package Information

```bash
# Show package details
pipd show requests

# Shows version, dependencies, description, etc.
```

#### Uninstall Packages

```bash
# Uninstall single package
sudo pipd uninstall requests

# Uninstall multiple packages
sudo pipd uninstall requests flask

# Skip confirmation
sudo pipd uninstall -y requests
```

### Advanced Usage

#### Verbose Mode

```bash
# Enable verbose logging for debugging
sudo pipd -v install requests
```

#### Custom Configuration

```bash
# Use custom config file
sudo pipd --config /path/to/config.toml install requests
```

#### Working with Requirements Files

```bash
# Install from requirements.txt
sudo pipd install -r requirements.txt

# Install from multiple requirements files
sudo pipd install -r base.txt -r dev.txt
```

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────┐
│                    CLI Interface                     │
│                  (Click-based CLI)                   │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────┐
│                 PipdOrchestrator                     │
│         (Main coordination component)                │
└──────┬──────────┬─────────────┬──────────┬──────────┘
       │          │             │          │
┌──────┴────┐ ┌──┴──────┐ ┌────┴────┐ ┌──┴────────┐
│ Package   │ │Debian   │ │ PyPI    │ │Dependency │
│ Resolver  │ │Manager  │ │Manager  │ │ Resolver  │
└───────────┘ └─────────┘ └─────────┘ └───────────┘
```

### Key Components

1. **CLI Interface**: Click-based command-line interface
2. **PipdOrchestrator**: Coordinates all operations
3. **PackageResolver**: Resolves packages across sources
4. **DebianPackageManager**: Handles APT operations
5. **PyPIPackageManager**: Handles PyPI packages and conversion
6. **DependencyResolver**: Manages dependency conflicts
7. **InstallationTransaction**: Provides rollback capability

### Package Resolution Flow

```
User Request → Normalize Name → Check Debian → Check PyPI → 
→ Resolve Dependencies → Install → Commit/Rollback
```

## Security

### Security Features

1. **Input Validation**: All package names are validated against a whitelist pattern
2. **Privilege Checking**: Ensures appropriate privileges before system modifications
3. **No Shell Injection**: Uses subprocess with arrays, not shell strings
4. **Transaction Rollback**: Failed installations are automatically rolled back
5. **Checksum Verification**: Optional package checksum verification

### Security Best Practices

1. Always run with minimum required privileges
2. Keep the system and pipd updated
3. Review package sources before installation
4. Use configuration to enforce security policies
5. Monitor logs for suspicious activity

### Restricted Package Names

The following patterns are blocked:
- Names containing shell metacharacters (`;`, `|`, `&`, etc.)
- Names with path traversal attempts (`../`, `./`)
- Names with command substitution (`` ` ``, `$()`)

## Troubleshooting

### Common Issues

#### PEP 668 Error (Externally Managed Environment)

```bash
error: externally-managed-environment

× This environment is externally managed
```

**This is expected behavior!** PIPD is designed to work with this restriction by:
- Creating isolated virtual environments for package conversion
- Never using pip to install directly to system Python
- Converting all packages to .deb format

If you see this error, ensure:
1. `python3-venv` is installed: `sudo apt install python3-venv`
2. PIPD is properly installed with its virtual environment
3. You're using `sudo pipd install` not `pip install`

#### Permission Denied

```bash
Error: This script requires root privileges. Please run with sudo.
```

**Solution**: Run with sudo: `sudo pipd install package`

#### Package Not Found

```bash
Error: Package xyz not found in any source
```

**Solutions**:
1. Check package name spelling
2. Ensure repositories are updated: `sudo apt update`
3. Check if PyPI fallback is enabled in config

#### Dependency Conflicts

```bash
Error: Dependency conflicts found:
  - requests: 2.25.1 (from debian) conflicts with 2.28.1 (from pypi)
```

**Solutions**:
1. Specify exact version: `sudo pipd install requests==2.25.1`
2. Use `--force-reinstall` to override
3. Uninstall conflicting package first

#### Virtual Environment Creation Failed

```bash
Error: Failed to create virtual environment
```

**Solutions**:
1. Ensure `python3-venv` is installed: `sudo apt install python3-venv`
2. Check disk space: `df -h`
3. Verify Python installation: `python3 --version`

#### Installation Rollback

```bash
Error: Installation failed, rolling back...
```

This is automatic - pipd will remove any partially installed packages.

### Debug Mode

Enable verbose logging for detailed troubleshooting:

```bash
# Temporary verbose mode
sudo pipd -v install package

# Or set in config
[general]
verbose = true
```

### Log Files

Check logs for detailed error information:

```bash
# View recent logs
sudo tail -f /var/log/pipd/pipd.log

# Search for errors
sudo grep ERROR /var/log/pipd/pipd.log
```

## Development

### Setting Up Development Environment

```bash
# Clone repository
git clone https://github.com/mestadler/pipd.git
cd pipd

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install development dependencies
pip install -r requirements-dev.txt

# Run tests
python -m pytest tests/
```

### Running Tests

```bash
# Run all tests
python -m pytest

# Run with coverage
python -m pytest --cov=pipd

# Run specific test file
python -m pytest tests/test_security.py

# Run in verbose mode
python -m pytest -v
```

### Code Style

```bash
# Format code
black pipd.py tests/

# Check style
flake8 pipd.py

# Type checking
mypy pipd.py
```

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make changes and add tests
4. Run tests and ensure they pass
5. Commit: `git commit -m "Add feature"`
6. Push: `git push origin feature-name`
7. Create a Pull Request

## API Reference

### Main Classes

#### Config

```python
class Config:
    """Configuration manager for pipd"""
    
    def __init__(self, config_path: Optional[str] = None):
        """Initialize with optional config path"""
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value using dot notation"""
```

#### PackageResolver

```python
class PackageResolver:
    """Resolve package names across different sources"""
    
    def resolve_package(self, package_name: str, 
                       version: Optional[str] = None) -> PackageInfo:
        """Resolve package from available sources"""
```

#### InstallationTransaction

```python
class InstallationTransaction:
    """Manage installation transactions for rollback capability"""
    
    def record_package_installation(self, package: str):
        """Record installed package"""
    
    def rollback(self):
        """Rollback all changes"""
    
    def commit(self):
        """Commit transaction"""
```

### Exceptions

- `PipdError`: Base exception for all pipd errors
- `PackageNotFoundError`: Package not found in any source
- `DependencyConflictError`: Version conflict detected
- `InstallationError`: Package installation failed
- `SecurityError`: Security-related error

### Decorators

#### @cached

```python
@cached(ttl=3600)
def expensive_function():
    """Function with cached results"""
```

## License

PIPD is released under the MIT License. See LICENSE file for details.

## Acknowledgments

- Debian packaging team for the robust APT system
- Poetry developers for dependency resolution
- py2deb developers for package conversion
- Click developers for the excellent CLI framework

## Support

- **Issues**: https://github.com/mestadler/pipd/issues
- **Discussions**: https://github.com/mestadler/pipd/discussions
- **Wiki**: https://github.com/mestadler/pipd/wiki
