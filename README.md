# � Python Development Template

A modern Python project template following current best practices as of 2025.

## ✨ Features

- **Modern Python packaging** with `pyproject.toml`
- **Dependency management** with `uv` for faster dependency resolution
- **Code quality tools**: Ruff for linting and formatting, mypy for type checking
- **Pre-commit hooks** for automated code quality checks
- **Testing setup** with pytest and coverage reporting
- **UV environment** management
- **Makefile** for common development tasks

## 🛠️ Installation

### Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh

uv --version
```

### Quick Start

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

## 📝 License

MIT License - feel free to use this template for your projects!

---
