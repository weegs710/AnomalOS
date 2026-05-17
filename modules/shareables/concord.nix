{ inputs, ... }: {
  perSystem = { system, pkgs, ... }: {
    packages.concord = (inputs.concord.packages.${system}.default).overrideAttrs (old: {
      # crane bakes cargoExtraArgs into buildPhase at eval time -- shell var override is a no-op
      buildPhase = builtins.replaceStrings
        [ "--locked " ]
        [ "--locked --features voice-playback " ]
        old.buildPhase;
      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.alsa-lib ];
    });
  };
}
