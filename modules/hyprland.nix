# =============================================================================
#  Hyprland session + login manager + portals
#
#  System-level enablement only. Your actual hyprland.conf and the rest of the
#  Wayland userland config live in the ~/.dotfiles git repo.
# =============================================================================
{ config, pkgs, lib, inputs, ... }:
{
  programs.hyprland = {
    enable = true;
    # Use the build from the official Hyprland flake (matches xdg portal version).
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

  # Make Electron/Chromium apps (Brave, Discord, Spotify, Cursor, Zed, VSCode) run native Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.EDITOR = "nvim";
  environment.sessionVariables.VISUAL = "nvim";

  # ---------------------------------------------------------------------------
  # Login manager: greetd + tuigreet (matches your CachyOS greetd-tuigreet setup).
  # Logs into Hyprland on a Wayland session.
  # ---------------------------------------------------------------------------
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
      user = "greeter";
    };
  };

  # XDG portals (screen sharing, file pickers). hyprland portal is provided above;
  # add gtk portal as a fallback for GTK apps.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # GTK theming support tools you used (nwg-look / lxappearance) need this.
  programs.dconf.enable = true;

  # GTK themes and icon themes from ./assets, copied (not symlinked, so they
  # stay writable) into ~/.themes and ~/.icons on every rebuild. Selection is
  # done by nwg-look / hyprland.conf; ~/.icons/default (nwg-look's cursor
  # file) is left untouched.
  # Runs after "users" so the account exists for install/chown on fresh machines.
  system.activationScripts.userThemes.deps = [ "users" ];
  system.activationScripts.userThemes.text = ''
    for kind in themes icons; do
      src=${../assets}/$kind
      dst=/home/mjadendorff/.$kind
      ${pkgs.coreutils}/bin/install -d -o mjadendorff -g users "$dst"
      for d in "$src"/*; do
        name=$(${pkgs.coreutils}/bin/basename "$d")
        ${pkgs.coreutils}/bin/rm -rf "$dst/$name"
        ${pkgs.coreutils}/bin/cp -a --no-preserve=mode,ownership "$d" "$dst/$name"
        ${pkgs.coreutils}/bin/chmod -R u+rwX,go+rX "$dst/$name"
        ${pkgs.coreutils}/bin/chown -hR mjadendorff:users "$dst/$name"
      done
    done
  '';

  # Polkit agent so GUI privilege prompts work under Hyprland.
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
  };
}
