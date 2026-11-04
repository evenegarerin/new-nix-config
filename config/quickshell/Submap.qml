import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

// waybar: hyprland/submap. Quickshell exposes no submap property, so follow
// the `submap>>` event; hyprland sends it with an empty payload on exit.
BarText {
  id: root

  property string submap: ""

  // set once a real submap event has been seen, so the startup probe below
  // can never overwrite fresher state
  property bool live: false

  text: submap
  color: Theme.fg
  font.pixelSize: Math.round(Theme.fontSize * 1.1) // style.css: #submap font-size 110%

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name === "submap") {
        root.submap = event.data;
        root.live = true;
      }
    }
  }

  // The event stream only reports changes, so a shell started inside a
  // submap would show nothing until the next switch. Seed it once.
  Process {
    running: true
    command: ["hyprctl", "submap"]

    stdout: StdioCollector {
      onStreamFinished: {
        if (root.live)
          return;
        var current = this.text.trim();
        root.submap = current === "default" ? "" : current;
      }
    }
  }
}
