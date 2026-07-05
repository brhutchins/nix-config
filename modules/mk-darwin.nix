{ inputs }:
let
  system = "aarch64-darwin";
  inherit (inputs) nix-darwin;
  data = import ./data;
in
{
  mkHost =
    {
      profile,
      home,
      hostConfig,
    }:
    let
      username = data.username;
    in
    nix-darwin.lib.darwinSystem {
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
