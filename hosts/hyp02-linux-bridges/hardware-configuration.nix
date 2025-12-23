{ config, lib, pkgs, modulesPath, ... }:

{
  # PLACEHOLDER: Generate actual hardware configuration with:
  # nixos-generate-config --show-hardware-config
  
  # This is a template that should be replaced with actual hardware configuration
  # when deploying to real hardware
  
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Example configuration - REPLACE WITH ACTUAL VALUES
  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # File systems - REPLACE WITH ACTUAL VALUES
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Swap - ADJUST AS NEEDED
  swapDevices = [ ];

  # CPU microcode
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
  # Or for AMD:
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
