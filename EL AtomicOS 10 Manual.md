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
- **Container-First Design**: Optimized for Podman/Docker workloads
- **Enterprise Linux Compatibility**: Works with RHEL 10 and clones
- **Web-Based Management**: Cockpit integration for easy administration
- **Enhanced Security**: SELinux enforcing, minimal attack surface
- **Atomic Updates**: Zero-downtime system updates via rpm-ostree
- **Cloud & Edge Ready**: Optimized for modern deployment scenarios

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
- Storage: 20 GB
- Network: Ethernet or WiFi

**Recommended:**
- CPU: 4+ cores
- RAM: 8+ GB
- Storage: 50+ GB SSD
- Network: Gigabit Ethernet

### Network Requirements

- Internet access for package downloads
- DNS resolution
- NTP access for time synchronization
- Optional: Container registry access

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
linux ks=http://your-server/EL_AtomicOS_10_kickstart.ks
```

**For Local Installation:**
```bash
# Copy kickstart to USB/CD and reference it
linux ks=hd:sdb1:/EL_AtomicOS_10_kickstart.ks
```

### 3. Customize Installation

Edit the kickstart file before installation:

```bash
# Change hostname
network --hostname=your-hostname

# Update passwords (generate with openssl passwd -6)
rootpw --iscrypted $6$your_encrypted_password
user --password=$6$your_encrypted_password

# Modify partitioning if needed
logvol / --size=50240  # Increase root partition
```

### 4. Installation Process

The installation will:
1. Partition disks with LVM
2. Install minimal package set
3. Configure services
4. Set up container runtime
5. Apply security settings
6. Reboot automatically

**Installation time:** 15-30 minutes depending on hardware and network

## First Boot and Initial Setup

### 1. Initial Login

```bash
# SSH access (preferred)
ssh atomicos@your-hostname

# Console login
Username: atomicos
Password: [your-configured-password]
```

### 2. System Verification

```bash
# Check system status
rpm-ostree status

# Verify container runtime
podman version

# Check services
systemctl status cockpit.socket
systemctl status podman.socket
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

Open browser to: `https://your-hostname:9090`
- Login with `atomicos` user credentials
- Accept self-signed certificate
- Explore system overview and container management

## System Architecture

### Filesystem Layout

```
/                   # Immutable root filesystem
├── /boot           # Boot partition (mutable)
├── /var            # Variable data (mutable)
├── /home           # User data (mutable)
├── /tmp            # Temporary files (mutable)
├── /etc            # Configuration (mutable overlay)
└── /opt/atomicos   # EL AtomicOS specific files
```

### Service Architecture

```
┌─────────────────────────────────────────┐
│            User Applications            │
├─────────────────────────────────────────┤
│              Containers                 │
│        (Podman/Docker/Buildah)          │
├─────────────────────────────────────────┤
│            Container Runtime            │
│             (crun/runc)                 │
├─────────────────────────────────────────┤
│          EL AtomicOS Services           │
│       (Cockpit, rpm-ostree)             │
├─────────────────────────────────────────┤
│         Enterprise Linux 10             │
│             (Kernel/Base)               │
└─────────────────────────────────────────┘
```

## Container Management

### Basic Podman Operations

```bash
# Pull an image
podman pull registry.redhat.io/rhel9/httpd-24

# Run a container
podman run -d --name web -p 8080:8080 registry.redhat.io/rhel9/httpd-24

# List containers
podman ps -a

# View logs
podman logs web

# Stop and remove
podman stop web
podman rm web
```

### Container as Services

```bash
# Generate systemd unit file
podman generate systemd --new --files --name web

# Move to system location
sudo mv container-web.service /etc/systemd/system/

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable --now container-web.service
```

### Container Auto-Updates

```bash
# Enable auto-update for containers
podman auto-update

# Check auto-update status
systemctl status podman-auto-update.timer

# Configure auto-update schedule
sudo systemctl edit podman-auto-update.timer
```

## System Updates and Maintenance

### Checking for Updates

```bash
# Check current status
rpm-ostree status

# Check for available updates
rpm-ostree upgrade --check

# Preview updates
rpm-ostree upgrade --preview
```

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

# Remove packages
sudo rpm-ostree uninstall htop tree

# Search for packages
rpm-ostree search package-name
```

## Web Management Interface

### Accessing Cockpit

1. Open browser: `https://hostname:9090`
2. Login with `atomicos` user
3. Navigate available modules:
   - **Overview**: System status and performance
   - **Containers**: Podman container management
   - **Services**: Systemd service control
   - **Terminal**: Web-based console
   - **Networking**: Network configuration
   - **Storage**: Disk and filesystem management

### Container Management via Web

- View running containers
- Start/stop/restart containers
- View container logs
- Access container console
- Monitor resource usage
- Pull new images
- Create containers from images

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

```bash
# Check firewall status
sudo firewall-cmd --state

# List active zones and services
sudo firewall-cmd --list-all

# Add services
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload

# Add ports for containers
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

### User Management

```bash
# Add users
sudo useradd -G wheel newuser
sudo passwd newuser

# Configure sudo access
sudo visudo

# Lock/unlock accounts
sudo usermod -L username
sudo usermod -U username
```

## Troubleshooting

### Common Issues

**Container Won't Start:**
```bash
# Check container logs
podman logs container-name

# Check SELinux context
ls -Z /path/to/container/data

# Fix SELinux context if needed
sudo restorecon -R /path/to/container/data
```

**Network Issues:**
```bash
# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check container networking
podman network ls
podman network inspect podman
```

**System Won't Boot After Update:**
```bash
# At boot menu, select previous deployment
# Or from rescue mode:
rpm-ostree rollback
reboot
```

### Log Locations

- System logs: `journalctl -u servicename`
- Container logs: `podman logs container-name`
- Installation log: `/var/log/atomicos-kickstart.log`
- System messages: `/var/log/messages`
- Security logs: `/var/log/audit/audit.log`
- Monitoring data: `/var/log/atomicos/`

### Support Resources

- GitHub Issues: `https://github.com/prometheus-systems-tech/EL-AtomicOS/issues`
- Documentation: `https://github.com/prometheus-systems-tech/EL-AtomicOS/wiki`
- Community Forum: [Enterprise Linux Community]
- Enterprise Support: Contact your EL vendor

## Advanced Configuration

### Custom Container Registries

```bash
# Configure additional registries
sudo vi /etc/containers/registries.conf

# Add private registry
[[registry]]
location = "registry.company.com"
insecure = false
```

### Automated Deployments

```bash
# Create deployment script
cat > /opt/atomicos/bin/deploy.sh << 'EOF'
#!/bin/bash
podman pull registry.company.com/app:latest
podman stop app || true
podman rm app || true
podman run -d --name app -p 8080:8080 registry.company.com/app:latest
EOF

# Set up timer for automated deployments
sudo systemctl edit --force app-deploy.timer
```

### Performance Tuning

```bash
# Optimize for containers
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf

# Configure container storage
sudo vi /etc/containers/storage.conf

# Optimize journal settings
sudo vi /etc/systemd/journald.conf
```

---

**EL AtomicOS 10** - Enterprise Linux Atomic Operating System  
Compatible with RHEL 10, AlmaLinux 10, Rocky Linux 10, CentOS Stream 10, and Oracle Linux 10

For the latest documentation and updates, visit:  
`https://github.com/prometheus-systems-tech/EL-AtomicOS`
