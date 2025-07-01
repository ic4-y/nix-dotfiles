# Disko-based Configuration for Declarative Partitioning

This document details a declarative partitioning strategy for NixOS using Disko, focusing on a setup with full disk encryption (LUKS), Btrfs filesystem, and support for impermanence.

## Disko Configuration for LUKS and Btrfs

The following Disko configuration defines a single NVMe drive (`/dev/nvme0n1`) with a GPT partition table. It includes an EFI System Partition (ESP) and a LUKS-encrypted partition that encapsulates a Btrfs filesystem with multiple subvolumes.

```nix
{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "boot";
              name = "ESP";
              size = "512M";
              type = "EF00"; # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };
            luks = {
              size = "100%";
              label = "luks";
              content = {
                type = "luks";
                name = "cryptroot";
                extraOpenArgs = [
                  "--allow-discards"
                  "--perf-no_read_workqueue"
                  "--perf-no_write_workqueue"
                ];
                # https://0pointer.net/blog/unlocking-luks2-volumes-with-tpm2-fido2-pkcs11-security-hardware-on-systemd-248.html
                settings = {crypttabExtraOpts = ["fido2-device=auto" "token-timeout=10"];};
                content = {
                  type = "btrfs";
                  extraArgs = ["-L" "nixos" "-f"];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = ["subvol=root" "compress=zstd" "noatime"];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = ["subvol=home" "compress=zstd" "noatime"];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = ["subvol=nix" "compress=zstd" "noatime"];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = ["subvol=persist" "compress=zstd" "noatime"];
                    };
                    "/log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["subvol=log" "compress=zstd" "noatime"];
                    };
                    "/swap" = {
                      mountpoint = "/swap";
                      swap.swapfile.size = "64G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
}
```

### Breakdown of the Disko Configuration:

- **`disk.nvme0n1`**: This block targets a specific disk, `/dev/nvme0n1`. You should adjust the `device` path to match your system's primary drive.
- **`partitions.ESP`**:
  - `label = "boot"` and `name = "ESP"`: Assigns labels for identification.
  - `size = "512M"`: Allocates 512 megabytes for the EFI System Partition.
  - `type = "EF00"`: Specifies the partition type as EFI System Partition.
  - `content.filesystem`: Defines the filesystem within this partition.
    - `format = "vfat"`: Formats the partition as FAT32.
    - `mountpoint = "/boot"`: Sets the mount point for the EFI partition.
    - `mountOptions = ["defaults"]`: Uses default mount options.
- **`partitions.luks`**: This defines the LUKS-encrypted partition that will contain the Btrfs filesystem.
  - `size = "100%"`: Allocates the remaining space on the disk to this partition.
  - `label = "luks"`: Assigns a label to the LUKS partition.
  - `content.luks`: Configures the LUKS encryption.
    - `name = "cryptroot"`: The name assigned to the decrypted LUKS volume, which will be accessible at `/dev/mapper/cryptroot`.
    - `extraOpenArgs = ["--allow-discards" "--perf-no_read_workqueue" "--perf-no_write_workqueue"]`: These arguments are passed to `cryptsetup open`. `--allow-discards` enables TRIM/discard support for SSDs, which is important for performance and wear leveling with encryption. The `perf-no_read_workqueue` and `perf-no_write_workqueue` options can optimize performance by disabling certain workqueues.
    - `settings = {crypttabExtraOpts = ["fido2-device=auto" "token-timeout=10"];}`: This integrates FIDO2 device support (e.g., YubiKey) for unlocking the LUKS volume during boot. `fido2-device=auto` attempts to auto-detect a FIDO2 device, and `token-timeout=10` sets a timeout for token interaction.
- **`content.btrfs`**: This block defines the Btrfs filesystem within the LUKS-encrypted volume.
  - `extraArgs = ["-L" "nixos" "-f"]`: These arguments are passed to `mkfs.btrfs`. `-L "nixos"` sets the filesystem label to "nixos", allowing it to be referenced by label. `-f` forces the creation of the filesystem.
  - **`subvolumes`**: Btrfs subvolumes are created to organize different parts of the system, facilitating impermanence and flexible data management.
    - `/root`: Mounted at `/`, serving as the root filesystem.
    - `/home`: Mounted at `/home` for user home directories.
    - `/nix`: Mounted at `/nix` for the Nix store, where all Nix packages and derivations reside.
    - `/persist`: Mounted at `/persist`, this subvolume is crucial for impermanence. It stores data that needs to persist across reboots, such as `/etc` configurations, `/var` data, and other mutable system states.
    - `/log`: Mounted at `/var/log` to ensure logs persist across reboots, even with an impermanent root.
    - `/swap`: Configures a 64GB swapfile within a dedicated Btrfs subvolume, mounted at `/swap`.
  - `mountOptions = ["subvol=..." "compress=zstd" "noatime"]`: Common mount options applied to the Btrfs subvolumes. `compress=zstd` enables Zstd compression, which offers a good balance of compression ratio and performance. `noatime` disables the updating of file access times, which can improve performance and reduce disk writes.
- **`fileSystems."/persist".neededForBoot = true;`**: This ensures that the `/persist` subvolume is mounted and available early in the boot process, which is essential for the system to function correctly with impermanence.
- **`fileSystems."/var/log".neededForBoot = true;`**: Similar to `/persist`, this ensures the `/var/log` subvolume is available early for logging.

## Integration with NixOS Configuration

To incorporate this Disko configuration into your NixOS system, save the above configuration as `disko.nix` (or any other `.nix` file) and import it into your main `configuration.nix` or host-specific configuration:

```nix
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix # Assuming the Disko configuration is in disko.nix
  ];
}
```

## Hibernate Configuration

For systems utilizing a swapfile within a LUKS-encrypted Btrfs subvolume, specific boot parameters are required to enable hibernation. The `resume_offset` parameter is critical as the swap is not on a separate partition but within the Btrfs filesystem.

```nix
{
  boot = {
    kernelParams = [
      "resume_offset=533760" # This offset is specific to the example; calculate for your system
    ];
    resumeDevice = "/dev/disk/by-label/nixos";
  };
}
```

The `resume_offset` value must be precisely calculated for your specific swapfile location within the Btrfs volume. An incorrect offset will prevent hibernation from working. Refer to the [Arch Linux wiki on Suspend and Hibernate](https://wiki.archlinux.org/title/Suspend_and_hibernate#Swap_file_on_Btrfs) for detailed instructions on how to determine this offset.

## LUKS Decryption Methods

### Passphrase Decryption

By default, LUKS volumes are protected by a passphrase. During system boot, you will be prompted to enter this passphrase to unlock the encrypted volume. This is the most common and straightforward method for decryption.

### FIDO2 Decryption Setup

To enable unlocking your LUKS-encrypted drive using a FIDO2 security key (e.g., YubiKey), you need to enroll the device with `systemd-cryptenroll`.

1.  **Execute the enrollment command:**
    ```bash
    sudo -E -s systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2
    ```
    Replace `/dev/nvme0n1p2` with the actual path to your LUKS partition.
2.  **Interact with your FIDO2 device:** Follow the prompts, which typically involve touching or interacting with your security key.

Once enrolled, your FIDO2 device can be used to decrypt the LUKS volume during boot. Be aware that using a FIDO2 device for decryption might introduce a slight delay in the boot process as the system waits for device interaction.
