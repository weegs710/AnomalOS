{
  config,
  pkgs,
  lib,
  ...
}:
let
  username = config.mySystem.user.name;
  home = config.users.users.${username}.home;
  flakePath = "${home}/repo/public/anomalos";

  # overrideScope propagates the patched lsp-mode to all dependent packages (lsp-ui, lsp-pyright, etc.)
  emacsPackages = (pkgs.emacsPackagesFor pkgs.emacs30-pgtk).overrideScope (
    final: prev: {
      lsp-mode = prev.lsp-mode.overrideAttrs (old: {
        # lsp-interface macro bakes gethash/plist-get at compile time -- postUnpack patches before all 6 top-level callers compile
        postUnpack = (old.postUnpack or "") + ''
          sed -i 's|(defvar lsp-use-plists (getenv "LSP_USE_PLISTS"))|(defvar lsp-use-plists t)|' \
            "$NIX_BUILD_TOP/$sourceRoot/lsp-protocol.el"
        '';
      });
    }
  );

  majutsu = emacsPackages.trivialBuild {
    pname = "majutsu";
    version = "0-unstable-2026-05-18";
    src = pkgs.fetchFromGitHub {
      owner = "0WD0";
      repo = "majutsu";
      rev = "aebd5acdecd1fa6de249dabd274b963cd73d3bfc";
      hash = "sha256-syZEyoP0p1B/Mw5X98Wb9yxbVRygtxU+WzSYn2QivNQ=";
    };
    packageRequires = with emacsPackages; [
      transient
      magit
    ];
  };

  # LSP servers not in global PATH -- inject them so emacs can find them
  lspTools = with pkgs; [
    emacs-lsp-booster
    basedpyright
    biome
    clippy
    hyprls
    marksman
    nil
    nixd
    nixfmt
    nufmt
    ruff
    rust-analyzer
    rustfmt
    typescript
    typescript-language-server
    vscode-langservers-extracted
  ];

  emacsWithPkgs = emacsPackages.withPackages (
    epkgs: with epkgs; [
      # startup / gc
      gcmh

      # navigation / ui
      avy
      centaur-tabs
      consult
      consult-lsp
      doom-modeline
      helpful
      ligature
      marginalia
      nerd-icons
      projectile
      treemacs
      treemacs-nerd-icons
      transient-posframe
      treemacs-projectile
      vertico
      which-key

      # completion
      corfu
      cape

      # lsp
      lsp-mode
      lsp-ui
      lsp-pyright
      flycheck

      # formatting
      apheleia

      # language modes
      nix-ts-mode
      rustic
      nushell-ts-mode
      web-mode
      typescript-mode
      js2-mode
      markdown-mode
      treesit-auto
      (treesit-grammars.with-grammars (
        g: with g; [
          tree-sitter-nix
          tree-sitter-python
          tree-sitter-rust
          tree-sitter-typescript
          tree-sitter-tsx
          tree-sitter-javascript
          tree-sitter-json
          tree-sitter-css
          tree-sitter-bash
          tree-sitter-toml
          tree-sitter-yaml
          tree-sitter-nu
        ]
      ))

      # version control
      magit
      majutsu
      vc-jj

      # terminal
      vterm
      vterm-toggle
    ]
  );

  wrappedEmacs = pkgs.symlinkJoin {
    name = "emacs-wrapped";
    paths = [ emacsWithPkgs ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/emacs \
        --prefix PATH : ${pkgs.lib.makeBinPath lspTools}
    '';
  };
in
{
  users.users.${username}.packages = [ wrappedEmacs ];

  # .emacs.d must NOT be preserved -- if it exists, emacs ignores XDG and uses it instead
  preservation.preserveAt."/persist".users.${username} = {
    directories = [
      ".config/emacs/eln-cache" # avoid native-recompile on each boot
      ".config/emacs/.cache"
    ];
    files = [
      ".config/emacs/history"
      ".config/emacs/recentf"
      ".config/emacs/bookmarks"
      ".config/emacs/projectile-bookmarks.eld"
    ];
  };

  hjem.users.${username} = {
    xdg.config.files = {
      "emacs/early-init.el".text = lib.replaceStrings [ "@HOME@" ] [ home ] (
        builtins.readFile ./early-init.el
      );
      # not managed by noctalia's template system -- safe to edit directly
      "emacs/themes/noctalia-theme.el".source = ./noctalia-theme.el;
      "emacs/init.el".text =
        lib.replaceStrings
          [ "@FLAKE_PATH@" "@HOME@" "@NIX_SEARCH_TV@" ]
          [ flakePath home "${pkgs.nix-search-tv}/bin/nix-search-tv" ]
          (builtins.readFile ./init.el);
    };

    xdg.data.files = {
      "icons/kitchen-sink-emacs.png".source = ../../../assets/kitchen-sink.png;
      "applications/emacs.desktop".text = ''
        [Desktop Entry]
        Name=Emacs
        GenericName=Text Editor
        Comment=Edit text
        MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
        Exec=emacs %F
        Icon=${home}/.local/share/icons/kitchen-sink-emacs.png
        Type=Application
        Terminal=false
        Categories=Development;TextEditor;
        StartupNotify=true
        StartupWMClass=Emacs
      '';
    };
  };
}
