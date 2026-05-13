{ inputs, ... }: {
  flake.nixosModules.concord =
    { config, lib, pkgs, ... }:
    let
      username = config.mySystem.user.name;
      concord = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.concord;
    in
    {
      users.users.${username}.packages = [ concord ];

      hjem.users.${username}.files.".config/concord/config.toml".text = ''
        [display]
        disable_image_preview = false
        show_avatars = true
        show_images = true
        image_preview_quality = "high"
        show_custom_emoji = true
        desktop_notifications = true
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
    };
}
