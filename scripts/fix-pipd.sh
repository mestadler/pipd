#!/bin/bash
# Fix PIPD installation - wrong file was installed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Fixing PIPD Installation${NC}"
echo "========================"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Step 1: Check what's currently installed
echo -e "${GREEN}Step 1:${NC} Checking current installation..."
if [ -f /usr/local/bin/pipd ]; then
    echo "Current /usr/local/bin/pipd content (first 5 lines):"
    head -n 5 /usr/local/bin/pipd
    echo "..."
fi

# Step 2: Find the correct pipd Python script
echo -e "${GREEN}Step 2:${NC} Looking for the correct pipd Python script..."

PIPD_SCRIPT=""
# Look for the actual Python pipd script (the big one, not the bash scripts)
for location in ./pipd pipd.py ./pipd.py ~/pipd ~/pipd.py ~/DevOps/pipd/pipd ~/DevOps/pipd/pipd.py; do
    if [ -f "$location" ]; then
        # Check if it's the Python script by looking for Python imports
        if grep -q "import argparse\|import click\|from typing import" "$location" 2>/dev/null; then
            PIPD_SCRIPT="$location"
            echo -e "${GREEN}✓${NC} Found Python pipd script at: $location"
            # Show file size to confirm it's the right one
            ls -lh "$location"
            break
        fi
    fi
done

if [ -z "$PIPD_SCRIPT" ]; then
    echo -e "${RED}Could not find the pipd Python script!${NC}"
    echo "Please ensure the main pipd Python script is in the current directory."
    echo "It should be the large Python file (100+ KB) with all the pipd implementation."
    exit 1
fi

# Step 3: Backup current installation
echo -e "${GREEN}Step 3:${NC} Backing up current installation..."
if [ -f /usr/local/bin/pipd ]; then
    cp /usr/local/bin/pipd /usr/local/bin/pipd.backup
    echo "Backup saved to /usr/local/bin/pipd.backup"
fi

# Step 4: Install the correct script
echo -e "${GREEN}Step 4:${NC} Installing the correct pipd script..."
cp "$PIPD_SCRIPT" /usr/local/bin/pipd
chmod +x /usr/local/bin/pipd

# Step 5: Verify it's a Python script
echo -e "${GREEN}Step 5:${NC} Verifying installation..."
if head -n 1 /usr/local/bin/pipd | grep -q "python"; then
    echo -e "${GREEN}✓${NC} Shebang line looks correct"
else
    echo -e "${YELLOW}Adding Python shebang...${NC}"
    # Add shebang if missing
    if ! grep -q "^#!" /usr/local/bin/pipd; then
        echo '#!/usr/bin/env python3' > /tmp/pipd.tmp
        cat /usr/local/bin/pipd >> /tmp/pipd.tmp
        mv /tmp/pipd.tmp /usr/local/bin/pipd
        chmod +x /usr/local/bin/pipd
    fi
fi

# Step 6: Test the installation
echo -e "${GREEN}Step 6:${NC} Testing pipd..."
echo "Python version being used:"
/usr/bin/env python3 --version

echo -e "\nTesting pipd --version:"
if pipd --version 2>&1 | grep -q "0.2.0\|pipd"; then
    echo -e "${GREEN}✓${NC} Version check passed"
else
    echo -e "${YELLOW}⚠${NC} Version check output:"
    pipd --version 2>&1 || true
fi

echo -e "\nTesting pipd --help:"
if pipd --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Help command works"
else
    echo -e "${RED}✗${NC} Help command failed"
fi

echo -e "\nTesting pipd list:"
if pipd list >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} List command works"
else
    echo -e "${YELLOW}⚠${NC} List command failed (this might be normal if not running as root)"
fi

# Step 7: Show file info
echo -e "\n${GREEN}Step 7:${NC} Installation summary:"
echo "Installed file: /usr/local/bin/pipd"
ls -lh /usr/local/bin/pipd
echo "File type:"
file /usr/local/bin/pipd
echo "First few lines:"
head -n 10 /usr/local/bin/pipd

echo
echo -e "${GREEN}✓ Fix complete!${NC}"
echo
echo "PIPD should now be properly installed."
echo "Try running:"
echo "  pipd --help"
echo "  sudo pipd list"
