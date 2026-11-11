{ config, ... }:

let
  user = config.my.user;
  userCfg = config.users.users.${user};
in

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
    inherit user;
    settings = {
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire";
        }
      ];
      music_directory = "${userCfg.home}/Music";
    };

    startWhenNeeded = true;
  };
  # MPD runs as a system service; this lets it reach the user's PipeWire session
  systemd.services.mpd.environment.XDG_RUNTIME_DIR = "/run/user/${toString userCfg.uid}";
}
