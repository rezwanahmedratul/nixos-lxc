{
  config,
  pkgs,
  lib,
  vars ? import ../../variables.nix,
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
    ./system.nix
    ./user.nix
    ./packages.nix
    ./lxc.nix
  ]
  ++ lib.optional vars.jenkins ./jenkins.nix
  ++ lib.optional vars.docker ./docker.nix;
}
