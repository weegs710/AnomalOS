# Architecture

How the repo evaluates, where a module goes, and what gates it. The reasoning behind this shape is in [Why not a flake](./why.md).

## Entry Point

`assemble.nix` is the only entry point. It hands a `sources` / `inputs` / `outputs` set to the vendored sprinkles engine in `lib/sprinkles.nix` and gets back:

| Output                       | What it is                                            |
| ---------------------------- | ----------------------------------------------------- |
| `nixosConfigurations`        | one per host directory under `modules/hosts/`         |
| `packages.<system>`          | every `weegsware/` package                            |
| `devShells.<system>.default` | `devshell.nix`                                        |
| `checks.<system>`            | `system.build.toplevel` for every host on that system |
| `apps.<system>`              | any `weegsware` package carrying `meta.mainProgram`   |

`flake.nix` is a three-line shim that declares no inputs. It exists so `nix build .#` resolves.

Two lists keep the per-system outputs honest:

- `systems` is what the repo publishes for -- `packages`, `devShells`, `apps`. It is `[ "x86_64-linux" ]`.
- `hostSystems` is computed from the hosts themselves, and `checks` fans out over it. An `aarch64-linux` host gets checked without anyone remembering to widen `systems`.

`nix-build ci.nix` flattens `checks` to `<system>-<host>` and builds all of it.

## Hosts Are Directories

`modules/hosts/` is read with `builtins.readDir`. Every directory that does not start with `_` is a host, and the directory name is the host name.

```
modules/hosts/HX99G/
├── metadata.nix    system, hostId, tags -- required, never imported as a module
├── host.nix        user, NH_FILE, stateVersion
├── hardware.nix    kernel, filesystems, GPU
└── zfs.nix         sanoid dataset assignments
```

Every `.nix` beside `metadata.nix` is imported. Files starting with `_` are skipped.

`metadata.nix` declares three things:

```nix
{
  system = "x86_64-linux";
  # ZFS reads this from /etc/hostid to refuse importing a pool owned by another machine, so it must differ per host
  hostId = "fff29759";
  tags = [ "desktop" "dev" "gaming" "lab" "server" ];
}
```

Three more are derived from the directory name, so identity has one source of truth:

```nix
mySystem.hostName = name;
networking.hostId = hostId;
environment.variables.NH_ATTRP = "nixosConfigurations.${name}";
```

`nh` under pure tack reads `NH_FILE` and `NH_ATTRP`, not `NH_FLAKE`.

### Adding a Host

Make the directory, write `metadata.nix`, drop in a hardware config. Generate a `hostId` with:

```bash
head -c4 /dev/urandom | od -A none -t x4
```

Then run `./install.sh` from the live image, see [Installing](./install.md). A new host also needs an agenix rekey before its secrets decrypt, see [Secrets](./secrets.md).

### Guards

Every requirement throws at evaluation:

| Condition                               | Result                             |
| --------------------------------------- | ---------------------------------- |
| no `metadata.nix`                       | throws, naming the directory       |
| no `system`                             | throws                             |
| no `tags`                               | throws, use `[ ]` for none         |
| `tags` is not a list                    | throws                             |
| unknown tag                             | throws, listing the valid tags     |
| `hostId` missing or not 8 lowercase hex | throws, with the generator command |
| no modules beside `metadata.nix`        | throws                             |
| two hosts sharing a `hostId`            | throws in `checks`                 |

The collision check lives in `checks` rather than in discovery, so one malformed host directory cannot block every other host's build.

## Module Discovery

Everything under `modules/hjem/` and `modules/nixos-modules/` is auto-discovered by a `bundle.nix` per subtree. Drop a `.nix` file into a domain and it is in. `weegsware/` works the same way -- each file returns `{ name = drv; }` and gets built and exposed as a package.

System modules (`modules/nixos-modules/`) are NixOS-level: services, packages, kernel, networking.

```nix
{ config, lib, pkgs, ... }:
{
  # your config here
}
```

User modules (`modules/hjem/`) are anything that lands in `~/.config` or `~/.local/share`, via [hjem](https://github.com/feel-co/hjem).

```nix
{ config, lib, pkgs, ... }:
let username = config.mySystem.user.name; in
{
  config = {
    hjem.users.${username} = {
      # ...
    };
  };
}
```

## Turning a Module Off

### `_` Prefix

Rename the file `_foo.nix` and it is skipped for the whole repo, in every bundle, on every host. The filename is host-blind, so it cannot mean "on here, off there".

### `only`

`only` arrives as a module argument through `specialArgs`, already bound to the host being built. It keys on a static descriptor `{ name, tags, system }` and never reads evaluated `config`, which keeps it out of module-system recursion.

`only.gate` wraps config in `lib.mkIf`:

```nix
{ config, pkgs, only, ... }:
only.gate { tags = [ "desktop" ]; }
{
  users.users.${config.mySystem.user.name}.packages = with pkgs; [ inkscape gimp3-with-plugins ];
}
```

`only.imports` gates an import list, which `mkIf` cannot do because `imports` is resolved before `config` is:

```nix
{ inputs, ... }:
{ only, ... }:
{
  imports = only.imports { tags = [ "gaming" ]; } (
    toList (fileFilter (f: f.hasExt "nix" && f.name != "bundle.nix" && !(hasPrefix "_" f.name)) ./.)
  );
}
```

That is `modules/hjem/gaming/bundle.nix`, gating the whole subtree in one line. `modules/nixos-modules/media-server/bundle.nix` does the same on the `server` tag. Their parent bundles use `lib.fileset.difference` to subtract the subtree, so a file is never claimed by two bundles.

`only` picks which host. `lib.mkIf` still picks which state. Don't reach for `only` when you mean `mkIf`.

### The Spec

`hosts`, `tags` and `systems` include. They are OR'd within and across each other, and leaving all three off means it applies everywhere.

```nix
only.gate { hosts = [ "HX99G" ]; }              { ... }
only.gate { tags = [ "server" ]; }              { ... }
only.gate { systems = [ "aarch64-linux" ]; }    { ... }
```

`when` is an extra predicate over the descriptor, AND'd on top. `except` subtracts and wins over the includes -- a bare list is shorthand for host-name-or-tag, an attrset `{ hosts; tags; systems; }` is precise.

```nix
only.gate { tags = [ "desktop" ]; except = [ "RPI" ]; } { ... }
```

Or hand it a predicate instead of an attrset:

```nix
only.gate (h: h.name == "HX99G") { ... }
```

### Tags

`validTags` is declared in `assemble.nix`:

```
desktop   dev   gaming   lab   server
```

A tag that is not on that list, in a host's `metadata.nix`, or in an `only` spec throws an error rather than silently matching nothing:

```
only: unknown tag(s) gamin; valid tags are desktop, dev, gaming, lab, server
```

Adding a tag is one line in `assemble.nix`.

### What Is Gated

| Module                        | Gate                         |
| ----------------------------- | ---------------------------- |
| `nixos-modules/desktop.nix`   | `desktop`                    |
| `nixos-modules/dev.nix`       | `dev`                        |
| `nixos-modules/gaming.nix`    | `gaming`                     |
| `nixos-modules/searx.nix`     | `server`                     |
| `nixos-modules/k8s.nix`       | `lab`                        |
| `nixos-modules/k8s-HA.nix`    | `lab`                        |
| `hjem/decky.nix`              | `gaming`                     |
| `hjem/gaming/`                | `gaming`, via `only.imports` |
| `nixos-modules/media-server/` | `server`, via `only.imports` |

Tailscale, SSH, the firewall, persistence and the shell are ungated. They are true of every machine.

## Options

`modules/nixos-modules/options.nix` is the whole `mySystem` surface for host identity:

```
mySystem.user.name          default "anomalos"
mySystem.user.description   default "AnomalOS User"
mySystem.user.extraGroups   default [ "networkmanager" "wheel" ]
mySystem.hostName           default "anomalos", overridden by the derived identity
mySystem.timeZone           default "America/New_York"
```

The only other `mySystem` tree is `mySystem.k8sLab` in `modules/nixos-modules/k8s.nix`.

## weegsware

`weegsware/` holds my wrapped packages: helium, nushell and steam. `assemble.nix` builds them, threads them into the config through the `weegsware` specialArg, and exposes them as `packages.x86_64-linux.<name>`.

That second half is the point -- they aren't trapped in my system config. Anyone can add this repo as a flake input and `nix run` my version of a package, and `.override` re-tunes them from outside without editing the file.

Some are nixpkgs overrides (steam, nushell) and some build from upstream source (helium). The from-source ones have their version and hash managed by [nvfetcher](https://github.com/berberman/nvfetcher): config in `nvfetcher.toml`, output in `_sources/generated.nix`, and running `nvfetcher` in the repo bumps them all at once.

## Where a New Thing Goes

A service, kernel option or system-wide program goes in `modules/nixos-modules/`. Anything in `~/.config`, or a user package, goes in `modules/hjem/`, colocated with the module that uses it. A package I wrap, override or build from source goes in `weegsware/`. A per-host fact goes in `modules/hosts/<HOST>/`. Reusable operational tooling goes in `lib/scripts/`.

## Layout

```
assemble.nix          the entry point
flake.nix             three-line shim so .# resolves
ci.nix                nix-build ci.nix -- builds every host
devshell.nix          nix-shell devshell.nix
install.sh            the installer
.tack/                pins.toml, pins.lock.json
lib/sprinkles.nix     vendored flake-output engine
lib/only.nix          the per-host gate
lib/requirements.nix  extracts a host's storage contract for the installer
lib/vmtest/           the VM harness, see docs/testing.md
lib/scripts/          reusable tooling, including draw.nu which renders the diagrams
modules/hosts/        one directory per machine
modules/nixos-modules/  system modules
modules/hjem/         user modules
weegsware/            wrapped packages, exposed as outputs
secrets/              agenix .age files and secrets.nix
assets/               the SVGs in the README
```
