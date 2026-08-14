# Vendored sprinkles engine (poacher fork), flattened from two files and reformatted.
# See: https://codeberg.org/poacher/sprinkles
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Contributors to the sprinkles project
let
  inherit (builtins)
    intersectAttrs
    functionArgs
    attrNames
    length
    concatStringsSep
    filter
    elem
    mapAttrs
    ;
  subtractLists = xs: ys: filter (x: !(elem x ys)) xs;
  mergeAttrsSubset =
    x: y: msg:
    let
      inYNotX = subtractLists (attrNames y) (attrNames x);
    in
    if length inYNotX == 0 then
      x // y
    else
      abort (concatStringsSep "" [
        msg
        "\nnames: "
        (concatStringsSep ", " (map (n: "`${n}`") inYNotX))
      ]);
in
{
  new =
    {
      sources,
      inputs,
      outputs,
      overrides,
    }:
    let
      argsOf = fn: attrs: intersectAttrs (functionArgs fn) attrs;
      callFunction = fn: attrs: fn (argsOf fn attrs);
      errorMessage =
        attr:
        "attributes that are not present in the original `${attr}` attribute set are present in the overriden `${attr}` attribute set\nhelp: consider removing them from the override";
      overrides' = {
        sources = { };
        inputs = _: { };
      } // overrides;
      sources' = mapAttrs (
        name: value:
        if value == null then
          throw "The source `${name}` is missing. Define it in the arguments passed to this sprinkle."
        else
          value
      ) (mergeAttrsSubset sources overrides'.sources (errorMessage "sources"));
      inputs' =
        let
          args = sprinkle // sources';
        in
        mergeAttrsSubset (callFunction inputs args) (callFunction overrides'.inputs args) (errorMessage "inputs");
      outputs' = callFunction outputs (sprinkle // inputs');
      sprinkle = {
        sources = sources';
        inputs = inputs';
        outputs = outputs';
      };
    in
    outputs';
}
