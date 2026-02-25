# Wrapped nushell with bundled tools in PATH
# Configuration is handled by hjem (modules/hjem/nushell.nix)
# This wrapper only ensures essential tools are always available in PATH
{
  perSystem = {pkgs, ...}: let
    nushellTools = with pkgs; [
      bat
      eza
      fd
      fzf
      ripgrep
      carapace
      oh-my-posh
      git
      delta
      tig
      lazygit
      direnv
      jq
      zoxide  # Directory jumper - replacement for Fish's z plugin
    ];

    wrappedNushell = pkgs.symlinkJoin {
      name = "nushell-wrapped";
      paths = [pkgs.nushell];
      buildInputs = nushellTools;
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/nu \
          --prefix PATH : ${pkgs.lib.makeBinPath nushellTools}
      '';

      passthru.shellPath = "/bin/nu";

      meta = {
        mainProgram = "nu";
        description = "Nushell with bundled development tools in PATH";
      };
    };
  in {
    packages.nushell = wrappedNushell;
  };
}
