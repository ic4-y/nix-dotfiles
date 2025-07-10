# Dotfiles for my NixOS :snowflake: machines

This repository contains my personal NixOS :snowflake: configurations for various desktop machines (PCs and laptops). It aims to provide a fully declarative, reproducible, and modular setup for managing system and user environments.

## Key Features & Configuration Areas

- **Declarative System & Home Management**: Leveraging NixOS and Home-Manager for reproducible system and user configurations.
- **Secrets Management**: Integration with `sops-nix` for securely managing sensitive data.
- **Backup & Recovery**: Robust backup strategies utilizing Restic and Btrfs snapshots.
- **Automated Deployment**: Streamlined machine provisioning with NixOS Anywhere.
- **Advanced Networking**: Configurations for Prometheus monitoring, Nebula mesh networks, WireGuard VPNs with network namespaces, and declarative Tailscale VPNs.
- **Development Environment**: Comprehensive setup for various programming languages, editors (e.g., Neovim), and CLI tools.
- **Graphical Environment**: Customizations for Wayland, GNOME, and various graphical applications including Eww and Mako.
- **Testing & CI/CD**: Plans for NixOS VM testing and integration with GitHub Actions for continuous integration.
- **Identity Management**: Centralized management of Git identities and email accounts.

## Getting Started

To understand and utilize these configurations effectively, a thorough understanding of the NixOS and Home-Manager configuration by reviewing relevant modules and documentation within this repository is required. Explore the `config/` directory for system and home modules, and the `docs/` directory for detailed implementation plans and strategies.
