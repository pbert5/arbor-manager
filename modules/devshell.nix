{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      ashzshHome = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          inputs.ashzsh.homeModules.default
          {
            home = {
              username = "ash";
              homeDirectory = "/tmp/nix-arbor-ashzsh";
              stateVersion = "26.05";
              enableNixpkgsReleaseCheck = false;
            };
            systemd.user.startServices = "suggest";
          }
        ];
      };
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
          export HOME="/tmp/nix-arbor-ashzsh"
          export SHELL="${pkgs.zsh}/bin/zsh"
          mkdir -p "$HOME"
          ashzsh_marker="$HOME/.ashzsh-activation"
          if [[ ! -r "$ashzsh_marker" || "$(<"$ashzsh_marker")" != "${ashzshHome.activationPackage}" ]]; then
            ${ashzshHome.activationPackage}/activate
            printf '%s\n' "${ashzshHome.activationPackage}" > "$ashzsh_marker"
          fi
          if [[ -r "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
            source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
          fi
          export NAVI_PATH="$PWD/cheats''${NAVI_PATH:+:$NAVI_PATH}"
          if [[ -z "''${NIX_ARBOR_WELCOME_SHOWN:-}" ]]; then
            export NIX_ARBOR_WELCOME_SHOWN=1
            printf '%s\n' \
              "Nix Arbor shell: nix flake show | nix flake check | nix fmt" \
              "Navi cheats: navi (project cheats are first in NAVI_PATH)"
          fi
          if [[ $- == *i* ]]; then
            exec "${pkgs.zsh}/bin/zsh" -i
          fi
        '';
      };
    };
}
