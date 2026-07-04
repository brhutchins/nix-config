{
  imports = [
    # Profile-only
    ../unfree-work.nix
    ../packages-work.nix
    ../thaw.nix
    ../gc.nix
    ./zscaler.nix
    ./karabiner.nix
    ./yabai.nix
    ../homebrew-work.nix

    # Shared
    ../aerospace.nix
    ../jankyborders.nix
    ../dev-tools.nix
    ../touchid.nix
    ../trackpad.nix
    ../homebrew-base.nix
  ];
}