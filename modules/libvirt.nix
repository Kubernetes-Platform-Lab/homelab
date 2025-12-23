{ config, pkgs, lib, ... }:

{
  # Shared libvirt/virtualization configuration
  
  virtualisation.libvirtd = {
    enable = true;
    extraConfig = ''
      unix_sock_group = "libvirtd"
      unix_sock_rw_perms = "0770"
      auth_unix_rw = "none"
    '';
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  # CLI management tools for libvirt
  environment.systemPackages = with pkgs; [
    libvirt      # virsh command-line tool
    qemu_kvm     # QEMU/KVM binaries
  ];

  # Allow traffic on bridge interfaces (important for VMs)
  networking.firewall.trustedInterfaces = [ "br-int" "pxe-net" "mgmt20" ];

  # Ensure virsh connects to qemu:///system by default for all users
  environment.variables.VIRSH_DEFAULT_CONNECT_URI = "qemu:///system";
}
