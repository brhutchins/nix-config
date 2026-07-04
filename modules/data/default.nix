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
}
