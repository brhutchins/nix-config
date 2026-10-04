# Overlays applied to the nixpkgs-unstable instance that `unfree-personal.nix`
# and `unfree-work.nix` import as `pkgs.unstable`. They affect only that
# instance, so the pinned stable nixpkgs is untouched.
[
  (final: prev: {
    # nixpkgs pins ketch 0.14.0; track the current release instead. 0.14.0's
    # default search backend is `brave` and needs a key, whereas 0.16+ has the
    # keyless `auto` fallback chain and newer providers/backends, so this is a
    # real upgrade rather than cosmetic.
    #
    # TestRegistryConfigCompatibilityGolden snapshots a dev build's user_agent
    # ("ketch/dev"), but Nix stamps the release version via the package's own
    # ldflags, which buildGoModule also passes to `go test`, so that one golden
    # differs (only in user_agent). The versionCheckHook install check still
    # verifies `ketch version`, so the release stamp is still exercised.
    ketch = prev.ketch.overrideAttrs (old: {
      version = "0.18.1";
      src = prev.fetchFromGitHub {
        owner = "1broseidon";
        repo = "ketch";
        tag = "v0.18.1";
        hash = "sha256-vXSYQJBZ0Eypy3S0qvJUEEk9SZnnIWmQ5DU3TGyuwfk=";
      };
      vendorHash = "sha256-NqZlxCbXfH4OJQGEVQwA6uu5LLlKDmwGYDRM6V8U/+4=";
      checkFlags = (old.checkFlags or [ ]) ++ [ "-skip" "TestRegistryConfigCompatibilityGolden" ];
    });
  })
]
