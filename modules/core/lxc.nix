{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Mark as container
  boot.isContainer = true;

  # Allow root and interactive login via container consoles (lxc-console, pct enter, etc.)
  systemd.services."getty@tty1".enable = lib.mkForce true;
  systemd.services."autovt@".enable = lib.mkForce true;

  # Unprivileged ping support (enables ICMP for non-root users in unprivileged LXC)
  security.wrappers.ping = {
    owner = "root";
    group = "root";
    capabilities = "cap_net_raw+p";
    source = "${pkgs.iputils.out}/bin/ping";
  };

  # Network configuration: modern systemd-networkd with DHCP on veth/eth interfaces
  networking.useDHCP = lib.mkDefault false;
  networking.useNetworkd = lib.mkDefault true;
  networking.useHostResolvConf = lib.mkForce false;
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
