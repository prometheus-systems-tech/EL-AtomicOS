# EL AtomicOS 10

Enterprise Linux Atomic Operating System for RHEL 10 and all compatible distributions.

**EL AtomicOS 10** is an immutable, container-focused operating system designed for modern cloud, edge, and enterprise workloads. It features:

- Atomic, transactional updates using OSTree and rpm-ostree
- Full compatibility with RHEL 10, AlmaLinux 10, Rocky Linux 10, Oracle Linux 10, CentOS Stream 10, and other Enterprise Linux 10 derivatives
- Out-of-the-box support for Podman, Docker, and Kubernetes workloads
- Web-based management via Cockpit (with Podman, Docker, and Kubernetes modules)
- Secure defaults with SELinux enforcing
- Persistent journald logging and robust systemd service management
- Minimal, cloud-ready, and edge-optimized footprint

## Key Features

- Immutable base system with atomic updates and rollback
- Container-first design: Podman, Docker, and Kubernetes supported side-by-side
- Web management: Cockpit with Podman, Docker, and Kubernetes integration
- Kubernetes node/cluster support (kubelet, kubeadm, kubectl included)
- Docker CLI, daemon, Compose, and Buildx support
- Enhanced security: SELinux enforcing, minimal attack surface
- Automated installation and configuration via Kickstart
- Fedora CoreOS-style partitioning (no LVM, XFS root, ext4 /boot, EFI, swap)

## Documentation

- [Installation and User Manual](./EL%20AtomicOS%2010%20Manual.md)
- [Kickstart Example](./EL_AtomicOS_10_kickstart.ks)
- [Project Wiki](https://github.com/prometheus-systems-tech/EL-AtomicOS/wiki)

## Quick Start

1. Download the Kickstart file and boot your system with the appropriate installation media.
2. Use the Cockpit web interface at `https://<hostname>:9090` for system and container management.
3. Manage containers with Podman, Docker, or Kubernetes from the CLI or Cockpit.

## Security Notes

- Default user: `atomic` (password: `atomic`) — **change immediately after install**
- SELinux is enforcing by default
- Cockpit and container ports are open in the firewall for remote management

## Copyright

*Creator :*
Copyright (c) 2025-Present, Ross W.D. Cameron \
                            <rwd.cameron@prometheus-systems.co.za>  

*Sponsored by :*
Copyright (c) 2025-Present, Prometheus Systems \
                            <https://www.prometheus-systems.co.za/>

## License

This project is licensed under the terms of the GNU General Public License v2 (GPLv2).  
See the [LICENSE](LICENSE) file for details.

## Contributing

By contributing to this project, you agree to license your contributions under the GPL v2.
