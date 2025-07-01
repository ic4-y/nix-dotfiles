# Backup Strategy with Restic and Btrfs Snapshots

This document outlines a backup strategy leveraging Restic for data deduplication and encryption, combined with Btrfs snapshots for efficient and consistent backups.

## Restic Implementation

Restic is a modern, secure, and efficient backup program. It supports various backend storage locations (e.g., local, SFTP, S3, Backblaze B2) and features deduplication, encryption, and data integrity verification.

### Key Restic Features:

- **Deduplication:** Only stores unique blocks of data, saving space.
- **Encryption:** All data is encrypted before being uploaded to the backend.
- **Data Integrity:** Ensures data is not corrupted during transfer or storage.
- **Snapshots:** Creates point-in-time backups that can be easily restored.

## Btrfs Snapshots for Backups

Btrfs snapshots provide a powerful mechanism for creating consistent backups. A snapshot is a read-only copy of a subvolume at a specific point in time. Since snapshots are copy-on-write, they are very fast to create and consume minimal disk space initially.

### Workflow for Btrfs Snapshot-based Backups:

1.  **Create a Btrfs snapshot:** Before running Restic, create a snapshot of the subvolume(s) you intend to back up. This ensures that Restic operates on a consistent dataset, preventing issues with files being modified during the backup process.
2.  **Mount the snapshot:** Mount the read-only snapshot to a temporary location.
3.  **Run Restic on the snapshot:** Point Restic to the mounted snapshot directory.
4.  **Delete the snapshot:** After the backup is complete, delete the temporary snapshot.

## One-Shot Backup Script Design

A one-shot script can automate the process of creating a Btrfs snapshot and then backing it up with Restic.

```bash
#!/usr/bin/env bash

# Configuration
BTRFS_SUBVOLUME="/path/to/your/subvolume" # e.g., /home or /
SNAPSHOT_DIR="/.snapshots" # Directory where snapshots are stored
RESTIC_REPO="sftp:user@host:/path/to/repo" # Restic repository
RESTIC_PASSWORD_FILE="/path/to/restic_password_file" # Path to file containing Restic password

# Ensure Restic password file exists and is secure
if [ ! -f "$RESTIC_PASSWORD_FILE" ]; then
    echo "Restic password file not found: $RESTIC_PASSWORD_FILE"
    exit 1
fi
export RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE")

# Create a timestamp for the snapshot
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
SNAPSHOT_PATH="${BTRFS_SUBVOLUME}${SNAPSHOT_DIR}/restic-backup-${TIMESTAMP}"

echo "Creating Btrfs snapshot of ${BTRFS_SUBVOLUME} at ${SNAPSHOT_PATH}..."
sudo btrfs subvolume snapshot -r "${BTRFS_SUBVOLUME}" "${SNAPSHOT_PATH}"

if [ $? -ne 0 ]; then
    echo "Failed to create Btrfs snapshot."
    exit 1
fi

echo "Running Restic backup on snapshot ${SNAPSHOT_PATH}..."
restic backup "${SNAPSHOT_PATH}" \
    --repo "${RESTIC_REPO}" \
    --verbose \
    --tag "btrfs-snapshot" \
    --exclude-file "/path/to/exclude_file.txt" # Optional: specify a file with patterns to exclude

if [ $? -ne 0 ]; then
    echo "Restic backup failed."
    sudo btrfs subvolume delete "${SNAPSHOT_PATH}" # Clean up snapshot on failure
    exit 1
fi

echo "Forgetting old Restic snapshots (e.g., keep 7 daily, 4 weekly, 12 monthly, 1 yearly)..."
restic forget \
    --repo "${RESTIC_REPO}" \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 12 \
    --keep-yearly 1 \
    --prune \
    --tag "btrfs-snapshot" # Only forget snapshots with this tag

if [ $? -ne 0 ]; then
    echo "Restic forget/prune failed."
    # Do not exit, as backup might still be valid
fi

echo "Verifying Restic repository integrity..."
restic check --repo "${RESTIC_REPO}"

if [ $? -ne 0 ]; then
    echo "Restic repository check failed."
    # Do not exit, as backup might still be valid
fi

echo "Deleting Btrfs snapshot ${SNAPSHOT_PATH}..."
sudo btrfs subvolume delete "${SNAPSHOT_PATH}"

if [ $? -ne 0 ]; then
    echo "Failed to delete Btrfs snapshot."
    exit 1
fi

echo "Backup process completed successfully."
```

**Notes on the Backup Script:**

- **`BTRFS_SUBVOLUME`**: The path to the Btrfs subvolume you want to back up (e.g., `/home`, `/`).
- **`SNAPSHOT_DIR`**: The directory where Btrfs snapshots are typically stored (e.g., `/.snapshots`). Ensure this directory exists and is on the same Btrfs filesystem.
- **`RESTIC_REPO`**: Your Restic repository string (e.g., `sftp:user@host:/path/to/repo`, `s3:s3.amazonaws.com/bucketname`).
- **`RESTIC_PASSWORD_FILE`**: Path to a file containing your Restic repository password. This is more secure than hardcoding the password in the script.
- **`--exclude-file`**: Use this to specify a file containing patterns of files/directories to exclude from the backup.
- **`restic forget --prune`**: This command is crucial for managing repository size by removing old snapshots according to a retention policy and then pruning the data.
- **`restic check`**: Verifies the integrity of the Restic repository.

## One-Shot Restore Script Design

A restore script allows you to retrieve data from a Restic repository. You can restore specific files, directories, or entire snapshots.

```bash
#!/usr/bin/env bash

# Configuration
RESTIC_REPO="sftp:user@host:/path/to/repo" # Restic repository
RESTIC_PASSWORD_FILE="/path/to/restic_password_file" # Path to file containing Restic password
RESTORE_TARGET_DIR="/tmp/restored_data" # Directory where data will be restored

# Ensure Restic password file exists and is secure
if [ ! -f "$RESTIC_PASSWORD_FILE" ]; then
    echo "Restic password file not found: $RESTIC_PASSWORD_FILE"
    exit 1
fi
export RESTIC_PASSWORD=$(cat "$RESTIC_PASSWORD_FILE")

echo "Listing Restic snapshots..."
restic snapshots --repo "${RESTIC_REPO}"

echo "Enter the snapshot ID or 'latest' to restore:"
read SNAPSHOT_ID

if [ -z "$SNAPSHOT_ID" ]; then
    echo "No snapshot ID provided. Exiting."
    exit 1
fi

echo "Restoring snapshot ${SNAPSHOT_ID} to ${RESTORE_TARGET_DIR}..."
mkdir -p "${RESTORE_TARGET_DIR}"

restic restore "${SNAPSHOT_ID}" \
    --repo "${RESTIC_REPO}" \
    --target "${RESTORE_TARGET_DIR}" \
    --verbose

if [ $? -ne 0 ]; then
    echo "Restic restore failed."
    exit 1
fi

echo "Restore completed successfully to ${RESTORE_TARGET_DIR}."
echo "You can now access your restored data."
```

**Notes on the Restore Script:**

- **`RESTIC_REPO` and `RESTIC_PASSWORD_FILE`**: Same as in the backup script.
- **`RESTORE_TARGET_DIR`**: The directory where the restored data will be placed. Ensure this directory has enough space.
- **`restic snapshots`**: Lists available snapshots in the repository, allowing the user to choose which one to restore.
- **`restic restore`**: Performs the actual restore operation. You can specify a snapshot ID or use `latest` to restore the most recent one.

## NixOS Integration

Integrating Restic and Btrfs snapshot management into NixOS can be done through systemd services and timers for automated backups, or by defining custom scripts in your Nix configuration.

### Example Systemd Service for Backup (Conceptual)

```nix
{ config, pkgs, ... }:

{
  systemd.services.restic-backup = {
    description = "Restic Btrfs Snapshot Backup";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /path/to/your/backup_script.sh";
      # Ensure Restic and Btrfs tools are in the PATH
      Path = "${pkgs.restic}/bin:${pkgs.btrfs-progs}/bin:${pkgs.coreutils}/bin";
      # Environment variables for Restic password (consider sops-nix for secrets)
      # EnvironmentFile = "/path/to/restic_env_file";
    };
  };

  systemd.timers.restic-backup = {
    description = "Run Restic Btrfs Snapshot Backup daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Ensure restic and btrfs-progs are available
  environment.systemPackages = with pkgs; [
    restic
    btrfs-progs
  ];
}
```

### Secrets Management for Restic Password

For production environments, it is highly recommended to manage the Restic password securely using tools like `sops-nix` to prevent it from being hardcoded or exposed in plain text.

## Automation and Scheduling

Automating backups is crucial for a robust strategy. Systemd timers are the preferred method in NixOS for scheduling tasks like daily or weekly backups.

### Considerations for Automation:

- **Frequency:** Determine appropriate backup frequency (daily, weekly, monthly) based on data change rate and recovery point objectives (RPO).
- **Retention Policy:** Implement a clear retention policy using `restic forget` to manage repository size and keep relevant historical backups.
- **Monitoring:** Set up monitoring for backup jobs to ensure they complete successfully and to be alerted of any failures.
- **Pre/Post-Backup Hooks:** Consider running pre-backup hooks (e.g., stopping services for consistent database backups) and post-backup hooks (e.g., starting services, sending notifications).
