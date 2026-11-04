pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// CPU / memory / disk / temperature, polled once per shell instance rather
// than once per monitor. Each figure is computed exactly the way the
// matching waybar module computes it, including the integer truncation.
Singleton {
  id: root

  property int cpuUsage: 0
  property int memoryUsage: 0
  property int diskUsage: 0
  property int temperature: 0

  // waybar's temperature module defaults to thermal zone 0 when neither
  // `hwmon-path` nor `thermal-zone` is set.
  readonly property string thermalZone: "/sys/class/thermal/thermal_zone0/temp"

  // --- cpu: 100 * (busy delta / total delta) over /proc/stat ----------
  property real _lastTotal: 0
  property real _lastIdle: 0

  FileView {
    id: statFile
    path: "/proc/stat"
    blockLoading: true
    printErrors: false

    onLoaded: {
      var fields = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
      if (fields.length < 5)
        return;

      // idle + iowait are the non-busy columns
      var idle = fields[3] + fields[4];
      var total = fields.reduce((a, b) => a + b, 0);

      var dTotal = total - root._lastTotal;
      var dIdle = idle - root._lastIdle;
      root._lastTotal = total;
      root._lastIdle = idle;

      if (dTotal > 0)
        root.cpuUsage = Math.round(100 * (dTotal - dIdle) / dTotal);
    }
  }

  Timer {
    interval: 2000 // waybar cpu.interval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: statFile.reload()
  }

  // --- memory: 100 * (MemTotal - MemAvailable) / MemTotal -------------
  FileView {
    id: memFile
    path: "/proc/meminfo"
    blockLoading: true
    printErrors: false

    onLoaded: {
      var info = {};
      for (const line of text().split("\n")) {
        var m = line.match(/^(\w+):\s+(\d+)/);
        if (m)
          info[m[1]] = Number(m[2]);
      }
      if (!info.MemTotal)
        return;

      var free = info.MemAvailable !== undefined ? info.MemAvailable : info.MemFree + info.Buffers + info.Cached + info.SReclaimable - info.Shmem;
      root.memoryUsage = Math.trunc(100 * (info.MemTotal - free) / info.MemTotal);
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: memFile.reload()
  }

  // --- temperature: millidegrees -> degrees ---------------------------
  FileView {
    id: tempFile
    path: root.thermalZone
    blockLoading: true
    printErrors: false
    onLoaded: root.temperature = Math.round(Number(text().trim()) / 1000)
  }

  Timer {
    interval: 1000 // waybar temperature.interval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: tempFile.reload()
  }

  // --- disk: 100 * (f_blocks - f_bfree) / f_blocks ---------------------
  // `df -P` reports exactly those two as the total and used columns, so
  // used/total reproduces waybar's `{percentage_used}`.
  Process {
    id: dfProc
    command: ["df", "-P", "-k", "/"]

    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n");
        if (lines.length < 2)
          return;
        var cols = lines[1].trim().split(/\s+/);
        var total = Number(cols[1]);
        var used = Number(cols[2]);
        if (total > 0)
          root.diskUsage = Math.trunc(100 * used / total);
      }
    }
  }

  Timer {
    interval: 30000 // waybar disk.interval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!dfProc.running)
      dfProc.running = true
  }
}
