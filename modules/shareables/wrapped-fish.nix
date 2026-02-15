# Wrapped fish shell with bundled tools in PATH
# Configuration is handled by Home Manager (modules/nixos-modules/fish.nix)
# This wrapper only ensures essential tools are always available in PATH
{
  perSystem = {pkgs, ...}: let
    fishTools = with pkgs; [
      bat
      eza
      fd
      fzf
      ripgrep
      oh-my-posh
      git
      delta
      tig
      lazygit
      direnv
      jq
    ];

    wrappedFish = pkgs.symlinkJoin {
      name = "fish-wrapped";
      paths = [pkgs.fish];
      buildInputs = fishTools;
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/fish \
          --prefix PATH : ${pkgs.lib.makeBinPath fishTools}
      '';

      passthru.shellPath = "/bin/fish";

      meta = {
        mainProgram = "fish";
        description = "Fish shell with bundled development tools in PATH";
      };
    };
  in {
    packages.fish = wrappedFish;
  };
}
