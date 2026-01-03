# Noctalia shell settings (declarative Nix configuration)
# Generated from GUI settings in gui-settings.json
#
# Workflow:
# 1. Make changes in noctalia GUI
# 2. GUI changes are saved to ~/.config/noctalia/gui-settings.json (via NOCTALIA_SETTINGS_FALLBACK)
# 3. Run diff to see changes:
#    diff -u <(jq -S . ~/.config/noctalia/settings.json) \
#            <(jq -S . ~/.config/noctalia/gui-settings.json)
# 4. Copy new gui-settings.json to this directory and rebuild to make permanent

{ lib, ... }:

# Read and convert the JSON file to a Nix attribute set
builtins.fromJSON (builtins.readFile ./gui-settings.json)
