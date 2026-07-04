{ pkgs, ... }: {
  launchd.user.agents.nix-garbage-collector = {
    command = "${pkgs.nh}/bin/nh clean --keep 5";
    serviceConfig = {
      RunAtLoad = false;
      StartCalendarInterval = [
        { Hour = 4; Minute = 15; Weekday = 7; }
      ];
    };
  };
}