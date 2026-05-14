{
  config,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
  wrappedFresh = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.fresh-editor;
  flakePath = "${config.users.users.${username}.home}/dotfiles";

  configJson = (pkgs.formats.json { }).generate "config.json" {
    version = 1;
    theme = "dark";

    editor = {
      use_terminal_bg = true;
      tab_size = 2;
      scroll_offset = 8;
      cursor_style = "blinking_bar";
      trim_trailing_whitespace_on_save = true;
      ensure_final_newline_on_save = true;
      enable_semantic_tokens_full = true;
      line_wrap = false;
      show_horizontal_scrollbar = true;
      rulers = [
        88
        100
        120
      ];
    };

    lsp = {
      nix = {
        command = "nixd";
        args = [ "--semantic-tokens" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
        initialization_options = {
          nixpkgs.expr = "import (builtins.getFlake \"${flakePath}\").inputs.nixpkgs { }";
          formatting.command = [ "nixfmt" ];
          options.nixos.expr = "(builtins.getFlake \"${flakePath}\").nixosConfigurations.HX99G.options";
        };
      };

      python = {
        command = "basedpyright-langserver";
        args = [ "--stdio" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
        initialization_options = {
          basedpyright.analysis = {
            typeCheckingMode = "standard";
            diagnosticSeverityOverrides = {
              reportUnusedImport = "warning";
              reportUnusedVariable = "warning";
            };
          };
        };
      };

      rust = {
        command = "rust-analyzer";
        args = [ ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
        initialization_options = {
          # runs clippy on save instead of cargo check
          checkOnSave.command = "clippy";
        };
      };

      hyprlang = {
        command = "hyprls";
        args = [ ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      nushell = {
        command = "nu";
        args = [ "--lsp" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      nil = {
        command = "nil";
        args = [ ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      markdown = {
        command = "marksman";
        args = [ "server" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      javascript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      typescript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      css = {
        command = "vscode-css-languageserver-bin";
        args = [ "--stdio" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      html = {
        command = "vscode-html-languageserver-bin";
        args = [ "--stdio" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      json = {
        command = "vscode-json-languageserver";
        args = [ "--stdio" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };

      jsonc = {
        command = "vscode-json-languageserver";
        args = [ "--stdio" ];
        process_limits = {
          enabled = false;
          max_memory_percent = null;
          max_cpu_percent = null;
        };
        enabled = true;
      };
    };

    keybindings = [
      {
        key = "w";
        modifiers = [ "ctrl" ];
        action = "close_tab";
        args = { };
        when = "normal";
      }
      {
        key = "j";
        modifiers = [ "ctrl" ];
        action = "focus_terminal";
        args = { };
        when = "normal";
      }
      {
        key = "e";
        modifiers = [ "ctrl" ];
        action = "quick_open";
        args = { };
        when = "normal";
      }
      {
        key = "s";
        modifiers = [
          "ctrl"
          "shift"
        ];
        action = "save_as";
        args = { };
        when = "normal";
      }
      {
        key = "i";
        modifiers = [
          "ctrl"
          "shift"
        ];
        action = "format_buffer";
        args = { };
        when = "normal";
      }
      {
        key = "\\";
        modifiers = [ "ctrl" ];
        action = "split_vertical";
        args = { };
        when = "normal";
      }
      {
        key = "f";
        modifiers = [ "ctrl" ];
        action = "start_live_grep";
        args = { };
        when = "normal";
      }
      {
        key = "o";
        modifiers = [
          "ctrl"
          "alt"
        ];
        action = "switch_project";
        args = { };
        when = "normal";
      }
      {
        key = "Down";
        modifiers = [
          "ctrl"
          "alt"
          "shift"
        ];
        action = "duplicate_line";
        args = { };
        when = "normal";
      }
      {
        key = "Up";
        modifiers = [
          "ctrl"
          "alt"
          "shift"
        ];
        action = "duplicate_line";
        args = { };
        when = "normal";
      }
    ];

    languages = {
      nix = {
        extensions = [ "nix" ];
        comment_prefix = "#";
        auto_indent = true;
        formatter = {
          command = "nixfmt";
          args = [ "-" ];
          stdin = true;
          timeout_ms = 10000;
        };
        format_on_save = true;
      };

      typescript = {
        formatter = {
          command = "biome";
          args = [
            "format"
            "--stdin-file-path"
            "dummy.ts"
          ];
          stdin = true;
          timeout_ms = 10000;
        };
        format_on_save = true;
      };

      javascript = {
        formatter = {
          command = "biome";
          args = [
            "format"
            "--stdin-file-path"
            "dummy.js"
          ];
          stdin = true;
          timeout_ms = 10000;
        };
        format_on_save = true;
      };

      rust = {
        formatter = {
          command = "rustfmt";
          args = [
            "--edition"
            "2021"
          ];
          stdin = true;
          timeout_ms = 30000;
        };
        format_on_save = true;
      };

      html = {
        formatter = {
          command = "biome";
          args = [
            "format"
            "--stdin-file-path"
            "dummy.html"
          ];
          stdin = true;
          timeout_ms = 10000;
        };
        format_on_save = true;
      };

      css = {
        formatter = {
          command = "biome";
          args = [
            "format"
            "--stdin-file-path"
            "dummy.css"
          ];
          stdin = true;
          timeout_ms = 10000;
        };
        format_on_save = true;
      };

      python = {
        formatter = {
          command = "ruff";
          args = [
            "format"
            "-"
          ];
          stdin = true;
          timeout_ms = 10000;
        };
        format_on_save = true;
      };

      hyprlang = {
        extensions = [ "hl" ];
        filenames = [
          "hyprland.conf"
          "hyprpaper.conf"
          "hypridle.conf"
          "hyprlock.conf"
        ];
        comment_prefix = "#";
        auto_indent = true;
        format_on_save = false;
      };

      nushell = {
        extensions = [ "nu" ];
        comment_prefix = "#";
        auto_indent = true;
        formatter = {
          command = "nufmt";
          args = [ "--stdin" ];
          stdin = true;
          timeout_ms = 10000;
        };
        format_on_save = true;
      };
    };
  };
in
{
  users.users.${username}.packages = [ wrappedFresh ];

  hjem.users.${username} = {
    xdg.config.files."fresh/config.json" = {
      source = configJson;
      type = "copy";
      permissions = "0644";
    };
  };
}
