# Detailed Implementation Plan: Integrate Email Accounts using Home-manager

This document outlines the detailed plan for integrating email accounts using Home-manager, providing comprehensive configuration options for various email clients, with a focus on Thunderbird.

## 1. Introduction to Home-manager for Email

Explain how Home-manager simplifies managing user-specific configurations, including email clients, ensuring consistency and reproducibility across different machines.

## 2. Centralized Email Account Configuration

Define a generic email account structure that can be reused by multiple clients, leveraging `accounts.email.accounts` options. This includes IMAP and SMTP server details, and secure password management using `sops-nix`.

### Code Example (Generic Email Account with `sops-nix`):

```nix
# home/modules/email-accounts.nix
{ config, pkgs, lib, ... }:
{
  # Define sops secret for email password
  sops.secrets."my-email-password" = {
    sopsFile = ./secrets/email/my-email-password.enc.yaml;
    key = "emailPassword";
    mode = "0400";
    owner = config.users.users.youruser.name; # Replace 'youruser' with the actual username
  };

  # Define the email account
  accounts.email.accounts.my-personal-email = {
    address = "my.personal.email@example.com";
    userName = "my.personal.email@example.com";
    realName = "Your Name";
    flavor = "plain"; # Or "gmail.com", "outlook.office365.com", etc.

    # IMAP (Incoming Mail) Configuration
    imap = {
      enable = true;
      host = "imap.example.com";
      port = 993;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };

    # SMTP (Outgoing Mail) Configuration
    smtp = {
      enable = true;
      host = "smtp.example.com";
      port = 465;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };

    # Command to retrieve the password securely
    passwordCommand = "cat ${config.sops.secrets."my-email-password".path}";

    # Optional: Configure standard folders
    folders = {
      inbox = "INBOX";
      sent = "Sent Items";
      drafts = "Drafts";
      trash = "Trash";
    };

    # Optional: GPG signing/encryption settings
    gpg = {
      enable = false; # Set to true to enable GPG for this account
      key = "YOUR_GPG_KEY_ID"; # Your GPG key ID
      signByDefault = false;
      encryptByDefault = false;
    };
  };
}
```

- **Note on `sops-nix`:** The `sops.secrets` definition assumes you have `sops-nix` set up in your NixOS configuration. The `secrets/email/my-email-password.enc.yaml` file would contain the encrypted password.

## 3. Integrating with Email Clients

### 3.1. Thunderbird Configuration

Thunderbird is a popular GUI email client. Home-manager provides extensive options under `programs.thunderbird` and `accounts.email.accounts.<name>.thunderbird`.

#### Code Example (Thunderbird Integration):

```nix
# home/modules/thunderbird.nix
{ config, pkgs, ... }:
{
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird; # Or a specific version like pkgs.thunderbird-102

    # Define a profile for Thunderbird
    profiles.default = {
      isDefault = true;
      name = "default";
      # Link the email account defined above to this profile
      accounts = [ config.accounts.email.accounts.my-personal-email ];

      # General settings for this profile
      settings = {
        "mail.spellcheck.inline" = false;
        "mail.server.server1.check_new_mail" = true; # Example setting
        "mail.identity.default.fullName" = "Your Full Name";
        "mail.identity.default.signature_file" = "${pkgs.writeText "signature.txt" "Best regards,\nYour Name"}";
      };

      # Custom userChrome.css for UI customization
      userChrome = ''
        /* Hide tab bar in Thunderbird */
        #tabs-toolbar {
          visibility: collapse !important;
        }
      '';

      # Custom userContent.css for email content rendering
      userContent = ''
        /* Example: Adjust font size in email content */
        body {
          font-size: 14px !important;
        }
      '';

      # Enable external GPG keys with GPGME (requires system-wide GPG setup)
      withExternalGnupg = true;
    };

    # Global Thunderbird settings (applied to all profiles)
    settings = {
      "general.useragent.override" = "";
      "privacy.donottrackheader.enabled" = true;
    };
  };
}
```

### 3.2. Terminal-based Email Clients (e.g., Neomutt)

For users preferring a terminal-centric workflow, clients like Neomutt can also be integrated.

#### Code Example (Neomutt Integration):

```nix
# home/modules/neomutt.nix
{ config, pkgs, ... }:
{
  programs.neomutt = {
    enable = true;
    package = pkgs.neomutt;

    # Link the email account
    accounts = [ config.accounts.email.accounts.my-personal-email ];

    # Neomutt specific configurations
    extraConfig = ''
      # Set folder for the account
      set folder = "imaps://${config.accounts.email.accounts.my-personal-email.imap.host}:${toString config.accounts.email.accounts.my-personal-email.imap.port}"
      set imap_user = "${config.accounts.email.accounts.my-personal-email.userName}"
      set imap_pass = "$(cat ${config.sops.secrets."my-email-password".path})"
      set smtp_url = "smtps://${config.accounts.email.accounts.my-personal-email.userName}@${config.accounts.email.accounts.my-personal-email.smtp.host}:${toString config.accounts.email.accounts.my-personal-email.smtp.port}/"
      set smtp_pass = "$(cat ${config.sops.secrets."my-email-password".path})"

      # Configure mailboxes
      mailboxes = "+INBOX" "+Sent Items" "+Drafts" "+Trash"

      # Optional: Sidebar configuration
      set sidebar_visible = yes
      set sidebar_width = 25
      set sidebar_format = "%D%?F? [%F]?%* %?N?%N/?%S"
    '';

    # Keybindings
    binds = [
      { map = "index"; key = "j"; action = "next-entry"; }
      { map = "index"; key = "k"; action = "previous-entry"; }
    ];

    # Enable sidebar support
    sidebar.enable = true;
  };
}
```

## 4. Cross-Machine Availability

Home-manager ensures that once these configurations are defined, they can be applied consistently across all your NixOS machines where Home-manager is deployed. This is achieved by simply including the relevant modules in each machine's `home.nix` or `flake.nix` configuration.

## 5. Security Considerations

- **`sops-nix`:** Emphasize the importance of `sops-nix` for encrypting sensitive data like email passwords in your Git repository.
- **GPG Integration:** Highlight the use of GPG for email signing and encryption, and how Home-manager facilitates its integration with clients like Thunderbird and Neomutt.
- **Permissions:** Ensure that secret files decrypted by `sops-nix` have appropriate file permissions (e.g., `mode = "0400"`) to prevent unauthorized access.

## 6. Conclusion

By leveraging Home-manager's declarative capabilities and integrating with `sops-nix`, email account management becomes reproducible, secure, and easily deployable across multiple NixOS machines, supporting both GUI and TUI clients.
