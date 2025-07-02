# Implementation Summary: Declarative Partitioning with Disko and Impermanence

This document summarizes the implementation steps taken to create a test-driven development workflow for a declarative partitioning scheme using Disko, with support for LUKS and impermanence.

## 1. Planning and Methodology

- **Initial Plan**: A detailed plan was created in `docs/reports/01-1-disko-plan.md` to outline the project setup, the TDD cycle, and the integration strategy.
- **TDD Methodology**: A formal TDD methodology was established in `docs/reports/00-instructions.md`, defining the "Red-Green-Refactor" cycle using `nix flake check` as the primary verification tool. This methodology was later refined based on `disko`'s own testing practices.

## 2. Project and Test Setup

1.  **Git Branch**: A new feature branch, `feature/disko-impermanence`, was created to isolate the development work.
2.  **Module Creation**:
    - `config/sys/modules/hardware/disko-test.nix`: A module containing the declarative disk layout for a test VM.
    - `config/sys/modules/impermanence.nix`: A module to handle system impermanence, including Btrfs subvolume rollback logic.
3.  **Test Library**:
    - `tests/lib.nix`: A flexible test library was created. It contains a `makeNixOSTest` helper for general NixOS tests and a `makeDiskoTest` helper specifically for testing `disko` configurations, based on `disko`'s own testing utilities.
4.  **Test Case**:
    - `tests/disko.nix`: The primary test file was created to use the `makeDiskoTest` helper from our library. It defines a test VM and a test script to verify the partitioning, encryption, and impermanence features.

## 3. Flake Configuration and Debugging

The path to a working "Red" test involved a detailed debugging cycle. The following issues were identified and resolved:

1.  **Invalid Import Path**:

    - **Problem**: The initial `nix flake check` failed with a `path ... does not exist` error, originating from an existing host configuration (`perseus-system.nix`).
    - **Resolution**: The invalid import `../sys/modules/systemd-suspend-touchpad-reset` was corrected to `../sys/modules/systemd-suspend-touchpad-reset.nix`.

2.  **Untracked Files in Flake**:

    - **Problem**: The flake evaluator could not find the newly created test files (`tests/disko.nix`, `tests/lib.nix`, etc.), resulting in `path ... does not exist` errors. This was because Nix flakes only include files tracked by Git.
    - **Resolution**: The new files were staged using `git add .` to make them visible to the flake.

3.  **Infinite Recursion with `pkgs`**:

    - **Problem**: An `infinite recursion encountered` error occurred. This was traced to a module (`disko-test.nix`) attempting to import `pkgs.disko.nixosModules.default` without `disko` being a formal input to the flake, creating a circular dependency.
    - **Resolution**: `disko` and `impermanence` were added as explicit inputs in `flake.nix`, and the modules were updated to import them directly from the flake inputs rather than from the `pkgs` set.

4.  **Missing Function Arguments (`lib`, `config`, `pkgs`, `disko`, `impermanence`)**:

    - **Problem**: A series of `function 'anonymous lambda' called without required argument` errors occurred. This happened because modules and test files were being imported without receiving all of their expected arguments.
    - **Resolution**: This required a multi-step fix, ensuring that the arguments were passed down correctly through the entire chain:
      - From `flake.nix` to `tests/disko.nix`.
      - From `tests/disko.nix` to `tests/lib.nix`.
      - From `tests/lib.nix` to the `makeDiskoTest` function.
      - From `makeDiskoTest` to the test VM's `nodes.machine` configuration.

5.  **Flake Input Updates**:

    - **Problem**: To ensure we were using the latest versions of our new dependencies, the flake inputs needed to be updated.
    - **Resolution**: The `nix flake update disko impermanence` command was used to update the `flake.lock` file for only the new inputs.

6.  **LUKS in Non-Interactive Environment**:

    - **Problem**: The test was hanging because the LUKS encryption required a password, which could not be entered in the non-interactive test environment.
    - **Resolution**: Inspired by the `disko` LUKS test example, a `settings.keyFile` was added to the LUKS configuration in `config/sys/modules/hardware/disko-test.nix`, and the `testScript` in `tests/lib.nix` was updated to create this key file before the test runs.

7.  **Incorrect Virtual Disk Size**:
    - **Problem**: The test was failing because the `makeDiskoTest` helper was creating a 4GB virtual disk by default, while the `disko` configuration was designed for a 25GB disk.
    - **Resolution**: The `makeDiskoTest` function in `tests/lib.nix` was modified to accept a `diskSize` argument, and `tests/disko.nix` was updated to pass `25 * 1024` to this argument.

## 4. Final Debugging and Resolution

The final stage of debugging successfully resolved the persistent evaluation errors, leading to a fully passing `nix flake check`. This section summarizes the last steps taken.

### The "Anonymous Lambda" Error

After a long debugging cycle, the core error was identified by running `nix eval` with `--show-trace`:

```
error: function 'anonymous lambda' called without required argument 'pkgs'
```

This error clearly indicated that a function was being called without the `pkgs` argument it required.

### Debugging and Resolution

The investigation quickly narrowed down the problem to the testing library and how it handled the Disko configuration.

1.  **Missing `pkgs` Argument**: The primary issue was in [`tests/testlib.nix`](tests/testlib.nix). The library checks if the provided `disko-config` is a function and calls it, but the original code only passed `lib` as an argument. Our Disko configuration ([`config/sys/modules/hardware/disko-test.nix`](config/sys/modules/hardware/disko-test.nix)) is a function that requires `pkgs`, which was causing the error.

    **Solution**: The function call was updated to pass `pkgs` alongside `lib`.

    ```nix
    // in tests/testlib.nix
    diskoConfigWithArgs =
      if builtins.isFunction importedDiskoConfig then
        importedDiskoConfig { inherit pkgs lib; } // Correctly passing pkgs
      else
        importedDiskoConfig;
    ```

2.  **Missing `disko` Module Import**: Fixing the first issue revealed a second one: `error: The option 'nodes.machine.disko' does not exist.`. This meant the `disko` NixOS module itself was not being imported into the test VM. The [`tests/testlib.nix`](tests/testlib.nix) file contained a commented-out placeholder where the import was needed.

    **Solution**: The `disko.nixosModules.disko` module, available from the flake input, was added to the `imports` list for the test VM.

    ```nix
    // in tests/testlib.nix
    imports = [
      disko.nixosModules.disko // This line was added
      testConfigBooted
    ];
    ```

### Conclusion

The test infrastructure, which correctly uses a double invocation of `makeTest` via a `makeTest'` helper function, was fundamentally sound. The errors were caused by incorrect configuration being passed _into_ this structure.

With these two targeted fixes in [`tests/testlib.nix`](tests/testlib.nix), all evaluation errors were resolved, and the `nix flake check` for the `disko-impermanence-test` now completes successfully. This brings the TDD cycle to a "Green" state, confirming the declarative partitioning and impermanence features are working as expected within the VM test environment.
