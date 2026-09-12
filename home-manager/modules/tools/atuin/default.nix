{ config, lib, pkgs, ... }:

let
  cfg = config.local.tools.atuin;
  data = import ../../../../modules/data;
in
{
  options.local.tools.atuin = {
    enable = lib.mkEnableOption "Atuin shell history (sync + AI)";

    syncAddress = lib.mkOption {
      type = lib.types.str;
      default = data.atuin.client.syncAddress;
      description = "Atuin sync server base URL (no trailing slash).";
    };

    aiEndpoint = lib.mkOption {
      type = lib.types.str;
      default = data.atuin.client.aiEndpoint;
      description = "Atuin AI bridge base URL.";
    };

    aiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = data.atuin.client.aiKey;
      description = "Bearer token this client presents to the AI bridge; must match the bridge's server aiKey.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      package = pkgs.unstable.atuin;
      enableZshIntegration = true;
      enableBashIntegration = true;
      forceOverwriteSettings = true;
      settings = {
        auto_sync = true;
        sync_address = cfg.syncAddress;
        sync_frequency = "5m";
        ai = {
          enabled = true;
          endpoint = cfg.aiEndpoint;
          endpoint_protocol = "oss";
        } // lib.optionalAttrs (cfg.aiKey != null) { api_token = cfg.aiKey; };
      };
    };
  };
}
