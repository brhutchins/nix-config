let
  # Private values loaded from TOML at eval time (requires --impure).
  # File lives outside the repo (in ~/.config/nix-config/) so it's
  # never part of the flake source.
  homeDir     = builtins.getEnv "HOME";
  configDir   = homeDir + "/.config/nix-config";
  privateFile = configDir + "/private.toml";
  private = if builtins.pathExists privateFile
            then fromTOML (builtins.readFile privateFile)
            else throw ''
              Private config not found at ~/.config/nix-config/private.toml.

              Copy the template to get started:
                cp ${toString ./private.toml.example} ~/.config/nix-config/private.toml

              Then run with --impure:
                darwin-rebuild switch --flake .#HOST --impure
            '';

  # Safely drill into the private attrset using or-default at each level.
  git        = private.git or {};
  userName   = git.userName or {};
  signingKey = git.signingKey or {};
  email      = private.email or {};
  atuin       = private.atuin or {};
  atuinSync   = atuin.sync or {};
  atuinAi     = atuin.ai or {};
  atuinAiClient = atuinAi.client or {};
  atuinAiServer = atuinAi.server or {};
in {

  username = private.username or "user";

  email = {
    personal = email.personal or "personal@example.com";
    work = email.work or "work@example.com";
  };

  git = {
    userName = {
      personal = userName.personal or "personal-username";
      work = userName.work or "work-username";
    };
    signingKey = {
      # Just the key name (e.g. "id_ed25519"), no path or .pub suffix.
      personal = signingKey.personal or "id_ed25519";
      work = signingKey.work or "id_ed25519_work";
    };
  };

  # Atuin, split by concern:
  #   sync.*        — this host's CLI sync target
  #   ai.client.*   — this host's CLI: the AI bridge it calls and the token it presents
  #   ai.server.*   — the AI bridge hosted here: advertised models, the token it
  #                   requires from clients, and the token it sends upstream
  # Missing keys stay null (absent, not "") so gated modules can detect
  # "not configured" rather than deploying a broken value.
  atuin = {
    sync = {
      address = atuinSync.address or null;
    };
    ai = {
      client = {
        endpoint = atuinAiClient.endpoint or null;
        key = atuinAiClient.key or null;
      };
      server = {
        models = atuinAiServer.models or [];
        upstream = atuinAiServer.upstream or "http://localhost:8001/v1";
        key = atuinAiServer.key or null;
        inferenceKey = atuinAiServer.inferenceKey or null;
      };
    };
  };
}
