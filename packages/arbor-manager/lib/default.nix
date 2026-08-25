{ lib }:
let
  machineTypes = {
    system = lib.types.enum [
      "x86_64-linux"
      "aarch64-linux"
    ];
    profiles = lib.types.listOf lib.types.str;
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
      provenance = raw.provenance or { kind = "inline"; };
      precedence = raw.precedence or 0;
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
    {
      inherit
        name
        hostname
        profiles
        system
        cluster
        provenance
        precedence
        ;
      enabled = raw.enabled or true;
    }
    // (builtins.removeAttrs raw [
      "system"
      "hostname"
      "profiles"
      "cluster"
      "enabled"
      "provenance"
      "precedence"
    ]);

  optionalModule = path: if builtins.pathExists path then [ path ] else [ ];

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

  localSource =
    machinesPath:
    builtins.attrValues (
      builtins.mapAttrs (name: directory: {
        inherit name directory;
        record = import "${directory}/default.nix";
        modules =
          optionalModule "${directory}/hardware-configuration.nix"
          ++ optionalModule "${directory}/configuration.nix";
        provenance = {
          kind = "local";
          path = toString directory;
        };
        precedence = 0;
      }) (discover machinesPath)
    );

  registrySnapshot =
    snapshot:
    lib.mapAttrsToList (name: record: {
      inherit name record;
      modules = [ ];
      provenance = {
        kind = "registry-snapshot";
      };
      precedence = 0;
    }) snapshot;

  mkMachine =
    {
      inputs,
      profiles,
      name,
      record,
      modules ? [ ],
      provenance ? {
        kind = "inline";
      },
      precedence ? 0,
      extraModules,
    }:
    let
      machine = validateMachine name (
        record
        // {
          provenance = record.provenance or provenance;
          precedence = record.precedence or precedence;
        }
      );
      profileNames = machine.profiles;
      missingProfiles = builtins.filter (profile: !(builtins.hasAttr profile profiles)) profileNames;
      profileModules = lib.concatMap (profile: profiles.${profile}) profileNames;
      _profiles =
        if missingProfiles == [ ] then
          true
        else
          throw "Arbor Manager: machine '${name}' references unknown profile(s): ${lib.concatStringsSep ", " missingProfiles}.";
      managerModule = { lib, ... }: {
        options.arbor.machine = lib.mkOption {
          type = lib.types.raw;
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
      };
    in
    assert _profiles;
    {
      inherit machine;
      modules = [ managerModule ] ++ profileModules ++ modules ++ extraModules;
    };
in
{
  inherit
    machineTypes
    validateMachine
    discover
    localSource
    registrySnapshot
    ;

  mkMachines =
    {
      inputs,
      sources ? null,
      machinesPath ? null,
      profiles ? { },
      extraModules ? [ ],
    }:
    let
      sourceEntries =
        if sources != null then
          sources
        else if machinesPath != null then
          localSource machinesPath
        else
          throw "Arbor Manager: mkMachines requires 'sources' or 'machinesPath'.";
      machines = builtins.listToAttrs (
        map (
          source:
          let
            name = source.name;
          in
          {
            inherit name;
            value = mkMachine {
              inherit
                inputs
                profiles
                name
                extraModules
                ;
              record = source.record;
              modules = source.modules or [ ];
              provenance = source.provenance or { kind = "inline"; };
              precedence = source.precedence or 0;
            };
          }
        ) sourceEntries
      );
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
