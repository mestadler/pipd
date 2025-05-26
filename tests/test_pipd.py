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
