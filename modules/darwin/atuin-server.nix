{ config, lib, pkgs, username, ... }:

let
  cfg = config.local.darwin.atuinServer;
  atuin = pkgs.unstable.atuin;
  dataDir = "/Users/${username}/.local/share/atuin";
  logFile = "/Users/${username}/.atuin-server.log";

  serverConfig = pkgs.writeText "atuin-server.toml" ''
    host = "${cfg.host}"
    port = ${toString cfg.port}
    open_registration = ${lib.boolToString cfg.openRegistration}
    db_uri = "sqlite://${dataDir}/atuin-server.db"
  '';
in
{
  options.local.darwin.atuinServer = {
    enable = lib.mkEnableOption "the Atuin sync server";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address the Atuin sync server binds to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
      description = "Port the Atuin sync server listens on.";
    };

    openRegistration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether new accounts may self-register. Enable briefly to register, then disable.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."atuin/server.toml".source = serverConfig;

    # System daemon (not a login agent) so it starts at boot without a GUI
    # login; UserName drops it to the admin user so the DB/log live in $HOME.
    launchd.daemons.atuin-server = {
      script = ''
        mkdir -p ${dataDir}
        # config: ${serverConfig}
        exec ${atuin}/bin/atuin-server start
      '';

      environment = {
        ATUIN_CONFIG_DIR = "/etc/atuin";
        HOME = "/Users/${username}";
      };

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
