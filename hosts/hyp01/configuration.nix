{ config, pkgs, lib, ... }:

{
  imports = [
    # Hardware configuration - generate with: nixos-generate-config
    ./hardware-configuration.nix

    # Host-specific network configuration
    ./networking.nix
    ./hosts.nix

    # VM configurations
    ./vms/talos-1.nix

    # Shared modules
    ../../modules/common.nix
    ../../modules/libvirt.nix

    # Host-specific certificates for cockpit
    ./cockpit.nix
  ];

  # Hostname
  networking.hostName = "hyp01";

  services.udev.extraRules = ''
    KERNEL=="sda", GROUP="kvm", MODE="0660"
  '';

  # Boot loader configuration (example - adjust for your hardware)
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
