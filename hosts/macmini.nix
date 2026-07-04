{ self, inputs, ... }:
let
  mkHost = (import ../modules/mk-darwin.nix { inherit inputs; }).mkHost;
in {
  flake.darwinConfigurations.MacMini = mkHost {
    profile = ../modules/darwin/personal;
    home = ../home-manager/machines/darwin-personal.nix;
    hostConfig = {
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
    };
  };
}

