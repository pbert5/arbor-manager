_: {
  perSystem =
    { pkgs, ... }:
    let
      cheats = ../cheats;
      help = pkgs.writeShellApplication {
        name = "nix-arbor-help";
        runtimeInputs = [ pkgs.navi ];
        text = ''
          exec navi --path "${cheats}''${NAVI_PATH:+:$NAVI_PATH}"
        '';
      };
    in
    {
      packages.navi-help = help;

      apps.help = {
        type = "app";
        program = "${help}/bin/nix-arbor-help";
        meta.description = "Browse Nix Arbor's project-local Navi cheats";
      };
    };
}
