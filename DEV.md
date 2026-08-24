# Nix Arbor Development

This runbook covers developing Nix Arbor together with checked-out component
flakes. The normal flake remains remote and locked; local component checkouts
are temporary development substitutions.

The checked-out components are `packages/AshZsh`, `packages/AshesTools`, and
`packages/AshDesktopApps`.
Each is both a Git submodule (editable checkout plus parent commit pointer) and
a remote flake input (the normal reproducible dependency). `--override-input`
temporarily splices a local checkout into that graph.

## Normal versus local mode

Nix Arbor normally consumes AshZsh through the remote input:

```nix
inputs.ashzsh.url = "github:pbert5/AshZsh";
```

The checkout at `packages/AshZsh` is a Git submodule for editing and testing.
It does not replace the flake input by itself. `--override-input` connects the
local checkout to one command without modifying `flake.nix` or `flake.lock`.

There are three separate version records:

1. The AshZsh repository commit.
2. Nix Arbor's submodule pointer.
3. Nix Arbor's locked remote `ashzsh` input.

## Initialize development checkouts

Submodules are never initialized or updated automatically by the development
helper. Initialize them explicitly when needed:

```bash
git submodule update --init --recursive
```

Inspect which local overrides are available without running Nix:

```bash
nix run .#local -- overrides
```

## Enter development shells

Normal, reproducible development uses the locked remote input:

```bash
nix develop
```

The native local equivalent is:

```bash
nix develop \
  --override-input ashzsh path:./packages/AshZsh
```

The helper applies that override automatically for every initialized component
checkout it knows about:

```bash
nix run .#local -- develop
```

Additional arguments pass through to `nix develop`, for example:

```bash
nix run .#local -- develop --command bash -c 'command -v navi'
```

## Check and inspect

Always check the normal remote-input state before merging or releasing:

```bash
nix flake check
nix flake show
nix flake metadata
```

Check the current local component state with the native form:

```bash
nix flake check --override-input ashzsh path:./packages/AshZsh
nix flake show --override-input ashzsh path:./packages/AshZsh
nix flake metadata --override-input ashzsh path:./packages/AshZsh
```

Or use the helper:

```bash
nix run .#local -- check
nix run .#local -- show
nix run .#local -- metadata
```

The helper only adds an override when `packages/AshZsh/flake.nix` exists. If
the checkout is absent, it runs the native command without an override.

The helper now applies available overrides for `ashzsh`, `ashes-tools`, and
`ashes-desktop-apps`.
The direct two-level workflow is:

```bash
cd packages/AshesTools
nix flake check --override-input awesome-nix-sets path:./packages/AwesomeNixSets
cd ../..
nix flake check --override-input ashes-tools path:./packages/AshesTools
```

For Ash Desktop Apps, the native local form is:

```bash
nix flake check --override-input ashes-desktop-apps path:./packages/AshDesktopApps
nix develop --override-input ashes-desktop-apps path:./packages/AshDesktopApps
```

Check AwesomeNixSets at its own boundary first when changing the nested
catalog. Multiple parent overrides are supported by Nix, but nested submodules
remain explicit repository checkouts rather than implicit dependency resolution.

## Evaluate and build

Pass the same installable and arguments you would pass to native Nix:

```bash
nix eval .#homeModules.ashzsh \
  --override-input ashzsh path:./packages/AshZsh
nix build .#packages.x86_64-linux.navi-help \
  --override-input ashzsh path:./packages/AshZsh
```

The helper equivalents are:

```bash
nix run .#local -- eval .#homeModules.ashzsh
nix run .#local -- build .#packages.x86_64-linux.navi-help
```

The helper's `eval` and `build` operations append any extra arguments to the
native command and apply available local overrides first.

## Work directly inside a component

AshZsh's own flake and Nix Arbor's composition check different boundaries:

```bash
cd packages/AshZsh
nix flake check
nix flake show

cd ../..
nix run .#local -- check
```

The first commands validate AshZsh independently. The final command validates
Nix Arbor consuming the current local AshZsh checkout.

## Updating a component

Commit changes inside AshZsh first:

```bash
cd packages/AshZsh
git status
git add .
git commit -m "..."
git push
cd ../..
```

Then update Nix Arbor's submodule pointer when the parent should reference that
commit:

```bash
git add packages/AshZsh
git commit -m "chore: update AshZsh submodule"
```

Separately update the reproducible remote input when ready:

```bash
nix flake lock --update-input ashzsh
git add flake.lock
git commit -m "chore: update AshZsh flake input"
```

Updating the child commit, submodule pointer, and remote lock entry are
independent operations. Local overrides allow development before any of those
records are changed.

## Typical development loop

1. Edit `packages/AshZsh`.
2. Run `nix flake check` inside AshZsh.
3. Run `nix run .#local -- check` from Nix Arbor.
4. Commit and push AshZsh when appropriate.
5. Update the Nix Arbor submodule pointer if desired.
6. Update Nix Arbor's remote `flake.lock` entry when ready.
7. Confirm plain `nix flake check` succeeds without overrides.

Local override success alone is not sufficient for release; the normal remote
input must also work.

## Helper limitations

The helper maintains the component mapping in `modules/apps.nix`:

```text
ashzsh             -> packages/AshZsh
ashes-tools        -> packages/AshesTools
ashes-desktop-apps -> packages/AshDesktopApps
```

It is intentionally a thin wrapper around native Nix. It does not initialize,
update, commit, push, or otherwise mutate submodules or flake locks. Invoke it
from the Nix Arbor checkout root. When running it through an absolute flake
reference from another directory, set `NIX_ARBOR_ROOT` to the checkout path.
