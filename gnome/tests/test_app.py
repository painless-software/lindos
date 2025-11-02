"""Tests for the GTK application module."""

import sys
from unittest.mock import MagicMock, patch

import pytest


# Setup Gtk mock with ApplicationWindow as a class that returns a proper mock
class MockApplicationWindow:
    def __init__(self, **kwargs):
        self.application = kwargs.get("application")

    def set_title(self, title):
        pass

    def set_decorated(self, decorated):
        pass

    def set_default_size(self, width, height):
        pass

    def set_child(self, child):
        pass

    def add_controller(self, controller):
        pass

    def close(self):
        pass


# Create proper mock for gi module
mock_gi = MagicMock()
mock_gdk = MagicMock()
mock_gtk = MagicMock()

mock_gtk.ApplicationWindow = MockApplicationWindow

mock_gi.repository.Gdk = mock_gdk
mock_gi.repository.Gtk = mock_gtk

sys.modules["gi"] = mock_gi
sys.modules["gi.repository"] = mock_gi.repository
sys.modules["gi.repository.Gdk"] = mock_gdk
sys.modules["gi.repository.Gtk"] = mock_gtk

# Now we can import the app module
from lindos.app import APP_ID, LindosTrayApp, main


@pytest.fixture
def mock_gtk_widgets():
    """Fixture to mock GTK widgets."""
    with patch("lindos.app.Gtk.Entry") as mock_entry_class:
        with patch("lindos.app.Gtk.Box") as mock_box_class:
            with patch("lindos.app.Gtk.EventControllerKey") as mock_ctrl_class:
                mock_entry = MagicMock()
                mock_box = MagicMock()
                mock_ctrl = MagicMock()

                mock_entry_class.return_value = mock_entry
                mock_box_class.return_value = mock_box
                mock_ctrl_class.return_value = mock_ctrl

                yield {
                    "entry_class": mock_entry_class,
                    "entry": mock_entry,
                    "box_class": mock_box_class,
                    "box": mock_box,
                    "ctrl_class": mock_ctrl_class,
                    "ctrl": mock_ctrl,
                }


def test_app_id_constant():
    """Test that APP_ID is correctly defined."""
    assert APP_ID == "ai.lindos.LindosTrayApp"


def test_lindos_tray_app_can_be_instantiated(mock_gtk_widgets):
    """Test that LindosTrayApp can be instantiated with a Gtk Application."""
    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        window = LindosTrayApp(mock_app)
        assert window is not None


def test_apply_theme_light(mock_gtk_widgets):
    """Test apply_theme with Light theme."""
    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        window = LindosTrayApp(mock_app)

        with patch("builtins.print") as mock_print:
            window.apply_theme("Light")
            mock_print.assert_called_once_with("Light theme detected")


def test_apply_theme_dark(mock_gtk_widgets):
    """Test apply_theme with Dark theme."""
    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Dark"):
        window = LindosTrayApp(mock_app)

        with patch("builtins.print") as mock_print:
            window.apply_theme("Dark")
            mock_print.assert_called_once_with("Dark theme detected")


def test_apply_theme_unsupported_raises_error(mock_gtk_widgets):
    """Test apply_theme with unsupported theme raises NotImplementedError."""
    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        window = LindosTrayApp(mock_app)

        with pytest.raises(NotImplementedError, match="Unsupported theme"):
            window.apply_theme("Unknown")


def test_on_text_changed_calls_external_library(mock_gtk_widgets):
    """Test that on_text_changed handler calls external library."""
    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        window = LindosTrayApp(mock_app)

        mock_widget = MagicMock()
        mock_widget.get_text.return_value = "test input"

        with patch.object(window, "call_external_library") as mock_call:
            window.on_text_changed(mock_widget, None)
            mock_call.assert_called_once_with("test input")


def test_call_external_library_with_empty_text(mock_gtk_widgets):
    """Test call_external_library with empty text doesn't call Rust."""
    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        with patch("lindos.app.RustCore") as mock_rust:
            window = LindosTrayApp(mock_app)
            window.call_external_library("")
            mock_rust.process_with_result.assert_not_called()


def test_call_external_library_success(mock_gtk_widgets):
    """Test call_external_library with successful processing."""
    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        with patch("lindos.app.RustCore") as mock_rust:
            mock_rust.process_with_result.return_value = ("result text", None)

            window = LindosTrayApp(mock_app)

            with patch("builtins.print") as mock_print:
                window.call_external_library("test input")
                mock_rust.process_with_result.assert_called_once_with("test input")
                mock_print.assert_called_once_with("Rust response: result text")


def test_call_external_library_with_error(mock_gtk_widgets):
    """Test call_external_library with error."""
    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        with patch("lindos.app.RustCore") as mock_rust:
            mock_error = MagicMock()
            mock_error.message = "Error occurred"
            mock_rust.process_with_result.return_value = (None, mock_error)

            window = LindosTrayApp(mock_app)

            with patch("builtins.print") as mock_print:
                window.call_external_library("test input")
                mock_rust.process_with_result.assert_called_once_with("test input")
                mock_print.assert_called_once_with(
                    "Error processing message: Error occurred"
                )


def test_on_key_press_escape_closes_window(mock_gtk_widgets):
    """Test on_key_press with Escape key closes window."""
    from lindos.app import Gdk

    Gdk.KEY_Escape = 65307
    Gdk.ModifierType.NO_MODIFIER_MASK = 0

    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        window = LindosTrayApp(mock_app)

        with patch.object(window, "close") as mock_close:
            window.on_key_press(None, Gdk.KEY_Escape, None, 0)
            mock_close.assert_called_once()


def test_on_key_press_ctrl_q_closes_window(mock_gtk_widgets):
    """Test on_key_press with Ctrl+Q closes window."""
    from lindos.app import Gdk

    Gdk.KEY_q = 113
    Gdk.ModifierType.CONTROL_MASK = 4

    mock_app = MagicMock()

    with patch("lindos.app.darkdetect.theme", return_value="Light"):
        window = LindosTrayApp(mock_app)

        with patch.object(window, "close") as mock_close:
            window.on_key_press(None, Gdk.KEY_q, None, 4)
            mock_close.assert_called_once()


def test_main_creates_and_runs_application():
    """Test that main function creates and runs the GTK application successfully."""
    with patch("lindos.app.Gtk.Application") as mock_gtk_app_class:
        mock_app = MagicMock()
        mock_gtk_app_class.return_value = mock_app

        main()

        # Verify app creation with correct ID
        mock_gtk_app_class.assert_called_once_with(application_id=APP_ID)

        # Verify app was connected to activate signal
        mock_app.connect.assert_called_once()
        assert mock_app.connect.call_args[0][0] == "activate"

        # Verify app was run
        mock_app.run.assert_called_once_with(None)


def test_main_activate_callback_creates_and_shows_window():
    """Test that the activate callback creates and presents window successfully."""
    with patch("lindos.app.Gtk.Application") as mock_gtk_app_class:
        with patch("lindos.app.LindosTrayApp") as mock_window_class:
            mock_app = MagicMock()
            mock_gtk_app_class.return_value = mock_app
            mock_window = MagicMock()
            mock_window_class.return_value = mock_window

            main()

            # Get the activate callback
            on_activate = mock_app.connect.call_args[0][1]

            # Call the activate callback
            on_activate(mock_app)

            # Verify window was created and presented
            mock_window_class.assert_called_once_with(mock_app)
            mock_window.present.assert_called_once()
