{
  lib,
  pkgs,
  gleam,
  fetchFromGitHub,
  stdenvNoCC,
  cacert,
  git,
}:

let
  beamPackages = pkgs.beam.packages.erlang_27;

  version = "0.1.0-unstable-4d582bc5";

  src = fetchFromGitHub {
    owner = "atuinsh";
    repo = "atuin-ai-server";
    rev = "4d582bc5ceea5b5edfdcf3abb49dc850400cda7c";
    hash = "sha256-+Iqqd12yUHOSm29uHUeWs2Z9fnutH9fOoTLb9EdvPMY=";
  };

  # Stock fetchMixDeps can't help here: the project registers a custom `:gleam`
  # Mix compiler that runs `gleam build` inside the `atuin_ai_core` git dep
  # during `mix compile`. So the Gleam-side dependencies (hex packages plus the
  # `dream_http_client` git dep) must be downloaded into the fixed-output deps
  # tree as well.
  mixFodDeps = stdenvNoCC.mkDerivation {
    pname = "atuin-ai-server-mix-deps";
    inherit version src;

    nativeBuildInputs = [
      beamPackages.elixir
      beamPackages.hex
      beamPackages.rebar
      beamPackages.rebar3
      cacert
      git
      gleam
    ];

    env = {
      MIX_ENV = "prod";
      HEX_HTTP_CONCURRENCY = 1;
      HEX_HTTP_TIMEOUT = 120;
    };

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-jI0NjngwqFsdxahLB6uzTxlhpTA1RdwHbaWqxhObZOg=";

    impureEnvVars = lib.fetchers.proxyImpureEnvVars;

    configurePhase = ''
      runHook preConfigure
      export HOME="$TEMPDIR"
      export HEX_HOME="$TEMPDIR/.hex"
      export MIX_HOME="$TEMPDIR/.mix"
      export MIX_DEPS_PATH="$TEMPDIR/deps"
      export REBAR_GLOBAL_CONFIG_DIR="$TMPDIR/rebar3"
      export REBAR_CACHE_DIR="$TMPDIR/rebar3.cache"
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      mix deps.get --only prod
      ( cd "$MIX_DEPS_PATH/atuin_ai_core" && gleam deps download )
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      find "$MIX_DEPS_PATH" -path '*/.git/*' -a ! -name HEAD -exec rm -rf {} +
      cp -R --no-preserve=mode,ownership,timestamps "$MIX_DEPS_PATH" "$out"
      runHook postInstall
    '';
  };
in
beamPackages.mixRelease {
  pname = "atuin-ai-server";
  inherit version src mixFodDeps;

  nativeBuildInputs = [ gleam ];

  # Upstream hardcodes Bandit's default bind address, which is 0.0.0.0. The
  # service is meant to be loopback-only (Tailscale Serve terminates TLS and
  # proxies to 127.0.0.1); bind Bandit to loopback explicitly.
  postPatch = ''
    substituteInPlace lib/atuin_ai/server/application.ex \
      --replace-fail \
        "[{Bandit, plug: AtuinAI.Server.Router, port: config.port}]" \
        "[{Bandit, plug: AtuinAI.Server.Router, ip: :loopback, port: config.port}]"
  '';

  meta = {
    description = "Self-hosted bridge exposing an OpenAI-compatible endpoint as Atuin's CLI chat API";
    homepage = "https://github.com/atuinsh/atuin-ai-server";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
