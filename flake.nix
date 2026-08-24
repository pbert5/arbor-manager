{
  description = "Nix Arbor: a small, composable Nix integration workspace";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    ashzsh.url = "github:pbert5/AshZsh";
    ashzsh.inputs.nixpkgs.follows = "nixpkgs";
    ashzsh.inputs.home-manager.follows = "home-manager";
    ashes-tools.url = "github:pbert5/AshesTools";
    ashes-tools.inputs.nixpkgs.follows = "nixpkgs";
    ashes-desktop-apps.url = "github:pbert5/AshDesktopApps";
    ashes-desktop-apps.inputs.nixpkgs.follows = "nixpkgs";
    tilingDesktop = {
      url = "github:pbert5/TilingDesktop";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./modules/devshell.nix
        ./modules/checks.nix
        ./modules/apps.nix
        ./modules/ashzsh.nix
      ];
    };
}
