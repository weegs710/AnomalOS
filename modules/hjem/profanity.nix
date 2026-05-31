{
  config,
  lib,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  starterAccounts = pkgs.writeText "profanity-accounts" ''
    [weegs@disroot.org]
    jid=weegs@disroot.org
    resource=hex
    enabled=true
    muc.nick=weegs
    muc.service=conference.disroot.org
    presence.last=online
    presence.login=online
    priority.online=0
    priority.chat=0
    priority.away=0
    priority.xa=0
    priority.dnd=0
    eval_password=cat /run/agenix/disroot-xmpp-password
    script.start=libera-startup
    theme=eldritch
  '';
in
{
  users.users.${username}.packages = [ pkgs.profanity ];

  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/profanity"
    ".local/share/profanity"
  ];

  hjem.users.${username}.files = {
    ".local/share/profanity/themes/eldritch".text = ''
      [colours]
      bkgnd=grey15
      titlebar=grey19
      titlebar.text=grey93
      titlebar.brackets=grey30
      titlebar.unencrypted=indianred1
      titlebar.encrypted=seagreen1
      titlebar.trusted=seagreen1
      titlebar.untrusted=indianred1
      titlebar.online=seagreen1
      titlebar.offline=grey30
      titlebar.away=lightsteelblue3
      titlebar.chat=seagreen1
      titlebar.dnd=indianred1
      titlebar.xa=lightsteelblue3

      statusbar=grey19
      statusbar.text=grey93
      statusbar.time=lightsteelblue3
      statusbar.brackets=grey30
      statusbar.active=lightsteelblue3
      statusbar.current=seagreen1
      statusbar.new=bold_turquoise2
      main.text=grey93
      main.text.me=seagreen1
      main.text.them=grey93
      main.splash=seagreen1
      main.help.header=turquoise2
      main.time=grey30

      input.text=grey93
      subscribed=seagreen1
      unsubscribed=indianred1
      otr.started.trusted=seagreen1
      otr.started.untrusted=indianred1
      otr.ended=indianred1
      otr.trusted=seagreen1
      otr.untrusted=indianred1
      online=seagreen1
      away=lightsteelblue3
      chat=seagreen1
      dnd=indianred1
      xa=lightsteelblue3
      offline=grey30
      incoming=turquoise2
      mention=seagreen1
      trigger=mediumpurple1
      typing=lightsteelblue3
      gone=grey30
      error=indianred1
      roominfo=lightsteelblue3
      roommention=seagreen1
      roommention.term=seagreen1
      roomtrigger=mediumpurple1
      roomtrigger.term=mediumpurple1
      me=seagreen1
      them=grey93
      roster.header=turquoise2
      roster.chat=seagreen1
      roster.online=seagreen1
      roster.away=lightsteelblue3
      roster.xa=lightsteelblue3
      roster.dnd=indianred1
      roster.offline=grey30
      roster.chat.active=seagreen1
      roster.online.active=seagreen1
      roster.away.active=lightsteelblue3
      roster.xa.active=lightsteelblue3
      roster.dnd.active=indianred1
      roster.offline.active=grey30
      roster.chat.unread=bold_seagreen1
      roster.online.unread=bold_seagreen1
      roster.away.unread=bold_lightsteelblue3
      roster.xa.unread=bold_lightsteelblue3
      roster.dnd.unread=bold_indianred1
      roster.offline.unread=bold_grey30
      roster.room=turquoise2
      roster.room.unread=bold_turquoise2
      roster.room.mention=seagreen1
      roster.room.trigger=mediumpurple1
      occupants.header=turquoise2
      receipt.sent=grey30
    '';

    ".local/share/profanity/scripts/libera-startup".text = ''
      /join #technicalrenaissance%irc.libera.chat@irc.disroot.org
      /join #linux%irc.libera.chat@irc.disroot.org
      /join #gamingonlinux%irc.libera.chat@irc.disroot.org
      /join ##anime%irc.libera.chat@irc.disroot.org
      /join #emacs%irc.libera.chat@irc.disroot.org
      /join #emacs-social%irc.libera.chat@irc.disroot.org
      /join #nixos%irc.libera.chat@irc.disroot.org
      /join #zfs%irc.libera.chat@irc.disroot.org
    '';
  };

  # profanity writes to accounts (omemo keys, last activity) and profrc (settings),
  # so both are bootstrapped as writable files rather than hjem symlinks.
  system.activationScripts.profanity-setup = lib.stringAfter [ "agenix" ] ''
    data_dir="/persist/home/${username}/.local/share/profanity"
    config_dir="/persist/home/${username}/.config/profanity"
    accounts_file="$data_dir/accounts"
    profrc="$config_dir/profrc"

    mkdir -p "$data_dir" "$config_dir"
    chown ${username}: "$data_dir" "$config_dir"
    chmod 700 "$data_dir"

    if [ ! -f "$accounts_file" ]; then
      install -m 600 -o ${username} ${starterAccounts} "$accounts_file"
    else
      grep -q "^script\.start=" "$accounts_file" || \
        ${pkgs.gnused}/bin/sed -i '/^\[weegs@disroot\.org\]/a script.start=libera-startup' "$accounts_file"
      grep -q "^theme=" "$accounts_file" || \
        ${pkgs.gnused}/bin/sed -i '/^\[weegs@disroot\.org\]/a theme=eldritch' "$accounts_file"
    fi

    if [ ! -f "$profrc" ] || [ ! -s "$profrc" ]; then
      printf '[ui]\nmouse=true\n\n[connection]\naccount=weegs@disroot.org\n' > "$profrc"
      chown ${username}: "$profrc"
      chmod 600 "$profrc"
    else
      grep -q "^account=" "$profrc" || \
        printf '\n[connection]\naccount=weegs@disroot.org\n' >> "$profrc"
    fi
  '';
}
