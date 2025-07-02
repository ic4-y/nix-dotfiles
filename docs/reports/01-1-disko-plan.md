# Plan: Declarative Partitioning with Disko, LUKS, and Impermanence

This document outlines the detailed, step-by-step plan to implement a declarative disk partitioning scheme using Disko, with support for LUKS full-disk encryption and system impermanence.

## 1. Project Setup

1.  **Create Git Branch**:

    - A new branch will be created from `main`: `feature/disko-impermanence`.

2.  **Create File Structure**:
    - Host-specific disko configurations will be created (e.g., `config/sys/hardware/disko-perseus.nix`).
    - A new NixOS VM test for validation: `tests/disko.nix`.

## 2. The Test-Driven Cycle

### Step 2.1: Write the Failing VM Test (Red)

The test in `tests/disko.nix` will define a NixOS VM with a 25GB virtual disk and will perform the following checks:

- **Partitioning**:
  - Assert that the disk is partitioned according to the `disko` configuration.
  - Check for the existence of the EFI (`/dev/disk/by-label/boot`) and LUKS (`/dev/disk/by-label/luks`) partitions.
- **Encryption & Filesystem**:
  - Assert that the LUKS partition is successfully unlocked and `/dev/mapper/cryptroot` exists.
  - Verify that the Btrfs filesystem is created on `cryptroot`.
- **Mount Points**:
  - Check that all Btrfs subvolumes (`/`, `/home`, `/nix`, `/persist`, `/var/log`) are mounted at their correct locations.
- **Impermanence**:
  - The test will write a unique file to `/persist/etc/machine-id`.
  - It will then reboot the VM.
  - After reboot, it will assert that the file `/etc/machine-id` exists and its content matches what was written, verifying that the persistent state was correctly linked from `/persist`.

### Step 2.2: Implement the Disko Configuration (Green)

In `config/sys/hardware/disko-perseus.nix`, we will:

1.  **Add Disko to Imports**: Ensure `disko` is available in the system configuration.
2.  **Define the Disko Configuration**:
    - Translate the Nix code from `docs/01-disko-declarative-partitioning.md` into this file.
    - The configuration will be tailored for the `perseus` host initially. The disk device will be set to `/dev/vda` for the test VM.
3.  **Integrate Impermanence**:
    - Import and configure the `impermanence` module to create persistent directories and files by linking them from the `/persist` subvolume. Key files to persist include:
      - `/etc/machine-id`
      - `/var/lib/systemd`
      - `/var/log`
4.  **Run the Test**: The VM test will import `config/sys/hardware/disko-perseus.nix`. We will iteratively run the test until it passes.

### Step 2.3: Refactor

1.  **Generalize for other hosts**: To avoid duplication, we can create a common `disko-lib.nix` that contains a function to generate the configuration. Each host-specific file (`disko-perseus.nix`, `disko-archon.nix`, etc.) can then call this function with its specific parameters (like the disk device).
2.  **Code Cleanup**: Add comments, improve formatting, and ensure the code is clear and maintainable.
3.  **Test Refinement**: Enhance the VM test with more specific checks, such as verifying filesystem mount options (`compress=zstd`, `noatime`).

## 3. Integration and Documentation

1.  **Host Integration**:
    - The plan will conclude with instructions on how to import `./config/sys/hardware/disko-perseus.nix` into the `config/hosts/perseus-system.nix` configuration.
    - It will also specify which existing filesystem/boot configurations need to be removed or disabled to prevent conflicts.
    - Similar steps will be outlined for `archon` and `cadmus`.
2.  **Documentation**:
    - A final report will be created at `docs/reports/01-disko-impermanence-partitioning.md` to reflect the final implementation and include a reference to the VM test.

---
