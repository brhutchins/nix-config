{ lib, ... }: {
  flake = {
    systems = lib.mkDefault [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}