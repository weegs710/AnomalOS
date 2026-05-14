{
  config,
  pkgs,
  ...
}:
let
  ns = pkgs.writeShellApplication {
    name = "ns";
    runtimeInputs = with pkgs; [
      fzf
      nix-search-tv
    ];
    checkPhase = "";
    text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
  };
  dprintConfig = pkgs.writeText "dprint.json" (
    builtins.toJSON {
      "markdown" = { };
      "plugins" = [ "file://${pkgs.dprint-plugins.dprint-plugin-markdown}/plugin.wasm" ];
      "includes" = [ "**/*.md" ];
    }
  );
  dprintmd = pkgs.writeShellApplication {
    name = "dprintmd";
    runtimeInputs = [ pkgs.dprint ];
    # config baked into store -- no per-project dprint.json needed
    text = ''exec dprint fmt --config "${dprintConfig}" --allow-no-files "$@"'';
  };
in
{
  environment.systemPackages = with pkgs; [
    ns
  ];

  users.users.${config.mySystem.user.name}.packages = with pkgs; [
    biome
    dprintmd
    nixfmt
    # tsserver resolves typescript from PATH at runtime, not bundled
    typescript
    typescript-language-server
    vscode-langservers-extracted
  ];

  programs.nix-index.enable = true;
}
