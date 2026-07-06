{ inputs, lib, ... }: {
  nixpkgs.overlays = [
    (self: super: {
      unstable = import inputs.nixpkgs-unstable {
        localSystem = super.stdenv.hostPlatform.system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "lmstudio"
        ];
      };
    })
    (self: super: {
      direnv = super.unstable.direnv;
    })
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "lmstudio"
    "raycast"
    "vim-choosewin"
    "blink-cmp-spell"
  ];
}
