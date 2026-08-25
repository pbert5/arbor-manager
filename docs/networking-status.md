# Networking integration status

This document records the current dependency queue after promotion of the
manager/runtime slice.

## Completed and promoted

- Network Manager `d2f538e`: strong accepted-endpoint parsing, explicit
  graph-only compatibility parsing, accepted authority versus observations,
  target-aware reachability, capability-gated peer application, generation-
  bound execution bindings, JSON-lines Unix sockets, `arbor-networkd`, and a
  NixOS service module.
- Registry adapter: accepted-state conversion rejects unsupported versions,
  quarantined records, malformed endpoints, revoked records, and unknown
  providers without granting authority to observations.
- Provider boundaries: LAN fact reporting, an explicit unconfigured
  Tailscale boundary, and idempotent generation-bound Ygg desired-peer state.
- Arbor Manager `03b6de9`: immutable-snapshot behavior is preserved and
  `network`/`route` socket commands are available through the existing CLI.
- Nix Arbor `1e8726e`: remote inputs are refreshed and the network manager
  NixOS module is exported as `nixosModules.arborNetworkManager`.

## Remaining queue

The following remain blocked pending implementation and real virtual-machine
evidence; they are not represented as complete by the component checks:

- real Registry watcher feeding networkd, rather than a static snapshot file;
- production LAN provider VM wiring and real one-/multi-hop OpenSSH execution;
- adaptation of `yggdrasil-private` from inventory peers to the networkd
  desired-peer socket, plus private/public Ygg VM tests;
- failover, partition healing, restart, revocation, and route revalidation VM
  acceptance;
- SSH host-public-identity publication and strict known-host execution;
- deployment route binding/transit-risk integration;
- independent security, route, SSH, Nix, distributed-runtime, and VM reviews;
- real Tailscale control-plane acceptance (external credentials are
  intentionally unavailable and must not be used on a developer tailnet).

The remaining items require cross-repository implementation and/or a NixOS VM
test environment; no acceptance claim should be inferred from the fast checks.
