import QtQuick

// Every piece of text in the bar: waybar's `* { font-size: 14px;
// font-family: JetBrainsMono Nerd Font; }` rule.
Text {
  color: Theme.fg
  font.family: Theme.fontFamily
  font.pixelSize: Theme.fontSize
  verticalAlignment: Text.AlignVCenter
  // Hidden modules must not reserve space in the RowLayout.
  visible: text.length > 0
}
