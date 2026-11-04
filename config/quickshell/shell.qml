import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
  id: root

  // waybar: "start_hidden": true. Toggled from hyprland with
  //   qs ipc call bar toggle
  // (waybar used `pkill -SIGUSR1 waybar` for the same thing).
  property bool barVisible: false

  IpcHandler {
    target: "bar"

    function toggle(): void {
      root.barVisible = !root.barVisible;
    }
    function show(): void {
      root.barVisible = true;
    }
    function hide(): void {
      root.barVisible = false;
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar

      required property var modelData

      screen: modelData
      visible: root.barVisible

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: Theme.barHeight
      color: "transparent"

      readonly property int sectionY: Theme.sectionTopMargin

      Section {
        edge: Section.Edge.Left
        y: bar.sectionY
        anchors.left: parent.left

        Logo {}
        Clock {}
        Disk {}
        Memory {}
        Cpu {}
        Temperature {}
        Submap {}
      }

      Section {
        edge: Section.Edge.Center
        y: bar.sectionY
        anchors.horizontalCenter: parent.horizontalCenter

        Workspaces {
          screen: bar.modelData
        }
      }

      Section {
        edge: Section.Edge.Right
        y: bar.sectionY
        anchors.right: parent.right

        Tray {}
        Herdr {}
        BluetoothIndicator {}
        Volume {}
        NetworkIndicator {}
        Battery {}
      }
    }
  }
}
