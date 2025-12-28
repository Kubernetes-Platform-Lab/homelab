{ config, pkgs, ... }:
{
  networking.hosts = {
    "127.0.0.1" = [
      "localhost"
    ];

    "127.0.0.2" = [
      "hyp04"
    ];

    "10.20.0.30" = [
      "hyp01.akna.lan"
    ];
    "10.20.0.31" = [
      "hyp02.akna.lan"
    ];
    "10.20.0.32" = [
      "hyp03.akna.lan"
    ];
    "10.20.0.33" = [
      "hyp04.akna.lan"
    ];
  };
}
