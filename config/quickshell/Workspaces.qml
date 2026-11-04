import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// waybar: hyprland/workspaces with all-outputs true. Workspaces living on
// another monitor are dimmed (style.css gives every button opacity .5 and
// only .hosting-monitor gets opacity 1).
RowLayout {
  id: root

  required property var screen

  readonly property var hyprMonitor: Hyprland.monitorFor(screen)

  spacing: Theme.moduleGap

  Repeater {
    model: ScriptModel {
      // Hyprland hands workspaces back in creation order; sort by id so the
      // bar does not reshuffle itself when a workspace is recreated.
      values: [...Hyprland.workspaces.values].sort((a, b) => a.id - b.id)
    }

    BarText {
      required property var modelData

      // waybar tracks a single active workspace globally rather than one
      // per output, so this follows `focused`, not `active`.
      text: modelData.focused ? "" : ""
      color: Theme.fg
      opacity: modelData.monitor === root.hyprMonitor ? 1.0 : 0.5
    }
  }
}
