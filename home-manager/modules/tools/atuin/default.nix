{ config, lib, pkgs, ... }:

let
  cfg = config.local.tools.atuin;
  data = import ../../../../modules/data;

  # Sync is only switched on when requested and a target URL exists; a host
  # that runs without syncing (e.g. PLN) omits [atuin.sync] entirely.
  syncEnabled = cfg.sync && cfg.syncAddress != null;

  # AI needs an endpoint; without one Atuin falls back to a plain history CLI.
  aiEnabled = cfg.aiEndpoint != null;
in
{
  options.local.tools.atuin = {
    enable = lib.mkEnableOption "Atuin shell history (sync + AI)";

    sync = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether this host syncs shell history to syncAddress.";
    };

    syncAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = data.atuin.sync.address;
      description = "Atuin sync server base URL (no trailing slash).";
    };

    aiEndpoint = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = data.atuin.ai.client.endpoint;
      description = "Atuin AI bridge base URL.";
    };

    aiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = data.atuin.ai.client.key;
      description = "Bearer token this client presents to the AI bridge; must match the bridge's server key.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional (!aiEnabled) ''
      local.tools.atuin.enable is set, but data.atuin.ai.client.endpoint is
      null (~/.config/nix-config/private.toml has no [atuin.ai.client] endpoint),
      so Atuin AI is disabled. History and (if configured) sync still work.
    '';

    programs.atuin = {
      enable = true;
      package = pkgs.unstable.atuin;
      enableZshIntegration = true;
      enableBashIntegration = true;
      forceOverwriteSettings = true;
      settings = {
        filter_mode_shell_up_key_binding = "directory";
        ai = {
          enabled = aiEnabled;
        }
        // lib.optionalAttrs aiEnabled {
          endpoint = cfg.aiEndpoint;
          endpoint_protocol = "oss";
        }
        // lib.optionalAttrs (aiEnabled && cfg.aiKey != null) {
          api_token = cfg.aiKey;
        };
      }
      // lib.optionalAttrs syncEnabled {
        auto_sync = true;
        sync_address = cfg.syncAddress;
        sync_frequency = "5m";
      }
      // lib.optionalAttrs (!syncEnabled) {
        auto_sync = false;
      };
    };
  };
}
