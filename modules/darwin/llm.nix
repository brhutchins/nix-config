{ pkgs, ... }: {
  environment.systemPackages = [
    pkgs.unstable.lmstudio
  ];
}