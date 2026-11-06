import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.SystemTray

// waybar: tray, icon-size 14, spacing 10
RowLayout {
  spacing: 10

  // keep the slab from reserving a gap when nothing is in the tray
  visible: SystemTray.items.values.length > 0

  Repeater {
    model: SystemTray.items

    Item {
      required property var modelData

      implicitWidth: trayIcon.implicitWidth
      implicitHeight: trayIcon.implicitHeight
      // SNI "passive" items are the ones waybar hides.
      visible: modelData.status !== SystemTrayItem.Passive
      Layout.alignment: Qt.AlignVCenter

      // the real icon, kept hidden: MultiEffect draws it instead
      IconImage {
        id: trayIcon

        source: modelData.icon
        implicitSize: 14
        visible: false
      }

      // black and white: drop all color, keep luminance
      MultiEffect {
        anchors.fill: trayIcon
        source: trayIcon
        saturation: -1.0
        brightness: Theme.trayBrightness
      }
    }
  }
}
