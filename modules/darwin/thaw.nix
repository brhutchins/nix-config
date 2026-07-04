{ config, lib, pkgs, ... }:
let
  cfg = config.programs.thaw;
  thawPkg = pkgs.callPackage ../../packages/thaw/default.nix { };
in {
  options.programs.thaw = {
    enable = lib.mkEnableOption "Thaw menu bar manager";
    launchAtLogin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to start Thaw automatically at user login.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ thawPkg ];

    launchd.user.agents.thaw = lib.mkIf cfg.launchAtLogin {
      serviceConfig = {
        Label = "com.thaw.app";
        ProgramArguments = [ "${thawPkg}/Applications/Thaw.app/Contents/MacOS/Thaw" ];
        RunAtLoad = true;
        KeepAlive = false;
      };
    };
  };
}