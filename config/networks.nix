{ lib, ... }:
let
  providerType = lib.types.enum [
    "lan"
    "tailscale"
    "yggdrasil"
  ];
  visibilityType = lib.types.enum [
    "private"
    "public"
  ];
  spanType = lib.types.enum [
    "intra-lan"
    "inter-lan"
  ];
  exposureType = lib.types.enum [
    "none"
    "explicit-allowlist"
    "ssh-only"
  ];
  networkModule =
    { ... }:
    {
      options = {
        provider = lib.mkOption {
          type = providerType;
          description = "Provider implementation name.";
        };
        mode = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "dhcp"
              "static"
              "public-peering"
              "private-overlay"
            ]
          );
          default = null;
        };
        visibility = lib.mkOption {
          type = visibilityType;
          default = "private";
        };
        span = lib.mkOption {
          type = spanType;
          default = "inter-lan";
        };
        priority = lib.mkOption {
          type = lib.types.ints.positive;
          default = 100;
          description = "Lower values are preferred.";
        };
        enabled = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        bootstrap = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        fallback = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
        };
        serviceExposure = lib.mkOption {
          type = exposureType;
          default = "none";
        };
        transit = {
          ssh = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          deploy = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          network = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
        underlays = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Provider-owned scalar settings; secrets are forbidden.";
        };
      };
    };
in
{
  options.cluster.networking.networks = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule networkModule);
    default = { };
    description = "Static network eligibility and policy. Live membership, identities, endpoints, and health come from Arbor Registry/runtime.";
  };

  config.cluster.networking.networks = {
    lan = {
      provider = "lan";
      mode = "dhcp";
      span = "intra-lan";
      priority = 10;
      bootstrap = true;
      serviceExposure = "explicit-allowlist";
      transit.ssh = true;
    };
    tailscale = {
      provider = "tailscale";
      span = "inter-lan";
      priority = 30;
      bootstrap = true;
      serviceExposure = "ssh-only";
      transit.ssh = true;
      settings.acceptDns = "false";
    };
    publicYggPeering = {
      provider = "yggdrasil";
      mode = "public-peering";
      visibility = "public";
      priority = 200;
      bootstrap = true;
      serviceExposure = "none";
      transit.network = false;
    };
    privateYgg = {
      provider = "yggdrasil";
      mode = "private-overlay";
      span = "inter-lan";
      priority = 25;
      serviceExposure = "explicit-allowlist";
      transit.ssh = true;
      underlays = [
        "lan"
        "publicYggPeering"
        "tailscale"
      ];
    };
  };
}
