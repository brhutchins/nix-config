{ inputs }:
let
  system = "aarch64-darwin";
  pkgs = import inputs.nixpkgs { inherit system; };
  nix-darwin-src = pkgs.runCommand "nix-darwin-patched" { } ''
    cp -R ${inputs.nix-darwin} "$out"
    chmod -R u+w "$out"
    substituteInPlace "$out/modules/homebrew.nix" \
      --replace-fail '++ optional (config.cleanup == "uninstall") "--force-cleanup"' '++ optional (config.cleanup == "uninstall") "--cleanup"' \
      --replace-fail '++ optional (config.cleanup == "zap") "--zap --force-cleanup"' '++ optional (config.cleanup == "zap") "--cleanup --zap"'
  '';
  nix-darwin-patched = pkgs.applyPatches {
    name = "nix-darwin-patched";
    src = nix-darwin-src;
    patches = [ ];
  };
  nix-darwin = pkgs.lib.fix (self:
    (import "${nix-darwin-patched}/flake.nix").outputs {
      inherit self;
      nixpkgs = inputs.nixpkgs;
    });
  data = import ./data;
in {
  mkHost = { profile, home, hostConfig }:
    let
      username = data.username;
    in nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs system username; };
      modules = [
        ./overlays.nix
        ./darwin/common.nix
        profile
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs system username; };
          home-manager.sharedModules = [ inputs.nixvim.homeModules.nixvim ];
        }
        home
        hostConfig
      ];
    };
}
