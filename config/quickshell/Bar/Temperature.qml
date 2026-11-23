// waybar: temperature, format " {temperatureC:>2}°C"
BarText {
  color: Theme.temperature
  text: " " + Theme.pad(SysInfo.temperature, 2) + "°C"
}
