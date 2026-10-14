# =============================================================================
#  NVIDIA — RTX 5070 Ti (Blackwell, GB203)  +  Hyprland / Wayland
#
#  Blackwell (RTX 50xx) REQUIREMENTS — the parts people get wrong:
#   1. open = true        -> Blackwell ONLY works with the open kernel modules.
#                            The legacy closed modules do not support it.
#   2. A recent driver    -> 575+ (production) is needed. We use `.stable`, which
#                            on nixos-unstable should already be >= 575. If your
#                            rebuild fails or you get a black screen, switch to
#                            `.beta` or `.latest` (see below).
#   3. modesetting + DRM  -> required for any Wayland compositor.
# =============================================================================
{ config, pkgs, lib, ... }:
{
  # OpenGL / Vulkan + 32-bit support (needed for Steam/Proton, wine, etc.)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;

    # REQUIRED for Blackwell. (open = the open-source kernel modules, NOT nouveau.)
    open = true;

    nvidiaSettings = true;

    # Power management: keep off unless you hit suspend/resume corruption, then try true.
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Driver branch. `.stable` should be fine on unstable for Blackwell.
    # If you need newer:  package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot.kernelParams = [
    "nvidia_drm.modeset=1"
    "nvidia_drm.fbdev=1"   # framebuffer console on the NVIDIA GPU; smoother boot/handoff
  ];

  # Load nvidia modules early so the framebuffer is up before the display manager.
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  # ---------------------------------------------------------------------------
  # Wayland/Hyprland session env for NVIDIA. These replace the commented-out
  # `env = ...` lines in your hyprland.conf (now handled at the system level).
  # ---------------------------------------------------------------------------
  environment.sessionVariables = {
    # Hardware video accel via NVIDIA
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # NOTE: GBM_BACKEND=nvidia-drm is intentionally NOT set — on recent drivers it
    # tends to break Electron/Chromium. Add it only if you hit GBM issues.
  };

  # llama.cpp built against CUDA for the 5070 Ti (laptop uses the Vulkan build).
  environment.systemPackages = [ (pkgs.llama-cpp.override { cudaSupport = true; }) ];
}
