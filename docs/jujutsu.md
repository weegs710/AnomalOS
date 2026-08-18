# Jujutsu Workflow

This repo is version-controlled with [Jujutsu](https://jj-vcs.github.io/jj/latest/) in colocated mode, so `.git/` is exposed and the Codeberg and Tangled remotes work normally. Every jj command exports to git as it goes.

Config is `modules/user-level/vcs/jj-config.toml`; the nushell wrappers are in `modules/user-level/nushell/config.nu`.

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
zeditor modules/user-level/something.nix

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

| Def         | What it does                                                            |
| ----------- | ----------------------------------------------------------------------- |
| `jj-fetch`  | `jj git fetch --all-remotes`                                            |
| `jj-push`   | push to every remote the repo has, then verify all of them are in sync  |
| `jj-pull`   | fetch all remotes, then move `main` to `main@codeberg`                  |
| `jj-commit` | `jj spi`, then move the closest bookmark to `@-`                        |

`jj-commit` refuses to run on a clean working copy rather than opening an empty split.

`jj-push` enumerates remotes rather than naming forges, so a repo's remote set decides where it can
go: public repos carry `codeberg`, `github` and `tangled`, private ones only `codeberg` and `github`.
Tangled has no private-repo support, so a private repo simply has no remote that reaches it.

It does not trust exit codes. `jj git push` exits 0 both when it declines to push a conflicted
bookmark and when it refuses to create an untracked remote bookmark, so `jj-push` compares every
bookmark against every remote afterwards and fails if any disagree.

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
