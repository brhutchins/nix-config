{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.tools.tuicr;
  c = config.local.theme."rose-pine-slate".colors;
  settingsFormat = pkgs.formats.toml { };
in
{
  options.local.tools.tuicr = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to install tuicr and manage its configuration.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.unstable.tuicr ];

    xdg.configFile."tuicr/config.toml".source = settingsFormat.generate "tuicr-config.toml" {
      theme = "rose-pine-slate";
      diff_view = "side-by-side";
      comment_vim = true;
    };

    xdg.configFile."tuicr/themes/rose-pine-slate.toml".source = settingsFormat.generate "rose-pine-slate.toml" {
      panel_bg = c.base;
      bg_highlight = c.surface;
      fg_primary = c.text;
      fg_secondary = c.subtle;
      fg_dim = c.muted;

      diff_add = c.foam;
      diff_add_bg = c.surface;
      diff_del = c.love;
      diff_del_bg = c.overlay;
      diff_context = c.text;
      diff_hunk_header = c.iris;
      expanded_context_fg = c.muted;

      syntax_add_bg = c.surface;
      syntax_del_bg = c.overlay;

      file_added = c.foam;
      file_modified = c.gold;
      file_deleted = c.love;
      file_renamed = c.iris;

      reviewed = c.foam;
      pending = c.gold;

      comment_note = c.iris;
      comment_suggestion = c.foam;
      comment_issue = c.love;
      comment_praise = c.pine;

      border_focused = c.iris;
      border_unfocused = c.overlay;
      status_bar_bg = c.surface;
      cursor_color = c.gold;
      cursor_line_bg = c.overlay;
      branch_name = c.iris;
      help_indicator = c.muted;

      message_info_fg = c.base;
      message_info_bg = c.iris;
      message_warning_fg = c.base;
      message_warning_bg = c.gold;
      message_error_fg = c.base;
      message_error_bg = c.love;
      update_badge_fg = c.base;
      update_badge_bg = c.gold;

      mode_fg = c.base;
      mode_bg = c.iris;
    };
  };
}
