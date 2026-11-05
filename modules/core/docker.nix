{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enable Docker daemon
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Docker Compose and CLI utilities
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}

