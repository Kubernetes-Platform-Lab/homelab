{ config, pkgs, ... }:

{
  networking = {
    # Use networkd for network management
    useNetworkd = true;
    useDHCP = false;

    # VLAN interfaces
    vlans = {
      vlan20 = {
        id = 20;
        interface = "eth0";
      };
      vlan30 = {
        id = 30;
        interface = "eth0";
      };
      vlan40 = {
        id = 40;
        interface = "eth0";
      };
    };

    # Bridge interfaces
    bridges = {
      # br10 for PXE boot - direct connection to eth0 (no VLAN tag)
      br10 = {
        interfaces = [ "eth0" ];
      };
      # VLAN bridges
      br20 = {
        interfaces = [ "vlan20" ];
      };
      br30 = {
        interfaces = [ "vlan30" ];
      };
      br40 = {
        interfaces = [ "vlan40" ];
      };
    };

    # Interface configuration
    interfaces = {
      # Physical interface - no IP, just up
      eth0 = {
        useDHCP = false;
      };

      # VLAN interfaces - no IP needed, will be on bridges
      vlan20 = {
        useDHCP = false;
      };
      vlan30 = {
        useDHCP = false;
      };
      vlan40 = {
        useDHCP = false;
      };

      # Bridge interfaces configuration
      # br10: PXE boot bridge (no IP, untagged VLAN for Talos initial boot)
      br10 = {
        useDHCP = false;
      };
      
      # br20: Hypervisor management bridge (VLAN 20)
      # This is for managing the NixOS host itself
      br20 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "10.20.0.30";
          prefixLength = 16;
        }];
      };
      
      # br30: Kubernetes nodes bridge (VLAN 30)
      # Talos VM will get 10.30.0.30 via its own configuration
      br30 = {
        useDHCP = false;
      };
      
      # br40: Kubernetes LoadBalancer services bridge (VLAN 40)
      # Talos will manage IPs in this range for LoadBalancer services
      br40 = {
        useDHCP = false;
      };
    };
  };
}
