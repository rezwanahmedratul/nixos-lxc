{
  config,
  pkgs,
  lib,
  vars ? import ../../variables.nix,
  hostName ? vars.hostName or "nixos-lxc",
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
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.11";
}

