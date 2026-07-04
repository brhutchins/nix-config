{
  description = "Multi-host Darwin flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
    };
    mole-nix = {
      url = "github:brhutchins/mole-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    maki-nix = {
      url = "github:tontinton/maki/";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    tiny-harness-nix = {
      url = "github:PTFOPlayer/TinyHarness/";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    lumen = {
      url = "github:jnsahaj/lumen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    herdr-nix = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake/darwin-configurations.nix
        ./flake/inputs.nix
        ./flake/per-system.nix
        ./hosts/default.nix
      ];
    };
}
