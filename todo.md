## Rules for each task

- [ ] **Contextual Awareness**: Before starting any task, ensure a thorough understanding of the NixOS and Home-Manager configuration by reviewing relevant modules and documentation within this repository, especially those related to the specific area of the task (e.g., `config/home/modules`, `config/sys/modules`, `docs/`).
- [ ] **Configuration Integration**: Any one-off task is considered complete only after its successful integration with the existing NixOS and Home-Manager configurations has been verified (e.g., by rebuilding and testing the system/home configuration). Once CI/CD and automated testing of features are set up, all tests must pass locally.
- [ ] **Update README.md**: Update `README.md` if the task is relevant enough to be included in the general information therein.
- [ ] **Task Completion Marking**: Upon successful completion of any task, ensure it is marked as completed in this list.

## One-off tasks

- [x] **Update README.md**: Update `README.md`. Gather a thorough understanding of the NixOS and Home-Manager configuration by reviewing relevant modules and documentation within this repository. Then provide a concise summary for people coming to this repo in README.md. Also ensure that this summary is aesthetically pleasing.
- [x] **Add SSHD**: Configure SSHD to generate SSH keys for the machines.
- [ ] **Integrate Sops-Nix**: Integrate `sops-nix` into the configuration for managing secrets (see [`docs/02-sops-nix-integration-plan.md`](docs/02-sops-nix-integration-plan.md)).
- [ ] **Add SSH Hostkeys to Secrets**: Add SSH hostkeys to secrets to fix them for future deployments.
- [ ] **Integrate Email Accounts**: Integrate email accounts with Home-Manager (see [`docs/11-home-manager-email-integration-plan.md`](docs/11-home-manager-email-integration-plan.md)).
- [ ] **Manage Git Identities**: Manage Git identities with Home-Manager (see [`docs/12-git-identity-management-plan.md`](docs/12-git-identity-management-plan.md)).
- [ ] **Add NixOS Tests**: Add NixOS tests for these features and many more (repeating task).
- [ ] **Integrate CI/CD**: Integrate CI/CD into the configuration (see [`docs/09-github-actions-ci-plan.md`](docs/09-github-actions-ci-plan.md)).
- [ ] **Declarative Partitioning with Disko**: Implement declarative partitioning using Disko (see [`docs/01-disko-declarative-partitioning.md`](docs/01-disko-declarative-partitioning.md)).
- [ ] **Restic BTRFS Backup Strategy**: Implement a Restic BTRFS backup strategy (see [`docs/03-restic-btrfs-backup-strategy.md`](docs/03-restic-btrfs-backup-strategy.md)).
- [ ] **NixOS Anywhere Deployment**: Plan and implement NixOS deployments using NixOS Anywhere (see [`docs/04-nixos-anywhere-deployment.md`](docs/04-nixos-anywhere-deployment.md)).
- [ ] **Prometheus Monitoring Strategy**: Implement a Prometheus monitoring strategy (see [`docs/05-prometheus-monitoring-strategy.md`](docs/05-prometheus-monitoring-strategy.md)).
- [ ] **Nebula Mesh Network**: Set up a Nebula mesh network (see [`docs/06-nebula-mesh-network.md`](docs/06-nebula-mesh-network.md)).
- [ ] **WireGuard Network Namespace**: Configure WireGuard within a network namespace (see [`docs/07-wireguard-network-namespace.md`](docs/07-wireguard-network-namespace.md)).
- [ ] **Tailscale Declarative VPN**: Implement Tailscale as a declarative VPN (see [`docs/08-tailscale-declarative-vpn.md`](docs/08-tailscale-declarative-vpn.md)).
- [ ] **NixOS VM Testing Plan**: Implement the NixOS VM testing plan (see [`docs/10-nixos-vm-testing-plan.md`](docs/10-nixos-vm-testing-plan.md)).
