{
  config,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
  dusklight = inputs.dusklight.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  users.users.${username}.packages = [ dusklight ];

  hjem.users.${username}.xdg.data.files."TwilitRealm/Dusklight/config.json".source = ./config.json;

  preservation.preserveAt."/persist".users.${username} = {
    directories = [
      ".local/share/TwilitRealm/Dusklight/USA"
      ".local/share/TwilitRealm/Dusklight/texture_replacements"
    ];
    files = [
      ".local/share/TwilitRealm/Dusklight/achievements.json"
      ".local/share/TwilitRealm/Dusklight/dawn_cache.db"
      ".local/share/TwilitRealm/Dusklight/pipeline_cache.db"
      ".local/share/TwilitRealm/Dusklight/imgui.ini"
    ];
  };
}
