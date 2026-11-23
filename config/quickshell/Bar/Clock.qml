import Quickshell

// waybar: clock, format "{:%d.%m. %H:%M:%S}" at 1s
BarText {
  color: Theme.clock
  text: Qt.formatDateTime(clock.date, "HH:mm:ss hh.MM.")

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }
}
