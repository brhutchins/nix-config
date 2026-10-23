{ pkgs, inputs, system, username, ... }:let
  maki = inputs.maki-nix.packages.${system}.default;
  herdr = inputs.herdr-nix.packages.${system}.default;
in {
  environment.systemPackages = [
    pkgs.vim
    pkgs.xh
    pkgs.hey
    pkgs.nodejs
    (pkgs.azure-cli.withExtensions [
      pkgs.azure-cli.extensions.azure-devops
    ])
    pkgs.code-cursor
    pkgs.unstable.cursor-cli
    pkgs.llama-cpp
    pkgs.unstable.opencode
    pkgs.mcporter
    pkgs.nh
    pkgs.ytt
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
