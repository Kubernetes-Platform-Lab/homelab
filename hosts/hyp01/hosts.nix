{ config, pkgs, ... }:
{
  networking.hosts = {
    "127.0.0.1" = [
      "localhost"
    ];

    "127.0.0.2" = [
      "hpnix"
    ];

    "10.20.0.30" = [
      "hyp01.akna.lan"
    ];
  };
}
