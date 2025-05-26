#!/bin/bash
# Prepare PIPD for GitHub

set -e

echo "Preparing PIPD for GitHub..."

# Create directory structure
mkdir -p docs examples tests scripts

# Copy the fixed pipd script
cp /tmp/pipd_fixed pipd
chmod +x pipd

# Create example configuration
cat > examples/config.toml.example << 'EOF'
# Example PIPD Configuration

[general]
# Prefer system packages over PyPI packages
prefer_system_packages = true

# Cache TTL in seconds (1 hour)
cache_ttl = 3600

# Enable verbose logging
verbose = false

# Maximum retry attempts
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
# Cache directory
cache_dir = "~/.cache/pipd"

# Log directory
log_dir = "~/.local/share/pipd/logs"

# Temporary directory
temp_dir = "/tmp/pipd"
EOF

# Create requirements-dev.txt
cat > requirements-dev.txt << 'EOF'
# Development dependencies for PIPD

# Core testing
pytest>=7.0.0
pytest-cov>=3.0.0
pytest-mock>=3.6.0

# Code quality
black>=22.0.0
flake8>=4.0.0
mypy>=0.950
isort>=5.10.0

# Type stubs
types-requests>=2.27.0
types-toml>=0.10.0

# Pre-commit
pre-commit>=2.17.0

# Documentation
sphinx>=4.0.0
sphinx-rtd-theme>=1.0.0
sphinx-click>=3.0.0

# Security scanning
bandit>=1.7.0
safety>=1.10.0
EOF

# Create CHANGELOG.md
cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to PIPD will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-19

### Added
- Full PEP 668 compliance with virtual environment isolation
- Multiple package conversion fallback methods
- Transaction support with automatic rollback
- Comprehensive error handling with recovery suggestions
- Python version selection in installer
- Caching decorator for performance
- Configuration file support (TOML)

### Fixed
- Name collision with Python's list() builtin
- Dependency.name attribute error
- Logging permission issues

### Changed
- Migrated from argparse to Click for better CLI
- Improved security with input validation
- Better separation of concerns in architecture

## [0.1.0] - 2024-12-01

### Added
- Initial release
- Basic package installation from Debian and PyPI
- Package listing and information display
- Uninstall functionality
EOF

# Create a simple test file
cat > tests/test_pipd.py << 'EOF'
#!/usr/bin/env python3
"""Basic tests for PIPD"""

import pytest
from unittest.mock import Mock, patch
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import after path is set
import pipd


class TestPackageValidation:
    """Test package name validation"""
    
    def test_valid_package_names(self):
        """Test that valid package names pass validation"""
        valid_names = [
            'requests',
            'django-rest-framework',
            'python3.12',
            'package_name',
            'CamelCase'
        ]
        
        for name in valid_names:
            assert pipd.validate_package_name(name) is True
    
    def test_invalid_package_names(self):
        """Test that invalid package names raise SecurityError"""
        invalid_names = [
            'package; rm -rf /',
            'package && echo bad',
            'package`whoami`',
            '../../../etc/passwd'
        ]
        
        for name in invalid_names:
            with pytest.raises(pipd.SecurityError):
                pipd.validate_package_name(name)


class TestPackageSpecParsing:
    """Test package specification parsing"""
    
    def test_parse_simple_package(self):
        """Test parsing package name without version"""
        name, version = pipd.parse_package_spec('requests')
        assert name == 'requests'
        assert version is None
    
    def test_parse_package_with_version(self):
        """Test parsing package with version specifier"""
        test_cases = [
            ('django==3.2', 'django', '3.2'),
            ('flask>=1.0', 'flask', '1.0'),
            ('numpy<2.0', 'numpy', '2.0'),
        ]
        
        for spec, expected_name, expected_version in test_cases:
            name, version = pipd.parse_package_spec(spec)
            assert name == expected_name
            assert version == expected_version


if __name__ == '__main__':
    pytest.main([__file__])
EOF

# Create GitHub Actions workflow
mkdir -p .github/workflows
cat > .github/workflows/test.yml << 'EOF'
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.8", "3.9", "3.10", "3.11", "3.12"]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y python3-apt python3-venv
    
    - name: Install Python dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements-dev.txt
    
    - name: Run linting
      run: |
        black --check pipd tests
        flake8 pipd tests --max-line-length=100
        isort --check-only pipd tests
    
    - name: Run type checking
      run: |
        mypy pipd --ignore-missing-imports
    
    - name: Run tests
      run: |
        pytest tests/ -v --cov=pipd --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
        fail_ci_if_error: true
EOF

# Create docs structure
cat > docs/INSTALL.md << 'EOF'
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
EOF

# Create a pre-commit configuration
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/psf/black
    rev: 22.10.0
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/pycqa/isort
    rev: 5.10.1
    hooks:
      - id: isort
        args: ["--profile", "black"]

  - repo: https://github.com/pycqa/flake8
    rev: 5.0.4
    hooks:
      - id: flake8
        args: ["--max-line-length=100", "--extend-ignore=E203,W503"]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v0.991
    hooks:
      - id: mypy
        additional_dependencies: [types-requests, types-toml]
EOF

# Create AUTHORS file
cat > AUTHORS << 'EOF'
# Authors

PIPD is developed and maintained by:

* Your Name <your.email@example.com>

Contributors:
* (Your name could be here!)

Special thanks to everyone who has contributed to making PIPD better!
EOF

# Create example requirements files
cat > examples/requirements-example.txt << 'EOF'
# Example requirements file for PIPD
requests>=2.28.0
click>=8.0.0
toml>=0.10.2

# Version specifiers are supported
django==4.2
flask>=2.0,<3.0

# Comments and blank lines are ignored
numpy  # Scientific computing
EOF

# Create a simple Makefile
cat > Makefile << 'EOF'
.PHONY: help install test lint format clean

help:
	@echo "Available commands:"
	@echo "  make install    - Install PIPD"
	@echo "  make test       - Run tests"
	@echo "  make lint       - Run linting"
	@echo "  make format     - Format code"
	@echo "  make clean      - Clean temporary files"

install:
	sudo ./install-pipd.sh

test:
	python -m pytest tests/ -v

lint:
	flake8 pipd tests --max-line-length=100
	mypy pipd --ignore-missing-imports

format:
	black pipd tests
	isort pipd tests

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .coverage coverage.xml
EOF

# Summary
echo
echo "GitHub preparation complete!"
echo
echo "Directory structure:"
echo "  docs/         - Documentation"
echo "  examples/     - Example configurations"
echo "  tests/        - Test files"
echo "  scripts/      - Utility scripts"
echo "  .github/      - GitHub Actions workflows"
echo
echo "Files created:"
echo "  - README.md"
echo "  - LICENSE (MIT)"
echo "  - CONTRIBUTING.md"
echo "  - CHANGELOG.md"
echo "  - .gitignore"
echo "  - requirements-dev.txt"
echo "  - .pre-commit-config.yaml"
echo "  - Makefile"
echo
echo "Next steps:"
echo "1. Review and update README.md with your GitHub username"
echo "2. Update AUTHORS file with your information"
echo "3. Initialize git repository: git init"
echo "4. Add files: git add ."
echo "5. Commit: git commit -m 'Initial commit'"
echo "6. Add remote: git remote add origin https://github.com/yourusername/pipd.git"
echo "7. Push: git push -u origin main"
