import Quickshell

// waybar: clock, format "{:%d.%m. %H:%M:%S}" at 1s
BarText {
  color: Theme.clock
  text: Qt.formatDateTime(clock.date, "dd.MM. HH:mm:ss")

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
