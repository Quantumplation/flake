{ pkgs, ... }: {
  security.rtkit.enable = true;

  services = {
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber = {
        enable = true;
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-disable-hdmi.conf" ''
            monitor.alsa.rules = [
              {
                matches = [
                  {
                    node.name = "~alsa_output.pci-.*hdmi.*"
                  }
                ]
                actions = {
                  update-props = {
                    node.disabled = true
                  }
                }
              }
            ]
          '')
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/52-rode-profile.conf" ''
            monitor.alsa.rules = [
              {
                matches = [
                  {
                    device.name = "alsa_card.usb-RODE_Microphones_RODE_Podcaster_v2_3BA811B4-00"
                  }
                ]
                actions = {
                  update-props = {
                    api.acp.auto-profile = false
                    device.profile = "analog-stereo"
                  }
                }
              }
            ]
          '')
        ];
      };
    };
  };
}
