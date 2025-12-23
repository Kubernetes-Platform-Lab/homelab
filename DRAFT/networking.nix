{ config, pkgs, ... }:

{
  # 1. Enable the Open vSwitch service
  virtualisation.vswitch.enable = true;

  networking = {
    useNetworkd = true;
    useDHCP = false;

    # 2. Define the OVS Bridge
    # In OVS, we typically use one main bridge and handle VLANs via tags.
    vswitch = {
      enable = true;
      bridges = {
        ovs-br0 = {
          interfaces = {
            # Attach physical interface as a trunk port
            eth0 = {};
          };
        };
      };
    };

    # 3. Host Management Interface (VLAN 20)
    # We create an "internal port" on the OVS bridge for the host itself.
    # Note: In a real NixOS setup, you'd ensure this port is created 
    # and tagged 20 via OVS commands or specialized systemd units.
    interfaces.mgmt20 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "10.20.0.30";
        prefixLength = 16;
      }];
    };
    
    # The physical interface usually shouldn't have an IP when part of a bridge
    interfaces.eth0.useDHCP = false;
  };
  
  # 4. Supplemental OVS setup (Example)
  # Sometimes needed to ensure internal ports are tagged correctly at boot
  systemd.services.ovs-config = {
    description = "Configure OVS internal ports and tags";
    after = [ "ovsdb.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      # Ensure mgmt20 exists as an internal port and is tagged VLAN 20
      ${pkgs.openvswitch}/bin/ovs-vsctl --may-exist add-port ovs-br0 mgmt20 -- set interface mgmt20 type=internal -- set port mgmt20 tag=20
    '';
  };
}
