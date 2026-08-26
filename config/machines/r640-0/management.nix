{ ... }:
{
  networking.hostName = "r640-0";
  networking.useDHCP = true;
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraSetFlags = [ "--accept-dns=false" ];
  };
  # Yggdrasil/Registry are intentionally not imported into this physical
  # profile. Their future overlay must remain optional to these paths.
  systemd.tmpfiles.rules = [
    "z /home/ash 2750 ash home-share - -"
    "z /home/madeline 2750 madeline home-share - -"
  ];
  systemd.services.home-share-flake-link = {
    description = "Create the safe r640 shared flake link";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu
      destination=/home/madeline/flake
      target=/home/ash/flake
      if [ -L "$destination" ]; then
        [ "$(readlink "$destination")" = "$target" ] || echo "leaving conflicting symlink $destination"
      elif [ -e "$destination" ]; then
        echo "leaving existing path $destination"
      elif [ -d "$target" ]; then
        ln -s "$target" "$destination"
      else
        echo "target $target is not present; leaving homes untouched"
      fi
    '';
  };
}
