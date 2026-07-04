{ ... }: {
  imports = [
    # nix-darwin does not ship a flake-parts flakeModule; `flake.darwinConfigurations`
    # is accepted by flake-parts' freeform `flake` attrset, so host files set it
    # directly. home-manager is wired via `darwinModules.home-manager` in
    # `mk-darwin.nix`, so we don't import its `flakeModules.home-manager` here.
  ];
}