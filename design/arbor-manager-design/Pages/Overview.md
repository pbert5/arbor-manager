---
id: arbor-tui-page-overview
type: page
title: Overview
status: active
source_of_truth: target-design
product_area: arbor-manager
audience: [operator, administrator]
implementation_status: missing
opened_from: ["[[03 Navigation]]"]
related_pages: ["[[Node Detail]]", "[[Network]]"]
effects: read-only
---

# Overview

## Purpose

Answer: **Is Arbor okay right now, and what needs my attention?**

This is the default landing screen. It is not a daemon/metrics dump.

## Healthy/degraded cluster target

```text
+-- Arbor Manager --------------------------------------------------+
| Overview  Nodes  Network  Access  Secrets  Deploy  Recovery  Diag |
+-------------------------------------------------------------------+
| HOME CLUSTER                                      r640-0 - local  |
| Last refreshed 8s ago                                  [Refresh] |
|                                                                   |
| CLUSTER                                                           |
|                                                                   |
| ● Nodes       3 / 3 ready        ● Registry      healthy          |
| ● Network     mesh converged     ◐ OpenBao       2 / 3 ready      |
| ● Access      healthy            ● Deployments   idle             |
|                                                                   |
+-- NODES -----------------------------------------------------------+
| ● r640-0          Ready        authority   Ygg ●   Bao ●           |
| ● desktoptoodle   Ready        peer        Ygg ●   Bao ●           |
| ◐ eVolver         Degraded     child       Ygg ●   Bao sealed      |
|                                             [Open nodes ->]       |
+-- ATTENTION -------------------------------------------------------+
| ! eVolver — OpenBao sealed                                        |
|   Secret consumers are unavailable.                               |
|   Registry, SSH, and private Ygg remain reachable.                |
|                                             [Investigate ->]      |
+-------------------------------------------------------------------+
| CLI  arbor-manager doctor                                         |
| up/down move   Enter open   / search   ? help            q quit   |
+-------------------------------------------------------------------+
```

## Cluster summary

Compress the system into a small set of operator domains:

- nodes
- Registry
- network
- OpenBao/secrets
- access
- deployments

Internal provider/vaultd/systemd detail belongs in Diagnostics or Node Runtime.

## Attention ordering

Order by operator impact:

```text
critical
operator action required
degraded
informational
```

A healthy cluster may simply say `No issues require attention.`

## Bootstrap mode

When the local host has Nix Arbor but is not yet fully enrolled, Overview transforms into dependency-aware bootstrap guidance rather than displaying a wall of red failures.

```text
+-- Arbor Setup — r640-0 -------------------------------------------+
| This machine has Nix Arbor installed but is not fully enrolled.   |
|                                                                   |
| ✓ Nix Arbor generation active                                    |
| ✓ Bootstrap SSH available                                        |
| ✓ Recovery source available                                      |
| ✓ Arbor Manager installed                                        |
| ✓ Runtime status contract                                        |
|                                                                   |
| ! Arbor identity not initialized                                 |
| · First Registry authority not established                       |
| · Private Ygg waiting for accepted Registry state                 |
| · OpenBao not initialized                                        |
|                                                                   |
| NEXT                                                              |
| Create this machine's Arbor identity.                             |
| [Begin identity bootstrap]   [Inspect details]                    |
+-------------------------------------------------------------------+
```

The checklist derives from authoritative state. Attempting a command never marks a step complete by itself.

## Selection behavior

- Node row -> [[Node Detail]]
- Network summary -> [[Network]]
- OpenBao/secrets summary -> Secrets
- Access summary -> Access
- Deployments summary -> Deployments
- Attention item -> the most specific diagnostic/detail destination
