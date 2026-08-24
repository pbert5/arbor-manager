_: {
  perSystem =
    { pkgs, ... }:
    let
      tools = with pkgs; [
        nix
        git
        gh
        jq
        yq
        ripgrep
        fd
        fzf
        just
        direnv
        nix-direnv
        navi
        yazi
        nh
        nix-output-monitor
        nix-tree
        nix-diff
        nix-index
        nil
        statix
        deadnix
        nixfmt
      ];
    in
    {
      formatter = pkgs.nixfmt-tree;

      devShells.default = pkgs.mkShell {
        name = "nix-arbor";
        packages = tools;

        shellHook = ''
          export NAVI_PATH="$PWD/cheats''${NAVI_PATH:+:$NAVI_PATH}"
          if [[ -z "''${NIX_ARBOR_WELCOME_SHOWN:-}" ]]; then
            export NIX_ARBOR_WELCOME_SHOWN=1
            printf '%s\n' \
              "Nix Arbor shell: nix flake show | nix flake check | nix fmt" \
              "Navi cheats: navi (project cheats are first in NAVI_PATH)"
          fi
        '';
      };
    };
}
