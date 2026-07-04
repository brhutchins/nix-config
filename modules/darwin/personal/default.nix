{
  imports = [
    # Profile-only
    ../unfree-personal.nix
    ../packages-personal.nix
    ../llm.nix
    ../tsshd.nix
    ../devenv.nix
    ../determinate.nix
    ../homebrew-personal.nix

    # Shared
    ../aerospace.nix
    ../jankyborders.nix
    ../dev-tools.nix
    ../touchid.nix
    ../trackpad.nix
    ../homebrew-base.nix
  ];
}