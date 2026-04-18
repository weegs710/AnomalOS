{
  flake.nixosModules.languages = {
    config,
    pkgs,
    ...
  }: let
    ns = pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      checkPhase = "";
      text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
    };
  in {
    environment.systemPackages = with pkgs; [
      ns
      jdk21
    ];

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      biome
      nixfmt
      # tsserver resolves typescript from PATH at runtime, not bundled
      typescript
      typescript-language-server
      vscode-langservers-extracted
    ];

    programs.nix-index.enable = true;
  };
}
