{ config, pkgs, lib, ... }:

{
  imports = [
    # Hardware configuration - generate with: nixos-generate-config
    ./hardware-configuration.nix
    
    # Host-specific network configuration
    ./networking.nix
    
    # VM configurations
    ./vms/talos-1.nix
    
    # Shared modules
    ../../modules/common.nix
    ../../modules/libvirt.nix
  ];

  # Hostname
  networking.hostName = "hyp02";

  # Boot loader configuration (example - adjust for your hardware)
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
