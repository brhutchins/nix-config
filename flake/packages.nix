{ inputs, lib, ... }:
{
  # Expose the custom packages as `self.packages.<system>.<name>` so hosts can
  # pass `package = self.packages.${system}.degoog` and `nix build .#<name>`
  # works. DeGoog is built with bun2nix, which supports aarch64-darwin,
  # aarch64-linux and x86_64-linux (nix-systems/triplet) — not x86_64-darwin,
  # which this flake still lists as a (untested) system.
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs { inherit system; };
    in
    {
      packages = {
        plannotator-tui = pkgs.callPackage ../packages/plannotator-tui {
          src = inputs.plannotator-tui;
        };
      } // lib.optionalAttrs (lib.hasAttr system inputs.bun2nix.packages) {
        degoog = pkgs.callPackage ../packages/degoog {
          bun2nix = inputs.bun2nix.packages.${system}.default;
          src = inputs.degoog;
        };
      };
    };
}
