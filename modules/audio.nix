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
        ];
      };
    };
  };
}
