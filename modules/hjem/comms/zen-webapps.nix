{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  # makes the zen-discord kiosk profile chromeless -- hides toolbar + vertical tab sidebar so it reads as an app, not a browser
  zenDiscordUserChrome = pkgs.writeText "zen-discord-userChrome.css" ''
    #navigator-toolbox,
    #zen-sidebar-splitter,
    #zen-sidebar-top-buttons,
    #zen-appcontent-navbar-wrapper,
    .zen-toolbar-background,
    .titlebar-buttonbox-container {
      display: none !important;
    }
  '';

  # legacyUserProfileCustomizations is required for userChrome.css to load at all
  zenDiscordUserJs = pkgs.writeText "zen-discord-user.js" ''
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    user_pref("sidebar.visibility", "hide-sidebar");
  '';

  # makes the zen-steamchat profile chromeless -- hides toolbar + vertical tab sidebar so it reads as an app, not a browser
  zenSteamchatUserChrome = pkgs.writeText "zen-steamchat-userChrome.css" ''
    #navigator-toolbox,
    #zen-sidebar-splitter,
    #zen-sidebar-top-buttons,
    #zen-appcontent-navbar-wrapper,
    .zen-toolbar-background,
    .titlebar-buttonbox-container {
      display: none !important;
    }
  '';

  # legacyUserProfileCustomizations is required for userChrome.css to load at all
  zenSteamchatUserJs = pkgs.writeText "zen-steamchat-user.js" ''
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    user_pref("sidebar.visibility", "hide-sidebar");
  '';
in
{
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/share/zen-discord"
    ".local/share/zen-steamchat"
  ];

  system.activationScripts.zen-discord-setup = lib.stringAfter [ "users" ] ''
    profile_dir="/persist/home/${username}/.local/share/zen-discord"
    chrome_dir="$profile_dir/chrome"

    mkdir -p "$chrome_dir"
    cp ${zenDiscordUserChrome} "$chrome_dir/userChrome.css"
    cp ${zenDiscordUserJs} "$profile_dir/user.js"
    chmod 644 "$chrome_dir/userChrome.css" "$profile_dir/user.js"
    chown -R ${username}: "$profile_dir"
  '';

  system.activationScripts.zen-steamchat-setup = lib.stringAfter [ "users" ] ''
    profile_dir="/persist/home/${username}/.local/share/zen-steamchat"
    chrome_dir="$profile_dir/chrome"

    mkdir -p "$chrome_dir"
    cp ${zenSteamchatUserChrome} "$chrome_dir/userChrome.css"
    cp ${zenSteamchatUserJs} "$profile_dir/user.js"
    chmod 644 "$chrome_dir/userChrome.css" "$profile_dir/user.js"
    chown -R ${username}: "$profile_dir"
  '';
}
