{ pkgs, ... }:
let
  border-color = {
    active = "0xffff70b3";
    warning = "0xfffffd82";
    warning-2 = "0xfff5f100";
    warning-3 = "0xffB8B500";
    inactive = "0x00000000";
  };
in {
  services.jankyborders = {
    package = pkgs.unstable.jankyborders;
    enable = true;
    inactive_color = border-color.inactive;
    active_color = border-color.active;
    width = 8.5;
  };
}