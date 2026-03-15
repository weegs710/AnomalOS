{inputs, ...}: {
  perSystem = {pkgs, ...}: let
    steamdeckDsp = pkgs.stdenv.mkDerivation {
      pname = "steamdeck-dsp";
      version = "0.88";
      src = inputs.steamdeck-dsp;

      nativeBuildInputs = [pkgs.faust pkgs.which];

      postPatch = ''
        substituteInPlace Makefile \
          --replace-fail /usr/include/boost "${pkgs.boost.dev}/include/boost" \
          --replace-fail /usr/include/lv2 "${pkgs.lv2.dev}/include/lv2"

        substituteInPlace pipewire-confs/hardware-profiles/*/filter-chain.conf.d/filter-chain.conf \
          --replace-warn "/usr/lib/ladspa/rnnoise_ladspa.so" "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so"

        substituteInPlace ucm2/conf.d/*/*.conf \
          --replace-warn "exec" "# exec"

        substituteInPlace \
          pipewire-confs/hardware-profiles/pipewire-hwconfig \
          pipewire-confs/systemd/system/pipewire-sysconf.service \
          wireplumber/hardware-profiles/wireplumber-hwconfig \
          wireplumber/systemd/system/wireplumber-sysconf.service \
          cec-sysconf/systemd/system/cec-sysconf.service \
          --replace-fail "/usr/share" "$out/share"
      '';

      preInstall = "export DEST_DIR=$out";

      postInstall = ''
        mv -vt $out $out/usr/*
        rmdir -v $out/usr

        touch $out/share/pipewire/hardware-profiles/valve-jupiter/filter-chain.conf.d/filter-chain-sink.conf
        rm -r $out/lib/systemd/system/multi-user.target.wants/

        for pkg in pipewire wireplumber; do
          for i in $(find $out/share/$pkg/hardware-profiles/* -type f -printf "%P\n" | sort | uniq); do
            mkdir -p $(dirname "$out/share/$pkg/$i")
            ln -s /run/$pkg/$i $out/share/$pkg/$i
          done
        done
      '';

      meta = {
        description = "Steam Deck audio DSP — UCM2 configs, LV2 plugins, pipewire/wireplumber hardware profiles";
        license = pkgs.lib.licenses.gpl3;
      };
    };

    jupiterFanControl = pkgs.stdenv.mkDerivation {
      pname = "jupiter-fan-control";
      version = "20240523.3";
      src = inputs.jupiter-fan-control;

      buildInputs = [(pkgs.python3.withPackages (py: [py.pyyaml]))];

      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/share
        cp -r usr/share/jupiter-fan-control $out/share
        sed -i "s|/usr/share/|$out/share/|g" $out/share/jupiter-fan-control/fancontrol.py
        runHook postInstall
      '';

      meta = {
        description = "Steam Deck userspace fan controller";
        license = pkgs.lib.licenses.gpl3Plus;
      };
    };
  in {
    packages.steamdeck-dsp = steamdeckDsp;
    packages.jupiter-fan-control = jupiterFanControl;
  };
}
