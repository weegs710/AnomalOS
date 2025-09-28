{ config, lib, pkgs, ... }:

with lib;

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
in

{
  config = mkIf config.mySystem.features.development {
    # Development languages and tools
    environment.systemPackages = with pkgs; [
      ns
      jdk21
    ];

    users.users.${config.mySystem.user.name}.packages = with pkgs; [
      # Development tools
      btop-rocm
      fzf
      gh
      jq
      tldr

      # Language servers and formatters
      alejandra
      hyprls
      nil

      # Programming languages
      nodejs
      python3
      rustc
      uv
    ];

    programs.nix-index.enable = true;
  };
}