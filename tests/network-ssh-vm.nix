{ pkgs, networkManagerPackage, networkManagerModule, managerPackage, ... }:
pkgs.testers.runNixOSTest {
  name = "arbor-network-one-hop-ssh";
  nodes = {
    target = { ... }: {
      virtualisation.vlans = [ 100 ];
      networking.hostName = "target";
      networking.interfaces.eth1.ipv4.addresses = [{ address = "192.168.100.3"; prefixLength = 24; }];
      services.openssh.enable = true;
      networking.firewall.enable = true;
      networking.firewall.extraCommands = ''
        iptables -I nixos-fw 1 -p tcp --dport 22 -s 192.168.100.2 -j nixos-fw-accept
        iptables -I nixos-fw 2 -p tcp --dport 22 -j DROP
      '';
      users.users.root.openssh.authorizedKeys.keys = [ ];
    };
    jump = { ... }: {
      virtualisation.vlans = [ 100 ];
      networking.hostName = "jump";
      networking.interfaces.eth1.ipv4.addresses = [{ address = "192.168.100.2"; prefixLength = 24; }];
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = [ ];
    };
    source = { ... }: {
      imports = [ networkManagerModule ];
      virtualisation.vlans = [ 100 ];
      networking.hostName = "source";
      networking.interfaces.eth1.ipv4.addresses = [{ address = "192.168.100.1"; prefixLength = 24; }];
      environment.systemPackages = [ managerPackage networkManagerPackage pkgs.jq pkgs.socat pkgs.iputils pkgs.openssh ];
      systemd.services.lan-provider = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${networkManagerPackage}/bin/arbor-network-provider-lan --node source --interface eth1 --socket /run/arbor-lan/lan.sock";
          RuntimeDirectory = "arbor-lan";
          Restart = "on-failure";
        };
      };
      services.arbor-networkd = {
        enable = true;
        package = networkManagerPackage;
        registrySnapshot = "/run/arbor/accepted.json";
        providerSockets.lan = "/run/arbor-lan/lan.sock";
      };
    };
  };
  testScript = ''
    start_all()
    target.wait_for_unit("sshd.service")
    jump.wait_for_unit("sshd.service")
    source.wait_for_unit("lan-provider.service")
    target_key = target.succeed("cat /etc/ssh/ssh_host_ed25519_key.pub").strip()
    jump_key = jump.succeed("cat /etc/ssh/ssh_host_ed25519_key.pub").strip()
    source.succeed("mkdir -p /root/.ssh && ssh-keygen -q -t ed25519 -N \"\" -f /root/.ssh/id_ed25519")
    client_key = source.succeed("cat /root/.ssh/id_ed25519.pub").strip()
    target.succeed("mkdir -p /root/.ssh && chmod 700 /root/.ssh")
    jump.succeed("mkdir -p /root/.ssh && chmod 700 /root/.ssh")
    target.succeed("echo " + repr(client_key) + " >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys")
    jump.succeed("echo " + repr(client_key) + " >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys")
    source.succeed("mkdir -p /run/arbor && " +
      "jq -n --arg targetKey " + repr(target_key) + " --arg jumpKey " + repr(jump_key) + " '" +
      "{format:\"arbor-registry/accepted-state\",version:1,digest:\"vm-ssh\",edges:[" +
      "{source:\"source\",target:\"jump\",network:\"lan\",provider:\"lan\",cost:1,endpointGeneration:1,capabilities:[\"ssh\"],transit:{ssh:true}}," +
      "{source:\"jump\",target:\"target\",network:\"lan\",provider:\"lan\",cost:1,endpointGeneration:1,capabilities:[\"ssh\"],transit:{ssh:true}}]," +
      "accepted:[" +
      "{schema:\"endpoint\",recordId:\"jump\",generation:1,payload:{node:\"jump\",network:\"lan\",provider:\"lan\",address:\"192.168.100.2\",generation:1,capabilities:[\"ssh\"],sshHostKey:$jumpKey}}," +
      "{schema:\"endpoint\",recordId:\"target\",generation:1,payload:{node:\"target\",network:\"lan\",provider:\"lan\",address:\"192.168.100.3\",generation:1,capabilities:[\"ssh\"],sshHostKey:$targetKey}}]}' > /run/arbor/accepted.json")
    source.succeed("systemctl restart arbor-networkd.service")
    source.wait_for_unit("arbor-networkd.service")
    source.sleep(3)
    print(source.execute("systemctl status arbor-networkd.service --no-pager"))
    print(source.execute("journalctl -u arbor-networkd.service --no-pager"))
    print(source.execute("ls -la /run /run/arbor /run/arbor-lan"))
    print(source.execute("arbor-manager network endpoints --socket /run/arbor/networkd.sock"))
    print(source.execute("arbor-manager network providers --socket /run/arbor/networkd.sock"))
    print(source.execute("journalctl -u lan-provider.service --no-pager"))
    print(source.execute("arbor-manager route --socket /run/arbor/networkd.sock --source source --target target"))
    source.succeed("arbor-manager ssh --socket /run/arbor/networkd.sock --source source --target target --user root")
  '';
}
