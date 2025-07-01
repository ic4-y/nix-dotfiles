# Detailed Implementation Plan: Integrate into CI Builds using Github Actions

This document outlines the detailed plan for integrating the NixOS configurations and documentation into CI builds using Github Actions, including Continuous Deployment (CD) with user approval and Nebula integration.

## 1. Github Actions Workflow Design for NixOS

Introduction to Github Actions and how to structure workflows for NixOS projects.

## 2. Flake Update Automation

Automating `nix flake update` to keep dependencies fresh.

### Code Example (Github Actions workflow for flake update):

```yaml
# .github/workflows/flake-update.yml
name: Nix Flake Update

on:
  schedule:
    - cron: "0 0 * * *" # Daily at midnight UTC
  workflow_dispatch: # Allow manual trigger

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - name: Update Nix Flake inputs
        run: nix flake update
      - name: Commit and Push changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add flake.lock
          git commit -m "Automated: Update Nix flake inputs" || echo "No changes to commit"
          git push
```

## 3. System Build Process

Building NixOS configurations in CI and caching build artifacts.

### Code Example (Github Actions workflow for building NixOS):

```yaml
# .github/workflows/build-nixos.yml
name: Build NixOS Configurations

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - name: Build NixOS configurations
        run: |
          # Example: Build a specific host
          nixos-rebuild build --flake ".#your-host-name"
          # Or build all systems defined in the flake
          # nix flake check --all-systems
```

## 4. Integration with Testing (VM Tests)

Referencing `docs/nixos-vm-testing.md` for running VM tests in CI. This section will emphasize that successful VM tests are a prerequisite for deployment approval.

## 5. Automated Deployment Workflow (Continuous Deployment)

Triggering `nixos-anywhere` deployments from CI, securely handling deployment credentials (e.g., SSH keys via Github Secrets), and pushing changes via the Nebula mesh network. This section will also cover the approval mechanism.

### Approval and Notification Mechanism

Implement a step that pauses the workflow and waits for manual approval, potentially sending a notification (e.g., via Telegram) to a designated user or group. This ensures that deployments only proceed after human review and confirmation, especially after successful VM tests.

### Code Example (Github Actions workflow for deployment with approval and Nebula):

```yaml
# .github/workflows/deploy.yml
name: Deploy NixOS Host

on:
  push:
    branches: [main]
    paths:
      - "config/hosts/your-host-system.nix" # Trigger on changes to host config
      - "flake.nix"
      - "flake.lock"
  workflow_dispatch:
    inputs:
      host:
        description: "Host to deploy"
        required: true
        default: "your-host-name"

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://your-monitoring-dashboard.com # Optional: Link to monitoring
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main

      # Step 1: Run VM tests (assuming a separate job or integrated here)
      # This step would typically be a dependency from a 'test' job
      - name: Run NixOS VM tests
        run: nix build .#nixosTests.${{ github.event.inputs.host }}-test # Example: specific test for the host
        # Add logic to fail if tests fail

      # Step 2: Send Telegram Notification and Wait for Approval
      - name: Notify and Wait for Approval
        uses: peter-evans/find-comment@v2 # Or a custom action for Telegram
        with:
          issue-number: ${{ github.event.pull_request.number }}
          comment-author: "github-actions[bot]"
          body-includes: "Deployment approval for ${{ github.event.inputs.host }}"
        # This is a placeholder. A real implementation would involve:
        # 1. Sending a Telegram message with a link to the workflow run.
        # 2. Waiting for a specific response (e.g., a comment on the PR, or a webhook from Telegram).
        # 3. Using a manual approval step in the environment settings.
        # For simplicity, we'll rely on GitHub's environment protection rules for manual approval.

      - name: Setup SSH over Nebula
        run: |
          # Assuming Nebula is configured and reachable from the CI runner
          # This might involve running a Nebula client on the CI runner or
          # using a self-hosted runner within the Nebula network.
          # For a public GitHub Actions runner, this would require a public Nebula lighthouse
          # or a tunnel.
          # For demonstration, we assume direct SSH access over Nebula IP.
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          # Use the Nebula IP of the target host
          ssh-keyscan -H ${{ secrets.DEPLOY_HOST_NEBULA_IP }} >> ~/.ssh/known_hosts
          # Ensure the CI runner has Nebula client installed and configured to reach the target.
          # This is a conceptual step. Actual implementation might involve a custom Docker image
          # for the runner with Nebula client, or a self-hosted runner.

      - name: Deploy Host via Nebula
        run: |
          nixos-anywhere --flake ".#${{ github.event.inputs.host }}" \
            nixops@${{ secrets.DEPLOY_HOST_NEBULA_IP }} \
            --ssh-user nixops \
            --extra-ssh-options "-i ~/.ssh/id_ed25519"
```
