# Nix Arbor

Nix Arbor is a small, modern Nix integration flake: an explicit composition
layer for independently versioned flakes.

It is not the permanent home of every package, module, machine identity,
service, secret, or cluster record. Those belong in focused child repositories
when they become real.

## Start here

```sh
nix develop
```

The default development shell is powered by AshZsh. It activates an isolated
Home Manager generation under `/tmp/nix-arbor-ashzsh` and starts AshZsh's Zsh
for interactive sessions. The generation is cached by activation-package
identity and does not modify the normal home configuration or start user
services.

Or enable automatic loading once in this checkout:

```sh
direnv allow
```

Automatic loading requires `direnv` and `nix-direnv` to already be installed
and enabled for your shell; the dev shell supplies them for subsequent work.

`.envrc` delegates to nix-direnv's `use flake`. Direnv is convenience; the
declarative environment remains `devShells.default` in the flake. Navi is
available inside the shell and automatically searches this project's `cheats/`
first. `nix run .#help` provides the same project-local Navi entry point.

## Discovery and maintenance

```sh
nix flake show
nix flake metadata
nix flake check
nix fmt
navi
```

The Navi cheats are an annotated learning/reference system, not just aliases.
They cover Nix language and CLI fundamentals, flakes and locks, development
shells, store and profile operations, debugging, NixOS builds/VMs/tests/
containers, and local child-flake overrides. Use `navi --print` to review a
command before executing it.

For local component development with Git submodules and `--override-input`, see
[DEV.md](DEV.md).

## Layout

```text
flake.nix          small input and flake-parts composition entry point
modules/           root composition modules for shell, checks, and apps
cheats/            project-local Navi learning/reference cheats
docs/              architecture decisions and future composition workflow
packages/          reserved for future child-flake checkouts; none required yet
src/               reserved for source genuinely belonging to Nix Arbor
tests/             reserved for future focused tests; none required yet
.envrc             nix-direnv automatic shell activation
Justfile           thin discoverability recipes around native Nix commands
```

Only directories with current files are committed; `packages/`, `src/`, and
`tests/` are conventions, not empty placeholders.

## External component development

Nix Arbor declares real child flakes as remote inputs. AshZsh is the first
example:

```nix
inputs.ashzsh.url = "github:pbert5/AshZsh";
```

The remote input is the reproducible default. A local Git checkout is kept
under `packages/AshZsh` as a Git submodule for convenient joint development.
The submodule is not itself the flake input; it is the working tree used by a
temporary override:

```sh
nix flake check --override-input ashzsh path:./packages/AshZsh
nix develop --override-input ashzsh path:./packages/AshZsh
nix build .#some-output --override-input ashzsh path:./packages/AshZsh
```

Edit AshZsh in `packages/AshZsh`, check the child directly with `nix flake
check` from that directory, then check Nix Arbor against the local child with
the commands above. The override is temporary and does not change the
committed lock file.

There are three independently versioned records:

1. AshZsh's Git repository HEAD.
2. Nix Arbor's Git submodule pointer to a specific AshZsh commit.
3. Nix Arbor's `flake.lock` entry for the remote `ashzsh` input.

After validating a child change, update the submodule pointer from the Nix
Arbor root:

```sh
git -C packages/AshZsh fetch
git -C packages/AshZsh checkout <validated-ashzsh-commit>
git add packages/AshZsh
git commit -m "chore: update AshZsh submodule"
```

Separately update the reproducible remote input when desired:

```sh
nix flake lock --update-input ashzsh
git add flake.lock
git commit -m "chore: update AshZsh flake input"
```

Updating one does not automatically update the other. The local override is
what lets active AshZsh work proceed before either record is changed.

## Updating and learning

Update all inputs with `nix flake update`, or one input with
`nix flake lock --update-input nixpkgs`. Prefer the targeted form when a change
does not require refreshing the whole graph.

`just` offers thin aliases for discovery, checking, formatting, linting, shell,
REPL, metadata, and output inspection; the native Nix command remains visible.
The repository's formatter is `nixfmt` driven through `nixfmt-tree`, and
`nix flake check` runs formatting, statix, and deadnix checks immediately.

This phase deliberately excludes hosts, hardware, Home Manager, deployments,
secrets, cluster topology, applications, and child flakes.
