# Why Not a Flake

This repo is pinned by [tack](https://github.com/manic-systems/tack), shaped by a vendored copy of [sprinkles](https://codeberg.org/poacher/sprinkles), and gated by a local module called `only`. A flake will handle the first two, inputs and outputs respectively, but achieve none of the magical quality of life improvements from the third.

Like I said, flakes bundle input pinning, output schema, and evaluation purity into one thing you CANNOT take apart. All three are useful, yet none of them NEED to be the same thing.

## The Working Copy

Under flakes, evaluation reads a copy of the repository in the Nix store, and that copy is built from what git tracks. So, a file you just wrote does not exist yet as far as the build is concerned.

If I drop a file in the root, never add it, and ask both entry points about it:

```console
$ echo '{ probe = 42; }' > _probe.nix

$ nix eval --impure --expr '(import ./_probe.nix).probe'
42

$ ls "$(nix flake metadata --json | jq -r .path)"/_probe.nix
ls: cannot access '/nix/store/7fmlz1plfihj0knprqv23xmkz89nxcid-source/_probe.nix': No such file or directory
```

Even though it is the same repo and the same file, I get two answers. Plain `import` reads the path in front of it. The flake reads `git+file://` and cannot see the untracked file, as if isn't there.

For a config I am editting almost constantly that becomes a `git add` ceremony before every build introducing something new, and a failure where the error names a missing file instead of saying I forgot to snapshot. I am very forgetful, and this got REALLY annoying.

Going pure tack skips this step entirely. `assemble.nix` is a plain Nix file, `import` resolves against the working copy, and the next build sees what I saved. At that point version control goes back to being only version control.

## Pinning, Separately From Output Schema

`flake.lock` is a lockfile that has been welded to an opinionated output schema. tack lets me split them apart.

`.tack/pins.toml` holds the inputs with a `[shorturls]` table and an `[all_follow]` rule; `.tack/pins.lock.json` holds the resolved revisions. There is no follows-graph to hand-write per input, because `all_follow` states it once. Updating inputs becomes `tu`, or `tu nixpkgs` to move just the one pin, `tl` will list which pins have newer upstream without actually changing anything.

The outputs come from sprinkles, which are simply `builtins` located in `lib/sprinkles.nix`. taking a set of `sources` / `inputs` / `outputs` and returning flake-shaped attributes:

```
nixosConfigurations   packages.<system>   devShells.<system>   checks.<system>   apps.<system>
```

So the repo is functionally consumable exactly like a flake would be using -- `nix run .#helium`, or adding it as an input elsewhere to get the wrapped packages -- meanwhile the pinning stays tack's problem. The `flake.nix` on top is three lines that brings `.#` back online when I want it:

```nix
{
  outputs = _: (import ./assemble.nix) { };
}
```

It declares no inputs, which is why there is no `flake.lock` in this repo at all. If you delete it, every build will still work; only `nix build .#` stops.

sprinkles is vendored rather than pinned. I did that because adopting it means it is load-bearing enough that an upstream that move or deletion would take the repo with it, and it is short enough that there is nothing really to gain from tracking it remotely. It is poacher's fork, flattened from two files into one, with an SPDX header on the file and the full text in `LICENSES/` to ensure that credit and attribution is as properly pointed, at least as well as I can.

## What `only` Does That the Schema Cannot

A flake's `nixosConfigurations` is a hand-written attribute set. Every host is a key you type out by hand and every host's module list is a list you maintain. Sharing a bundle across hosts while excluding it from one or more is YOUR problem to solve, module by module.

AnomalOS has no host registry. `modules/hosts/` is read off disk, every directory is a host, and every `.nix` beside `metadata.nix` gets imported. Identity gets derived from the directory name, so `mySystem.hostName`, `NH_ATTRP` and the attribute in `nixosConfigurations` cannot drift apart on accident.

Exclusion is controlled by `only`. It arrives through `specialArgs` already bound to the host it is gating, and answers two different questions:

```nix
only.gate { tags = [ "gaming" ]; } {
  programs.steam.enable = true;
}
```

and

```nix
imports = only.imports { tags = [ "server" ]; } [ ./jellyfin.nix ./transmission.nix ];
```

`only.gate` is just `lib.mkIf` with conditions pre-computed for you. `only.imports` exists because `imports` gets resolved before `config` does, so `mkIf` cannot reach it -- wrapping an import list in `mkIf` is not a REAL gate at all. `only.imports` decides membership of the list itself, before the module system starts, which works because `specialArgs` are available at that point whereas an evaluated config is not.

That is also why `only` keys on a static descriptor -- `{ name, tags, system }`, no `config` -- and why the tag vocabulary is closed. `validTags` lives in `assemble.nix`, so a typo in a host's `tags` or in an `only` spec will throw with the valid list rather than silently matching nothing:

```
only: unknown tag(s) gamin; valid tags are desktop, dev, gaming, lab, server
```

HX99G carries all five tags and evaluated to 363 packages. A second host directory carrying only `desktop` evaluated to 278, with gamescope, steam-hardware, Jellyfin, Navidrome, Radarr, Transmission, SearXNG, all being off -- with no conditionals written inside the modules that provide them.

## The Trade-off of doing it this way

- There is no `nix flake check`. `ci.nix` replaces it: `nix-build ci.nix` builds every host on every system the repo declares and returns non-zero on the first failure, it has been flattened to `<system>-<host>` so a host with different architecture than the one running it never gets silently skipped.
- There is no `flake.lock` in a consumer's dependency graph. Someone adding this repo as a flake input gets the packages and whatever tack pinned, but with no lockfile to override.
- `nix flake show` and friends still go through git. The `.#` shim resolves as `git+file://`, so those commands see the snapshot rather than the working copy. Builds do not.

See [Architecture](./architecture.md) for how discovery, the bundles and `weegsware` fit together.
