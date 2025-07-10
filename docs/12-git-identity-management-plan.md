# Git Identity Management with Nix and Home-Manager

## 1. Introduction

This document outlines a detailed plan for managing multiple Git identities (e.g., personal, work) using Nix and Home-Manager. The existing Home-Manager setup is located under `config/home/modules`. This approach centralizes configuration, ensures reproducibility, and simplifies switching between different Git personas.

## 2. Why Manage Git Identities with Nix/Home-Manager?

- **Reproducibility**: Ensure consistent Git configurations across different machines.
- **Centralized Management**: All Git-related settings, including user names and emails, are managed in one place.
- **Ease of Switching**: Define multiple identities and easily switch between them based on project or context.
- **Version Control**: Git configurations are version-controlled alongside the rest of your NixOS/Home-Manager setup.

## 3. Core Concepts

- **Git Identities**: Git uses `user.name` and `user.email` to identify commits. These can be set globally, per-repository, or conditionally.
- **Home-Manager Modules**: Home-Manager allows defining user-specific configurations in a modular way. We will create a dedicated module for Git identities.
- **Nix Options**: Home-Manager provides options for configuring Git, such as `programs.git.enable` and `programs.git.userName`, `programs.git.userEmail`.

## 4. Implementation Plan

The plan involves creating a new Home-Manager module to define different Git identities and integrating it into the existing `config/home/modules` structure.

### Step 4.1: Create a New Home-Manager Module for Git Identities

Create a new Nix file, e.g., `config/home/modules/apps/git-identities.nix`, to house the Git identity configurations.

```nix
# config/home/modules/apps/git-identities.nix
{ config, pkgs, lib, ... }:

let
  # Define your Git identities here
  # Each identity is a set with 'name' and 'email' attributes
  identities = {
    personal = {
      name = "Your Personal Name";
      email = "your-personal-email@example.com";
      signingKey = "YOUR_PERSONAL_GPG_KEY_ID"; # Optional: for commit signing
    };
    work = {
      name = "Your Work Name";
      email = "your-work-email@work.com";
      signingKey = "YOUR_WORK_GPG_KEY_ID"; # Optional: for commit signing
    };
    # Add more identities as needed
  };

in {
  options.my.git.identity = lib.mkOption {
    type = lib.types.enum (lib.attrNames identities);
    description = "Select the active Git identity.";
    default = "personal"; # Set your default identity
  };

  config = lib.mkIf config.programs.git.enable {
    programs.git = {
      userName = identities.${config.my.git.identity}.name;
      userEmail = identities.${config.my.git.identity}.email;

      # Optional: Configure GPG signing if signingKey is provided for the selected identity
      signing = {
        key = lib.mkIf (identities.${config.my.git.identity}.signingKey or null != null)
          identities.${config.my.git.identity}.signingKey;
        signByDefault = lib.mkIf (identities.${config.my.git.identity}.signingKey or null != null) true;
      };

      # Optional: Include extra configuration for specific identities
      extraConfig = {
        # Example: Set up conditional includes for specific directories
        # This allows overriding the global identity for specific projects
        "includeIf \"gitdir:~/projects/work/\"" = {
          path = "~/.config/git/config-work"; # Path to a separate Git config file
        };
      };
    };
  };
}
```

### Step 4.2: Integrate the New Module

Include the new `git-identities.nix` module in your main Home-Manager configuration, typically `config/home/home-manager.nix` or `config/home/modules/home-manager.nix`.

```nix
# config/home/home-manager.nix (or similar main Home-Manager entry point)
{ config, pkgs, ... }:

{
  imports = [
    ./modules/apps/git.nix # Your existing git module
    ./modules/apps/git-identities.nix # The new git identities module
    # ... other modules
  ];

  # Enable git program
  programs.git.enable = true;

  # Set the default Git identity
  my.git.identity = "personal"; # Or "work", depending on your preference

  # ... rest of your home-manager configuration
}
```

### Step 4.3: Update Existing Git Configuration (if necessary)

Review `config/home/modules/apps/git.nix`. Ensure that `programs.git.userName` and `programs.git.userEmail` are _not_ set directly in this file if you intend for `git-identities.nix` to manage them. The `git-identities.nix` module will set these based on the `my.git.identity` option.

If `config/home/modules/apps/git.nix` currently sets `userName` and `userEmail`, remove those lines to avoid conflicts.

### Step 4.4: Handling Conditional Includes for Project-Specific Identities

For projects that always require a specific identity, regardless of the global Home-Manager setting, you can use Git's `includeIf` directive.

1.  **Create separate Git config files**:

    - `~/.config/git/config-work`:
      ```
      [user]
          name = Your Work Name
          email = your-work-email@work.com
      [gpg]
          signingkey = YOUR_WORK_GPG_KEY_ID
      ```
    - `~/.config/git/config-personal`:
      ```
      [user]
          name = Your Personal Name
          email = your-personal-email@example.com
      [gpg]
          signingkey = YOUR_PERSONAL_GPG_KEY_ID
      ```

2.  **Manage these files with Home-Manager**:
    You can use `home.file` to manage these files. Add the following to `config/home/modules/apps/git-identities.nix` or a similar module:

    ```nix
    # Inside config/home/modules/apps/git-identities.nix or a new file
    home.file.".config/git/config-personal".text = ''
      [user]
          name = ${identities.personal.name}
          email = ${identities.personal.email}
      ${lib.optionalString (identities.personal.signingKey or null != null) ''
      [gpg]
          signingkey = ${identities.personal.signingKey}
      ''}
    '';

    home.file.".config/git/config-work".text = ''
      [user]
          name = ${identities.work.name}
          email = ${identities.work.email}
      ${lib.optionalString (identities.work.signingKey or null != null) ''
      [gpg]
          signingkey = ${identities.work.signingKey}
      ''}
    '';
    ```

3.  **Add `includeIf` to `programs.git.extraConfig`**:
    As shown in Step 4.1, add the `includeIf` directives to your `programs.git.extraConfig` in `git-identities.nix`:

    ```nix
    programs.git.extraConfig = {
      "includeIf \"gitdir:~/projects/work/\"" = {
        path = "~/.config/git/config-work";
      };
      "includeIf \"gitdir:~/projects/personal/\"" = {
        path = "~/.config/git/config-personal";
      };
      # Add more conditional includes as needed
    };
    ```

    This setup ensures that if you are in a repository under `~/projects/work/`, the `config-work` file will override the global settings.

### Step 4.5: Managing GPG Keys (Optional but Recommended)

If you use GPG for commit signing, ensure your GPG keys are managed and available to Home-Manager. This typically involves:

- **Importing keys**: Manually import your GPG keys into your GnuPG keyring.
- **GnuPG Home-Manager configuration**: Ensure `programs.gnupg.enable = true;` and potentially configure `programs.gnupg.agent.enable = true;` for the GPG agent.
- **SSH Agent Integration**: If using GPG keys for SSH, configure `programs.ssh.enableGpgAgent = true;`.

### Step 4.6: Testing the Setup

After applying the Home-Manager configuration:

1.  **Verify global identity**:

    ```bash
    git config --global user.name
    git config --global user.email
    ```

    These should reflect the `my.git.identity` set in your Home-Manager configuration.

2.  **Test conditional identity (if configured)**:
    Navigate to a project directory configured with `includeIf` (e.g., `~/projects/work/my-work-repo`).

    ```bash
    cd ~/projects/work/my-work-repo
    git config user.name
    git config user.email
    ```

    These should reflect the work identity.

3.  **Test commit signing (if configured)**:
    Make a test commit and verify it's signed with the correct key.
    ```bash
    git commit -S -m "Test commit"
    git log --show-signature -1
    ```

## 5. Future Considerations

### 5.1. Using SSH Keys for Git Commit Signing

Git 2.34 and later supports using SSH keys for commit signing, providing an alternative to GPG. This can be integrated into your Home-Manager setup.

To enable SSH signing:

1.  **Ensure Git version is 2.34+**:

    ```nix
    programs.git.package = pkgs.gitAndTools.gitFull; # Or a specific version if needed
    ```

2.  **Configure Git to use SSH for signing**:
    In your `git-identities.nix` or `git.nix` module, add the following:

    ```nix
    programs.git = {
      # ... existing git configuration ...
      signing = {
        # Set the signing format to ssh
        format = "ssh";
        # Specify the SSH key to use for signing
        key = "~/.ssh/id_ed25519"; # Replace with your SSH key path
        # Optional: Sign all commits by default
        signByDefault = true;
      };
      extraConfig = {
        "gpg.ssh.allowedSignersFile" = "~/.ssh/allowed_signers";
      };
    };
    ```

    You will need to replace `~/.ssh/id_ed25519` with the actual path to your SSH private key used for signing.

3.  **Create an `allowed_signers` file**:
    Git requires an `allowed_signers` file to verify SSH signatures. This file maps SSH public keys to email addresses.
    Example `~/.ssh/allowed_signers`:

    ```
    your-personal-email@example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL... # Your personal SSH public key
    your-work-email@work.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK... # Your work SSH public key
    ```

    You can manage this file with Home-Manager using `home.file`:

    ```nix
    home.file.".ssh/allowed_signers".text = ''
      ${identities.personal.email} ${builtins.readFile ./path/to/your/personal_ssh_key.pub}
      ${identities.work.email} ${builtins.readFile ./path/to/your/work_ssh_key.pub}
    '';
    ```

    Make sure to replace `./path/to/your/personal_ssh_key.pub` and `./path/to/your/work_ssh_key.pub` with the actual paths to your public SSH keys.

4.  **Update `git-identities.nix` for SSH signing keys**:
    Modify the `identities` set to include `signingKeySsh` instead of `signingKey` (or add it alongside if you want both GPG and SSH options).

    ```nix
    # config/home/modules/apps/git-identities.nix
    { config, pkgs, lib, ... }:

    let
      identities = {
        personal = {
          name = "Your Personal Name";
          email = "your-personal-email@example.com";
          signingKeySsh = "~/.ssh/id_ed25519_personal"; # Path to personal SSH key
        };
        work = {
          name = "Your Work Name";
          email = "your-work-email@work.com";
          signingKeySsh = "~/.ssh/id_ed25519_work"; # Path to work SSH key
        };
      };

    in {
      options.my.git.identity = lib.mkOption {
        type = lib.types.enum (lib.attrNames identities);
        description = "Select the active Git identity.";
        default = "personal";
      };

      config = lib.mkIf config.programs.git.enable {
        programs.git = {
          userName = identities.${config.my.git.identity}.name;
          userEmail = identities.${config.my.git.identity}.email;

          signing = {
            format = "ssh";
            key = identities.${config.my.git.identity}.signingKeySsh;
            signByDefault = true;
          };

          extraConfig = {
            "gpg.ssh.allowedSignersFile" = "~/.ssh/allowed_signers";
          };
        };
      };
    }
    ```

    **Note on `age` and SSH keys**: While `age` can use SSH public keys as recipients for encryption, it is not directly involved in Git's native commit signing process. Git's SSH signing feature uses the SSH key directly. If you intend to use `age` for encrypting sensitive Git-related files (e.g., `allowed_signers` or other configuration), you would use `age` separately for that purpose, but it doesn't replace Git's signing mechanism.

### 5.2. Secrets Management

For highly sensitive information (e.g., private GPG keys, SSH private keys), consider using a dedicated secrets management solution like `sops-nix` or `agenix` in conjunction with Home-Manager, rather than hardcoding key IDs or paths directly in the Nix files.

### 5.3. Scripted Switching

While Home-Manager sets a default, you might want a quick way to temporarily switch identities without rebuilding. This could involve simple shell aliases or scripts that modify `~/.gitconfig` directly (though this would conflict with Home-Manager's declarative approach if not handled carefully). The `includeIf` approach is generally preferred for declarative management.
