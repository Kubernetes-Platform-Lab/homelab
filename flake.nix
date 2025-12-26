{
  description = "Talos Kubernetes Lab - Hypervisor Infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, deploy-rs, disko, sops-nix, ... }: {
    # NixOS configurations
    nixosConfigurations = {
      hyp01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/hyp01/configuration.nix
          ./hosts/hyp01/disko.nix
        ];
      };
      hyp02 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/hyp02/configuration.nix
          ./hosts/hyp02/disko.nix
        ];
      };
      hyp03 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/hyp03/configuration.nix
          ./hosts/hyp03/disko.nix
        ];
      };
      hyp04 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./hosts/hyp04/configuration.nix
          ./hosts/hyp04/disko.nix
        ];
      };
    };

    # deploy-rs configuration
    deploy.nodes = {
      hyp01 = {
        hostname = "10.20.0.30";  # Management IP (VLAN 20)
        # For initial deployment, override with: --hostname YOUR_CURRENT_IP

        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.hyp01;

          user = "root";

          # SSH options
          sshOpts = [
            "-o" "StrictHostKeyChecking=accept-new"
          ];
        };

        # Fast connection for remote deployment
        fastConnection = false;
        autoRollback = true;
        magicRollback = true;
        confirmTimeout = 30;
      };
      hyp02 = {
        hostname = "10.20.0.31";  # Management IP (VLAN 20)
        # For initial deployment, override with: --hostname YOUR_CURRENT_IP

        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.hyp02;

          user = "root";

          # SSH options
          sshOpts = [
            "-o" "StrictHostKeyChecking=accept-new"
          ];
        };

        # Fast connection for remote deployment
        fastConnection = false;
        autoRollback = true;
        magicRollback = true;
        confirmTimeout = 30;
      };
      hyp03 = {
        hostname = "10.20.0.32";  # Management IP (VLAN 20)
        # For initial deployment, override with: --hostname YOUR_CURRENT_IP

        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.hyp03;

          user = "root";

          # SSH options
          sshOpts = [
            "-o" "StrictHostKeyChecking=accept-new"
          ];
        };

        # Fast connection for remote deployment
        fastConnection = false;
        autoRollback = true;
        magicRollback = true;
        confirmTimeout = 30;
      };
      hyp04 = {
        hostname = "10.20.0.33";  # Management IP (VLAN 20)
        # For initial deployment, override with: --hostname YOUR_CURRENT_IP

        profiles.system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.hyp04;

          user = "root";

          # SSH options
          sshOpts = [
            "-o" "StrictHostKeyChecking=accept-new"
          ];
        };

        # Fast connection for remote deployment
        fastConnection = false;
        autoRollback = true;
        magicRollback = true;
        confirmTimeout = 30;
      };
    };
  };
}
