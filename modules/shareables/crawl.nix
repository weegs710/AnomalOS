{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.crawlTilesBGM = pkgs.crawlTiles.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./patches/crawl-bgm ];
      });
    };
}
