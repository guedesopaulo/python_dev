"""Test the package import."""

import python_dev


def test_version() -> None:
    """Test that version is defined."""
    assert hasattr(python_dev, "__version__")
    assert python_dev.__version__ == "0.0.1"
