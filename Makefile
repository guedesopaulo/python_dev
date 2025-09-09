# === Configuration ===
ENV_PATH := $(shell pwd)
ENV_NAME := $(notdir $(ENV_PATH))

# Check if conda env exists
CONDA_ENV_EXISTS := $(shell conda env list | grep -w $(ENV_NAME))

# === Default Target ===
.PHONY: all
all: ensure-env req sync-deps install-hooks

# === Ensure Conda Environment Exists ===
.PHONY: ensure-env
ensure-env:
ifeq ($(CONDA_ENV_EXISTS),)
	@echo "🧪 Conda env '$(ENV_NAME)' not found. Creating from environment.yml..."
	conda env create -n $(ENV_NAME) -f environment.yml
else
	@echo "✅ Conda env '$(ENV_NAME)' already exists."
endif

# === Sync dependencies from requirements-dev.txt ===
.PHONY: sync-deps
sync-deps: req
	@echo "🔄 Syncing dependencies from requirements-dev.txt..."
	conda run -n $(ENV_NAME) uv pip sync requirements-dev.txt

# === Install pre-commit if not installed ===
.PHONY: install-hooks
install-hooks:
	@echo "🔍 Checking if pre-commit is installed..."
	@conda run -n $(ENV_NAME) pre-commit --version >/dev/null 2>&1 || \
		( echo "⚠️  pre-commit not installed. Installing..."; conda run -n $(ENV_NAME) pip install pre-commit )
	@echo "✅ Installing pre-commit hooks..."
	conda run -n $(ENV_NAME) pre-commit install

# === Update requirements.txt and requirements-dev.txt ===
.PHONY: req
req: ensure-env
	@echo "📦 Updating requirements.txt and requirements-dev.txt from pyproject.toml..."
	conda run -n $(ENV_NAME) uv pip compile pyproject.toml -o requirements.txt
	conda run -n $(ENV_NAME) uv pip compile pyproject.toml -o requirements-dev.txt --extra dev

# === Run tests ===
.PHONY: test
test: ensure-env
	@echo "🧪 Running tests..."
	conda run -n $(ENV_NAME) pytest

# === Run linting ===
.PHONY: lint
lint: ensure-env
	@echo "🔍 Running linting..."
	conda run -n $(ENV_NAME) ruff check .
	conda run -n $(ENV_NAME) mypy .

# === Format code ===
.PHONY: format
format: ensure-env
	@echo "🎨 Formatting code..."
	conda run -n $(ENV_NAME) ruff format .
	conda run -n $(ENV_NAME) ruff check --fix .

# === Clean cache and build artifacts ===
.PHONY: clean
clean:
	@echo "🧹 Cleaning cache and build artifacts..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +
	rm -rf build/ dist/ htmlcov/ .coverage

# === Update pre-commit hooks ===
.PHONY: update-hooks
update-hooks: ensure-env
	@echo "🔄 Updating pre-commit hooks..."
	conda run -n $(ENV_NAME) pre-commit autoupdate
