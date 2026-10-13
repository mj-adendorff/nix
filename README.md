# NixOS config — Hyprland · desktop (RTX 5070 Ti · Ryzen 7 7800X3D) · laptop (Zenbook S14 UX5406SA)

Declarative NixOS config replicating my CachyOS Hyprland setup, with two hosts:

| Host      | Hardware                                                              | Flake target |
|-----------|-----------------------------------------------------------------------|--------------|
| `desktop` | AMD Ryzen 7 7800X3D + NVIDIA RTX 5070 Ti (Blackwell)                  | `#desktop`   |
| `laptop`  | ASUS Zenbook S14 UX5406SA — Core Ultra 200V (Lunar Lake) + Arc 140V   | `#laptop`    |

## Layout

```
nix/
├── flake.nix                  # inputs (nixpkgs unstable, hyprland, nixos-hardware) + host wiring
├── hosts/
│   ├── desktop/
│   │   ├── configuration.nix  # hostname, initrd SSH unlock, WoL, firewall ports
│   │   └── hardware-configuration.nix
│   └── laptop/
│       ├── configuration.nix  # hostname, power-profiles-daemon, thermald, lid handling
│       └── hardware-configuration.nix  # PLACEHOLDER — regenerate on the laptop! (see below)
├── modules/
│   ├── common.nix             # shared: GRUB dual-boot, kernel, user, locale, zsh, nix settings, SMB share
│   ├── nvidia.nix             # desktop: Blackwell driver (open modules + Wayland env), CUDA llama.cpp
│   ├── intel-arc.nix          # laptop: Lunar Lake xe/iHD via nixos-hardware, Vulkan llama.cpp
│   ├── hyprland.nix           # Hyprland session, greetd/tuigreet, portals, polkit
│   ├── desktop.nix            # pipewire, bluetooth, fonts, steam, zram, firewall
│   ├── dev.nix                # docker, libvirt, global toolchain, direnv
│   └── packages.nix           # apps/utilities translated from `pacman -Qqe`
```

Dotfiles are **not** managed by Nix — they live in the bare git repo
`git@github.com:mj-adendorff/.dotfiles.git` (alias `config`). On first boot the
`dotfiles-bootstrap` service clones it into `~/.dotfiles` and checks it out into
`$HOME` (once only; it won't overwrite existing files). Check it with
`journalctl -u dotfiles-bootstrap`.

## Install on the target machine

1. **Boot the NixOS minimal ISO**, partition & mount your disks to `/mnt`
   (and the EFI partition to `/mnt/boot`). Pick `<host>` = `desktop` or `laptop` below.

   *Laptop:* turn **Secure Boot off** in the BIOS (F2).

   **ESP size:** root is LUKS-encrypted, so GRUB copies every kernel + initrd
   onto the EFI partition (`/boot`). It needs **≥ 1 GiB** (the desktop's is ~5 GB).
   The Zenbook's factory Windows ESP is far smaller, so don't reuse it. Instead,
   shrink Windows and create a separate **1 GiB FAT32 ESP** for NixOS
   (`mkfs.fat -F 32 -n NIXBOOT`, partition type `EF00`) and mount *that* at `/mnt/boot`.
   A second ESP is fine: os-prober still finds Windows' bootloader on the original one.
   Check sizes with `lsblk -o NAME,SIZE,FSTYPE,PARTTYPENAME`.

2. **Generate the real hardware config** — this step is mandatory:
   ```sh
   sudo nixos-generate-config --root /mnt
   ```

3. **Get this repo onto the machine** (git clone, USB, scp…), then **overwrite
   the placeholder** with the freshly generated hardware file:
   ```sh
   cp /mnt/etc/nixos/hardware-configuration.nix \
      /path/to/nix/hosts/<host>/hardware-configuration.nix
   ```

4. **Install:**
   ```sh
   sudo nixos-install --flake /path/to/nix#<host>
   ```
   Set a root password when prompted, reboot, then set your user password:
   ```sh
   passwd mjadendorff   # (or do it via `users.users.mjadendorff.initialPassword` before install)
   ```

5. **Day-to-day rebuilds** after the system is up (repo lives at `~/nix`):
   ```sh
   sudo nixos-rebuild switch --flake ~/nix            # picks the target matching the hostname
   nix flake update --flake ~/nix                    # bump inputs
   ```

## Zenbook S14 (UX5406SA) notes — read `modules/intel-arc.nix` / `hosts/laptop/`

- GPU uses the **`xe`** driver + iHD VA-API, from nixos-hardware's Lunar Lake
  profile. Needs a recent kernel; `linuxPackages_latest` is used on both hosts.
- **Audio** is SoundWire (cs42l43 + cs35l56). It works with current kernel +
  `sof-firmware` + `alsa-ucm-conf`, all provided on nixos-unstable. If you only get
  "Dummy Output", run `nix flake update` first: the fix lives in newer `alsa-ucm-conf`.
- **Power**: `power-profiles-daemon` + `thermald` (not TLP, which conflicts with
  ppd). Switch profiles with `powerprofilesctl` or the noctalia widget.
- **Display**: 2880×1800 OLED. Set the `eDP-1` monitor line in `hyprland.conf`
  (e.g. `monitor = eDP-1, 2880x1800@120, 0x0, 1.6`; the 120Hz mode is on 3K panels only).
- No initrd SSH unlock, WoL or open port 8000 on the laptop — those stay desktop-only.
- The `/mnt/drive` Pi share is on both hosts. It's automounted and times out after
  10s when you're away from home, so it won't hang. It needs `/etc/nixos/smb-secrets`
  on each machine.

## ⚠️ RTX 5070 Ti (Blackwell) notes — read `modules/nvidia.nix`

- `hardware.nvidia.open = true` is **required** for Blackwell. Don't flip it off.
- Driver is `nvidiaPackages.stable`. On `nixos-unstable` this should already be
  ≥ 575 and support Blackwell. **If you get a black screen / build error**, edit
  `modules/nvidia.nix` and switch to `.beta` (or `.latest`).
- If you ever see flickering cursors under Hyprland, your config already sets
  `cursor { no_hardware_cursors = true }` which is the usual fix.

## Dev environments (the NixOS way)

Don't install project toolchains globally. Per project, drop a `flake.nix` with a
dev shell and a `.envrc` containing `use flake`, then `direnv allow`. Example:

```nix
# project/flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { nixpkgs, ... }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = [ pkgs.nodejs_22 pkgs.pnpm pkgs.postgresql_16 ];
    };
  };
}
```
`cd` in → toolchain loads; `cd` out → it's gone. No global version conflicts.

## Things to review / adjust (carried over from your CachyOS config)

- **Timezone** in `modules/common.nix` is set to `Africa/Johannesburg`.
- **Monitors**: `hypr/hyprland.conf` has the laptop's `eDP-1` line (ignored
  on the desktop) and `DP-1, 2560x1440@165`. Adjust to your real outputs.
- **`wallpaper-rotator.sh`** is referenced in `exec-once` but was missing from
  `~/.config/hypr` — that autostart line will silently fail until you add it.
- **`snappy-switcher`** autostarts in `hyprland.conf` but isn't in nixpkgs; either
  remove that `exec-once` or package it manually.
- **Laptop-only bits** in your Hypr config (lid switch, keyboard backlight in
  `hypridle.conf`, brightnessctl) do nothing on the desktop but work on the laptop.
- **Databases**: postgres + mariadb run as services (as on CachyOS); valkey is CLI only.
- **`.zshrc`** (from the dotfiles repo) sources `/usr/share/zsh/plugins/...` and
  `/usr/bin/git`, which don't exist on NixOS. Autosuggestions/syntax-highlighting
  are loaded system-wide instead, so drop or guard those lines.

## Rollback

Every `nixos-rebuild switch` creates a boot generation. If a rebuild breaks the
system, reboot and pick the previous generation from the GRUB "NixOS — all
configurations" submenu, or:
```sh
sudo nixos-rebuild switch --rollback
```
```
