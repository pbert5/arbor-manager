---
id: arbor-tui-metadata
type: conventions
title: Metadata and Conventions
status: active
source_of_truth: target-design
product_area: arbor-manager
related:
  - "[[00 Home]]"
  - "[[01 Principles]]"
tags: [tui, conventions]
---

# Metadata and Conventions

## Page frontmatter

Page specifications should normally identify:

```yaml
id: arbor-tui-page-...
type: page
title: ...
status: proposed | active | retired
source_of_truth: target-design
product_area: arbor-manager
audience: [operator, administrator]
implementation_status: missing | partial | implemented
opened_from: []
related_components: []
related_workflows: []
effects: read-only | managed-change | security-sensitive
```

## Status vocabulary

Use text/symbol semantics that survive monochrome terminals:

```text
● healthy / ready / accepted / active
◐ degraded / partial / waiting
○ unavailable / offline / not initialized
! operator attention required
× failed / rejected
… operation pending
```

Color may reinforce status but never carries meaning alone.

## Identity presentation

Preferred:

```text
eVolver
Arbor ID       node:8ab4…
Generation     2
Fingerprint    SHA256:…
```

Do not lead ordinary rows with long IDs.

## Time and freshness

Observed/live projections should state freshness when stale state could mislead the operator:

```text
Last observed  11s ago
Registry       current
Runtime status 42s old
```

Stale last-known state remains useful if clearly labeled.

## Intent, observation, and effect

Use precise wording:

```text
Requested
Accepted
Planned
Executing
Activated
Verified
Observed
Failed
```

Do not collapse these into a generic `success` label when they mean different things.

## CLI equivalent

A page/action may expose a low-emphasis footer such as:

```text
CLI  arbor-manager doctor
```

or an exact command assembled from the current context. Never show secret values or acknowledgement material merely for convenience.

## Terminal widths

- Wide: 120+ columns — full navigation, split layouts, small topology graph.
- Standard: 80–119 columns — single-column sections and compressed tables.
- Narrow: below 80 columns — entity, status, attention, next action first; secondary metadata moves behind details.

The TUI must remain useful over SSH.
