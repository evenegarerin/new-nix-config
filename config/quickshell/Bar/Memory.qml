// waybar: memory, format " {percentage:>2}%"
BarText {
  color: Theme.memory
  text: " " + Theme.pad(SysInfo.memoryUsage, 2) + "%"
}
