{ config, lib, pkgs, ... }: {
  environment.systemPackages =
    lib.mkIf (!config.local.darwin.minimize) [
      pkgs.unstable.lmstudio
    ];
}