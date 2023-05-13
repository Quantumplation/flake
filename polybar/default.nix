{ config, pkgs, ... }:

{
  home-manager.users.pi.xdg.configFile."polybar/launch.sh".executable = true;
  home-manager.users.pi.xdg.configFile."polybar/launch.sh".text = (builtins.readFile ./launch.sh);
  home-manager.users.pi.xdg.configFile."polybar/config".text = (builtins.readFile ./config);
  home-manager.users.pi.xdg.configFile."polybar/colors".text = (builtins.readFile ./colors);
  home-manager.users.pi.xdg.configFile."polybar/system".text = (builtins.readFile ./system);
  home-manager.users.pi.xdg.configFile."polybar/modules".text = (builtins.readFile ./modules);
}
