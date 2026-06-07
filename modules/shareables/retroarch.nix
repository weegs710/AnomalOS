# Wrapped RetroArch with all cores (per-core .opt configs live in hjem/gaming/retroarch.nix)
# Run with: nix run git+https://codeberg.org/weegs710/AnomalOS#retroarch
{
  perSystem =
    { pkgs, ... }:
    {
      packages.retroarch = pkgs.wrapRetroArch {
        cores = with pkgs.libretro; [
          nestopia
          bsnes
          mupen64plus
          gambatte
          mgba
          melonds
          genesis-plus-gx
          picodrive
          beetle-saturn
          flycast
          beetle-psx-hw
          pcsx2
          ppsspp
          stella
          beetle-pce-fast
          atari800
          prosystem
          handy
          virtualjaguar
          hatari
          beetle-vb
          gw
          beetle-ngp
          beetle-wswan
          bluemsx
          vice-x64
          vice-xplus4
          vice-xvic
          puae
          freeintv
          vecx
          o2em
          np2kai
          fuse
        ];
      };
    };
}
