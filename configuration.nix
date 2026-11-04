{
  config,
  pkgs,
  lib,
  username ? "ratul",
  hostName ? "nixos-lxc",
  ...
}:

{
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

  # Shell configuration
  programs.zsh.enable = true;

  # User accounts
  users.mutableUsers = true;

  # Root account configuration
  users.users.root = {
    initialHashedPassword = ""; # Allows passwordless root login on container console
  };

  # Primary non-root user
  users.users.${username} = {
    isNormalUser = true;
    description = "Rezwan Ahmed Ratul";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
    initialHashedPassword = "";
  };

  # Passwordless sudo for wheel group inside container
  security.sudo.wheelNeedsPassword = false;

  # Nix Package Manager & Flakes configuration
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      username
    ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  # System-wide packages
  environment.systemPackages = with pkgs; [
    # Core utilities
    curl
    wget
    git
    vim
    neovim
    tmux
    file
    which
    tree
    jq

    # System inspection & performance
    htop
    btop
    fastfetch

    # Networking tools
    iproute2
    nettools
    dnsutils
    iptables

    # Modern shell tools
    eza
    bat
    ripgrep
    fd
    zoxide
    fzf
    starship
  ];

  system.stateVersion = "26.11";
}
