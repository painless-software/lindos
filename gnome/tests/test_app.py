"""Tests for the app module - verifying structure without runtime dependencies."""

from pathlib import Path

# Check that the app.py file exists and has correct structure
app_file = Path(__file__).parent.parent / "LindosTrayApp" / "app.py"


class TestAppModule:
    """Test that app module has correct structure."""

    def test_app_file_exists(self):
        """Test that app.py file exists."""
        assert app_file.exists()

    def test_app_has_correct_app_id(self):
        """Test that APP_ID is defined correctly in source."""
        content = app_file.read_text()
        assert 'APP_ID = "ai.lindos.LindosTrayApp"' in content

    def test_app_has_lindostrayapp_class(self):
        """Test that LindosTrayApp class is defined."""
        content = app_file.read_text()
        assert "class LindosTrayApp" in content

    def test_app_has_main_function(self):
        """Test that main function is defined."""
        content = app_file.read_text()
        assert "def main():" in content

    def test_app_has_required_methods(self):
        """Test that required methods are defined."""
        content = app_file.read_text()
        assert "def add_textbox(self):" in content
        assert "def connect_keys(self):" in content
        assert "def apply_theme(self, theme: str):" in content
        assert "def on_text_changed(self, widget, _):" in content
        assert "def call_external_library(self, text):" in content
        assert "def on_key_press(self, widget, keyval, _, modifier):" in content

    def test_app_imports_rust_core(self):
        """Test that app imports rust_core."""
        content = app_file.read_text()
        assert "from rust_core import RustCore" in content

    def test_app_imports_gtk(self):
        """Test that app imports Gtk correctly."""
        content = app_file.read_text()
        assert 'gi.require_version("Gtk", "4.0")' in content
        assert 'gi.require_version("Gdk", "4.0")' in content
