{ lib, stdenv, rustPlatform, src, plannotator-tui }:

# The Herdr Annotate "full" plugin directory (manifest + binaries) as a store
# path. Herdr resolves the manifest's relative commands (`./bin/...`,
# `$HERDR_PLUGIN_ROOT/scripts/...`) against this directory, so the two binaries
# are symlinked in under the names the manifest expects (`.exe` is an ordinary
# filename on macOS/Linux).
#
# The native terminal-annotation runtime (`herdr-annotate`) is built here;
# document/reply review reuses the plannotator-tui package. Its crate sets
# `rust-version = "1.96"` and Cargo enforces it, so the caller must pass a
# rustPlatform of at least 1.96 (nixpkgs-unstable; stable 26.05 is 1.95).
let
  runtime = rustPlatform.buildRustPackage {
    pname = "herdr-annotate";
    version = "0.2.0";

    src = "${src}/rust";

    cargoLock.lockFile = "${src}/rust/Cargo.lock";

    doCheck = false;

    meta.mainProgram = "herdr-annotate";
  };
in
stdenv.mkDerivation {
  pname = "plannotator-tui-herdr-plugin";
  version = "0.8.0";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/scripts"
    cp ${src}/herdr-plugin.toml "$out/herdr-plugin.toml"
    cp ${src}/scripts/plannotator-tui.sh "$out/scripts/plannotator-tui.sh"
    chmod +x "$out/scripts/plannotator-tui.sh"

    ln -s ${runtime}/bin/herdr-annotate "$out/bin/herdr-annotate.exe"
    ln -s ${plannotator-tui}/bin/plannotator-tui "$out/bin/plannotator-tui.exe"

    runHook postInstall
  '';

  meta = {
    description = "Herdr Annotate full plugin: terminal annotations plus document review via plannotator-tui";
    homepage = "https://github.com/plannotator/herdr-annotate";
    license = lib.licenses.mit;
  };
}
