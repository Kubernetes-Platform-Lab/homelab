{ config, pkgs, lib, ... }:

{
  # Ensure directory exists
  #  environment.etc."cockpit/ws-certs.d" = {
  #    source = null;  # null means no file, just create the directory
  #    isDirectory = true;  # Specify that this is a directory
  #  };

  sops.secrets.cockpitCert = {
    format = "yaml";
    path = "/etc/cockpit/ws-certs.d/cockpit.crt";
    sopsFile = ../../secrets/cockpit-secrets.yaml;
  };

  sops.secrets.cockpitKey = {
    format = "yaml";
    path = "/etc/cockpit/ws-certs.d/cockpit.key";
    sopsFile = ../../secrets/cockpit-secrets.yaml;
  };

  # Cockpit enable
  services.cockpit = {
    enable = true;
    allowed-origins = [ https://10.20.0.*:9090 https://hyp01.akna.lan:9090 ];
    settings = {
      cockpit = {
        AllowUnencrypted = "false";
      };
    };
  };
}
