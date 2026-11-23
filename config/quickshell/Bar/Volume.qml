import Quickshell.Services.Pipewire

// waybar: pulseaudio, format "  {volume:>2}%" / format-muted "  "
BarText {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var audio: sink ? sink.audio : null

  color: Theme.audio
  text: {
    if (!audio)
      return "";
    if (audio.muted)
      return "  ";
    return "  " + Theme.pad(Math.round(audio.volume * 100), 2) + "%";
  }

  // Volume and mute are only published while the node is bound.
  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }
}
