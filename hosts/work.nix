{ self, inputs, ... }:
let
  mkHost = (import ../modules/mk-darwin.nix { inherit inputs; }).mkHost;
in {
  flake.darwinConfigurations.PLN = mkHost {
    profile = ../modules/darwin/work;
    home = ../home-manager/machines/darwin-pln.nix;
    hostConfig = {
      system.stateVersion = 4;  # DO NOT change
      system.configurationRevision = self.rev or null;

      services.aerospace.settings.on-window-detected = [
        { "if".app-id = "com.tinyspeck.slackmacap";    run = "move-node-to-workspace Communications"; }
        { "if".app-id = "com.microsoft.teams2";        run = "move-node-to-workspace Meeting"; }
        { "if".app-id = "io.pomerium.PomeriumDesktop"; run = "move-node-to-workspace Utilities"; }
        { "if".app-id = "com.apple.Music";             run = "move-node-to-workspace Audio"; }
        { "if".app-id = "com.apple.audio.AudioMIDISetup"; run = "move-node-to-workspace Audio"; }
      ];

      services.aerospace.settings.workspace-to-monitor-force-assignment = {
        "Communications" = "built-in";
        "Meeting" = "built-in";
      };

      system.defaults.NSGlobalDomain._HIHideMenuBar = true;
    };
  };
}
