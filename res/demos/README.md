# Recording the tab walkthroughs

From the repository root, use the locked Nix inputs to build the app, Python
with Pillow and pyte, and the DejaVu Sans Mono font.

```sh
app=$(nix build --no-link --print-out-paths .#arbor-manager)
python=$(nix build --no-link --print-out-paths --impure --expr \
  'with (builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.${builtins.currentSystem}; python3.withPackages (p: [ p.pillow p.pyte ])')
fonts=$(nix build --no-link --print-out-paths --impure --expr \
  '(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.${builtins.currentSystem}.dejavu_fonts')
"$python/bin/python" res/demos/record.py "$app/bin/arbor-manager" \
  "$fonts/share/fonts/truetype"
```

Use `--tab network` to record one tab or `--debug` to print each screen.
The recorder opens a 112 × 25 pseudo-terminal, sends the keys in `scenes.py`,
and checks the resulting screens before saving the GIF beside the script.
