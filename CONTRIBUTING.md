# Contributing to PIPD

Thank you for your interest in contributing to PIPD! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect differing viewpoints and experiences

## How to Contribute

### Reporting Issues

1. Check if the issue already exists
2. Create a new issue with a clear title and description
3. Include:
   - Your OS version (`cat /etc/os-release`)
   - Python version (`python3 --version`)
   - PIPD version (`pipd --version`)
   - Steps to reproduce the issue
   - Expected vs actual behavior

### Suggesting Features

1. Open a discussion in the "Ideas" category
2. Describe the feature and its use case
3. Explain how it fits with PIPD's goals

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`python -m pytest`)
6. Update documentation as needed
7. Commit with clear messages (`git commit -m 'Add amazing feature'`)
8. Push to your fork (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## Development Setup

### Prerequisites

- Python 3.8+
- Debian-based system for full testing
- Git

### Setting Up Your Environment

```bash
# Clone your fork
git clone https://github.com/yourusername/pipd.git
cd pipd

# Add upstream remote
git remote add upstream https://github.com/originalowner/pipd.git

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install development dependencies
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install
```

### Running Tests

```bash
# Run all tests
python -m pytest

# Run with coverage
python -m pytest --cov=pipd

# Run specific test file
python -m pytest tests/test_resolver.py

# Run in verbose mode
python -m pytest -v
```

### Code Style

We use:
- **Black** for code formatting
- **isort** for import sorting
- **flake8** for linting
- **mypy** for type checking

Run all checks:
```bash
# Format code
black pipd tests

# Sort imports
isort pipd tests

# Lint
flake8 pipd tests

# Type check
mypy pipd
```

### Testing Guidelines

1. Write tests for all new functionality
2. Maintain or improve code coverage
3. Test edge cases and error conditions
4. Use meaningful test names
5. Mock external dependencies (apt, subprocess, etc.)

Example test:
```python
def test_validate_package_name_with_invalid_characters():
    """Test that invalid package names raise SecurityError"""
    with pytest.raises(SecurityError):
        validate_package_name("package; rm -rf /")
```

## Project Structure

```
pipd/
├── pipd                    # Main executable
├── install-pipd.sh         # Installation script
├── tests/                  # Test files
│   ├── test_resolver.py
│   ├── test_debian.py
│   └── ...
├── docs/                   # Documentation
├── examples/              # Example configurations
└── scripts/               # Utility scripts
```

## Commit Message Guidelines

Follow the conventional commits specification:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Test additions or modifications
- `chore:` Maintenance tasks

Examples:
```
feat: add support for pip install --user equivalent
fix: handle spaces in package names correctly
docs: update installation instructions for Ubuntu 24.04
```

## Release Process

1. Update version in `pipd` (`__version__`)
2. Update CHANGELOG.md
3. Create release PR
4. After merge, tag the release
5. GitHub Actions will handle the rest

## Getting Help

- Check existing issues and discussions
- Join our chat (if available)
- Ask in the PR or issue

## Recognition

Contributors will be recognized in:
- The project README
- Release notes
- The AUTHORS file

Thank you for contributing to PIPD!
