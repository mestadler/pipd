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
