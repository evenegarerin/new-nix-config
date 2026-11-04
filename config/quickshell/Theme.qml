pragma Singleton

import Quickshell
import QtQuick

// Single source of truth for the bar's geometry, fonts and palette.
// Values mirror config/waybar/style.css one for one.
Singleton {
  // --- geometry -------------------------------------------------------
  // Measured against the running waybar: its slabs are 33px tall, sit 2px
  // below the top of a 35px bar and run flush into both screen edges.
  readonly property int rowHeight: 33
  readonly property int sectionTopMargin: 2 // .modules-* margin-top
  readonly property int barHeight: rowHeight + sectionTopMargin

  // .modules-left/right padding 0 10px + per-module padding 0 5px
  readonly property int sectionPadding: 15
  // .modules-center padding 0 15px + per-module padding 0 5px
  readonly property int centerPadding: 20
  // two adjacent modules each contribute 5px of padding
  readonly property int moduleGap: 10
  readonly property int rounding: 15

  // --- typography -----------------------------------------------------
  readonly property string fontFamily: "JetBrainsMono Nerd Font"
  readonly property int fontSize: 14

  // --- palette --------------------------------------------------------
  readonly property color bg: Qt.rgba(0, 0, 0, 0.8)
  readonly property color fg: "whitesmoke"

  readonly property color logo: Qt.rgba(250 / 255, 95 / 255, 95 / 255, 0.6)
  readonly property color clock: Qt.rgba(95 / 255, 209 / 255, 250 / 255, 0.6)
  readonly property color disk: Qt.rgba(95 / 255, 250 / 255, 147 / 255, 0.6)
  readonly property color memory: Qt.rgba(237 / 255, 95 / 255, 250 / 255, 0.6)
  readonly property color cpu: Qt.rgba(250 / 255, 196 / 255, 95 / 255, 0.6)
  readonly property color temperature: Qt.rgba(250 / 255, 95 / 255, 160 / 255, 0.6)
  readonly property color bluetooth: Qt.rgba(255 / 255, 251 / 255, 0 / 255, 0.6)
  readonly property color audio: Qt.rgba(212 / 255, 0 / 255, 255 / 255, 0.6)
  readonly property color network: Qt.rgba(0 / 255, 183 / 255, 255 / 255, 0.6)

  readonly property color battery: Qt.rgba(38 / 255, 166 / 255, 91 / 255, 0.6)
  readonly property color batteryWarning: Qt.rgba(255 / 255, 190 / 255, 97 / 255, 0.6)
  readonly property color batteryCritical: Qt.rgba(245 / 255, 60 / 255, 60 / 255, 0.6)

  readonly property var herdr: ({
    "blocked": Qt.rgba(245 / 255, 60 / 255, 60 / 255, 0.6),
    "done": Qt.rgba(21 / 255, 184 / 255, 13 / 255, 0.6),
    "working": Qt.rgba(33 / 255, 255 / 255, 211 / 255, 0.6),
    "idle": Qt.rgba(255 / 255, 190 / 255, 97 / 255, 0.6),
    "unknown": Qt.rgba(72 / 255, 104 / 255, 98 / 255, 0.6)
  })

  // Right-align `value` in a field `width` wide, the way waybar's
  // `{usage:>2}` format spec does.
  function pad(value, width) {
    var s = String(value);
    while (s.length < width)
      s = " " + s;
    return s;
  }
}
