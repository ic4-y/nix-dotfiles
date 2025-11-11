# Bubblewrap Isolation Implementation Plan for NixOS

## Objective

Implement Bubblewrap-based isolation for selected applications on NixOS, providing strong sandboxing and containment using declarative configuration.

## Steps to Integrate Bubblewrap Isolation

### 1. Identify Target Applications

- List applications requiring isolation (e.g., browsers, messaging clients, custom tools).
- Document security and privacy requirements for each.

### 2. Add Bubblewrap to System Packages

```nix
environment.systemPackages = with pkgs; [
  bubblewrap
];
```

### 3. Create Bubblewrap Wrapper Scripts

- For each target app, create a wrapper script that launches the app inside a Bubblewrap sandbox.
- Example for Firefox:

```bash
#!/usr/bin/env bash
exec bwrap \
  --dev-bind / / \
  --proc /proc \
  --tmpfs /tmp \
  --ro-bind /etc/resolv.conf /etc/resolv.conf \
  --unshare-pid --unshare-net --unshare-uts --unshare-ipc --unshare-mount \
  --bind $HOME/.mozilla /home/user/.mozilla \
  -- \
  firefox "$@"
```

### 4. Integrate with NixOS Configuration

- Place wrapper scripts in `/etc/local/bin` or a custom directory.
- Update desktop entries or systemd services to use the wrapper.

### 5. Optional: Combine with Network Namespace Isolation

- Use systemd or `ip netns` to create a dedicated network namespace.
- Launch Bubblewrap with `--share-net` and `--namespace network:<ns>` for network isolation.

### 6. Manage Persistent Data

- Bind-mount necessary config/data directories (e.g., browser profiles, cache).
- Use read-only or tmpfs mounts for sensitive paths.

### 7. Test and Validate

- Launch each isolated app and verify containment (filesystem, network, process).
- Check for functionality regressions and address missing resources.

### 8. Document Maintenance and Updates

- Maintain a list of isolated apps and wrapper scripts.
- Update scripts and NixOS config as apps or requirements change.

## References

- [Bubblewrap documentation](https://github.com/containers/bubblewrap)
- [NixOS Bubblewrap module](https://search.nixos.org/packages?query=bubblewrap)
- [Systemd network namespace docs](https://www.freedesktop.org/software/systemd/man/systemd-nspawn.html)
