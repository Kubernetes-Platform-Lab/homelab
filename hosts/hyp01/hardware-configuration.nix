{ config, lib, pkgs, modulesPath, ... }:

{
  # PLACEHOLDER: Generate actual hardware configuration with:
  # nixos-generate-config --show-hardware-config

  # This is a template that should be replaced with actual hardware configuration
  # when deploying to real hardware
  #
  # NOTE: File systems are managed by disko.nix, not here!

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Example configuration - REPLACE WITH ACTUAL VALUES
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  #hardware.enableRedistributableFirmware = true;
  #hardware.firmware = [ pkgs.linux-firmware ];

  # AMD CPU microcode
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
