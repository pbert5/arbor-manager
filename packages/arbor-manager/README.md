# Arbor Manager

Arbor Manager is the reusable assembly layer between a machine source and
ordinary NixOS configurations. `mkMachines` consumes pure source entries, so
callers can provide records from any source without adding a registry
dependency.

Its public API is `lib.mkMachines`:

```nix
inputs.arbor-manager.lib.mkMachines {
  inherit inputs;
  sources = [
    {
      name = "server";
      record = { system = "x86_64-linux"; profiles = [ "server" ]; };
      provenance = { kind = "registry-snapshot"; revision = "..."; };
      precedence = 10;
    }
  ];
  profiles = { server = [ ./profiles/server.nix ]; };
}
```

Each source entry has `name` and `record`, and may provide `modules`,
`provenance`, and numeric `precedence`. Records retain `cluster` (including
any relationship fields) as data; Arbor Manager does not prescribe role
values. `localSource ./config/machines` adapts the conventional directory
layout, and `registrySnapshot { name = record; }` adapts a pure snapshot.

For compatibility, `machinesPath = ./config/machines` remains an alias for
the local adapter. Local directories contain `default.nix` (facts), and may
contain `hardware-configuration.nix` and `configuration.nix` modules.
Directories are discovered deterministically in lexical order. Each result is
still assembled with native `nixosSystem`, with the normalized record exposed
at `config.arbor.machine` and as the `machine` special argument.
