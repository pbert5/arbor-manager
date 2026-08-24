# Nix Arbor architecture

Nix Arbor is intentionally an integration flake. It composes independently
versioned flakes; it is not a future home for every package, host, service, or
secret.

## Composition

The root flake uses [flake-parts](https://flake.parts/) as its one composition
framework. `perSystem` keeps system-dependent packages, shells, apps, checks,
and formatters together while the root file remains an input declaration and
module import list. The supported systems are explicit rather than inherited
from every system nixpkgs happens to expose.

`flake-utils`, `flake-utils-plus`, and similar frameworks are intentionally not
also used. Combining composition frameworks would add conventions without
adding a current capability this small integration layer needs.

## External flakes and local development

An eventual child repository is declared as a normal remote input, for example:

```nix
inputs.foo.url = "github:pbert5/foo";
```

Normal operation stays remote and locked. During development, a checkout can be
substituted without editing the committed flake or lock file:

```sh
git submodule update --init packages/foo
nix develop --override-input foo path:./packages/foo
nix build .#some-output --override-input foo path:./packages/foo
nix flake check --override-input foo path:./packages/foo
nix eval .#some-output --override-input foo path:./packages/foo
```

`packages/foo` is a development checkout, not a default flake input. A Git
submodule records which child commit the parent workspace expects; a Nix input
records the dependency graph and its lock state; `--override-input` connects a
local checkout to that graph for one command. These mechanisms are related but
not interchangeable.

When a child becomes real, its own flake should expose its own packages,
modules, checks, and shells. The root should import or compose only the outputs
it needs.

## Checks and tooling

The default shell contains the tools used for everyday Nix Arbor work. The
formatter is `nixfmt`, exposed through the standard `formatter` output so
`nix fmt` is the source of truth. Checks run `nixfmt`, `statix`, and `deadnix`
over the small root composition layer. Heavy build orchestration and packaging
helpers remain documented options rather than mandatory shell dependencies.
## External component development

AshZsh is the real child-flake example for Nix Arbor. The committed root
`flake.nix` points at `github:pbert5/AshZsh`, so ordinary checks use the remote
reproducible input. A local checkout is available as the Git submodule
`packages/AshZsh`.

During active development:

```sh
cd packages/AshZsh
nix flake check
cd ../..
nix flake check --override-input ashzsh path:./packages/AshZsh
nix develop --override-input ashzsh path:./packages/AshZsh
```

Edit the child in place, validate it directly, and then validate the parent
with `--override-input`. Once a child commit is ready, commit that commit in
AshZsh and update Nix Arbor's submodule pointer:

```sh
git -C packages/AshZsh log -1
git -C packages/AshZsh status
git add packages/AshZsh
git commit -m "chore: update AshZsh submodule"
```

The remote lock input is updated independently:

```sh
nix flake lock --update-input ashzsh
git add flake.lock
git commit -m "chore: update AshZsh flake input"
```

These are three separate version records: AshZsh's repository HEAD, the
submodule pointer committed by Nix Arbor, and Nix Arbor's `flake.lock` entry
for the remote input. `--override-input ashzsh path:./packages/AshZsh` makes
the local checkout win for one command only; it does not rewrite the lock
file, move the submodule pointer, or publish the child repository.
