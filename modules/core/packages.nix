{ pkgs, ... }:

{
  # System-wide base packages
  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];
}

