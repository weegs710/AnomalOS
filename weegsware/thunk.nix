{ pkgs, lib, ... }:
let
  # rocmSupport is a nixpkgs-wide switch, so the ROCm build comes from its own instance and the rest of the system stays on the plain one
  rocm = import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config = {
      allowUnfree = true;
      rocmSupport = true;
    };
  };

  # gfx1032 has no kernels in nixpkgs' ROCm builds, so the targets are the gfx1030 family it runs on via HSA_OVERRIDE_GFX_VERSION
  sd = rocm.stable-diffusion-cpp.override {
    rocmSupport = true;
    rocmGpuTargets = [ "gfx1030" ];
  };

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
      rewriter = {
        group = "rewriter";
        file = "Qwen3.5-35B-A3B-Q4_K_M.gguf";
        url = "https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF/resolve/bc014a17be43adabd7066b7a86075ff935c6a4e2/Qwen3.5-35B-A3B-Q4_K_M.gguf";
        hash = "sha256-O0bRBmvJHMLWE+O8Is5pHdd+bw0zyQYGkNJM5t5JQ3U=";
      };
      rewriter_vision = {
        group = "rewriter";
        file = "Qwen3.5-35B-A3B-mmproj-F16.gguf";
        url = "https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF/resolve/bc014a17be43adabd7066b7a86075ff935c6a4e2/mmproj-F16.gguf";
        hash = "sha256-pRarkugkDaRzTWg1K9+6hMFugw7kABC4+sgNacdycv8=";
      };
    }
  );

  unwrapped = pkgs.writers.writeNuBin "thunk" (builtins.readFile ./thunk.nu);

  tools = lib.makeBinPath [
    pkgs.imagemagick
    pkgs.potrace
    pkgs.vtracer
  ];
in
{
  thunk =
    pkgs.runCommand "thunk"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta = {
          description = "Local Z-Image Turbo generation on the AMD GPU, with a refinement web page and a local CPU prompt rewriter";
          mainProgram = "thunk";
        };
      }
      ''
        makeWrapper ${unwrapped}/bin/thunk $out/bin/thunk \
          --set THUNK_MANIFEST ${manifest} \
          --set THUNK_SD ${lib.getExe' sd "sd-cli"} \
          --set THUNK_SD_SERVER ${lib.getExe' sd "sd-server"} \
          --set THUNK_LLAMA_SERVER ${lib.getExe' pkgs.llama-cpp "llama-server"} \
          --set THUNK_UI ${./thunk-ui.html} \
          --set THUNK_ESRGAN ${lib.getExe pkgs.realesrgan-ncnn-vulkan} \
          --suffix PATH : ${tools}
      '';
}
