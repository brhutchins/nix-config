{ pkgs, inputs, system, username, ... }:let
  maki = inputs.maki-nix.packages.${system}.default;
  herdr = inputs.herdr-nix.packages.${system}.default;
in {
  environment.systemPackages = [
    pkgs.vim
    pkgs.xh
    pkgs.hey
    pkgs.nodejs
    pkgs.azure-cli
    pkgs.code-cursor
    pkgs.unstable.cursor-cli
    pkgs.llama-cpp
    pkgs.unstable.opencode
    pkgs.unstable.pi-coding-agent
    pkgs.unstable.mcporter
    pkgs.nh
    maki
    herdr
  ];

  nix.package = pkgs.nix;
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.trusted-users = [ "${username}" ];

  programs.zsh.enable = true;
  programs.thaw.enable = true;
  programs.thaw.launchAtLogin = true;
}
