def cachix-pin-system [] {
    let store_path = (^nix path-info /run/current-system | str trim)
    print $"Pinning ($store_path) as 'current-system' --keep-revisions 3..."
    # Fixed name so --keep-revisions rotates over revisions of the same pin, not unique pins that never evict.
    ^cachix pin anomalos "current-system" $store_path --keep-revisions 3
    print "Done."
}

def nrs [] {
    nh os switch
    if $env.LAST_EXIT_CODE == 0 {
        ^nix-store -qR /run/current-system | ^cachix push anomalos
        if $env.LAST_EXIT_CODE == 0 {
            cachix-pin-system
        }
    }
}

def nrt [] {
    nh os test
}

def nrbt [] {
    nh os boot
}

def nrbld [] {
    nh os build
}

def --wrapped tu [...inputs: string] {
    cd ~/repo/public/anomalos/
    if ($inputs | is-empty) {
        ^tack update
    } else {
        ^tack update ...$inputs
    }
}

def --wrapped tl [...inputs: string] {
    cd ~/repo/public/anomalos/
    if ($inputs | is-empty) {
        ^tack look
    } else {
        ^tack look ...$inputs
    }
}

def closure [] {
    nix path-info -Sh /run/current-system
}

def --wrapped snag [...args: string] {
    nu ~/.config/snag/snag.nu ...$args
}

def --wrapped yoink [...args: string] {
    nu ~/.config/yoink/yoink.nu ...$args
}

def --wrapped sync-music [...args: string] {
    nu ~/.config/sync-music/sync-music.nu ...$args
}

def --wrapped gb [...args: string] {
    nu ~/repo/private/weegs.dev/moderate.nu ...$args
}

def --wrapped draw [...args: string] {
    nu ~/repo/public/anomalos/lib/scripts/draw.nu ...$args
}

def evaltime [] {
    hyperfine $'nix eval ($env.NH_FLAKE)#nixosConfigurations.HX99G.config.system.build.toplevel --substituters " " --option eval-cache false --raw --read-only'
}

def recycle [] {
    sudo nix-env --delete-generations +10 --profile /nix/var/nix/profiles/system
    sudo nix-collect-garbage
}

def jj-pull [] {
    jj git fetch --all-remotes
    jj bookmark move main --to main@origin
}

def jj-push [] {
    jj git fetch --all-remotes
    jj git push
    jj git fetch --all-remotes
}

def jj-commit [] {
    let status_output = jj status | complete | get stdout

    if ($status_output | str contains "The working copy has no changes") {
        print "Error: No changes to commit. Working copy is clean."
        return 1
    }

    jj spi
    jj bookmark move --from 'closest_bookmark(@-)' --to @-
}

def tngl-pull [] {
    jj git fetch --remote tangled
    jj bookmark move main --to main@tangled
}

def tngl-push [] {
    jj git fetch --remote tangled
    jj git push --remote tangled
    jj git fetch --remote tangled
}

def noct-r [] {
    systemctl --user restart noctalia
}

# promote noctalia gui changes (state overlay) into the declared repo config so they survive rebuilds + get vcs history
def noct-s [] {
    noctalia config export merged | complete | get stdout | save --force ~/repo/public/anomalos/modules/hjem/desktop/noctalia/config.toml
}

# pull gui-edited zed settings back into the repo (reverse of the copy-type rebuild); --raw keeps jsonc comments verbatim
def zed-s [] {
    open --raw ~/.config/zed/settings.json | save --force ~/repo/public/anomalos/modules/hjem/desktop/zed/settings.json
}

# pull gui-edited vesktop + vencord settings back into the repo (reverse of the copy-type rebuild)
def vesk-s [] {
    open --raw ~/.config/vesktop/settings.json | save --force ~/repo/public/anomalos/modules/hjem/comms/vesktop/settings.json
    open --raw ~/.config/vesktop/settings/settings.json | save --force ~/repo/public/anomalos/modules/hjem/comms/vesktop/vencord-settings.json
}

def space [] {
    df -h | detect columns --guess
}

def room [] {
    df -h . | detect columns --guess
}

alias repl = nix repl --expr 'import ~/repo/public/anomalos/repl.nix {}'
alias ccl = claude-launcher
alias hex = claude-launcher hex
alias l = ls -alh
alias ll = ls -l
alias closure = nix path-info -Sh /run/current-system
alias cam-cust = andcam-custom
alias cam-d = andcam-daemon
alias cam-list = andcam-list
alias cam-off = pkill scrcpy
alias cam-on = andcam-start
alias gparted = gparted-safe
alias jj-fetch = jj git fetch --all-remotes
alias tngl-fetch = jj git fetch --remote tangled
alias pixel = ssh -p 8022 u0_a267@100.121.71.20

def nu_greeting [] {
    let states = [
        "Analyzing system mutations..."
        "Optimizing evaluation times..."
        "Dreaming of derivations..."
        "Refactoring reality..."
        "Compiling consciousness..."
        "Binging vimjoyer content..."
        "Studying iynaix's code..."
    ]
    let state = $states | shuffle | first

    print -n $"(ansi cyan)   (ansi reset)"
    print $"Status: ($state)"
}

# Zoxide integration (migrated from Fish 'z' plugin)
def --env --wrapped __zoxide_z [...rest: string] {
    let path = match $rest {
        [] => { '~' }
        ['-'] => { '-' }
        [$arg] if ($arg | path expand | path type) == 'dir' => { $arg }
        _ => {
            ^zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n"
        }
    }
    cd $path
}

def --env --wrapped __zoxide_zi [...rest: string] {
    cd $'(^zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
}

alias z = __zoxide_z
alias zi = __zoxide_zi

let carapace_completer = {|spans: list<string>|
    carapace $spans.0 nushell ...$spans
    | from json
    | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
}

let fish_completer = {|spans: list<string>|
    fish --command $"complete '--do-complete=($spans | str join ' ')'"
    | from tsv --flexible --noheaders --no-infer
    | rename value description
}

let combined_completer = {|spans: list<string>|
    let result = do $carapace_completer $spans | default []
    if ($result | is-empty) {
        do $fish_completer $spans
    } else {
        $result
    }
}

$env.config = {
    show_banner: false
    hooks: {
        env_change: {
            PWD: [
                {
                    condition: {|before, after| $before == null }
                    code: {|| nu_greeting }
                }
                {
                    code: {|_, dir| ^zoxide add -- $dir }
                }
            ]
        }
    }
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "prefix"
        external: {enable: true, max_results: 100, completer: $combined_completer}
    }
    history: {max_size: 100000, sync_on_enter: true, file_format: "sqlite"}

    # Emacs mode for Fish muscle memory compatibility
    edit_mode: emacs
    table: {
        mode: rounded
        index_mode: always
        show_empty: true
        padding: {left: 1, right: 1}
    }
    error_style: "fancy"
    use_ansi_coloring: true
    cursor_shape: {vi_insert: line, vi_normal: block, emacs: line}
}
