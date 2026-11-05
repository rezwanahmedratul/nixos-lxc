# NixOS LXC Container Image

A modular, reproducible Flake configuration for building lightweight NixOS LXC / Proxmox VE / Incus container images with Home Manager integration.

Supports configurable modes via `variables.nix`:
- **Jenkins SSH Build Agent** (JDK 21, Docker daemon to build images, dedicated `jenkins` user, controller SSH access).
- **Standalone Docker** (Docker daemon & Docker Compose, primary user `ratul` with docker permissions).
- **Bare Metal** (Minimal NixOS LXC container with user `ratul`).

---

## Configuration Variables (`variables.nix`)

Edit `variables.nix` in the repository root to select your target container configuration:

```nix
{
  # Mode Selection:
  # 1. Jenkins SSH Agent:  jenkins = true;  docker = false;
  # 2. Standalone Docker:  jenkins = false; docker = true;  (overrides jenkins if both true)
  # 3. Bare Metal LXC:     jenkins = false; docker = false;
  jenkins = true;
  docker = false;

  # Container Hostname
  hostName = "nixos-jenkins-agent";

  # Primary User (used when jenkins = false)
  username = "ratul";

  # SSH Authorized Keys for user 'ratul' and root
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2kXjQ5NmBPJUxeLwJkex8Za6L+yLtQy021v4nrg0TV rezwanahmedratul007@gmail.com"
  ];

  # SSH Authorized Keys for user 'jenkins' (Jenkins Controller SSH public key)
  jenkinsAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2kXjQ5NmBPJUxeLwJkex8Za6L+yLtQy021v4nrg0TV rezwanahmedratul007@gmail.com"
  ];
}
```

### Container Mode Behaviors

| Feature / Mode | Jenkins Agent (`jenkins = true`) | Standalone Docker (`docker = true`) | Bare Metal (`both false`) |
| :--- | :--- | :--- | :--- |
| **User `jenkins`** | Yes (in `docker` & `wheel` groups) | No | No |
| **User `ratul`** | **Disabled** (no home-manager profile) | Enabled (`docker` & `wheel`) | Enabled (`wheel`) |
| **JDK 21 (`jdk21`)** | Installed & set to `JAVA_HOME` + `/usr/bin/java` | Not installed | Not installed |
| **Docker Daemon** | Enabled (`virtualisation.docker`) | Enabled (`virtualisation.docker`) | Disabled |
| **Docker Compose** | Installed | Installed | Not installed |
| **SSH Daemon** | Enabled on boot | Enabled on boot | Enabled on boot |
| **Modules Imported** | `modules/core/jenkins.nix` | `modules/core/docker.nix` | `modules/core/default.nix` only |

---

## Architecture Overview

- **`variables.nix`**: Single source of truth for mode toggles, users, hostnames, and SSH authorized keys.
- **`modules/core/`**: Core system configuration and service modules:
  - **`default.nix`**: Aggregates all core modules (`system.nix`, `user.nix`, `packages.nix`, `lxc.nix`, and conditional feature modules).
  - **`system.nix`**: System settings (hostname, timezone, locale, sudo, openssh, nix flakes enablement, stateVersion).
  - **`user.nix`**: User accounts and Home Manager integration (`imports = [ ./../home ]`).
  - **`packages.nix`**: System-wide packages (`curl`, `git`, `vim`).
  - **`jenkins.nix`**: Configures Jenkins SSH build agent (JDK 21, Docker daemon to build images, `jenkins` user in `docker` group, SSH setup).
  - **`docker.nix`**: Enables standalone Docker daemon with weekly auto-pruning and installs `docker-compose`.
  - **`lxc.nix`**: LXC container optimizations (fast network boot, tty autologin, unprivileged ping support).
- **`modules/home/`**: Home Manager user configuration modules:
  - **`default.nix`**: User home profile entrypoint, importing `git.nix` and `shell.nix`.
  - **`git.nix`**: User git identity, default branch, and options.
  - **`shell.nix`**: Zsh and Bash configurations, syntax highlighting, autosuggestions, and shared aliases.
- **`flake.nix`**: Flake inputs and outputs, exposing configurations (`nixos-lxc`, `proxmox-lxc`) and buildable packages (`tarball`, `proxmox`). Imports `./modules/core` directly.

---

## Setting Up the Jenkins Agent

When `jenkins = true`:

1. **Add your Jenkins Controller's Public Key**:
   Add the public key from your Docker Jenkins controller (e.g., `id_rsa.pub` or `id_ed25519.pub`) to `jenkinsAuthorizedKeys` in `variables.nix`.
2. **Build and Deploy the LXC**:
   Build the image with `nix build` (or `nix build .#proxmox`) and deploy it to your hypervisor (Proxmox / Incus / LXC).
   > **Note for LXC / Proxmox**: Make sure `nesting=1` (and `keyctl=1`) is enabled on the LXC so Docker can run inside the container:
   > ```bash
   > pct set <vmid> --features nesting=1,keyctl=1
   > ```
3. **Configure the Node in Jenkins Controller**:
   - Go to: **Manage Jenkins** -> **Nodes** -> **New Node**
   - **Node Name**: e.g., `nixos-agent`
   - **Type**: Permanent Agent
   - **Remote root directory**: `/home/jenkins`
   - **Labels**: `docker linux nixos`
   - **Launch method**: **Launch agents via SSH**
     - **Host**: `<IP-of-nixos-lxc>`
     - **Credentials**: SSH Username with private key:
       - **Username**: `jenkins`
       - **Private Key**: Paste private key corresponding to `jenkinsAuthorizedKeys`
     - **Host Key Verification Strategy**: *Non verifying Verification Strategy* (or *Known hosts file*)
     - **JavaPath**: `/usr/bin/java` (or leave empty, detected automatically)

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

1. Upload or copy the tarball to your Proxmox VE host:
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
     --features nesting=1,keyctl=1

   pct start 100
   pct enter 100
   ```

### LXC / Incus / LXD

1. Import the rootfs tarball:
   ```bash
   # Incus / LXD
   incus image import result/tarball/nixos-system-x86_64-linux.tar.xz --alias nixos-base
   incus launch nixos-base my-nixos-container -c security.nesting=true
   incus exec my-nixos-container -- bash
   ```
