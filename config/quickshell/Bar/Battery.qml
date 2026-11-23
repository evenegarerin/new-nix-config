import QtQuick
import Quickshell.Services.UPower

BarText {
  id: root

  readonly property var battery: UPower.displayDevice

  readonly property bool available: battery.ready && battery.isPresent && battery.isLaptopBattery

  readonly property int capacity: available ? Math.round(battery.percentage * 100) : -1
  readonly property bool charging: battery.state === UPowerDeviceState.Charging
  readonly property bool discharging: battery.state === UPowerDeviceState.Discharging

  readonly property bool warning: discharging && capacity <= 30
  readonly property bool critical: discharging && capacity <= 15

  readonly property int secondsLeft: battery.timeToEmpty
  readonly property string remaining: {
    if (!UPower.onBattery || secondsLeft <= 0)
      return "";
    if (secondsLeft < 3600)
      return " " + Math.round(secondsLeft / 60) + "m";
    return " " + Math.round(secondsLeft / 3600) + "h";
  }

  color: critical ? Theme.batteryCritical : warning ? Theme.batteryWarning : Theme.battery
  text: capacity < 0 ? "" : (charging ? "󰂄 " : "󰂀 ") + capacity + "%" + remaining

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
