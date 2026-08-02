{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.tools.gh-dash;
  c = config.local.theme."rose-pine-slate".colors;
  yamlFormat = pkgs.formats.yaml { };
in
{
  options.local.tools.gh-dash = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to install gh-dash and manage its configuration.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.unstable.gh-dash ];

    xdg.configFile."gh-dash/config.yml".source = yamlFormat.generate "gh-dash-config.yml" {
      prSections = [
        { title = "My Pull Requests"; filters = "is:open author:@me"; }
        { title = "Needs My Review"; filters = "is:open review-requested:@me"; }
        { title = "Involved"; filters = "is:open involves:@me -author:@me"; }
      ];

      issuesSections = [
        { title = "My Issues"; filters = "is:open author:@me"; }
        { title = "Assigned"; filters = "is:open assignee:@me"; }
        { title = "Involved"; filters = "is:open involves:@me -author:@me"; }
      ];

      defaults = {
        view = "prs";
        prsLimit = 20;
        issuesLimit = 20;
        notificationsLimit = 20;
        refetchIntervalMinutes = 30;
        prApproveComment = "LGTM";
        preview = {
          open = true;
          width = 0.45;
          height = 0.60;
          position = "auto";
        };
      };

      theme.colors = {
        text = {
          primary = c.text;
          secondary = c.subtle;
          inverted = c.base;
          faint = c.muted;
          warning = c.love;
          success = c.foam;
        };
        background.selected = c.overlay;
        border = {
          primary = c.overlay;
          secondary = c.surface;
          faint = c.surface;
        };
      };

      pager.diff = "tuicr";
    };
  };
}
