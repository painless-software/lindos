import darkdetect
import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
from gi.repository import Gdk, Gtk

from .rust_core import RustCore

APP_ID = "ai.lindos.LindosTrayApp"


class LindosTrayApp(Gtk.ApplicationWindow):
    """A borderless window with a text box that reacts on key strokes."""

    def __init__(self, app):
        super().__init__(application=app)

        self.set_title("Lindos Desktop Assistant")
        self.set_decorated(False)  # no title bar and borders
        self.set_default_size(300, 100)

        self.add_textbox()
        self.connect_keys()
        self.apply_theme(darkdetect.theme())

    def add_textbox(self):
        textbox = Gtk.Entry()
        textbox.connect("notify::text", self.on_text_changed)
        textbox.set_placeholder_text("Ask me anything...")
        textbox.set_hexpand(True)
        textbox.set_vexpand(False)

        vbox = Gtk.Box()
        vbox.append(textbox)
        self.set_child(vbox)

    def connect_keys(self):
        ctrl = Gtk.EventControllerKey()
        ctrl.connect("key-pressed", self.on_key_press)
        self.add_controller(ctrl)

    def apply_theme(self, theme: str):
        """Set background color based on the theme."""
        if theme == "Light":
            print("Light theme detected")
        elif theme == "Dark":
            print("Dark theme detected")
        else:
            msg = f"Unsupported theme '{theme}'"
            raise NotImplementedError(msg)

    def on_text_changed(self, widget, _):
        """Get the current text from the entry."""
        text = widget.get_text()
        self.call_external_library(text)

    def call_external_library(self, text):
        """Call the Rust core library to process the text."""
        if not text:
            return  # Don't process empty text

        result, error = RustCore.process_with_result(text)

        if error:
            print(f"Error processing message: {error.message}")
        else:
            print(f"Rust response: {result}")

    def on_key_press(self, widget, keyval, _, modifier):
        """Close application window on Escape key, Ctrl+Space, Ctrl+W, Ctrl+Q."""
        if (
            keyval == Gdk.KEY_Escape and modifier == Gdk.ModifierType.NO_MODIFIER_MASK
        ) or (
            modifier == Gdk.ModifierType.CONTROL_MASK
            and keyval in (Gdk.KEY_space, Gdk.KEY_q, Gdk.KEY_w)
        ):
            self.close()


def main():
    def on_activate(app):
        win = LindosTrayApp(app)
        win.present()

    app = Gtk.Application(application_id=APP_ID)
    app.connect("activate", on_activate)
    app.run(None)


if __name__ == "__main__":
    main()
