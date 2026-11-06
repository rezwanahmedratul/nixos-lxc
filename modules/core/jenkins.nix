{
  config,
  pkgs,
  lib,
  vars ? import ../../variables.nix,
  ...
}:

{
  # Docker daemon and auto-pruning directly included for Jenkins agent to build images
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # JDK 21 (required by Jenkins SSH remoting agent) and Docker Compose
  environment.systemPackages = with pkgs; [
    jdk21
    docker-compose
  ];

  # Set JAVA_HOME system-wide
  environment.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk21}";
  };

  # Provide /usr/bin/java symlink so Jenkins SSH launcher can locate java out of the box
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/java - - - - ${pkgs.jdk21}/bin/java"
  ];

  # Dedicated Jenkins Agent User (ratul user is removed in jenkins mode)
  users.users.jenkins = {
    isNormalUser = true;
    home = "/home/jenkins";
    createHome = true;
    description = "Jenkins CI Build Agent";
    initialHashedPassword = ""; # Allows passwordless login on container console
    extraGroups = [
      "docker"
      "wheel"
    ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = vars.jenkinsAuthorizedKeys or [ ];
  };

  # OpenSSH daemon configuration for inbound Jenkins Controller connections
  services.openssh = {
    enable = true;
    startWhenNeeded = false;
    settings = {
      PermitRootLogin = lib.mkDefault "prohibit-password";
      PasswordAuthentication = lib.mkDefault true;
    };
    openFirewall = true;
  };
}
