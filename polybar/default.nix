{ config, pkgs, ... }:

let
  modulesContent = pkgs.substituteAll {
    src = ./modules;
    rofi = "${config.home-manager.users.pi.home.path.outPath}/bin/rofi";
    rofipulseselect = "${pkgs.rofi-pulse-select}/bin/rofi-pulse-select";
  };
in
{
  

  home-manager.users.pi.xdg.configFile."polybar/launch.sh".executable = true;
  home-manager.users.pi.xdg.configFile."polybar/launch.sh".text = (builtins.readFile ./launch.sh);
  home-manager.users.pi.xdg.configFile."polybar/config".text = (builtins.readFile ./config);
  home-manager.users.pi.xdg.configFile."polybar/main".text = (builtins.readFile ./main);
  home-manager.users.pi.xdg.configFile."polybar/second".text = (builtins.readFile ./second);
  home-manager.users.pi.xdg.configFile."polybar/colors".text = (builtins.readFile ./colors);
  home-manager.users.pi.xdg.configFile."polybar/system".text = (builtins.readFile ./system);
  home-manager.users.pi.xdg.configFile."polybar/modules".text = (builtins.readFile modulesContent);
}
