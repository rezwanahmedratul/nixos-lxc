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
      system = "x86_64-linux";
      username = "ratul";

      # Helper function to define an LXC NixOS system
      mkLxcSystem =
        {
          hostName ? "nixos-lxc",
          isProxmox ? false,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs username hostName;
          };
          modules = [
            # Base container virtualization module from nixpkgs
            (
              if isProxmox then
                "${nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix"
              else
                "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
            )

            # LXC container tuning & optimizations
            ./modules/lxc.nix

            # Core NixOS system configuration
            ./configuration.nix

            # Home Manager module & user configuration
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs username;
              };
              home-manager.users.${username} = import ./home.nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        # Standard LXC / Incus / LXD container configuration
        nixos-lxc = mkLxcSystem {
          hostName = "nixos-lxc";
          isProxmox = false;
        };

        # Proxmox VE LXC container configuration
        proxmox-lxc = mkLxcSystem {
          hostName = "proxmox-lxc";
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
