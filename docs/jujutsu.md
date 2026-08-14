# Jujutsu Workflow

This repo is version-controlled with [Jujutsu](https://jj-vcs.github.io/jj/latest/) in colocated mode, so `.git/` is exposed and the Codeberg and Tangled remotes work normally. Every jj command exports to git as it goes.

Config is `modules/hjem/vcs/jj-config.toml`; the nushell wrappers are in `modules/hjem/nushell/config.nu`.

## No Need to Snapshot Before a Build

Nix reads the working copy directly here, so `nix eval`, `nix repl` and `nrt` all see whatever is on disk. Snapshot when you want a version-control checkpoint, not to make the evaluator agree with the filesystem.

The exception is the `.#` CLI. `nix build .#`, `nix flake show` and friends resolve as `git+file://`, so those DO go through the snapshot.

## Mental Model

- the working copy (`@`) is a commit, not "dirty" state
- changes are tracked automatically and amend `@`
- there is no staging area -- `jj n` finalizes what you have and starts a new empty commit
- bookmarks do not move on their own

## Daily Loop

```bash
zeditor modules/hjem/something.nix

jj s                              # what changed
jj d                              # the diff

jj dm "add wireguard configuration"
jj n                              # finalize, start a new empty commit

nrt                               # test it

jj sq                             # broke it? fix and squash back down

jj-push                           # fetch + push + fetch
```

## Aliases

| Alias      | Expands to                                          |
| ---------- | --------------------------------------------------- |
| `s`        | `status`                                            |
| `l`        | `log -r recent()`                                   |
| `ll`       | `log -T builtin_log_detailed`                       |
| `d`        | `diff`                                              |
| `dp`       | `diff @-`                                           |
| `ds`       | `diff --stat`                                       |
| `n`        | `new`                                               |
| `dm "msg"` | `describe -m`                                       |
| `sq`       | `squash`                                            |
| `sp`       | `split`                                             |
| `spi`      | `split --interactive`                               |
| `bs`       | `bookmark set`                                      |
| `tug`      | `bookmark move --from closest_bookmark(@-) --to @-` |
| `f`        | `git fetch`                                         |
| `p`        | `git push`                                          |
| `u`        | `undo`                                              |

`f` and `p` hit the default remote only. Use the wrappers below for every remote.

## Nushell Wrappers

| Def         | What it does                                          |
| ----------- | ----------------------------------------------------- |
| `jj-fetch`  | `jj git fetch --all-remotes`                          |
| `jj-push`   | fetch all remotes, push, fetch again                  |
| `jj-pull`   | fetch all remotes, then move `main` to `main@origin`  |
| `jj-commit` | `jj spi`, then move the closest bookmark to `@-`      |
| `tngl-push` | the same push cycle against the `tangled` remote only |
| `tngl-pull` | fetch `tangled`, then move `main` to `main@tangled`   |

`jj-commit` refuses to run on a clean working copy rather than opening an empty split.

## Coming From Git

| git             | jj                        | note                    |
| --------------- | ------------------------- | ----------------------- |
| `git status`    | `jj s`                    |                         |
| `git diff`      | `jj d`                    |                         |
| `git commit -m` | `jj dm "msg"` then `jj n` | describe, then finalize |
| `git push`      | `jj p`                    | default remote only     |
| `git fetch`     | `jj f`                    | no auto-merge           |
| `git branch`    | `jj bs`                   | sets a bookmark         |

## Recovery

`jj u` undoes the last operation, and the operation log covers rebases, squashes, deletions and bookmark moves alike.

```bash
jj op log        # everything that has happened
jj u             # undo the most recent one
```
