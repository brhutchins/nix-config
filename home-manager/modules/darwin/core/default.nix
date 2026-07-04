{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.darwin.core;
  stackline = pkgs.callPackage ../../../../packages/stackline {  };
in
{
  options.local.darwin.core = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

  };

  config = mkIf cfg.enable {

    home.shellAliases = {
      fw = "aerospace list-windows --all | fzf --bind 'enter:execute(bash -c \"aerospace focus --window-id {1}\")+abort'";
    };

    #####
    # Karabiner Elements

    home.file.".config/karabiner/karabiner.json" = {
      text = builtins.toJSON {
        global.show_in_menu_bar = false;
        profiles = [
          {
            complex_modifications = {
              parameters."basic.to_delayed_action_delay_milliseconds" = 200;
              rules = [
                {
                  manipulators = [
                    {
                      description = "Change caps_lock to hyper + escape.";
                      from = {
                        key_code = "caps_lock";
                        modifiers.optional = [ "any" ];
                      };
                      to = [
                        {
                          key_code = "left_shift";
                          modifiers = [ "left_command" "left_control" "left_option" ];
                        }
                      ];
                      to_if_alone = [ { key_code = "escape"; } ];
                      type = "basic";
                    }
                  ];
                }
                {
                  manipulators = [
                    {
                      description = "Backspace";
                      from = {
                        modifiers.optional = [ "any" ];
                        simultaneous = [
                          { key_code = "semicolon"; }
                          { key_code = "a"; }
                        ];
                      };
                      to = [ { key_code = "delete_or_backspace"; } ];
                      type = "basic";
                    }
                  ];
                }
              ];
            };
            devices = [
              {
                identifiers = {
                  is_keyboard = true;
                  product_id = 34304;
                  vendor_id = 1452;
                };
                ignore = true;
              }
            ];
            fn_function_keys = [
              {
                from.key_code = "f6";
                to = [ { key_code = "f6"; } ];
              }
            ];
            name = "Default profile";
            selected = true;
            virtual_hid_keyboard = {
              country_code = 0;
              keyboard_type_v2 = "iso";
            };
          }
        ];
      };
      force = true;
    };

  };
}
