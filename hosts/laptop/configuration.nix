# =============================================================================
#  ASUS Zenbook S14 (UX5406SA) — Core Ultra 7 258V (Lunar Lake), Arc 140V,
#  3K OLED, Intel BE201 Wi-Fi 7, SoundWire audio (cs42l43 codec + cs35l56 amps).
# =============================================================================
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ../../modules/common.nix
    ../../modules/intel-arc.nix
    ../../modules/hyprland.nix
    ../../modules/desktop.nix
    ../../modules/dev.nix
    ../../modules/packages.nix
  ];

  ###########################################################################
  ## Networking
  ###########################################################################
  networking.hostName = "laptop";

  ###########################################################################
  ## Power / thermals
  ###########################################################################
  # power-profiles-daemon drives intel_pstate EPP on Lunar Lake and is what the
  # noctalia power-profile widget talks to. (With it enabled, nixos-hardware's
  # laptop profile leaves TLP off — the two conflict.)
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  services.upower.enable = true;   # battery info for the bar / hypridle

  # Lid close -> suspend (s2idle on Lunar Lake). logind default, made explicit;
  # ignore the lid when docked to an external display.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  ###########################################################################
  ## Audio
  ###########################################################################
  # Speakers/mics are SoundWire (sof-soundwire: cs42l43 + cs35l56). They need
  # sof-firmware + the cs35l56 tuning in linux-firmware (both pulled in by
  # hardware.enableRedistributableFirmware in modules/desktop.nix), a recent
  # kernel, and a recent alsa-ucm-conf — all satisfied on nixos-unstable.

  # The release you initially installed against. DO NOT bump casually — read the
  # release notes first. It is NOT the same as your nixpkgs version.
  system.stateVersion = "26.05";
}
