# EL AtomicOS 10 Kickstart Configuration
#
# Copyright (c) 2025-Present, Ross W.D. Cameron <rwd.cameron@prometheus-systems.co.za>
# Copyright (c) 2025-Present, Prometheus Systems <https://prometheus-systems.co.za/>
#
# This file is part of EL AtomicOS 10 and is licensed under the GNU General Public License v2.
# See the LICENSE file for details.
# Enterprise Linux Atomic Operating System for RHEL 10 and compatible distributions
# Creates an immutable, container-focused system similar to openSUSE MicroOS
# Compatible with: RHEL 10, AlmaLinux 10, Rocky Linux 10, CentOS Stream 10, Oracle Linux 10

# Installation method
install
text
reboot

# Network configuration
network --bootproto=dhcp --device=link --activate --onboot=on --hostname=el-atomicos

# Keyboard and language
keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8

# Timezone
timezone America/New_York --utc

# Security settings
authselect select sssd
selinux --enforcing
firewall --enabled --ssh

# Root password (change this!)
rootpw --iscrypted $6$rounds=4096$saltsalt$hash_here_replace_with_real_hash

# User account for administration
user --name=atomicos --password=$6$rounds=4096$saltsalt$hash_here_replace_with_real_hash --iscrypted --gecos="EL AtomicOS Admin" --groups=wheel,docker

# Disk partitioning for immutable system
clearpart --all --initlabel
zerombr

# Bootloader configuration
bootloader --location=mbr --driveorder=sda --append="rhgb quiet"

# Partition layout optimized for atomic updates
part /boot --fstype=ext4 --size=1024 --ondisk=sda
part /boot/efi --fstype=efi --size=512 --ondisk=sda
part pv.01 --size=1 --grow --ondisk=sda

# LVM configuration for flexible storage management
volgroup atomicos pv.01
logvol / --fstype=xfs --name=root --vgname=atomicos --size=20480 --grow
logvol /var --fstype=xfs --name=var --vgname=atomicos --size=10240
logvol /home --fstype=xfs --name=home --vgname=atomicos --size=5120
logvol /tmp --fstype=xfs --name=tmp --vgname=atomicos --size=2048
logvol swap --name=swap --vgname=atomicos --size=4096

# Package selection - minimal base for atomic system
%packages --nobase --excludedocs
@core
@standard
@hardware-support
kernel
dracut-config-generic
grub2
grub2-efi-x64
shim-x64
NetworkManager
chrony
rsyslog
openssh-server
sudo
vim-minimal
curl
wget
git
podman
buildah
skopeo
cockpit
cockpit-podman
systemd-resolved
rpm-ostree
ostree
flatpak
# Container runtime and tools
crun
runc
conmon
containers-common
# Security and monitoring
aide
auditd
fail2ban
# Development essentials
gcc
make
python3
python3-pip
# Network tools
bind-utils
traceroute
tcpdump
nmap-ncat
# System management
htop
iotop
strace
lsof
psmisc
%end

# Post-installation script
%post --log=/var/log/atomicos-kickstart.log
systemctl enable NetworkManager
systemctl enable chronyd
systemctl enable sshd
systemctl enable cockpit.socket
systemctl enable podman.socket
systemctl enable systemd-resolved
systemctl disable postfix

# Create EL AtomicOS branding
cat > /etc/os-release << 'EOF'
NAME="EL AtomicOS"
VERSION="10"
ID="el-atomicos"
VERSION_ID="10"
PRETTY_NAME="EL AtomicOS 10 (Enterprise Linux Atomic Operating System)"
ANSI_COLOR="0;34"
CPE_NAME="cpe:/o:enterprise:el_atomicos:10"
HOME_URL="https://github.com/prometheus-systems-tech/EL-AtomicOS"
DOCUMENTATION_URL="https://github.com/prometheus-systems-tech/EL-AtomicOS/wiki"
SUPPORT_URL="https://github.com/prometheus-systems-tech/EL-AtomicOS/issues"
BUG_REPORT_URL="https://github.com/prometheus-systems-tech/EL-AtomicOS/issues"
LOGO="el-atomicos"
EOF

# Create system directories
mkdir -p /var/log/atomicos
mkdir -p /etc/atomicos
mkdir -p /opt/atomicos/{bin,lib,share}

# Configure immutable system settings
echo 'PRETTY_HOSTNAME="EL AtomicOS 10"' >> /etc/machine-info
echo 'DEPLOYMENT="EL AtomicOS Production"' >> /etc/machine-info

# Configure container storage
mkdir -p /etc/containers
cat > /etc/containers/policy.json << 'EOF'
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker-daemon": {
            "": [{"type":"insecureAcceptAnything"}]
        }
    }
}
EOF

# Configure Podman for rootless operation
cat > /etc/containers/containers.conf << 'EOF'
[containers]
log_driver = "journald"
pids_limit = 2048

[engine]
cgroup_manager = "systemd"
events_logger = "journald"
runtime = "crun"

[network]
network_backend = "netavark"
EOF

# Configure automatic updates (disabled by default for stability)
cat > /etc/atomicos/update.conf << 'EOF'
# EL AtomicOS Update Configuration
AUTO_UPDATE_ENABLED=false
UPDATE_SCHEDULE="weekly"
REBOOT_STRATEGY="off"
UPDATE_GROUP="stable"
EOF

# Configure container auto-update service
systemctl enable podman-auto-update.timer

# Configure firewall for container services
firewall-offline-cmd --add-service=cockpit
firewall-offline-cmd --add-port=2376/tcp  # Docker API
firewall-offline-cmd --add-port=8080/tcp  # Common container port

# Set up Cockpit for web management
systemctl enable cockpit.socket

# Configure journal for container logs
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/atomicos.conf << 'EOF'
[Journal]
Storage=persistent
SystemMaxUse=1G
RuntimeMaxUse=100M
MaxRetentionSec=1month
EOF

# Create welcome message
cat > /etc/motd << 'EOF'

  ╔═══════════════════════════════════════════════════════════╗
  ║                    EL AtomicOS 10                         ║
  ║        Enterprise Linux Atomic Operating System          ║
  ║                                                           ║
  ║  Container-optimized • Immutable • Secure • Scalable     ║
  ║                                                           ║
  ║  Web Management: https://$(hostname):9090                 ║
  ║  Documentation: /usr/share/doc/atomicos/                  ║
  ║                                                           ║
  ║  Container Commands:                                      ║
  ║    podman ps          - List running containers          ║
  ║    podman pull <img>  - Pull container image             ║
  ║    podman run <img>   - Run container                    ║
  ║                                                           ║
  ║  System Commands:                                         ║
  ║    rpm-ostree status  - Show system status               ║
  ║    rpm-ostree upgrade - Update system                    ║
  ║    systemctl reboot   - Reboot to apply updates          ║
  ╚═══════════════════════════════════════════════════════════╝

EOF

# Create documentation directory
mkdir -p /usr/share/doc/atomicos
cat > /usr/share/doc/atomicos/README << 'EOF'
EL AtomicOS 10 - Enterprise Linux Atomic Operating System

This system is designed as an immutable, container-focused platform
compatible with RHEL 10 and its ecosystem clones.

Key Features:
- Immutable base system with atomic updates via rpm-ostree
- Container-first approach with Podman
- Web-based management via Cockpit
- Enhanced security with SELinux enforcing
- Optimized for cloud and edge deployments

For more information, visit:
https://github.com/prometheus-systems-tech/EL-AtomicOS
EOF

# Configure sudo for atomicos user
echo 'atomicos ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/atomicos

# Final system preparation
systemctl set-default multi-user.target
systemctl enable rpm-ostreed

echo "EL AtomicOS 10 post-installation complete"

%end

# Reboot after installation
reboot
