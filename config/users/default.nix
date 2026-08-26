{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  assertions = [
    {
      assertion = config.users.users.ash.uid == 1000;
      message = "The ash identity must use UID 1000.";
    }
    {
      assertion = config.users.users.madeline.uid == 1001;
      message = "The madeline identity must use UID 1001.";
    }
    {
      assertion = config.users.groups.home-share.gid == 993;
      message = "The home-share group must use GID 993.";
    }
  ];
  programs.zsh.enable = true;
  users.groups.home-share.gid = 993;
  users.users.ash = {
    uid = 1000;
    isNormalUser = true;
    description = "Ash";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "dialout"
      "home-share"
    ];
    linger = true;
    # Public fallback keys only; private keys remain on operator devices.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK37SqGag+fd939XSZT+ytV3/KOzI6K9N/sDq3nye27O ash@windows-machine"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKKJ8mhwR1PeloNNp5vzroZaQ4ga0x1TLi2f/2DX1lPs admin@toptoodle"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKRnn0GgKyiHU+v4oBbOp40e3hpEZOZ/iKW9Jhtpaker bertinert"
    ];
    hashedPasswordFile = lib.mkIf config.arbor.environment.secrets.enable config.sops.secrets.ash-password.path;
  };
  users.users.madeline = {
    uid = 1001;
    isNormalUser = true;
    description = "Madeline";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "dialout"
      "home-share"
    ];
    openssh.authorizedKeys.keys = [ ];
    hashedPasswordFile = lib.mkIf config.arbor.environment.secrets.enable config.sops.secrets.madeline-password.path;
  };
  home-manager.users.ash = {
    imports = [ inputs.ashzsh.homeModules.default ];
    home.username = "ash";
    home.homeDirectory = "/home/ash";
    home.stateVersion = "26.05";
    programs.git.enable = true;
    programs.git.settings.user = {
      name = "ash-r640-0";
      email = "phsilbert@gmail.com";
    };
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = config.arbor.environment.public.sshHosts;
    };
  };
  home-manager.users.madeline = {
    home.username = "madeline";
    home.homeDirectory = "/home/madeline";
    home.stateVersion = "26.05";
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = config.arbor.environment.public.sshHosts;
    };
  };
}
