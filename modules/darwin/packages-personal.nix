{ config, lib, pkgs, inputs, system, ... }:
let
  maki = inputs.maki-nix.packages.${system}.default;
  tiny-harness = inputs.tiny-harness-nix.packages.${system}.default;
  herdr = inputs.herdr-nix.packages.${system}.default;
in {
  environment.systemPackages = lib.mkMerge [
    (lib.mkIf (!config.local.darwin.minimize) (with pkgs; [
      zed-editor
      darktable
      llama-cpp
      # TeX toolchain host-wide; scheme-medium + preview.sty for AUCTeX
      # preview-latex (texlive.combined.* schemes don't include the preview pkg)
      (texlive.combine { inherit (texlive) scheme-medium preview csquotes; })
    ]))
    (with pkgs; [
      raycast
      unstable.pi-coding-agent
      mcporter
      ghostty-bin
      unstable.opencode
      unstable.nixd
      unstable.vhs
      maki
      tiny-harness
      herdr
    ])
  ];
}
