---
id: arbor-tui-decision-bootstrap-managed-deployment
type: design-decision
title: Bootstrap and Managed Deployment
status: active
source_of_truth: target-design
product_area: arbor-manager
related_pages:
  - "[[Pages/Overview]]"
  - "[[Pages/Node Detail]]"
tags: [deployment, bootstrap, design-decision]
---

# Bootstrap and Managed Deployment

## Decision

The TUI distinguishes **bootstrap activation** from **steady-state managed deployment**.

## Bootstrap activation

A physical node that does not yet have the Arbor runtime/identity/routes needed for managed deployment may require an explicit operator handoff such as a local or SSH session followed by:

```text
sudo nixos-rebuild switch --flake ...#host
```

The TUI may guide this action, show the exact safe command, and verify the resulting state afterward. It must not pretend this is an Arbor-managed deployment if Arbor cannot yet reach or authenticate the node through its managed deployment path.

Bootstrap access and recovery material remain independent enough to preserve recoverability if Registry, private Ygg, OpenBao, or other managed services are degraded.

## Steady-state deployment

Once a node is enrolled and has accepted deployment reachability, the operator concept becomes:

```text
choose target(s)
      ↓
resolve current accepted state
      ↓
create immutable deployment plan
      ↓
show exclusions / risks / canary / batches
      ↓
explicit acknowledgement
      ↓
execute configured deployment path
      ↓
per-node result + receipt
      ↓
resume/retry if appropriate
      ↓
observe actual activated state
```

The UI should emphasize the immutable plan and observed outcome, not the implementation detail of which adapter executable currently bridges the plan to direct NixOS/SSH or Colmena.

## Backends are advanced detail

Current Arbor Manager implementation supports backend recommendations and adapter execution boundaries. These remain real implementation contracts, but the target TUI treats them as deployment-engine details unless the operator must choose or repair one.

Possible advanced detail:

```text
Deployment engine
recommended      direct
configured path  direct NixOS activation
plan digest      sha256:…
receipt           available
```

Do not present `--backend-executable` as the everyday mental model.

## Published/locked revision discipline

A deployment candidate should make it possible to inspect which published component revisions the root flake lock consumes. Local `packages/` overrides are development aids and should be clearly labeled if an operator deliberately uses them.

## Success language

Use precise milestones:

```text
planned
acknowledged
executing
activation returned success
node reconnected
running generation observed
verification passed
```

Do not call a deployment complete merely because an adapter process returned zero if the system has not yet observed the intended running state.
