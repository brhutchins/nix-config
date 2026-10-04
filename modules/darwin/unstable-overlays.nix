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

    # nixpkgs ships curl-impersonate 2.1.1, which lacks the chrome136/chrome142
    # profiles. `curl_cffi` 0.16.0 (used by pkgs.unstable.searxng) resolves its
    # bare "chrome" alias to chrome136, so nixpkgs' curl-cffi disables its
    # impersonation tests with "Impersonating chrome136 is not supported".
    # Upstream 2.2.2 adds chrome136/142/145/146/150 and its vendored deps
    # (curl, brotli, BoringSSL, nghttp2, ngtcp2, nghttp3, zlib, zstd, libidn2)
    # are identical to 2.1.1's deps.nix, so only `version` and `src` need to
    # change (overrideAttrs does not re-evaluate `src` from a new `version`).
    # The Darwin linker patch and the build-libidn2.sh substitution still apply
    # unchanged to v2.2.2 (verified against the tag commit).
    curl-impersonate = prev.curl-impersonate.overrideAttrs (old: {
      version = "2.2.2";
      src = prev.fetchFromGitHub {
        owner = "lexiforest";
        repo = "curl-impersonate";
        rev = "107d67f9f7a518334b1b11e4810637e70b2671a7"; # v2.2.2
        hash = "sha256-BrMhM18L/tLjGMKu6JUPOzeuUQzuSCZzcCyJPHJWp20=";
      };
    });
  })
]
