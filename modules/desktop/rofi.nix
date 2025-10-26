{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config = mkIf config.mySystem.features.desktop {
    home-manager.users.${config.mySystem.user.name} = {
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
        	font:             "Terminess Nerd Font 10";
        }

        window {
        	fullscreen:       true;
        	background-color: #0a0019cc;
        	padding:          4em;
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
