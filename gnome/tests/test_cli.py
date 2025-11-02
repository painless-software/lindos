"""
Tests for command line interface (CLI).
"""

import shutil
from importlib import import_module


def test_main_module():
    """Partially simulate execution of ``python -m lindos``."""
    import_module("lindos.__main__")


def test_entrypoint():
    """Is entrypoint script installed? (pyproject.toml)"""
    assert shutil.which("lindos-tray-app")
