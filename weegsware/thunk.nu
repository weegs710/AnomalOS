
# thunk -- local image generation (Z-Image Turbo on the AMD GPU)
#
# gen drives stable-diffusion.cpp, ui serves a refinement web page from its server binary on 127.0.0.1
# and, when the rewriter models are fetched, a CPU-only llama.cpp server one port up that writes the next prompt.
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
    {
        HSA_OVERRIDE_GFX_VERSION: ($env.HSA_OVERRIDE_GFX_VERSION? | default "10.3.0")
        HIP_VISIBLE_DEVICES: ($env.HIP_VISIBLE_DEVICES? | default "0")
    }
}

# usage
def main [] {
    print "thunk -- local image generation\n"
    print "  thunk gen \"<prompt>\" [-s SEED] [-W 768] [-H 768] [--steps 8] [-b N] [-i INIT.png --strength 0.75] [-o out.png]"
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
] {
    need-models
    let seed = ($seed | default (random int 0..2147483647))
    let out = ($out | default $"thunk-($seed).png")
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
        if not ($init | path exists) { die $"no such init image: ($init)" }
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

# serve the web page on localhost, backed by the same model files, with the CPU rewriter one port up
def "main ui" [--port: int = 8188, --no-rewriter] {
    need-models
    let have = (roles rewriter | all {|r| (model-path $r | path exists) })
    if (not $no_rewriter) and (not $have) {
        print -e "thunk: rewriter models are not fetched, the page runs without it -- run: thunk models fetch rewriter"
    }
    if (not $no_rewriter) and $have {
        let rport = $port + 1
        let threads = ([4 ((sys cpu | length) // 2)] | math max)
        let log = (data-dir | path join "rewriter.log")
        # exactly one origin: given a list, the server sends the whole list as Access-Control-Allow-Origin and browsers refuse it
        let largs = [
            "-m" (model-path rewriter) "--mmproj" (model-path rewriter_vision)
            "--host" "127.0.0.1" "--port" $rport
            "--cors-origins" $"http://127.0.0.1:($port)"
            "-t" $threads "-c" 8192 "-np" 1 "--no-warmup"
        ]
        print -e $"thunk: rewriter loading on http://127.0.0.1:($rport), cpu only, log in ($log)"
        job spawn { ^$env.THUNK_LLAMA_SERVER ...$largs o+e> $log } | ignore
    }
    let args = [
        "--listen-ip" "127.0.0.1" "--listen-port" $port
        "--serve-html-path" $env.THUNK_UI
        "--diffusion-model" (model-path diffusion)
        "--vae" (model-path vae)
        "--llm" (model-path llm)
        "--offload-to-cpu" "--vae-tiling"
    ]
    print -e $"thunk: loading the model, then the page is at http://127.0.0.1:($port) -- Ctrl+C stops it"
    load-env (gpu-env)
    ^$env.THUNK_SD_SERVER ...$args
}
