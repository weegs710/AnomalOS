{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    python = pkgs.python312;

    pythonOverrides = python.override {
      self = python;
      packageOverrides = pyfinal: pyprev: {
        discord-protos = pyfinal.buildPythonPackage rec {
          pname = "discord-protos";
          version = "0.0.2";
          pyproject = true;

          src = pkgs.fetchPypi {
            inherit pname version;
            hash = "sha256-I5U6BfMr7ttAtwjsS0V1MKYZaknI110zeukoKipByZc=";
          };

          build-system = with pyfinal; [ setuptools ];

          dependencies = with pyfinal; [ protobuf ];

          pythonImportsCheck = [ "discord_protos" ];
        };

        numpy = pyprev.numpy.overridePythonAttrs (old: rec {
          version = "2.4.2";
          src = pkgs.fetchPypi {
            pname = "numpy";
            inherit version;
            hash = "sha256-ZZphB+Mag8TjP3Y5Qidf0niyHQlQlAROs1Vp6Goh3a4=";
          };
        });

        orjson = pyprev.orjson.overridePythonAttrs (old: rec {
          version = "3.11.7";
          src = pkgs.fetchPypi {
            pname = "orjson";
            inherit version;
            hash = "sha256-mxpnJDlFgZzlXSSjC1nWoWjoYiBFLSyW9NHwk+ccDEk=";
          };
          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            name = "orjson-${version}";
            hash = "sha256-eB7jVTsvBSUjtaKsbRnRtYSd+SqnCaoDyG76iExmSHc=";
          };
        });

        urllib3 = pyprev.urllib3.overridePythonAttrs (old: rec {
          version = "2.6.3";
          src = pkgs.fetchPypi {
            pname = "urllib3";
            inherit version;
            hash = "sha256-G2K2iElEpX2+MhUJq5T9TTswcHXgwurpkaxx7hWtOO0=";
          };
        });

        websocket-client = pyprev.websocket-client.overridePythonAttrs (old: rec {
          version = "1.9.0";
          src = pkgs.fetchPypi {
            pname = "websocket_client";
            inherit version;
            hash = "sha256-noE2JLbrYZmZqX3HlYRpIXwxdjErOhakvRvH4IpG7Jg=";
          };
        });

        python-socks = pyprev.python-socks.overridePythonAttrs (old: rec {
          version = "2.8.0";
          src = pkgs.fetchPypi {
            pname = "python_socks";
            inherit version;
            hash = "sha256-NA+Cd4sgopC91TjuR0kpeNYD3/eCaq8s42LSGtnubxs=";
          };
        });

        av = pyprev.av.overridePythonAttrs (old: rec {
          version = "16.1.0";
          src = pkgs.fetchPypi {
            pname = "av";
            inherit version;
            hash = "sha256-oJS0/Yejch2s8CeU09LIK41xLIW5U0Q36CqKl4wXX/0=";
          };
        });

        pillow = pyprev.pillow.overridePythonAttrs (old: rec {
          version = "12.1.1";
          src = pkgs.fetchPypi {
            pname = "pillow";
            inherit version;
            hash = "sha256-mtj6WTerBSGOK2pM/zApWtNa/S+DrFkuaMDYcbsP28Q=";
          };
        });
      };
    };

    endcordSrc = pkgs.fetchFromGitHub {
      owner = "sparklost";
      repo = "endcord";
      rev = "98b4322f9f91c28d5f32427b89b90f4f2b9f75dd";
      hash = "sha256-WeeKs3wbmIm+/qL9C/sRYckpfgB9JY0RblbTowozrTs=";
    };

    endcordDeps = with pythonOverrides.pkgs; [
      discord-protos
      emoji
      filetype
      numpy
      orjson
      pexpect
      pycryptodome
      pynacl
      pysocks
      python-socks
      qrcode
      soundcard
      soundfile
      urllib3
      websocket-client
      av
      pillow
    ];

    endcordPkg = pythonOverrides.pkgs.buildPythonApplication {
      pname = "endcord";
      version = "1.3.0";

      src = endcordSrc;

      pyproject = true;

      build-system = with pythonOverrides.pkgs; [
        setuptools
        cython
      ];

      dependencies = endcordDeps;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      buildInputs = with pkgs; [
        ncurses
        libsecret
        alsa-lib
      ];

      doCheck = false;

      postInstall = ''
        makeWrapper ${pythonOverrides.pkgs.python.interpreter} $out/bin/endcord \
          --prefix PYTHONPATH : "${pythonOverrides.pkgs.makePythonPath endcordDeps}" \
          --prefix PYTHONPATH : "${endcordSrc}" \
          --add-flags "${endcordSrc}/main.py"
      '';

      meta = {
        description = "Feature rich Discord TUI client";
        homepage = "https://github.com/sparklost/endcord";
        mainProgram = "endcord";
      };
    };

    extraTools = with pkgs; [
      xclip
      wl-clipboard
      (aspellWithDicts (dicts: with dicts; [ en ]))
      yt-dlp
    ];

    wrappedEndcord = pkgs.symlinkJoin {
      name = "endcord-wrapped";
      paths = [endcordPkg];
      buildInputs = extraTools;
      nativeBuildInputs = [pkgs.makeWrapper];

      postBuild = ''
        wrapProgram $out/bin/endcord \
          --prefix PATH : ${pkgs.lib.makeBinPath extraTools}
      '';

      meta = {
        mainProgram = "endcord";
        description = "Feature rich Discord TUI client with optional tools";
      };
    };
  in {
    packages.endcord = wrappedEndcord;
  };
}
