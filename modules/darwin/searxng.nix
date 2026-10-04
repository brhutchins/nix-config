{ config, lib, pkgs, username, ... }:

let
  cfg = config.local.darwin.searxng;

  # Rendered as JSON (valid YAML) and deep-merged with `settings`. The secret
  # stays a placeholder here; the launchd wrapper substitutes a per-host value
  # generated at first start, so no secret is ever written to the Nix store.
  baseSettings = {
    use_default_settings = true;
    general = {
      instance_name = "searxng";
    };
    server = {
      bind_address = cfg.host;
      port = cfg.port;
      limiter = false;
      image_proxy = true;
      secret_key = "__SEARXNG_SECRET__";
    } // lib.optionalAttrs (cfg.baseUrl != null) {
      base_url = cfg.baseUrl;
    };
    search = {
      formats = cfg.formats;
    };
  };

  settingsTemplate = pkgs.writeText "searxng-settings.yml"
    (builtins.toJSON (lib.recursiveUpdate baseSettings cfg.settings));

  configDir = "/Users/${username}/.config/searxng";
in
{
  options.local.darwin.searxng = {
    enable = lib.mkEnableOption "local SearXNG";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address SearXNG binds to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Port SearXNG listens on (ketch's default SearXNG URL).";
    };

    formats = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "json" ];
      description = ''
        search.formats. Include "json" for the ketch backend, and "html" to
        serve the web UI.
      '';
    };

    baseUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        server.base_url; set when the instance is served behind a proxy
        (e.g. Tailscale Serve) so generated URLs are absolute and correct.
      '';
    };

    caBundle = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        CA bundle for outbound engine requests (the Zscaler MITM bundle on work
        hosts). Sets SSL_CERT_FILE, REQUESTS_CA_BUNDLE and CURL_CA_BUNDLE.
      '';
    };

    package = lib.mkPackageOption pkgs "searxng" { };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Extra settings deep-merged over the module defaults (engine/UI tuning).";
    };
  };

  config = lib.mkIf cfg.enable {
    # The wrapper generates the secret on first start (and reuses it thereafter)
    # and re-renders settings.yml each start. The template is embedded in the
    # script, so a config change changes the plist and nix-darwin restarts the
    # daemon. `searxng-run` reads SEARXNG_SETTINGS_PATH from the environment.
    launchd.daemons.searxng = {
      script = ''
        set -eu
        dataDir="${configDir}"
        ${pkgs.coreutils}/bin/mkdir -p "$dataDir"
        if [ ! -s "$dataDir/secret" ]; then
          umask 077
          ${pkgs.coreutils}/bin/head -c 36 /dev/urandom | ${pkgs.coreutils}/bin/base64 | ${pkgs.coreutils}/bin/tr -dc 'A-Za-z0-9' > "$dataDir/secret"
        fi
        ${pkgs.gnused}/bin/sed "s|__SEARXNG_SECRET__|$(${pkgs.coreutils}/bin/cat "$dataDir/secret")|g" \
          ${settingsTemplate} > "$dataDir/settings.yml.tmp"
        ${pkgs.coreutils}/bin/chmod 600 "$dataDir/settings.yml.tmp" "$dataDir/secret"
        ${pkgs.coreutils}/bin/mv "$dataDir/settings.yml.tmp" "$dataDir/settings.yml"
        export SEARXNG_SETTINGS_PATH="$dataDir/settings.yml"
        exec ${lib.getExe cfg.package}
      '';

      environment = {
        HOME = "/Users/${username}";
      } // lib.optionalAttrs (cfg.caBundle != null) {
        SSL_CERT_FILE = cfg.caBundle;
        REQUESTS_CA_BUNDLE = cfg.caBundle;
        CURL_CA_BUNDLE = cfg.caBundle;
      };

      serviceConfig = {
        UserName = username;
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/Users/${username}/.searxng.log";
        StandardErrorPath = "/Users/${username}/.searxng.log";
      };
    };
  };
}
