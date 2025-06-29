<!--
EL AtomicOS 10 Installation and User Manual

Copyright (c) 2025-Present, Ross W.D. Cameron <rwd.cameron@prometheus-systems.co.za>
Copyright (c) 2025-Present, Prometheus Systems <https://prometheus-systems.co.za/>

This documentation is part of EL AtomicOS 10 and is licensed under the GNU General Public License v2.
See the LICENSE file for details.
-->
# EL AtomicOS 10 Installation and User Manual

**Enterprise Linux Atomic Operating System**  
*Container-optimized, immutable OS for RHEL 10 and compatible distributions*

## Table of Contents
- [Overview](#overview)
- [Compatibility Matrix](#compatibility-matrix)
- [Prerequisites](#prerequisites)
- [Kickstart Installation Guide](#kickstart-installation-guide)
- [First Boot and Initial Setup](#first-boot-and-initial-setup)
- [System Architecture](#system-architecture)
- [Container Management](#container-management)
- [System Updates and Maintenance](#system-updates-and-maintenance)
- [Web Management Interface](#web-management-interface)
- [Security Configuration](#security-configuration)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

## Overview

EL AtomicOS 10 is an immutable, container-focused operating system built on Enterprise Linux 10 foundations. It provides a secure, scalable platform optimized for modern containerized workloads while maintaining compatibility across the RHEL 10 ecosystem.

### Key Features

- **Immutable Base System**: Core OS is read-only with atomic updates
- **Container-First Design**: Optimized for Podman, Docker, and Kubernetes workloads with toolbox support
- **Enterprise Linux Compatibility**: Works with RHEL 10 and all compatible distributions
- **Web-Based Management**: Cockpit integration with Podman module for easy administration
- **Enhanced Security**: SELinux enforcing, fail2ban, auditd, minimal attack surface
- **Atomic Updates**: System updates via rpm-ostree with rollback capability
- **Cloud and Edge Ready**: Optimized for modern deployment scenarios

## Compatibility Matrix

EL AtomicOS 10 is compatible with the following Enterprise Linux 10 distributions:

| Distribution | Version | Status | Notes |
|--------------|---------|--------|-------|
| RHEL | 10.x | ✅ Supported | Primary target platform |
| AlmaLinux | 10.x | ✅ Supported | Full compatibility |
| Rocky Linux | 10.x | ✅ Supported | Full compatibility |
| CentOS Stream | 10 | ✅ Supported | Development/testing |
| Oracle Linux | 10.x | ✅ Supported | UEK kernel supported |
| Scientific Linux | 10.x | 🟡 Community | Limited testing |

## Prerequisites

### Hardware Requirements

**Minimum:**
- CPU: 2 cores (x86_64 or aarch64)
- RAM: 4 GB
- Storage: 30 GB (due to OSTree overhead and container storage)
- Network: Ethernet or WiFi

**Recommended:**
- CPU: 4+ cores
- RAM: 8+ GB
- Storage: 50+ GB SSD
- Network: Gigabit Ethernet

### Network Requirements

- Internet access for OSTree repository and package downloads
- DNS resolution
- NTP access for time synchronization (chronyd service)
- Container registry access (optional, for pulling container images)
- Access to Fedora OSTree repository (https://ostree.fedoraproject.org/atomic/)

## Kickstart Installation Guide

### 1. Prepare Installation Media

Download the EL AtomicOS 10 kickstart file:
```bash
curl -O https://raw.githubusercontent.com/prometheus-systems-tech/EL-AtomicOS/main/EL_AtomicOS_10_kickstart.ks
```

### 2. Boot Installation

**For Network Installation:**
```bash
# At boot prompt, add kickstart parameter
linux inst.ks=http://your-server/EL_AtomicOS_10_kickstart.ks
```

**For Local Installation:**
```bash
# Copy kickstart to USB/CD and reference it
linux inst.ks=hd:sdb1:/EL_AtomicOS_10_kickstart.ks
```

### 3. Customize Installation

Edit the kickstart file before installation to match your environment:

**Important Security Note:** The default kickstart uses plaintext passwords for demonstration. **Always change these for production use.**

```bash
# Change hostname
network --hostname=your-hostname

# Update user credentials (CRITICAL - change default password)
# Generate secure password with: openssl passwd -6 "your-secure-password"
user --name=atomic --password=$6$rounds=4096$saltsalt$your_generated_hash --iscrypted --gecos="EL AtomicOS Admin" --groups=wheel,docker

# Modify partitioning if needed
logvol / --size=50240  # Increase root partition
logvol /var --size=20480  # Increase for container storage

# OSTree configuration (update if using custom repository)
ostreesetup --osname=el-atomicos --remote=fedora --url=https://ostree.fedoraproject.org/atomic/ --ref=fedora/40/x86_64/atomic-host --nogpg
```

### 4. Installation Process

The kickstart installation will:
1. Partition disks with LVM (20GB root, 10GB /var, 5GB /home, 2GB /tmp, 4GB swap)
2. Install core packages (@core, @standard, @hardware-support)
3. Set up OSTree with Fedora Atomic Host repository
4. Configure container runtimes (Podman, Docker, containerd) and Kubernetes
5. Enable services (Cockpit, NetworkManager, SSH, systemd-resolved, etc.)
6. Apply security settings (SELinux enforcing, fail2ban, auditd)
7. Create atomic user with sudo privileges
8. Set system to multi-user target (no GUI)
9. Reboot automatically

**Installation time:** 20-45 minutes depending on hardware and network speed

**Note:** The system uses Fedora 40 Atomic Host OSTree repository as the base. This provides OSTree functionality while maintaining RHEL compatibility through standard package installations.

## First Boot and Initial Setup

### 1. Initial Login

**Default Credentials (CHANGE IMMEDIATELY):**
- Username: `atomic`
- Password: `atomic` (as configured in kickstart)

```bash
# SSH access (preferred - enabled by default)
ssh atomic@el-atomicos  # or your configured hostname

# Console login
Username: atomic
Password: atomic
```

**Security Warning:** The default password is insecure. Change it immediately after first login:
```bash
sudo passwd atomic
```

### 2. System Verification

```bash
# Check OSTree deployment status
rpm-ostree status

# Verify container runtime versions
podman version
docker version
crun --version

# Check enabled services
systemctl status cockpit.socket
systemctl status podman.socket
systemctl status docker
systemctl status containerd
systemctl status kubelet
systemctl status sshd
systemctl status NetworkManager
systemctl status chronyd
systemctl status systemd-resolved

# Verify security services
systemctl status fail2ban
systemctl status auditd

# Check user privileges
sudo whoami  # Should work without password prompt (NOPASSWD configured)

# Verify firewall status
sudo firewall-cmd --list-all
```

### 3. Network Configuration

```bash
# Check network status
nmcli device status

# Configure static IP (if needed)
nmcli con modify "System eth0" ipv4.addresses 192.168.1.100/24
nmcli con modify "System eth0" ipv4.gateway 192.168.1.1
nmcli con modify "System eth0" ipv4.dns 8.8.8.8
nmcli con modify "System eth0" ipv4.method manual
nmcli con up "System eth0"
```

### 4. Access Web Interface

Open browser to: `https://el-atomicos:9090` (or your configured hostname)
- Login with `atomic` user credentials
- Accept self-signed certificate warning
- Available modules:
  - **Overview**: System status and performance
  - **Podman**: Container management (via cockpit-podman)
  - **Docker**: Docker container management (via cockpit-docker)
  - **Services**: Systemd service control
  - **Terminal**: Web-based console
  - **Networking**: Network configuration
  - **Storage**: Disk and filesystem management

**Note:** Cockpit listens on all interfaces and is accessible via HTTPS only. The firewall allows access on port 9090.

## System Architecture

### Filesystem Layout

```
/                   # Immutable root filesystem (remounted read-only)
├── /boot           # Boot partition (ext4, 1024MB, mutable)
├── /boot/efi       # EFI partition (512MB, mutable)
├── /var            # Variable data (XFS, 10GB, mutable)
│   ├── /var/lib/containers  # Container storage
│   └── /var/log    # System logs (journald persistent)
├── /home           # User data (XFS, 5GB, mutable)
├── /tmp            # Temporary files (XFS, 2GB, mutable)
├── /etc            # Configuration overlay (mutable)
├── /usr/share/doc/atomicos  # EL AtomicOS documentation
└── swap            # Swap space (4GB)
```

**Storage Details:**
- Root filesystem uses OSTree for immutable base system
- Container storage in /var/lib/containers with journald logging
- Journal storage: max 1GB system, 100MB runtime, 1-month retention
- All filesystems use XFS except /boot (ext4) and /boot/efi

### Service Architecture

```
┌─────────────────────────────────────────┐
│            User Applications            │
├─────────────────────────────────────────┤
│              Containers                 │
│   (Podman, Docker, Kubernetes)         │
├─────────────────────────────────────────┤
│            Container Runtime            │
│  (crun, runc, containerd, CRI-O)       │
├─────────────────────────────────────────┤
│          EL AtomicOS Services           │
│   (Cockpit, rpm-ostree, fail2ban)      │
├─────────────────────────────────────────┤
│         Enterprise Linux Base           │
│    (OSTree + Standard EL packages)     │
└─────────────────────────────────────────┘
```

**Enabled Services:**
- NetworkManager (networking)
- sshd (SSH access)
- cockpit.socket (web management)
- podman.socket (Podman API)
- docker (Docker daemon)
- containerd (container runtime)
- kubelet (Kubernetes node agent)
- chronyd (time synchronization)
- systemd-resolved (DNS resolution)
- rpm-ostreed (system updates)
- fail2ban (intrusion prevention)
- auditd (security auditing)
- podman-auto-update.timer (container updates)

## Container Management

EL AtomicOS 10 supports multiple container runtimes and orchestration platforms:

### Basic Podman Operations

```bash
# Pull an image from a registry
podman pull docker.io/library/httpd:latest

# Run a container with port mapping
podman run -d --name web -p 8080:80 docker.io/library/httpd:latest

# List running containers
podman ps

# List all containers (including stopped)
podman ps -a

# View container logs
podman logs web

# Execute command in running container
podman exec -it web /bin/bash

# Stop and remove container
podman stop web
podman rm web

# Remove unused images
podman image prune
```

**Container Configuration:**
- Podman runtime: crun (with runc as fallback)
- Docker runtime: containerd
- Kubernetes runtime: containerd via CRI
- Logging: journald (configured in /etc/containers/containers.conf and /etc/docker/daemon.json)
- Network: netavark (Podman), bridge (Docker)
- Storage: /var/lib/containers (Podman), /var/lib/docker (Docker)
- Process limit: 2048 per container

### Basic Docker Operations

```bash
# Pull an image from a registry
docker pull httpd:latest

# Run a container with port mapping
docker run -d --name web -p 8080:80 httpd:latest

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs web

# Execute command in running container
docker exec -it web /bin/bash

# Stop and remove container
docker stop web
docker rm web

# Remove unused images
docker image prune
```

### Basic Kubernetes Operations

```bash
# Check cluster status
kubectl cluster-info

# Get nodes
kubectl get nodes

# Get all pods in all namespaces
kubectl get pods --all-namespaces

# Create a deployment
kubectl create deployment nginx --image=nginx

# Expose a deployment as a service
kubectl expose deployment nginx --port=80 --type=NodePort

# Scale a deployment
kubectl scale deployment nginx --replicas=3

# Get services
kubectl get services

# View logs from a pod
kubectl logs <pod-name>

# Execute command in a pod
kubectl exec -it <pod-name> -- /bin/bash

# Delete a deployment
kubectl delete deployment nginx
```

**Kubernetes Configuration:**
- Container runtime: containerd
- Network plugin: Ready for CNI installation
- kubelet service: Enabled and configured
- Required ports: 6443, 10250, 10251, 10252, 2379-2380 (opened in firewall)
- Configuration: /etc/kubernetes/

**Note:** Kubernetes cluster initialization requires additional setup after installation.

### Container as Services

**For Podman:**
```bash
# Generate systemd unit file
podman generate systemd --new --files --name web

# Move to system location
sudo mv container-web.service /etc/systemd/system/

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now container-web.service
```

**For Docker:**
```bash
# Create systemd service file for Docker container
cat > /etc/systemd/system/docker-web.service << 'EOF'
[Unit]
Description=Web Container
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --rm --name web -p 8080:80 httpd:latest
ExecStop=/usr/bin/docker stop web

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now docker-web.service
```

### Container Auto-Updates

The system includes automatic update capabilities for containers:

**Podman Auto-Updates:**
```bash
# Check auto-update status
systemctl status podman-auto-update.timer

# Enable auto-update for a container (label required)
podman run -d --label "io.containers.autoupdate=registry" --name web nginx

# Manually trigger auto-update
podman auto-update

# View auto-update logs
journalctl -u podman-auto-update.service
```

**Docker Auto-Updates:**
```bash
# Using Watchtower for Docker auto-updates
docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower

# Check Watchtower status
docker logs watchtower
```

## System Updates and Maintenance

### Checking for Updates

```bash
# Check current OSTree deployment status
rpm-ostree status

# Check for available updates from remote
rpm-ostree upgrade --check

# Preview what updates are available
rpm-ostree upgrade --preview

# View update configuration
cat /etc/atomicos/update.conf
```

**Update Configuration (in /etc/atomicos/update.conf):**
- AUTO_UPDATE_ENABLED=false (disabled by default)
- UPDATE_SCHEDULE="weekly"
- REBOOT_STRATEGY="off"
- UPDATE_GROUP="stable"

### Applying Updates

```bash
# Download and stage updates
sudo rpm-ostree upgrade

# Reboot to apply updates
sudo systemctl reboot

# Verify update after reboot
rpm-ostree status
```

### Rollback Support

```bash
# View deployment history
rpm-ostree status

# Rollback to previous deployment
sudo rpm-ostree rollback

# Reboot to activate rollback
sudo systemctl reboot
```

### Package Management

```bash
# Install additional packages (creates new deployment)
sudo rpm-ostree install htop tree

# Remove packages (creates new deployment)
sudo rpm-ostree uninstall htop tree

# Search for packages in repositories
rpm-ostree search package-name

# Install from local RPM file
sudo rpm-ostree install ./package.rpm

# Reset to clean state (remove all layered packages)
sudo rpm-ostree reset

# View layered packages
rpm-ostree status --verbose
```

**Note:** Package changes require a reboot to take effect, as they create a new OSTree deployment.

## Web Management Interface

### Accessing Cockpit

1. Open browser: `https://hostname:9090`
2. Login with `atomic` user (default password: `atomic`)
3. Accept self-signed certificate warning
4. Available modules installed by default:
   - **Overview**: System status, CPU, memory, disk usage
   - **Podman**: Container management via cockpit-podman module
   - **Docker**: Docker container management via cockpit-docker module
   - **Services**: Systemd service control and status
   - **Terminal**: Web-based console access
   - **Networking**: Network interface configuration
   - **Storage**: Disk and filesystem management
   - **Accounts**: User account management

**Security Notes:**
- Cockpit uses HTTPS only (self-signed certificate by default)
- Firewall allows access on port 9090 from all interfaces
- Container ports 2376/tcp, 8080/tcp opened by default
- Kubernetes ports 6443/tcp, 10250-10252/tcp, 2379-2380/tcp opened by default

### Container Management via Web

The cockpit-podman and cockpit-docker modules provide comprehensive container management:

**Podman Module:**
- **Images**: View, pull, and manage container images
- **Containers**: View running/stopped containers with status
- **Start/Stop/Restart**: Container lifecycle management
- **Logs**: Real-time and historical container logs
- **Console**: Direct terminal access to containers
- **Resource Monitoring**: CPU, memory, and network usage per container
- **Port Management**: View and manage exposed ports
- **Volume Management**: Container volume and bind mount management

**Docker Module:**
- **Images**: Docker image management and registry operations
- **Containers**: Docker container lifecycle and status monitoring
- **Networks**: Docker network configuration and management
- **Volumes**: Docker volume management
- **System**: Docker system information and cleanup

**Direct Integration**: All operations sync with command-line podman and docker usage

## Security Configuration

### SELinux Management

```bash
# Check SELinux status
getenforce

# View SELinux denials
sudo ausearch -m AVC -ts recent

# Generate custom policies (if needed)
sudo audit2allow -M mycustom -l
sudo semodule -i mycustom.pp
```

### Firewall Configuration

The system uses firewalld with preconfigured rules:

```bash
# Check firewall status
sudo firewall-cmd --state

# List all active rules
sudo firewall-cmd --list-all

# View enabled services (SSH and Cockpit enabled by default)
sudo firewall-cmd --list-services

# View open ports (2376/tcp, 8080/tcp, and Kubernetes ports opened by default)
sudo firewall-cmd --list-ports

# Add services permanently
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload

# Add custom ports for containers
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload

# Remove rules
sudo firewall-cmd --remove-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

**Default Configuration:**
- SSH (port 22): Enabled
- Cockpit (port 9090): Enabled  
- Container ports 2376/tcp and 8080/tcp: Enabled
- Kubernetes API (port 6443): Enabled
- Kubernetes kubelet (port 10250): Enabled
- Kubernetes controller manager (port 10252): Enabled
- Kubernetes scheduler (port 10251): Enabled
- etcd (ports 2379-2380): Enabled
- All other traffic: Blocked by default

### User Management

The system creates one default user with specific privileges:

```bash
# Default user configuration
# Username: atomic
# Groups: wheel, docker
# Sudo: NOPASSWD:ALL (configured in /etc/sudoers.d/atomicos)

# Add additional users
sudo useradd -G wheel newuser
sudo passwd newuser

# Add user to docker group for container access
sudo usermod -aG docker newuser

# Configure sudo access (edit sudoers safely)
sudo visudo

# Lock/unlock accounts
sudo usermod -L username
sudo usermod -U username

# View user groups
groups atomic
```

**Security Considerations:**
- Default `atomic` user has passwordless sudo (for administrative convenience)
- Docker group membership allows container management without sudo
- Consider creating additional users with limited privileges for production use

## Troubleshooting

### Common Issues

**Container Won't Start:**
```bash
# Check Podman container logs
podman logs container-name

# Check Docker container logs
docker logs container-name

# Check SELinux context
ls -Z /path/to/container/data

# Fix SELinux context if needed
sudo restorecon -R /path/to/container/data

# Check container runtime status
systemctl status podman.socket
systemctl status docker
systemctl status containerd
```

**Network Issues:**
```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check container networking
podman network ls
podman network inspect podman

# Check Docker networking
docker network ls
docker network inspect bridge

# Check Kubernetes networking (if cluster is initialized)
kubectl get nodes
kubectl get pods --all-namespaces
```

**System Won't Boot After Update:**
```bash
# At boot menu, select previous deployment
# Or from rescue mode:
rpm-ostree rollback
reboot
```

### Log Locations

**System Logs (journald with persistent storage):**
```bash
# View all system logs
journalctl

# Service-specific logs
journalctl -u cockpit.socket
journalctl -u podman.socket  
journalctl -u docker
journalctl -u containerd
journalctl -u kubelet
journalctl -u sshd
journalctl -u NetworkManager
journalctl -u fail2ban

# Container logs
podman logs container-name
docker logs container-name

# Follow logs in real-time
journalctl -f
podman logs -f container-name
docker logs -f container-name
```

**Important Log Files:**
- Installation log: `/var/log/atomicos-kickstart.log`
- System messages: `journalctl` (persistent, 1GB max, 1-month retention)
- Security/audit logs: `/var/log/audit/audit.log`
- Fail2ban logs: `journalctl -u fail2ban`

**Log Configuration:**
- Journal storage: Persistent in /var/log/journal
- System max use: 1GB
- Runtime max use: 100MB  
- Max retention: 1 month
- Container logs: Via journald driver

### Support Resources

- **GitHub Repository**: `https://github.com/prometheus-systems-tech/EL-AtomicOS`
- **Issues and Bug Reports**: `https://github.com/prometheus-systems-tech/EL-AtomicOS/issues`
- **Documentation Wiki**: `https://github.com/prometheus-systems-tech/EL-AtomicOS/wiki`
- **System Documentation**: `/usr/share/doc/atomicos/README` (local)
- **Enterprise Linux Community**: Distribution-specific forums and communities
- **Upstream OSTree**: `https://ostreedev.github.io/ostree/`
- **Podman Documentation**: `https://docs.podman.io/`
- **Docker Documentation**: `https://docs.docker.com/`
- **Kubernetes Documentation**: `https://kubernetes.io/docs/`
- **Cockpit Documentation**: `https://cockpit-project.org/documentation.html`

**For Enterprise Support:**
Contact your Enterprise Linux distribution vendor (Red Hat, AlmaLinux, Rocky Linux, etc.) for commercial support options.

## Advanced Configuration

### Custom Container Registries

Configure additional registries by editing the containers configuration:

```bash
# Edit registries configuration
sudo vi /etc/containers/registries.conf

# Add private registry (example)
[[registry]]
location = "registry.company.com"
insecure = false

# Configure insecure registry (testing only)
[[registry]]
location = "localhost:5000"  
insecure = true

# Test registry access
podman login registry.company.com
podman pull registry.company.com/app:latest
```

**Default Registry Configuration:**
- Podman registry policy: `insecureAcceptAnything` (configured in /etc/containers/policy.json)
- Docker registry: Uses Docker Hub by default
- Both allow pulling from any registry without signature verification
- For production, configure proper signature verification policies

### Kubernetes Cluster Setup

```bash
# Initialize Kubernetes cluster (on master node)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Set up kubectl for regular user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install a pod network (Flannel example)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Join worker nodes (run on worker nodes)
# Use the kubeadm join command output from the init step

# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces
```

**Note:** Kubernetes cluster setup requires additional configuration beyond the base installation.

### Automated Deployments

**Podman Deployment Script:**
```bash
# Create deployment script
cat > /opt/atomicos/bin/deploy-podman.sh << 'EOF'
#!/bin/bash
podman pull registry.company.com/app:latest
podman stop app || true
podman rm app || true
podman run -d --name app -p 8080:8080 registry.company.com/app:latest
EOF
```

**Docker Deployment Script:**
```bash
# Create Docker deployment script
cat > /opt/atomicos/bin/deploy-docker.sh << 'EOF'
#!/bin/bash
docker pull registry.company.com/app:latest
docker stop app || true
docker rm app || true
docker run -d --name app -p 8080:8080 registry.company.com/app:latest
EOF
```

**Kubernetes Deployment:**
```bash
# Create Kubernetes deployment YAML
cat > /opt/atomicos/manifests/app-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: registry.company.com/app:latest
        ports:
        - containerPort: 8080
EOF

# Apply deployment
kubectl apply -f /opt/atomicos/manifests/app-deployment.yaml
```

### Performance Tuning

```bash
# Container-specific optimizations
# Increase memory map count for containers like Elasticsearch
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Apply sysctl changes
sudo sysctl -p

# Configure container storage optimization
sudo vi /etc/containers/storage.conf

# Example storage.conf optimizations:
# [storage]
# driver = "overlay"
# [storage.options.overlay]
# mount_program = "/usr/bin/fuse-overlayfs"

# Optimize systemd journal for container workloads
sudo vi /etc/systemd/journald.conf.d/atomicos.conf
# (Already configured: 1GB system, 100MB runtime, 1-month retention)

# Check current container storage usage
podman system df
docker system df

# Clean up unused resources
podman system prune -a
docker system prune -a

# Clean up unused Kubernetes resources
kubectl delete pods --field-selector=status.phase==Succeeded
kubectl delete pods --field-selector=status.phase==Failed
```

**System Tuning Notes:**
- Journal settings optimized for container logging
- Container pids_limit set to 2048 in /etc/containers/containers.conf
- Docker daemon configured with systemd cgroup driver
- crun used as primary runtime for Podman (better performance)
- containerd used for Docker and Kubernetes
- systemd cgroup manager configured for better integration
- Kubernetes-ready with kubelet service enabled

---

**EL AtomicOS 10** - Enterprise Linux Atomic Operating System  
Compatible with RHEL 10, AlmaLinux 10, Rocky Linux 10, CentOS Stream 10, Oracle Linux 10, and other Enterprise Linux 10 derivatives

**Key Technologies:**
- OSTree for immutable system management
- Podman for rootless container orchestration
- Docker for traditional container workflows  
- Kubernetes for container orchestration at scale
- Cockpit for web-based administration
- rpm-ostree for atomic system updates

For the latest documentation and updates, visit:  
`https://github.com/prometheus-systems-tech/EL-AtomicOS`
