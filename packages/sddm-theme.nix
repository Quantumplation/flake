{ stdenv, fetchFromGitHub }:

{
  sddm-abstract-dark = stdenv.mkDerivation rec {
    pname="sddm-abstract-dark-theme";
    version = "0.1";
    dontBuild = true;
    src = fetchFromGitHub {
      owner = "dR3b";
      repo = "abstractdark-sddm-theme";
      rev = "v${version}";
      sha256 = "1si141hnp4lr43q36mbl3anlx0a81r8nqlahz3n3l7zmrxb56s2y";
    };

    installPhase = ''
      mkdir -p $out/share/sddm/themes
      cp -aR $src $out/share/sddm/themes/abstract-dark
    '';
  };
}
