.PHONY: help install lint format test run seed snapshot clean docs build full-build setup pre-commit

# Variables
PYTHON := python3.11
DBT := dbt
PROFILES_DIR := $(HOME)/.dbt

# Default target
help:
	@echo "Available targets:"
	@echo "  make setup             - Install all dependencies"
	@echo "  make install           - Install Python and dbt dependencies"
	@echo "  make seed              - Load seed data"
	@echo "  make bronze            - Run bronze layer models"
	@echo "  make silver            - Run silver layer models"
	@echo "  make gold              - Run gold layer models"
	@echo "  make run               - Run all models"
	@echo "  make test              - Run all tests"
	@echo "  make snapshot          - Run snapshots (SCD Type-2)"
	@echo "  make build             - Seed + Run + Test (dependency order)"
	@echo "  make full-build        - Clean + Seed + Run + Snapshot + Test"
	@echo "  make lint              - Run dbt parse and debug checks"
	@echo "  make format            - Format Python files with black/isort"
	@echo "  make docs              - Generate dbt documentation"
	@echo "  make serve-docs        - Serve dbt docs on localhost:8000"
	@echo "  make clean             - Clean target/ and dbt_packages/"
	@echo "  make pre-commit        - Install pre-commit hooks"
	@echo "  make validate          - Run all validation checks"
	@echo "  make dev-setup         - Full local development setup"

# Setup and installation
setup: install
	@echo "✓ Setup complete"

install:
	@echo "Installing dependencies..."
	$(PYTHON) -m pip install --upgrade pip
	pip install -r requirements.txt
	$(DBT) deps

pre-commit:
	@echo "Installing pre-commit hooks..."
	pre-commit install
	@echo "✓ Pre-commit hooks installed"

dev-setup: install pre-commit
	@echo "Creating .dbt directory..."
	mkdir -p ~/.dbt
	@echo "✓ Development environment ready"

# dbt commands
seed:
	@echo "Loading seed data..."
	$(DBT) seed --profiles-dir $(PROFILES_DIR)

bronze:
	@echo "Running bronze layer..."
	$(DBT) run --select "010_bronze" --profiles-dir $(PROFILES_DIR)

silver:
	@echo "Running silver layer..."
	$(DBT) run --select "020_silver" --profiles-dir $(PROFILES_DIR)

gold:
	@echo "Running gold layer..."
	$(DBT) run --select "030_gold" --profiles-dir $(PROFILES_DIR)

run: seed bronze silver gold
	@echo "✓ All models executed"

snapshot:
	@echo "Running snapshots..."
	$(DBT) snapshot --profiles-dir $(PROFILES_DIR)

test:
	@echo "Running tests..."
	$(DBT) test --profiles-dir $(PROFILES_DIR)

test-verbose:
	@echo "Running tests (verbose)..."
	$(DBT) test -v --profiles-dir $(PROFILES_DIR)

build:
	@echo "Building models (seed + run + test)..."
	$(DBT) build --profiles-dir $(PROFILES_DIR)

full-build: clean seed run snapshot test
	@echo "✓ Full pipeline complete"

# Code quality
lint:
	@echo "Linting dbt code..."
	$(DBT) parse --profiles-dir $(PROFILES_DIR)
	$(DBT) debug --profiles-dir $(PROFILES_DIR)

format:
	@echo "Formatting Python code..."
	black .
	isort .
	@echo "✓ Code formatted"

validate: lint test
	@echo "✓ Validation complete"

# Documentation
docs:
	@echo "Generating dbt documentation..."
	$(DBT) docs generate --profiles-dir $(PROFILES_DIR)

serve-docs:
	@echo "Starting dbt docs server on http://localhost:8000..."
	$(DBT) docs serve --profiles-dir $(PROFILES_DIR)

# Utility commands
clean:
	@echo "Cleaning dbt artifacts..."
	$(DBT) clean
	rm -rf target/ dbt_packages/ .dbt_workspace/

ls:
	@echo "Listing all dbt models..."
	$(DBT) ls --profiles-dir $(PROFILES_DIR)

ls-sources:
	@echo "Listing all dbt sources..."
	$(DBT) ls --resource-type source --profiles-dir $(PROFILES_DIR)

freshness:
	@echo "Checking source freshness..."
	$(DBT) source freshness --profiles-dir $(PROFILES_DIR)

# Layer-specific operations
test-bronze:
	$(DBT) test --select "bronze" --profiles-dir $(PROFILES_DIR)

test-silver:
	$(DBT) test --select "silver" --profiles-dir $(PROFILES_DIR)

test-gold:
	$(DBT) test --select "gold" --profiles-dir $(PROFILES_DIR)

# Cost optimization
compile:
	@echo "Compiling without running..."
	$(DBT) compile --profiles-dir $(PROFILES_DIR)

parse:
	@echo "Parsing project..."
	$(DBT) parse --profiles-dir $(PROFILES_DIR)

# Development workflow
dev: bronze silver test
	@echo "✓ Development build complete"

# Production-safe commands
prod-test: lint test
	@echo "✓ Production safety checks passed"

prod-build: clean build docs
	@echo "✓ Production build complete"

.DEFAULT_GOAL := help
