# EL AtomicOS 10 Kickstart Configuration
text
reboot

network --bootproto=dhcp --device=link --activate --onboot=on --hostname=el-atomicos

keyboard --vckeymap=us --xlayouts='us'
lang en_US.UTF-8
timezone America/New_York --utc

authselect select sssd
selinux --enforcing
firewall --enabled --ssh

user --name=atomic --password=atomic --plaintext --gecos="EL AtomicOS Admin" --groups=wheel,docker

clearpart --all --initlabel
zerombr

bootloader --location=mbr --driveorder=sda --append="rhgb quiet"

part /boot --fstype=ext4 --size=1024 --ondisk=sda
part /boot/efi --fstype=efi --size=512 --ondisk=sda
part pv.01 --size=1 --grow --ondisk=sda

volgroup atomicos pv.01
logvol / --fstype=xfs --name=root --vgname=atomicos --size=20480 --grow
logvol /var --fstype=xfs --name=var --vgname=atomicos --size=10240
logvol /home --fstype=xfs --name=home --vgname=atomicos --size=5120
logvol /tmp --fstype=xfs --name=tmp --vgname=atomicos --size=2048
logvol swap --name=swap --vgname=atomicos --size=4096

# OSTree setup - this is the key addition
ostreesetup --osname=el-atomicos --remote=fedora --url=https://ostree.fedoraproject.org/atomic/ --ref=fedora/40/x86_64/atomic-host --nogpg

%packages --excludedocs
@core
@standard
@hardware-support
rpm-ostree
ostree
podman
toolbox
docker-ce
docker-ce-cli
containerd.io
docker-buildx-plugin
docker-compose-plugin
kubernetes
kubeadm
kubelet
kubectl
systemd-resolved
flatpak
cockpit
cockpit-podman
cockpit-docker
sudo
vim-minimal
curl
wget
git
crun
runc
conmon
containers-common
fail2ban
auditd
bind-utils
nmap-ncat
tcpdump
htop
iotop
strace
lsof
psmisc
%end

%post --log=/var/log/atomicos-kickstart.log
# Initialize OSTree after installation
ostree admin init-fs /sysroot
ostree admin os-init el-atomicos

systemctl enable rpm-ostreed
systemctl enable ostree-remount.service
systemctl enable NetworkManager
systemctl enable chronyd
systemctl enable sshd
systemctl enable cockpit.socket
systemctl enable podman.socket
systemctl enable docker
systemctl enable containerd
systemctl enable kubelet
systemctl enable systemd-resolved
systemctl enable podman-auto-update.timer
systemctl disable postfix

mkdir -p /etc/atomicos
cat > /etc/atomicos/update.conf << 'EOF'
AUTO_UPDATE_ENABLED=false
UPDATE_SCHEDULE="weekly"
REBOOT_STRATEGY="off"
UPDATE_GROUP="stable"
EOF

mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/atomicos.conf << 'EOF'
[Journal]
Storage=persistent
SystemMaxUse=1G
RuntimeMaxUse=100M
MaxRetentionSec=1month
EOF

firewall-offline-cmd --add-service=cockpit
firewall-offline-cmd --add-port=2376/tcp
firewall-offline-cmd --add-port=8080/tcp
firewall-offline-cmd --add-port=6443/tcp
firewall-offline-cmd --add-port=10250/tcp
firewall-offline-cmd --add-port=10251/tcp
firewall-offline-cmd --add-port=10252/tcp
firewall-offline-cmd --add-port=2379-2380/tcp

cat > /etc/machine-info << EOF
PRETTY_HOSTNAME="EL AtomicOS 10"
DEPLOYMENT="EL AtomicOS Production"
EOF

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

# Configure Docker daemon
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "journald",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Configure kubelet
mkdir -p /etc/kubernetes
cat > /etc/kubernetes/kubelet.conf << 'EOF'
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
EOF

echo 'atomicos ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/atomicos

mkdir -p /usr/share/doc/atomicos
cat > /usr/share/doc/atomicos/README << 'EOF'
EL AtomicOS 10 - Enterprise Linux Atomic Operating System

This system is designed as an immutable, container-focused platform
compatible with RHEL 10 and its ecosystem clones.

Key Features:
- Immutable base system with atomic updates via rpm-ostree
- Container-first approach with Podman, Docker, and Kubernetes support
- Web-based management via Cockpit
- Enhanced security with SELinux enforcing
- Optimized for cloud and edge deployments
EOF

cat > /etc/motd << 'EOF'

  ╔═══════════════════════════════════════════════════════════╗
  ║                    EL AtomicOS 10                         ║
  ║        Enterprise Linux Atomic Operating System           ║
  ║                                                           ║
  ║ Container-optimized • Immutable • Secure • Scalable      ║
  ║                                                           ║
  ║  Web Management: https://$(hostname):9090                 ║
  ║  Documentation: /usr/share/doc/atomicos/                  ║
  ║                                                           ║
  ║  podman ps          - List running containers             ║
  ║  docker ps          - List Docker containers              ║
  ║  kubectl get pods   - List Kubernetes pods                ║
  ║  rpm-ostree status  - Show system status                  ║
  ║  rpm-ostree upgrade - Update system                       ║
  ║                                                           ║
  ╚═══════════════════════════════════════════════════════════╝

EOF

echo 'mount -o remount,ro /' >> /etc/rc.local
chmod +x /etc/rc.local

systemctl set-default multi-user.target

echo "EL AtomicOS 10 post-installation complete"
%end

reboot
