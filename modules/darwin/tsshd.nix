{ pkgs, username, ... }:
let
  tsshd = pkgs.unstable.tsshd;
in {
  environment.systemPackages = [
    tsshd
  ];

  launchd.agents.tsshd = {
    command = "${tsshd}/bin/tsshd serve";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/${username}/.tsshd.log";
      StandardErrorPath = "/Users/${username}/.tsshd.log";
    };
  };
}