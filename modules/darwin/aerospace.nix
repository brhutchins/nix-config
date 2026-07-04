{ pkgs, ... }:
let
  jankyborders = pkgs.unstable.jankyborders;
  border-color = {
    active = "0xffff70b3";
    warning = "0xfffffd82";
    warning-2 = "0xfff5f100";
    warning-3 = "0xffB8B500";
    inactive = "0x00000000";
  };
  borders = color:
    "exec-and-forget ${jankyborders}/bin/borders active_color=${color}";
in {
  services.aerospace = {
    enable = true;
    settings = {
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      gaps = {
        outer.left = 2;
        outer.bottom = 2;
        outer.top = 2;
        outer.right = 2;
        inner.horizontal = 8;
        inner.vertical = 8;
      };
      key-mapping = {
        key-notation-to-key-code = {
          # Remap for Colemak.
          q = "q";
          w = "w";
          f = "e";
          p = "r";
          g = "t";
          j = "y";
          l = "u";
          u = "i";
          y = "o";
          semicolon = "p";
          leftSquareBracket = "leftSquareBracket";
          rightSquareBracket = "rightSquareBracket";
          backslash = "backslash";

          a = "a";
          r = "s";
          s = "d";
          t = "f";
          d = "g";
          h = "h";
          n = "j";
          e = "k";
          i = "l";
          o = "semicolon";
          quote = "quote";

          z = "z";
          x = "x";
          c = "c";
          v = "v";
          b = "b";
          k = "n";
          m = "m";
          comma = "comma";
          period = "period";
          slash = "slash";
        };
      };

      mode.main.binding = {
        # Workspaces.
        cmd-ctrl-alt-shift-1 = "workspace 1";
        cmd-ctrl-alt-shift-2 = "workspace 2";
        cmd-ctrl-alt-shift-3 = "workspace 3";
        cmd-ctrl-alt-shift-4 = "workspace 4";
        cmd-ctrl-alt-shift-5 = "workspace 5";
        cmd-ctrl-alt-shift-a = "workspace Audio";
        cmd-ctrl-alt-shift-s = "workspace Communications";
        cmd-ctrl-alt-shift-m = "workspace Meeting";
        cmd-ctrl-alt-shift-u = "workspace Utilities";
        cmd-ctrl-alt-shift-h = "workspace Home";

        alt-shift-w = "mode workspace";
        cmd-ctrl-alt-shift-semicolon = [ "mode navigation" "${borders border-color.warning}" ];
      };

      mode.navigation.binding = {
        esc = [ "mode main" "${borders border-color.active}" ];

        cmd-ctrl-alt-shift-semicolon = [ "mode workspace" "${borders border-color.warning-2}" ];

        h = "focus left";
        j = "focus down";
        k = "focus up";
        l = "focus right";

        shift-h = "move left";
        shift-j = "move down";
        shift-k = "move up";
        shift-l = "move right";

        alt-shift-h = [ "join-with left" ];
        alt-shift-j = [ "join-with up" ];
        alt-shift-k = [ "join-with down" ];
        alt-shift-l = [ "join-with right" ];

        minus = "resize smart -50";
        equal = "resize smart +50";

        space = [ "fullscreen" ];
      };

      mode.workspace.binding = {
        esc = [ "mode main" "${borders border-color.active}" ];

        cmd-ctrl-alt-shift-semicolon = [ "mode service" "${borders border-color.warning-3}" ];

        "1" = [ "workspace 1" "mode main" "${borders border-color.active}" ];
        "2" = [ "workspace 2" "mode main" "${borders border-color.active}" ];
        "3" = [ "workspace 3" "mode main" "${borders border-color.active}" ];
        "4" = [ "workspace 4" "mode main" "${borders border-color.active}" ];
        "5" = [ "workspace 5" "mode main" "${borders border-color.active}" ];
        "a" = [ "workspace Audio" "mode main" "${borders border-color.active}" ];
        "s" = [ "workspace Communications" "mode main" "${borders border-color.active}" ];
        "m" = [ "workspace Meeting" "mode main" "${borders border-color.active}" ];
        "u" = [ "workspace Utilities" "mode main" "${borders border-color.active}" ];
        "h" = [ "workspace Home" "mode main" "${borders border-color.active}" ];

        alt-1 = [ "move-node-to-workspace 1" "mode main" "${borders border-color.active}" ];
        alt-2 = [ "move-node-to-workspace 2" "mode main" "${borders border-color.active}" ];
        alt-3 = [ "move-node-to-workspace 3" "mode main" "${borders border-color.active}" ];
        alt-4 = [ "move-node-to-workspace 4" "mode main" "${borders border-color.active}" ];
        alt-5 = [ "move-node-to-workspace 5" "mode main" "${borders border-color.active}" ];
        alt-a = [ "move-node-to-workspace Audio" "mode main" "${borders border-color.active}" ];
        alt-s = [ "move-node-to-workspace Communications" "mode main" "${borders border-color.active}" ];
        alt-m = [ "move-node-to-workspace Meeting" "mode main" "${borders border-color.active}" ];
        alt-u = [ "move-node-to-workspace Utilities" "mode main" "${borders border-color.active}" ];
        alt-h = [ "move-node-to-workspace Home" "mode main" "${borders border-color.active}" ];

        tab = [ "move-workspace-to-monitor --wrap-around next" "mode main" "${borders border-color.active}" ];
      };

      mode.service.binding = {
        esc = [ "mode main" "${borders border-color.active}" ];

        r = [ "flatten-workspace-tree" "mode main" "${borders border-color.active}" ]; # reset layout
        space = [ "layout floating tiling" "mode main" "${borders border-color.active}" ]; # Toggle between floating and tiling layout

        slash = "layout tiles horizontal vertical";
        comma = "layout accordion horizontal vertical";
      };
    };
  };
}
