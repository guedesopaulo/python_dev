# Python Development Template

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
make deps         # Sync dependencies and install pre-commit hooks (uv sync + pre-commit install)
make check        # Run pre-commit hooks against all files
make test         # Run tests with pytest
make cov          # Run coverage (erase, run, and report)
make clean        # Clean cache and build artifacts
```

## 📝 License

MIT License - feel free to use this template for your projects!

---
