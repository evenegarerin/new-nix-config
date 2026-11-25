import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.Bar

Scope {
  id: root

  property bool shown: false
  property bool restoring: false
  property string summary: ""

  function restore() {
    root.restoring = true;
    applyProc.running = true;
    root.shown = false;
  }

  function skip() {
    skipProc.running = true;
    root.shown = false;
  }

  component DialogButton: Rectangle {
    id: btn

    property string label
    property color accent
    signal clicked

    implicitWidth: btnText.implicitWidth + 40
    implicitHeight: btnText.implicitHeight + 16
    radius: Theme.rounding
    color: btnMouse.containsMouse ? accent : Qt.rgba(1, 1, 1, 0.1)

    Text {
      id: btnText
      anchors.centerIn: parent
      text: btn.label
      color: Theme.fg
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
    }

    MouseArea {
      id: btnMouse
      anchors.fill: parent
      hoverEnabled: true
      onClicked: btn.clicked()
    }
  }

  IpcHandler {
    target: "sessionRestore"

    function ask(summary: string): void {
      root.summary = summary;
      root.shown = true;
    }
  }

  Process {
    id: applyProc
    command: ["systemctl", "--user", "start", "hyprland-session-restore-apply.service"]
    onExited: root.restoring = false
  }

  Timer {
    running: root.restoring
    interval: 120000
    onTriggered: root.restoring = false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      readonly property bool focused: Hyprland.focusedMonitor === Hyprland.monitorFor(modelData)

      screen: modelData
      visible: root.restoring
      color: Qt.rgba(0, 0, 0, 0.6)
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      WlrLayershell.namespace: "session-restore-overlay"

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
      }

      Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => event.accepted = true
      }

      Text {
        anchors.centerIn: parent
        text: "Restoring session…"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 20
        font.bold: true
      }
    }
  }

  Process {
    id: skipProc
    command: ["systemctl", "--user", "start", "hyprland-session-restore-skip.service"]
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: popup

      required property var modelData
      readonly property bool focused: Hyprland.focusedMonitor === Hyprland.monitorFor(modelData)

      screen: modelData
      visible: root.shown
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: focused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      WlrLayershell.namespace: "session-restore"

      implicitWidth: box.implicitWidth
      implicitHeight: box.implicitHeight

      onVisibleChanged: if (visible) box.forceActiveFocus()
      onFocusedChanged: if (visible && focused) box.forceActiveFocus()

      Rectangle {
        id: box

        anchors.fill: parent
        implicitWidth: content.implicitWidth + 60
        implicitHeight: content.implicitHeight + 60
        radius: Theme.rounding
        color: Theme.bg

        focus: true
        Keys.onPressed: event => {
          if (event.key === Qt.Key_R) {
            root.restore();
            event.accepted = true;
          } else if (event.key === Qt.Key_S || event.key === Qt.Key_Escape) {
            root.skip();
            event.accepted = true;
          }
        }

        Column {
          id: content

          anchors.centerIn: parent
          spacing: 20

          Text {
            text: "Restore last session?"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.bold: true
          }

          Text {
            text: root.summary
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 15

            DialogButton {
              label: "(R)estore"
              accent: Theme.disk
              onClicked: root.restore()
            }

            DialogButton {
              label: "(S)kip"
              accent: Theme.logo
              onClicked: root.skip()
            }
          }
        }
      }
    }
  }
}
