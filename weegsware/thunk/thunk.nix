{
  pkgs,
  lib,
  gpu ? "rocm",
  rocmGpuTargets ? [ "gfx1030" ],
  ...
}:
let
  # rocmSupport and cudaSupport are nixpkgs-wide switches, so the GPU build comes from its own instance and the rest of the system stays on the plain one
  gpuPkgs =
    flag:
    import pkgs.path {
      inherit (pkgs.stdenv.hostPlatform) system;
      config = {
        allowUnfree = true;
        ${flag} = true;
      };
    };

  # gfx1032 has no kernels in nixpkgs' ROCm builds, so the targets are the gfx1030 family it runs on via HSA_OVERRIDE_GFX_VERSION
  sd =
    {
      rocm = (gpuPkgs "rocmSupport").stable-diffusion-cpp.override {
        rocmSupport = true;
        inherit rocmGpuTargets;
      };
      cuda = (gpuPkgs "cudaSupport").stable-diffusion-cpp.override { cudaSupport = true; };
      vulkan = pkgs.stable-diffusion-cpp.override { vulkanSupport = true; };
    }
    .${gpu};

  # fetched at run time into ~/.local/share/thunk, never part of the system closure, so nothing here reaches a binary cache
  # roles without a group are the image models; the rewriter group is optional and fetched with `thunk models fetch rewriter`
  manifest = pkgs.writeText "thunk-models.json" (
    builtins.toJSON {
      diffusion = {
        file = "z_image_turbo-Q6_K.gguf";
        url = "https://huggingface.co/leejet/Z-Image-Turbo-GGUF/resolve/c61c0e422dc8b541b7548cf33a4ef8302b0f8085/z_image_turbo-Q6_K.gguf";
        hash = "sha256-MZ9ie+rIBZt1RvNqe01Ql7f07mofw3WF0PdcodEtAa8=";
      };
      llm = {
        file = "Qwen3-4B-Instruct-2507-Q4_K_M.gguf";
        url = "https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF/resolve/a06e946bb6b655725eafa393f4a9745d460374c9/Qwen3-4B-Instruct-2507-Q4_K_M.gguf";
        hash = "sha256-NgWAO5gstkrq1E9sGyrjbjrNtB2ORsipTGUzvExn5Zc=";
      };
      vae = {
        file = "ae.safetensors";
        url = "https://huggingface.co/Comfy-Org/Z-Image-Turbo/resolve/6fc90a3b1b653e935a0d175e260736de25b84df5/split_files/vae/ae.safetensors";
        hash = "sha256-r8jignLNFds5GbrNtpGM6cHtIulssSxNXtD7qCNSnjg=";
      };
      # the 9B sees prints and fits in RAM beside the image model; the 35B pushed sd-server out of memory
      rewriter = {
        group = "rewriter";
        file = "Qwen3.5-9B-Q4_K_M.gguf";
        url = "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/3885219b6810b007914f3a7950a8d1b469d598a5/Qwen3.5-9B-Q4_K_M.gguf";
        hash = "sha256-A7dHJ6hgpWM44ELEQguz8Esv7Fc0F19MufqFPa9St+g=";
      };
      rewriter_vision = {
        group = "rewriter";
        file = "Qwen3.5-9B-mmproj-F16.gguf";
        url = "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/3885219b6810b007914f3a7950a8d1b469d598a5/mmproj-F16.gguf";
        hash = "sha256-9w3DUJBTlisNDT7op+rOv11gqlYMrXglSuhphRauAp8=";
      };
    }
  );

  python = pkgs.python3.withPackages (p: [
    p.numpy
    p.opencv4
    p.pillow
  ]);

  # the service imports tools.py and serves the page from its own directory
  serve = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./serve.py
      ./tools.py
      ./rules.md
      ./ui.html
      ./app.js
    ];
  };

  unwrapped = pkgs.writers.writeNuBin "thunk" (builtins.readFile ./thunk.nu);

  tools = lib.makeBinPath [
    pkgs.imagemagick
    pkgs.potrace
    pkgs.vtracer
    pkgs.fontconfig
  ];
in
{
  thunk =
    pkgs.runCommand "thunk"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta = {
          description = "Local Z-Image Turbo generation with a workbench page, edit tools and a local prompt rewriter";
          mainProgram = "thunk";
        };
      }
      ''
        makeWrapper ${unwrapped}/bin/thunk $out/bin/thunk \
          --set THUNK_GPU ${gpu} \
          --set THUNK_MANIFEST ${manifest} \
          --set THUNK_SD ${lib.getExe' sd "sd-cli"} \
          --set THUNK_SD_SERVER ${lib.getExe' sd "sd-server"} \
          --set THUNK_LLAMA_SERVER ${lib.getExe' pkgs.llama-cpp "llama-server"} \
          --set THUNK_PYTHON ${python}/bin/python3 \
          --set THUNK_SERVE ${serve}/serve.py \
          --set THUNK_ESRGAN ${lib.getExe pkgs.realesrgan-ncnn-vulkan} \
          --suffix PATH : ${tools}
      '';
}
