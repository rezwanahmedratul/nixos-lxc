# Jenkins SSH Agent on NixOS LXC

A complete guide for setting up and connecting a dedicated **NixOS LXC Jenkins Build Agent** (with **JDK 25** and **Docker**) to a **Jenkins Controller** (running in Docker or on a remote server).

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Obtain or Generate SSH Keys](#step-1-obtain-or-generate-ssh-keys)
4. [Step 2: Configure variables.nix](#step-2-configure-variablesnix)
5. [Step 3: Build & Deploy the NixOS LXC Container](#step-3-build--deploy-the-nixos-lxc-container)
6. [Step 4: Configure Credentials in Jenkins Controller](#step-4-configure-credentials-in-jenkins-controller)
7. [Step 5: Register the Node in Jenkins Controller](#step-5-register-the-node-in-jenkins-controller)
8. [Step 6: Verify with a Test Pipeline](#step-6-verify-with-a-test-pipeline)
9. [Troubleshooting & Gotchas](#troubleshooting--gotchas)

---

## Architecture Overview

```
┌─────────────────────────────────┐                 ┌─────────────────────────────────┐
│       Docker Host Server        │                 │         Proxmox VE / LXC        │
│          (10.0.0.50)            │                 │           (10.0.0.45)           │
│                                 │                 │                                 │
│  ┌───────────────────────────┐  │   SSH Port 22   │  ┌───────────────────────────┐  │
│  │    Jenkins Controller     │──┼─────────────────┼─>│     NixOS LXC Agent       │  │
│  │ (jenkins/jenkins:lts-jdk21)│  │ (User: jenkins) │  │  - User: jenkins (wheel)  │  │
│  └───────────────────────────┘  │                 │  │  - OpenJDK 25             │  │
│                                 │                 │  │  - Docker Engine 29+      │  │
│                                 │                 │  │  - Docker Compose         │  │
└─────────────────────────────────┘                 │  └───────────────────────────┘  │
                                                    └─────────────────────────────────┘
```

- **Jenkins Controller**: Connects to the NixOS agent via SSH using the `jenkins` user.
- **NixOS LXC Agent**:
  - Provisions a dedicated user `jenkins` with passwordless console access and `wheel` / `docker` group membership.
  - Installs **OpenJDK 25** and automatically symlinks `/usr/bin/java`.
  - Enables the Docker daemon so pipelines can build and run Docker containers without `sudo`.
  - Configures OpenSSH with standard MACs and Key Exchange algorithms for Java SSH client compatibility.

---

## Prerequisites

1. **Jenkins Controller** running with the **SSH Build Agents** plugin installed.
   - Go to: **Manage Jenkins** -> **Plugins** -> **Installed plugins** -> search for `SSH Build Agents`.
   - If not installed, find it under **Available plugins** and install it.
2. **Proxmox VE, Incus, or LXD** with container nesting enabled.

---

## Step 1: Obtain or Generate SSH Keys

On your Docker server or workstation, generate an SSH keypair (or use an existing one):

```bash
# Generate an ED25519 SSH keypair
ssh-keygen -t ed25519 -C "docker-server" -f ~/.ssh/id_ed25519
```

- **Public Key** (`~/.ssh/id_ed25519.pub`): Added to `variables.nix` on the NixOS agent.
- **Private Key** (`~/.ssh/id_ed25519`): Added into Jenkins Controller Credentials.

Display your public key:
```bash
cat ~/.ssh/id_ed25519.pub
# Example: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqE6+H7/m6tsCtT9YGWr1S7BY5ztS82YcubMMNXLy3P docker-server
```

---

## Step 2: Configure variables.nix

In the repository root, edit `variables.nix`:

```nix
{
  # Enable Jenkins Agent Mode (mutually exclusive with docker = true)
  jenkins = true;
  docker = false;

  # Container Hostname
  hostName = "nixos-jenkins-agent";

  # Add your controller's public SSH key here:
  jenkinsAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqE6+H7/m6tsCtT9YGWr1S7BY5ztS82YcubMMNXLy3P docker-server"
    # (Optional) Add your personal SSH public key for direct terminal access:
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE2kXjQ5NmBPJUxeLwJkex8Za6L+yLtQy021v4nrg0TV rezwanahmedratul007@gmail.com"
  ];
}
```

---

## Step 3: Build & Deploy the NixOS LXC Container

### 1. Build the Container Image

```bash
# For Proxmox VE:
nix build .#proxmox

# Or for standard LXC / Incus:
nix build .#tarball
```

### 2. Deploy on Proxmox VE

Copy the output tarball to your Proxmox VE host:
```bash
scp result/tarball/nixos-image-lxc-proxmox-*.tar.xz root@<proxmox-ip>:/var/lib/vz/template/cache/nixos-jenkins-agent.tar.xz
```

Create and launch the container on Proxmox:
```bash
pct create 100 /var/lib/vz/template/cache/nixos-jenkins-agent.tar.xz \
  --ostype unmanaged \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --cores 4 \
  --memory 4096 \
  --swap 1024 \
  --storage local-lvm \
  --unprivileged 1 \
  --features nesting=1,keyctl=1

pct start 100
```

> [!IMPORTANT]
> `--features nesting=1,keyctl=1` is **mandatory** for unprivileged LXC containers so that the Docker daemon can run and build images inside.

---

## Step 4: Configure Credentials in Jenkins Controller

1. Open your Jenkins Web UI (`http://<controller-ip>:8080`).
2. Navigate to: **Manage Jenkins** -> **Credentials** -> **System** -> **Global credentials (unrestricted)**.
3. Click **Add Credentials** (top right).
4. Configure:
   - **Kind**: `SSH Username with private key`
   - **ID**: `nixos-jenkins-ssh` *(or leave blank)*
   - **Description**: `NixOS Agent SSH Key`
   - **Username**: `jenkins`
   - **Private Key**: Select **Enter directly**, click **Add**, and paste the full contents of `id_ed25519` (including the `BEGIN` and `END` headers).
   - **Passphrase**: Leave blank (unless protected by a passphrase).
5. Click **Create**.

---

## Step 5: Register the Node in Jenkins Controller

1. In Jenkins Web UI, navigate to: **Manage Jenkins** -> **Nodes** -> **New Node**.
2. Set:
   - **Node name**: `nixos-agent`
   - **Type**: `Permanent Agent`
   - Click **Create**.
3. Configure node settings:
   - **Number of executors**: `2` (or matching your LXC CPU cores)
   - **Remote root directory**: `/home/jenkins`
   - **Labels**: `docker linux nixos`
   - **Usage**: `Use this node as much as possible`
   - **Launch method**: Select **Launch agents via SSH**
     - **Host**: `<IP-of-NixOS-Agent>` (e.g. `10.0.0.45`)
     - **Credentials**: Select the `jenkins (NixOS Agent SSH Key)` credential created in Step 4.
     - **Host Key Verification Strategy**: Select **Non verifying Verification Strategy** (or **Known hosts file Verification Strategy**).
     - Under **Advanced**:
       - **JavaPath**: `/usr/bin/java` (or leave empty; `/usr/bin/java` is symlinked by default).
       - **Port**: `22`
4. Click **Save**.
5. Click on the node and click **Launch agent** (or **Relaunch agent**).
6. Verify the log displays:
   ```
   Checking Java version in PATH...
   Specification-Version: 25
   ...
   Agent successfully connected and online
   ```

---

## Step 6: Verify with a Test Pipeline

Create a new **Pipeline** job in Jenkins and paste this `Jenkinsfile`:

```groovy
pipeline {
    agent { label 'docker' }

    stages {
        stage('Verify Environment') {
            steps {
                sh 'whoami'
                sh 'java -version'
                sh 'docker version'
                sh 'docker compose version'
            }
        }
        stage('Test Docker Build & Run') {
            steps {
                sh '''
                    cat << 'EOF' > Dockerfile
                    FROM alpine:latest
                    RUN echo "Built successfully on NixOS LXC Agent!" > /output.txt
                    CMD cat /output.txt
                    EOF

                    docker build -t test-agent-image .
                    docker run --rm test-agent-image
                '''
            }
        }
    }
}
```

Run the pipeline. Both stages should complete with a green checkmark without requiring any `sudo` passwords.

---

## Troubleshooting & Gotchas

### 1. "Key exchange was not finished, connection is closed" / "no matching MAC found"
- **Cause**: Modern OpenSSH (10.x / 9.x) in NixOS only enables modern Encrypt-then-MAC (`*-etm@openssh.com`) algorithms by default. Jenkins' Java SSH client (Trilead-SSH2) offers standard non-ETM MACs (`hmac-sha2-512`, `hmac-sha2-256`).
- **Solution**: Handled automatically in [modules/core/system.nix](file:///home/ratul/Github/nixos-lxc/modules/core/system.nix):
  ```nix
  services.openssh.settings.Macs = [
    "hmac-sha2-512-etm@openssh.com"
    "hmac-sha2-256-etm@openssh.com"
    "umac-128-etm@openssh.com"
    "hmac-sha2-512"
    "hmac-sha2-256"
    "hmac-sha1"
  ];
  ```

### 2. "KnownHostsFileKeyVerificationStrategy" Failure
- **Cause**: The host key of the new NixOS LXC agent is not yet in the Jenkins container's `known_hosts`.
- **Solution**: In node settings, set **Host Key Verification Strategy** to **Non verifying Verification Strategy**, or scan the key into the controller:
  ```bash
  docker exec -u jenkins <jenkins-container> ssh-keyscan -H <agent-ip> >> /var/jenkins_home/.ssh/known_hosts
  ```

### 3. Docker Permission Denied inside Agent
- The `jenkins` user is automatically added to the `docker` and `wheel` groups in [modules/core/jenkins.nix](file:///home/ratul/Github/nixos-lxc/modules/core/jenkins.nix).
- If building Docker images fails on the host, ensure the Proxmox container has `--features nesting=1,keyctl=1`.

### 4. Console Login Without Password
- Both `root` and `jenkins` have `initialHashedPassword = ""`.
- You can log in directly via the Proxmox Web Console (noVNC / xterm.js) by typing `root` or `jenkins` and pressing **Enter** (blank password).

