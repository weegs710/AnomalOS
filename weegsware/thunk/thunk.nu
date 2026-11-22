
# thunk -- local image generation (Z-Image Turbo through stable-diffusion.cpp)
#
# gen drives stable-diffusion.cpp, or the running workbench's queue when `thunk ui` is up.
# ui starts the workbench service: one GPU queue, projects in ~/Pictures/thunk, edit tools, a local rewriter.
# Data lives in ~/.local/share/thunk. Run `thunk models fetch` once, and `thunk models fetch rewriter` for the rewriter.

# a fixed-output fetch: nix checks the hash, and the out-link is a gc root outside the system closure
const FETCH_EXPR = r#'{ name, url, hash }: derivation {
  inherit name url;
  system = "builtin";
  builder = "builtin:fetchurl";
  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = hash;
}'#

def die [msg: string] {
    error make --unspanned { msg: $"thunk: ($msg)" }
}

def data-dir []: nothing -> string {
    $env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share") | path join "thunk"
}

def manifest []: nothing -> record {
    open $env.THUNK_MANIFEST
}

# roles without a group are the image models
def roles [group: string]: nothing -> list<string> {
    let m = (manifest)
    $m | columns | where {|r| $group == "all" or (($m | get $r | get -o group | default "image") == $group) }
}

def model-path [role: string]: nothing -> string {
    [(data-dir) "models" (manifest | get $role | get file)] | path join
}

def need-models [] {
    for role in (roles image) {
        let p = (model-path $role)
        if not ($p | path exists) {
            die $"model missing: ($p) -- run: thunk models fetch"
        }
    }
}

# gfx1032 has no kernels of its own; 10.3.0 maps it onto gfx1030
def gpu-env []: nothing -> record {
    if ($env.THUNK_GPU? | default "rocm") != "rocm" { return {} }
    {
        HSA_OVERRIDE_GFX_VERSION: ($env.HSA_OVERRIDE_GFX_VERSION? | default "10.3.0")
        HIP_VISIBLE_DEVICES: ($env.HIP_VISIBLE_DEVICES? | default "0")
    }
}

def service-url [port: int]: nothing -> string {
    $"http://127.0.0.1:($port)"
}

def service-up [port: int]: nothing -> bool {
    try { (http get --max-time 2sec $"(service-url $port)/api/state").ready } catch { false }
}

# usage
def main [] {
    print "thunk -- local image generation\n"
    print "  thunk gen \"<prompt>\" [-s SEED] [-W 768] [-H 768] [--steps 8] [-b N] [-i INIT.png --strength 0.75] [-o out.png] [--port 8188]"
    print "  thunk up <in.png> [-o out.png] [-s 4] [-n realesrgan-x4plus]"
    print "  thunk trace <in.png> [-o out.svg] [--mono]"
    print "  thunk ui [--port 8188] [--no-rewriter]"
    print "  thunk models [fetch | status | verify] [image | rewriter | all]"
}

# fetch, list or verify the model files of one group
def "main models" [action: string = "status", group: string = "image"] {
    let wanted = (roles $group)
    if ($wanted | is-empty) { die $"models: no models in group '($group)'" }
    match $action {
        "fetch" => {
            for role in $wanted {
                let m = (manifest | get $role)
                let out = (model-path $role)
                print $"fetching ($m.file)"
                mkdir ($out | path dirname)
                ^nix build --out-link $out --argstr name $m.file --argstr url $m.url --argstr hash $m.hash --expr $FETCH_EXPR
            }
        }
        "status" => {
            $wanted | each {|role|
                let m = (manifest | get $role)
                let p = (model-path $role)
                let here = ($p | path exists)
                {
                    role: $role
                    file: $m.file
                    state: (if $here { "ok" } else { "missing" })
                    store: (if $here { $p | path expand } else { "" })
                }
            }
        }
        "verify" => {
            for role in $wanted {
                let m = (manifest | get $role)
                let p = (model-path $role)
                if not ($p | path exists) { die $"missing: ($p)" }
                let got = (^nix hash file --type sha256 --sri $p | str trim)
                if $got != $m.hash { die $"hash mismatch on ($p): want ($m.hash), got ($got)" }
                print $"ok   ($m.file)"
            }
        }
        _ => { die $"models: unknown action '($action)'" }
    }
}

# hand the job to the running workbench, so only one sd process ever touches the GPU
def gen-queued [port: int, prompt: string, seed: int, width: int, height: int, steps: int, batch: int, out: string, init, strength: float] {
    let url = (service-url $port)
    http post --allow-errors --content-type application/json $"($url)/api/projects" { name: "cli" } | ignore
    let starts = if $init == null { [] } else {
        let ref = (http post --content-type application/json $"($url)/api/p/cli/ref" {
            name: ($init | path basename)
            data: (open --raw $init | encode base64)
        })
        [$"ref:($ref.ref)"]
    }
    let job = (http post --content-type application/json $"($url)/api/p/cli/round" {
        prompt: $prompt, seed: $seed, width: $width, height: $height, steps: $steps, count: $batch
        starts: $starts, strengths: [$strength]
    })
    print -e $"thunk: queued on the workbench as cli round ($job.round)"
    loop {
        let st = (http get $"($url)/api/state")
        let mine = ($st.queue | where project == "cli" and round == $job.round)
        let live = ($mine | where status in ["queued" "running"])
        if ($live | is-empty) {
            let bad = ($mine | where status in ["failed" "cancelled"])
            if not ($bad | is-empty) { die $"($bad | first | get status): ($bad | first | get error)" }
            break
        }
        sleep 1sec
    }
    let st = (http get $"($url)/api/state")
    let prints = (http get $"($url)/api/p/cli").prints | where round == $job.round and kind == "gen" | sort-by index
    let parsed = ($out | path parse)
    for p in ($prints | enumerate) {
        let dest = if ($prints | length) == 1 { $out } else {
            $parsed | update stem $"($parsed.stem)_($p.index + 1)" | path join
        }
        cp ([$st.root "cli" $p.item.file] | path join) $dest
        print -e $"thunk: seed ($p.item.seed) -> ($dest)"
    }
}

# generate an image with stable-diffusion.cpp
def "main gen" [
    prompt: string
    --seed (-s): int
    --width (-W): int = 768
    --height (-H): int = 768
    --steps: int = 8
    --batch (-b): int = 1
    --out (-o): string
    --init (-i): string
    --strength: float = 0.75
    --port: int = 8188
] {
    let seed = ($seed | default (random int 0..2147483647))
    let out = ($out | default $"thunk-($seed).png")
    if $init != null and not ($init | path exists) { die $"no such init image: ($init)" }
    if (service-up $port) {
        gen-queued $port $prompt $seed $width $height $steps $batch $out $init $strength
        return
    }
    need-models
    mut args = [
        "--diffusion-model" (model-path diffusion)
        "--vae" (model-path vae)
        "--llm" (model-path llm)
        "--cfg-scale" "1.0" "--steps" $steps
        "-W" $width "-H" $height "-b" $batch "--seed" $seed
        "--offload-to-cpu" "--vae-tiling"
        "-p" $prompt "-o" $out
    ]
    if $init != null {
        $args = ($args | append ["-i" $init "--strength" $strength])
    }
    print -e $"thunk: seed ($seed) -> ($out)"
    load-env (gpu-env)
    ^$env.THUNK_SD ...$args
}

# upscale with Real-ESRGAN
def "main up" [
    input: string
    --out (-o): string
    --scale (-s): int = 4
    --model (-n): string = "realesrgan-x4plus"
] {
    if not ($input | path exists) { die $"no such image: ($input)" }
    let out = ($out | default ($input | path parse | update stem {|p| $"($p.stem)-x($scale)" } | update extension "png" | path join))
    ^$env.THUNK_ESRGAN -i $input -o $out -s $scale -n $model
}

# vectorise to svg: vtracer for colour, potrace for a one-colour trace
def "main trace" [
    input: string
    --out (-o): string
    --mono
] {
    if not ($input | path exists) { die $"no such image: ($input)" }
    let out = ($out | default ($input | path parse | update extension "svg" | path join))
    if $mono {
        ^magick $input -background white -alpha remove -colorspace Gray -threshold "50%" "pbm:-" | ^potrace --svg -o $out
    } else {
        ^vtracer --input $input --output $out
    }
    print -e $"thunk: wrote ($out)"
}

# the workbench on localhost: the image model, the rewriter (cpu) and the page, Ctrl+C stops all three
def "main ui" [--port: int = 8188, --no-rewriter] {
    need-models
    if (service-up $port) { die $"a workbench is already running on (service-url $port)" }
    let have = (roles rewriter | all {|r| (model-path $r | path exists) })
    if (not $no_rewriter) and (not $have) {
        print -e "thunk: the vision rewriter is not fetched, the page writes prompts without seeing prints -- run: thunk models fetch rewriter"
    }
    load-env (gpu-env)
    load-env {
        THUNK_PORT: ($port | into string)
        THUNK_MODELS: (data-dir | path join "models")
    }
    if $no_rewriter { $env.THUNK_NO_REWRITER = "1" }
    print -e $"thunk: loading the models, then the page is at (service-url $port)"
    ^$env.THUNK_PYTHON $env.THUNK_SERVE
}
