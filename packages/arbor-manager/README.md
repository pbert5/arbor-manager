# Arbor Manager

Arbor Manager is the reusable assembly layer between a machine source and
ordinary NixOS configurations. It currently consumes a static directory of
Nix machine records; a future registry-backed source can provide the same
normalized records without changing the NixOS assembly API.

Its public API is `lib.mkMachines`:

```nix
inputs.arbor-manager.lib.mkMachines {
  inherit inputs;
  machinesPath = ./config/machines;
  profiles = { server = [ ./profiles/server.nix ]; };
}
```

Each machine directory contains `default.nix` (facts), and may contain the
conventional `hardware-configuration.nix` and `configuration.nix` modules.
Directories are discovered deterministically in lexical order.
