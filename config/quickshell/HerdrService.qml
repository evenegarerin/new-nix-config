pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Polls herdr-agents.sh, which still emits the waybar JSON shape
// ({text, class, tooltip}). Only `text` and `class` are used here.
Singleton {
  id: root

  property string text: ""
  property string agentClass: "unknown"

  Process {
    id: proc
    command: [Quickshell.shellPath("herdr-agents.sh"), "status"]

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var json = JSON.parse(this.text);
          root.text = json.text || "";
          root.agentClass = json.class || "unknown";
        } catch (e) {
          root.text = "";
        }
      }
    }
  }

  Timer {
    interval: 2000 // waybar custom/herdr.interval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!proc.running)
      proc.running = true
  }
}
