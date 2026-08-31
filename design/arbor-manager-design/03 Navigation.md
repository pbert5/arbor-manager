---
id: arbor-tui-navigation
type: navigation-model
title: Navigation
status: active
source_of_truth: target-design
product_area: arbor-manager
related_pages:
  - "[[Pages/Overview]]"
  - "[[Pages/Node Detail]]"
  - "[[Pages/Network]]"
tags: [tui, navigation]
---

# Navigation

The main navigation exposes operator concepts, not every internal Arbor subsystem.

## Target information architecture

```text
Overview
Nodes
Network
Access
Secrets
Deployments
Recovery
Diagnostics
```

Detail screens are opened contextually and do not need top-level entries.

```text
Nodes
  +-- Node Detail
       +-- Summary
       +-- Identity
       +-- Relationships
       +-- Routes
       +-- Access
       +-- Services
       +-- Runtime
```

## Persistent shell

Wide target:

```text
+-- Arbor Manager --------------------------------------------------+
| Overview  Nodes  Network  Access  Secrets  Deploy  Recovery  Diag |
+-------------------------------------------------------------------+
|                                                                   |
|                         PAGE CONTENT                              |
|                                                                   |
+-------------------------------------------------------------------+
| up/down move   Enter open   / search   : command   ? help   q quit|
+-------------------------------------------------------------------+
```

## Global keys

```text
Up / Down      move
j / k          move
Enter          open / activate
Esc            back / close
Tab            next section
Shift+Tab      previous section
/              search / filter
:              command palette
?              contextual help
r              refresh
q              quit/back according to context
```

Do not put destructive operations on easy single-key shortcuts.

## Command palette

The `:` palette exposes available operations in the current state, for example:

```text
> doctor
  open node
  inspect routes
  plan deployment
  bootstrap identity
  open recovery
```

Unavailable operations may remain discoverable when useful but must explain why they are unavailable.
