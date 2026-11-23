import Quickshell.Bluetooth

// waybar: bluetooth. `format` is empty, so a powered-off adapter collapses
// the module; powered on shows the glyph; a connection appends the alias.
BarText {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var device: Bluetooth.devices.values.find(d => d.connected) ?? null

  color: Theme.bluetooth
  text: {
    if (!adapter || !adapter.enabled)
      return "";
    if (device)
      return " " + (device.alias || device.name || "");
    return "";
  }
}
