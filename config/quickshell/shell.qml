import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
  id: root

  IpcHandler {
    id: ipc

    target: "bar"

    // The bar starts hidden, like waybar's "start_hidden": true.
    //
    //   qs ipc call -- bar show    (the `--` is required: `qs ipc` has its own
    //                              `show` subcommand that otherwise swallows it)
    //   qs ipc call bar hide
    //   qs ipc call bar toggle
    //   qs ipc prop get bar shown  -> "true" / "false"
    //
    // waybar could only ever offer `toggle`, because SIGUSR1 carries no state.
    property bool shown: false

    function show(): void {
      ipc.shown = true;
    }
    function hide(): void {
      ipc.shown = false;
    }
    function toggle(): void {
      ipc.shown = !ipc.shown;
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar

      required property var modelData

      screen: modelData
      visible: ipc.shown

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
