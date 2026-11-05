{
  description = "NixOS LXC Container Tarball Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      vars = import ./variables.nix;
      system = "x86_64-linux";
      username = vars.username or "ratul";

      # Helper function to define an LXC NixOS system
      mkLxcSystem =
        {
          hostName ? vars.hostName or "nixos-lxc",
          isProxmox ? false,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs vars username hostName;
          };
          modules = [
            # Base container virtualization module from nixpkgs
            (
              if isProxmox then
                "${nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix"
              else
                "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
            )

            # Core NixOS system configuration (imports home-manager module and feature modules)
            ./configuration.nix
          ]
          ++ nixpkgs.lib.optional (!isProxmox) {
            # Disable bundling the whole nixpkgs channel to save ~200MB+ in image size
            system.installer.channel.enable = false;
          };
        };
    in
    {
      nixosConfigurations = {
        # Standard LXC / Incus / LXD container configuration
        nixos-lxc = mkLxcSystem {
          hostName = vars.hostName or "nixos-lxc";
          isProxmox = false;
        };

        # Proxmox VE LXC container configuration
        proxmox-lxc = mkLxcSystem {
          hostName = vars.hostName or "proxmox-lxc";
          isProxmox = true;
        };
      };

      packages.${system} = {
        # Default package: standard LXC container tarball (.tar.xz)
        default = self.packages.${system}.tarball;

        # Standard LXC container tarball
        tarball = self.nixosConfigurations.nixos-lxc.config.system.build.tarball;

        # Proxmox VE specific LXC tarball
        proxmox = self.nixosConfigurations.proxmox-lxc.config.system.build.tarball;
      };
    };
}
