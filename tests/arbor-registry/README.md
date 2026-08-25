# Arbor Registry synthetic acceptance harness

This is a repository-level, pure-Nix scenario for the extracted registry and
manager contracts. It models `root-A -> parent-B -> child-C/child-D`, a
peer `peer-P`, and a standby relationship. It checks:

- deterministic transport convergence and duplicate idempotence;
- signed source resolution and materialized endpoint/service views;
- local, descendant, peer, and accessible selectors, including quarantine of
  incompatible and standby nodes;
- registry → local → session source precedence and provenance;
- secret-like values and security-authority overrides are rejected;
- required-feature compatibility quarantine does not enter materialized state;
- recovery generation authorization and revocation of the old generation;
- canary/batch deployment planning, critical-route risk, and unsafe target
  rejection.

Run the expression from the repository root:

```sh
nix eval --impure --expr \
  'let f = builtins.getFlake (toString ./.); in import ./tests/arbor-registry/acceptance.nix { lib = f.inputs.nixpkgs.lib; }'
```

Expected result: `true`.

## Workflow and live-boundary checks

The acceptance scenario is intentionally pure: Nix does not contact a
registry transport, OpenBao, systemd-vaultd, SSH, or Colmena. The following
commands exercise the repository workflow around it:

```sh
./scripts/agent-worktree status
git worktree list
git -C packages/AshDesktopApps status --short --branch
git -C packages/AshZsh status --short --branch
git -C packages/tiling-desktop status --short --branch
```

The expected safety behavior is that the agent worktree is separate from the
primary checkout, direct submodules are initialized, and no submodule is
modified by this harness. On a dirty or unmerged named worktree, removal must
be refused:

```sh
./scripts/agent-worktree remove acceptance-harness
```

This command is expected to fail with a dirty/unmerged-worktree refusal while
the task branch is active. Do not add `--force`; it is a safety check, not a
cleanup step.

## Missing live capabilities

These are not claimed by this pure Nix harness; separate executable checks
cover the transport and OpenBao HTTP provider where noted:

- production OrbitDB/Helia topology policy, network partitions, and
  signed live replication beyond the repository's two-daemon convergence
  check;
- OpenBao authorization policy, production auth, systemd-vaultd credentials,
  and proof under a real NixOS service manager; the package check exercises
  OpenBao dev-server HTTP delivery and rotation reads;
- real SSH or `nixos-rebuild` execution, Colmena invocation, host reachability,
  canary acknowledgement, rollback, and deployment receipts;
- cryptographic verification of recovery approvals in the pure recovery model;
- live submodule fetch/authentication and nested-submodule behavior beyond the
  initialized direct submodules checked above.
