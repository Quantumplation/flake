# This is a TEMPLATE hardware configuration for Noether.
# After installing NixOS, replace this file with the auto-generated
# /etc/nixos/hardware-configuration.nix from your new system.
#
# To install:
# 1. Boot from USB
# 2. Partition your disk (e.g., with gdisk or parted)
# 3. Format partitions (mkfs.ext4, mkfs.fat, etc.)
# 4. Mount them to /mnt
# 5. Generate config: nixos-generate-config --root /mnt
# 6. Copy the generated hardware-configuration.nix here
# 7. Run: nixos-install --flake /mnt/path/to/flake#noether

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # NOTE: This is a placeholder. The actual hardware configuration
  # will be generated during installation with proper:
  # - Boot loader settings (systemd-boot or grub)
  # - File systems (UUIDs, mount points)
  # - Kernel modules
  # - CPU microcode
  # - Swap configuration

  # Recommended partitioning for Framework 16 with 4TB NVMe:
  # - EFI partition: 512MB (FAT32)
  # - Swap: 96GB (for hibernation with 96GB RAM)
  # - Root: remaining space (ext4 or btrfs)

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # AMD CPU (Framework 16 typically uses AMD Ryzen)
  hardware.cpu.amd.updateMicrocode = true;

  # Enable firmware updates
  services.fwupd.enable = true;
}
