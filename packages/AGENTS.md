# Packages

`packages/` is for independently versioned child flakes checked out for active
development. Keep child changes in that repository's own branch/worktree;
update Nix Arbor only for an intentional submodule pointer or input change.
Initialize nested submodules with `git submodule update --init --recursive`.
