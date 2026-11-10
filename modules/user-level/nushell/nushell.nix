{
  config,
  pkgs,
  lib,
  weegsware,
  ...
}:
let
  wrappedNushell = weegsware.nushell;

  nushellPlugins = with pkgs.nushellPlugins; [
    formats
    # nixpkgs f4a03c0 sets LIBGIT2_NO_VENDOR but omits libgit2 from gstat's buildInputs, fixed on master
    (gstat.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.libgit2 ];
    }))
    query
    # semver # compiled for nushell 0.111.0, incompatible with 0.112.1
    # skim # compiled for nushell 0.111.0, incompatible with 0.112.1
  ];

  # Pre-generate plugin registry so plugins are available without manual `plugin add`
  pluginRegistry = pkgs.runCommand "nu-plugin-registry" { } ''
    mkdir -p "$out"
    ${lib.getExe pkgs.nushell} \
      --plugin-config "$out/plugin.msgpackz" \
      --commands '${lib.concatStringsSep "; " (map (p: "plugin add ${lib.getExe p}") nushellPlugins)}'
  '';

  # atuin init tries to create ~/.config/atuin/ -- give it a writable HOME inside the sandbox
  atuin-init = pkgs.runCommand "atuin-init" { HOME = "/tmp"; } ''
    mkdir -p "$out"
    ${lib.getExe pkgs.atuin} init nu > "$out/init.nu"
    # atuin names both of its keybindings "atuin", which nushell warns on as a duplicate
    sed -i '0,/name: atuin/s//name: atuin_search/' "$out/init.nu"
    sed -i 's/name: atuin$/name: atuin_up/' "$out/init.nu"
  '';

  colors = {
    base00 = "060404";
    base02 = "3d414b";
    base04 = "996666";
    base05 = "e8ecf1";
    base07 = "ff2a22";
    base08 = "a01018";
    base0C = "7b8494";
    base0D = "e8ecf1";
    base0F = "c6ccd5";
    # time_format runs through Go's time layout: the digits 1-5 and 06 in a hex color are replaced by the clock, so base04 and base0E avoid them
    base0E = "c6ccd6";
  };

  # kept as a nix attrset, not an extracted json: the triglavian palette interpolates from the shared `colors` set above instead of being hardcoded hex
  ompConfig = builtins.toJSON {
    "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
    "version" = 2;
    "console_title_template" = "{{ if .Root }}root @ {{ end }}{{ .Shell }} in {{ .Folder }}";
    "blocks" = [
      {
        "alignment" = "left";
        "type" = "prompt";
        "segments" = [
          {
            "type" = "os";
            "style" = "diamond";
            "leading_diamond" = "";
            "background" = "#${colors.base02}";
            "foreground" = "#${colors.base05}";
            "template" = " {{ if .WSL }} on {{ end }}{{ .Icon }} ";
            "properties" = {
              "alpine" = "";
              "arch" = "";
              "debian" = "";
              "fedora" = "";
              "linux" = "";
              "macos" = "";
              "manjaro" = "";
              "nixos" = "";
              "ubuntu" = "";
              "windows" = "";
            };
          }

          {
            "type" = "shell";
            "style" = "powerline";
            "powerline_symbol" = "";
            "background" = "#${colors.base0C}";
            "foreground" = "#${colors.base00}";
            "template" = "  {{ .Name }} ";
          }

          {
            "type" = "root";
            "style" = "powerline";
            "powerline_symbol" = "";
            "background" = "#${colors.base08}";
            "foreground" = "#${colors.base05}";
            "template" = "  admin ";
          }

          {
            "type" = "git";
            "style" = "powerline";
            "powerline_symbol" = "";
            "background" = "#${colors.base0F}";
            "foreground" = "#${colors.base00}";
            "background_templates" = [
              "{{ if or (.Working.Changed) (.Staging.Changed) }}#${colors.base07}{{ end }}"
              "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#ff8480{{ end }}"
              "{{ if gt .Ahead 0 }}#e8ecf1{{ end }}"
              "{{ if gt .Behind 0 }}#a9b4c9{{ end }}"
            ];
            "properties" = {
              "branch_icon" = " ";
              "fetch_status" = true;
              "fetch_upstream_icon" = true;
              "fetch_worktree_count" = true;
              "disable_with_jj" = true;
            };
            "template" =
              " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }}<#${colors.base00}>  {{ .Staging.String }}</>{{ end }}{{ if gt .StashCount 0 }}  {{ .StashCount }}{{ end }} ";
          }
          {
            "type" = "jujutsu";
            "style" = "powerline";
            "powerline_symbol" = "";
            "background" = "#${colors.base0F}";
            "foreground" = "#${colors.base00}";
            "background_templates" = [
              "{{ if .Working.Changed }}#${colors.base07}{{ end }}"
            ];
            "properties" = {
              "fetch_status" = true;
              "ignore_working_copy" = false;
            };
            "template" =
              " {{ if .ClosestBookmarks }}{{ .ClosestBookmarks }}{{ else }}{{ .ChangeID }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }} ";
          }
        ];
      }

      {
        "alignment" = "right";
        "type" = "prompt";
        "segments" = [
          {
            "type" = "status";
            "style" = "diamond";
            "leading_diamond" = "";
            "background" = "#${colors.base0F}";
            "foreground" = "#${colors.base00}";
            "background_templates" = [
              "{{ if gt .Code 0 }}#c5141e{{ end }}"
            ];
            "foreground_templates" = [
              "{{ if gt .Code 0 }}#${colors.base05}{{ end }}"
            ];
            "properties" = {
              "always_enabled" = true;
            };
            "template" = " {{ if gt .Code 0 }}{{ else }}λ{{ end }} ";
          }

          {
            "type" = "executiontime";
            "style" = "diamond";
            "trailing_diamond" = "";
            "background" = "#${colors.base02}";
            "foreground" = "#${colors.base05}";
            "properties" = {
              "style" = "roundrock";
              "threshold" = 0;
            };
            "template" = "  {{ .FormattedMs }} ";
          }
        ];
      }

      {
        "alignment" = "left";
        "type" = "prompt";
        "newline" = true;
        "segments" = [
          {
            "type" = "text";
            "style" = "plain";
            "foreground" = "#${colors.base07}";
            "template" = "╭─";
          }

          {
            "type" = "time";
            "style" = "plain";
            "foreground" = "#${colors.base04}";
            "properties" = {
              "time_format" =
                "<#${colors.base0E}> 15:04:05</> <#${colors.base04}>|</> <#${colors.base0E}> 2 Jan, Monday</> <#${colors.base04}>|</>";
            };
            "template" = "{{ .CurrentDate | date .Format }}";
          }

          {
            "type" = "path";
            "style" = "diamond";
            "leading_diamond" = "<#${colors.base07}>  </><#${colors.base0D}> in </>";
            "foreground" = "#${colors.base0D}";
            "properties" = {
              "folder_icon" = "  ";
              "folder_separator_icon" = "  ";
              "home_icon" = " ";
              "style" = "agnoster_short";
              "max_depth" = 3;
            };
            "template" = " {{ .Path }} ";
          }
        ];
      }

      {
        "alignment" = "left";
        "type" = "prompt";
        "newline" = true;
        "segments" = [
          {
            "type" = "text";
            "style" = "plain";
            "foreground" = "#${colors.base07}";
            "template" = "╰─";
          }

          {
            "type" = "status";
            "style" = "plain";
            "foreground" = "#${colors.base07}";
            "properties" = {
              "always_enabled" = true;
            };
            "template" = "❯ ";
          }
        ];
      }
    ];
    "osc99" = true;
    "transient_prompt" = {
      "background" = "transparent";
      "foreground" = "#${colors.base07}";
      "template" = " ";
    };
    "secondary_prompt" = {
      "background" = "transparent";
      "foreground" = "#${colors.base07}";
      "template" = "╰─❯ ";
    };
  };
in
{
  config = {
    programs.fish.enable = true;

    # fish forces the runtime man cache, which copies every man page into /var/cache/man on the 256M root tmpfs
    preservation.preserveAt."/cache".directories = [
      {
        directory = "/var/cache/man";
        user = "mandb";
        group = "mandb";
        mode = "0755";
      }
    ];

    users.users.${config.mySystem.user.name}.packages = [
      pkgs.atuin
      pkgs.fish
      pkgs.fzf
      pkgs.oh-my-posh
      pkgs.tldr
      pkgs.zoxide
      wrappedNushell
    ];

    hjem.users.${config.mySystem.user.name}.xdg.config.files = {
      "oh-my-posh/config.json".text = ompConfig;

      "nushell/plugin.msgpackz".source = "${pluginRegistry}/plugin.msgpackz";
      "nushell/atuin-init.nu".source = "${atuin-init}/init.nu";

      "nushell/env.nu".source = ./env.nu;

      "nushell/config.nu".text = builtins.readFile ./config.nu + config.mySystem.nushell.extraConfig;

      # Empty by design - all initialization in env.nu for consistency
      "nushell/login.nu".text = "";
    };

    preservation.preserveAt."/persist".users.${config.mySystem.user.name}.directories = [
      ".config/nushell"
      ".config/atuin"
      ".config/carapace"
      ".local/share/atuin"
      ".local/share/nushell"
      ".local/share/zoxide"
    ];
  };
}
