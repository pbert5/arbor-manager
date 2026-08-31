---
id: arbor-tui-vault-home
type: index
title: Arbor Manager TUI Design Vault
status: active
source_of_truth: target-design
product_area: arbor-manager
tags: [tui, ui-spec, product-design, obsidian]
---

# Arbor Manager TUI Design Vault

This vault describes the target operator experience for `arbor-manager tui` independently from the current Bash prototype and current CLI/runtime implementation.

The vault answers **what should the operator experience be?** Arbor Manager, Arbor Registry, Arbor Network Manager, Nix Arbor, and their tests answer **what is currently implemented?**

## Current alignment baseline

Design was seeded against:

- Nix Arbor integration branch `codex/arbor-operator-migration` at `894b8e628ad06aa0f06485c9e343dbeb55ce3f0e`.
- Arbor Manager integration branch `integration/nix-arbor-operator-migration` at `4eb20b5f41a5a39fe3d428129aeb80a0b5dd60a8`.
- Published/locked component consumption is the deployment baseline; local component snapshots are development aids, not physical deployment truth.
- The first physical NixOS activation of a new/recovered host may be an explicit operator handoff with local `sudo nixos-rebuild switch`; after Arbor enrollment, steady-state deployment is represented as Arbor-managed intent, plan, execution, and receipts.

The design must not expose the historical implementation detail of an operator-supplied backend executable as the primary user concept. Backends/adapters remain inspectable implementation details behind deployment planning and execution.

## Start here

- [[01 Principles]]
- [[02 Metadata and Conventions]]
- [[03 Navigation]]
- [[Decisions/Bootstrap and Managed Deployment]]

## Pages

- [[Pages/Overview]]
- [[Pages/Node Detail]]
- [[Pages/Network]]

Planned follow-on pages:

- Nodes
- Access
- Secrets
- Deployments
- Recovery
- Diagnostics

## Product relationship

```text
TUI Design Vault
"What should the operator experience be?"
        |
        | implementation + acceptance
        v
Arbor Manager CLI/runtime contracts
"What behavior exists?"
        |
        +--> CLI
        +--> TUI renderer
        +--> automation / scripting
```

## Editing rules

1. Prefer normal Markdown and wiki links.
2. Use YAML frontmatter for machine-readable relationships.
3. Use ASCII layouts for durable, diffable terminal geometry.
4. Images and Claude Design exports may supplement a page but never replace its written contract.
5. Friendly names are primary; stable IDs/fingerprints remain visible as secondary identity.
6. Every status must preserve the difference between trust, transport, observation, intent, and completed effect.
7. Destructive/security-sensitive actions require explicit confirmation through authoritative Arbor contracts.
8. Design may lead implementation. Mark missing behavior rather than silently changing the design to match a temporary implementation limitation.
9. Keep bootstrap/recovery access independent enough that loss of Registry/Ygg/OpenBao does not imply loss of basic host access.
