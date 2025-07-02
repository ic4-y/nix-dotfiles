# Methodology: Test-Driven Development for NixOS Configuration

This document defines the standard Test-Driven Development (TDD) workflow for making changes to the NixOS configuration in this repository, based on the modern NixOS testing framework integrated with flakes.

## Core Principles

1.  **Test First**: No feature is implemented or modified without a corresponding test case written first.
2.  **Isolation**: All new features are developed in separate Git branches.
3.  **Verifiability**: Every change must be verifiable through automated testing using `nix flake check`.
4.  **Modularity**: Configurations should be modular and reusable across different hosts where applicable.

## The TDD Workflow

The development process follows a "Red-Green-Refactor" cycle, now adapted for the `nix flake check` command.

### Step 1: Create a Test Helper (One-time setup)

We will use a helper function in `tests/lib.nix` to import the testing framework from `nixpkgs` and pass flake inputs and outputs to our tests.

```nix
# tests/lib.nix
test: { pkgs, self }:
let
  inherit (pkgs) lib;
  nixos-lib = import (pkgs.path + "/nixos/lib") {};
in
(nixos-lib.runTest {
  hostPkgs = pkgs;
  defaults.documentation.enable = lib.mkDefault false;
  node.specialArgs = { inherit self; };
  imports = [ test ];
}).config.result
```

### Step 2: Write a Failing Test (Red)

1.  **Create a new NixOS test file** (e.g., `tests/my-feature.nix`). This file will use the `tests/lib.nix` helper.
2.  **Define the test `nodes`**: Create one or more test VMs and use `self.nixosModules.my-module` to import the module being tested.
3.  **Write the `testScript`**: Write assertions in the Python-based test script that define the feature's success criteria.
4.  **Expose the test in `flake.nix`**: Add the test to the `checks` output in `flake.nix`.

    ```nix
    # flake.nix
    # ...
    checks = forAllSystems (system: let
      checkArgs = {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit self;
      };
    in {
      my-feature-test = import ./tests/my-feature.nix checkArgs;
    });
    # ...
    ```

5.  **Run the test**: Execute `nix flake check -L` and confirm that it fails as expected.

### Step 3: Implement the Feature (Green)

1.  Create or modify the NixOS module file(s).
2.  Write the _minimum_ amount of code necessary to make the test pass.
3.  Continuously run `nix flake check -L` until the test succeeds.

### Step 4: Refactor

1.  With a passing test, safely refactor your code for clarity, modularity, and maintainability.
2.  Expose options via `lib.mkOption` to make the module more generic.
3.  Refine the test itself to be more robust.

### Interactive Debugging

For complex tests, interactive debugging is invaluable.

1.  **Build the test driver**:
    ```bash
    nix build .#checks.x86_64-linux.<test-name>.driver
    ```
2.  **Run the driver interactively**:
    ```bash
    ./result/bin/nixos-test-driver --interactive
    ```
3.  This provides a Python REPL where you can execute test commands one by one (e.g., `node1.wait_for_unit("my-service")`) or even get a shell inside the VM with `node1.shell_interact()`.

This revised methodology will be our guide for the rest of this implementation.
