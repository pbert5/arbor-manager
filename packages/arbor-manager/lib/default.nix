{ lib }:
let
  machineTypes = {
    system = lib.types.enum [
      "x86_64-linux"
      "aarch64-linux"
    ];
    profiles = lib.types.listOf lib.types.str;
    clusterRole = lib.types.enum [
      "leader"
      "follower"
      "subordinate-leader"
      "none"
    ];
  };

  validateMachine =
    name: raw:
    let
      required =
        field:
        if builtins.hasAttr field raw then
          builtins.getAttr field raw
        else
          throw "Arbor Manager: machine '${name}' is missing required field '${field}'.";
      system = required "system";
      _system =
        if
          builtins.elem system [
            "x86_64-linux"
            "aarch64-linux"
          ]
        then
          true
        else
          throw "Arbor Manager: machine '${name}' has unsupported system '${system}'.";
      hostname = raw.hostname or name;
      profiles = raw.profiles or [ ];
      cluster = raw.cluster or { };
      role = cluster.role or "none";
    in
    assert lib.assertMsg (
      builtins.match "[a-zA-Z0-9][a-zA-Z0-9-]*" name != null
    ) "Arbor Manager: machine directory name '${name}' is not a valid hostname-like identifier.";
    assert lib.assertMsg (
      builtins.isList profiles && builtins.all builtins.isString profiles
    ) "Arbor Manager: machine '${name}' profiles must be a list of strings.";
    assert lib.assertMsg (
      builtins.match "[a-zA-Z0-9][a-zA-Z0-9-]*" hostname != null
    ) "Arbor Manager: machine '${name}' has an invalid hostname '${hostname}'.";
    assert _system;
    assert builtins.elem role [
      "leader"
      "follower"
      "subordinate-leader"
      "none"
    ];
    {
      inherit
        name
        hostname
        profiles
        system
        ;
      cluster = {
        inherit role;
      }
      // (builtins.removeAttrs cluster [ "role" ]);
      enabled = raw.enabled or true;
    }
    // (builtins.removeAttrs raw [
      "system"
      "hostname"
      "profiles"
      "cluster"
      "enabled"
    ]);

  discover =
    machinesPath:
    let
      entries = builtins.readDir machinesPath;
      names = builtins.sort builtins.lessThan (
        builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries)
      );
    in
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = "${toString machinesPath}/${name}";
      }) names
    );

  optionalModule = path: if builtins.pathExists path then [ path ] else [ ];

  mkMachine =
    {
      inputs,
      profiles,
      name,
      directory,
      extraModules,
    }:
    let
      raw = import "${directory}/default.nix";
      machine = validateMachine name raw;
      profileNames = machine.profiles;
      missingProfiles = builtins.filter (profile: !(builtins.hasAttr profile profiles)) profileNames;
      profileModules = lib.concatMap (profile: profiles.${profile}) profileNames;
      _profiles =
        if missingProfiles == [ ] then
          true
        else
          throw "Arbor Manager: machine '${name}' references unknown profile(s): ${lib.concatStringsSep ", " missingProfiles}.";
      modules = [
        ({ lib, ... }: {
          options.arbor.machine = lib.mkOption {
            type = lib.types.raw;
            readOnly = true;
            default = machine;
            description = "Normalized Arbor Manager machine record.";
          };
          config = {
            assertions = [
              {
                assertion = machine.enabled;
                message = "Arbor Manager: disabled machine '${name}' cannot be built.";
              }
            ];
            networking.hostName = machine.hostname;
            nixpkgs.hostPlatform = lib.mkDefault machine.system;
            arbor.machine = machine;
          };
        })
      ]
      ++ profileModules
      ++ optionalModule "${directory}/hardware-configuration.nix"
      ++ optionalModule "${directory}/configuration.nix"
      ++ extraModules;
    in
    assert _profiles;
    {
      inherit machine modules;
    };
in
{
  inherit machineTypes validateMachine discover;

  mkMachines =
    {
      inputs,
      machinesPath,
      profiles ? { },
      extraModules ? [ ],
    }:
    let
      directories = discover machinesPath;
      machines = builtins.mapAttrs (
        name: directory:
        mkMachine {
          inherit
            inputs
            profiles
            name
            directory
            extraModules
            ;
        }
      ) directories;
      configurations = builtins.mapAttrs (
        _name: machine:
        inputs.nixpkgs.lib.nixosSystem {
          inherit (machine.machine) system;
          specialArgs = {
            inherit inputs;
            machine = machine.machine;
          };
          modules = machine.modules;
        }
      ) machines;
    in
    {
      inherit configurations machines;
      machineNames = builtins.attrNames machines;
    };
}
