{ config, lib, pkgs, username, ... }:

let
  cfg = config.local.darwin.atuinAiServer;
  data = import ../data;
  pkg = pkgs.unstable.callPackage ../../packages/atuin-ai-server { };

  # Models the bridge advertises to clients; the first is the default.
  models = data.atuin.ai.server.models;
  # Token this bridge requires from its clients (client → bridge).
  serverAiKey = data.atuin.ai.server.key;
  # Token this bridge presents to the inference backend (bridge → inference).
  inferenceKey = data.atuin.ai.server.inferenceKey;

  cacheDir = "/Users/${username}/.cache/atuin-ai-server";
  logFile = "/Users/${username}/.atuin-ai-server.log";

  # The upstream OpenAI-compatible engine (oMLX) requires its own token,
  # distinct from the one clients use to reach this bridge.
  upstreamApiKeyLine =
    lib.optionalString (inferenceKey != null) ''api_key = "${inferenceKey}"'';

  # One [[models]] block per configured model. The alias is what a client
  # selects and sends back, so use the provider model ID as the alias.
  modelsToml = lib.concatMapStrings (id: ''
    [[models]]
    alias = "${id}"
    name = "${id}"
    description = "Local model"
    model = "${id}"
  '') models;

  # Keep the rendered config as a Nix store path and point the daemon at it.
  # The store path hash changes with the content, so the launchd plist's
  # EnvironmentVariables change too and nix-darwin reloads (restarts) the
  # service on config changes. Plain environment.etc would not, since the
  # plist would keep referencing an unchanging /etc path.
  chatConfig = pkgs.writeText "atuin-ai-config.toml" ''
    port = ${toString cfg.port}
    endpoint = "${cfg.upstream}"
    default_model = "${builtins.head models}"
    ${upstreamApiKeyLine}
    ${modelsToml}
    [request.body]
    stream_options = { include_usage = true }
  '';

  # Deploying the bridge with no models would silently serve an empty catalog
  # and fail every chat turn. Stay dormant (sync and Serve(443) keep working)
  # until private.toml gains a non-empty `models`.
  deploy = cfg.enable && models != [];
in
{
  options.local.darwin.atuinAiServer = {
    enable = lib.mkEnableOption "atuin-ai-server";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address the bridge is documented to bind. The upstream release always
        listens on loopback (patched in packages/atuin-ai-server), so values
        other than loopback have no effect.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port the Atuin AI server listens on.";
    };

    upstream = lib.mkOption {
      type = lib.types.str;
      default = data.atuin.ai.server.upstream;
      description = "OpenAI-compatible endpoint of the inference server.";
    };
  };

  config = lib.mkMerge [
    {
      warnings = lib.optional (cfg.enable && models == []) ''
        local.darwin.atuinAiServer.enable is set, but data.atuin.ai.server.models
        is empty in ~/.config/nix-config/private.toml, so the Atuin AI server is
        not being deployed (sync and Tailscale Serve for it are unaffected).
        Add `models = ["<id>", ...]` under [atuin.ai.server] in private.toml and
        rebuild.
      '';
    }

    (lib.mkIf deploy {
      launchd.daemons.atuin-ai-server = {
        script = ''
          mkdir -p ${cacheDir}
          exec ${pkg}/bin/atuin_ai_server start
        '';

        environment = {
          CHAT_CONFIG = "${chatConfig}";
          RELEASE_DISTRIBUTION = "none";
          # The release launcher reads releases/COOKIE unless this is set; the
          # nixpkgs build strips it. Distribution is disabled, so it is inert.
          RELEASE_COOKIE = "atuin-ai-server";
          RELEASE_TMP = cacheDir;
          HOME = "/Users/${username}";
        } // lib.optionalAttrs (serverAiKey != null) { AUTH_TOKEN = serverAiKey; };

        serviceConfig = {
          UserName = username;
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = logFile;
          StandardErrorPath = logFile;
        };
      };
    })
  ];
}
