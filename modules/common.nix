{ config, pkgs, lib, ... }:

{
  # Common configuration shared across all hypervisors
  
  # NixOS version
  system.stateVersion = "25.11";

  # Enable SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password"; # Allow root via key, or password if enabled below
      PasswordAuthentication = true; # Temporarily enable for recovery
    };
  };

  # Common system packages for hypervisor management
  environment.systemPackages = with pkgs; [
    vim
    htop
    tmux
    curl
    wget
    git
    rsync
    sudo
  ];

  # Basic firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH
  };

  # Nix settings for flakes
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" "admin" ];
      
      # Placeholder for future Private Binary Cache (GitOps)
      # substituters = [
      #   "https://cache.nixos.org"
      #   "https://your-private-cache.example.com/main"
      # ];
      # trusted-public-keys = [
      #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      #   "main:your-signing-key-goes-here"
      # ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # sops-nix configuration
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    # Decrypt using the host's SSH key
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    
    # Secrets to decrypt on the target system
    secrets = {
      "passwords/root_password" = {
        neededForUsers = true;
      };
      "api_keys/cachix_token" = {};
    };
  };

  # User configuration
  users.users = {
    root = {
      # Keep root password for physical console access
      hashedPasswordFile = config.sops.secrets."passwords/root_password".path;
      # hashedPassword = "$6$a9dc8NDYWXIdX0X6$tpzvYa/OeiKOYGQB5wxOBTLqSR6VBRnaEtBb8tX.w0GYjtB7uZ0/t2vnLXPQayHIFPHLl/0GtDR05HM1CFsOJ.";
    };
    
    admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" "libvirtd" ]; # Enable sudo
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMiQXrspaQ0JaKc9lYKryyCr4+uuf56WlOZ4k8cVXLcf wkubica@polcom"
      ];
      # Use the same password from sops for sudo
      hashedPasswordFile = config.sops.secrets."passwords/root_password".path;
      # hashedPassword = "$6$a9dc8NDYWXIdX0X6$tpzvYa/OeiKOYGQB5wxOBTLqSR6VBRnaEtBb8tX.w0GYjtB7uZ0/t2vnLXPQayHIFPHLl/0GtDR05HM1CFsOJ.";
    };
  };

  # Allow passwordless sudo for the wheel group (optional, but convenient)
  security.sudo.wheelNeedsPassword = false;
}
