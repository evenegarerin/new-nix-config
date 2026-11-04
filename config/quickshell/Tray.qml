import QtQuick
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

    IconImage {
      required property var modelData

      source: modelData.icon
      implicitSize: 14
      // SNI "passive" items are the ones waybar hides.
      visible: modelData.status !== SystemTrayItem.Passive
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
