# rebuilds the triglavian-icons zed extension from charmed-icons, recolored by the {source hex: new hex} map noctalia renders

def main [colors: path] {
    let ext_root = ($env.HOME | path join ".local/share/zed/extensions")
    let src = ($ext_root | path join "installed" "charmed-icons")
    let dest = ($ext_root | path join "installed" "triglavian-icons")
    # outside installed/ so zed never reads a half-built extension
    let stage = ($ext_root | path join "triglavian-icons.build")

    if not ($src | path exists) {
        error make { msg: $"charmed-icons is not installed at ($src), zed installs it from auto_install_extensions" }
    }

    let map = (open $colors)
    let keys = ($map | columns)

    rm -rf $stage
    mkdir ($stage | path join "icon_themes") ($stage | path join "icons" "light")

    for svg in (glob ($src | path join "icons" "light" "*.svg")) {
        mut text = (open --raw $svg)
        # two passes so a new color that equals another source color is not recolored twice
        for k in $keys { $text = ($text | str replace --all --regex ("(?i)#" ++ $k) $"@@($k)@@") }
        for k in $keys { $text = ($text | str replace --all $"@@($k)@@" ($map | get $k)) }
        $text | save --force ($stage | path join "icons" "light" ($svg | path basename))
    }

    let theme = (open ($src | path join "icon_themes" "light-theme.json"))
    $theme
        | update name "Triglavian Icons"
        | update themes ($theme.themes | each { |t| $t | update name "Triglavian Icons" | update appearance "dark" })
        | to json --indent 2
        | save --force ($stage | path join "icon_themes" "triglavian.json")

    open --raw ($src | path join "extension.toml")
        | str replace --regex '(?m)^id = .*$' 'id = "triglavian-icons"'
        | str replace --regex '(?m)^name = .*$' 'name = "Triglavian Icons"'
        | str replace --regex '(?m)^description = .*$' 'description = "Charmed Icons (MIT, littensy and jmesrje) recolored from the noctalia palette"'
        | str replace --regex '(?m)^icon_themes = .*$' 'icon_themes = ["icon_themes/triglavian.json"]'
        | save --force ($stage | path join "extension.toml")

    rm -rf $dest
    mv $stage $dest
    print $"triglavian-icons rebuilt: ($keys | length) colors, ((glob ($dest | path join 'icons' 'light' '*.svg')) | length) icons"
}
