# =============================================================================
#  Settings shared by every host (desktop + laptop): boot loader, locale, user,
#  dotfiles bootstrap, shell, nix settings, network share.
#  Host-specific bits (hostname, GPU, initrd networking…) live in hosts/<name>/.
# =============================================================================
{ config, pkgs, lib, ... }:
{
  ###########################################################################
  ## Boot
  ###########################################################################
  # GRUB (EFI) — chosen for the Windows dual-boot; os-prober auto-adds Windows
  # to the menu. Because root is LUKS-encrypted, every kernel + initrd lives on
  # the ESP at /boot (see copyKernels), so the ESP must be large: >= 1 GiB.
  # The desktop's ESP is ~5 GB. A stock Windows ESP (100–260 MB) is too small —
  # give NixOS its own ESP instead (see README).
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot"; # the (>= 1 GiB) ESP
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";          # EFI install, not a disk MBR
    useOSProber = true;        # detect Windows 11 and add a boot entry
    configurationLimit = 10;   # keep 10 NixOS rollback generations in the menu
    copyKernels = true;        # REQUIRED: /boot is FAT32 and root is LUKS-encrypted,
                               # so kernels must be copied onto /boot (GRUB can't read
                               # them from the encrypted root).
  };
  # os-prober needs to read the Windows NTFS partition at install time:
  boot.supportedFilesystems = [ "ntfs" ];

  # CachyOS shipped a tuned kernel. NixOS default is the mainline `linux` kernel.
  # For a similar "latest performance" feel, use the latest mainline kernel
  # (also required for good Lunar Lake support on the laptop):
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # (Optional CachyOS-like tuning lives in modules/desktop.nix via kernel.sysctl.)
  boot.initrd.systemd.enable = true;

  ###########################################################################
  ## Networking
  ###########################################################################
  networking.networkmanager = {
    enable = true; # replaces NetworkManager + nm-applet stack
    plugins = [ pkgs.networkmanager-l2tp ];
  };

  # Pi SMB share. Automounted on first access; the timeouts keep it from
  # hanging when the machine (i.e. the laptop) is away from the home network.
  fileSystems."/mnt/drive" = {
    device = "//192.168.0.38/PiShare/";
    fsType = "cifs";
    options = [
      "rw"
      "credentials=/etc/nixos/smb-secrets"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=10"
      "uid=1000"
      "gid=100"
      "file_mode=0755"
    ];
  };

  ###########################################################################
  ## Locale / time
  ###########################################################################
  time.timeZone = "Africa/Johannesburg"; # adjust if needed
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  ###########################################################################
  ## User
  ###########################################################################
  users.users.mjadendorff = {
    isNormalUser = true;
    description = "MJ Adendorff";
    extraGroups = [
      "wheel"           # sudo
      "networkmanager"
      "video"
      "audio"
      "docker"
      "wireshark"
    ];
    shell = pkgs.zsh;
  };

  # Dotfiles: on first boot, bare-clone the git repo into ~/.dotfiles and check it
  # out into $HOME (the `config` alias workflow). Runs once — never touches the files
  # again, so they stay git-managed. Checkout refuses to overwrite existing files.
  systemd.services.dotfiles-bootstrap = {
    description = "Clone mjadendorff's dotfiles";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!/home/mjadendorff/.dotfiles";
    path = [ pkgs.git pkgs.openssh ];
    serviceConfig = {
      Type = "oneshot";
      User = "mjadendorff";
      WorkingDirectory = "/home/mjadendorff";
    };
    script = ''
      git clone --bare https://github.com/mj-adendorff/.dotfiles.git .dotfiles
      config() { git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" "$@"; }
      config config status.showUntrackedFiles no
      config remote set-url --push origin git@github.com:mj-adendorff/.dotfiles.git
      # Remove the clone on failure so the next boot retries.
      config checkout || { rm -rf .dotfiles; exit 1; }
      config submodule update --init --recursive
    '';
  };

  # zsh must be enabled at system level to be a valid login shell.
  # ~/.zshrc itself comes from the ~/.dotfiles git repo; these load from /etc/zshrc
  # (replacing the /usr/share/zsh/plugins/... sources used on CachyOS).
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
	ohMyZsh = {
		enable = true;
		plugins = ["git" "z" "sudo"];
		theme = "robbyrussell";
	};
  };

  ###########################################################################
  ## Nix settings
  ###########################################################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  # Prebuilt binaries for the Hyprland flake input (otherwise it compiles from source)
  nix.settings.extra-substituters = [ "https://hyprland.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Allow proprietary packages (NVIDIA driver, Brave, Discord, Spotify, Steam, etc.)
  nixpkgs.config.allowUnfree = true;
}
