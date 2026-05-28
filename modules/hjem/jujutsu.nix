{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  config = {
    users.users.${username}.packages = [ pkgs.jujutsu ];

    hjem.users.${username} = {
      xdg.config.files."jj/config.toml".text = ''
        #:schema https://docs.jj-vcs.dev/latest/config-schema

        [user]
          name = "weegs710"
          email = "weegs@tutamail.com"

        [ui]
          pager = ":builtin"
          editor = "emacsclient -nw --alternate-editor='emacs -nw'"

        [git]
          auto-local-branch = true

        [remotes.origin]
          auto-track-bookmarks = "*"

        [remotes.codeberg]
          auto-track-bookmarks = "*"

        # ============================================================================
        # REVSET ALIASES
        # ============================================================================
        [revset-aliases]
        'trunk()' = 'main@origin'
        'closest_bookmark(to)' = 'heads(::to & bookmarks())'
        'recent()' = 'ancestors(reachable(@, mutable()), 2)'

        # ============================================================================
        # ALIASES
        # ============================================================================
        [aliases]
        # Viewing & Status
        s = ["status"]
        l = ["log", "-r", "recent()"]
        ll = ["log", "-T", "builtin_log_detailed"]

        # Diffs
        d = ["diff"]
        dp = ["diff", "@-"]
        ds = ["diff", "--stat"]

        # Change Creation & Editing
        n = ["new"]
        dm = ["describe", "-m"]

        # Change Manipulation
        sq = ["squash"]
        sp = ["split"]
        spi = ["split", "--interactive"]

        # Bookmarks
        bs = ["bookmark", "set"]
        tug = ["bookmark", "move", "--from", "closest_bookmark(@-)", "--to", "@-"]

        # Git Remotes
        f = ["git", "fetch"]
        p = ["git", "push"]

        # History
        u = ["undo"]

        [templates]
        format_short_change_id = 'id.shortest()'
      '';
    };
  };
}
