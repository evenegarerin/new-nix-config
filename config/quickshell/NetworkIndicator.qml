import Quickshell.Networking

// waybar: network. Waybar follows the default route; a wired link wins over
// wifi here, which is the same choice NetworkManager's routing metric makes.
BarText {
  id: root

  readonly property var ethernet: Networking.devices.values.find(d => d.type === NetworkDevice.Wired && d.connected) ?? null
  readonly property var wifi: Networking.devices.values.find(d => d.type === NetworkDevice.Wifi && d.connected) ?? null
  readonly property var wifiNetwork: wifi ? (wifi.networks.values.find(n => n.connected) ?? null) : null

  color: Theme.network
  text: {
    if (ethernet)
      return " ";
    if (wifiNetwork)
      return "  " + wifiNetwork.name;
    if (wifi)
      return "  ";
    return " no connection";
  }
}
