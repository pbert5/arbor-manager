---
id: arbor-tui-page-node-detail
type: page
title: Node Detail
status: active
source_of_truth: target-design
product_area: arbor-manager
audience: [operator, administrator]
implementation_status: missing
opened_from: ["[[Overview]]", "Nodes", "[[Network]]"]
related_pages: ["[[Network]]"]
effects: read-only-by-default
---

# Node Detail

## Purpose

Answer: **Tell me everything operationally important about this machine.**

Node Detail is the center of gravity for Arbor's human interface. Identity, relationships, routes, access, services, runtime state, deployment state, and recovery context converge here.

## Header

```text
< Nodes

eVolver                                               ◐ Degraded
edge experiment controller

Arbor ID       node:8ab4…
Generation     2
Last observed  11s ago

[SSH] [Deploy] [Actions v]
```

Friendly name is primary. IDs and fingerprints are secondary and copyable.

## Summary tab

```text
+-- eVolver --------------------------------------------------------+
| Summary Identity Relationships Routes Access Services Runtime     |
+-------------------------------------------------------------------+
| STATUS                                                            |
| Arbor          ● Accepted          SSH           ● Reachable       |
| Registry       ● Current           Private Ygg   ● Connected       |
| OpenBao        ◐ Sealed            Deployment    ● Current         |
|                                                                   |
| ! OpenBao is sealed                                               |
|   Secret consumers are currently unavailable.                     |
|                                         [Open Secrets ->]         |
+-- RELATIONSHIPS ---------------------------------------------------+
| Parent    r640-0          accepted   generation 4                  |
| Peer      desktoptoodle   accepted   generation 2                  |
|                                      [Open relationships ->]      |
+-- ROUTES ----------------------------------------------------------+
| ● private-ygg   preferred    200:…              14 ms              |
| ● LAN           fallback     192.168.86.31       2 ms              |
|                                             [Open routes ->]       |
+-- SERVICES --------------------------------------------------------+
| ● ssh                     reachable                               |
| ● evolver-controller      healthy                                 |
| ◐ secret-provider         waiting for Bao                         |
|                                           [Open services ->]       |
+-------------------------------------------------------------------+
| CLI  arbor-manager node inspect eVolver                           |
+-------------------------------------------------------------------+
```

## Identity

Show stable Arbor identity, current generation, public fingerprint, provenance, accepted state, and predecessor/successor or revocation state where relevant. Never show private key material.

```text
State          ● accepted
Generation     2
Fingerprint    SHA256:…
Provenance     rotated from generation 1
Authority      r640-0 / generation 4
Previous       generation 1 - retired
```

## Relationships

Relationships are trusted Registry graph edges. Do not use Ygg connectivity as a relationship synonym.

```text
PARENTS
● r640-0
  accepted
  capability: participant-management

PEERS
● desktoptoodle
  accepted

STANDBY / RECOVERY
none
```

## Routes

Distinguish configured, observed, validated, selected, fallback, and failed route states.

```text
PREFERRED
● private-ygg
  200:…
  validated 6s ago
  selected

FALLBACK
● LAN
  192.168.86.31
  reachable
```

## Access

Represent managed and bootstrap access independently.

```text
Operator
● laptop-primary
  SSH key SHA256:…
  bootstrap + managed

Deployment
● r640-0 -> eVolver
  deployer SHA256:…
  verified

Bootstrap recovery
● LAN SSH
  independent of Registry/Ygg
```

Never show private keys.

## Services

Show accepted service/endpoint records in human terms first, with raw endpoint identity available as detail.

## Runtime

Implementation-oriented state lives here:

- relevant systemd units
- Registry runtime/readiness
- network provider runtime
- vaultd/provider state
- OpenBao installed/initialized/sealed
- transport runtime
- status freshness
- running component revision when known

## Deploy action

`Deploy` opens the deployment workflow for this node. The normal concept is not "run arbitrary backend executable". The TUI presents target selection, immutable plan, risk, acknowledgement, execution status, receipts/resume state, and final observed activation. Backend/adapter choice is advanced detail unless operator intervention is actually required.

For a fresh host that has not joined Arbor, local/manual `nixos-rebuild switch` may appear as a **bootstrap operator handoff** rather than pretending Arbor can deploy to a node it cannot yet manage.
