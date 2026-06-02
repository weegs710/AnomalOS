;;; early-init.el --- before frame init -*- lexical-binding: t -*-

(setq package-enable-at-startup nil)

;; gcmh handles GC after startup -- suppress during init
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(defvar my/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
          (lambda () (setq file-name-handler-alist my/file-name-handler-alist)))


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
