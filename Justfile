set shell := ["bash", "-euo", "pipefail", "-c"]

help:
    @printf '%s\n' 'Use native Nix commands: nix develop, nix flake check, nix fmt, navi'

check:
    nix flake check

fmt:
    nix fmt

lint:
    statix check modules
    deadnix --fail flake.nix modules

show:
    nix flake show

metadata:
    nix flake metadata

shell:
    nix develop

repl:
    nix repl
