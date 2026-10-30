# =============================================================================
#  Desktop platform services: audio, bluetooth, printing, fonts, gaming, etc.
#  These replace the dozens of CachyOS service packages with declarative options.
# =============================================================================
{ config, pkgs, lib, ... }:
{
  ###########################################################################
  ## Audio — PipeWire (replaces pipewire-pulse/alsa/wireplumber package soup)
  ###########################################################################
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  ###########################################################################
  ## Bluetooth
  ###########################################################################
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  ###########################################################################
  ## Other hardware/services
  ###########################################################################
  services.printing.enable = true;          # CUPS
  services.avahi = { enable = true; nssmdns4 = true; };  # mDNS / printer discovery
  services.fstrim.enable = true;            # SSD trim
  services.fwupd.enable = true;             # firmware updates
  services.resolved.enable = true;          # systemd-resolved (enabled on CachyOS)
  services.gnome.gnome-keyring.enable = true;
  services.ananicy = {                      # CachyOS process priority daemon
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
  hardware.enableRedistributableFirmware = true;

  # Filesystem support (you had btrfs/ntfs/exfat tooling installed)
  boot.supportedFilesystems = [ "btrfs" "ntfs" "exfat" "vfat" ];

  ###########################################################################
  ## Fonts (matches your Noto + Nerd Fonts + CJK + emoji set)
  ###########################################################################
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    dejavu_fonts
    open-sans
    source-han-sans
    # Nerd Fonts — note the new namespaced attribute style on recent nixpkgs:
    nerd-fonts.caskaydia-cove   # Cascadia Code NF
    nerd-fonts.terminess-ttf    # Terminus
    nerd-fonts.meslo-lg         # Meslo NF
    nerd-fonts._0xproto         # 0xProto NF
    nerd-fonts.zed-mono         # ZedMono NF
    nerd-fonts._3270            # 3270 NF
    nerd-fonts.bigblue-terminal # BigBlueTerm NF
    nerd-fonts.hurmit           # Hurmit NF
  ];


  # Links nix packages to /bin/
  services.envfs.enable = true;
  # openssh server
  services.openssh = {
    enable = true;
	openFirewall = true;
  };

  ###########################################################################
  ## CachyOS-ish performance touches (optional, conservative)
  ###########################################################################
  # zram swap is a good default and roughly mirrors CachyOS responsiveness tuning.
  zramSwap.enable = true;

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # firewall on (you had ufw). Open ports as needed per service.
  networking.firewall.enable = true;
}
