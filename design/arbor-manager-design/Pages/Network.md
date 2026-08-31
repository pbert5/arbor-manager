---
id: arbor-tui-page-network
type: page
title: Network
status: active
source_of_truth: target-design
product_area: arbor-manager
audience: [operator, administrator]
implementation_status: missing
opened_from: ["[[Overview]]", "[[Node Detail]]"]
effects: read-only-by-default
---

# Network

## Purpose

Answer: **Can my nodes reach each other, which routes are actually being used, and why?**

The screen must make discovery, trust, transport, route validation, and selected path visibly distinct.

## Healthy cluster target

```text
+-- Network --------------------------------------------------------+
| Overview  Nodes  Network  Access  Secrets  Deploy  Recovery  Diag |
+-------------------------------------------------------------------+
| PRIVATE NETWORK                                      ● Converged  |
|                                                                   |
|                    +-------------+                                |
|                    |   r640-0    |                                |
|                    |      ●      |                                |
|                    +------|------+                                |
|                         /   \                                     |
|                        /     \                                    |
|              +--------v--+  +-v----------+                        |
|              |desktoptoodle|--| eVolver  |                        |
|              |     ●      |  |     ●      |                        |
|              +------------+  +------------+                        |
|                                                                   |
| Ygg mesh      3 / 3 nodes       ● converged                       |
| Routes        6 / 6 expected    ● valid                           |
| Provider      3 / 3 ready       ●                                 |
+-- CONNECTIONS ----------------------------------------------------+
| NODE            TARGET          ROUTE          STATE       RTT     |
| r640-0          desktoptoodle   private-ygg    ● selected   8 ms   |
| r640-0          eVolver         private-ygg    ● selected  14 ms   |
| desktoptoodle   eVolver         private-ygg    ● selected  12 ms   |
+-- ATTENTION ------------------------------------------------------+
| No network issues require attention.                              |
+-------------------------------------------------------------------+
| Enter inspect route   f filter   v view mode   ? help      q quit |
+-------------------------------------------------------------------+
```

The graph is a small-cluster convenience. The connection/route list is the scalable canonical view.

## Degraded route example

```text
PRIVATE NETWORK                                     ◐ Degraded

r640-0 ------ desktoptoodle
   |
   x
 eVolver

! r640-0 -> eVolver

Preferred private-Ygg route failed validation.
Available fallback: LAN 192.168.86.31

Trust       accepted
Registry    current
Transport   Ygg peer unreachable
Fallback    reachable

[Inspect route] [Test reachability] [Open eVolver]
```

The wording must preserve that **trust can remain accepted while transport is unavailable**.

## Route inspector

```text
r640-0 -> eVolver

SELECTED ROUTE
private-ygg
address      200:…
validated    8s ago
latency      14 ms

TRUST
relationship     accepted
source           Registry
generation       current

TRANSPORT
Ygg identity     9c6339…
peer observed    yes

FALLBACKS
LAN              192.168.86.31   reachable

CLI
arbor-manager network route r640-0 eVolver
```

## Network state model

The TUI should be capable of presenting these independent dimensions:

```text
discovered
accepted/trusted
transport observed
route configured
route validated
route selected
fallback reachable
stale/unobserved
```

Do not compress all of them into a single `connected` boolean.

## Private Ygg

Private Ygg is transport, not trust. Desired peer state should be understood as derived from accepted Registry/network-manager state, not as an independent static trust list.

## Bootstrap reachability

Bootstrap LAN/SSH may remain available while managed Arbor/Ygg routes are not. The Network and Node Access views should make that recovery path visible without treating it as the preferred steady-state route.
