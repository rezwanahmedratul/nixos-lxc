{
  pkgs,
  lib,
  username ? "ratul",
  ...
}:

{
  imports = [
    ./git.nix
    ./shell.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
