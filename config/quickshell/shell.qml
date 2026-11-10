import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
  id: root

  // the persistent property allows the barState to survive config reloads, without reapplying shown = false
  PersistentProperties {
    id: barState

    reloadableId: "barState"

    // start hidden on app start
    property bool shown: false
  }

  IpcHandler {
    id: ipc

    target: "bar"

    function show(): void {
      barState.shown = true;
    }
    function hide(): void {
      barState.shown = false;
    }
    function toggle(): void {
      barState.shown = !barState.shown;
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar

      required property var modelData

      screen: modelData
      visible: barState.shown

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

        BarText {
          text: ">>"
          color: Theme.logo
        }

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

        BarText {
          text: HerdrService.text
          color: Theme.herdr[HerdrService.agentClass] !== undefined ? Theme.herdr[HerdrService.agentClass] : Theme.herdr["unknown"]
        }

        BluetoothIndicator {}
        Volume {}
        NetworkIndicator {}
        Battery {}
      }
    }
  }
}
