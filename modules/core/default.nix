{
  config,
  pkgs,
  lib,
  vars ? import ../../variables.nix,
  hostName ? vars.hostName or "nixos-lxc",
  username ? vars.username or "ratul",
  ...
}:

{
  # Validation: jenkins and docker cannot both be true
  assertions = [
    {
      assertion = !(vars.jenkins && vars.docker);
      message = "Conflict in variables.nix: 'jenkins' and 'docker' cannot both be true! Select 'jenkins = true' (Jenkins Agent with Docker & user jenkins), 'docker = true' (Docker with user ratul), or leave both false (Bare Metal with user ratul).";
    }
  ];

  imports = [
    # LXC container optimizations & tuning
    ./lxc.nix
  ]
  ++ lib.optional vars.jenkins ./jenkins.nix
  ++ lib.optional vars.docker ./docker.nix;

  # Hostname & Networking
  networking.hostName = hostName;

  # Time Zone & Locale
  time.timeZone = "Asia/Dhaka";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Shell configuration (zsh enabled for interactive user ratul, disabled in headless jenkins mode)
  programs.zsh.enable = !vars.jenkins;

  # User accounts
  users.mutableUsers = true;

  users.users = {
    # Root account configuration
    root = {
      initialHashedPassword = ""; # Allows passwordless root login on container console
      openssh.authorizedKeys.keys = vars.authorizedKeys or [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2kXjQ5NmBPJUxeLwJkex8Za6L+yLtQy021v4nrg0TV rezwanahmedratul007@gmail.com"
      ];
    };
  }
  // lib.optionalAttrs (!vars.jenkins) {
    # Primary non-root user (omitted when jenkins = true)
    ${username} = {
      isNormalUser = true;
      description = "Rezwan Ahmed Ratul";
      extraGroups = [
        "wheel"
        "networkmanager"
      ] ++ lib.optional vars.docker "docker";
      shell = pkgs.zsh;
      initialHashedPassword = "";
      openssh.authorizedKeys.keys = vars.authorizedKeys or [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2kXjQ5NmBPJUxeLwJkex8Za6L+yLtQy021v4nrg0TV rezwanahmedratul007@gmail.com"
      ];
    };
  };

  # Passwordless sudo for wheel group inside container
  security.sudo.wheelNeedsPassword = false;

  # OpenSSH server configuration
  services.openssh = {
    enable = true;
    startWhenNeeded = false; # Run as dedicated daemon on boot
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = true;
    };
    openFirewall = true;
  };

  # Nix Package Manager & Flakes configuration
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = lib.mkForce [
      "root"
      (if vars.jenkins then "jenkins" else username)
    ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  # Essential base utilities only (slimmed down)
  environment.systemPackages = with pkgs; [
    curl
    git
    vim
  ];

  system.stateVersion = "26.11";
}
