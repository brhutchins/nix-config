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

    # The loopback ports are read from the owning modules
    # (`local.darwin.<svc>.port`); this module only owns the public side
    # (HTTPS ports, mount paths).

    syncHttpsPort = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = "Public (tailnet) HTTPS port for the Atuin sync server.";
    };

    aiHttpsPort = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "Public (tailnet) HTTPS port for the Atuin AI server.";
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

    degoogHttpsPort = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = ''
        Public (tailnet) HTTPS port for DeGoog. Defaults to 443, shared with
        Atuin sync and SearXNG via a path mount so the URL needs no port.
      '';
    };

    degoogPath = lib.mkOption {
      type = lib.types.str;
      default = "/degoog";
      description = ''
        Path under the HTTPS port at which DeGoog is mounted. Must match the
        path of `local.darwin.degoog.baseUrl`. Tailscale Serve strips the mount
        path before forwarding, so the proxy target re-adds it: DeGoog mounts
        its routes under `DEGOOG_BASE_URL`'s path component.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      (lib.optionals config.local.darwin.searxng.enable [
        {
          # SearXNG re-adds the prefix itself (FlaskFix, from base_url), so
          # this only guards typos between the mount and base_url.
          assertion =
            let
              # Null-safe so a missing/path-less baseUrl fails the assertion,
              # not the eval.
              path =
                let base = config.local.darwin.searxng.baseUrl; in
                if base == null then null
                else builtins.match "[a-z]+://[^/]+(/.*)" base;
            in
            path != null && lib.removeSuffix "/" (lib.head path) == cfg.searxngPath;
          message = "local.darwin.searxng.baseUrl must be set (when served) and its path must match local.darwin.tailscale-serve.searxngPath (${cfg.searxngPath})";
        }
      ])
      ++ (lib.optionals config.local.darwin.degoog.enable [
        {
          # Serve strips `--set-path` and the target re-adds it, so DeGoog only
          # receives the prefix it expects when baseUrl's path == degoogPath.
          # Strict match: baseUrl must be set and carry the exact path.
          assertion =
            let
              path =
                let base = config.local.darwin.degoog.baseUrl; in
                if base == null then null
                else builtins.match "[a-z]+://[^/]+(/.*)" base;
            in
            path != null && lib.head path == cfg.degoogPath;
          message = "local.darwin.degoog.baseUrl must be set (when served) and its path component must match local.darwin.tailscale-serve.degoogPath (${cfg.degoogPath})";
        }
      ]);

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

        "$TS" serve --bg --yes --https=${toString cfg.syncHttpsPort} http://127.0.0.1:${toString config.local.darwin.atuinServer.port}
      '' + lib.optionalString (models != []) ''
        "$TS" serve --bg --yes --https=${toString cfg.aiHttpsPort} http://127.0.0.1:${toString config.local.darwin.atuinAiServer.port}
      '' + lib.optionalString config.local.darwin.searxng.enable ''
        "$TS" serve --bg --yes --https=${toString cfg.searxngHttpsPort} --set-path=${cfg.searxngPath} http://127.0.0.1:${toString config.local.darwin.searxng.port}
      '' + lib.optionalString config.local.darwin.degoog.enable ''
        # Serve strips `--set-path` before proxying; the target path re-adds it
        # so DeGoog receives the `/degoog` prefix its routes are mounted under.
        "$TS" serve --bg --yes --https=${toString cfg.degoogHttpsPort} --set-path=${cfg.degoogPath} http://127.0.0.1:${toString config.local.darwin.degoog.port}${cfg.degoogPath}
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
