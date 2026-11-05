{
  config,
  pkgs,
  lib,
  inputs,
  vars ? import ./variables.nix,
  hostName ? vars.hostName or "nixos-lxc",
  username ? vars.username or "ratul",
  ...
}:

{
  imports = [
    # Home Manager as a NixOS module
    inputs.home-manager.nixosModules.default

    # Core system configuration & container modules
    ./modules/core
  ];

  # Home Manager user configuration (active when not in jenkins mode)
  home-manager = lib.mkIf (!vars.jenkins) {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs username;
    };
    users.${username} = import ./modules/home;
  };
}
