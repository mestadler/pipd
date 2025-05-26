#!/bin/bash
# PIPD Installation Script
# Installs pipd and all its dependencies

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PIPD_VERSION="0.2.0"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/pipd"
LOG_DIR="/var/log/pipd"

# Python version configuration
RECOMMENDED_PYTHON="3.12"
MINIMUM_PYTHON="3.8"
DEFAULT_PYTHON=""

# Functions
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/debian_version ]]; then
        print_error "This script only supports Debian-based systems"
        exit 1
    fi
    
    print_status "Detected Debian-based system"
}

detect_python_versions() {
    print_status "Detecting available Python versions..."
    
    # Array to store available Python versions
    AVAILABLE_PYTHONS=()
    
    # Check for different Python versions
    for version in python3.{8..13} python3; do
        if command -v $version &> /dev/null; then
            actual_version=$($version -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
            AVAILABLE_PYTHONS+=("$version:$actual_version")
            print_info "Found $version (Python $actual_version)"
        fi
    done
    
    if [ ${#AVAILABLE_PYTHONS[@]} -eq 0 ]; then
        print_error "No Python 3 installation found!"
        print_error "Please install Python 3.8 or newer:"
        print_error "  sudo apt install python3"
        exit 1
    fi
}

select_python_version() {
    print_status "Selecting Python version for PIPD..."
    
    # Check if user specified a Python version via environment variable
    if [ ! -z "$PIPD_PYTHON" ]; then
        if command -v "$PIPD_PYTHON" &> /dev/null; then
            DEFAULT_PYTHON="$PIPD_PYTHON"
            print_status "Using user-specified Python: $DEFAULT_PYTHON"
            return
        else
            print_warning "Specified Python '$PIPD_PYTHON' not found, will prompt for selection"
        fi
    fi
    
    # Check for recommended version first
    for python_info in "${AVAILABLE_PYTHONS[@]}"; do
        python_cmd="${python_info%%:*}"
        python_ver="${python_info##*:}"
        if [ "$python_ver" = "$RECOMMENDED_PYTHON" ]; then
            DEFAULT_PYTHON="$python_cmd"
            print_status "Found recommended Python version $RECOMMENDED_PYTHON"
            return
        fi
    done
    
    # If recommended not found, prompt user
    echo
    echo "Available Python versions:"
    echo "========================="
    
    # Create selection menu
    PS3="Please select Python version to use for PIPD (1-${#AVAILABLE_PYTHONS[@]}): "
    select python_info in "${AVAILABLE_PYTHONS[@]}"; do
        if [ ! -z "$python_info" ]; then
            DEFAULT_PYTHON="${python_info%%:*}"
            python_ver="${python_info##*:}"
            
            # Warn about Python 3.13
            if [ "$python_ver" = "3.13" ]; then
                print_warning "Python 3.13 is very new and may have compatibility issues."
                print_warning "Some package conversion tools might not work properly."
                read -p "Continue with Python 3.13? (y/N) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_info "Please select another version."
                    continue
                fi
            fi
            
            print_status "Selected: $DEFAULT_PYTHON (Python $python_ver)"
            break
        else
            print_error "Invalid selection. Please try again."
        fi
    done
    
    # Verify minimum version
    python_ver="${python_info##*:}"
    if ! $DEFAULT_PYTHON -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
        print_error "Selected Python version is too old. Minimum required: Python $MINIMUM_PYTHON"
        exit 1
    fi
}

install_system_dependencies() {
    print_status "Installing system dependencies..."
    
    apt-get update
    
    # Core dependencies
    apt-get install -y \
        python3 \
        python3-pip \
        python3-apt \
        python3-setuptools \
        python3-wheel \
        python3-dev \
        python3-venv \
        build-essential
    
    # Additional dependencies for pipd
    apt-get install -y \
        python3-stdeb \
        python3-requests \
        python3-toml \
        dh-python \
        debhelper \
        fakeroot \
        dpkg-dev
    
    print_status "System dependencies installed"
}

install_python_dependencies() {
    print_status "Installing Python dependencies..."
    
    # Create a virtual environment for pipd's tools to avoid PEP 668 issues
    PIPD_VENV="/opt/pipd-venv"
    
    if [ ! -d "$PIPD_VENV" ]; then
        print_status "Creating pipd virtual environment..."
        python3 -m venv "$PIPD_VENV"
    fi
    
    # Activate the virtual environment
    source "$PIPD_VENV/bin/activate"
    
    # Upgrade pip in the virtual environment
    python3 -m pip install --upgrade pip
    
    # Install Poetry in the virtual environment
    if ! command -v poetry &> /dev/null; then
        print_status "Installing Poetry in pipd environment..."
        pip install poetry
    fi
    
    # Install py2deb and other tools
    pip install py2deb click stdeb
    
    # Deactivate virtual environment
    deactivate
    
    # Create wrapper scripts that use the virtual environment
    create_wrapper_scripts
    
    print_status "Python dependencies installed"
}

create_wrapper_scripts() {
    print_status "Creating wrapper scripts..."
    
    # Create wrapper for py2deb
    cat > /usr/local/bin/pipd-py2deb << 'EOF'
#!/bin/bash
source /opt/pipd-venv/bin/activate
exec py2deb "$@"
EOF
    chmod +x /usr/local/bin/pipd-py2deb
    
    # Create wrapper for poetry
    cat > /usr/local/bin/pipd-poetry << 'EOF'
#!/bin/bash
source /opt/pipd-venv/bin/activate
exec poetry "$@"
EOF
    chmod +x /usr/local/bin/pipd-poetry
    
    print_status "Wrapper scripts created"
}

create_directories() {
    print_status "Creating directories..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    
    # Create cache directory
    mkdir -p /var/cache/pipd
    chmod 755 /var/cache/pipd
    
    print_status "Directories created"
}

install_pipd() {
    print_status "Installing pipd..."
    
    # Download pipd script
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Look for pipd script in multiple locations
    PIPD_SCRIPT=""
    
    # Check common locations
    for location in "/tmp/pipd.py" "/tmp/pipd" "./pipd.py" "./pipd" "$HOME/pipd.py" "$HOME/pipd"; do
        if [[ -f "$location" ]]; then
            PIPD_SCRIPT="$location"
            print_status "Found pipd script at: $location"
            break
        fi
    done
    
    if [[ -z "$PIPD_SCRIPT" ]]; then
        print_error "pipd script not found!"
        print_error "Please ensure the pipd script is in one of these locations:"
        print_error "  - /tmp/pipd.py or /tmp/pipd"
        print_error "  - ./pipd.py or ./pipd (current directory)"
        print_error "  - ~/pipd.py or ~/pipd (home directory)"
        exit 1
    fi
    
    # Copy the script
    cp "$PIPD_SCRIPT" "$TEMP_DIR/pipd"
    
    # Ensure proper shebang
    if ! head -n 1 pipd | grep -q "^#!/usr/bin/env python3"; then
        print_status "Adding Python shebang..."
        echo '#!/usr/bin/env python3' > pipd.tmp
        cat pipd >> pipd.tmp
        mv pipd.tmp pipd
    fi
    
    # Make executable
    chmod +x pipd
    
    # Install to system
    install -m 755 pipd "$INSTALL_DIR/pipd"
    
    # Clean up
    cd /
    rm -rf "$TEMP_DIR"
    
    print_status "pipd installed to $INSTALL_DIR/pipd"
}

create_default_config() {
    print_status "Creating default configuration..."
    
    cat > "$CONFIG_DIR/config.toml" << 'EOF'
# PIPD Configuration File

[general]
# Prefer system packages over PyPI packages
prefer_system_packages = true

# Cache TTL in seconds
cache_ttl = 3600

# Verbose logging
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
cache_dir = "/var/cache/pipd"

# Log directory
log_dir = "/var/log/pipd"

# Temporary directory
temp_dir = "/tmp/pipd"
EOF

    chmod 644 "$CONFIG_DIR/config.toml"
    print_status "Default configuration created"
}

setup_logging() {
    print_status "Setting up logging..."
    
    # Create log rotation configuration
    cat > /etc/logrotate.d/pipd << 'EOF'
/var/log/pipd/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 root root
}
EOF

    print_status "Logging configured"
}

run_tests() {
    print_status "Running basic tests..."
    
    # Test pipd is accessible
    if ! command -v pipd &> /dev/null; then
        print_error "pipd command not found"
        return 1
    fi
    
    # Test pipd version
    if pipd --version | grep -q "$PIPD_VERSION"; then
        print_status "Version check passed"
    else
        print_warning "Version mismatch detected"
    fi
    
    # Test basic functionality
    if pipd list &> /dev/null; then
        print_status "Basic functionality test passed"
    else
        print_error "Basic functionality test failed"
        return 1
    fi
    
    return 0
}

create_uninstall_script() {
    print_status "Creating uninstall script..."
    
    cat > "$INSTALL_DIR/pipd-uninstall" << 'EOF'
#!/bin/bash
# PIPD Uninstall Script

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

echo "Uninstalling pipd..."

# Remove binary
rm -f /usr/local/bin/pipd

# Remove configuration
rm -rf /etc/pipd

# Remove logs
rm -rf /var/log/pipd

# Remove cache
rm -rf /var/cache/pipd

# Remove logrotate config
rm -f /etc/logrotate.d/pipd

# Remove uninstall script
rm -f /usr/local/bin/pipd-uninstall

# Remove virtual environment
rm -rf /opt/pipd-venv

# Remove wrapper scripts
rm -f /usr/local/bin/pipd-py2deb
rm -f /usr/local/bin/pipd-poetry

echo "pipd has been uninstalled successfully"
EOF

    chmod +x "$INSTALL_DIR/pipd-uninstall"
    print_status "Uninstall script created at $INSTALL_DIR/pipd-uninstall"
}

cleanup_on_error() {
    print_error "Installation failed. Cleaning up..."
    
    # Remove partial installation
    rm -f "$INSTALL_DIR/pipd"
    rm -rf /opt/pipd-venv
    rm -f /usr/local/bin/pipd-py2deb
    rm -f /usr/local/bin/pipd-poetry
    
    print_error "Cleanup complete. Please fix the issues and try again."
}

print_completion_message() {
    echo
    echo "========================================="
    echo -e "${GREEN}PIPD Installation Complete!${NC}"
    echo "========================================="
    echo
    echo "Installation Summary:"
    echo "  - pipd installed to: $INSTALL_DIR/pipd"
    echo "  - Configuration at: $CONFIG_DIR/config.toml"
    echo "  - Logs will be at: $LOG_DIR/"
    echo "  - Python version: $(python3 --version)"
    echo
    echo "Usage Examples:"
    echo "  pipd install requests"
    echo "  pipd install django==3.2"
    echo "  pipd list"
    echo "  pipd show requests"
    echo "  pipd uninstall requests"
    echo
    echo "To uninstall pipd, run:"
    echo "  sudo pipd-uninstall"
    echo
    echo "For help:"
    echo "  pipd --help"
    echo
}

# Set trap to cleanup on error
trap cleanup_on_error ERR

# Main installation flow
main() {
    echo "PIPD Installer v${PIPD_VERSION}"
    echo "============================="
    echo
    
    # Pre-flight checks
    check_root
    check_os
    
    # Python version selection
    detect_python_versions
    select_python_version
    
    echo
    print_info "Installation will proceed with: $DEFAULT_PYTHON"
    print_info "Press Enter to continue or Ctrl+C to cancel..."
    read
    
    # Installation steps
    install_system_dependencies
    install_python_dependencies
    create_directories
    install_pipd
    create_default_config
    setup_logging
    create_uninstall_script
    
    # Run tests
    if run_tests; then
        print_completion_message
    else
        print_error "Installation completed but tests failed"
        print_error "Please check the installation manually"
        print_warning "You can check the Python configuration with: pipd-python-info"
        exit 1
    fi
}

# Run main function
main "$@"
