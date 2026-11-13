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
├── host.nix        user, display, games path, NH_FILE, stateVersion
├── hardware.nix    kernel, filesystems, GPU
├── net.nix         static NIC profile, suricata interface, AdGuard bind addresses
├── input.nix       keyd trackball remap
├── desktop.nix     deploys the per-host umbriel and noctalia config
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

### Variants

`metadata.nix` may also declare `variants`, the same machine built with extra tags:

```nix
variants.vm = { tags = [ "lab" ]; };
```

That adds `nixosConfigurations.HX99G-vm`. It keeps the parent's name, so `hostName`, `hostId` and any `hosts = [ "HX99G" ]` spec still match, and only `NH_ATTRP` points at the variant. The extra tags decide what gets imported, like any host's tags. Variants are built by `checks` and never offered by `install.sh`, which lists directories.

### Adding a Host

Make the directory, write `metadata.nix`, drop in a hardware config. Generate a `hostId` with:

```bash
head -c4 /dev/urandom | od -A none -t x4
```

Then run `./install.sh` from the live image, see [Installing](./install.md). A new host also needs an agenix rekey before its secrets decrypt, see [Secrets](./secrets.md).

What the host has to declare depends on its tags. A `server` host must set `services.suricata.settings.af-packet`, which the nixpkgs module asserts on. A `desktop` or `gaming` host must set `mySystem.display`, and a `gaming` host `mySystem.paths.games` as well, because those options have no default and the modules that read them (mpv, heroic, am2r, es-de) fail evaluation without them. `modules/hosts/HX99G/net.nix` and `host.nix` are the examples.

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
| a variant not shaped `{ tags = [ ]; }`  | throws                             |
| unknown tag in a variant                | throws, listing the valid tags     |
| variant named like a host directory     | throws                             |
| two hosts sharing a `hostId`            | throws in `checks`                 |

The collision check lives in `checks` rather than in discovery, so one malformed host directory cannot block every other host's build.

## Module Discovery

Everything under `modules/user-level/` and `modules/system-level/` is auto-discovered by a `bundle.nix` per subtree. Drop a `.nix` file into a domain and it is in. `weegsware/` works the same way -- each file returns `{ name = drv; }` and gets built and exposed as a package.

System modules (`modules/system-level/`) are NixOS-level: services, packages, kernel, networking.

```nix
{ config, lib, pkgs, ... }:
{
  # your config here
}
```

User modules (`modules/user-level/`) are anything that lands in `~/.config` or `~/.local/share`, via [hjem](https://github.com/feel-co/hjem).

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
    only.files (toList (fileFilter (f: f.hasExt "nix" && f.name != "bundle.nix" && !(hasPrefix "_" f.name)) ./.))
  );
}
```

That is `modules/user-level/gaming/bundle.nix`, gating the whole subtree in one line. `modules/system-level/media-server/bundle.nix` does the same on the `server` tag. Their parent bundles use `lib.fileset.difference` to subtract the subtree, so a file is never claimed by two bundles.

`only.files` does the same for one file. Every bundle passes its file list through it, and a file that opens with an `only` header is dropped on a host it does not match:

```nix
{
  only = { tags = [ "lab" ]; };
  module = { config, lib, ... }: { options = ...; config = ...; };
}
```

Use it when the file declares options. With `only.gate` the options would still exist on every host, and with the header they only exist where the file applies. The top level must be exactly `{ only; module; }`, anything else throws. Files without a header pass through untouched.

`only` picks which host. `lib.mkIf` still picks which state. Don't reach for `only` when you mean `mkIf`.

### The Spec

`hosts`, `tags` and `systems` include. They are OR'd within a key and AND'd across keys, so adding a key narrows the match. Leaving all three off, or empty, means it applies everywhere.

```nix
only.gate { hosts = [ "HX99G" ]; }              { ... }
only.gate { tags = [ "server" ]; }              { ... }
only.gate { systems = [ "aarch64-linux" ]; }    { ... }
```

`when` is an extra predicate over the descriptor, AND'd on top. `except` subtracts and wins over the includes -- a bare list is shorthand for tags only (a name that is not a valid tag throws, so host names are rejected), an attrset `{ hosts; tags; systems; }` is precise and combines its keys the same way the includes do.

```nix
only.gate { tags = [ "desktop" ]; except = { hosts = [ "RPI" ]; }; } { ... }
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
only: unknown tags gamin in the spec; valid tags are desktop, dev, gaming, lab, server
```

The rest of a spec is closed the same way. `hosts` are checked against the directories in `modules/hosts/`, `systems` against nixpkgs' `lib.systems.flakeExposed`, and a key `only` does not know (`tag`, `excpet`) throws instead of being ignored.

Adding a tag is one line in `assemble.nix`.

### What Is Gated

| Module                                                  | Gate                  | Form                    |
| ------------------------------------------------------- | --------------------- | ----------------------- |
| `system-level/desktop.nix`                              | `desktop`             | `only.gate`             |
| `system-level/umbriel-system.nix`                       | `desktop`             | header                  |
| `system-level/scraping.nix`                             | `desktop`             | `only.gate`             |
| `system-level/audio.nix`                                | `desktop` or `gaming` | `only.gate`             |
| `system-level/dev.nix`                                  | `dev`                 | `only.gate`             |
| `system-level/android.nix`                              | `dev`                 | `only.gate`             |
| `system-level/shop.nix`                                 | `dev`                 | header                  |
| `system-level/gaming.nix`                               | `gaming`              | `only.gate`             |
| `system-level/searx.nix`                                | `server`              | `only.gate`             |
| `system-level/security/adguard/adguard.nix`             | `server`              | `only.gate`             |
| `system-level/security/dnscrypt.nix`                    | `server`              | `only.gate`             |
| `system-level/security/suricata.nix`                    | `server`              | `only.gate`             |
| `system-level/k8s.nix`                                  | `lab`                 | header                  |
| `system-level/k8s-HA.nix`                               | `lab`                 | header                  |
| `system-level/win11-vm.nix`                             | `lab`                 | header                  |
| `system-level/media-server/`                            | `server`              | subtree, `only.imports` |
| `user-level/desktop/`, every module in it               | `desktop`             | `only.gate`             |
| `user-level/helium.nix`, `zennotes.nix`, `services.nix` | `desktop`             | `only.gate`             |
| `user-level/comms/`, `peepers/`                         | `desktop`             | `only.gate`             |
| `user-level/rummage/rummage.nix`                        | `desktop`             | header                  |
| `user-level/music/` mpd, rmpc and mpv                   | `desktop`             | `only.gate`             |
| `user-level/servers.nix`, `thunk.nix`, `writing-tools/` | `dev`                 | `only.gate`             |
| `user-level/gaming/`                                    | `gaming`              | subtree, `only.imports` |

Header is the `only.files` form, a file shaped `{ only; module; }`. A subtree is gated once in its `bundle.nix`, so nothing inside it carries a gate of its own.

Boot, core, users, net, options, persistence, secrets, YubiKey, sanoid, the TLS store, sshd, and at user level bash, nushell, vcs, fastfetch and tui-tools are ungated. They are true of every machine. Each still owns its own state: sshd opens its port with `openFirewall`, Tailscale opens its own, and the game LAN ports sit in `gaming.nix` with the module that needs them. Nothing is parked in a shared firewall file.

## Options

`modules/system-level/options.nix` is the `mySystem` surface every host shares, for identity and the few machine facts modules read:

```
mySystem.user.name              default "anomalos"
mySystem.user.description       default "AnomalOS User"
mySystem.user.extraGroups       default [ "networkmanager" "wheel" ]
mySystem.hostName               default "anomalos", overridden by the derived identity
mySystem.timeZone               default "America/New_York"
mySystem.nushell.extraConfig    default "", appended to the nushell config by gated modules
mySystem.display.width          no default, primary monitor width in pixels
mySystem.display.height         no default, primary monitor height in pixels
mySystem.display.refresh        no default, primary monitor refresh rate in Hz
mySystem.paths.games            no default, root of the games library mount
mySystem.audio.monitorSource    default null, the PipeWire monitor source visualizers listen to
mySystem.btopPackage            default pkgs.btop, a GPU host can pick a variant
```

`display` and `paths.games` have no default on purpose. A host that turns on a module reading them has to say what its monitor and games mount are, and `modules/hosts/HX99G/host.nix` does. `nushell.extraConfig` exists because `use` is parse-time in nushell, so a gated module cannot guard its own import at runtime and appends it here instead.

The only other `mySystem` trees are `mySystem.k8sLab` in `modules/system-level/k8s.nix` and `mySystem.win11Vm` in `modules/system-level/win11-vm.nix`.

## weegsware

`weegsware/` holds my wrapped packages: helium, nushell, steam and thunk. `assemble.nix` builds them, threads them into the config as the `weegsware` module argument (built on the host's own `pkgs`, so weegsware and the system share one nixpkgs instance), and exposes them as `packages.x86_64-linux.<name>`.

That second half is the point -- they aren't trapped in my system config. Anyone can add this repo as a flake input and `nix run` my version of a package, and `.override` re-tunes them from outside without editing the file.

Some are nixpkgs overrides (steam, nushell) and some build from upstream source (helium). The from-source ones have their version and hash managed by [nvfetcher](https://github.com/berberman/nvfetcher): config in `nvfetcher.toml`, output in `_sources/generated.nix`, and running `nvfetcher` in the repo bumps them all at once.

## Where a New Thing Goes

A service, kernel option or system-wide program goes in `modules/system-level/`. Anything in `~/.config`, or a user package, goes in `modules/user-level/`, colocated with the module that uses it. A module carries its own user packages and build glue next to the thing it serves, and its state too: persist entries, uid pins, secrets, firewall ports and units live in the module that owns them. `modules/system-level/persist.nix` keeps only the state no module owns. A package I wrap, override or build from source goes in `weegsware/` when it is worth publishing as an output, and stays in its module when only this config uses it. A fact that is true of one machine only goes in `modules/hosts/<HOST>/`, including per-host app config. `modules/hosts/HX99G/desktop.nix` deploys `umbriel/host.toml` and `noctalia/host.toml` from `umbriel-host.toml` and `noctalia-host.toml` there, holding the monitor outputs, lockscreen widgets and per-monitor wallpapers. Reusable operational tooling goes in `lib/scripts/`.

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
modules/system-level/ system modules
modules/user-level/   user modules
weegsware/            wrapped packages, exposed as outputs
secrets/              agenix .age files, agenix-rules.nix, recipients/*.pub
assets/               the SVGs in the README
```
