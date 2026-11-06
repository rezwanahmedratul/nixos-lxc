{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Rezwan Ahmed Ratul";
        email = "rezwanahmedratul007@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      color.ui = "auto";
      safe.directory = [
        "/etc/nixos"
      ];
    };
  };
}

