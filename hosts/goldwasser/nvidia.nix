{ config, pkgs, ... }: {
  # NVIDIA GPU Configuration for Goldwasser (Desktop)

  # Boot configuration for NVIDIA
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # NVIDIA systemd service
  systemd.services.nvidia-persistenced = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  # NVIDIA hardware configuration
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaPersistenced = true;
    nvidiaSettings = true;
  };
}
