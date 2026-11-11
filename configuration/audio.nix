{ ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.mpd = {
    enable = true;
    user = "castle";
    settings = {
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire";
        }
      ];
      music_directory = "/home/castle/Music";
    };

    startWhenNeeded = true;
  };
  # MPD runs as a system service; this lets it reach the user's PipeWire session
  systemd.services.mpd.environment.XDG_RUNTIME_DIR = "/run/user/1000";
}
