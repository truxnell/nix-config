{ lib }:
lib.mapAttrsToList
  (
    name: opts: # Params
    {
      alert = name;
      expr = opts.condition;
      for = opts.time or "2m";
      labels = { };
      annotations.description = opts.description;
    })
  {
    ###############################################################################
    # node_exporter – comprehensive homelab alerts (grouped & severity-labelled)
    # Values: keep it simple, hands-off, reliable – two-node NAS + NUC
    ###############################################################################

    ###############################################################################
    # 1. MEMORY PRESSURE
    ###############################################################################
    # critical when <5 % free for 5 min – box will OOM soon
    host_mem_crit = {
      condition = ''(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < 0.05'';
      time      = "5m";
      description = "{{$labels.instance}} RAM <5 % – OOM risk";
      labels = {
        severity = "critical";
      };
    };

    # warning when <10 % free for 10 min – time to investigate before it worsens
    host_mem_warn = {
      condition = ''(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < 0.10'';
      time      = "10m";
      description = "{{$labels.instance}} RAM <10 %";
      labels = {
        severity = "warning";
      };
    };

    # swap usage >0 means we already spilled to disk – worth a warning
    host_swap_used = {
      condition = ''node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes > 0'';
      time      = "0m";
      description = "{{$labels.instance}} using swap";
      labels = {
        severity = "warning";
      };
    };

    ###############################################################################
    # 2. CPU / LOAD
    ###############################################################################
    # load5 > CPU-count for 10 min – services getting sluggish
    host_load_warn = {
      condition = ''node_load5 > on(instance) (count by(instance) (node_cpu_seconds_mode{mode="idle"}))'';
      time      = "10m";
      description = "{{$labels.instance}} load above CPU count";
      labels = {
        severity = "warning";
      };
    };

    # steal >5 % on a VM means noisy neighbour or under-provisioned hyper-thread
    host_steal = {
      condition = ''avg(rate(node_cpu_seconds_mode{mode="steal"}[5m])) by(instance) > 0.05'';
      time      = "10m";
      description = "{{$labels.instance}} high steal time";
      labels = {
        severity = "warning";
      };
    };

    ###############################################################################
    # 3. DISK SPACE (rootfs only – ignore ro snapshots)
    ###############################################################################
    host_root_90 = {
      condition = ''(node_filesystem_avail_bytes{mountpoint="/",fstype!="zfs"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.10'';
      time      = "5m";
      description = "{{$labels.instance}} root fs >90 % full";
      labels = {
        severity = "critical";
      };
    };

    host_root_80 = {
      condition = ''(node_filesystem_avail_bytes{mountpoint="/",fstype!="zfs"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.20'';
      time      = "15m";
      description = "{{$labels.instance}} root fs >80 % full";
      labels = {
        severity = "warning";
      };
    };

    # inodes exhaustion is silent but deadly
    host_root_inodes_90 = {
      condition = ''(node_filesystem_files_free{mountpoint="/"} / node_filesystem_files{mountpoint="/"}) < 0.10'';
      time      = "5m";
      description = "{{$labels.instance}} root fs <10 % inodes free";
      labels = {
        severity = "critical";
      };
    };

    ###############################################################################
    # 4. DISK I/O & ERRORS
    ###############################################################################
    # any read/write error counter increment – investigate disk or cable
    host_disk_err = {
      condition = ''increase(node_disk_read_errors_total[5m]) > 0 or increase(node_disk_write_errors_total[5m]) > 0'';
      time      = "0m";
      description = "{{$labels.instance}} disk errors on {{$labels.device}}";
      labels = {
        severity = "warning";
      };
    };

    # >500 ms average IO time – pool or disk struggling
    host_disk_slow = {
      condition = ''rate(node_disk_io_time_seconds_total[5m]) / rate(node_disk_reads_completed_total[5m] + node_disk_writes_completed_total[5m]) > 0.5'';
      time      = "10m";
      description = "{{$labels.instance}} {{$labels.device}} avg IO >500 ms";
      labels = {
        severity = "warning";
      };
    };

    ###############################################################################
    # 5. TEMPERATURE (spinning disks – ignore SSDs without sensor)
    ###############################################################################
    host_disk_hot = {
      condition = ''node_hwmon_temp_celsius{sensor=~"temp[0-9]"} >= 50 unless on(device) (node_disk_rotation_rate_rpm == 0)'';
      time      = "5m";
      description = "{{$labels.instance}} disk temp ≥50 °C on {{$labels.chip}}";
      labels = {
        severity = "warning";
      };
    };

    host_disk_crit = {
      condition = ''node_hwmon_temp_celsius{sensor=~"temp[0-9]"} >= 55 unless on(device) (node_disk_rotation_rate_rpm == 0)'';
      time      = "0m";
      description = "{{$labels.instance}} disk temp ≥55 °C";
      labels = {
        severity = "critical";
      };
    };

    ###############################################################################
    # 6. NETWORK
    ###############################################################################
    # carrier lost on main interface (ignore veth, lo)
    host_net_down = {
      condition = ''node_network_up{device!~"veth.*|lo|wlo.*"} == 0'';
      time      = "2m";
      description = "{{$labels.instance}} interface {{$labels.device}} down";
      labels = {
        severity = "warning";
      };
    };

    # RX/TX errors – usually cable or auto-neg mismatch
    host_net_err = {
      condition = ''increase(node_network_receive_errs_total[5m]) > 10 or increase(node_network_transmit_errs_total[5m]) > 10'';
      time      = "5m";
      description = "{{$labels.instance}} {{$labels.device}} net errors";
      labels = {
        severity = "warning";
      };
    };

    ###############################################################################
    # 7. SYSTEMD SERVICES
    ###############################################################################
    host_systemd_failed = {
      condition = ''node_systemd_unit_state{state="failed"} == 1'';
      time      = "0m";
      description = "{{$labels.instance}} service {{$labels.name}} failed";
      labels = {
        severity = "warning";
      };
    };

    ###############################################################################
    # 8. MISCELLANEOUS
    ###############################################################################
    # kernel wants reboot (newer libc, security patch)
    host_reboot = {
      condition = ''node_reboot_required > 0'';
      time      = "0m";
      description = "{{$labels.instance}} reboot required";
      labels = {
        severity = "warning";
      };
    };

    # NTP drift >500 ms – can break TLS & logs
    host_clock = {
      condition = ''abs(node_timex_offset_seconds) > 0.5'';
      time      = "5m";
      description = "{{$labels.instance}} clock off by {{$value}} s";
      labels = {
        severity = "warning";
      };
    };

    # file-descriptor usage >90 %
    host_fd = {
      condition = ''(node_filefd_allocated / node_filefd_maximum) > 0.90'';
      time      = "5m";
      description = "{{$labels.instance}} >90 % FDs used";
      labels = {
        severity = "warning";
      };
    };




    ###############################################################################
    # node_exporter ZFS module – mirror pool (docs/photos)
    ###############################################################################
    # pool health: 0 = ONLINE, 1 = DEGRADED, 2 = FAULTED, 3 = OFFLINE, 4 = UNAVAIL
    zpool_degraded = {
      condition = ''node_zfs_pool_health > 0'';
      time      = "0m";
      description = "ZFS pool {{$labels.pool}} health={{ $value }} (0=online)";
      labels = {
        severity = "critical";
      };
    };

    # last scrub timestamp (Unix seconds)
    zfs_scrub_old_warn = {
      condition = ''(time() - node_zfs_pool_last_scan_timestamp{scan_type="scrub"}) / 86400 > 10'';
      time      = "0m";
      description = "Pool {{$labels.pool}} scrub >10 d ago";
      labels = {
        severity = "warning";
      };
    };

    zfs_scrub_old_crit = {
      condition = ''(time() - node_zfs_pool_last_scan_timestamp{scan_type="scrub"}) / 86400 > 14'';
      time      = "0m";
      description = "Pool {{$labels.pool}} scrub >14 d ago";
      labels = {
        severity = "critical";
      };
    };

    # checksum errors (node_exporter gives us total counter)
    zfs_checksum_warn = {
      condition = ''increase(node_zfs_pool_checksum_errors[10m]) > 0'';
      time      = "0m";
      description = "Pool {{$labels.pool}} new checksum errors";
      labels = {
        severity = "warning";
      };
    };

    zfs_checksum_crit = {
      condition = ''node_zfs_pool_checksum_errors > 0'';
      for       = "30m";
      description = "Pool {{$labels.pool}} persistent checksum errors";
      labels = {
        severity = "critical";
      };
    };

    # pool capacity (node_exporter only gives us USED & AVAIL bytes)
    zfs_cap_warn = {
      condition = ''(node_zfs_pool_available_bytes / (node_zfs_pool_available_bytes + node_zfs_pool_used_bytes)) < 0.20'';
      time      = "0m";
      description = "Pool {{$labels.pool}} >80 % full";
      labels = {
        severity = "warning";
      };
    };

    zfs_cap_crit = {
      condition = ''(node_zfs_pool_available_bytes / (node_zfs_pool_available_bytes + node_zfs_pool_used_bytes)) < 0.10'';
      time      = "0m";
      description = "Pool {{$labels.pool}} >90 % full";
      labels = {
        severity = "critical";
      };
    };

    ###############################################################################
    # smartctl_exporter – disk-health alerts (NixOS attribute-set format)
    ###############################################################################

    ###############################################################################
    # 0. Exporter health
    ###############################################################################
    smartctl_exporter_err = {
      condition = ''smartctl_device_smartctl_exit_status > 0'';
      time      = "10m";
      description = "smartctl exit non-zero on {{$labels.device}} – disk may be sleeping or unreachable";
      labels = {
        severity = "warning";
      };
    };

    ###############################################################################
    # 1. Overall SMART status
    ###############################################################################
    smart_status_failed = {
      condition = ''smartctl_device_smart_status == 0'';
      time      = "2m";
      description = "SMART failure on {{$labels.device}} – investigate and replace the disk";
      labels = {
        severity = "critical";
      };
    };

    ###############################################################################
    # 2. Temperature
    ###############################################################################
    smart_temp_warn = {
      condition = ''smartctl_device_temperature{temperature_type="current"} >= 55'';
      time      = "5m";
      description = "High temperature (≥55 °C) on {{$labels.device}} – check cooling";
      labels = {
        severity = "warning";
      };
    };

    smart_temp_crit = {
      condition = ''smartctl_device_temperature{temperature_type="current"} >= 60'';
      time      = "5m";
      description = "Critical temperature (≥60 °C) on {{$labels.device}} – immediate action";
      labels = {
        severity = "critical";
      };
    };

    ###############################################################################
    # 3. Reallocated / Pending / Uncorrectable sectors
    ###############################################################################
    smart_realloc_warn = {
      condition = ''smartctl_device_attribute{attribute_name="Reallocated_Sector_Ct",attribute_value_type="raw"} > 0'';
      time      = "10m";
      description = "Reallocated sectors > 0 on {{$labels.device}} – monitor closely";
      labels = {
        severity = "warning";
      };
    };

    smart_realloc_crit = {
      condition = ''smartctl_device_attribute{attribute_name="Reallocated_Sector_Ct",attribute_value_type="raw"} >= 10'';
      time      = "10m";
      description = "Reallocated sectors ≥ 10 on {{$labels.device}} – replace disk soon";
      labels = {
        severity = "critical";
      };
    };

    smart_pending = {
      condition = ''smartctl_device_attribute{attribute_name="Current_Pending_Sector",attribute_value_type="raw"} > 0'';
      time      = "2m";
      description = "Pending sectors on {{$labels.device}} – data at risk, backup & replace";
      labels = {
        severity = "critical";
      };
    };

    smart_offline_uncorr = {
      condition = ''smartctl_device_attribute{attribute_name="Offline_Uncorrectable",attribute_value_type="raw"} > 0'';
      time      = "2m";
      description = "Offline uncorrectable errors on {{$labels.device}} – replace disk";
      labels = {
        severity = "critical";
      };
    };

    smart_reported_uncorr = {
      condition = ''smartctl_device_attribute{attribute_name="Reported_Uncorrect",attribute_value_type="raw"} > 0'';
      time      = "2m";
      description = "Reported uncorrectable errors on {{$labels.device}} – replace disk";
      labels = {
        severity = "critical";
      };
    };

    ###############################################################################
    # 4. Mechanical / spin retry
    ###############################################################################
    smart_spin_retry = {
      condition = ''smartctl_device_attribute{attribute_name="Spin_Retry_Count",attribute_value_type="raw"} > 0'';
      time      = "2m";
      description = "Spin retry events on {{$labels.device}} – failure likely, replace disk";
      labels = {
        severity = "critical";
      };
    };

    ###############################################################################
    # 5. Cable / port issues
    ###############################################################################
    smart_crc_warn = {
      condition = ''smartctl_device_attribute{attribute_name="UDMA_CRC_Error_Count",attribute_value_type="raw"} >= 50'';
      time      = "10m";
      description = "High UDMA CRC errors on {{$labels.device}} – check cable/port/power";
      labels = {
        severity = "warning";
      };
    };


    # ###############################################################################
    # # zfs_exporter (NAS ZFS mirror)
    # ###############################################################################
    # zfspool_degraded = {
    #   condition = ''zpool_status{state!="ONLINE"} > 0'';
    #   time      = "0s";
    #   description = "ZFS pool {{$labels.pool}} is {{$labels.state}}";
    # };

    # ###############################################################################
    # # SnapRAID / MergerFS exporters (NAS media pool)
    # ###############################################################################
    # snapraid_unsynced = {
    #   condition = ''snapraid_sync_age_hours > 25'';
    #   time      = "0s";
    #   description = "SnapRAID has not synced for {{$value}} h";
    # };

    # mergerfs_drive_down = {
    #   condition = ''mergerfs_drives_up < 8'';
    #   time      = "2m";
    #   description = "MergerFS reports only {{$value}} drives online";
    # };

    # ###############################################################################
    # # blackbox_exporter (reachability & TLS)
    # ###############################################################################
    # endpoint_down = {
    #   condition = ''probe_success == 0'';
    #   time      = "2m";
    #   description = "{{$labels.instance}} probe failed";
    # };

    # cert_expiry_soon = {
    #   condition = ''(probe_ssl_earliest_cert_expiry - time()) / 86400 < 14'';
    #   time      = "0s";
    #   description = "TLS cert for {{$labels.instance}} expires in <14 d";
    # };

    # udm_unreachable = {
    #   condition = ''probe_success{instance="udm.home",job="blackbox"} == 0'';
    #   time      = "2m";
    #   description = "UDM-Pro not answering ICMP";
    # };

    # ###############################################################################
    # # VictoriaMetrics self-monitoring
    # ###############################################################################
    # vmalert_failing = {
    #   condition = ''up{job="vmalert"} == 0'';
    #   time      = "0s";
    #   description = "vmalert is down – no rules are evaluated";
    # };

    # metrics_ingestion_stalled = {
    #   condition = ''increase(vm_rows_added_total[5m]) == 0'';
    #   time      = "10m";
    #   description = "No new samples ingested in 10 m";
    # };

    # ###############################################################################
    # # quick smoketest (no scraper)
    # ###############################################################################
    # test = {
    #   condition = ''vector(1)'';
    #   time      = "0s";
    #   description = "Smoketest Alert";
    # };

  }
