{ username, ... }: {
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "${username}";

  users.users.${username}.home = "/Users/${username}";

  environment.variables.EDITOR = "nvim";

  system.defaults = {
    dock = {
      appswitcher-all-displays = true;
      autohide = true;
      mru-spaces = false;
      expose-group-apps = true;
    };
    finder = {
      AppleShowAllExtensions = true;
      CreateDesktop = false;
      FXDefaultSearchScope = "SCcf";
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
    };
  };

  services.tailscale.enable = true;
}
