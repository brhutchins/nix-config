{ pkgs, ... }: {
  # Registers fonts system-wide (/Library/Fonts/Nix Fonts) so GUI apps
  # (Emacs etc.) can see them — home.packages alone does not.
  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    hasklig
  ];
}
