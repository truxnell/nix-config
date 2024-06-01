{
  database.path = "/data/frigate.db";
  mqtt = {
    enabled = true;
    host = "mqtt.trux.dev";
    port = 1883;
    topic_prefix = "frigate";
    user = "{FRIGATE_MQTT_USERNAME}";
    password = "{FRIGATE_MQTT_PASSWORD}";
  };

  ffmpeg = {
    global_args = [ "-hide_banner" "-loglevel" "warning" ];
    hwaccel_args = "preset-intel-qsv-h264";
    output_args.record = "preset-record-ubiquiti";
  };

  detectors.coral = {
    type = "edgetpu";
    device = "usb";
  };

  snapshots = {
    enabled = true;
    timestamp = false;
    bounding_box = true;
    retain = {
      default = 2;
    };
  };

  record = {
    enabled = true;
    retain = {
      days = 30;
      mode = "all";
    };
    events.retain = {
      default = 30;
      mode = "active_objects";
    };
  };

  objects = {
    track = [ "person" ];
    filters.person = {
      min_area = 5000;
      max_area = 100000;
      threshold = 0.7;
    };
  };

  go2rtc.streams = {
    midgarden_lq = "rtspx://10.8.10.1:7441/brWeoAmzSap1eSn0";
    midgarden_hq = "rtspx://10.8.10.1:7441/wcl28kSjhPY6yoNT";
    backgarden_lq = "rtspx://10.8.10.1:7441/YejyBzbcJftkgMSA";
    backgarden_hq = "rtspx://10.8.10.1:7441/n1jD2ngAPG9e4dv2";

  };

  cameras = {
    midgarden = {
      ffmpeg.inputs = [
        {
          path = "rtsp://127.0.0.1:8554/midgarden_lq";
          roles = [ "detect" ];
        }
        {
          path = "rtsp://127.0.0.1:8554/midgarden_hq";
          roles = [ "record" ];
        }
      ];
    };
    backgarden = {
      ffmpeg.inputs = [
        {
          path = "rtsp://127.0.0.1:8554/backgarden_lq";
          roles = [ "detect" ];
        }
        {
          path = "rtsp://127.0.0.1:8554/backgarden_hq";
          roles = [ "record" ];
        }

      ];

    };
  };


}
