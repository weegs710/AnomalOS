# Vendored nixpkgs-multiverse engine.
# See: https://github.com/fzakaria/nixpkgs-multiverse
{
  revisionsFile,
  indexFile,
  system ? builtins.currentSystem,
  config ? { allowUnfree = true; },
  overlays ? [ ],
  pinned ? null,
}:
let
  revisions = builtins.fromJSON (builtins.readFile revisionsFile);
  index = builtins.fromJSON (builtins.readFile indexFile);

  nRevs = builtins.length revisions;
  offsets = builtins.genList (i: i) nRevs;
  revAt = i: builtins.elemAt revisions i;

  # The index stores bare offsets, so it is only meaningful against the revision array it was generated from.
  checkedIndex =
    if (index.revisionCount or null) != nRevs then
      throw "shop: index was built against ${toString (index.revisionCount or 0)} revisions but revisions.json holds ${toString nRevs}"
    else
      index;

  attrIndex = checkedIndex.attrs;

  labelOf =
    i:
    let
      r = revAt i;
    in
    r.release or "${r.date}-${builtins.substring 0 12 r.rev}";

  releaseOffsets = builtins.listToAttrs (
    builtins.concatMap (
      i:
      let
        r = revAt i;
      in
      if r ? release then
        [
          {
            name = r.release;
            value = i;
          }
        ]
      else
        [ ]
    ) offsets
  );

  offsetOnOrBefore =
    date: builtins.foldl' (acc: i: if (revAt i).date <= date then i else acc) null offsets;

  offsetOfRev =
    sha:
    builtins.foldl' (
      acc: i:
      if acc != null then
        acc
      else if builtins.substring 0 (builtins.stringLength sha) (revAt i).rev == sha then
        i
      else
        acc
    ) null offsets;

  resolve =
    sel:
    if releaseOffsets ? ${sel} then
      releaseOffsets.${sel}
    else if builtins.match "[0-9]{4}-[0-9]{2}-[0-9]{2}" sel != null then
      let
        i = offsetOnOrBefore sel;
      in
      if i == null then throw "shop: no revision on or before ${sel}" else i
    else
      let
        i = offsetOfRev sel;
      in
      if i == null then
        throw "shop: '${sel}' is not a release name, a YYYY-MM-DD date, or a known commit"
      else
        i;

  pathFor =
    i:
    let
      r = revAt i;
    in
    builtins.fetchTree {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      inherit (r) rev narHash;
    };

  # listToAttrs is lazy in its values, so building this costs one thunk per revision and fetches nothing.
  instances = builtins.listToAttrs (
    map (i: {
      name = toString i;
      value = import (pathFor i) { inherit system config overlays; };
    }) offsets
  );

  versionsFor = attr: attrIndex.${attr} or { };

  # builtins.attrNames sorts lexicographically, which orders 3.12.10 before 3.12.7.
  sortVersions = builtins.sort (a: b: builtins.compareVersions a b < 0);

  tipOffset = nRevs - 1;

  # The nix-index db's tree is normally newer than anything the index holds, so the tip is the nearest revision at or before it.
  pinnedOffset =
    if pinned == null then
      tipOffset
    else
      let
        i = offsetOfRev pinned;
      in
      if i == null then tipOffset else i;
in
rec {
  inherit revisions;

  revs = map labelOf offsets;
  releases = builtins.attrNames releaseOffsets;

  at = sel: instances.${toString (resolve sel)};
  tip = instances.${toString tipOffset};

  pkgs = instances.${toString pinnedOffset};
  pinnedLabel = labelOf pinnedOffset;
  pinnedExact = pinned != null && offsetOfRev pinned != null;

  versionsOf = attr: sortVersions (builtins.attrNames (versionsFor attr));

  versionTable =
    attr:
    map (v: {
      version = v;
      revision = revOf attr v;
    }) (versionsOf attr);

  revOf =
    attr: ver:
    let
      i = (versionsFor attr).${ver} or null;
    in
    if i == null then null else labelOf i;

  version =
    attr: ver:
    let
      i = (versionsFor attr).${ver} or null;
      known = versionsOf attr;
    in
    if i == null then
      throw ''
        shop: no revision provides ${attr} ${ver}
        known versions: ${
          if known == [ ] then
            "(none -- this attribute has no version axis)"
          else
            builtins.concatStringsSep " " known
        }
      ''
    else
      instances.${toString i}.${attr};

  # mapAttrs is lazy in its values, so forcing one version instantiates exactly one revision.
  versions = builtins.mapAttrs (
    attr: vers: builtins.mapAttrs (ver: _: version attr ver) vers
  ) attrIndex;

  latest = builtins.mapAttrs (
    attr: vers:
    let
      sorted = sortVersions (builtins.attrNames vers);
    in
    version attr (builtins.elemAt sorted (builtins.length sorted - 1))
  ) attrIndex;
}
