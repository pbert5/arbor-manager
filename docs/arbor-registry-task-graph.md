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
| EXTRACT-ARBOR-REGISTRY | DONE | audit + synthesis | worker; `packages/arbor-registry` | standalone registry library/flake |
| REGISTRY-RECONCILIATION | DONE | extraction + graph + compatibility | worker scope | accepted/materialized state, quarantine and tests |
| MANAGER-SOURCE-ABSTRACTION | DONE | manager audit + synthesis | worker; `packages/arbor-manager` | pure source API, role removal, read-only metadata |
| SECRET-BOUNDARY-MODEL | DONE | audit + vault research | research | runtime-only identity/secret brief |
| MACHINE-RECORD-MODEL | DONE | manager audit + synthesis | research | normalized source/merge contract |
| NETWORK-INTERFACE-MODEL | DONE | graph + machine contract | research | provider-neutral runtime API |
| DEPLOYMENT-MODEL | DONE | graph + Colmena research | research | planner/backend contract |
| ROOT-REGISTRY-COMPOSITION | DONE | registry + manager outputs | lead; root flake | local component input and override wiring |
| REGISTRY-MACHINE-SOURCE | DONE | registry + manager + machine model | manager | pure digest-requiring snapshot adapter |
| MACHINE-SNAPSHOT-TOOLING | DONE | registry source | manager; `packages/arbor-manager` | inspect/export provenance and digest checks |
| OPENBAO-RUNTIME-IDENTITY | DONE | secret boundary + registry | registry; `packages/arbor-registry` | runtime identity generations and recovery boundary |
| SYSTEMD-VAULTD-INTEGRATION | DONE (boundary) | secret boundary + research | registry; `packages/arbor-registry` | runtime credential binding module; upstream vaultd/OpenBao remain injected |
| ENDPOINT-SERVICE-REGISTRY | DONE | network model + registry | worker | endpoints/services/runtime views and policy modules |
| NODE-SELECTION | DONE | registry source + graph | worker | selectors and copyable output |
| DEPLOY-PLANNER | DONE | deployment backend + selection | worker | plans/risk/acknowledgements |
| SECURITY-REVIEW | DONE | integrated implementation | reviewer | first review fixed MUST FIX findings |
| NIX-REVIEW | DONE | integrated implementation | reviewer | purity and store-boundary review; manager sanitization fixed |
| DISTRIBUTED-SYSTEMS-REVIEW | DONE | integrated registry | reviewer + fixer | schema/lineage/cycle/idempotency findings fixed |
| DEPLOYMENT-REVIEW | DONE | planner/backends | reviewer + fixer | ordering/cycle/backend/name findings fixed |
| FINAL-VALIDATION | DONE | reviews + fixes | lead + integration-test | all-systems component/root checks and pure scenarios passed |
| SOURCE-PRECEDENCE-MERGE | DONE | machine source + snapshot | worker; `packages/arbor-manager` | registry → local → session merge with provenance |
| VAULT-BINDING-VALIDATION | DONE | vault runtime boundary | worker; `packages/arbor-registry` | binding and public-identifier assertions |
| MULTI-NODE-RUNTIME-SCENARIO | DONE (test evidence) | runtime + recovery + manager | integration-test | root/parent/child/peer/standby scenario; live services not exercised |
| ARBOR-MANAGER-REMOTE | DONE | manager source integration | lead | standalone `pbert5/arbor-manager`, remote lock and local override |
| ARBOR-REGISTRY-REMOTE-SYNC | DONE | registry changes stabilized | lead | latest component published and root lock refreshed |
| DEPLOYMENT-REVIEW-FIX | DONE | deployment review | worker; manager | topology-safe canaries and snapshot-bound Colmena projection |
| RUNTIME-REVIEW-FIX | DONE | security/distributed review | worker; registry runtime | compatibility, lineage, malformed/conflict quarantine and locking |
| SECURITY-BOUNDARY-FIX | DONE (model boundary) | security review | worker; registry/manager | recovery/vault identifiers, recursive protections, redacted inspection |
| FINAL-GAP-AUDIT | DONE WITH FOLLOW-UPS | all integrated work | lead + reviewers | checks pass; recovery, upstream systemd-vaultd, and real remote deployment remain external |
| ORBITDB-ADAPTER | DONE (optional daemon) | runtime Provider boundary | worker; `packages/arbor-registry/transport` | extracted OrbitDB/Helia daemon and executable two-daemon convergence test |
| EXPLICIT-PEER-EDGES | DONE | graph model | worker; `packages/arbor-registry/lib` | explicit peer records, cohorts, and selectors |
| ARBOR-CLI | DONE (offline + opt-in provider) | snapshot/selector/planner APIs | worker; `packages/arbor-manager` | inspect/list/export/plan and digest-bound direct provider execution |
| DEPLOYMENT-ACK-EXECUTION | DONE (opt-in direct provider) | deployment planner + CLI | worker; `packages/arbor-manager` | immutable plan/ack checks and mocked backend execution; no real host contacted |
| VAULT-RUNTIME-TEST | DONE (mock + OpenBao HTTP) | vault boundary | worker; `packages/arbor-registry` | readiness/rotation/no-leakage contract plus OpenBao dev-server delivery test |
| ACCEPTANCE-HARNESS | DONE (synthetic) | runtime + manager APIs | integration-test; repository tests | end-to-end pure scenario; live capabilities documented |
| HARDWARE-SNAPSHOT-SOURCE | DONE (validation) | machine-record model | worker; `packages/arbor-manager` | structured facts/content-addressed artifact references |
| TRANSPORT-CONVERGENCE-FIX | DONE (bounded) | optional OrbitDB daemon | worker; registry transport/runtime | peer bootstrap, replicated indexing, cursor forwarding, atomic index writes |
| SECURITY-HARDENING-ROUND-2 | DONE | final security review | workers; registry/manager | socket fail-closed, CLI redaction, recovery verifier/rotation safeguards |
| TRANSPORT-LOCK-OWNERSHIP-FIX | DONE | post-fix distributed/security review | worker; `packages/arbor-registry/transport` | ownership-safe stale takeover, heartbeat, and old-owner release tests |
| PROVIDER-EXECUTION-HARDENING | DONE | security review | lead; registry runtime + manager CLI | bounded/timed provider commands, contained backend stderr, full backend response identity |
| TRANSPORT-REPLAY-RECOVERY-HARDENING | DONE | distributed review | lead; registry transport | duplicate-event convergence, unreadable-record cursor retry, bounded quarantine, private state permissions |
| FINAL-POSTFIX-REVIEW | DONE | provider/transport hardening | independent security + distributed reviewers | no MUST-fix findings; token/restart/socket-parent SHOULD hardening also applied |

The lead dispatches a newly unblocked row immediately; this table is not a
serial phase plan. Research agents may finish without changing repository
state; mutable workers own one branch/worktree and report commits.
