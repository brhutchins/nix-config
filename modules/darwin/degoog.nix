{ config, lib, pkgs, username, ... }:

let
  cfg = config.local.darwin.degoog;

  configDir = "/Users/${username}/.config/degoog";
  dataDir = "${configDir}/data";
  passwordFile = "${configDir}/settings-password";
  logFile = "/Users/${username}/.degoog.log";
in
{
  options.local.darwin.degoog = {
    enable = lib.mkEnableOption "local DeGoog";

    port = lib.mkOption {
      type = lib.types.port;
      default = 4444;
      description = "Loopback port DeGoog listens on.";
    };

    baseUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        DEGOOG_BASE_URL. Set to the absolute public URL (including any Tailscale
        Serve mount path) when the instance is served behind a proxy, so
        generated links and redirects are correct. DeGoog mounts its routes
        under the URL's path component.
      '';
    };

    publicInstance = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        DEGOOG_PUBLIC_INSTANCE. Leave false: an unlocked settings page can
        install server-side code, and this instance is loopback/Tailscale only.
      '';
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment variables for the DeGoog daemon.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = ''
        The DeGoog package to run (e.g.
        `self.packages.${pkgs.stdenv.hostPlatform.system}.degoog`).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # DeGoog is a persistent web server, so it runs as a long-lived launchd
    # daemon owned by the user (like SearXNG). The settings password is
    # generated on first start into the config dir (0600) and exported to the
    # daemon; no secret is ever written to the Nix store. Rotate it by deleting
    # the file and restarting the daemon.
    launchd.daemons.degoog = {
      script = ''
        set -eu
        dir=${lib.escapeShellArg configDir}
        ${pkgs.coreutils}/bin/mkdir -p "$dir/data"
        if [ ! -s ${lib.escapeShellArg passwordFile} ]; then
          umask 077
          ${pkgs.coreutils}/bin/head -c 36 /dev/urandom | ${pkgs.coreutils}/bin/base64 | ${pkgs.coreutils}/bin/tr -dc 'A-Za-z0-9' > ${lib.escapeShellArg passwordFile}
        fi
        # All mutable state (store, SQLite, engines, plugins, themes, transports)
        # defaults to subdirectories of DEGOOG_DATA_DIR; the store is read-only.
        export DEGOOG_DATA_DIR=${lib.escapeShellArg dataDir}
        export DEGOOG_PORT=${toString cfg.port}
        export DEGOOG_PUBLIC_INSTANCE=${lib.boolToString cfg.publicInstance}
        export DEGOOG_SETTINGS_PASSWORDS="$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg passwordFile})"
        ${lib.optionalString (cfg.baseUrl != null) "export DEGOOG_BASE_URL=${lib.escapeShellArg cfg.baseUrl}"}
        # Store git-clone + Curl transports need git/curl on PATH.
        export PATH=${lib.makeBinPath [ pkgs.git pkgs.curl ]}:$PATH
        exec ${lib.getExe cfg.package}
      '';

      environment = {
        HOME = "/Users/${username}";
      } // cfg.extraEnvironment;

      serviceConfig = {
        UserName = username;
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = logFile;
        StandardErrorPath = logFile;
      };
    };
  };
}
