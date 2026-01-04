# Cursor Themes

## phinger-cursors-dark-hyprcursor

Compiled hyprcursor format of phinger-cursors-dark.

### Source

- **Upstream:** https://github.com/phisch/phinger-cursors
- **Author:** Philipp Schaffrath (phisch)
- **License:** CC-BY-SA-4.0
- **Version:** 2.1 (dark variant)

### Conversion

Converted from nixpkgs `pkgs.phinger-cursors` using `hyprcursor-util`:

```bash
# Extract xcursor → working state
hyprcursor-util --extract ~/.local/share/icons/phinger-cursors-dark \
  --output /tmp/extract

# Compile working state → hyprcursor
hyprcursor-util --create /tmp/extract/extracted_phinger-cursors-dark \
  --output ./output
```

**Date converted:** 2026-01-04
**Tool:** hyprcursor-util from https://github.com/hyprwm/hyprcursor

### Format Details

- **xcursor (original):** 2.0 MB
- **hyprcursor (this):** 8.5 KB
- Files: `.hlc` (compiled hyprcursor theme files)

### Updating

1. Get latest `pkgs.phinger-cursors` from nixpkgs
2. Run conversion commands above
3. Replace `phinger-cursors-dark-hyprcursor/` directory
4. Commit

### Usage

- Works: Hyprland, Qt apps, Chromium/Electron
- Fallback needed: GTK apps (use xcursor version)
