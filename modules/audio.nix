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
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/50-device-names.conf" ''
            monitor.alsa.rules = [
              {
                matches = [
                  { node.name = "alsa_input.pci-0000_c2_00.6.HiFi__Mic2__source" }
                ]
                actions = {
                  update-props = {
                    node.description = "Headset Mic"
                    priority.session = 1000
                  }
                }
              }
              {
                matches = [
                  { node.name = "alsa_input.pci-0000_c2_00.6.HiFi__Mic1__source" }
                ]
                actions = {
                  update-props = {
                    node.description = "Built-in Mic"
                    priority.session = 2000
                  }
                }
              }
              {
                matches = [
                  { node.name = "alsa_output.pci-0000_c2_00.6.HiFi__Speaker__sink" }
                ]
                actions = {
                  update-props = {
                    node.description = "Laptop Speakers"
                  }
                }
              }
            ]
          '')
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-hdmi-audio.conf" ''
            monitor.alsa.rules = [
              {
                matches = [
                  {
                    node.name = "~alsa_output.pci-.*hdmi.*"
                  }
                ]
                actions = {
                  update-props = {
                    node.description = "HDMI Audio"
                    priority.session = 500
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
