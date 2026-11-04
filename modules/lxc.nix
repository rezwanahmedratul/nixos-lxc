{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Mark as container
  boot.isContainer = true;

  # Avoid bundling the entire nixpkgs channel source inside the container tarball.
  # This saves ~200MB+ in image size while keeping flake-based workflows intact.
  system.installer.channel.enable = lib.mkDefault false;

  # Allow root and interactive login via container consoles (lxc-console, pct enter, etc.)
  services."getty@tty1".enable = lib.mkForce true;
  services."autovt@".enable = lib.mkForce true;

  # Unprivileged ping support (enables ICMP for non-root users in unprivileged LXC)
  security.wrappers.ping = {
    owner = "root";
    group = "root";
    capabilities = "cap_net_raw+p";
    source = "${pkgs.iputils.out}/bin/ping";
  };

  # Network configuration: support DHCP and systemd-networkd on veth / eth interfaces
  networking.useDHCP = lib.mkDefault true;
  networking.useHostResolvConf = lib.mkDefault false;
  systemd.network.enable = lib.mkDefault true;

  # Fast startup: don't block boot waiting for optional network interfaces to be online
  systemd.targets.network-online.wantedBy = lib.mkForce [];
  systemd.services.systemd-networkd-wait-online.enable = lib.mkDefault false;

  # SSH daemon enabled by default for container access
  services.openssh = {
    enable = lib.mkDefault true;
    startWhenNeeded = lib.mkDefault true;
    settings = {
      PermitRootLogin = lib.mkDefault "prohibit-password";
      PasswordAuthentication = lib.mkDefault true;
    };
  };
}

