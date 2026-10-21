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
    flake-parts.url = "github:hercules-ci/flake-parts";
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # Source only: DeGoog's own flake outputs are Linux-only (its checks/apps
    # are a NixOS VM test), but the Bun app builds and runs natively on
    # aarch64-darwin via packages/degoog.
    degoog = {
      url = "github:degoog-org/degoog/1.0.0";
      flake = false;
    };
    herdr-nix = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # Prebuilt nix-index database (and the `nix-locate` wrapper that uses it),
    # so `nix-locate` works without building an index locally. Consumed by
    # pi-nixify's `nix` tool (`provides` action).
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-nix = {
      url = "github:earendil-works/pi/stable";
    };
    pi-vim = {
      url = "github:brhutchins/pi-vim";
      flake = false;
    };
    pi-research-mode = {
      url = "github:brhutchins/pi-research-mode";
      flake = false;
    };
    pi-nixify = {
      url = "github:brhutchins/pi-nixify";
      flake = false;
    };
    plannotator-tui = {
      url = "github:plannotator/plannotator-tui/v0.9.4";
      flake = false;
    };
    herdr-annotate = {
      url = "github:plannotator/herdr-annotate/cbba4732229191347ff5128e3da71f64474a6a49";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake/darwin-configurations.nix
        ./flake/inputs.nix
        ./flake/packages.nix
        ./flake/per-system.nix
        ./hosts/default.nix
      ];
    };
}
