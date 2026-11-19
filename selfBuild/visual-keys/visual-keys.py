#!/usr/bin/env python
"""
heldkeys - show only the keys you are holding down right now (Wayland/X11).

Uses showmethekey-cli (from Show Me The Key) as the input backend, so it
works on Wayland. A key appears when pressed and disappears when released.
No history, no timeout.

Requirements: showmethekey, python3-gobject, GTK 4, membership in the "input" group
Run:          python3 heldkeys.py
"""

import json
import subprocess
import sys
import threading

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk  # noqa: E402
from gi.repository import Gtk4LayerShell as LayerShell  # noqa: E402

# ---- settings -------------------------------------------------------------
FONT_SIZE = 36  # px
FONT_FAMILY = '"JetBrainsMono Nerd Font", monospace'
BOTTOM_MARGIN = 60  # px above the bottom edge
HEIGHT_FACTOR = 1.5  # window height relative to the text height
SHOW_MOUSE = False  # also show mouse buttons while held
SEPARATOR = " + "
CLI = ["showmethekey-cli"]
# ---------------------------------------------------------------------------

NAMES = {
    "LEFTCTRL": "Ctrl",
    "RIGHTCTRL": "Ctrl",
    "LEFTSHIFT": "Shift",
    "RIGHTSHIFT": "Shift",
    "LEFTALT": "Alt",
    "RIGHTALT": "AltGr",
    "LEFTMETA": "Super",
    "RIGHTMETA": "Super",
    "ESC": "Esc",
    "ENTER": "Enter",
    "KPENTER": "Enter",
    "BACKSPACE": "⌫",
    "TAB": "Tab",
    "SPACE": "Space",
    "CAPSLOCK": "Caps",
    "DELETE": "Del",
    "INSERT": "Ins",
    "UP": "↑",
    "DOWN": "↓",
    "LEFT": "←",
    "RIGHT": "→",
    "PAGEUP": "PgUp",
    "PAGEDOWN": "PgDn",
    "HOME": "Home",
    "END": "End",
    "MINUS": "-",
    "EQUAL": "=",
    "LEFTBRACE": "[",
    "RIGHTBRACE": "]",
    "SEMICOLON": ";",
    "APOSTROPHE": "'",
    "GRAVE": "`",
    "BACKSLASH": "\\",
    "COMMA": ",",
    "DOT": ".",
    "SLASH": "/",
    "LEFT_BTN": "LMB",
    "RIGHT_BTN": "RMB",
    "MIDDLE_BTN": "MMB",
}
MODIFIER_ORDER = ["Ctrl", "Super", "Alt", "AltGr", "Shift"]


def pretty(raw):
    name = raw.removeprefix("KEY_").removeprefix("BTN_")
    if raw.startswith("BTN_"):
        name = name + "_BTN" if name in ("LEFT", "RIGHT", "MIDDLE") else name
    return NAMES.get(name, name.title() if len(name) > 1 else name)


class HeldKeys(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="local.heldkeys")
        self.held = []  # raw key names, in press order
        self.proc = None

    def do_activate(self):
        css = Gtk.CssProvider()
        css.load_from_string(f"""
            window {{ background: transparent; }}
            label {{
                font-family: {FONT_FAMILY};
                font-size: {FONT_SIZE}px; font-weight: bold; color: white;
                background: rgba(0,0,0,0.7);
            }}
        """)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.label = Gtk.Label()
        self.win = Gtk.ApplicationWindow(application=self, title="heldkeys")
        self.win.set_decorated(False)
        self.win.set_child(self.label)
        self.win.connect("close-request", self.on_close)

        LayerShell.init_for_window(self.win)
        LayerShell.set_layer(self.win, LayerShell.Layer.OVERLAY)
        LayerShell.set_anchor(self.win, LayerShell.Edge.BOTTOM, True)
        LayerShell.set_margin(self.win, LayerShell.Edge.BOTTOM, BOTTOM_MARGIN)
        LayerShell.set_keyboard_mode(self.win, LayerShell.KeyboardMode.NONE)
        LayerShell.set_namespace(self.win, "heldkeys")

        try:
            self.proc = subprocess.Popen(
                CLI, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True
            )
        except FileNotFoundError:
            sys.exit("showmethekey-cli not found - install Show Me The Key.")
        threading.Thread(target=self.read_events, daemon=True).start()

    def read_events(self):
        for line in self.proc.stdout:
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            if ev.get("event_name") == "POINTER_BUTTON" and not SHOW_MOUSE:
                continue
            GLib.idle_add(self.update, ev["key_name"], ev["state_name"])
        GLib.idle_add(self.quit)

    def update(self, key, state):
        if state == "PRESSED" and key not in self.held:
            self.held.append(key)
        elif state == "RELEASED" and key in self.held:
            self.held.remove(key)

        names = []
        for k in self.held:
            n = pretty(k)
            if n not in names:
                names.append(n)
        mods = [m for m in MODIFIER_ORDER if m in names]
        rest = [n for n in names if n not in MODIFIER_ORDER]
        text = SEPARATOR.join(mods + rest)

        self.label.set_text(text)

        if not text:
            self.win.set_visible(False)
            return False

        _, nat = self.label.get_preferred_size()

        height = round(nat.height * HEIGHT_FACTOR)

        self.win.set_size_request(nat.width + height, height)
        self.win.set_visible(True)
        return False

    def on_close(self, *_):
        if self.proc and self.proc.poll() is None:
            try:  # ask the backend to exit cleanly
                self.proc.stdin.write("stop\n")
                self.proc.stdin.flush()
            except BrokenPipeError:
                pass
        return False


if __name__ == "__main__":
    HeldKeys().run(sys.argv)
