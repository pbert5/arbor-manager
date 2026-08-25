{ inputs, ... }:
{
  # Export child component modules from one neutral composition boundary.
  config.flake.homeModules = {
    ashzsh = inputs.ashzsh.homeModules.default;
    tilingDesktop = inputs.tilingDesktop.homeModules.default;
  };
  config.flake.nixosModules.tilingDesktop = inputs.tilingDesktop.nixosModules.default;
  config.flake.arborRegistry = inputs.arbor-registry.lib;
}
