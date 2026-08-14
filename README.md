# anomalOS

My NixOS configuration. It is not a flake: tack does the pinning, a vendored sprinkles engine gives the repo flake-shaped outputs, and hosts are read off the disk.

> **Important**: This is a hobbyist project and I'm learning as I go. If something is broken or stupid, that's why. It's built for my machine and my workflow, so it might work on yours and it might not. It's all FOSS, so take the whole thing or steal bits of it.

> **Requirements**: Nushell. The wrappers and utilities in this repo are written in it and will not work without it. It ships inside the config, but if you're cherry-picking modules, install it first.

![anomalOS Overview](assets/anomalOS-overview.svg)

![anomalOS Diagram](assets/anomalOS-diagram.svg)

## Docs

- [Why not a flake](./docs/why.md) -- what tack, sprinkles and `only` do that the flake schema doesn't
- [Architecture](./docs/architecture.md) -- how it evaluates, where a module goes, what gates it
- [Installing](./docs/install.md) -- `install.sh`, start to finish
- [Testing](./docs/testing.md) -- `ci.nix` and the VM harness
- [Features](./docs/features.md) -- what's actually configured
- [ZFS and snapshots](./docs/zfs.md) -- layout, sanoid, recovery
- [Secrets](./docs/secrets.md) -- agenix
- [Jujutsu](./docs/jujutsu.md) -- the version control workflow
- [Maintenance](./docs/maintenance.md) -- day to day, and what to do when it breaks

## Keeping fresh and tidy

```console
$ nrt        # build and activate, reverts on reboot
$ nrs        # build, activate, and make it the boot default
$ tu         # refresh every pinned input
$ tl         # list pins with newer upstream available
$ recycle    # keep the last 10 generations, garbage-collect the rest
```

Nix reads the working copy directly, so edits are visible to the next build as soon as they're saved. There is no `jj s` or `git add` required.

## Install

Boot a NixOS live image, then:

```bash
git clone https://codeberg.org/weegs710/AnomalOS.git ~/anomalos
cd ~/anomalos

./install.sh --save-plan /tmp/plan   # ask, check, write the plan, stop
./install.sh --plan /tmp/plan        # apply it
```

`install.sh` builds a plan and checks it against what the host's configuration declares before it writes to a disk. See [Installing](./docs/install.md).

## Contributing

Fork it and do whatever. Bug reports and improvements are welcome -- run `nix-shell devshell.nix` first so we're on the same formatter.

`nix-build ci.nix` builds every host and returns nonzero on the first failure.

## Credits

| Who                                         | For                                                        |
| ------------------------------------------- | ---------------------------------------------------------- |
| [iynaix](https://github.com/iynaix)         | code examples, good practices, and logical thinking        |
| [jet](https://github.com/Michael-C-Buckley) | NixOS nuance, code snippets, and highlighting new projects |
| [ladas](https://github.com/Ladas552)        | nagging me about stuff I can improve                       |
| [vimjoyer](https://github.com/vimjoyer)     | his videos and snippets                                    |

## License

MIT, please see [LICENSE](LICENSE).

Three bundled things aren't mine and carry their own terms: the vendored sprinkles engine, the ghostty cursor shader, and the phinger cursor art. The carve-out is in [LICENSE](LICENSE) and the full texts are in [LICENSES/](LICENSES/).

## Links

- Codeberg: https://codeberg.org/weegs710/AnomalOS
- Website: https://weegs.dev
