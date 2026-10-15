# =============================================================================
#  Development platform: containers, virtualization, and the "global" toolchain.
#
#  PHILOSOPHY (read this): on NixOS you should NOT install per-language toolchains
#  globally. Use a per-project `flake.nix` + `direnv` dev shell instead — see
#  README "Dev environments". The compilers below are the few you genuinely want
#  available everywhere; project versions come from project shells.
# =============================================================================
{ config, pkgs, lib, ... }:
{
  ###########################################################################
  ## Containers
  ###########################################################################
  virtualisation.docker.enable = true;
  # docker-desktop was removed on CachyOS; plain engine + buildx/compose instead.

  ###########################################################################
  ## Virtualization (you had gnome-boxes + libvirt-style usage)
  ###########################################################################
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  ###########################################################################
  ## Global dev tools — editors, VCS, build basics, language runtimes.
  ###########################################################################
  environment.systemPackages = with pkgs; [
    # Gcloud
	google-cloud-sdk

    # Version control & helpers
    git
    git-lfs
    delta            # git-delta
    gh               # github-cli
    lazygit
	poetry

    # Build essentials
    gcc
    gnumake
    cmake
    meson
    ninja
    pkg-config
    gdb
    valgrind

    # Language runtimes you keep globally (project-specific versions via dev shells)
    go
    rustup           # manages rust toolchains; replaces the `rust` package
    nodejs_22
    python313
    jdk21
    tree-sitter

    # Infra
    terraform
    docker-compose
    docker-buildx
    lazydocker
    bun

    # Database CLIs (servers are declared as services below, commented out)
    postgresql       # provides psql client
    mariadb          # provides mysql/mariadb client
    valkey           # redis-compatible CLI
  ];

  ###########################################################################
  ## Database SERVERS — postgres + mariadb run as services on the laptop.
  ###########################################################################
  services.postgresql.enable = false;
  services.mysql = { enable = false; package = pkgs.mariadb; };
  # services.redis.servers."".enable = true;  # valkey/redis (CLI only on CachyOS)

  # direnv for automatic per-project dev shells (the NixOS-native dev workflow)
  programs.direnv.enable = true;
}
