{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

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
    gajim
  ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".local/share/gajim"
    ".config/gajim"
  ];

  # kept as a nix attrset, not an extracted json: the attrset is the source, json would just be its generated output
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
