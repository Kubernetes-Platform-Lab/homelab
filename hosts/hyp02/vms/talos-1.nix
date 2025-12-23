{ config, pkgs, ... }:

{
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
        echo "Creating disk image /var/lib/libvirt/images/talos-1.qcow2 (20G)..."
        ${pkgs.qemu_kvm}/bin/qemu-img create -f qcow2 /var/lib/libvirt/images/talos-1.qcow2 20G
        chmod 600 /var/lib/libvirt/images/talos-1.qcow2
      fi

      # 3. Always redefine to apply XML changes safely
      if ${pkgs.libvirt}/bin/virsh list --all | grep -qx "talos-1"; then
        echo "Updating definition for talos-1..."
        ${pkgs.libvirt}/bin/virsh destroy talos-1 || true
        ${pkgs.libvirt}/bin/virsh undefine talos-1
      fi

      # 4. Define the VM from XML
      ${pkgs.libvirt}/bin/virsh define ${./talos-1.xml}
      ${pkgs.libvirt}/bin/virsh autostart talos-1
    '';
  };

  # Auto-start the VM
  systemd.services.autostart-talos-1-vm = {
    description = "Auto-start Talos VM 1";
    after = [ "libvirtd.service" "define-talos-1-vm.service" ];
    wants = [ "define-talos-1-vm.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Start the VM if it's not running
      if ! ${pkgs.libvirt}/bin/virsh list --name | grep -qx talos-1; then
        echo "Starting VM talos-1..."
        ${pkgs.libvirt}/bin/virsh start talos-1
      fi
    '';
  };
}
