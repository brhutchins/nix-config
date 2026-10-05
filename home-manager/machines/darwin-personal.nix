{ username, ... }: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bak";

  home-manager.users.${username} = { pkgs, ... }: {
    home = {
      stateVersion = "23.05";
      packages = with pkgs; [
        unstable.colima
        docker_29
      ];
    };

    imports = [ ../modules/core ];
    local = {
      core.gui.enable = true;
      editors.emacs.enable = true;
      tools.atuin.enable = true;
      tools.pi = {
        enable = true;
        searxngUrl = "https://macmini.tail09722.ts.net/searxng";
        degoogUrl = "https://macmini.tail09722.ts.net/degoog";
      };
    };
  };
}

