{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.mySystem.features.desktop {
    home-manager.users.${config.mySystem.user.name} = {
      home.file.".config/stylix-web16.json".text = builtins.toJSON [
        {
          id = 1;
          enabled = true;
          name = "Stylix Web16";
          sections = [
            {
              code = ''
                    :root {
                  --base00: #${config.lib.stylix.colors.base00} !important;
                  --base01: #${config.lib.stylix.colors.base01} !important;
                  --base02: #${config.lib.stylix.colors.base02} !important;
                  --base03: #${config.lib.stylix.colors.base03} !important;
                  --base04: #${config.lib.stylix.colors.base04} !important;
                  --base05: #${config.lib.stylix.colors.base05} !important;
                  --base06: #${config.lib.stylix.colors.base06} !important;
                  --base07: #${config.lib.stylix.colors.base07} !important;
                  --base08: #${config.lib.stylix.colors.base08} !important;
                  --base09: #${config.lib.stylix.colors.base09} !important;
                  --base0A: #${config.lib.stylix.colors.base0A} !important;
                  --base0B: #${config.lib.stylix.colors.base0B} !important;
                  --base0C: #${config.lib.stylix.colors.base0C} !important;
                  --base0D: #${config.lib.stylix.colors.base0D} !important;
                  --base0E: #${config.lib.stylix.colors.base0E} !important;
                  --base0F: #${config.lib.stylix.colors.base0F} !important;
                }

                body {
                  background-color: var(--base00) !important;
                  color: var(--base05) !important;
                }

                a {
                  color: var(--base0D) !important;
                }

                a:visited {
                  color: var(--base0E) !important;
                }

                a:hover {
                  color: var(--base0C) !important;
                }

                code, pre {
                  background-color: var(--base01) !important;
                  color: var(--base05) !important;
                  border: 1px solid var(--base02) !important;
                }

                h1, h2, h3, h4, h5, h6 {
                  color: var(--base05) !important;
                }

                input, textarea, select {
                  background-color: var(--base01) !important;
                  color: var(--base05) !important;
                  border: 1px solid var(--base03) !important;
                }

                button {
                  background-color: var(--base02) !important;
                  color: var(--base05) !important;
                  border: 1px solid var(--base03) !important;
                }

                    button:hover {
                      background-color: var(--base03) !important;
                    }
              '';
              urls = [];
              domains = [];
              regexps = [".*"];
            }
          ];
        }
      ];
    };
  };
}
