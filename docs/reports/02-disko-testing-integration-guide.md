# Integration Guide: NixOS VM Testing for Disko Configurations

This document provides a comprehensive guide on how to integrate the `testlib.nix` library into a Nix flake-based project to enable robust, automated VM testing for `disko` declarative disk configurations.

## 1. Overview

The `testlib.nix` library provides a reusable helper function, `makeDiskoTest`, that abstracts away the boilerplate of setting up a NixOS VM test. It allows you to test a `disko` configuration against a virtual machine, verifying that partitioning, formatting, and mounting work as expected before applying the configuration to a physical machine.

## 2. Integration Steps

Follow these steps to integrate the testing library into your own project.

### Step 1: Copy the Test Library

Copy the `tests/testlib.nix` file into your own project's `tests/` directory. This file is self-contained and provides the core testing logic.

### Step 2: Add Flake Inputs

Your `flake.nix` must include the necessary inputs for `disko` and any other modules you intend to test (like `impermanence`).

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    # ... other inputs
  };

  outputs = { self, nixpkgs, disko, impermanence, ... }@inputs: {
    # ...
  };
}
```

### Step 3: Create a Disko Configuration Module

Create a standard NixOS module that defines your declarative disk layout using `disko`. This module should be a function that accepts `pkgs` and `lib` as arguments.

**Example**: `config/disko-layouts/my-server.nix`

```nix
{ pkgs, lib, ... }:

{
  disko.devices = {
    disk.vda = {
      type = "disk";
      device = "/dev/vda"; # This will be replaced by the test runner
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes = {
                "/root" = { mountpoint = "/"; };
                "/home" = { mountpoint = "/home"; };
                "/nix" = { mountpoint = "/nix"; };
              };
            };
          };
        };
      };
    };
  };
}
```

### Step 4: Create a Test Case

Create a new file in your `tests/` directory that defines a specific test case. This file will import `testlib.nix` and call the `makeDiskoTest` function.

**Example**: `tests/my-server-test.nix`

```nix
{ pkgs, self, lib, disko, ... }@args:

let
  # Import the test library, passing the required inputs
  testLib = import ./testlib.nix { inherit pkgs disko lib; };
in
# Call the test generator
testLib.makeDiskoTest {
  # --- Required Arguments ---
  name = "my-server-test";
  disko-config = ../config/disko-layouts/my-server.nix; # Path to your disko module

  # --- Optional Arguments ---
  # Pass any flake inputs your disko module might need
  inherit pkgs disko;

  # Add extra shell commands to run inside the VM after disko runs
  extraTestScript = ''
    machine.succeed("btrfs subvolume list / | grep -qs 'path root$'");
    machine.succeed("test -f /boot/EFI/BOOT/BOOTX64.EFI");
  '';

  # Set the virtual disk size (in MB) to match your configuration
  # diskSize = 25 * 1024; # 25 GB
}
```

### Step 5: Add the Check to Your Flake

Finally, add the test case to the `checks` output in your `flake.nix`. This makes it runnable with `nix flake check`.

```nix
# flake.nix
{
  # ... inputs
  outputs = { self, nixpkgs, disko, impermanence, ... }@inputs: {
    # ... other outputs

    checks.x86_64-linux = {
      # Import your test file, passing all the necessary flake inputs
      my-server-disko-test = import ./tests/my-server-test.nix {
        inherit pkgs self lib disko impermanence;
      };
    };
  };
}
```

## 3. Running the Test

With the integration complete, you can run your test using the standard Nix command:

```shell
nix flake check -L
```

Nix will build and run the VM, execute the `disko` configuration, and run your `extraTestScript` to verify the results. The result will be cached, so subsequent runs will be instantaneous unless you change one of the inputs (e.g., the test file or the `disko` configuration).

## 4. Conclusion

This library provides a powerful, declarative, and reproducible way to ensure your disk configurations are correct before deploying them to real hardware. By integrating it into your development workflow, you can prevent common partitioning errors and increase confidence in your system configurations.
