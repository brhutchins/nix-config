{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.local.tools.plannotator-tui;
  settingsFormat = pkgs.formats.toml { };

  package = pkgs.callPackage ../../../../packages/plannotator-tui {
    src = inputs.plannotator-tui;
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
  };
}
