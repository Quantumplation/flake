{ pkgs, ... }: {
  home.packages = [ pkgs.swaynotificationcenter ];

  services.swaync = {
    enable = true;
    # style.css is managed at runtime by theme-switch, not by home-manager
    settings = {
      positionX = "right";
      positionY = "top";
      control-center-width = 400;
      control-center-height = 600;
      control-center-margin-top = 10;
      control-center-margin-bottom = 10;
      control-center-margin-right = 10;
      control-center-margin-left = 10;
      notification-window-width = 400;
      timeout = 5;
      timeout-low = 3;
      timeout-critical = 0;
      fit-to-screen = false;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      notification-icon-size = 48;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      transition-time = 300;
      hide-on-clear = true;
      hide-on-action = true;
      script-fail-notify = false;
    };
  };
}
