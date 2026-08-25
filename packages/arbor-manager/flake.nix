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
            pure = lib.mkMachines {
              inputs = fixtureInputs;
              sources = [
                {
                  name = "pure";
                  record = {
                    system = "x86_64-linux";
                    profiles = [ ];
                    hostname = "pure-host";
                    cluster.role = "arbitrary-data";
                  };
                  provenance = {
                    kind = "test";
                    source = "pure";
                  };
                  precedence = 7;
                }
              ];
              extraModules = [
                ({ lib, ... }: {
                  config.arbor.machine = lib.mkForce (
                    assembled.machines.fixture.machine
                    // {
                      forced = true;
                    }
                  );
                })
              ];
            };
            snapshot = lib.mkMachines {
              inputs = fixtureInputs;
              sources = lib.registrySnapshot {
                snapshot = {
                  system = "x86_64-linux";
                  profiles = [ ];
                };
              };
            };
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
          assert pure.configurations.pure.config.networking.hostName == "pure-host";
          assert pure.configurations.pure.config.arbor.machine.forced;
          assert pure.machines.pure.machine.provenance.kind == "test";
          assert pure.machines.pure.machine.precedence == 7;
          assert pure.machines.pure.machine.cluster.role == "arbitrary-data";
          assert !(builtins.hasAttr "clusterRole" lib.machineTypes);
          assert snapshot.machineNames == [ "snapshot" ];
          assert snapshot.configurations.snapshot.config.networking.hostName == "snapshot";
          assert (import ./tests/node-selection.nix { inherit (nixpkgs) lib; });
          (import nixpkgs { inherit system; }).emptyFile;
      });
    };
}
