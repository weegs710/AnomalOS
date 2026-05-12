{ inputs, ... }: {
  flake.nixosModules.dcss =
    { config, pkgs, ... }:
    let
      username = config.mySystem.user.name;
      crawlTilesBGM = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.crawlTilesBGM;
    in
    {
      users.users.${username}.packages = [ crawlTilesBGM ];

      hjem.users.${username}.files.".crawl/init.txt".text = ''
        # Starting Screen
        restart_after_game = true
        restart_after_save = false
        pregen_dungeon = full

        # Autopickup
        autopickup = $?!+"/♦}/
        autopickup_exceptions += >scroll of uselessness
        autopickup_exceptions += >scroll of noise
        autopickup_exceptions += >scroll of immolation
        autopickup_exceptions += >scroll of inaccuracy
        autopickup_exceptions += <curare
        assign_item_slot = backward

        # Travel & Exploration
        travel_delay = 30
        rest_delay = -1
        runrest_ignore_monster += bat:3
        rest_wait_both = true
        rest_wait_ancestor = true
        auto_exclude += oklob plant
        auto_exclude += curse skull
        auto_exclude += curse toe
        auto_exclude += torpedo ray
        auto_exclude += sleeping:jellyfish

        # Command Enhancements
        auto_switch = true
        spell_menu = true
        autofight_fires = true
        autofight_caught = true
        autofight_wait = true
        warn_hatches = true
        single_column_item_menus = false

        # Messages & Display
        hp_warning = 25
        mp_warning = 25
        item_stack_summary_minimum = 2
        msg_min_height = 10
        msg_max_height = 15
        messages_at_top = true
        show_travel_trail = true
        default_show_all_skills = true
        view_delay = 200
        always_show_gems = true
        more_gem_info = true
        force_more_message += You are sucked into a shaft
        force_more_message += You fall through a shaft
        force_more_message += You are engulfed in a sudden explosion
        force_more_message += The .* is revealed
        force_more_message += You feel a surge of divine power
        force_more_message += You are.* teleport
        flash_screen_message += You are.* paralys
        flash_screen_message += You are.* petrif
        flash_screen_message += You fall through a shaft
        flash_screen_message += You are sucked into a shaft
        monster_alert += -uniques
        monster_alert += -nasty

        # Sound
        sound_file_path = /home/${username}/.crawl/sound/

        # BGM -- must come before include so these fire first (CNC OSP also matches Welcome to X)
        sound ^= Welcome.*Dungeon:bgm/dungeon.mp3
        sound ^= Welcome.*Ecumenical Temple:bgm/temple.mp3
        sound ^= Welcome.*Lair of Beasts:bgm/lair.mp3
        sound ^= Welcome.*Swamp:bgm/swamp.mp3
        sound ^= Welcome.*Shoals:bgm/shoals.mp3
        sound ^= Welcome.*Snake Pit:bgm/snake.mp3
        sound ^= Welcome.*Spider Nest:bgm/spider.mp3
        sound ^= Welcome.*Pits of Slime:bgm/slime.mp3
        sound ^= Welcome.*Orcish Mines:bgm/mines.mp3
        sound ^= Welcome.*Elven Halls:bgm/elven.mp3
        sound ^= Welcome.*Vaults:bgm/vaults.mp3
        sound ^= Welcome.*Crypt:bgm/crypt.mp3
        sound ^= Welcome.*Tomb of the Ancients:bgm/tomb.mp3
        sound ^= Welcome.*Depths:bgm/depths.mp3
        sound ^= Welcome.*Realm of Zot:bgm/zot.mp3
        sound ^= Welcome to Hell:bgm/hell.mp3
        sound ^= Welcome back to the Vestibule of Hell:bgm/hell.mp3
        sound ^= An ancient malice corrodes:bgm/dis.mp3
        sound ^= Welcome back to the Iron City of Dis:bgm/dis.mp3
        sound ^= Your scrolls appear blurry in the acrid smoke:bgm/gehenna.mp3
        sound ^= Welcome back to Gehenna:bgm/gehenna.mp3
        sound ^= Your potions freeze solid in the terrible cold:bgm/cocytus.mp3
        sound ^= Welcome back to Cocytus:bgm/cocytus.mp3
        sound ^= This decaying realm drains your will:bgm/tartarus.mp3
        sound ^= Welcome back to Tartarus:bgm/tartarus.mp3
        sound ^= You enter the Abyss:bgm/abyss.mp3
        sound ^= Welcome back to the Abyss:bgm/abyss.mp3
        sound ^= You enter the halls of Pandemonium:bgm/pandemonium.mp3
        sound ^= Welcome back to Pandemonium:bgm/pandemonium.mp3
        sound ^= You land on top of a ziggurat:bgm/ziggurat.mp3
        sound ^= You enter an inter-dimensional bazaar:bgm/bazaar.mp3
        sound ^= You enter a treasure trove:bgm/trove.mp3
        sound ^= You enter a sewer:bgm/sewer.mp3
        sound ^= You enter an ossuary:bgm/ossuary.mp3
        sound ^= You enter a bailey:bgm/bailey.mp3
        sound ^= You enter a gauntlet:bgm/gauntlet.mp3
        sound ^= You enter an ice cave:bgm/ice_cave.mp3
        sound ^= You enter a volcano:bgm/volcano.mp3
        sound ^= You enter a wizard.*s laboratory:bgm/wizlab.mp3
        sound ^= You enter a great desolation of salt:bgm/desolation.mp3
        sound ^= You are dragged down into the Crucible of Flesh:bgm/crucible.mp3
        sound ^= You enter an ornate necropolis:bgm/necropolis.mp3
        sound ^= You pick up the Orb of Zot:bgm/orb.mp3

        include = sound/init.txt

        # Tiles
        game_scale = 2
        tile_full_screen = true
        tile_tooltip_ms = 200
        tile_show_demon_tier = true
        tile_show_threat_levels = nasty, unusual, tough
        tile_player_status_icons = slow, fragile, petr, mark, will/2, haste, weak, corr, might, brill, -move
        tile_layout_priority = minimap, monster, inventory, spell, command
      '';
    };
}
