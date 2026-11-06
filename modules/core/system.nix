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
      # Allow standard MACs required by Jenkins Java SSH agent (Trilead SSH)
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
        "hmac-sha2-512"
        "hmac-sha2-256"
        "hmac-sha1"
      ];
      # Allow standard key exchange algorithms for compatibility
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "ecdh-sha2-nistp256"
        "ecdh-sha2-nistp384"
        "ecdh-sha2-nistp521"
        "diffie-hellman-group-exchange-sha256"
        "diffie-hellman-group14-sha256"
      ];
    };
    extraConfig = ''
      HostKeyAlgorithms +ssh-rsa,rsa-sha2-256,rsa-sha2-512,ssh-ed25519
    '';
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