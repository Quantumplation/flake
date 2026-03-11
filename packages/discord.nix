{ pkgs, ... }: {
  nixpkgs.overlays = [
    (self: super: {
      discord = super.discord.overrideAttrs (
        _: {
          src = builtins.fetchTarball {
            url = "https://discord.com/api/download?platform=linux&format=tar.gz";
            sha256 = "1qa1jd1y4df1437lfw7f5pmf63ms9s5p9ylmmizmzcmd5b5llj13";
          };
        }
      );
    })
  ];

  environment.systemPackages = with pkgs; [
    discord
  ];
}
