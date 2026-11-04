# NixOS LXC Container Image

A modular, reproducible Flake configuration for building lightweight NixOS LXC / Proxmox VE / Incus container images with Home Manager integration.

---

## Architecture Overview

- **`flake.nix`**: Flake inputs and outputs. Exposes configurations (`nixos-lxc`, `proxmox-lxc`) and buildable packages (`default`, `tarball`, `proxmox`).
- **`configuration.nix`**: System-level configuration (hostname, timezone `Asia/Dhaka`, users `root` & `ratul`, shells, sudo permissions, Nix Flakes enablement, and essential system CLI packages).
- **`configure.nix`**: Convenience wrapper / alias module importing `configuration.nix`.
- **`home.nix`**: User-level Home Manager configuration for `ratul` (Git setup, Zsh, Starship prompt, Bat, Eza, Zoxide, Fzf, and developer CLI tools).
- **`modules/lxc.nix`**: Container optimizations:
  - Disables installer channel bundling to minimize image size (~200MB+ savings).
  - TTY1 getty and console auto-spawning for instant `lxc console` or `pct enter` access.
  - SUID ping wrapper with `cap_net_raw+p` for unprivileged containers.
  - Systemd network & DHCP support for container veth interfaces.
  - Fast boot optimizations disabling blocking `systemd-networkd-wait-online`.

---

## Building the Container Image

To build the standard LXC container tarball:

```bash
nix build
# or explicitly
nix build .#tarball
```

To build specifically for Proxmox VE:

```bash
nix build .#proxmox
```

The output tarball will be located in:
```bash
./result/tarball/nixos-system-x86_64-linux.tar.xz
```

---

## Deploying the Container

### Proxmox VE

1. Upload or copy the tarball to your Proxmox VE host (e.g. to `/var/lib/vz/template/cache/`):
   ```bash
   scp result/tarball/nixos-system-x86_64-linux.tar.xz root@<proxmox-ip>:/var/lib/vz/template/cache/nixos-lxc.tar.xz
   ```
2. Create and start the container:
   ```bash
   pct create 100 /var/lib/vz/template/cache/nixos-lxc.tar.xz \
     --ostype unmanaged \
     --net0 name=eth0,bridge=vmbr0,ip=dhcp \
     --cores 2 \
     --memory 2048 \
     --swap 512 \
     --storage local-lvm \
     --unprivileged 1 \
     --features nesting=1

   pct start 100
   pct enter 100
   ```

### LXC / Incus / LXD

1. Import the rootfs tarball:
   ```bash
   # Standalone LXC
   lxc-create -n nixos-lxc -t local -- --metadata ... --fstree result/tarball/nixos-system-x86_64-linux.tar.xz
   lxc-start -n nixos-lxc
   lxc-attach -n nixos-lxc

   # Or Incus / LXD
   incus image import result/tarball/nixos-system-x86_64-linux.tar.xz --alias nixos-base
   incus launch nixos-base my-nixos-container
   incus exec my-nixos-container -- zsh
   ```

---

## Default Access & Credentials

- **Root User**:
  - Console login: empty initial password (allows direct login from container console / `pct enter`).
  - SSH: key-based authentication recommended (`PermitRootLogin prohibit-password`).
- **Standard User (`ratul`)**:
  - Full passwordless sudo privileges inside container.
  - Pre-configured with Zsh, Starship prompt, and developer tooling via Home Manager.
