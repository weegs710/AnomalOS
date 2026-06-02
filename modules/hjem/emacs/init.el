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
  :config
  ;; emacs-lisp checker spawns emacs --batch loading all packages -- prevent flycheck from enabling at all
  (setq flycheck-global-modes '(not emacs-lisp-mode))
  (global-flycheck-mode))

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
        "import (builtins.getFlake \"@FLAKE_PATH@\").inputs.nixpkgs {}"
        lsp-nix-nixd-nixos-options-expr
        "(builtins.getFlake \"@FLAKE_PATH@\").nixosConfigurations.HX99G.options"
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
                           "@NIX_SEARCH_TV@ print --indexes nixpkgs 2>/dev/null"))
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

;;; hub

(require 'transient)

(winner-mode 1)

(defun my/new-empty-buffer ()
  (interactive)
  (switch-to-buffer (generate-new-buffer "untitled")))

(defun my/kill-all-buffers ()
  (interactive)
  (mapc (lambda (b) (when (buffer-file-name b) (kill-buffer b)))
        (buffer-list)))

(defun my/kill-other-buffers ()
  (interactive)
  (let ((current (current-buffer)))
    (mapc (lambda (b)
            (when (and (buffer-file-name b) (not (eq b current)))
              (kill-buffer b)))
          (buffer-list))))

(defun my/zoom-window ()
  (interactive)
  (if (= 1 (length (window-list)))
      (winner-undo)
    (delete-other-windows)))

(defun my/open-emacs-config ()
  (interactive)
  (dired "@HOME@/repo/public/anomalos/modules/hjem/emacs/"))

(transient-define-prefix my/hub-files ()
  "Files."
  [["Open"
    ("n" "new empty" my/new-empty-buffer)
    ("f" "open file" find-file)
    ("d" "open directory" dired)
    ("r" "recent files" consult-recent-file)
    ("e" "emacs config" my/open-emacs-config)]
   ["Save"
    ("s" "save" save-buffer)
    ("S" "save as" write-file)
    ("a" "save all" save-some-buffers)]
   ["Close"
    ("v" "revert to saved" revert-buffer)
    ("k" "close" kill-current-buffer)
    ("K" "close all" my/kill-all-buffers)
    ("q" "quit emacs" save-buffers-kill-emacs)]])

(transient-define-prefix my/hub-buffers ()
  "Buffers."
  [["Switch"
    ("b" "switch to any open file" consult-buffer)
    ("n" "next open file" next-buffer)
    ("p" "previous open file" previous-buffer)]
   ["Close"
    ("k" "close this" kill-current-buffer)
    ("K" "close all others" my/kill-other-buffers)]
   ["List"
    ("l" "list all open files" ibuffer)]])

(transient-define-prefix my/hub-code ()
  "Code (LSP)."
  [["Navigate"
    ("d" "go to definition" lsp-find-definition)
    ("u" "find all usages" lsp-find-references)
    ("i" "go to implementation" lsp-find-implementation)
    ("h" "show docs" lsp-ui-doc-glance)]
   ["Actions"
    ("e" "show errors" consult-lsp-diagnostics)
    ("a" "fix / code action" lsp-execute-code-action)
    ("f" "format file" apheleia-format-buffer)
    ("r" "rename symbol" lsp-rename)]])

(transient-define-prefix my/hub-search ()
  "Search."
  [["Search"
    ("s" "in this file" consult-line)
    ("p" "in project" consult-ripgrep)]
   ["Replace"
    ("r" "replace in file" query-replace)
    ("R" "replace in project" projectile-replace)]])

(transient-define-prefix my/hub-layout ()
  "Layout."
  [["Panels"
    ("t" "file tree" treemacs)
    ("v" "terminal" vterm-toggle)]
   ["Windows"
    ("1" "one window" delete-other-windows)
    ("2" "split side by side" split-window-right)
    ("3" "split top/bottom" split-window-below)
    ("z" "zoom / restore" my/zoom-window)
    ("b" "balance splits" balance-windows)]])

(transient-define-prefix my/hub-help ()
  "Help."
  [["Help"
    ("k" "what does this key do?" helpful-key)
    ("f" "look up a function" helpful-callable)
    ("v" "look up a variable" helpful-variable)
    ("m" "describe current mode" describe-mode)
    ("a" "search all help" apropos)]])

(transient-define-prefix my/hub ()
  "Editor hub."
  [["Quick"
    ("SPC" "command palette" execute-extended-command)]
   ["Navigate"
    ("f" "files" my/hub-files)
    ("b" "buffers" my/hub-buffers)
    ("c" "code" my/hub-code)
    ("s" "search" my/hub-search)
    ("l" "layout" my/hub-layout)
    ("h" "help" my/hub-help)]])

(keymap-global-set "C-c SPC" #'my/hub)
