{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.local.tools.plannotator-tui;
  settingsFormat = pkgs.formats.toml { };

  system = pkgs.stdenv.hostPlatform.system;
  # herdr-annotate requires rustc >= 1.96; stable 26.05 ships 1.95.
  unstable = inputs.nixpkgs-unstable.legacyPackages.${system};

  package = pkgs.callPackage ../../../../packages/plannotator-tui {
    src = inputs.plannotator-tui;
  };

  # The full Herdr Annotate plugin directory (manifest + both binaries).
  herdrPlugin = pkgs.callPackage ../../../../packages/plannotator-tui-herdr-plugin {
    rustPlatform = unstable.rustPlatform;
    src = inputs.herdr-annotate;
    plannotator-tui = package;
  };
in
{
  options.local.tools.plannotator-tui = {
    enable = mkEnableOption "plannotator-tui terminal Markdown annotator";

    placement = mkOption {
      type = types.enum [ "overlay" "split" "popup" ];
      default = "overlay";
      description = ''
        How plannotator-tui opens inside Herdr. `overlay` is a real pane
        zoomed over the whole tab; Herdr restores focus and zoom on exit.
      '';
    };

    theme = mkOption {
      type = types.enum [ "auto" "light" "dark" ];
      default = "dark";
      description = ''
        UI palette. `auto` asks the terminal for its background colour once at
        startup (and can swallow a key pressed into that window); `dark`/`light`
        skip the question. The document itself always keeps the terminal's own
        colours.
      '';
    };

    herdr.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Register the Herdr Annotate plugin (terminal annotations plus
        document/reply review) by writing ~/.config/herdr/plugins.json.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    # plannotator-tui reads these from
    # $XDG_CONFIG_HOME/plannotator-tui/config.toml (see `plannotator-tui config`).
    # `deny_unknown_fields` upstream means only emit keys we actually set.
    xdg.configFile."plannotator-tui/config.toml".source =
      settingsFormat.generate "plannotator-tui-config.toml" {
        herdr.placement = cfg.placement;
        ui.theme = cfg.theme;
      };

    # Herdr's plugin registry is a plain JSON file read at startup; it re-parses
    # each entry's manifest from `manifest_path`, so a minimal entry is enough.
    # Managing it here (rather than running `herdr plugin link`) keeps the plugin
    # declarative. Consequence: Herdr's own install/uninstall/enable/disable
    # mutations fail against this read-only symlink, as with config.toml.
    xdg.configFile."herdr/plugins.json" = mkIf cfg.herdr.enable {
      text = builtins.toJSON [
        {
          plugin_id = "annotate";
          name = "Annotate";
          version = "0.8.0";
          manifest_path = "${herdrPlugin}/herdr-plugin.toml";
          plugin_root = "${herdrPlugin}";
          enabled = true;
        }
      ];
    };
  };
}
