{ pkgs, ... }:
let
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
    atuin
    zoxide
  ];

  wrappedNushell = pkgs.symlinkJoin {
    name = "nushell-wrapped";
    paths = [ pkgs.nushell ];
    buildInputs = nushellTools;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nu \
        --suffix PATH : ${pkgs.lib.makeBinPath nushellTools}
    '';

    passthru.shellPath = "/bin/nu";

    meta = {
      mainProgram = "nu";
      description = "Nushell with bundled development tools in PATH";
    };
  };
in
{
  nushell = wrappedNushell;
}
