{ lib, ... }:

{
  # Disko configuration for hyp01 hypervisor
  # This defines the disk partitioning scheme for automated installation

  disko.devices = {
    disk = {
      # Main system disk
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Fanxiang_S500Pro_256GB_FXS500Pro253860116"; # IMPORTANT: Adjust to your actual disk device
        content = {
          type = "gpt";
          partitions = {
            # EFI boot partition
            boot = {
              size = "512M";
              type = "EF00"; # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };

            # Root partition
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };

      #Optional: Separate disk for VM storage
      #Uncomment and adjust if you have a dedicated disk for VMs
      # vm-storage = {
      #   type = "disk";
      #   device = "/dev/sda";  # Raw block device for VM images
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       vms = {
      #         size = "100%";
      #         content = {
      #           type = "filesystem";
      #           format = "xfs";
      #           mountpoint = "/var/lib/libvirt";
      #           mountOptions = [ "defaults" "noatime" ];
      #         };
      #       };
      #     };
      #   };
      # };
    };
  };
}
