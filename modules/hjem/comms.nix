{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  username = config.mySystem.user.name;
  concord = inputs.concord.packages.${pkgs.stdenv.hostPlatform.system}.default;

  gajim = pkgs.gajim.overrideAttrs (old: {
    # gst-plugins-rs provides gtk4paintablesink -- without it the animated image pipeline fails and GIFs open twice
    buildInputs = old.buildInputs ++ [ pkgs.gst_all_1.gst-plugins-rs ];
  });

  gajimBootstrap = pkgs.writeText "gajim-bootstrap.nu" ''
    let data_dir = "/persist/home/${username}/.local/share/gajim"
    let settings_db = ($data_dir | path join "settings.db")
    let password = (open --raw /run/agenix/disroot-xmpp-password | str trim)
    let account_json = ({active: true, resource: "hex", savepass: true, password: $password} | to json)

    if not ($settings_db | path exists) {
        stor open | query db "CREATE TABLE settings (name TEXT UNIQUE, settings TEXT)"
        stor open | query db "CREATE TABLE account_settings (account TEXT UNIQUE, settings TEXT)"
        for name in [app soundevents proxies plugins workspaces window_sizes] {
            stor open | query db "INSERT INTO settings(name, settings) VALUES (?, ?)" --params [$name "{}"]
        }
        stor open | query db "INSERT INTO account_settings(account, settings) VALUES (?, ?)" --params ["weegs@disroot.org" $account_json]
        stor export --file-name $settings_db
    } else {
        let exists = (
            try {
                open $settings_db | query db "SELECT COUNT(*) AS cnt FROM account_settings WHERE account = ?" --params ["weegs@disroot.org"] | get cnt.0
            } catch {
                0
            }
        )
        if $exists == 0 {
            open $settings_db | query db "INSERT INTO account_settings(account, settings) VALUES (?, ?)" --params ["weegs@disroot.org" $account_json]
        }
    }
  '';
in
{
  users.users.${username}.packages = [
    concord
    gajim
  ];

  hjem.users.${username}.files.".config/concord/config.toml".text = ''
    [display]
    disable_image_preview = false
    show_avatars = true
    show_images = true
    image_preview_quality = "high"
    show_custom_emoji = true

    [notifications]
    desktop_notifications = true

    [voice]
    voice_output_volume = 100
    self_mute = false
    self_deaf = false
    allow_microphone_transmit = true
    microphone_sensitivity = -60
  '';

  system.activationScripts.concord-credential = lib.stringAfter [ "agenix" ] ''
    cred_dir="/persist/home/${username}/.config/concord"
    cred_path="$cred_dir/credential"

    mkdir -p "$cred_dir"
    chown ${username}: "$cred_dir"
    chmod 700 "$cred_dir"

    if [ ! -f "$cred_path" ]; then
      token=$(cat ${config.age.secrets.discord-token.path})
      printf '%s' "$token" > "$cred_path"
      chmod 600 "$cred_path"
      chown ${username}: "$cred_path"
    fi
  '';

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/concord"
    ".local/share/gajim"
    ".config/gajim"
  ];

  # force ConfigPasswordStorage -- no gnome-keyring/kwallet on this system
  environment.etc."gajim/app-overrides.json".text = builtins.toJSON {
    use_keyring = false;
  };

  system.activationScripts.gajim-setup = lib.stringAfter [ "agenix" ] ''
    data_dir="/persist/home/${username}/.local/share/gajim"
    mkdir -p "$data_dir"
    chown ${username}: "$data_dir"
    chmod 700 "$data_dir"
    ${pkgs.nushell}/bin/nu ${gajimBootstrap}
    chown ${username}: "$data_dir/settings.db" 2>/dev/null || true
  '';
}
