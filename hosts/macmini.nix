{ self, inputs, ... }:
let
  mkHost = (import ../modules/mk-darwin.nix { inherit inputs; }).mkHost;
in {
  flake.darwinConfigurations.MacMini = mkHost {
    profile = ../modules/darwin/personal;
    home = ../home-manager/machines/darwin-personal.nix;
    hostConfig = { lib, pkgs, username, ... }: {
      local.darwin.minimize = true;

      local.darwin.atuinServer.enable = true;
      local.darwin.atuinAiServer.enable = true;
      local.darwin.tailscaleServe.enable = true;
      local.darwin.searxng = {
        enable = true;
        formats = [ "html" "json" ];
        baseUrl = "https://macmini.tail09722.ts.net/searxng/";
        # pkgs.unstable.searxng carries curl_cffi 0.16, which needs the
        # curl-impersonate 2.2.2 override for a current Chrome profile.
        package = pkgs.unstable.searxng;
      };

      system.stateVersion = 6;
      system.configurationRevision = self.rev or null;

      services.aerospace.settings.on-window-detected = [
        { "if".app-id = "com.apple.Music";               run = "move-node-to-workspace Audio"; }
        { "if".app-id = "com.apple.audio.AudioMIDISetup"; run = "move-node-to-workspace Audio"; }
        { "if".app-id = "net.whatsapp.WhatsApp";         run = "move-node-to-workspace Communications"; }
        { "if".app-id = "com.apple.MobileSMS";           run = "move-node-to-workspace Communications"; }
        { "if".app-id = "com.apple.mail";                run = "move-node-to-workspace Communications"; }
      ];

      services.aerospace.settings.workspace-to-monitor-force-assignment = {
        "1" = "main";
        "2" = "main";
        "Communications" = "built-in";
        "Meeting" = "built-in";
      };

      system.defaults.NSGlobalDomain._HIHideMenuBar = true;

      # Keep the server awake indefinitely. `power.sleep` is applied by
      # nix-darwin via `systemsetup` (which swallows errors), so the extra
      # `pmset` activation script covers the settings nix-darwin does not
      # expose (wake-on-LAN, Power Nap) and acts as a robust fallback.
      power = {
        sleep.computer = "never";
        sleep.harddisk = "never";
        sleep.allowSleepByPowerButton = false;
        restartAfterPowerFailure = true;
        restartAfterFreeze = true;
      };

      system.activationScripts.pmset.text = ''
        pmset -a sleep 0 disksleep 0 womp 1 powernap 1 tcpkeepalive 1
      '';
    };
  };
}

