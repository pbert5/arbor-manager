{
  description = "Arbor Manager: reusable static machine inventory to NixOS assembly";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      lib = import ./lib { inherit (nixpkgs) lib; };
    in
    {
      inherit lib;
      formatter = forAllSystems (system: (import nixpkgs { inherit system; }).nixfmt-tree);
      checks = forAllSystems (system: {
        fixtures =
          let
            fixtureInputs = { inherit nixpkgs; };
            assembled = lib.mkMachines {
              inputs = fixtureInputs;
              machinesPath = ./tests/fixtures;
              profiles.server = [ ];
            };
            valid = lib.validateMachine "fixture" {
              system = "x86_64-linux";
              profiles = [ "server" ];
            };
            invalid = builtins.tryEval (lib.validateMachine "broken" { system = "i686-linux"; });
          in
          assert valid.name == "fixture";
          assert valid.hostname == "fixture";
          assert !invalid.success;
          assert
            assembled.machineNames == [
              "fixture"
              "valid"
            ];
          assert assembled.configurations.fixture.config.networking.hostName == "fixture";
          (import nixpkgs { inherit system; }).emptyFile;
      });
    };
}
