import QtQuick
import Quickshell.Io

// waybar: battery. UPower is not enabled on this host, so the values come
// straight from sysfs the way waybar reads them.
BarText {
  id: root

  property string sysfsPath: "/sys/class/power_supply/BAT0"

  property int capacity: -1
  property string status: ""

  // waybar only swaps in format-charging while the battery is actually
  // charging; "Full" has no format-full here, so it falls back to format.
  readonly property bool charging: status === "Charging"
  // waybar states: good 70, warning 30, critical 15
  readonly property bool warning: !charging && capacity <= 30
  readonly property bool critical: !charging && capacity <= 15

  color: critical ? Theme.batteryCritical : warning ? Theme.batteryWarning : Theme.battery
  text: capacity < 0 ? "" : (charging ? "󰂄 " : "󰂀 ") + capacity + "%"

  FileView {
    id: capacityFile
    path: root.sysfsPath + "/capacity"
    blockLoading: true
    printErrors: false
    onLoaded: root.capacity = parseInt(text().trim())
    onLoadFailed: root.capacity = -1
  }

  FileView {
    id: statusFile
    path: root.sysfsPath + "/status"
    blockLoading: true
    printErrors: false
    onLoaded: root.status = text().trim()
  }

  Timer {
    interval: 1000 // waybar battery.interval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      capacityFile.reload();
      statusFile.reload();
    }
  }

  // style.css: #battery.critical:not(.charging) blinks once per second
  SequentialAnimation on opacity {
    running: root.critical
    loops: Animation.Infinite
    alwaysRunToEnd: true

    NumberAnimation {
      to: 0.4
      duration: 1000
    }
    NumberAnimation {
      to: 1.0
      duration: 1000
    }
  }
}
