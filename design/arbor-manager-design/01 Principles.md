---
id: arbor-tui-principles
type: principle-set
title: TUI Design Principles
status: active
source_of_truth: target-design
product_area: arbor-manager
related:
  - "[[00 Home]]"
tags: [tui, principles]
---

# TUI Design Principles

## Complexity belongs underneath the operator experience

The operator should primarily think in terms of:

```text
Cluster
Nodes
Network
Access
Secrets
Deployments
Recovery
Attention
```

Registry generations, capability provenance, provider sockets, Ygg identities, route validation records, deployment adapter internals, and OpenBao mechanics remain available when needed without dominating ordinary workflows.

## Nodes are the primary object

A machine is the main human-recognizable object. Identity, relationships, routes, access, services, runtime state, deployment state, and recovery context converge in Node Detail rather than becoming disconnected top-level worlds.

## Friendly names before stable identity

Human-friendly names are primary. Stable IDs, generations, fingerprints, and exact endpoints are secondary and copyable.

## Problems before green detail

Healthy state compresses. Degraded state expands and explains impact and next action. Do not turn raw `0`, `false`, or `null` fields into the primary operator language.

## Explain dependencies and next actions

A blocked state should explain what is complete, what is waiting, and what action can advance it. Bootstrap should feel like a dependency-aware checklist, not a wall of failures.

## Trust is not transport

The UI must preserve distinctions such as:

- Registry acceptance does not mean a route is currently reachable.
- Ygg reachability does not imply Arbor trust.
- SSH reachability does not imply Arbor enrollment.
- A configured route does not imply it is observed, validated, or selected.
- OpenBao installed does not imply initialized or unsealed.
- A deployment request/acknowledgement does not imply successful activation.

## Bootstrap is different from steady state

A new/recovered physical host may require one explicit local/operator NixOS activation to install enough Arbor runtime to join the system. That is a bootstrap handoff, not the steady-state deployment model.

Once a node is enrolled and has usable accepted routes/access, the normal operator concept is an Arbor deployment: select targets, inspect immutable intent/plan, acknowledge risk, execute through the configured deployment path, observe per-node results, and retain receipts/resume state.

## Published/locked code is physical truth

For physical deployment, the UI should surface the component revisions actually consumed by the committed root flake/lock when that matters. Local component overrides are development context and must not be presented as the running physical version unless explicitly active.

## Safe by default

Opening a page, refreshing state, exploring a graph, or viewing a plan is read-only. Destructive, security-sensitive, identity, recovery, secret, or deployment actions require explicit intent and authoritative validation.

## Teach the underlying system

Every meaningful page/action should expose its copyable CLI equivalent where practical. The TUI is a discoverable operator surface over Arbor, not magic that hides it.

## Bootstrap access remains visible

When managed Arbor routing is degraded, the UI should still represent independent bootstrap/recovery access such as LAN SSH separately. Managed trust failure and basic host reachability are not the same thing.
