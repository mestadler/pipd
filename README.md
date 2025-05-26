# PIPD - Python Package Installer for Debian

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Version](https://img.shields.io/badge/python-3.8%2B-blue)](https://www.python.org/downloads/)
[![Debian](https://img.shields.io/badge/Debian-compatible-red)](https://www.debian.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-compatible-orange)](https://ubuntu.com/)

PIPD is an advanced Python package management tool designed specifically for Debian-based systems. It bridges the gap between system package management (APT) and Python package management (PyPI), prioritizing system packages when available while providing seamless fallback to PyPI.

## 🌟 Key Features

- **🔍 Intelligent Package Resolution**: Automatically checks Debian repositories before PyPI
- **🚀 Familiar CLI Interface**: Uses pip-like commands for ease of use  
- **🛡️ Transaction Support**: Automatic rollback on installation failures
- **📦 Package Conversion**: Converts PyPI packages to .deb format for system integration
- **🔒 Security First**: Input validation, privilege checking, and safe execution
- **⚡ Performance**: Built-in caching to reduce redundant network calls
- **🎯 PEP 668 Compliant**: Works with externally managed Python environments

## 📋 Table of Contents

- [Why PIPD?](#-why-pipd)
- [Installation](#-installation)
- [Usage](#-usage)
- [Configuration](#%EF%B8%8F-configuration)
- [Architecture](#-architecture)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🤔 Why PIPD?

Modern Debian/Ubuntu systems implement PEP 668, which prevents pip from installing packages system-wide to avoid conflicts. PIPD solves this by:

1. **Prioritizing system packages**: Safer and more stable
2. **Converting PyPI packages**: Creates proper .deb packages  
3. **Managing dependencies**: Handles conflicts between system and PyPI packages
4. **Providing rollback**: Failed installations don't leave your system broken

## 🚀 Installation

### Prerequisites

- Debian-based system (Debian 11+, Ubuntu 20.04+)
- Python 3.8 or higher
- Root privileges for installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/yourusername/pipd.git
cd pipd

# Run the installer
sudo ./install-pipd.sh
```

The installer will:
- Detect available Python versions
- Install system dependencies
- Set up the PIPD environment
- Configure logging and permissions

### Manual Installation

See [docs/INSTALL.md](docs/INSTALL.md) for detailed manual installation instructions.

## 📖 Usage

### Basic Commands

```bash
# Install packages
sudo pipd install requests numpy pandas

# Install specific version
sudo pipd install django==4.2

# Install from requirements file
sudo pipd install -r requirements.txt

# List installed packages
pipd list

# Show package information
pipd show requests

# Uninstall packages
sudo pipd uninstall requests
```

### Advanced Usage

```bash
# Force reinstall
sudo pipd install --force-reinstall numpy

# Upgrade packages
sudo pipd install --upgrade django

# List with different formats
pipd list --format json
pipd list --format simple

# Verbose mode for debugging
sudo pipd -v install tensorflow
```

## ⚙️ Configuration

PIPD uses a TOML configuration file located at `/etc/pipd/config.toml`:

```toml
[general]
prefer_system_packages = true
cache_ttl = 3600
verbose = false

[sources]
check_debian_first = true
allow_pypi_fallback = true

[security]
verify_checksums = true
safe_mode = true
```

User-specific configuration can be placed in `~/.config/pipd/config.toml`.

## 🏗 Architecture

PIPD follows a modular architecture:

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

- **PackageResolver**: Resolves packages across Debian and PyPI sources
- **DebianPackageManager**: Handles APT operations
- **PyPIPackageManager**: Downloads and converts PyPI packages
- **DependencyResolver**: Manages dependency conflicts
- **InstallationTransaction**: Provides rollback capability

## 🔧 Troubleshooting

### Common Issues

#### PEP 668 Error
```bash
error: externally-managed-environment
```
This is expected! PIPD is designed to work with this restriction by converting packages to .deb format.

#### Permission Denied
```bash
Error: This script requires root privileges
```
Solution: Use `sudo pipd install <package>`

#### Package Not Found
PIPD searches Debian repositories first. If a package isn't found:
1. Check the package name spelling
2. Update package lists: `sudo apt update`
3. The package might only be available on PyPI

### Debug Mode

Enable verbose logging for troubleshooting:
```bash
sudo pipd -v install <package>
```

Check logs at `/var/log/pipd.log` for detailed information.

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/pipd.git
cd pipd

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install development dependencies
pip install -r requirements-dev.txt

# Run tests
python -m pytest tests/
```

## 📊 Comparison with Other Tools

| Feature | PIPD | pip | pipx | apt |
|---------|------|-----|------|-----|
| System package priority | ✅ | ❌ | ❌ | ✅ |
| PyPI packages | ✅ | ✅ | ✅ | ❌ |
| .deb conversion | ✅ | ❌ | ❌ | N/A |
| Transaction rollback | ✅ | ❌ | ❌ | ✅ |
| PEP 668 compliant | ✅ | ❌ | ✅ | N/A |

## 🛡️ Security

PIPD implements several security measures:
- Input validation for package names
- Privilege checking before system modifications
- Secure subprocess execution
- Optional checksum verification

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Debian packaging team for the robust APT system
- Python Software Foundation for pip and venv
- py2deb and stdeb developers for package conversion tools
- Click developers for the excellent CLI framework

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/pipd/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/pipd/discussions)
- **Wiki**: [Project Wiki](https://github.com/yourusername/pipd/wiki)

---

Made with ❤️ for the Debian/Ubuntu Python community

## 📚 Documentation

- [**Installation Guide**](docs/INSTALL.md) - Detailed installation instructions
- [**User Manual**](docs/MANUAL.md) - Comprehensive usage documentation  
- [**PEP 668 Guide**](docs/PEP668.md) - Understanding PEP 668 and how PIPD handles it
- [**Python Compatibility**](docs/PYTHON_COMPATIBILITY.md) - Python version support details
- [**Contributing**](CONTRIBUTING.md) - How to contribute to PIPD

## 📁 Project Structure
pipd/
├── pipd                    # Main executable
├── install-pipd.sh         # Installation script
├── install-python312-debian.sh  # Python 3.12 installer
├── README.md              # This file
├── LICENSE                # MIT License
├── CONTRIBUTING.md        # Contribution guidelines
├── docs/                  # Documentation
│   ├── INSTALL.md         # Installation guide
│   ├── MANUAL.md          # User manual
│   ├── PEP668.md          # PEP 668 explanation
│   └── PYTHON_COMPATIBILITY.md
├── examples/              # Example configurations
│   ├── config.toml.example
│   └── requirements-example.txt
├── tests/                 # Test suite
│   └── test_pipd.py
└── scripts/               # Utility scripts
├── fix-pipd.sh
└── github-script.sh

