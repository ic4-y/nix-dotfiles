# Monitoring Strategy with Prometheus

This document outlines a comprehensive monitoring strategy for NixOS machines using Prometheus for metric collection and aggregation. It covers the setup of Node Exporter for host-level metrics, the configuration of a Prometheus server for centralized monitoring, and specific considerations for security-related events and NVMe drive health.

## Prometheus Setup

Prometheus is an open-source monitoring system with a dimensional data model, flexible query language (PromQL), and an alert manager. It pulls metrics from configured targets at specified intervals.

### Key Components:

- **Prometheus Server:** The core component that scrapes and stores time-series data.
- **Exporters:** Agents that expose metrics from various systems and applications in a Prometheus-compatible format.
- **Alertmanager:** Handles alerts sent by the Prometheus server, deduplicating, grouping, and routing them to appropriate notification channels.
- **Grafana (Optional):** A popular open-source platform for data visualization and dashboards, often used with Prometheus.

## Setting up Node Exporter and NVMe Monitoring

Node Exporter is a Prometheus exporter for machine metrics. It exposes a wide range of hardware and OS metrics. For NVMe drive health, additional tools or collectors might be necessary.

### NixOS Configuration for Node Exporter

To enable and configure Node Exporter on a NixOS machine, add the following to your `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  services.prometheus.exporters.node = {
    enable = true;
    # Node Exporter listens on 0.0.0.0:9100 by default
    # Optional: Enable specific collectors or disable others
    # collectors = {
    #   diskstats = true;
    #   filesystem = true;
    #   nvme = true; # Check if this collector is available and sufficient for your needs
    #   # For more detailed NVMe SMART data, consider smartctl_exporter or custom textfile collector
    # };
  };

  # Firewall configuration will be handled via Nebula VPN interface later.
  # Example: networking.firewall.interfaces."nebula0".allowedTCPPorts = [ 9100 ];

  # For NVMe SMART data, you might need smartmontools and a custom exporter or textfile collector.
  # Example for smartmontools:
  # services.smartd.enable = true;
  # services.smartd.devices = [ "/dev/nvme0" ]; # Adjust device path
  # You could then use a textfile collector to expose smartctl output as metrics.
}
```

After rebuilding and activating the system, Node Exporter will be running. You can verify this by accessing `http://your-machine-ip:9100/metrics`. For detailed NVMe health, you might need to explore `smartctl_exporter` or create custom scripts that parse `smartctl` output and expose it via Node Exporter's textfile collector.

## Prometheus Server Configuration

The Prometheus server needs to be configured to scrape metrics from the Node Exporters running on your machines.

### NixOS Configuration for Prometheus Server

On the machine designated as your Prometheus server, add the following to its `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  services.prometheus = {
    enable = true;
    port = 9090; # Default Prometheus web UI port

    # Configuration for scraping targets
    scrapeConfigs = [
      {
        job_name = "nixos_nodes";
        static_configs = [
          {
            targets = [
              "your-node1-ip:9100"
              "your-node2-ip:9100"
              "your-node3-ip:9100"
              # Add more targets as needed
            ];
          }
        ];
      }
      # Add other scrape configurations for different jobs/exporters
    ];

    # Optional: Alertmanager configuration
    # alertmanager = {
    #   enable = true;
    #   url = "http://localhost:9093"; # Or the Alertmanager's address
    # };

    # Optional: Storage retention
    # storage.retention = "30d"; # Keep data for 30 days
  };

  # Firewall configuration will be handled via Nebula VPN interface later.
  # Example: networking.firewall.interfaces."nebula0".allowedTCPPorts = [ 9090 ];
}
```

Replace `your-nodeX-ip:9100` with the actual IP addresses or hostnames of your NixOS machines running Node Exporter.

## Aggregating Metrics

Prometheus automatically aggregates metrics by job and instance. For more complex aggregations or custom metrics, you can use PromQL (Prometheus Query Language) and Recording Rules.

## Alerting for Security Events and NVMe Degradation

Prometheus integrates with Alertmanager to handle alerts. You can define alerting rules based on PromQL expressions.

### Integrating Auditd for Security Events

To monitor security-related events using `auditd` and expose them to Prometheus, you can use a log-to-metrics exporter or a custom script. A common approach is to use `auditd` to log events and then process these logs.

#### NixOS Configuration for Auditd

```nix
{ config, pkgs, ... }:

{
  services.auditd.enable = true;
  # Define audit rules here, e.g., for failed SSH logins, sudo attempts, file access
  # services.auditd.rules = [
  #   "-w /var/log/auth.log -p wa -k auth_log_changes"
  #   "-a always,exit -F arch=b64 -S execve -k exec_calls"
  #   "-a always,exit -F arch=b32 -S execve -k exec_calls"
  #   "-w /etc/passwd -p wa -k passwd_changes"
  #   "-w /etc/shadow -p wa -k shadow_changes"
  #   "-w /etc/sudoers -p wa -k sudoers_changes"
  # ];

  # You would then need a mechanism to parse audit logs and expose metrics.
  # This could be a custom script using Node Exporter's textfile collector,
  # or a dedicated log exporter like promtail (if using Loki for logs)
  # or a custom exporter that reads audit logs and converts them to Prometheus metrics.
}
```

After configuring `auditd` rules, you'll need a way to convert these audit events into Prometheus metrics. This often involves:

1.  **Custom Script with Textfile Collector:** A script that parses `audit.log` (or `augen.log`) for specific events and writes Prometheus-formatted metrics to a file in Node Exporter's textfile collector directory.
2.  **Log Exporter:** Tools like `promtail` (part of the Loki stack) can scrape logs and send them to Loki, which can then be queried by Grafana. While not directly Prometheus metrics, this provides a powerful logging and alerting solution. For direct Prometheus integration, a custom log parser is usually needed.

### Example Alerting Rules

Here are conceptual examples of alerting rules for security events and NVMe degradation. These would be defined in your Prometheus server's configuration.

#### Security-Related Alerts (Conceptual, based on custom metrics from audit logs)

Assuming you have a custom exporter or textfile collector generating metrics like `security_failed_ssh_logins_total` or `security_sudo_attempts_total`.

```yaml
groups:
  - name: security_alerts
    rules:
      - alert: HighFailedSSHLogins
        expr: increase(security_failed_ssh_logins_total[5m]) > 10
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High number of failed SSH login attempts on {{ $labels.instance }}"
          description: "Instance {{ $labels.instance }} has seen {{ $value }} failed SSH login attempts in the last 5 minutes."

      - alert: SudoAttemptsDetected
        expr: increase(security_sudo_attempts_total[5m]) > 0
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "Sudo attempts detected on {{ $labels.instance }}"
          description: "Sudo attempts have been made on {{ $labels.instance }} in the last 5 minutes."
```

#### NVMe Drive Degradation Alerts (Conceptual, based on Node Exporter or smartctl_exporter metrics)

Assuming metrics like `node_disk_smart_health_status` (from Node Exporter if enabled, or `smartctl_exporter`) or specific SMART attributes are exposed.

```yaml
groups:
  - name: nvme_health_alerts
    rules:
      - alert: NvmeDriveCriticalHealth
        expr: node_disk_smart_health_status{device="nvme0n1"} == 0 # Assuming 0 means critical/failed
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "NVMe drive {{ $labels.device }} on {{ $labels.instance }} is in critical health"
          description: "The NVMe drive {{ $labels.device }} on {{ $labels.instance }} is reporting a critical health status."

      - alert: NvmeWearLevelingWarning
        expr: node_nvme_smart_attribute_value{attribute="wear_leveling_count"} > 90 # Example threshold
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "NVMe drive {{ $labels.device }} on {{ $labels.instance }} approaching wear limit"
          description: "The NVMe drive {{ $labels.device }} on {{ $labels.instance }} has a wear leveling count of {{ $value }}."
```

## Visualization with Grafana (Optional)

Grafana is widely used for creating interactive dashboards to visualize Prometheus metrics.

### NixOS Configuration for Grafana

```nix
{ config, pkgs, ... }:

{
  services.grafana = {
    enable = true;
    port = 3000; # Default Grafana web UI port
    # Optional: Configure data sources, dashboards, etc.
    # settings = {
    #   server = {
    #     http_port = 3000;
    #   };
    #   datasources = {
    #     "Prometheus" = {
    #       type = "prometheus";
    #       url = "http://localhost:9090"; # Prometheus server address
    #       isDefault = true;
    #     };
    #   };
    # };
  };

  # Firewall configuration will be handled via Nebula VPN interface later.
  # Example: networking.firewall.interfaces."nebula0".allowedTCPPorts = [ 3000 ];
}
```

After enabling Grafana, access its web UI (default `http://your-grafana-ip:3000`), add Prometheus as a data source, and start building dashboards.
