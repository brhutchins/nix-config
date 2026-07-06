{ inputs, lib, pkgs, ... }: {
  nixpkgs.overlays = [
    (self: super: {
      unstable = import inputs.nixpkgs-unstable {
        localSystem = super.stdenv.hostPlatform.system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "claude-code"
          "cursor-cli"
        ];
      };
    })
  ];

  nixpkgs.config.allowUnfreePredicate = let
    whitelist = map lib.getName [
      pkgs.claude-code
      pkgs.code-cursor
      pkgs.vimPlugins.vim-choosewin
      pkgs.vimPlugins.blink-cmp-spell
    ];
  in
    pkg: builtins.elem (lib.getName pkg) whitelist;
}
