hyp01:
  nix run github:serokell/deploy-rs -- .#hyp01 --ssh-user admin
  #sudo nix run github:nix-community/nixos-anywhere -- --flake .#hyp01 root@10.10.0.55 
hyp02:
  nix run github:serokell/deploy-rs -- .#hyp02 --ssh-user admin
  #sudo nix run github:nix-community/nixos-anywhere-- --flake .#hyp02 root@10.10.0.xx
hyp03:
  nix run github:serokell/deploy-rs -- .#hyp03 --ssh-user admin
  #sudo nix run github:nix-community/nixos-anywhere -- --flake .#hyp02 root@10.10.0.xx
hyp04:
  nix run github:serokell/deploy-rs -- .#hyp04 --ssh-user admin
