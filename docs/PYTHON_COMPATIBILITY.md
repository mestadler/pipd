# Python Version Compatibility

## Recommended Python Versions

- **Python 3.12**: Best compatibility with all features ✅
- **Python 3.11**: Excellent compatibility ✅
- **Python 3.10**: Good compatibility ✅
- **Python 3.8-3.9**: Supported ✅

## Python 3.13 Notes

Python 3.13 is very new (released October 2024) and some package conversion tools have compatibility issues:

- **py2deb**: ❌ Not compatible (missing 'symbol' and 'pipes' modules)
- **stdeb**: ✅ Works perfectly as fallback
- **wheel conversion**: ✅ Works as final fallback
- **minimal deb**: ✅ Works as last resort

PIPD handles this gracefully by automatically falling back to working methods.

### Known Python 3.13 Issues

1. **pip in virtual environments**: Older pip versions have issues with Python 3.13's restructured modules
2. **py2deb**: Depends on deprecated `pipes` module removed in Python 3.13
3. **Some build tools**: May have compatibility issues

Despite these issues, PIPD successfully installs packages using its fallback methods.

## Package Conversion Methods

PIPD tries multiple methods in order:

1. **py2deb** (fastest, but requires Python ≤ 3.12)
   - Best for complex packages with many dependencies
   - Handles dependency resolution well
   - Not available on Python 3.13

2. **stdeb** (reliable, works with most packages)
   - Works with Python 3.13
   - Good for packages with setup.py
   - Handles most standard packages

3. **wheel-to-deb conversion** (for wheel-only packages)
   - Direct conversion of wheel files
   - Works with all Python versions
   - Good for pure Python packages

4. **minimal deb creation** (last resort)
   - Creates basic .deb package
   - Always works
   - May miss some dependencies

## Real-World Testing

PIPD has been tested with Python 3.13 installing various packages:

- ✅ **deepfilternet**: Installed successfully using stdeb fallback
- ✅ **requests**: Installs from Debian repos (python3-requests)
- ✅ **rich**: Installs from Debian repos (python3-rich)
- ✅ **cowsay**: Installs from Debian repos

## Installation Recommendations

### For Full Feature Support

```bash
# Install Python 3.12
sudo ./install-python312-debian.sh

# Use Python 3.12 with PIPD
sudo PIPD_PYTHON=python3.12 ./install-pipd.sh
```

### For Python 3.13 Users

```bash
# PIPD will work but with limited conversion tools
sudo ./install-pipd.sh

# The installer will warn about Python 3.13 limitations
# but PIPD will still function using fallback methods
```

## Version Detection

The PIPD installer automatically detects available Python versions and will:
1. Recommend Python 3.12 if available
2. Warn about Python 3.13 limitations
3. Allow you to choose your preferred version

## Future Compatibility

As the Python ecosystem catches up with Python 3.13:
- py2deb may be updated to support Python 3.13
- New conversion tools may become available
- PIPD will automatically use them when available

## Troubleshooting Version Issues

### Checking Your Setup

```bash
# Check Python version
python3 --version

# Check PIPD's Python version
head -1 /usr/local/bin/pipd

# Check available conversion tools
pipd-py2deb --help 2>&1 || echo "py2deb not available"
```

### Switching Python Versions

```bash
# Reinstall PIPD with a different Python version
sudo PIPD_PYTHON=python3.11 ./install-pipd.sh
```

## Summary

- **Best Experience**: Use Python 3.12
- **Good Experience**: Use Python 3.8-3.11
- **Works with Limitations**: Python 3.13 (uses fallback methods)

Even with Python 3.13, PIPD successfully installs packages by gracefully falling back to alternative conversion methods. The tool is designed to be resilient and adaptive to different Python environments.
