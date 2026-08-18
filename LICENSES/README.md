# Third-party material in anomalOS

anomalOS itself is MIT (see [`../LICENSE`](../LICENSE)). Three things in this repo came from
elsewhere and are **not** covered by that MIT grant. Each is listed below with its own terms, and
where I modified it.

## `lib/sprinkles.nix`

- **From:** the poacher fork of sprinkles, <https://codeberg.org/poacher/sprinkles>
- **Upstream terms:** `MIT OR Apache-2.0`, copyright "Contributors to the sprinkles project"
- **Taken under:** MIT. Full text in [`MIT-sprinkles.txt`](MIT-sprinkles.txt).
- **Modified:** yes. Upstream ships the engine as two files (`default.nix` and `lib/default.nix`);
  this is both flattened into one, reformatted with nixfmt, with the upstream doc comments removed
  and one internal binding renamed. Behaviour is unchanged.

## `modules/user-level/desktop/ghostty/cursor_tail.glsl`

- **From:** <https://github.com/sahaj-b/ghostty-cursor-shaders>
- **Terms:** MIT, Copyright (c) 2026 Sahaj Bhatt. Full text in
  [`MIT-ghostty-cursor-shaders.txt`](MIT-ghostty-cursor-shaders.txt).
- **Modified:** yes, substantially. Trimmed from 239 lines to ~127 by removing the commented-out
  easing-function variants, renamed two helpers (`normalize` → `normalizeCoord`,
  `antialising` → `antialias`), reformatted, and added a visibility/progress gate so the collapsed
  trail stops drawing a lingering ring when a TUI hides the cursor.
- Upstream's rectangle SDF is itself based on Inigo Quilez's 2D distance functions article,
  <https://iquilezles.org/articles/distfunctions2d/>.

## `modules/user-level/desktop/xdg/phinger-cursors-dark-hyprcursor/`

- **From:** phinger-cursors by phisch, <https://github.com/phisch/phinger-cursors>
- **Terms:** CC-BY-SA-4.0. Full text in
  [`CC-BY-SA-4.0-phinger-cursors.txt`](CC-BY-SA-4.0-phinger-cursors.txt).
- **Modified:** yes. This is Adapted Material: the upstream dark XCursor theme converted into
  hyprcursor format with `hyprcursor-util`. No artwork was redrawn.
- **ShareAlike:** this adaptation is distributed under CC-BY-SA-4.0, the same licence as the
  original. It is **not** covered by the repo's MIT licence.
- Disclaimer of warranties: see the "Disclaimer of Warranties and Limitation of Liability" section
  of the licence text.
