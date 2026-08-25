{ inputs, ... }:
{
  # Export child component modules from one neutral composition boundary.
  config.flake.homeModules = {
    ashzsh = inputs.ashzsh.homeModules.default;
    tilingDesktop = inputs.tilingDesktop.homeModules.default;
  };
  config.flake.nixosModules.tilingDesktop = inputs.tilingDesktop.nixosModules.default;
  config.flake.nixosModules.arborRegistry = inputs.arbor-registry.nixosModules.default;
  config.flake.nixosModules.arborVaultRuntime = inputs.arbor-registry.nixosModules.vault-runtime;
  config.flake.nixosModules.arborVaultRuntimeUpstream = inputs.arbor-registry.nixosModules.vault-runtime-upstream;
}
