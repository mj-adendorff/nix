# =============================================================================
#  System packages — translated from your CachyOS `pacman -Qqe` list.
#
#  EXCLUDED on purpose (NixOS handles these declaratively or they're Arch-only):
#    base, base-devel, mkinitcpio, linux-cachyos*/lts/rt kernels, plymouth,
#    paru, yay-bin, octopi, chwd, hwdetect, reflector, pacman-contrib, pkgfile,
#    cachyos-* (settings/hooks/mirrorlists/zsh/fish configs), rebuild-detector,
#    intel-ucode / intel-media-driver / vulkan-intel (handled per-GPU in
#    modules/nvidia.nix and modules/intel-arc.nix + nixos-hardware),
#    tlp/auto-cpufreq/cpupower (laptop uses power-profiles-daemon instead),
#    netctl/iwd/wpa_supplicant
#    (NetworkManager handles wifi), howdy (face unlock — complex, set up later),
#    xorg-* server bits (Wayland-only here; XWayland comes via programs.hyprland).
#
#  Things that are enabled elsewhere as proper modules, not packages:
#    steam, docker, libvirt/virt-manager, pipewire, bluetooth, fonts, hyprland.
#    llama-cpp: GPU-specific build (CUDA in nvidia.nix, Vulkan in intel-arc.nix).
# =============================================================================
{ config, pkgs, lib, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    ##### AI coding agent (flake input, see flake.nix) #####
    inputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.default  # omp
    inputs.dnsglobe.packages.${pkgs.stdenv.hostPlatform.system}.default  # dnsglobe

    ##### Browsers #####
    brave
    chromium
	firefox

    ##### Comms / media #####
    discord
    spotify
    spotify-player
    vlc
    evince          # PDF (GNOME)
    papers          # PDF (GNOME, evince successor)
    sioyek          # PDF (alias `pdf` in .zshrc)
    tdf             # terminal PDF viewer
    ffmpegthumbnailer

    ##### Editors / IDEs #####
    zed-editor      # zed
    neovim
    neovide
    helix
    vim

    ##### Terminals & multiplexers #####
    alacritty
    ghostty
    tmux
    screen

    ##### Hyprland userland (compositor enabled in hyprland.nix) #####
    hypridle
    noctalia        # noctalia
    rofi
    wl-clipboard          # provides wl-paste / wl-copy
    slurp
    networkmanagerapplet  # nm-applet
    brightnessctl
    playerctl
    pavucontrol
    pulsemixer
    nwg-look              # GTK theming under Wayland
    lxappearance
    libnotify

    ##### File manager & desktop apps #####
    nautilus
    gnome-calendar
    gnome-weather
    font-manager
    feh

    ##### CLI / system utilities #####
    wget
    curl
    git
    ripgrep
    fd
    fzf
    plocate
    tree
    duf
    htop
    btop
    glances
    s-tui
    fastfetch
    bluetui
    ranger
    newsboat
    miller
    jq
    chafa
    ddgr
    flawz
    tuicr
    socat
    pandoc
    pdftk
    mupdf               # mupdf-tools (mutool)
    exiftool            # perl-image-exiftool
    unzip
    unrar
    p7zip               # 7zip
    rsync
    pv
    dmidecode
    usbutils
    pciutils
    smartmontools
    parted
    gparted
    ntfs3g
    cifs-utils
    samba               # smbclient
    fuse                # fuse2 (AppImages)
    exfatprogs
    dosfstools
    btrfs-progs
    snapper
    btrfs-assistant
    macchanger

	##### TUI tools
	netwatch
	mcat
	posting         # TUI HTTP client (v2 from nixpkgs; v3 has no release yet)
	(callPackage ../pkgs/lazyjira.nix { })  # prebuilt release binary

    ##### Security / pentest toolkit (you had a full set) #####
	angryoxide
    aircrack-ng
    hashcat
    metasploit
    radare2
    rizin
    wireshark-cli       # tshark; full GUI: use `wireshark`
    netscanner
    nmap

  ];

  # Wireshark with proper capture group/setcap (matches your wireshark usage)
  programs.wireshark.enable = true;

  # ---------------------------------------------------------------------------
  # NOT in nixpkgs (were AUR/-bin packages). Handle separately if you want them:
  #   snappy-switcher, hyprpwcenter, havn                 -> build manually / find flake
  #   (lazyjira-bin: packaged locally in pkgs/lazyjira.nix)
#   bookokrat-bin, pdf-tui-bin, pwndbg                  -> not packaged (pwndbg: use its flake)
#   networkmanager-pptp                                 -> not packaged (l2tp is, see configuration.nix)
  #   etcher-bin                                          -> removed from nixpkgs (Electron EOL); use `dd`/ventoy/gnome-disks
  #   spotify-electron-bin, spotify-launcher              -> replaced above by official `spotify`
  #   howdy                                               -> face unlock; involved on NixOS, set up later
  # ---------------------------------------------------------------------------
}
