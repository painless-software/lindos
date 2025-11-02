"""Lindos GNOME Tray Application."""

# Import only rust_core by default since it doesn't have GTK dependencies
from .rust_core import ProcessingError, RustCore, RustResult

__all__ = ["ProcessingError", "RustCore", "RustResult"]


def get_app_components():
    """Lazy import of app components that require GTK."""
    from .app import APP_ID, LindosTrayApp, main

    return APP_ID, LindosTrayApp, main
