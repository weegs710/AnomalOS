let
  # the .pub files end in a newline that would otherwise become part of the recipient
  key = name: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ./recipients/${name}.pub);

  # age refuses to mix post-quantum and classic recipients in one file, so all three are ML-KEM hybrids
  recipients = [
    (key "weegs-main")
    (key "weegs-backup")
    (key "HX99G")
  ];
in
{
  "tailscale-authkey.age".publicKeys = recipients;
  "radarr-api-key.age".publicKeys = recipients;
  "radarr-env.age".publicKeys = recipients;
  "sonarr-api-key.age".publicKeys = recipients;
  "sonarr-env.age".publicKeys = recipients;
  "disroot-xmpp-password.age".publicKeys = recipients;
  "searx-secret-key.age".publicKeys = recipients;
  "github-token.age".publicKeys = recipients;
}
