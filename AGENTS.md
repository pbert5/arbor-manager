# Nix Arbor agent guide

Nix Arbor is a small composition flake for independently versioned Nix
components. Keep the root flake focused on composition; large components
belong in independent flakes and repositories.

## Workspace rules

- One agent task = one branch = one worktree. Do not edit another agent's
  checkout or use the primary checkout for task changes.
- Use `agent/<agent-or-role>/<task-slug>` for agent branches. Prefer the
  `scripts/agent-worktree` helper, with worktrees outside this repository.
- Read the closest `AGENTS.md` before changing a subtree. `packages/` contains
  active component checkouts; `references/` contains material for inspection,
  not dependencies to modify casually.
- Keep changes scoped to the request. Do not silently change architecture or
  port whole subsystems from a reference repository.

## Change and handoff expectations

- Prefer native Nix and Git commands. Run the narrowest useful checks, then
  `nix flake check` when the flake or shared tooling changes.
- Format changed Nix files with `nix fmt` and make coherent local commits.
- Do not use `git reset --hard`, `git clean -fdx`, force-push, or destructive
  cleanup as shortcuts. Agents do not push unless explicitly asked.
- A normal completed task merges its validated commit into the identified base
  branch, verifies the merged base, then removes its clean worktree and stale
  merged local agent branch. Stop at a committed handoff instead when
  validation fails, work is incomplete, conflicts remain, coordination or
  review is required, deployment approval is needed, the base is unclear, or
  the merge could overwrite newer work.
- After merging, inspect `git status` and a recent `git log --graph`, then rerun
  the relevant validation against the merged base. Never treat a successful
  merge exit code as sufficient.
- Resolve conflicts semantically by inspecting both sides; do not choose whole
  files with `ours` or `theirs` as a shortcut. Preserve independent entries in
  sensitive integration and workflow files.
- A handoff names the branch and worktree, commit SHA(s), summary, changed
  files, validation, known issues, and review readiness. See
  `docs/agent-workflows.md`.
- Delegate isolated search, documentation, testing, or review work to a
  focused subagent. Reserve architectural decisions and integration for the
  owning agent.

Nix teaching material belongs in `cheats/` and `docs/`, not in this durable
repository policy.
