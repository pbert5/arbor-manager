# Agent-first workflows

The repository contract is **one task = one branch = one worktree**. The
primary checkout is for integration and review; agents work in sibling
directories under `../nix-arbor-worktrees/`.

## Starting work

The helper creates `agent/<agent-or-role>/<task-slug>` and initializes
submodules:

```sh
./scripts/agent-worktree new workspace-infra luna
cd ../nix-arbor-worktrees/agent-luna-workspace-infra
nix develop
```

Native Git equivalent:

```sh
git worktree add -b agent/luna/my-task ../nix-arbor-worktrees/agent-luna-my-task HEAD
git -C ../nix-arbor-worktrees/agent-luna-my-task submodule update --init
```

Start Codex or Claude only after entering that worktree:

```sh
codex
claude
```

Codex Cloud environments can select `scripts/codex-setup` as their supported
setup script. It initializes direct submodules and evaluates the dev shell
non-interactively; the cloud image must provide Nix. Run non-interactive
checks such as `nix flake check`; authentication and personal settings stay
outside the repository. Submodules are explicit: `git submodule update --init`.
If a child repository has its own valid
`.gitmodules`, initialize that child recursively with
`git -C packages/<component> submodule update --init --recursive`.

## Delegation and handoff

Use the small role briefs in `.agents/roles/`. Delegate isolated research,
search, test investigation, or review; keep architecture and integration in
the owning session. Claude wrappers live in `.claude/agents/`, and Codex
custom agents are registered under `.codex/agents/`.

A normal handoff includes branch, worktree path, commit SHA(s), summary, files
changed, validation, known issues, and whether it is ready for review. A
reviewer should inspect `git diff <base>...<branch>` and the branch's checks
before cherry-picking or merging.

## Completion and merge

For a normal task, a validated agent branch merges itself into its identified
base branch before reporting completion:

```text
isolated worktree -> implement -> validate -> commit -> review/check
    -> merge into intended base -> verify the merged base -> clean up
```

After the merge, verify `git status`, inspect a recent graph with
`git log --graph --decorate --oneline`, and rerun the relevant checks against
the merged base. For Nix Arbor this normally includes `nix flake check` and
the focused component checks. A successful `git merge` exit code alone is not
completion.

Do not merge when validation fails, the task is incomplete, conflicts remain,
another agent is changing the same integration area, review was explicitly
requested first, production/deployment approval is required, the base is
unclear, or the merge could discard newer work. In those cases commit a
handoff and report the reason.

Resolve conflicts semantically: inspect both sides and preserve independent
entries. Never select whole-file `ours` or `theirs` merely to make a conflict
disappear. Take extra care with `flake.nix`, `flake.lock`, `.gitmodules`,
integration modules, `DEV.md`, `AGENTS.md`, `CLAUDE.md`, `Justfile`, and
`.vscode/tasks.json`.

## Worktree lifecycle and safe cleanup

```sh
./scripts/agent-worktree list
./scripts/agent-worktree status
./scripts/agent-worktree remove my-task
./scripts/agent-worktree cleanup-merged
./scripts/agent-worktree prune
```

The helper refuses to remove a dirty or unmerged agent branch by default and
never runs `git reset --hard` or `git clean`. A clean agent branch whose
commits are ancestors of the configured base is a candidate for
`cleanup-merged`: the helper removes its worktree, prunes its metadata, and
deletes only the merged local branch. It never deletes remote branches.
Inspect `git worktree list` and `agent-worktree status` first; leave branches
that are dirty, unmerged, or still needed by another active effort in place.
`--force` is available only on an explicitly named `remove` command. Bulk
cleanup never accepts force.

Native commands remain useful:

```sh
git worktree add -b agent/name/task ../nix-arbor-worktrees/agent-name-task HEAD
git worktree list
git worktree remove ../nix-arbor-worktrees/agent-name-task
git worktree prune
git branch --merged main
```

`packages/` child repositories have independent branches and worktrees; this
helper manages Nix Arbor only. The `references/flake-devbox` submodule is
legacy/reference material: inspect it, but do not normally modify it or make
new code depend on it.
