{
  description = "Arbor Registry: pure signed-record reconciliation and graph library";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      registry = import ./lib { lib = nixpkgs.lib; };
      nixosModule = import ./modules/nixos.nix;
    in
    {
      lib = registry;
      nixosModules.default = nixosModule;
      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-tree);
      checks = forAllSystems (system: {
        invariants = import ./tests/invariants.nix {
          inherit registry;
          pkgs = import nixpkgs { inherit system; };
        };
        modules = import ./tests/modules.nix {
          module = nixosModule;
          pkgs = import nixpkgs { inherit system; };
        };
        recovery = import ./tests/recovery.nix {
          inherit registry;
          pkgs = import nixpkgs { inherit system; };
        };
      });
    };
}
