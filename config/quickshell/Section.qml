import QtQuick
import QtQuick.Layouts

// One of the three rounded slabs the bar is made of. Mirrors waybar's
// .modules-left / .modules-center / .modules-right rules: the two outer
// slabs sit flush against the screen edge and keep that edge square.
Rectangle {
  id: root

  enum Edge {
    Left,
    Center,
    Right
  }

  property int edge: Section.Edge.Center
  property real padding: edge === Section.Edge.Center ? Theme.centerPadding : Theme.sectionPadding
  property real gap: edge === Section.Edge.Center ? Theme.centerGap : Theme.moduleGap

  // anything you put inside Section {} goes into the row
  default property alias content: row.data

  // children widths + gaps * (count - 1) + padding on both sides
  implicitWidth: row.implicitWidth + padding * 2
  implicitHeight: Theme.rowHeight

  // Collapse the slab entirely when every module inside it is hidden,
  // so an empty group leaves no floating black box behind.
  visible: row.implicitWidth > 0

  readonly property real rounding: Theme.rounding

  topLeftRadius: edge === Section.Edge.Left ? 0 : rounding
  bottomLeftRadius: edge === Section.Edge.Left ? 0 : rounding
  topRightRadius: edge === Section.Edge.Right ? 0 : rounding
  bottomRightRadius: edge === Section.Edge.Right ? 0 : rounding

  color: Theme.bg

  RowLayout {
    id: row
    anchors.fill: parent
    anchors.leftMargin: root.padding
    anchors.rightMargin: root.padding
    spacing: root.gap
  }
}
