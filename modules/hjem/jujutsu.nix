{...}: {
  flake.nixosModules.jujutsu = {
    config,
    pkgs,
    ...
  }: let
    username = config.mySystem.user.name;
  in {
    config = {
      users.users.${username}.packages = [pkgs.jujutsu];

      hjem.users.${username} = {
        xdg.config.files."jj/config.toml".text = ''
          #:schema https://docs.jj-vcs.dev/latest/config-schema

          [user]
            name = "weegs710"
            email = "weegs@tutamail.com"

          [ui]
            default-command = "log"
            pager = "bat"

          [git]
            auto-local-branch = true

          [remotes.origin]
            auto-track-bookmarks = "*"

          [aliases]
          l = ["log"]
          d = ["diff"]
          bm = ["bookmark", "move", "main", "--to", "@"]
          push = ["git", "push", "--branch", "main"]
          fetch = ["git", "fetch"]
        '';
      };
    };
  };
}
