// waybar: cpu, format " {usage:>2}%"
BarText {
  color: Theme.cpu
  text: " " + Theme.pad(SysInfo.cpuUsage, 2) + "%"
}
