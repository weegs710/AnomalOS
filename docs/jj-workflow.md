# Jujutsu Workflow

How to use jj to manage this flake.

## The one thing you must remember

**NixOS flakes only see tracked files.** Run `jj ta` after creating new `.nix` files or your rebuild will ignore them.

## Daily workflow

Most common pattern:

```bash
# Make changes to config files

# Track new files
jj ta

# Check what changed
jj s
jj d

# Describe the work
jj dm "add someapp config"

# Create new empty change
jj n

# Test it
nrt-rig

# If you need to fix something, edit and squash back
jj sq

# Push when done
jj push
```

## File tracking

Critical commands:

```bash
jj ta         # Track all files in current directory
jj t file     # Track specific file
jj ls         # List tracked files
jj ut file    # Untrack file
jj s          # Shows tracked vs untracked
```

Typical scenario:

```bash
# After creating modules/hjem/hyprland-extra.nix

# Track it BEFORE testing
jj ta

# Verify it's tracked
jj s
# Should show: A modules/hjem/hyprland-extra.nix

# Now rebuild will see it
nrt-rig
```

## Common operations

### Viewing

```bash
jj s          # Status
jj l          # Recent commits
jj ll         # Detailed log
jj lg         # Last 20 commits
jj d          # Diff working copy
jj dp         # Diff against parent
jj ds         # Diff with stats
```

### Creating changes

```bash
jj n          # New change
jj ne         # New change, edit parent (like git stash)
jj nt         # New change on trunk (main@origin)
jj nm "msg"   # New change with message

jj e <rev>    # Edit specific revision
jj desc       # Describe (opens editor)
jj dm "msg"   # Describe without editor
```

### Squashing and splitting

```bash
jj sq         # Squash into parent
jj sqi        # Squash interactively
jj sp         # Split interactively
jj ab         # Absorb (auto-squash into right commits)
```

Absorb is smart — it figures out which ancestor commits to squash changes into based on file history.

### Rebasing

```bash
jj r          # Rebase
jj rt         # Rebase onto trunk
jj rba        # Rebase all mutable changes onto trunk
```

## Multi-remote workflow

This repo pushes to GitHub and Codeberg. The origin remote has multiple push URLs, so pushing to origin pushes to both.

```bash
# Fetch from both remotes (run both)
jj fo         # Fetch origin
jj fc         # Fetch codeberg

# Push to both (origin has multiple push URLs)
jj push       # Push main branch (pushes to GitHub + Codeberg)
jj pc         # Push to codeberg only
```

## Bookmarks

Bookmarks in jj don't auto-advance like git branches. Move them explicitly:

```bash
jj bl         # List bookmarks
jj bc <name>  # Create bookmark
jj bs <name> -r <rev>  # Set bookmark to revision
jj bm <name> --to <rev>  # Move bookmark
jj nb <name>  # Create bookmark at parent
jj tug        # Move nearest bookmark to parent
```

After finishing work, move main forward:

```bash
jj bs main -r @
# Or use the tug alias to move the nearest bookmark
jj tug
```

## Recovery

Everything is recoverable. Every operation is logged:

```bash
jj u                    # Undo last operation
jj operation log        # View operation log
jj opl                  # Last 20 operations
jj operation restore <op-id>  # Restore to specific operation
```

Undo works for everything — rebases, squashes, deletions, all of it.

Examples:

```bash
# Accidentally squashed wrong commit
jj u

# Deleted bookmark by mistake
jj u

# Rebase went wrong
jj u
```

## Conflicts

```bash
jj conflicts        # List conflicted changes
jj resolve          # Resolve interactively
```

## Cleanup

```bash
jj ae               # Abandon empty changes
jj hideempty        # Hide empty mutable commits
jj abandon <rev>    # Abandon specific revision
```

## Alias reference

Organized by frequency of use.

**Essential (use daily):**
- `s` — status
- `ta` — track all files in current directory
- `d` — diff
- `dm "msg"` — describe change
- `n` — new empty change
- `sq` — squash into parent
- `push` — push main branch (GitHub + Codeberg)
- `fo` — fetch origin
- `fc` — fetch codeberg

**Common:**
- `l` — recent log
- `t file` — track specific file
- `ut file` — untrack file
- `ls` — list tracked files
- `sp` — split interactively
- `ab` — absorb (auto-squash)
- `u` — undo last operation

**Occasional:**
- `ll` — detailed log
- `lg` — last 20 commits
- `dp` — diff parent
- `ds` — diff stats
- `ne` — new change, edit parent
- `nt` — new change on trunk
- `e <rev>` — edit revision
- `sqi` — squash interactive
- `r` — rebase
- `rt` — rebase onto trunk
- `bl` — list bookmarks
- `bc` — create bookmark
- `bs` — set bookmark
- `bm` — move bookmark
- `tug` — move bookmark to parent
- `opl` — last 20 operations
- `conflicts` — list conflicts

**Rarely needed:**
- `la` — all commits
- `nm` — new with message
- `desc` — describe (editor)
- `c` — commit
- `ci` — commit interactive
- `sqf` — squash from
- `sqt` — squash into
- `spp` — split parallel
- `rba` — rebase all mutable
- `reheat` — rebase stack
- `nb` — new bookmark at parent
- `bd` — delete bookmark
- `f` — fetch default remote
- `p` — push default remote
- `pc` — push codeberg only
- `opl` — last 20 operations
- `sh` — show commit
- `shp` — show parent
- `ae` — abandon empty
- `hideempty` — hide empty commits

## Differences from git

| Git | jj | Notes |
|-----|-----|-------|
| `git add .` | `jj ta` | Track all files |
| `git commit -m` | `jj dm "msg"` then `jj n` | Describe then create new empty |
| `git push` | `jj push` | Push main branch |
| `git pull` | `jj fa` | Fetch all (no auto-merge) |
| `git branch` | `jj bl` | List bookmarks |
| `git checkout` | `jj e` | Edit revision |
| `git rebase -i` | `jj sq`, `jj sp`, `jj ab` | More granular |
| `git stash` | `jj ne` | New change, edit parent |
| `git reset --hard` | `jj u` | Undo last operation |
| `git reflog` | `jj op` | Operation log |

## Configuration

All aliases defined in `modules/hjem/jujutsu.nix`. Edit and rebuild to change:

```bash
cd ~/dotfiles/modules/hjem
# Edit jujutsu.nix
jj ta
nrt-rig
```
