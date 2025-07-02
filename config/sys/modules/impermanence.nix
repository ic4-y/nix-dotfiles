{ pkgs, lib, ... }:

{
  # Impermanence configuration
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc" # For /etc/machine-id and other configurations
      "/var" # For /var/lib/systemd, etc. (excluding /var/log which is a separate subvolume)
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  # Btrfs subvolume rollback for the root filesystem
  boot.initrd.postResumeCommands = lib.mkAfter ''
    mkdir -p /btrfs_tmp
    # Mount the top-level Btrfs volume by its label
    # Assuming the Btrfs filesystem is labeled "nixos" as per the disko config
    mount -L nixos /btrfs_tmp

    # Check if the 'root' subvolume exists and move it to 'old_roots'
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    # Function to recursively delete Btrfs subvolumes
    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    # Clean up old root snapshots (older than 30 days)
    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30 -type d); do
        if [[ "$i" != "/btrfs_tmp/old_roots/" ]]; then # Avoid deleting the old_roots directory itself
            delete_subvolume_recursively "$i"
        fi
    done

    # Create a new 'root' subvolume
    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';
}
