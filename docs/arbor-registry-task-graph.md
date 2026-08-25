# Arbor Registry task graph

Lead-maintained queue for the extraction. States use the repository workflow:
`READY`, `IN_PROGRESS`, `BLOCKED`, `INTEGRATION`, `REVIEW`, `VALIDATION`,
`DONE`.

| ID | State | Dependencies | Owner / write set | Deliverable |
|---|---|---|---|---|
| REGISTRY-AUDIT | DONE | — | research | legacy classification and evidence |
| ARBOR-MANAGER-AUDIT | DONE | — | research | current API and source seam |
| SYSTEMD-VAULTD-RESEARCH | DONE | — | research | credential integration evidence |
| COLMENA-RESEARCH | DONE | — | research | backend contract and risks |
| GRAPH-MODEL | DONE | — | architecture | relationship and SCC invariants |
| COMPATIBILITY-MODEL | DONE | — | architecture | envelope/quarantine rules |
| ARCHITECTURE-SYNTHESIS | DONE | six discovery tasks | lead | frozen boundary in `docs/arbor-registry-architecture.md` |
| EXTRACT-ARBOR-REGISTRY | IN_PROGRESS | audit + synthesis | worker; `packages/arbor-registry` | standalone registry library/flake |
| REGISTRY-RECONCILIATION | IN_PROGRESS | extraction + graph + compatibility | same worker scope | accepted/materialized state and tests |
| MANAGER-SOURCE-ABSTRACTION | IN_PROGRESS | manager audit + synthesis | worker; `packages/arbor-manager` | pure source API and role removal |
| SECRET-BOUNDARY-MODEL | IN_PROGRESS | audit + vault research | research | runtime-only identity/secret brief |
| MACHINE-RECORD-MODEL | IN_PROGRESS | manager audit + synthesis | research | normalized source/merge contract |
| NETWORK-INTERFACE-MODEL | IN_PROGRESS | graph + machine contract | research | provider-neutral runtime API |
| DEPLOYMENT-MODEL | IN_PROGRESS | graph + Colmena research | research | planner/backend contract |
| ROOT-REGISTRY-COMPOSITION | BLOCKED | registry + manager outputs | lead/worker; root flake | inputs, overrides, exports, checks |
| REGISTRY-MACHINE-SOURCE | BLOCKED | registry + manager + machine model | future worker | immutable snapshot adapter |
| MACHINE-SNAPSHOT-TOOLING | BLOCKED | registry source | future worker | inspect/export provenance |
| OPENBAO-RUNTIME-IDENTITY | BLOCKED | secret boundary + registry | future worker | runtime identity module |
| SYSTEMD-VAULTD-INTEGRATION | BLOCKED | secret boundary + research | future worker | thin NixOS binding module |
| ENDPOINT-SERVICE-REGISTRY | BLOCKED | network model + registry | future worker | endpoints/services/runtime views |
| NODE-SELECTION | BLOCKED | registry source + graph | future worker | selectors and copyable output |
| DEPLOY-PLANNER | BLOCKED | deployment backend + selection | future worker | plans/risk/acknowledgements |
| SECURITY-REVIEW | BLOCKED | integrated implementation | reviewer | adversarial findings |
| NIX-REVIEW | BLOCKED | integrated implementation | nix specialist | purity/store/flakes review |
| DISTRIBUTED-SYSTEMS-REVIEW | BLOCKED | integrated registry | reviewer | convergence/replay review |
| DEPLOYMENT-REVIEW | BLOCKED | planner/backends | reviewer | deployment safety review |
| FINAL-VALIDATION | BLOCKED | reviews + fixes | lead | clean-checkout flake checks and scenarios |

The lead dispatches a newly unblocked row immediately; this table is not a
serial phase plan. Research agents may finish without changing repository
state; mutable workers own one branch/worktree and report commits.
