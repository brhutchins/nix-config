{ config, lib, pkgs, ... }:

let
  cfg = config.local.darwin.tailscaleServe;
  data = import ../data;
  models = data.atuin.ai.server.models;
  tailscale = config.services.tailscale.package;
in
{
  options.local.darwin.tailscaleServe = {
    enable = lib.mkEnableOption "Tailscale Serve TLS termination in front of the Atuin services";

    syncLocalPort = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Loopback port of the Atuin sync server.";
    };

    syncHttpsPort = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = "Public (tailnet) HTTPS port for the Atuin sync server.";
    };

    aiLocalPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Loopback port of the Atuin AI server.";
    };

    aiHttpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "Public (tailnet) HTTPS port for the Atuin AI server.";
    };

    searxngLocalPort = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Loopback port of the SearXNG instance.";
    };

    searxngHttpsPort = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = ''
        Public (tailnet) HTTPS port for SearXNG. Defaults to 443, shared with
        Atuin sync via a path mount so the URL needs no port.
      '';
    };

    searxngPath = lib.mkOption {
      type = lib.types.str;
      default = "/searxng";
      description = ''
        Path under the HTTPS port at which SearXNG is mounted. Must match the
        path of `local.darwin.searxng.baseUrl`. Tailscale Serve strips it before
        forwarding; SearXNG re-adds it from base_url (its FlaskFix middleware).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # One-shot reconciler: waits out tailscaled at boot, then applies the
    # loopback-only mappings. `serve --bg` state self-restores across reboots
    # and `tailscale up`, so the daily calendar run just converges changes
    # (e.g. HTTPS certs enabled after the fact) without waiting for a reboot.
    launchd.daemons.tailscale-serve = {
      script = ''
        TS="${tailscale}/bin/tailscale"

        i=0
        while [ "$i" -lt 60 ]; do
          if "$TS" ip -4 >/dev/null 2>&1; then
            break
          fi
          i=$((i + 1))
          sleep 5
        done

        "$TS" serve --bg --yes --https=${toString cfg.syncHttpsPort} http://127.0.0.1:${toString cfg.syncLocalPort}
      '' + lib.optionalString (models != []) ''
        "$TS" serve --bg --yes --https=${toString cfg.aiHttpsPort} http://127.0.0.1:${toString cfg.aiLocalPort}
      '' + lib.optionalString config.local.darwin.searxng.enable ''
        "$TS" serve --bg --yes --https=${toString cfg.searxngHttpsPort} --set-path=${cfg.searxngPath} http://127.0.0.1:${toString cfg.searxngLocalPort}
      '';

      serviceConfig = {
        UserName = "root";
        RunAtLoad = true;
        StartCalendarInterval = [
          { Hour = 4; Minute = 30; }
        ];
        StandardOutPath = "/var/log/tailscale-serve.log";
        StandardErrorPath = "/var/log/tailscale-serve.log";
      };
    };
  };
}
