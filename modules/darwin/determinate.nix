{ inputs, username, ... }: {
  imports = [ inputs.determinate.darwinModules.default ];
  determinateNix = {
    enable = true;
    customSettings = {
      trusted-users = [ "${username}" ];
    };
  };
}