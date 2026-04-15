{
  flake.nixosModules.ghostty = {
    config,
    pkgs,
    ...
  }: let
    ghostty = pkgs.ghostty.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./patches/ghostty-cursor-debounce-patch];
    });
  in {
    users.users.${config.mySystem.user.name}.packages = [ghostty];

    hjem.users.${config.mySystem.user.name} = {
      xdg.config.files."ghostty/config".text = ''
        scroll-to-bottom = keystroke
        copy-on-select = clipboard
        window-show-tab-bar = never
        theme = noctalia

        keybind = shift+enter=text:\n
        keybind = ctrl+v=paste_from_clipboard

        # Unbind terminal shortcuts that conflict with editors
        keybind = ctrl+q=unbind
        keybind = ctrl+w=unbind
        keybind = shift+page_up=unbind
        keybind = shift+page_down=unbind
        keybind = shift+home=unbind
        keybind = shift+end=unbind

        custom-shader = ~/.config/ghostty/shaders/cursor_tail.glsl
        custom-shader-animation = always
      '';

      xdg.config.files."ghostty/shaders/cursor_tail.glsl".text = ''
        // -- CONFIGURATION --
        vec4 TRAIL_COLOR = iCurrentCursorColor;
        const float DURATION = 0.09;
        const float MAX_TRAIL_LENGTH = 0.2;
        const float THRESHOLD_MIN_DISTANCE = 0.0;
        const float BLUR = 2.0;

        // EaseOutCirc
        float ease(float x) {
            return sqrt(1.0 - pow(x - 1.0, 2.0));
        }

        float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b) {
            vec2 d = abs(p - xy) - b;
            return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
        }

        float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
            vec2 e = b - a;
            vec2 w = p - a;
            vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
            float segd = dot(p - proj, p - proj);
            d = min(d, segd);

            float c0 = step(0.0, p.y - a.y);
            float c1 = 1.0 - step(0.0, p.y - b.y);
            float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
            float allCond = c0 * c1 * c2;
            float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
            float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
            s *= flip;
            return d;
        }

        float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
            float s = 1.0;
            float d = dot(p - v0, p - v0);
            d = seg(p, v0, v3, s, d);
            d = seg(p, v1, v0, s, d);
            d = seg(p, v2, v1, s, d);
            d = seg(p, v3, v2, s, d);
            return s * sqrt(d);
        }

        vec2 normalizeCoord(vec2 value, float isPosition) {
            return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
        }

        float antialias(float distance) {
            return 1.0 - smoothstep(0.0, normalizeCoord(vec2(BLUR, BLUR), 0.0).x, distance);
        }

        float determineIfTopRightIsLeading(vec2 a, vec2 b) {
            float condition1 = step(b.x, a.x) * step(a.y, b.y);
            float condition2 = step(a.x, b.x) * step(b.y, a.y);
            return 1.0 - max(condition1, condition2);
        }

        void mainImage(out vec4 fragColor, in vec2 fragCoord) {
            fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);

            vec2 vu = normalizeCoord(fragCoord, 1.0);
            vec2 offsetFactor = vec2(-0.5, 0.5);

            vec4 currentCursor = vec4(normalizeCoord(iCurrentCursor.xy, 1.0), normalizeCoord(iCurrentCursor.zw, 0.0));
            vec4 previousCursor = vec4(normalizeCoord(iPreviousCursor.xy, 1.0), normalizeCoord(iPreviousCursor.zw, 0.0));

            vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
            vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);

            vec2 delta = centerCP - centerCC;
            float lineLength = length(delta);

            float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5);
            vec4 newColor = vec4(fragColor);

            float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE;
            float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);

            if (lineLength > minDist) {
                float tail_delay_factor = MAX_TRAIL_LENGTH / lineLength;
                float isLongMove = step(MAX_TRAIL_LENGTH, lineLength);

                float head_eased = mix(1.0, ease(progress), isLongMove);
                float tail_eased = mix(ease(progress), ease(smoothstep(tail_delay_factor, 1.0, progress)), isLongMove);

                vec2 delta_abs = abs(centerCC - centerCP);
                float threshold = 0.001;
                float isStraightMove = max(step(delta_abs.y, threshold), step(delta_abs.x, threshold));

                vec2 head_pos_tl = mix(previousCursor.xy, currentCursor.xy, head_eased);
                vec2 tail_pos_tl = mix(previousCursor.xy, currentCursor.xy, tail_eased);

                float isTopRightLeading = determineIfTopRightIsLeading(currentCursor.xy, previousCursor.xy);
                float isBottomLeftLeading = 1.0 - isTopRightLeading;

                vec2 v0 = vec2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w);
                vec2 v1 = vec2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y);
                vec2 v2 = vec2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y);
                vec2 v3 = vec2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w);

                float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3);

                vec2 head_center = mix(centerCP, centerCC, head_eased);
                vec2 tail_center = mix(centerCP, centerCC, tail_eased);
                vec2 min_center = min(head_center, tail_center);
                vec2 max_center = max(head_center, tail_center);
                vec2 box_size = (max_center - min_center) + currentCursor.zw;
                vec2 box_center = (min_center + max_center) * 0.5;

                float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5);
                float sdfTrail = mix(sdfTrail_diag, sdfTrail_rect, isStraightMove);

                float trailAlpha = antialias(sdfTrail);
                newColor = mix(newColor, TRAIL_COLOR, trailAlpha);
                newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.0));
            }

            fragColor = newColor;
        }
      '';

      xdg.data.files."applications/com.mitchellh.ghostty.desktop".text = ''
        [Desktop Entry]
        Name=Ghostty
        Comment=Fast, feature-rich terminal emulator
        Keywords=shell;prompt;command;commandline;cmd;
        Icon=com.mitchellh.ghostty
        StartupWMClass=com.mitchellh.ghostty
        TryExec=ghostty
        Exec=ghostty
        Type=Application
        Categories=System;TerminalEmulator;Utility;
        Terminal=false
      '';
    };
  };
}
