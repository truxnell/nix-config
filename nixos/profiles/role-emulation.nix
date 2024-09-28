{ config, lib, pkgs, imports, boot, self, ... }:
# Role for headless servers
# covers raspi's, sbc, NUC etc, anything
# that is headless and minimal for running services

with lib;
{


  config = {

    environment.systemPackages = with pkgs; [
      ryujinx
    ];

  };

}
