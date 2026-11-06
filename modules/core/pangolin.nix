{
  config,
  pkgs,
  lib,
  vars ? import ../../variables.nix,
  ...
}:

let
  siteConfig = vars.pangolinSite or { };
  siteId = siteConfig.id or vars.pangolinId or "";
  siteSecret = siteConfig.secret or vars.pangolinSecret or "";
  endpoint = siteConfig.endpoint or vars.pangolinEndpoint or "https://pangolin.ratul.fun";
in
{
  # Install pangolin-cli utility in the container system environment
  environment.systemPackages = with pkgs; [
    pangolin-cli
  ];

  # Declarative background service for Pangolin Site tunnel (equivalent to `pangolin up site`)
  systemd.services.pangolin-site = {
    description = "Pangolin Site Tunnel";
    aliases = [ "pangolin.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      NEWT_ID = siteId;
      NEWT_SECRET = siteSecret;
      PANGOLIN_ENDPOINT = endpoint;
    };

    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";
      Restart = "always";
      RestartSec = 2;
      UMask = "0077";
      PrivateTmp = true;
      ExecStart = "${pkgs.pangolin-cli}/bin/pangolin up site --id ${siteId} --secret ${siteSecret} --endpoint ${endpoint}";
    };
  };
}
