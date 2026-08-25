# Networking integration status

This document records the current dependency queue after promotion of the
manager/runtime slice.

## Completed and promoted

- Network Manager `3be9fc2`: strong accepted-endpoint parsing, explicit
  graph-only compatibility parsing, accepted authority versus observations,
  target-aware reachability, capability-gated peer application, generation-
  bound execution bindings, JSON-lines Unix sockets, `arbor-networkd`, and a
  NixOS service module.
- Registry adapter: accepted-state conversion rejects unsupported versions,
  quarantined records, malformed endpoints, revoked records, and unknown
  providers without granting authority to observations.
- Provider boundaries: LAN fact reporting, an explicit unconfigured
  Tailscale boundary, idempotent generation-bound Ygg desired-peer state, and
  a Ygg control-socket adapter.
- Arbor Manager `309a970`: immutable-snapshot behavior is preserved;
  `network`/`route` and verified native `ssh` commands consume daemon routes;
  the one-hop VM now exercises the real daemon/provider route and ProxyJump
  boundary, with final OpenSSH connectivity still blocked by the VM topology.
- Yggdrasil Private `7f0973c`: explicit dynamic-peer mode and provider service
  are integrated without removing the public/bootstrap sidecar or firewall
  controls.
- Nix Arbor: remote inputs are refreshed and both provider modules
  are exported.

## Remaining queue

The following remain blocked pending implementation and real virtual-machine
evidence; they are not represented as complete by the component checks:

- live Registry service/watch feed (networkd now watches an accepted-state
  file) and bootstrap convergence;
- real one-/multi-hop OpenSSH execution in the VM harness (route binding and
  host-key generation pass; jump TCP/22 remains refused in the current VM
  topology);
- private/public Ygg VM transport and revocation evidence;
- failover, partition healing, restart, revocation, and route revalidation VM
  acceptance;
- SSH host-public-identity publication and strict known-host execution (the
  accepted identity path is implemented; final VM execution remains queued);
- deployment route binding/transit-risk integration;
- independent security, route, SSH, Nix, distributed-runtime, and VM reviews;
- real Tailscale control-plane acceptance (external credentials are
  intentionally unavailable and must not be used on a developer tailnet).

The remaining items require cross-repository implementation and/or a NixOS VM
test environment; no acceptance claim should be inferred from the fast checks.
