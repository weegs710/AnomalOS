{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    home-manager.users.${config.mySystem.user.name} = {
      home.file.".config/rofi/config.rasi".text = ''
        configuration {
          theme-search-dir: "/home/${config.mySystem.user.name}/.config/rofi/themes";
        }

        @theme "darkblue-bottom"
      '';

      home.file.".config/rofi/themes/darkblue-bottom.rasi".text = ''
        /**
         * Outrun Dark theme for rofi
         * Bottom-center positioning with stylix colors
         */
        * {
            font:                        "sans 18";
            background-color:            #${config.lib.stylix.colors.base00};
            foreground:                  #${config.lib.stylix.colors.base05};
            selected-normal-foreground:  #${config.lib.stylix.colors.base00};
            selected-normal-background:  #${config.lib.stylix.colors.base0D};
            selected-urgent-foreground:  #${config.lib.stylix.colors.base00};
            selected-urgent-background:  #${config.lib.stylix.colors.base08};
            selected-active-foreground:  #${config.lib.stylix.colors.base00};
            selected-active-background:  #${config.lib.stylix.colors.base0B};
            normal-foreground:           #${config.lib.stylix.colors.base05};
            normal-background:           transparent;
            urgent-foreground:           #${config.lib.stylix.colors.base08};
            urgent-background:           transparent;
            active-foreground:           #${config.lib.stylix.colors.base0D};
            active-background:           transparent;
            alternate-normal-foreground: #${config.lib.stylix.colors.base05};
            alternate-normal-background: transparent;
            border-color:                #${config.lib.stylix.colors.base0C};
            separatorcolor:              #${config.lib.stylix.colors.base03};
        }

        window {
            location: south;
            anchor: south;
            width: 25%;
            background-color: #${config.lib.stylix.colors.base00};
            border: 1;
            border-color: #${config.lib.stylix.colors.base0D};
            border-radius: 15px;
            padding: 10;
        }

        mainbox {
            border:  0;
            padding: 0;
        }

        message {
            border:       2px 0px 0px;
            border-color: @separatorcolor;
            padding:      5px;
        }

        textbox {
            text-color: @foreground;
        }

        listview {
            lines:        7;
            fixed-height: 0;
            border:       2px 0px 0px;
            border-color: @separatorcolor;
            spacing:      2px;
            scrollbar:    false;
            padding:      5px 0px 0px;
        }

        element {
            border: 0;
            padding: 5px;
            border-radius: 8px;
        }

        element-icon {
            size: 1.5em;
        }

        element-text {
            background-color: inherit;
            text-color:       inherit;
        }

        element.normal.normal {
            background-color: @normal-background;
            text-color:       @normal-foreground;
        }

        element.selected.normal {
            background-color: @selected-normal-background;
            text-color:       @selected-normal-foreground;
        }

        element.alternate.normal {
            background-color: @alternate-normal-background;
            text-color:       @alternate-normal-foreground;
        }

        inputbar {
            spacing: 0;
            text-color: @foreground;
            padding: 8px;
            background-color: #${config.lib.stylix.colors.base01};
            border: 0px 0px 1px 0px;
            border-color: #${config.lib.stylix.colors.base0D};
            border-radius: 10px;
        }

        entry {
            spacing:    0;
            text-color: @foreground;
        }

        prompt {
            spacing:    0;
            text-color: #${config.lib.stylix.colors.base0D};
        }

        inputbar {
            children: [ prompt, entry ];
        }
      '';

      home.file.".config/rofi/themes/anomal-os.rasi".text = ''
        /**
         * ROFI Color Theme
         *
         * Fullscreen theme with switchable PREVIEW option.
         * Anomal-16 color scheme by weegs710
         *
         * User: Dave Davenport (original)
         * Modified: weegs710 (Anomal-16 colors)
         * Copyright: Dave Davenport
         */

        * {
        	background-color: transparent;
        	text-color:       #00e5ff;
        	font:             "sans 10";
        }

        window {
        	location:         south;
        	anchor:           south;
        	width:            60%;
        	background-color: #0a0019cc;
        	padding:          2em;
        	children:         [ wrap, listview-split];
        	spacing:          1em;
        }


        /** We add an extra child to this if PREVIEW=true */
        listview-split {
          orientation: horizontal;
          spacing: 0.4em;
          children: [listview];
        }

        wrap {
        	expand: false;
        	orientation: vertical;
        	children: [ inputbar, message ];
        	background-image: linear-gradient(#c8b0ff0d, #c8b0ff66);
        	border-color: #3399ff;
        	border: 3px;
        	border-radius: 1em;
        }

        icon-ib {
        	expand: false;
        	filename: "system-search";
        	vertical-align: 0.5;
        	horizontal-align: 0.5;
        	size: 1em;
        }
        inputbar {
        	spacing: 0.4em;
        	padding: 0.4em;
        	children: [ icon-ib, entry ];
        }
        entry {
        	placeholder: "Search";
        	placeholder-color: #3d2a7a;
        }
        message {
        	background-color: #ff006633;
        	border-color: #ff6600;
        	border: 3px 0px 0px 0px;
        	padding: 0.4em;
        	spacing: 0.4em;
        }

        listview {
        	flow: horizontal;
        	fixed-columns: true;
        	columns: 10;
        	lines: 7;
        	spacing: 1.0em;
        }

        element {
        	orientation: vertical;
        	padding: 0.1em;

        	background-image: linear-gradient(#c8b0ff0d, #c8b0ff33);
        	border-color: #3399ff26;
        	border: 3px;
        	border-radius: 1em;

          children: [element-icon, element-text ];
        }
        element-icon {
        	size: calc(((100% - 8em) / 10 ));
        	horizontal-align: 0.5;
        	vertical-align: 0.5;
        }
        element-text {
        	horizontal-align: 0.5;
        	vertical-align: 0.5;
          padding: 0.2em;
        }

        element selected {
        	background-image: linear-gradient(#ff00ff40, #ff00ff1a);
        	border-color: #ff00ff;
        	border: 3px;
        	border-radius: 1em;
        }

        /**
         * Launching rofi with environment PREVIEW set to true
         * will split the screen and show a preview widget.
         */
        @media ( enabled: env(PREVIEW, false)) {
          /** preview widget */
          icon-current-entry {
            expand:          true;
            size:            80%;
          }
          listview-split {
            children: [listview, icon-current-entry];
          }
          listview {
          columns: 4;
          }

        }

        @media ( enabled: env(NO_IMAGE, false)) {
        	listview {
        		columns: 1;
        		spacing: 0.4em;
        	}
        	element {
        		children: [ element-text ];
        	}
        	element-text {
        		horizontal-align: 0.0;
        	}
        }
      '';
    };
  };
}
