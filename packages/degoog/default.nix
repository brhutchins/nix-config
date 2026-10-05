{
  lib,
  pkgs,
  bun2nix,
  src,
}:

# A near-copy of DeGoog's own `third-party/nix/package.nix`, with the darwin
# installer backend flag added. DeGoog's flake only exposes Linux outputs
# because its checks/apps are a NixOS VM test, but the Bun app itself builds
# and runs natively on aarch64-darwin.
let
  app = bun2nix.writeBunApplication {
    inherit src;

    packageJson = "${src}/package.json";

    buildPhase = "bun run build";
    startScript = "bun run start";

    # Bump note: this substitutes one exact line of upstream `src/server/index.ts`.
    # `--replace-fail` makes a bump fail loudly if the line moved/changed, which
    # is the point — on a degoog input bump, re-check upstream: if DeGoog ever
    # binds a hostname itself, drop this patch.
    #
    # DeGoog's `Bun.serve` omits `hostname`, so it listens on 0.0.0.0 by default.
    # The plan requires loopback-only (the instance is reached directly on PLN and
    # via Tailscale Serve on MacMini, and an exposed settings page can install
    # server-side code), so bind it to 127.0.0.1 explicitly.
    postPatch = ''
      substituteInPlace src/server/index.ts \
        --replace-fail \
          'Bun.serve({ port, fetch: app.fetch, websocket, idleTimeout: 120 })' \
          'Bun.serve({ hostname: "127.0.0.1", port, fetch: app.fetch, websocket, idleTimeout: 120 })'
    '';

    bunDeps = bun2nix.fetchBunDeps {
      bunNix = pkgs.runCommandLocal "fetch-degoog-deps" { } ''
        ${lib.getExe bun2nix} --lock-file ${src}/bun.lock --output-file $out
      '';
    };

    # Store `git` for the git-clone transport and `curl` for the Curl transport.
    runtimeInputs = [
      pkgs.git
      pkgs.curl
    ];

    # The Nix store is read-only; Bun's default `clonefile` installer backend
    # fails on darwin. `--backend=symlink` gets `bun install` through, but then
    # packages resolve their own deps through the read-only store symlink
    # (e.g. sass requiring immutable), which breaks the build. `copyfile` makes
    # real copies in the writable build dir instead.
    bunInstallFlags = lib.optionals pkgs.stdenv.isDarwin [ "--backend=copyfile" ];

    # No `meta` here: bun2nix's mkDerivation sets `meta.mainProgram` and
    # extendMkDerivation's left-biased `//` merge clobbers the whole attrset,
    # dropping description/homepage/license. Applied below instead.
  };
in
app.overrideAttrs (old: {
  meta = (old.meta or { }) // {
    description = "Search engine aggregator with a comprehensive plugin/extension system";
    homepage = "https://github.com/degoog-org/degoog";
    license = lib.licenses.agpl3Only;
    mainProgram = "degoog";
  };
})
