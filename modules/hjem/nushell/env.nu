$env.SHELL = (^which nu | str trim)
$env.PAGER = "bat"
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"

# Run directly without save/source pattern (Nushell-specific behavior)
oh-my-posh init nu --config ~/.config/oh-my-posh/config.json
source ~/.config/nushell/atuin-init.nu

$env.CARAPACE_BRIDGES = 'fish,bash,zsh'
$env.CARAPACE_CACHE = $'($env.HOME)/.cache/carapace'
$env.CARAPACE_MATCH = '^(?!docker$)' # Disable docker completions due to carapace bug with 'docker build -f <TAB>' See: https://github.com/nushell/nushell/issues/13201

$env.config = ($env.config? | default {} | merge {
  hooks: {
    pre_prompt: [{ ||
      if (which direnv | is-empty) {
        return
      }
      direnv export json | from json | default {} | load-env
    }]
  }
})
