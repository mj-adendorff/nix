{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/nvidia.nix
    ../../modules/hyprland.nix
    ../../modules/desktop.nix
    ../../modules/dev.nix
    ../../modules/packages.nix
  ];

  ###########################################################################
  ## Boot — remote LUKS unlock over SSH (from the Pi) in the initrd
  ###########################################################################
  boot.initrd = {
    # Replace with your Ethernet driver
    availableKernelModules = [ "r8169" ];

    systemd.network = {
      enable = true;

      networks."10-ethernet" = {
        matchConfig.Name = "enp6s0";
        networkConfig.DHCP = "ipv4";
        linkConfig.RequiredForOnline = "routable";
      };
    };

    network.ssh = {
      enable = true;
      port = 2222;

      hostKeys = [
        "/etc/secrets/initrd/ssh_host_ed25519_key"
      ];

      authorizedKeys = [
        ''command="systemctl default" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICDKnkeBcSMraE6hdPhGnfkg8g13lEsXiLsfOkNQCZIC server@pi''
      ];
    };
  };

  ###########################################################################
  ## Networking
  ###########################################################################
  networking.hostName = "desktop";
  networking.interfaces.enp6s0.wakeOnLan.enable = true;
  networking.firewall.allowedTCPPorts = [8000];
  networking.firewall.allowedUDPPorts = [8000];

  # The release you initially installed against. DO NOT bump casually — read the
  # release notes first. It is NOT the same as your nixpkgs version.
  system.stateVersion = "26.05";
}
