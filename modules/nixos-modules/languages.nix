{
  flake.nixosModules.languages = {
    config,
    lib,
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
      config = lib.mkIf config.mySystem.features.development {
        environment.systemPackages = with pkgs; [
          ns
          jdk21
        ];

        users.users.${config.mySystem.user.name}.packages = [
        ];

        programs.nix-index.enable = true;
      };
    };
}
