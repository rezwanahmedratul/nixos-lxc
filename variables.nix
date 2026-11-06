{
  # Mode Selection (Choose ONE mode; both cannot be true)
  jenkins = false; # Jenkins Agent (includes Docker, removes ratul, adds jenkins user)
  docker = false; # Standalone Docker (Docker & Compose with user ratul)

  # System Hostname
  hostName = "nixos-jenkins-agent";

  # Pangolin Site Client (Tunnels this LXC container to your Pangolin gateway)
  pangolin = true;
  pangolinSite = {
    id = "your-site-id";
    secret = "your-site-secret";
    endpoint = "https://your-pangolin-endpoint";
  };

  # Primary User Configuration (Active when jenkins = false)
  username = "ratul";

  # SSH Authorized Keys for user 'ratul' and root
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2kXjQ5NmBPJUxeLwJkex8Za6L+yLtQy021v4nrg0TV rezwanahmedratul007@gmail.com"
  ];

  # SSH Authorized Keys for user 'jenkins'
  # Add the public SSH key of your Docker Jenkins Controller here (e.g. from id_rsa.pub or id_ed25519.pub):
  jenkinsAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2kXjQ5NmBPJUxeLwJkex8Za6L+yLtQy021v4nrg0TV rezwanahmedratul007@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqE6+H7/m6tsCtT9YGWr1S7BY5ztS82YcubMMNXLy3P docker-server"
  ];
}
