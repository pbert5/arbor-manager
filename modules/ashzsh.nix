{ inputs, ... }:
{
  # Keep the child module available through the composition flake while
  # leaving Home Manager and host assembly to downstream consumers.
  config.flake.homeModules.ashzsh = inputs.ashzsh.homeModules.default;
}
