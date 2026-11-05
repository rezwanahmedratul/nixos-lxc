{ pkgs, ... }:

{
  # Essential system-wide base packages
  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];
}
