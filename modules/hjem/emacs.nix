{ config, pkgs, ... }:
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

  # .config/emacs/eln-cache: native compilation cache -- avoid recompile on each boot
  # .emacs.d must NOT be preserved -- if it exists, emacs ignores XDG and uses it instead
  preservation.preserveAt."/persist".users.${username} = {
    directories = [
      ".config/emacs/eln-cache"
      ".config/emacs/.cache"
    ];
    files = [
      ".config/emacs/history"
      ".config/emacs/recentf"
      ".config/emacs/bookmarks"
    ];
  };

  hjem.users.${username}.xdg.config.files = {
    "emacs/early-init.el".text = ''
      ;;; early-init.el --- before frame init -*- lexical-binding: t -*-

      (setq package-enable-at-startup nil)

      ;; gcmh handles GC after startup -- suppress during init
      (setq gc-cons-threshold most-positive-fixnum
            gc-cons-percentage 0.6)

      (defvar my/file-name-handler-alist file-name-handler-alist)
      (setq file-name-handler-alist nil)
      (add-hook 'emacs-startup-hook
                (lambda () (setq file-name-handler-alist my/file-name-handler-alist)))


      ;; must be set before lsp-mode loads
      (setenv "LSP_USE_PLISTS" "true")

      ;; default 4KB causes thousands of syscalls per LSP JSON response
      (setq read-process-output-max (* 4 1024 1024))

      ;; reduces childframe latency on pgtk (corfu, vertico)
      (when (boundp 'pgtk-wait-for-event-timeout)
        (setq pgtk-wait-for-event-timeout 0.001))

      ;; prevents frame resize on font load -- measurable startup speedup
      (setq frame-inhibit-implied-resize t
            frame-resize-pixelwise       t)

      ;; nerd-icons are large glyphs -- cache compaction is expensive
      (setq inhibit-compacting-font-caches t)

      (setq auto-mode-case-fold nil
            load-prefer-newer   t)

      (push '(menu-bar-lines . 0)   default-frame-alist)
      (push '(tool-bar-lines . 0)   default-frame-alist)
      (push '(vertical-scroll-bars) default-frame-alist)
      (setq inhibit-startup-screen t
            inhibit-startup-message t
            initial-scratch-message nil
            initial-major-mode      'fundamental-mode)
    '';

    # noctalia emacs template was never in activeTemplates -- we own this file, noctalia won't clobber it
    "emacs/themes/noctalia-theme.el".text = ''
      ;;; noctalia-theme.el --- Eldritch colorscheme -*- lexical-binding: t -*-

      ;; Package-Requires: ((emacs "24.1"))

      ;;; Code:

      (deftheme noctalia "Eldritch colorscheme.")

      (let* ((bg "#212337")
            (err "#f16c75")
            (err-container "#a8020d")
            (on-background "#ebfafa")
            (on-err "#171928")
            (on-err-container "#fbd0d3")
            (on-primary "#171928")
            (on-primary-container "#cffce6")
            (on-secondary "#171928")
            (on-secondary-container "#cdf6fe")
            (on-surface "#ebfafa")
            (on-surface-variant "#abb4da")
            (on-tertiary "#171928")
            (on-tertiary-container "#dbd1fa")
            (outline-color "#606b9d")
            (outline-variant "#434b6e")
            (primary "#37f499")
            (primary-container "#00793e")
            (secondary "#04d1f9")
            (secondary-container "#00404c")
            (shadow "#414868")
            (surface "#212337")
            (surface-container "#292e42")
            (surface-container-high "#31374f")
            (surface-container-highest "#39405b")
            (surface-container-low "#25283c")
            (surface-container-lowest "#222539")
            (surface-variant "#292e42")
            (tertiary "#a48cf2")
            (tertiary-container "#3305c6")
            (success "#a48cf2")
            (on-success "#171928")
            (success-container "#3305c6")
            (on-success-container "#dbd1fa")
            (primary-fixed "#37f499")
            (primary-fixed-dim "#00793e")
            (secondary-fixed "#04d1f9")
            (secondary-fixed-dim "#00404c")
            (tertiary-fixed "#a48cf2")
            (tertiary-fixed-dim "#3305c6")
            (on-primary-fixed "#171928")
            (on-secondary-fixed "#171928")
            (on-tertiary-fixed "#171928"))

        (custom-theme-set-faces
         'noctalia
         `(default ((t (:background ,bg :foreground ,on-background))))
         `(cursor ((t (:background ,primary))))
         `(highlight ((t (:background ,surface-container-high))))
         `(region ((t (:background ,primary-container :foreground ,on-primary-container :extend t))))
         `(secondary-selection ((t (:background ,secondary-container :foreground ,on-secondary-container :extend t))))
         `(isearch ((t (:background ,tertiary-container :foreground ,on-tertiary-container :weight bold))))
         `(lazy-highlight ((t (:background ,secondary-container :foreground ,on-secondary-container))))
         `(vertical-border ((t (:foreground ,outline-color))))
         `(border ((t (:background ,outline-color :foreground ,outline-color))))
         `(window-divider ((t (:foreground ,outline-color))))
         `(window-divider-first-pixel ((t (:foreground ,outline-color))))
         `(window-divider-last-pixel ((t (:foreground ,outline-color))))
         `(fringe ((t (:background ,surface :foreground ,outline-variant))))
         `(shadow ((t (:foreground ,outline-variant))))
         `(link ((t (:foreground ,primary :underline t))))
         `(link-visited ((t (:foreground ,tertiary :underline t))))
         `(success ((t (:foreground ,success))))
         `(warning ((t (:foreground ,secondary))))
         `(error ((t (:foreground ,err))))
         `(match ((t (:background ,secondary-container :foreground ,on-secondary-container))))
         `(font-lock-builtin-face ((t (:foreground ,primary))))
         `(font-lock-comment-face ((t (:foreground ,outline-color :slant italic))))
         `(font-lock-comment-delimiter-face ((t (:foreground ,outline-variant))))
         `(font-lock-constant-face ((t (:foreground ,tertiary :weight bold))))
         `(font-lock-doc-face ((t (:foreground ,on-surface-variant :slant italic))))
         `(font-lock-function-name-face ((t (:foreground ,primary :weight bold))))
         `(font-lock-keyword-face ((t (:foreground ,secondary :weight bold))))
         `(font-lock-string-face ((t (:foreground ,tertiary))))
         `(font-lock-type-face ((t (:foreground ,primary-fixed))))
         `(font-lock-variable-name-face ((t (:foreground ,on-surface))))
         `(font-lock-warning-face ((t (:foreground ,err :weight bold))))
         `(font-lock-preprocessor-face ((t (:foreground ,secondary-fixed-dim))))
         `(font-lock-negation-char-face ((t (:foreground ,tertiary-fixed))))
         `(show-paren-match ((t (:background ,primary-container :foreground ,on-primary-container :weight bold))))
         `(show-paren-mismatch ((t (:background ,err-container :foreground ,on-err-container :weight bold))))
         `(mode-line ((t (:background ,surface-container-high :foreground ,on-surface :box nil))))
         `(mode-line-inactive ((t (:background ,surface :foreground ,on-surface-variant :box nil))))
         `(mode-line-buffer-id ((t (:foreground ,primary :weight bold))))
         `(mode-line-emphasis ((t (:foreground ,primary :weight bold))))
         `(mode-line-highlight ((t (:foreground ,primary :box nil))))
         `(org-block ((t (:background ,surface-container-low :extend t :inherit fixed-pitch))))
         `(org-block-begin-line ((t (:background ,surface-container-low :foreground ,primary-fixed-dim :extend t :slant italic :inherit fixed-pitch))))
         `(org-block-end-line ((t (:background ,surface-container-low :foreground ,primary-fixed-dim :extend t :slant italic :inherit fixed-pitch))))
         `(org-level-1 ((t (:foreground ,primary :weight bold :height 1.2))))
         `(org-level-2 ((t (:foreground ,secondary :weight bold :height 1.1))))
         `(org-level-3 ((t (:foreground ,tertiary :weight bold))))
         `(org-todo ((t (:foreground ,err :weight bold))))
         `(org-done ((t (:foreground ,success :weight bold))))
         `(which-key-key-face ((t (:foreground ,primary :weight bold))))
         `(which-key-separator-face ((t (:foreground ,outline-variant))))
         `(which-key-command-description-face ((t (:foreground ,on-surface))))
         `(which-key-group-description-face ((t (:foreground ,secondary))))
         `(which-key-special-key-face ((t (:foreground ,tertiary :weight bold))))
         `(line-number ((t (:foreground ,outline-variant :inherit fixed-pitch))))
         `(line-number-current-line ((t (:foreground ,primary :weight bold :inherit fixed-pitch))))
         `(dired-directory ((t (:foreground ,primary :weight bold))))
         `(dired-symlink ((t (:foreground ,secondary :slant italic))))
         `(dired-flagged ((t (:foreground ,err))))
         `(markdown-header-face-1 ((t (:foreground ,primary :weight bold :height 1.2))))
         `(markdown-header-face-2 ((t (:foreground ,primary-container :weight bold :height 1.1))))
         `(markdown-header-face-3 ((t (:foreground ,secondary :weight bold))))
         `(markdown-inline-code-face ((t (:foreground ,tertiary-fixed :background ,surface-container-low :inherit fixed-pitch))))
         `(markdown-code-face ((t (:background ,surface-container-low :extend t :inherit fixed-pitch))))
         `(flycheck-error ((t (:underline (:style wave :color ,err)))))
         `(flycheck-warning ((t (:underline (:style wave :color ,secondary)))))
         `(flycheck-info ((t (:underline (:style wave :color ,tertiary)))))
         `(minibuffer-prompt ((t (:foreground ,primary :weight bold))))
         `(lsp-face-highlight-textual ((t (:background ,primary-container :foreground ,on-primary-container :weight bold))))
         `(lsp-face-highlight-read ((t (:background ,secondary-container :foreground ,on-secondary-container :weight bold))))
         `(lsp-face-highlight-write ((t (:background ,tertiary-container :foreground ,on-tertiary-container :weight bold))))
         `(tab-bar ((t (:background ,surface-container-high :foreground ,on-surface :box nil))))
         `(tab-bar-tab ((t (:background ,surface-container-high :foreground ,on-surface :weight bold :box nil))))
         `(tab-bar-tab-inactive ((t (:background ,surface :foreground ,on-surface-variant :box nil))))
         `(centaur-tabs-default ((t (:background ,surface-container-high :foreground ,on-surface))))
         `(centaur-tabs-selected ((t (:background ,surface-container-high :foreground ,on-surface :weight bold))))
         `(centaur-tabs-unselected ((t (:background ,surface :foreground ,on-surface-variant))))
         `(centaur-tabs-selected-modified ((t (:background ,surface-container-high :foreground ,tertiary :weight bold))))
         `(centaur-tabs-unselected-modified ((t (:background ,surface :foreground ,tertiary))))
         `(centaur-tabs-active-bar-face ((t (:background ,primary))))
         `(corfu-default ((t (:background ,surface-container :foreground ,on-surface))))
         `(corfu-current ((t (:background ,primary-container :foreground ,on-primary-container))))
         `(corfu-bar ((t (:background ,primary))))
         `(corfu-border ((t (:background ,outline-variant))))
         `(fixed-pitch ((t (:family "monospace"))))
         `(variable-pitch ((t (:family "sans serif"))))))

      (when load-file-name
        (add-to-list 'custom-theme-load-path
                     (file-name-as-directory (file-name-directory load-file-name))))

      (provide-theme 'noctalia)
      ;;; noctalia-theme.el ends here
    '';

    "emacs/init.el".text = ''
      ;;; init.el --- weegs emacs config -*- lexical-binding: t -*-

      ;; Packages are Nix-managed in the store -- initialize to load their autoloads
      (package-initialize)

      ;;; gc

      ;; hands off GC management to gcmh after init
      (use-package gcmh
        :demand t
        :config (gcmh-mode 1))

      ;;; quality of life

      (setq backup-directory-alist
            `(("." . ,(expand-file-name "backups/" user-emacs-directory))))

      ;; save to actual file on idle instead of #file# sidecars -- jj working copy is crash recovery
      (setq auto-save-default nil)
      (auto-save-visited-mode +1)

      (require 'server)
      (unless (server-running-p)
        (server-start))

      (savehist-mode 1)

      (recentf-mode 1)
      (setq recentf-max-saved-items 200)

      ;; save bookmarks on every change rather than only on quit
      (setq bookmark-save-flag 1)

      (global-set-key (kbd "<escape>") #'keyboard-quit)
      (keymap-set minibuffer-local-map "<escape>" #'abort-minibuffers)

      (show-paren-mode 1)
      (global-display-line-numbers-mode t)

      (setq window-divider-default-right-width 2
            window-divider-default-bottom-width 2
            window-divider-default-places t)
      (window-divider-mode 1)
      (setq vc-follow-symlinks t
            require-final-newline t)

      ;; prevents syntax highlight updates during keystrokes -- removes input lag
      (setq redisplay-skip-fontification-on-input t)

      (setq native-comp-async-report-warnings-errors 'silent)

      ;; nvim scrolloff=999 -- maximum-scroll-margin caps it at 50% so top/bottom of file work cleanly
      (setq scroll-margin 999
            maximum-scroll-margin 0.5
            scroll-conservatively 101
            scroll-preserve-screen-position t)

      (electric-pair-mode 1)
      (setq imenu-auto-rescan t)

      ;;; prettify

      (setq prettify-symbols-unprettify-at-point t)
      (setq-default prettify-symbols-alist
        '(("==" . "≡") ("===" . "≣") ("!=" . "≠") ("!==" . "≢")
          (">=" . "≥") ("<=" . "≤") ("->" . "→") ("<-" . "←")
          ("<->" . "↔") ("<=>" . "⇔") ("->>" . "↠") ("<<-" . "↞")
          ("~>" . "↝") ("|>" . "▷") ("<|" . "◁") ("map" . "↦")
          ("lambda" . "λ") ("alpha" . "α") ("beta" . "β") ("gamma" . "γ")
          ("delta" . "δ") ("pi" . "π") ("sum" . "∑") ("..." . "…")
          ("::" . "∷") (">>" . "»") ("<<" . "«") ("sqrt" . "√")
          ("integral" . "∫") ("forall" . "∀") ("exists" . "∃")))
      (add-hook 'prog-mode-hook #'prettify-symbols-mode)
      (add-hook 'org-mode-hook  #'prettify-symbols-mode)

      ;; allow prettify in comments so ;;; renders as # in elisp section headers
      (add-hook 'emacs-lisp-mode-hook
        (lambda ()
          (setq-local prettify-symbols-compose-predicate
            (lambda (start _end _match)
              (not (nth 3 (syntax-ppss start)))))
          (setq-local prettify-symbols-alist
            (cons '(";;;" . ?#) prettify-symbols-alist))))

      ;;; pulse

      (defun my/pulse-line (&rest _)
        (pulse-momentary-highlight-one-line (point)))

      (advice-add 'find-file        :after #'my/pulse-line)
      (advice-add 'switch-to-buffer :after #'my/pulse-line)

      ;;; font

      (set-face-attribute 'default nil
                          :font "JetBrainsMono Nerd Font Mono"
                          :height 100)

      ;;; ligatures

      (use-package ligature
        :config
        (ligature-set-ligatures 't
          '("<---" "<--" "<<-" "<-" "->" "-->" "--->" "<->" "<-->" "<--->"
            "<~~" "~~>" "~>" "<~" "~-" "-~"
            "<$>" "<$" "$>" "<+>" "<+" "+>" "<*>" "<*" "*>"
            "<!--" "</" "/>" "</>" "<|" "<|>" "|>" "||" "|-" "-|"
            "==" "===" "!=" "!==" "<=" ">=" "<=>" "<==>" "<==="
            "->>" "->>" "=>>" "==>" "<<==" "<<=" ">>" "<<" ">>>"
            ":::" "::" ":=" "=:" "?:" ":>" ":<" "<:"
            "/=" "/==" "++" "+++" "..." ".." "**"))
        (global-ligature-mode t))

      ;;; theme

      (add-to-list 'custom-theme-load-path
                   (expand-file-name "themes/" user-emacs-directory))
      (condition-case err
          (load-theme 'noctalia t)
        (error (message "noctalia theme load failed: %s" err)))

      ;;; which-key

      (use-package which-key
        :config
        (which-key-mode)
        (setq which-key-idle-delay 0.0
              which-key-popup-type 'side-window
              which-key-side-window-location 'bottom
              which-key-side-window-max-height 0.33))

      ;;; vertico + marginalia

      (use-package vertico
        :demand t
        :config (vertico-mode))

      (use-package marginalia
        :demand t
        :config (marginalia-mode))

      ;;; consult

      (use-package consult
        :bind (("C-x b"   . consult-buffer)
               ("C-s"     . consult-line)
               ("M-g i"   . consult-imenu)
               ("C-c f"   . consult-ripgrep)))

      ;;; corfu + cape

      (use-package corfu
        :demand t
        :config
        (setq corfu-auto t
              corfu-auto-delay 0.2
              corfu-quit-no-match t
              corfu-cycle t)
        (global-corfu-mode))

      (use-package cape
        :config
        (add-to-list 'completion-at-point-functions #'cape-file)
        (add-to-list 'completion-at-point-functions #'cape-dabbrev))

      ;;; nerd-icons

      (use-package nerd-icons
        :custom
        (nerd-icons-font-family "JetBrainsMono Nerd Font Mono"))

      ;;; doom-modeline

      (use-package doom-modeline
        :demand t
        :config
        (doom-modeline-mode 1)
        (setq doom-modeline-height 28
              doom-modeline-icon t
              doom-modeline-major-mode-icon t
              doom-modeline-buffer-file-name-style 'relative-from-project
              doom-modeline-project-detection 'projectile
              doom-modeline-vcs-max-length 24
              doom-modeline-check-simple-format t
              doom-modeline-env-enable-rust nil
              doom-modeline-env-enable-python nil))

      ;;; helpful

      (use-package helpful
        :bind (("C-h f" . helpful-callable)
               ("C-h v" . helpful-variable)
               ("C-h k" . helpful-key)
               ("C-h x" . helpful-command)))

      ;;; projectile

      (use-package projectile
        :demand t
        :config
        (projectile-mode +1)
        (setq projectile-project-search-path '(("~/repo/" . 2))
              ;; stops projectile serializing known-projects on every file open
              projectile-track-known-projects-automatically nil
              projectile-require-project-root nil
              projectile-switch-project-action #'my/projectile-restore-buffer)
        ;; projectile-find-file-hook-function visits TAGS table + updates cache on every file open -- useless with LSP
        (remove-hook 'find-file-hook #'projectile-find-file-hook-function)
        :bind-keymap
        ("C-c p" . projectile-command-map))

      ;;; project session

      (defvar my/project-buffer-history (make-hash-table :test 'equal))

      (defun my/projectile-save-buffer ()
        (when-let ((file (buffer-file-name))
                   ((projectile-project-p)))
          (puthash (projectile-project-root) file my/project-buffer-history)))

      (defun my/projectile-restore-buffer ()
        (let* ((root (projectile-project-root))
               (saved (gethash root my/project-buffer-history)))
          (if (and saved (file-exists-p saved))
              (find-file saved)
            (switch-to-buffer "*scratch*")
            ;; anchor default-directory so treemacs-project-follow-mode detects the new project
            (setq-local default-directory root)
            ;; bypass the 1.5s idle debounce -- update treemacs immediately
            (when (fboundp 'treemacs--do-follow-project)
              (treemacs--do-follow-project)))))

      (add-hook 'projectile-before-switch-project-hook #'my/projectile-save-buffer)

      ;;; treemacs

      (use-package treemacs
        :bind (("C-x t t" . treemacs)
               ("C-x t s" . treemacs-select-directory))
        :config
        (setq treemacs-width 35
              treemacs-display-in-side-window t
              treemacs-follow-after-init t
              treemacs-indentation 2
              treemacs-show-hidden-files nil)
        (treemacs-filewatch-mode t)
        (treemacs-fringe-indicator-mode 'always)
        (treemacs-project-follow-mode 1))

      (use-package treemacs-projectile
        :after (treemacs projectile))

      (use-package treemacs-nerd-icons
        :after treemacs
        :config
        (setq treemacs-nerd-icons-icon-size 1.3)
        (treemacs-load-theme "nerd-icons"))

      (add-hook 'emacs-startup-hook
                (lambda ()
                  (require 'treemacs)
                  (ignore-errors
                    (treemacs-do-add-project-to-workspace
                     (expand-file-name "~/repo/public/anomalos") "anomalos"))
                  (treemacs)))

      ;;; centaur-tabs

      (use-package centaur-tabs
        :demand t
        :init
        ;; must be set before the package loads -- it captures the face value at load time
        (setq centaur-tabs-background-color "#212337")
        :config
        ;; excluded-prefixes feeds the hide-hash cache populated during centaur-tabs-mode init scan
        (dolist (prefix '("*vterm" "*Messages" "*Flycheck" "*compilation"
                          "*Warnings" "*Help" "*helpful" "*xref" "*vc"
                          "*VC" "*Backtrace" "*Agenda" "*scratch"
                          "*nativecomp" "*Async-native-comp" "*treemacs"))
          (add-to-list 'centaur-tabs-excluded-prefixes prefix))
        (centaur-tabs-mode t)
        (setq centaur-tabs-set-icons t
              centaur-tabs-set-bar 'over
              centaur-tabs-height 32
              centaur-tabs-style "bar"
              centaur-tabs-set-close-button t
              centaur-tabs-set-modified-marker t
              centaur-tabs-modified-marker "●")
        ;; headline-match reads centaur-tabs-unselected bg after mode init, before our theme lands
        (set-face-attribute 'centaur-tabs-unselected nil :background "#212337")
        (centaur-tabs-headline-match)
        (dolist (hook '(vterm-mode-hook messages-buffer-mode-hook
                        help-mode-hook compilation-mode-hook
                        flycheck-error-list-mode-hook))
          (add-hook hook #'centaur-tabs-local-mode))
        :bind (("C-<prior>" . centaur-tabs-backward)
               ("C-<next>"  . centaur-tabs-forward)
               ("C-w"       . kill-current-buffer)))

      ;;; treesit-auto

      (use-package treesit-auto
        :demand t
        :config
        (setq treesit-auto-langs '(nix python rust typescript tsx javascript json css bash toml yaml))
        ;; global-treesit-auto-mode advises set-auto-mode-0, rebuilding remap-alist on every file open
        (treesit-auto-add-to-auto-mode-alist 'all))

      ;;; flycheck

      (use-package flycheck
        :demand t
        :config (global-flycheck-mode))

      ;;; lsp-mode

      (use-package lsp-mode
        :commands (lsp lsp-deferred)
        :init
        (setq lsp-use-plists t)
        :hook ((nix-ts-mode        . lsp-deferred)
               (nix-mode           . lsp-deferred)
               (python-ts-mode     . lsp-deferred)
               (rust-ts-mode       . lsp-deferred)
               (rustic-mode        . lsp-deferred)
               (typescript-ts-mode . lsp-deferred)
               (tsx-ts-mode        . lsp-deferred)
               (js-ts-mode         . lsp-deferred)
               (css-ts-mode        . lsp-deferred)
               (json-ts-mode       . lsp-deferred)
               (html-mode          . lsp-deferred)
               (web-mode           . lsp-deferred)
               (nushell-ts-mode    . lsp-deferred)
               (markdown-mode      . lsp-deferred))
        :config
        (setq lsp-keymap-prefix "C-c l"
              lsp-enable-snippet nil
              lsp-idle-delay 0.3
              lsp-log-io nil
              lsp-completion-provider :none
              lsp-auto-install-servers nil
              lsp-restart 'auto-restart
              lsp-enable-file-watchers nil
              lsp-headerline-breadcrumb-enable nil
              lsp-lens-enable nil
              lsp-enable-symbol-highlighting nil
              ;; code-actions segment loads all-the-icons -- not worth it
              lsp-modeline-code-actions-enable nil
              ;; use projectile root automatically -- no interactive prompt per new project
              lsp-auto-guess-root t)
        ;; restrict to only languages in use -- lsp--require-packages loads all 100+ clients at first invocation
        (setq lsp-client-packages '(lsp-nix lsp-pyright lsp-rust lsp-javascript lsp-css lsp-json lsp-html lsp-nushell lsp-marksman))
        ;; rnix-lsp and nix-nil conflict with nixd -- nixd provides full anomalos flake context
        (setq lsp-disabled-clients '(rnix-lsp nix-nil)
              lsp-nix-nixd-nixpkgs-expr
              "import (builtins.getFlake \"${flakePath}\").inputs.nixpkgs {}"
              lsp-nix-nixd-nixos-options-expr
              "(builtins.getFlake \"${flakePath}\").nixosConfigurations.HX99G.options"
              lsp-nix-nixd-formatting-command ["nixfmt"])
        (setq lsp-rust-analyzer-cargo-watch-command "clippy")
        (setq lsp-pyright-langserver-command "basedpyright"))

      (use-package lsp-ui
        :after lsp-mode
        :config
        ;; sideline triggers redisplay on every buffer event -- too expensive
        (setq lsp-ui-sideline-enable nil
              lsp-ui-doc-enable t
              lsp-ui-doc-position 'at-point
              lsp-ui-doc-show-with-cursor nil
              lsp-ui-doc-show-with-mouse t))

      ;; lsp-booster skips json-parse -- feeds pre-converted elisp bytecode directly
      (defun lsp-booster--advice-json-parse (old-fn &rest args)
        (or (when (equal (following-char) ?#)
              (let ((bytecode (read (current-buffer))))
                (when (byte-code-function-p bytecode) (funcall bytecode))))
            (apply old-fn args)))
      (advice-add (if (fboundp 'json-parse-buffer) 'json-parse-buffer 'json-read)
                  :around #'lsp-booster--advice-json-parse)
      (defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
        (let ((orig (funcall old-fn cmd test?)))
          (if (and (not test?) (not (file-remote-p default-directory))
                   lsp-use-plists (not (functionp 'json-rpc-connection))
                   (executable-find "emacs-lsp-booster"))
              (cons "emacs-lsp-booster" orig)
            orig)))
      (advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command)

      (use-package consult-lsp
        :after (consult lsp-mode)
        :bind (:map lsp-mode-map
               ("C-c l s" . consult-lsp-symbols)
               ("C-c l d" . consult-lsp-diagnostics)))

      ;;; language modes

      (use-package nix-ts-mode
        :mode "\\.nix\\'")

      (use-package rustic
        :mode "\\.rs\\'"
        :config
        (setq rustic-lsp-client 'lsp-mode
              rustic-format-on-save nil))  ; apheleia handles formatting

      (use-package nushell-ts-mode
        :mode "\\.nu\\'")

      (use-package web-mode
        :mode (("\\.html?\\'" . web-mode)
               ("\\.css\\'"   . web-mode))
        :config
        (setq web-mode-markup-indent-offset 2
              web-mode-css-indent-offset 2
              web-mode-code-indent-offset 2))

      (use-package typescript-mode
        :mode "\\.tsx?\\'")

      (use-package js2-mode
        :mode "\\.js\\'")

      (use-package markdown-mode
        :mode (("\\.md\\'"       . markdown-mode)
               ("\\.markdown\\'" . markdown-mode)))

      ;;; apheleia

      (use-package apheleia
        :demand t
        :config
        (setf (alist-get 'nixfmt apheleia-formatters)
              '("nixfmt" "-"))
        (setf (alist-get 'ruff-format apheleia-formatters)
              '("ruff" "format" "--stdin-file-path" (filepath)))
        (setf (alist-get 'nufmt apheleia-formatters)
              '("nufmt" "--stdin"))
        (setf (alist-get 'biome-ts apheleia-formatters)
              '("biome" "format" "--stdin-file-path" (filepath)))
        (setf (alist-get 'biome-css apheleia-formatters)
              '("biome" "format" "--stdin-file-path" (filepath)))
        (setf (alist-get 'rustfmt-edition apheleia-formatters)
              '("rustfmt" "--edition" "2021"))
        (setf (alist-get 'nix-mode      apheleia-mode-alist) 'nixfmt)
        (setf (alist-get 'nix-ts-mode   apheleia-mode-alist) 'nixfmt)
        (setf (alist-get 'python-ts-mode apheleia-mode-alist) 'ruff-format)
        (setf (alist-get 'nushell-ts-mode apheleia-mode-alist) 'nufmt)
        (setf (alist-get 'typescript-ts-mode apheleia-mode-alist) 'biome-ts)
        (setf (alist-get 'tsx-ts-mode   apheleia-mode-alist) 'biome-ts)
        (setf (alist-get 'js-ts-mode    apheleia-mode-alist) 'biome-ts)
        (setf (alist-get 'web-mode      apheleia-mode-alist) 'biome-css)
        (setf (alist-get 'css-ts-mode   apheleia-mode-alist) 'biome-css)
        (setf (alist-get 'rustic-mode   apheleia-mode-alist) 'rustfmt-edition)
        (setf (alist-get 'rust-ts-mode  apheleia-mode-alist) 'rustfmt-edition)
        (apheleia-global-mode +1))

      ;;; jujutsu

      (use-package vc-jj
        :demand t
        :config
        ;; vc-jj.el adds JJ at load time -- null out to stop vc spawning jj subprocesses per file open
        (setq vc-handled-backends nil))

      ;; custom-initialize-set skips if default-boundp -- pre-set nil beats magit's defcustom default of t
      (setq magit-auto-revert-mode nil)
      (with-eval-after-load 'magit
        (magit-auto-revert-mode -1))

      (use-package majutsu
        :demand t
        :config
        (defun my/jj-snapshot ()
          "Snapshot the jj working copy."
          (interactive)
          (majutsu-run-jj "status")
          (message "Snapshotted working copy"))

        (defun my/jj-fetch ()
          "Fetch from all git remotes."
          (interactive)
          (majutsu-git--start '("fetch" "--all-remotes") "Fetched from all remotes"))

        (defun my/jj-pull ()
          "Fetch all remotes then advance main to main@origin."
          (interactive)
          (majutsu-git--start '("fetch" "--all-remotes") nil
            (lambda (_)
              (majutsu-run-jj "bookmark" "move" "main" "-t" "main@origin"))))

        (defun my/jj-push ()
          "Fetch, push, then fetch again."
          (interactive)
          (majutsu-git--start '("fetch" "--all-remotes") nil
            (lambda (_)
              (majutsu-git--start '("push") "Pushed"
                (lambda (_)
                  (majutsu-git--start '("fetch" "--all-remotes") "Done"))))))

        (defun my/jj-commit ()
          "Split working copy interactively then advance the closest bookmark."
          (interactive)
          (let* ((root (majutsu--toplevel-safe))
                 (status (with-temp-buffer
                           (let ((default-directory root))
                             (call-process "jj" nil t nil "status")
                             (buffer-string)))))
            (if (string-match-p "The working copy has no changes" status)
                (message "No changes to commit")
              (letrec
                ((cancel-hook
                  (lambda ()
                    (remove-hook 'with-editor-post-finish-hook finish-hook)
                    (remove-hook 'with-editor-post-cancel-hook cancel-hook)))
                 (finish-hook
                  (lambda ()
                    (remove-hook 'with-editor-post-finish-hook finish-hook)
                    (remove-hook 'with-editor-post-cancel-hook cancel-hook)
                    (let ((default-directory root))
                      (majutsu-run-jj "bookmark" "move"
                                      "--from" "closest_bookmark(@-)"
                                      "--to" "@-")))))
                (add-hook 'with-editor-post-finish-hook finish-hook)
                (add-hook 'with-editor-post-cancel-hook cancel-hook))
              (majutsu-split))))

        (defvar-keymap my/jj-map
          :doc "jj workflow keybindings."
          "l" #'majutsu-log
          "j" #'my/jj-snapshot
          "c" #'my/jj-commit
          "p" #'my/jj-push
          "P" #'my/jj-pull
          "f" #'my/jj-fetch)

        (keymap-global-set "C-c j" my/jj-map))

      ;;; vterm

      (use-package vterm
        :config
        (setq vterm-max-scrollback 10000
              vterm-shell (executable-find "nu"))
        (add-hook 'vterm-mode-hook (lambda () (display-line-numbers-mode -1))))

      (use-package vterm-toggle
        :bind (("C-`" . vterm-toggle))
        :config
        (setq vterm-toggle-fullscreen-p nil)
        ;; fallback to current window instead of splitting when no alist rule matches
        (setq display-buffer-base-action '(display-buffer-same-window))
        (setq display-buffer-alist
              '(("\\*vterm\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . -1)
                 (window-height . 0.3))
                ("\\*\\(Messages\\|Flycheck\\|compilation\\|Warnings\\|Help\\|helpful\\|xref\\|vc-diff\\|VC-log\\|lsp-help\\|lsp-log\\|Backtrace\\|Occur\\|grep\\|Agenda\\|Buffer List\\).*\\*"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 1)
                 (window-height . 0.3))))

        ;; doom-modeline text-property keymaps override global-set-key -- advise the functions directly
        (advice-add 'mouse-buffer-menu :override (lambda (&rest _) (consult-buffer)))
        (advice-add 'mode-line-previous-buffer :override (lambda (&rest _) (consult-buffer))))

      ;;; avy

      (use-package avy
        :bind (("C-;"   . avy-goto-char-timer)
               ("M-g l" . avy-goto-line))
        :config
        (setq avy-background t
              avy-style 'at-full
              avy-timeout-seconds 0.3)
        (set-face-attribute 'avy-lead-face nil
                            :background "#a48cf2"
                            :foreground "#171928"
                            :weight 'bold)
        (set-face-attribute 'avy-lead-face-0 nil
                            :background "#37f499"
                            :foreground "#171928"
                            :weight 'bold)
        (set-face-attribute 'avy-lead-face-1 nil
                            :background "#04d1f9"
                            :foreground "#171928"
                            :weight 'bold)
        (set-face-attribute 'avy-lead-face-2 nil
                            :background "#a48cf2"
                            :foreground "#171928"
                            :weight 'bold)
        (set-face-attribute 'avy-background-face nil
                            :foreground "#606b9d"))

      ;;; nix

      (defvar my/nix-packages-cache nil)
      (defconst my/nix-packages-cache-file "/tmp/emacs-nix-packages.cache")

      (defun my/nix--packages ()
        (or my/nix-packages-cache
            (setq my/nix-packages-cache
                  (if (file-readable-p my/nix-packages-cache-file)
                      (with-temp-buffer
                        (insert-file-contents my/nix-packages-cache-file)
                        (split-string (buffer-string) "\n" t))
                    (let* ((raw (shell-command-to-string
                                 "${pkgs.nix-search-tv}/bin/nix-search-tv print --indexes nixpkgs 2>/dev/null"))
                           (pkgs (split-string raw "\n" t)))
                      (with-temp-file my/nix-packages-cache-file
                        (insert raw))
                      pkgs)))))

      (defun my/nix--in-with-pkgs-p ()
        (save-excursion
          (let ((depth 0) result done)
            (while (and (not done) (not (bobp)))
              (backward-char)
              (pcase (char-after)
                (?\] (setq depth (1+ depth)))
                (?\[
                 (if (> depth 0)
                     (setq depth (1- depth))
                   (skip-chars-backward " \t\n")
                   (setq result (looking-back "with pkgs;" nil)
                         done t)))))
            result)))

      (defun my/nix-insert-package ()
        "Pick a nixpkgs package from ns index and insert at point."
        (interactive)
        (message "Loading nixpkgs index...")
        (let* ((pick (completing-read "nixpkgs: " (my/nix--packages) nil t))
               (str  (if (my/nix--in-with-pkgs-p)
                         pick
                       (format "pkgs.%s" pick))))
          (insert str)))

      (with-eval-after-load 'which-key
        (which-key-add-key-based-replacements "C-c n" "nix")
        (which-key-add-key-based-replacements "C-c n s" "nix-search+insert"))
      (keymap-set global-map "C-c n s" #'my/nix-insert-package)
    '';
  };
}
