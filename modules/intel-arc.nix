# =============================================================================
#  Intel Lunar Lake — Core Ultra 200V + Arc 130V/140V iGPU (Xe2)  +  Hyprland
#
#  The heavy lifting comes from nixos-hardware's Lunar Lake profile:
#    - `xe` kernel driver (instead of i915), loaded in the initrd
#    - intel-media-driver (iHD) VA-API, intel-compute-runtime (OpenCL/Level Zero),
#      vpl-gpu-rt (QSV), CPU microcode updates
#  The kernel must be recent (we use linuxPackages_latest in modules/common.nix).
# =============================================================================
{ config, pkgs, lib, inputs, ... }:
{
  imports = [ "${inputs.nixos-hardware}/common/cpu/intel/lunar-lake" ];

  # OpenGL / Vulkan + 32-bit support (needed for Steam/Proton, wine, etc.)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Hardware video accel via the iHD VA-API driver
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  environment.systemPackages = with pkgs; [
    (llama-cpp.override { vulkanSupport = true; })  # llama.cpp on the Arc iGPU
    intel-gpu-tools   # intel_gpu_top
    libva-utils       # vainfo
  ];
}
