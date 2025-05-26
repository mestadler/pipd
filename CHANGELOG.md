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
