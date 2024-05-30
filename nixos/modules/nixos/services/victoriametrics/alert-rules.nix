{ lib }:
lib.mapAttrsToList
  (name: opts: # Params
  {
    alert = name;
    expr = opts.condition;
    for = opts.time or "2m";
    labels = { };
    annotations.description = opts.description;
  }
  )
{
  filesystem_full_80percent = {
    condition = ''disk_used_percent{mode!="ro"} >= 80'';
    time = "10m";
    description = "{{$labels.instance}} device {{$labels.device}} on {{$labels.path}} got less than 20% space left on its filesystem";
  };

  filesystem_inodes_full = {
    condition = ''disk_inodes_free / disk_inodes_total < 0.10'';
    time = "10m";
    description = "{{$labels.instance}} device {{$labels.device}} on {{$labels.path}} got less than 10% inodes left on its filesystem";
  };

  ram_using_95percent = {
    condition = "mem_buffered + mem_free + mem_cached < mem_total * 0.05";
    time = "1h";
    description = "{{$labels.host}} is using at least 95% of its RAM for at least 1 hour";
  };

  load15 = {
    condition = ''system_load15 / system_n_cpus{org!="nix-community"} >= 2.0'';
    time = "10m";
    description = "{{$labels.host}} is running with load15 > 1 for at least 5 minutes: {{$value}}";
  };

  reboot = {
    condition = "system_uptime < 300";
    description = "{{$labels.host}} just rebooted";
  };

  zfs_errors = {
    condition = "zfs_arcstats_l2_io_error + zfs_dmu_tx_error + zfs_arcstats_l2_writes_error > 0";
    description = "{{$labels.instance}} reports: {{$value}} ZFS IO errors";
  };

  zpool_status = {
    condition = "zpool_status_errors > 0";
    description = "{{$labels.instance}} reports: zpool {{$labels.name}} has {{$value}} errors";
  };

  unusual_disk_read_latency = {
    condition = "rate(diskio_read_time[1m]) / rate(diskio_reads[1m]) > 0.1 and rate(diskio_reads[1m]) > 0";
    description = "{{$labels.instance}}: Disk latency is growing (read operations > 100ms)";
  };

  unusual_disk_write_latency = {
    condition = "rate(diskio_write_time[1m]) / rate(diskio_write[1m]) > 0.1 and rate(diskio_write[1m]) > 0";
    description = "{{$labels.instance}}: Disk latency is growing (write operations > 100ms)";
  };

  host_memory_under_memory_pressure = {
    condition = "rate(node_vmstat_pgmajfault[1m]) > 1000";
    description = "{{$labels.instance}}: The node is under heavy memory pressure. High rate of major page faults: {{$value}}";
  };

  ext4_errors = {
    condition = "ext4_errors_value > 0";
    description = "{{$labels.instance}}: ext4 has reported {{$value}} I/O errors: check /sys/fs/ext4/*/errors_count";
  };

  alerts_silences_changed = {
    condition = ''abs(delta(alertmanager_silences{state="active"}[1h])) >= 1'';
    description = "alertmanager: number of active silences has changed: {{$value}}";
  };
}
