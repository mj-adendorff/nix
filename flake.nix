{
  description = "mjadendorff's NixOS — Hyprland on desktop (NVIDIA RTX 5070 Ti / AMD 7800X3D) and laptop (ASUS Zenbook S14 UX5406SA)";

  inputs = {
    # Using unstable: needed for a recent-enough NVIDIA driver for Blackwell (RTX 50xx),
    # good Lunar Lake support on the laptop, and the freshest Hyprland.
    # Pin to nixos-25.11 later if you want more stability.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Official Hyprland flake — gives you upstream builds rather than the (sometimes
    # older) nixpkgs version. Optional but recommended for a Hyprland-first setup.
    hyprland.url = "github:hyprwm/Hyprland";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    # oh-my-pi (`omp`) coding agent. Keeps its own nixpkgs pin so the build matches upstream.
    oh-my-pi.url = "github:can1357/oh-my-pi";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";
    mkHost = name: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [ ./hosts/${name}/configuration.nix ];
    };
  in {
    nixosConfigurations = {
      desktop = mkHost "desktop";
      laptop = mkHost "laptop";
    };
  };
}
