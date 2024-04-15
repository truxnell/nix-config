{ config, lib, pkgs, ... }:
let
  motd = pkgs.writeShellScriptBin "motd"
    ''
      #! /usr/bin/env bash
      source /etc/os-release
      service_status=$(systemctl list-units | grep podman-)
      RED="\e[31m"
      GREEN="\e[32m"
      BOLD="\e[1m"
      ENDCOLOR="\e[0m"
      LOAD1=`cat /proc/loadavg | awk {'print $1'}`
      LOAD5=`cat /proc/loadavg | awk {'print $2'}`
      LOAD15=`cat /proc/loadavg | awk {'print $3'}`

      MEMORY=`free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100 / $2 }'`

      # time of day
      HOUR=$(date +"%H")
      if [ $HOUR -lt 12  -a $HOUR -ge 0 ]
      then    TIME="morning"
      elif [ $HOUR -lt 17 -a $HOUR -ge 12 ]
      then    TIME="afternoon"
      else
          TIME="evening"
      fi


      uptime=`cat /proc/uptime | cut -f1 -d.`
      upDays=$((uptime/60/60/24))
      upHours=$((uptime/60/60%24))
      upMins=$((uptime/60%60))
      upSecs=$((uptime%60))

      figlet "$(hostname)" | lolcat -f
      printf "$BOLD    %-20s$ENDCOLOR %s\n" "Role:" "${config.mySystem.purpose}"
      printf "\n"
      ${lib.strings.concatStrings (lib.lists.forEach cfg.networkInterfaces (x: "printf \"$BOLD  * %-20s$ENDCOLOR %s\\n\" \"IPv4 ${x}\" \"$(ip -4 addr show ${x} | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}')\"\n"))}
      printf "$BOLD  * %-20s$ENDCOLOR %s\n" "Release" "$PRETTY_NAME"
      printf "$BOLD  * %-20s$ENDCOLOR %s\n" "Kernel" "$(uname -rs)"
      [ -f /var/run/reboot-required ] && printf "$RED  * %-20s$ENDCOLOR %s\n" "A reboot is required"
      printf "\n"
      printf "$BOLD  * %-20s$ENDCOLOR %s\n" "CPU usage" "$LOAD1, $LOAD5, $LOAD15 (1, 5, 15 min)"
      printf "$BOLD  * %-20s$ENDCOLOR %s\n" "Memory" "$MEMORY"
      printf "$BOLD  * %-20s$ENDCOLOR %s\n" "System uptime" "$upDays days $upHours hours $upMins minutes $upSecs seconds"
      printf "\n"
      if ! type "$zpool" &> /dev/null; then
        printf "$BOLD Zpool status: $ENDCOLOR\n"
        zpool status -x | sed -e 's/^/  /'
      fi
      if ! type "$zpool" &> /dev/null; then
        printf "$BOLD Zpool usage: $ENDCOLOR\n"
        zpool list -Ho name,cap,size | awk '{ printf("%-10s%+3s used out of %+5s\n", $1, $2, $3); }' | sed -e 's/^/  /'
      fi
      printf "\n"
      printf "$BOLDService status$ENDCOLOR\n"

      while IFS= read -r line; do
        if [[ $line =~ ".scope" ]]; then
          continue
        fi
        if echo "$line" | grep -q 'failed'; then
          service_name=$(echo $line | awk '{print $2;}' | sed 's/podman-//g')
          printf "$RED• $ENDCOLOR%-50s $RED[failed]$ENDCOLOR\n" "$service_name"
        elif echo "$line" | grep -q 'running'; then
          service_name=$(echo $line | awk '{print $1;}' | sed 's/podman-//g')
          printf "$GREEN• $ENDCOLOR%-50s $GREEN[active]$ENDCOLOR\n" "$service_name"
        else
          echo "service status unknown"
        fi
      done <<< "$service_status"
    '';
  cfg = config.mySystem.system.motd;
in
{
  options.mySystem.system.motd = {
    enable = lib.mkEnableOption "MOTD";
    networkInterfaces = lib.mkOption {
      description = "Network interfaces to monitor";
      type = lib.types.listOf lib.types.str;
      # default = lib.mapAttrsToList (_: val: val.interface)
      default = [ ];
    };

  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      motd
      pkgs.lolcat
      pkgs.figlet
    ];
    programs.fish.interactiveShellInit = lib.mkIf config.programs.fish.enable ''
      motd
    '';
  };
}
