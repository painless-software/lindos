import darkdetect
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk

from rust_core import RustCore


class LindosTrayApp(Gtk.Window):
    def __init__(self):
        """A borderless window with a text box that reacts on key strokes."""
        super().__init__(title=None)
        self.set_decorated(False)  # no title bar and borders
        self.set_default_size(300, 100)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)

        self.text_entry = Gtk.Entry()
        self.text_entry.set_placeholder_text("Ask me anything...")
        self.text_entry.connect("changed", self.on_text_changed)
        vbox.pack_start(self.text_entry, True, True, 0)

        self.connect("key-press-event", self.on_key_press)

        self.apply_theme(darkdetect.theme())

    def apply_theme(self, theme: str):
        """Set background color based on the theme."""
        if theme == "Light":
            print("Light theme detected")
        elif theme == "Dark":
            print("Dark theme detected")
        else:
            raise NotImplementedError(f"Unsupported theme '{theme}'")

    def on_text_changed(self, widget):
        """Get the current text from the entry."""
        text = widget.get_text()
        self.call_external_library(text)

    def call_external_library(self, text):
        """Call the Rust core library to process the text."""
        if not text:
            # Don't process empty text
            return
        
        # Process the message using Rust core
        result, error = RustCore.process_with_result(text)
        
        if error:
            print(f"Error processing message: {error.message}")
        else:
            print(f"Rust response: {result}")

    def on_key_press(self, widget, key_event):
        """Close application window on Escape key or Ctrl+Space."""
        if key_event.keyval == Gdk.KEY_Escape or (
            key_event.keyval == Gdk.KEY_space
            and key_event.state & Gdk.ModifierType.CONTROL_MASK
        ):
            self.close()


win = LindosTrayApp()
win.connect("destroy", Gtk.main_quit)
win.show_all()
Gtk.main()
