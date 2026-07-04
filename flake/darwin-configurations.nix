{ lib, ... }:
let
  inherit (lib) mkOption types;
in {
  options = {
    flake.darwinConfigurations = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = { };
      description = ''
        Instantiated nix-darwin configurations. Used by `darwin-rebuild`.

        flake-parts does not ship this option (it only declares
        `nixosConfigurations`); without it, multiple hosts setting
        `flake.darwinConfigurations.<name>` collide on the freeform `unique`
        type. Declaring it here lets each host file contribute its own key.

        `types.lazyAttrsOf types.raw` evaluates each host's contribution
        independently and throws on duplicate keys (two modules setting the
        same `darwinConfigurations.<name>` surface as an eval-time error
        naming both files), so host-name collisions fail loudly rather than
        silently overwriting.
      '';
    };
  };
}