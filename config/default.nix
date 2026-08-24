{ inputs, ... }:
let
  desktop = [
    inputs.home-manager.nixosModules.home-manager
    inputs.tilingDesktop.nixosModules.default
    inputs.ashes-desktop-apps.nixosModules.default
    {
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "26.05";
      users.users.ash = {
        isNormalUser = true;
        description = "Ash";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
      };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.ash = {
        imports = [
          inputs.ashzsh.homeModules.default
          inputs.tilingDesktop.homeModules.hyprland
          inputs.ashes-desktop-apps.homeModules.default
        ];
        home.stateVersion = "26.05";
        home.username = "ash";
        home.homeDirectory = "/home/ash";
        ashesDesktopApps = {
          enable = true;
          sets = [ "desktop.core" ];
        };
      };
    }
  ];
  server = [
    {
      system.stateVersion = "26.05";
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = [ ];
    }
  ];
  machines = inputs.arbor-manager.lib.mkMachines {
    inherit inputs;
    machinesPath = ./machines;
    profiles = { inherit desktop server; };
  };
in
{
  flake.nixosConfigurations = machines.configurations;
}
