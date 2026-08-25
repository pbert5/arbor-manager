# Arbor Registry migration matrix

| Legacy Flake Devbox capability | New owner | New interface | Status | Notes |
|---|---|---|---|---|
| OrbitDB/libp2p/Helia transport | arbor-registry transport provider | append/fetch provider boundary | Contract only | Live OrbitDB adapter remains follow-up |
| Signed registry events/canonical hashing | arbor-registry | typed envelope and signer interface | Runtime signer implemented | Production key authority remains external |
| Registry daemon/controller | arbor-registry runtime | accepted-state service boundary | Local runtime implemented | No production OrbitDB daemon yet |
| Reconciliation and materialization | arbor-registry | `reconcile` raw→accepted→materialized | Implemented/tested | Legacy receipt/burn policy still incomplete |
| Enrollment and membership | arbor-registry runtime | identity/relationship record families | Schema contract | Enrollment workflow remains follow-up |
| Relationship graph | arbor-registry | signed relationship projection and graph queries | Implemented/tested | Explicit peer-edge integration is active work |
| Machine inventory | arbor-manager | `sources`/`machinesPath` normalized entries | Implemented/tested | Registry snapshot requires digest; merge policy is narrow |
| Hardware configuration | trusted local composition | structured facts + local module selectors | Contract only | No executable Nix from registry |
| Service/endpoint discovery | arbor-registry | accepted endpoint/name/service views | Implemented/tested | Network adapters remain external |
| Secret release metadata | arbor-registry + OpenBao adapter | public policy/reference records | Contract only | No secret values in registry |
| OpenBao authority and runtime identity | OpenBao integration | `cluster.vault` metadata + runtime provider | Boundary + executable AppRole test | Production identity provisioning and approval verification remain external |
| systemd-vaultd delivery | systemd-vaultd provider | NixOS credential binding adapter | Boundary + executable readiness/rotation/no-leak test | Upstream module remains a pinned external input |
| Receipts/audit | arbor-registry | receipt record family | Schema only | End-to-end receipt streams remain follow-up |
| Cluster manager selectors | arbor-manager | pure graph selectors + offline CLI | Library implemented/tested | CLI implementation is active work |
| Bulk deployment | arbor-manager + Colmena | pure deployment plan/backend contract | Implemented/tested | No live SSH/Colmena execution yet |
| Fixed leader/follower roles | relationship graph | derived edge properties | Removed | Root machine records no longer declare roles |
| Git/SSH/Radicle registry transport | none in steady state | migration-only compatibility | Intentionally dropped | Not authoritative in new architecture |
| IPFS Cluster coordination | separate future component | external provider | Deferred | Outside registry authority model |
| Bao auto-unseal/TPM | separate security work | reviewed runtime integration | Deferred | Not implied by current flake |

The implementation deliberately stops at pure, testable boundaries where the
runtime authority or external service is not present. It does not claim a
working multi-host recovery, OpenBao, systemd-vaultd, OrbitDB, or Colmena
deployment until those integrations have their own executable tests.
