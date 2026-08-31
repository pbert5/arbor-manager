# Claude Design Handoff

This directory is intended to become the standalone `pbert5/arbor-manager-design` repository and then be mounted into Arbor Manager as a Git submodule.

Until that repository exists, this design-reference branch is the collaboration source for the seeded vault.

## Authority

Treat these Markdown specifications as target-design authority for:

- information hierarchy
- terminal layout/geometry
- navigation
- interaction presentation
- status language
- operator mental model
- responsive terminal behavior
- explicitly described visual states

Treat the current Arbor repositories as functional/domain authority for:

- Registry trust and authority semantics
- capability/provenance rules
- identity generations and recovery semantics
- network/provider behavior
- deployment plan/acknowledgement/receipt contracts
- OpenBao boundaries
- SSH/bootstrap access
- secret redaction
- actual CLI/API syntax

Do not silently alter functional semantics to make a visual concept easier.

## Claude Design refinement goals

The seeded ASCII screens intentionally establish information architecture before styling. Refinement should explore:

1. Overall terminal visual language and density.
2. Wide, standard, and narrow layouts.
3. Overview hierarchy and attention treatment.
4. Node Detail tabs/inspectors and action placement.
5. Network graph versus route-table balance.
6. Bootstrap-mode progression.
7. Status symbols, typography, separators, and focus/selection treatment.
8. Help/command-palette/action-menu presentation.
9. Destructive confirmation flows without weakening Arbor acknowledgements.

## Preserve during refinement

- Nodes remain the primary object.
- Trust, transport, route, observation, intent, and effect remain distinct.
- Bootstrap/local activation remains distinct from steady-state Arbor-managed deployment.
- CLI equivalents remain discoverable.
- Friendly names lead; stable identities remain visible.
- Healthy information compresses; problems explain themselves.
- Basic SSH/recovery reachability must not be confused with managed Arbor health.

## Suggested deliverables

For each major screen, produce at least:

- wide terminal target
- standard terminal target
- narrow/SSH target
- selected/focused state
- degraded/attention state
- empty/not-yet-enrolled state when applicable

If using Claude Design generated HTML, export/download the Standalone HTML as a visual reference artifact. It should supplement, not replace, the Markdown contracts.
