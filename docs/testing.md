# Testing

Two layers. `ci.nix` proves every host still evaluates and builds. `lib/vmtest/` proves `install.sh` can take a bare disk and turn it into a machine that boots.

## Evaluation and Build

```bash
nix-build ci.nix
```

`ci.nix` flattens `checks` to `<system>-<host>` and builds `system.build.toplevel` for all of it, returning nonzero on the first failure. Keying on the current machine's system instead would silently skip a host built for an architecture this machine is not.

Every guard in [Architecture](./architecture.md#guards) fires at evaluation, so a malformed `metadata.nix`, an unknown tag or a duplicate `hostId` fails here rather than at install time.

## The VM Harness

`lib/vmtest/` boots a scenario in a throwaway QEMU VM so the destructive half of `install.sh` runs against real disks nobody cares about.

```bash
lib/vmtest/vmtest.sh lib/vmtest/scenarios/smoke
lib/vmtest/vmtest.sh lib/vmtest/scenarios/install-hx99g --timeout 1800
lib/vmtest/vmtest.sh lib/vmtest/scenarios/end-to-end --timeout 5400
lib/vmtest/vmtest.sh lib/vmtest/scenarios/end-to-end --reboot
```

| Flag                | What it does                                                   |
| ------------------- | -------------------------------------------------------------- |
| `--timeout SECONDS` | give up if the VM has not printed `HARNESS: DONE`. Default 600 |
| `--interactive`     | hand the console over instead of capturing it                  |
| `--reboot`          | boot the previous run's disks with no installer media attached |
| `--cache DIR`       | mount a directory as a read-only extra store                   |

Everything the VM prints goes to stdout and to `console.log` in the run directory.

## Where It Puts Things

`$WORK`, default `~/.cache/anomalos-vmtest`. Do not point this at a tmpfs -- a real install is far larger than RAM and the qcow2 images will eat all of it.

`$REPO` defaults to the repo the script lives in, and `$ISO` to `$WORK/iso/iso`.

## How It Works

`iso.nix` builds a minimal NixOS installer image with `9p` in the initrd, `jq` and `git` on the path, and a `harness` systemd unit that mounts the 9p share at `/harness` and runs `/harness/run.sh` as root, printing `HARNESS: EXIT <rc>` and `HARNESS: DONE` when it finishes. Console output is forced onto `ttyS0` because the VM is headless.

The repository is mounted read-only at a second 9p share, so adding a scenario costs no ISO rebuild. A scenario is two files:

```
scenarios/<name>/disks     one "NAME SIZE" pair per line, e.g. "vda 40G"
scenarios/<name>/run.sh    executable, runs as root inside the VM
```

Each `run.sh` copies the repo out of the read-only share, drops `.git` / `.jj` / `.direnv`, and asserts with a `chk` helper that prints `OK` or `FAIL` per check and accumulates an exit code.

The driver creates fresh qcow2 images on every run, so a scenario cannot inherit the previous run's disk state. `--reboot` is the exception, which is the point of that flag.

## Scenarios

| Scenario            | What it proves                                                                                                     |
| ------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `smoke`             | the harness itself works, before `install.sh` is asked to trust it                                                 |
| `install-hx99g`     | the destructive half of `install.sh` against throwaway virtio disks                                                |
| `hardware-branches` | every branch of `handle_hardware_config`, re-wiping the disks between cases                                        |
| `broken-hardware`   | an existing `hardware.nix` with no `/boot`, kept rather than regenerated, so the bootability check has to catch it |
| `persist-restore`   | a canary file and a fake host key survive a full wipe and reinstall, while `/nix` comes back fresh                 |
| `end-to-end`        | a real install, left bootable, so `--reboot` can prove the machine comes up                                        |

`end-to-end` wants 70G on `vda`, which holds the boot partition, swap and the whole system closure at the time of writing.

## The End-to-End Run

```bash
lib/vmtest/vmtest.sh lib/vmtest/scenarios/end-to-end --timeout 5400
lib/vmtest/vmtest.sh lib/vmtest/scenarios/end-to-end --reboot
```

The second command attaches no ISO. If a login prompt appears, the disks the installer wrote are a bootable machine.

The first one takes a long time. The VM has no substituter it can reach for a system closure nobody has built before, so it compiles. `--cache` is what makes later runs cheap, and it wants a build closure, not a runtime one -- staging `/run/current-system` there does nothing for it.
