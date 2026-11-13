{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  sources = import ../../../../_sources/generated.nix {
    inherit (pkgs)
      fetchgit
      fetchurl
      fetchFromGitHub
      dockerTools
      ;
  };

  # .NET FailFasts at startup when no ICU is present in the FHS rootfs
  evelens = pkgs.appimageTools.wrapType2 {
    inherit (sources.evelens) pname version src;
    extraPkgs = p: [ p.icu ];
  };

  # python-jose is unmaintained and carries an open auth-bypass CVE; pyfa only uses it to verify the RS256 SSO token
  # See: https://github.com/mpdavis/python-jose/issues/398
  pyfa = pkgs.pyfa.overridePythonAttrs (old: {
    dependencies = builtins.filter (p: (p.pname or "") != "python-jose") old.dependencies ++ [
      pkgs.python3Packages.pyjwt
    ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace service/esiAccess.py \
        --replace-fail "from jose import jwt" "import jwt" \
        --replace-fail "from jose.exceptions import ExpiredSignatureError, JWTError, JWTClaimsError" \
          "from jwt.exceptions import ExpiredSignatureError, InvalidTokenError as JWTError, InvalidIssuerError as JWTClaimsError" \
        --replace-fail "                jwk_set," "                jwt.PyJWK(jwk_set)," \
        --replace-fail 'algorithms=jwk_set["alg"],' 'algorithms=[jwk_set["alg"]],'
    '';
  });
in
{
  users.users.${username}.packages = [
    evelens
    pyfa
  ];

  # config.nu resolves the bare filename relative to itself, so this has to land beside it
  hjem.users.${username}.xdg.config.files."nushell/eve.nu".source = ./eve.nu;

  mySystem.nushell.extraConfig = ''

    use eve.nu *
  '';

  # ESI tokens and the cached SDE are runtime-written, so no module can own them declaratively
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/EveLens"
    ".pyfa"
  ];
}
