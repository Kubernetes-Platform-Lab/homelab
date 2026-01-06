{ config, pkgs, ... }:

let
  xmldir = ../vms ;  # Adjust this path as needed
in
{
  environment.etc."libvirt/qemu/talos-1.xml" = {
    source = "${xmldir}/talos-1.xml";  # Path within your source directory
    mode = "0644";
  };

  # Systemd service to define the VM and ensure image existence
  systemd.services.define-talos-1-vm = {
    description = "Define Talos VM 1 and ensure storage";
    after = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # 1. Ensure the images directory exists
      mkdir -p /var/lib/libvirt/images

      # 2. Create qcow2 image if it doesn't exist
      if [ ! -f /var/lib/libvirt/images/talos-1.qcow2 ]; then
        ${pkgs.qemu_kvm}/bin/qemu-img create -f qcow2 /var/lib/libvirt/images/talos-1.qcow2 20G
        chmod 600 /var/lib/libvirt/images/talos-1.qcow2
      fi

      # 3. Always redefine to apply XML changes safely
        ${pkgs.libvirt}/bin/virsh destroy talos-1 || true
        ${pkgs.libvirt}/bin/virsh undefine talos-1 || true
        sleep 5
        echo "undefined"

      # 4. Define the VM from XML
        ${pkgs.libvirt}/bin/virsh define /etc/libvirt/qemu/talos-1.xml
        ${pkgs.libvirt}/bin/virsh start talos-1
        ${pkgs.libvirt}/bin/virsh autostart talos-1
    '';
  };
}
