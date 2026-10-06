{ lib, rustPlatform, src }:

# Standalone Rust TUI for annotating Markdown in the terminal
# (https://github.com/plannotator/plannotator-tui). Not in nixpkgs and upstream
# ships no flake, so we build the pinned source here. The whole dependency
# graph is crates.io-only (no git deps), so `cargoLock.lockFile` resolves and
# pins everything from the workspace lockfile without a separate cargo hash.
#
# The binary crate's dev-dependencies pull `rusqlite`/`libsqlite3-sys` with the
# `bundled` feature; `doCheck = false` avoids compiling a C SQLite just to run
# tests. nixpkgs' rustc (1.98) satisfies the workspace `rust-version = "1.96"`.
rustPlatform.buildRustPackage {
  pname = "plannotator-tui";
  version = "0.9.4";

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  doCheck = false;

  meta = {
    description = "Annotate Markdown in the terminal - standalone, and as a Herdr plugin";
    homepage = "https://github.com/plannotator/plannotator-tui";
    license = lib.licenses.mit;
    mainProgram = "plannotator-tui";
  };
}
