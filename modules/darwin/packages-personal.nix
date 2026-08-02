{ pkgs, inputs, system, ... }:
let
  lumen = inputs.lumen.packages.${system}.default;
  maki = inputs.maki-nix.packages.${system}.default;
  tiny-harness = inputs.tiny-harness-nix.packages.${system}.default;
  herdr = inputs.herdr-nix.packages.${system}.default;
in {
  environment.systemPackages = with pkgs; [
    raycast
    unstable.pi-coding-agent
    unstable.mcporter
    zed-editor
    ghostty-bin
    darktable
    unstable.gh-dash
    unstable.opencode
    unstable.nixd
    unstable.vhs
    llama-cpp
    lumen
    maki
    tiny-harness
    herdr
  ];
}
