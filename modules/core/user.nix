{
  config,
  pkgs,
  lib,
  inputs,
  vars ? import ../../variables.nix,
  username ? vars.username or "ratul",
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.default
  ];

  # Shell configuration (zsh enabled for user ratul, disabled in headless jenkins mode)
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

  # Trusted users for Nix package manager
  nix.settings.trusted-users = lib.mkForce [
    "root"
    (if vars.jenkins then "jenkins" else username)
  ];

  # Home Manager user configuration (active when not in jenkins mode)
  home-manager = lib.mkIf (!vars.jenkins) {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs username;
    };
    users.${username} = {
      imports = [ ./../home ];
    };
  };
}

