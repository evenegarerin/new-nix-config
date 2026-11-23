import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Bar

PanelWindow {
  id: win

  property var held: []

  readonly property var names: ({
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
    "SLASH": "/"
  })
  readonly property var modOrder: ["Ctrl", "Super", "Alt", "AltGr", "Shift"]

  function pretty(raw) {
    const n = raw.replace(/^KEY_/, "");
    if (names[n] !== undefined)
      return names[n];
    return n.length > 1 ? n[0] + n.slice(1).toLowerCase() : n;
  }

  readonly property string label: {
    const uniq = [];
    for (const k of held) {
      const p = pretty(k);
      if (!uniq.includes(p))
        uniq.push(p);
    }
    const mods = modOrder.filter(m => uniq.includes(m));
    const rest = uniq.filter(n => !modOrder.includes(n));
    return mods.concat(rest).join(" + ");
  }

  visible: label !== ""
  color: "transparent"
  anchors.bottom: true
  margins.bottom: 60
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.namespace: "visual-keys"
  mask: Region {}

  implicitHeight: Math.round(keys.implicitHeight * 1.5)
  implicitWidth: keys.implicitWidth + implicitHeight

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.7)

    Text {
      id: keys
      anchors.centerIn: parent
      text: win.label
      color: "white"
      font.family: Theme.fontFamily
      font.pixelSize: 36
      font.bold: true
    }
  }

  Process {
    running: true
    command: ["showmethekey-cli"]

    stdout: SplitParser {
      onRead: line => {
        let ev;
        try {
          ev = JSON.parse(line);
        } catch (e) {
          return;
        }
        if (ev.event_name === "POINTER_BUTTON")
          return;
        const h = win.held.slice();
        const i = h.indexOf(ev.key_name);
        if (ev.state_name === "PRESSED" && i < 0)
          h.push(ev.key_name);
        else if (ev.state_name === "RELEASED" && i >= 0)
          h.splice(i, 1);
        else
          return;
        win.held = h;
      }
    }
  }
}
