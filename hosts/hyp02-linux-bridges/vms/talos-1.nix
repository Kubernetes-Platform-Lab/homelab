{ config, pkgs, ... }:

{
  # Systemd service to define the VM on boot
  systemd.services.define-talos-1-vm = {
    description = "Define Talos VM 1 in libvirt";
    after = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Check if VM already exists
      if ! ${pkgs.libvirt}/bin/virsh list --all | grep -q talos-1; then
        # Define the VM from XML
        ${pkgs.libvirt}/bin/virsh define /home/valdi/Poligon/nixlab/hosts/hyp01/vms/talos-1.xml
        # Set VM to auto-start
        ${pkgs.libvirt}/bin/virsh autostart talos-1
      fi
    '';
  };

  # Optional: Auto-start the VM
  systemd.services.autostart-talos-1-vm = {
    description = "Auto-start Talos VM 1";
    after = [ "libvirtd.service" "define-talos-1-vm.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Start the VM if it's not running
      if ! ${pkgs.libvirt}/bin/virsh list | grep -q talos-1; then
        ${pkgs.libvirt}/bin/virsh start talos-1
      fi
    '';
  };
}
