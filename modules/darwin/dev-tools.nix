{ pkgs, inputs, system, ... }:
let
  mole = inputs.mole-nix.packages.${system}.default;
in {
  environment.systemPackages = [
    mole
    pkgs.unstable.gitu
  ];
}