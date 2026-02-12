# Jujutsu (jj) Notes

## Official Documentation

- [Jujutsu Docs](https://jj-vcs.github.io/jj/latest/)
- [Git Compatibility](https://jj-vcs.github.io/jj/latest/git-compatibility/)
- [Working Copy](https://jj-vcs.github.io/jj/latest/working-copy/)
- [FAQ](https://jj-vcs.github.io/jj/latest/FAQ/)
- [NixOS + JJ Guide](https://saylesss88.github.io/vcs/jujutsu.html)

## Mental Model

**Key difference from Git:**
- Your working copy (@) IS a commit, not "dirty" state
- Changes automatically tracked and amend @ commit
- No staging area - `jj n` finalizes current work and creates new empty commit
- Bookmarks don't auto-move - you move them explicitly

## Daily Workflow

```bash
# Make changes to config files
vim configuration.nix

# Check what changed
jj s
jj d

# Describe and finalize
jj dm "add wireguard configuration"
jjn          # Creates new commit + moves bookmark (shell alias)

# Test
nrt-rig

# If broken, fix and squash
jj sq

# Push to both remotes (GitHub + Codeberg)
jj p
```

## Core Commands

### Viewing
```bash
jj s          # Status
jj l          # Recent commits
jj ll         # Detailed log
jj d          # Diff working copy
jj dp         # Diff against parent (@-)
jj ds         # Diff stats
```

### Change Management
```bash
jj dm "msg"   # Describe current commit
jj n          # Create new empty commit (finalizes current)
jjn           # jj n + move bookmark (shell alias - use this)
```

### Manipulation
```bash
jj sq         # Squash into parent
jj sp         # Split commit interactively
jj spi        # Split with interface
```

### Bookmarks
```bash
jj bs <name> -r <rev>   # Set bookmark to revision
jj tug                  # Move closest bookmark to @-
```

Bookmarks don't auto-advance. After `jj n`, run `jj tug` or use `jjn` shell alias.

### Remotes
```bash
jj f          # Fetch from all remotes
jj p          # Push (to both GitHub + Codeberg via origin)
```

Origin remote pushes to both GitHub and Codeberg automatically (multiple push URLs configured).

### Recovery
```bash
jj u          # Undo last operation
```

Everything is recoverable via operation log. `jj u` works for rebases, squashes, deletions, etc.

## Key Aliases

Configured in `modules/hjem/jujutsu.nix`:

**Daily use:**
- `s` — status
- `d` — diff
- `dm "msg"` — describe
- `n` — new commit
- `sq` — squash
- `p` — push
- `f` — fetch
- `u` — undo

**Shell aliases** (in `modules/nixos-modules/nix-daemon.nix`):
- `jjn` — `jj new && jj bookmark move` (recommended workflow)

## Differences from Git

| Git | jj | Notes |
|-----|-----|-------|
| `git status` | `jj s` | |
| `git diff` | `jj d` | |
| `git commit -m` | `jj dm "msg"` then `jjn` | Describe then finalize |
| `git push` | `jj p` | |
| `git fetch` | `jj f` | No auto-merge |
| `git undo` | `jj u` | Undo last operation |
| `git branch` | `jj bs` | Set bookmark |

## NixOS Flakes Integration

**Colocate mode** exposes `.git/` so NixOS flakes can track files. Files are automatically tracked by jj and exported to git on every command - no manual `jj file track` needed.

If flakes can't see new files, ensure:
1. Files aren't in `.gitignore`
2. You've run `jjn` to move bookmarks (keeps git in sync)

## Configuration

Edit `modules/hjem/jujutsu.nix` and rebuild:
```bash
vim modules/hjem/jujutsu.nix
nrt-rig
```
