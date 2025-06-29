# EL AtomicOS 10

Enterprise Linux Atomic Operating System for RHEL 10 and all compatible distributions.

**EL AtomicOS 10** is an immutable, container-focused operating system designed for modern cloud, edge, and enterprise workloads. It provides:

- Atomic, transactional updates using OSTree and rpm-ostree
- Full compatibility with RHEL 10, AlmaLinux 10, Rocky Linux 10, Oracle Linux 10, CentOS Stream 10, and other Enterprise Linux 10 derivatives
- Out-of-the-box support for Podman, Docker, and Kubernetes workloads
- Secure defaults with SELinux enforcing, fail2ban, and auditd
- Web-based management via Cockpit (with Podman and Docker modules)
- Persistent journald logging and robust systemd service management
- Minimal, cloud-ready, and edge-optimized footprint

## Key Features

- Immutable base system with atomic updates and rollback
- Container-first design: Podman, Docker, and Kubernetes supported side-by-side
- Web management: Cockpit with Podman and Docker integration
- Enhanced security: SELinux, fail2ban, auditd, minimal attack surface
- Automated installation and configuration via Kickstart
- LVM partitioning and persistent logging

## Documentation

- [Installation and User Manual](./EL%20AtomicOS%2010%20Manual.md)
- [Kickstart Example](./EL_AtomicOS_10_kickstart.ks)
- [Project Wiki](https://github.com/prometheus-systems-tech/EL-AtomicOS/wiki)

## Copyright

Copyright (c) 2025-Present, Ross W.D. Cameron \
                            <rwd.cameron@prometheus-systems.co.za>  

Copyright (c) 2025-Present, Prometheus Systems \
                            <https://www.prometheus-systems.co.za/>

## License

This project is licensed under the terms of the GNU General Public License v2 (GPLv2).  
See the [LICENSE](LICENSE) file for details.

## Contributing

By contributing to this project, you agree to license your contributions under the GPL v2.
