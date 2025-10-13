{inputs, ...}: let
  common = import ./common.nix {inherit inputs;};
  profiles = import ./profiles.nix {inherit (inputs.nixpkgs) lib;};
in {
  flake.nixosConfigurations = {
    Rig = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = common.commonModules ++ [profiles.profiles.full];
    };

    Hack = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = common.commonModules ++ [profiles.profiles.noYubikey];
    };

    Guard = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = common.commonModules ++ [profiles.profiles.noClaudeCode];
    };

    Stub = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = common.commonModules ++ [profiles.profiles.minimal];
    };
  };
}
