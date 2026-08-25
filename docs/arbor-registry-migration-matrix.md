# Arbor Registry migration matrix

| Legacy Flake Devbox capability | New owner | New interface | Status | Notes |
|---|---|---|---|---|
| OrbitDB/libp2p/Helia transport | arbor-registry transport provider | append/fetch Unix-socket provider | Optional daemon extracted and convergence-tested | Bootstrap is explicit; production topology policy remains external |
| Signed registry events/canonical hashing | arbor-registry | typed envelope and signer interface | Runtime signer implemented | Production key authority remains external |
| Registry daemon/controller | arbor-registry runtime | accepted-state service boundary | Local runtime implemented | No production OrbitDB daemon yet |
| Reconciliation and materialization | arbor-registry | `reconcile` raw→accepted→materialized | Implemented/tested | Legacy receipt/burn policy still incomplete |
| Enrollment and membership | arbor-registry runtime | signed enrollment request + authority-approved node identity | Implemented/tested | Operator/parent approval policy remains deployment-specific |
| Relationship graph | arbor-registry | signed relationship projection and graph queries | Implemented/tested | Explicit peer edges and cohorts implemented |
| Machine inventory | arbor-manager | `sources`/`machinesPath` normalized entries | Implemented/tested | Registry snapshot requires digest; merge policy is narrow |
| Hardware configuration | trusted local composition | structured facts + content-addressed artifact references | Implemented/tested | Artifact fetching/signature verification remains external |
| Service/endpoint discovery | arbor-registry | accepted endpoint/name/service views | Implemented/tested | Network adapters remain external |
| Secret release metadata | arbor-registry + OpenBao adapter | public policy/reference records | Contract only | No secret values in registry |
| OpenBao authority and runtime identity | OpenBao integration | `cluster.vault` metadata + runtime provider | Boundary and OpenBao HTTP delivery implemented/tested | Production auth and multi-host recovery remain external |
| systemd-vaultd delivery | systemd-vaultd provider | NixOS credential binding contract | Initial fetch/readiness + watcher + real upstream VM delivery implemented | Long-lived process refresh still requires service-specific restart/update policy |
| Receipts/audit | arbor-registry + arbor-manager | signed runtime receipts + deployment receipts/resume | Implemented/tested | Distributed receipt stream replication remains follow-up |
| Cluster manager selectors | arbor-manager | pure graph selectors + offline CLI | Implemented/tested | CLI remains offline |
| Bulk deployment | arbor-manager + Colmena | digest-bound plan, acknowledgement, backend adapter, receipts | Opt-in direct/Colmena adapter implemented/tested | No real SSH/Colmena target was contacted |
| Fixed leader/follower roles | relationship graph | derived edge properties | Removed | Root machine records no longer declare roles |
| Git/SSH/Radicle registry transport | none in steady state | migration-only compatibility | Intentionally dropped | Not authoritative in new architecture |
| IPFS Cluster coordination | separate future component | external provider | Deferred | Outside registry authority model |
| Bao auto-unseal/TPM | separate security work | reviewed runtime integration | Deferred | Not implied by current flake |

The implementation deliberately stops at pure, testable boundaries where the
runtime authority or external service is not present. OrbitDB transport and
OpenBao HTTP delivery now have executable tests, and a NixOS VM validates the
upstream systemd-vaultd socket path; multi-host recovery and real Colmena/SSH
deployment remain external validation work.
