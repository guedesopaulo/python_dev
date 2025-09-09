# � Python Development Template

A modern Python project template following current best practices as of 2025.

## ✨ Features

- **Modern Python packaging** with `pyproject.toml` and `setup.cfg`
- **Dependency management** with `uv` for faster dependency resolution
- **Code quality tools**: Ruff for linting and formatting, mypy for type checking
- **Pre-commit hooks** for automated code quality checks
- **Testing setup** with pytest and coverage reporting
- **Conda environment** management
- **Makefile** for common development tasks

## 🛠️ Installation

### Quick Setup (Recommended)

```bash
# Run the default setup (creates env, syncs dependencies, installs pre-commit)
make
```

### Available Make Commands

```bash
make              # Default: setup environment, sync deps, install hooks
make req          # Update requirements.txt files from pyproject.toml
make test         # Run tests with pytest
make lint         # Run linting (ruff + mypy)
make format       # Format code with ruff
make clean        # Clean cache and build artifacts
make update-hooks # Update pre-commit hooks to latest versions
```

## 📋 Manual Installation

If you prefer to run commands manually:

```bash
# 1. Create and activate the Conda environment
conda env create -n python_dev -f environment.yml
conda activate python_dev

# 2. Lock base dependencies from pyproject.toml into requirements.txt
uv pip compile pyproject.toml -o requirements.txt

# 3. Lock extras (e.g. dev dependencies) into requirements-dev.txt
uv pip compile pyproject.toml -o requirements-dev.txt --extra dev

# 4. Sync dependencies exactly as locked into your environment
uv pip sync requirements-dev.txt

# 5. Install pre-commit hooks
pre-commit install
```

## 🔧 Development Workflow

1. **Add dependencies** to `pyproject.toml`
2. **Update requirements** with `make req`
3. **Sync environment** with `make sync-deps`
4. **Run tests** with `make test`
5. **Format code** with `make format`
6. **Check linting** with `make lint`

## 📦 Project Structure

```
├── src/
│   └── python_dev/          # Main package source code
├── tests/                   # Test files
├── pyproject.toml          # Modern Python project configuration
├── setup.cfg               # Legacy configuration (for compatibility)
├── environment.yml         # Conda environment specification
├── ruff.toml              # Ruff configuration
├── .pre-commit-config.yaml # Pre-commit hooks configuration
├── Makefile               # Development automation
└── README.md              # This file
```

## 🚀 Using This Template

1. **Clone or fork** this repository
2. **Update project metadata** in `pyproject.toml` and `setup.cfg`
3. **Rename the package** from `python_dev` to your project name:
   - Rename `src/python_dev/` directory
   - Update references in configuration files
4. **Add your dependencies** to `pyproject.toml`
5. **Run `make`** to set up the development environment

## 🧪 Testing

```bash
# Run all tests
make test

# Run tests with coverage report
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/test_specific.py
```

## 📋 Code Quality

This template includes automated code quality tools:

- **Ruff**: Fast Python linter and formatter (replaces flake8, isort, black)
- **mypy**: Static type checking
- **pre-commit**: Runs quality checks before each commit

## 🔄 Updating Dependencies

When you add new dependencies to `pyproject.toml`:

```bash
make req          # Updates requirements.txt files
make sync-deps    # Syncs your environment
```

## 📝 License

MIT License - feel free to use this template for your projects!

---

*Last updated: September 2025*
