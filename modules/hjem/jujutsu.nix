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
            pager = ":builtin"
            editor = "zeditor"

          [git]
            auto-local-branch = true

          [remotes.origin]
            auto-track-bookmarks = "*"

          [remotes.codeberg]
            auto-track-bookmarks = "*"

          # ============================================================================
          # REVSET ALIASES - Define commonly used revision patterns
          # ============================================================================
          [revset-aliases]
          'trunk()' = 'main@origin'
          'closest_bookmark(to)' = 'heads(::to & bookmarks())'
          'recent()' = 'ancestors(reachable(@, mutable()), 2)'
          'stack(x)' = 'ancestors(x) ~ ancestors(trunk())'

          # ============================================================================
          # ALIASES - Optimized for NixOS flake dotfiles management
          # See ~/dotfiles/docs/jj-workflow.md for detailed workflow guide
          # ============================================================================
          [aliases]
          # Viewing & Status
          s = ["status"]
          st = ["status"]
          l = ["log", "-r", "recent()"]
          ll = ["log", "-T", "builtin_log_detailed"]
          la = ["log", "-r", "all()"]
          lg = ["log", "--limit", "20"]

          # Diffs
          d = ["diff"]
          dp = ["diff", "@-"]
          ds = ["diff", "--stat"]

          # File Tracking (CRITICAL for NixOS flakes - untracked files invisible to Nix)
          t = ["file", "track"]
          ta = ["file", "track", "."]
          ut = ["file", "untrack"]
          ls = ["file", "list"]
          lsr = ["file", "list", "-r"]

          # Change Creation & Editing
          n = ["new"]
          ne = ["new", "@-"]
          nt = ["new", "trunk()"]
          nm = ["new", "-m"]
          e = ["edit"]
          desc = ["describe"]
          dm = ["describe", "-m"]
          c = ["commit"]
          ci = ["commit", "--interactive"]

          # Change Manipulation
          sq = ["squash"]
          sqi = ["squash", "--interactive"]
          sqf = ["squash", "--from"]
          sqt = ["squash", "--into"]
          sp = ["split"]
          spi = ["split", "--interactive"]
          spp = ["split", "--parallel"]
          ab = ["absorb"]

          # Rebasing
          r = ["rebase"]
          rt = ["rebase", "-d", "trunk()"]
          retrunk = ["rebase", "-d", "trunk()"]
          rba = ["rebase", "-s", "all:roots(trunk()..mutable())", "-d", "trunk()"]
          reheat = ["rebase", "-d", "trunk()", "-s", "all:roots(trunk()..stack(@))"]

          # Bookmarks
          b = ["bookmark"]
          bl = ["bookmark", "list"]
          bc = ["bookmark", "create"]
          bs = ["bookmark", "set"]
          bm = ["bookmark", "move"]
          bd = ["bookmark", "delete"]
          nb = ["bookmark", "create", "-r", "@-"]
          tug = ["bookmark", "move", "--from", "closest_bookmark(@-)", "--to", "@-"]

          # Git Remotes
          f = ["git", "fetch"]
          fo = ["git", "fetch", "--remote", "origin"]
          fc = ["git", "fetch", "--remote", "codeberg"]
          p = ["git", "push"]
          pc = ["git", "push", "--remote", "codeberg"]
          push = ["git", "push", "--remote", "origin", "--branch", "main"]
          fetch = ["git", "fetch"]

          # History Exploration & Cleanup
          opl = ["operation", "log", "--limit", "20"]
          u = ["undo"]
          sh = ["show"]
          shp = ["show", "@-"]
          ae = ["abandon", "empty()"]
          hideempty = ["hide", "empty() & mutable() ~ root()"]

          # Conflict Resolution
          conflicts = ["log", "-r", "conflicts()"]

          [revsets]
          log = "coalesce(trunk(),root())::present(@) | ancestors(visible_heads() & recent(), 2)"

          [templates]
          format_short_change_id = 'id.shortest()'
        '';
      };
    };
  };
}
