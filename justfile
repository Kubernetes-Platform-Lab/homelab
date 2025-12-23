hyp01:
  nix run github:serokell/deploy-rs -- .#hyp01 --ssh-user admin
  #sudo nix run github:nix-community/nixos-avim nywhere -- --flake .#hyp01 root@10.10.0.55 
hyp02:
  nix run github:serokell/deploy-rs -- .#hyp02 --ssh-user admin
  #sudo nix run github:nix-community/nixos-avim nywhere -- --flake .#hyp02 root@10.10.0.xx

