{ config, pkgs, ... }:
{
  # Enable Open vSwitch
  virtualisation.vswitch.enable = true;

  # Initialize Open vSwitch bridge via systemd
  systemd.services.ovs-init = {
    description = "Open vSwitch bridge initialization";
    after = [ "ovsdb.service" "ovs-vswitchd.service" ];
    requires = [ "ovsdb.service" "ovs-vswitchd.service" ];
    before = [ "network.target" "systemd-networkd.service" ];
    wantedBy = [ "network-pre.target" "multi-user.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for OVS socket to be ready
      for i in {1..10}; do
        if [ -S /run/openvswitch/db.sock ]; then
          break
        fi
        echo "Waiting for OVS socket..."
        sleep 1
      done

      # Ensure bridge exists
      ${pkgs.openvswitch}/bin/ovs-vsctl --may-exist add-br br-int
      
      # Add physical port and bring it up
      ${pkgs.openvswitch}/bin/ovs-vsctl --may-exist add-port br-int enp9s0f0
      ${pkgs.iproute2}/bin/ip link set enp9s0f0 up
      
      # Create internal ports and bring them up
      ${pkgs.openvswitch}/bin/ovs-vsctl --may-exist add-port br-int pxe-net -- set interface pxe-net type=internal
      ${pkgs.iproute2}/bin/ip link set pxe-net up
      
      # Create mgmt port with correct tag syntax and bring it up
      ${pkgs.openvswitch}/bin/ovs-vsctl --may-exist add-port br-int mgmt20 tag=20 -- set interface mgmt20 type=internal
      ${pkgs.iproute2}/bin/ip link set mgmt20 up
    '';
  };

  # Create the virtual VRF device
  systemd.network.netdevs."vrf-blue" = {
    netdevConfig = {
      Name = "vrf-blue";
      Kind = "vrf";
    };
    vrfConfig.Table = 100;
  };

  # Configure networkd for pxe-net (Primary Gateway)
  systemd.network.networks."30-pxe-net" = {
    matchConfig.Name = "pxe-net";
    networkConfig = {
      DHCP = "yes";
      # VRF = "vrf-blue"; # Uncomment to enable VRF for this interface
    };
    dhcpV4Config.RouteMetric = 1024; # Primary
  };

  # Configure networkd for mgmt20 (Secondary Gateway)
  systemd.network.networks."40-mgmt20" = {
    matchConfig.Name = "mgmt20";
    networkConfig = {
      Address = "10.20.0.30/16";
    };
    routes = [{
      Gateway = "10.20.0.1";
      Metric = 2048; # Secondary
    }];
  };

  networking = {
    # Use networkd for network management
    useNetworkd = true;
    useDHCP = false;

    # Interface configuration
    interfaces = {
      # Physical interface - no IP
      enp9s0f0.useDHCP = false;
    };
  };
}
