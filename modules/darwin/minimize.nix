{ lib, ... }: {
  options.local.darwin.minimize = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Drop the heavy always-on toolset (store-light host).";
  };
}
