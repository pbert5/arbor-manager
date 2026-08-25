# Arbor networking architecture (initial contract)

This slice freezes the provider-neutral boundary and route model. It does not
claim that provider repositories or live Registry integration are complete.

```text
Nix policy -> Network Manager <- accepted Registry state
                         |
                    provider runtime
                         |
             endpoints + health + reachability graph
                         |
                 constrained route solver
```

Nix declares static eligibility, provider installation, cost/priority,
fallback, exposure, bootstrap, and transit policy. Registry accepted state
supplies live node membership, public identities, endpoint generations,
authorization provenance, and revocation. Provider health is observed at
runtime. Private keys and credentials are runtime-only.

## Frozen provider contract

Providers expose a narrow JSON-lines Unix-socket protocol:

* `status` — health and current reconciliation generation;
* `capabilities` — provider features and supported record versions;
* `local-identities` — public local identities only;
* `local-endpoints` — normalized public endpoint records;
* `health` — per-network reachability observations;
* `apply-peers` — idempotent desired authorized peer set, including generation
  and provenance.

The manager validates records before calling a provider. `apply-peers` may not
receive arbitrary Registry data: only accepted, current, network-specific
identity generations are passed through. Provider-specific firewall and
credential handling remains provider-owned.

## Route model

Authority/relationship edges and packet reachability edges are separate. A
relationship can authorize an edge or transit capability, but never implies
connectivity. A reachable public Ygg endpoint never implies private Arbor
membership. Routes are deterministic constrained shortest paths over edges
with provider, network, health, endpoint generation, capabilities, and explicit
transit permissions. Lower configured priority/cost wins; degraded and unknown
health are penalties, unreachable and revoked edges are excluded. Repeated
vertices are rejected, and route plans carry the Registry snapshot digest and
identity generations so execution can reject stale plans.

## Dependency graph

```text
legacy audit ───────────────┐
Ygg audit ──────────────────┤
Registry interface audit ───┼─> interface synthesis ─> manager daemon
OpenBao boundary audit ─────┤                         ├─> provider adapters
route solver design ────────┤                         ├─> route CLI/SSH
SSH design ─────────────────┘                         └─> deployment integration

Nix policy schema ───────────────> Nix Arbor composition
Ygg provider adaptation ────────> private-Ygg VM acceptance
LAN provider ───────────────────> LAN VM acceptance
Tailscale provider ─────────────> isolated provider tests
all provider/runtime work ──────> integrated VM acceptance
```

## Legacy classification

Preserve: visibility/span/route-domain semantics; fallback ranking;
private/public exposure separation; private Ygg over a separate public
transport; pinned Ygg public keys and `AllowedPublicKeys`; multicast as a
transport candidate; persistent local keys; provider firewall ownership; live
SSH known-host publication pattern.

Adapt: inventory-derived Ygg peers to accepted Registry generations; public
Ygg sidecar input to provider runtime state; Tailscale host aliases to
normalized endpoints; static host bootstrap endpoint to route snapshots;
service exposure to typed policy.

Replace: dendrite string loaders; committed cluster-wide node lists; direct
endpoint field lookup in deployment; recursive parent walking; rebuild-driven
membership updates.

Drop: public transport implying trust; public Ygg ordinary service exposure;
Git inventory as live authority; physical-host tests; insecure `/dev/null`
known-host workarounds.

## Current blockers

`yggdrasil-private` currently exports an inventory-driven NixOS module and must
be adapted in its own repository. No public LAN/Tailscale provider repositories
exist yet. Arbor Registry already has typed `endpoint`, `identity-generation`,
`capability`, `compatibility`, and `revocation` families; a compatibility task
must define the smallest accepted endpoint payload extension for provider,
generation, and transit metadata. Existing OpenBao provider/vaultd boundaries
can carry provider credential requirements; networking must reuse that binding
surface.
