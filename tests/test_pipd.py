#!/usr/bin/env python3
"""Tests for PIPD"""

import pytest
from unittest.mock import Mock, patch, MagicMock
import sys
import os
import subprocess
import tempfile

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class TestPackageValidation:
    """Test package name validation"""
    
    def test_valid_package_names(self):
        """Test that valid package names pass validation"""
        # Import here to avoid issues if pipd isn't in path
        import pipd
        
        valid_names = [
            'requests',
            'django-rest-framework',
            'python3.12',
            'package_name',
            'CamelCase',
            'package.with.dots',
            'package-with-dashes'
        ]
        
        for name in valid_names:
            assert pipd.validate_package_name(name) is True
    
    def test_invalid_package_names(self):
        """Test that invalid package names raise SecurityError"""
        import pipd
        
        invalid_names = [
            'package; rm -rf /',
            'package && echo bad',
            'package`whoami`',
            '../../../etc/passwd',
            'package|cat /etc/passwd',
            'package\necho bad',
            'package$(date)',
        ]
        
        for name in invalid_names:
            with pytest.raises(pipd.SecurityError):
                pipd.validate_package_name(name)


class TestPackageSpecParsing:
    """Test package specification parsing"""
    
    def test_parse_simple_package(self):
        """Test parsing package name without version"""
        import pipd
        
        name, version = pipd.parse_package_spec('requests')
        assert name == 'requests'
        assert version is None
    
    def test_parse_package_with_version(self):
        """Test parsing package with version specifier"""
        import pipd
        
        test_cases = [
            ('django==3.2', 'django', '3.2'),
            ('flask>=1.0', 'flask', '1.0'),
            ('numpy<2.0', 'numpy', '2.0'),
            ('scipy<=1.5', 'scipy', '1.5'),
            ('pandas>1.0', 'pandas', '1.0'),
            ('matplotlib~=3.0', 'matplotlib', '3.0'),
        ]
        
        for spec, expected_name, expected_version in test_cases:
            name, version = pipd.parse_package_spec(spec)
            assert name == expected_name
            assert version == expected_version


class TestConfig:
    """Test configuration management"""
    
    @patch('os.path.exists')
    @patch('builtins.open', create=True)
    def test_default_config(self, mock_open, mock_exists):
        """Test loading default configuration"""
        import pipd
        
        mock_exists.return_value = False
        config = pipd.Config()
        
        assert config.get('general.prefer_system_packages') is True
        assert config.get('general.cache_ttl') == 3600
        assert config.get('security.safe_mode') is True
    
    def test_get_nested_values(self):
        """Test getting nested configuration values"""
        import pipd
        
        config = pipd.Config()
        assert config.get('paths.cache_dir') == '~/.cache/pipd'
        assert config.get('nonexistent.path') is None
        assert config.get('nonexistent.path', 'default') == 'default'


class TestCachedDecorator:
    """Test caching functionality"""
    
    def test_cache_hit(self):
        """Test that cache returns cached value"""
        import pipd
        
        call_count = 0
        
        @pipd.cached(ttl=60)
        def test_function(x):
            nonlocal call_count
            call_count += 1
            return x * 2
        
        # First call
        result1 = test_function(5)
        assert result1 == 10
        assert call_count == 1
        
        # Second call should use cache
        result2 = test_function(5)
        assert result2 == 10
        assert call_count == 1  # No additional call
        
        # Different argument should cause new call
        result3 = test_function(3)
        assert result3 == 6
        assert call_count == 2


class TestTransaction:
    """Test transaction management"""
    
    def test_transaction_rollback(self):
        """Test that rollback works correctly"""
        import pipd
        
        transaction = pipd.InstallationTransaction()
        
        # Record some operations
        transaction.record_package_installation('test-package')
        transaction.record_file_creation('/tmp/test-file')
        
        # Transaction should not be successful yet
        assert transaction.successful is False
        
        # After commit, should be successful
        transaction.commit()
        assert transaction.successful is True


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
