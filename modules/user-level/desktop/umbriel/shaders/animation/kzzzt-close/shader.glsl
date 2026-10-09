const float DURATION = 0.7; // seconds; must match [animation.windows_out] duration_ms
const float FPS = 30.0; // the surge steps in hard frames, never smoothly
const float PEAK = 0.5; // progress at which the surge is at full and the fuse starts to go
const float POP = 0.86; // progress of the last overexposed frame
const float SPLIT_PX = 9.0;
const float TEAR_PX = 60.0;
const float TEAR_MIN = 0.06; // fraction of the window height
const float TEAR_MAX = 0.35;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

float fz_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 fz_unpremul(vec4 c) {
    return c.rgb / max(c.a, 0.0001);
}

// Only what is already bright burns into the glow.
vec3 fz_bright(vec3 c) {
    return c * max(dot(c, LUMA) - 0.12, 0.0);
}

vec4 animation(vec2 uv) {
    float lp = clamp(umbriel_linear_progress, 0.0, 1.0);
    float t = lp * DURATION;
    float fr = floor(t * FPS);
    float tseed = umbriel_random_seed.z * 50.0;
    float roll = fz_hash(vec2(fr, umbriel_random_seed.x * 100.0));

    // Per-frame spikes and dips keep the surge from reading as a smooth ramp.
    float ramp = smoothstep(0.0, PEAK, lp);
    float spike = fz_hash(vec2(fr, tseed + 1.0));
    float surge = ramp * (spike < 0.14 ? 0.1 : 0.35 + 1.65 * spike);

    float pop_len = 1.0 / (DURATION * FPS);
    float pop = step(POP, lp) * (1.0 - step(POP + pop_len, lp));
    float gone = step(POP + pop_len, lp);
    float duty = 1.0 - smoothstep(PEAK, POP, lp);
    float on = lp < PEAK ? 1.0 : step(fz_hash(vec2(fr, tseed + 2.0)), duty);
    float vis = max(on * (1.0 - gone), pop);
    float flinch = smoothstep(0.0, 0.03, lp);
    float ten = clamp(surge, 0.0, 1.4) * flinch;

    // A zero count means the palette is off, which is how a shader keeps its own colours.
    bool pal = umbriel_palette_count > 0;
    vec3 trace = pal ? umbriel_palette_at(0.0).rgb : vec3(0.22, 1.0, 0.45);
    vec3 fringe_a = pal ? umbriel_palette_at(0.0).rgb : vec3(0.25, 0.9, 1.0);
    vec3 fringe_b = pal ? umbriel_palette_at(0.75).rgb : vec3(1.0, 0.22, 0.3);
    vec3 hot = mix(trace, vec3(1.0), 0.7);

    vec2 size = umbriel_size;
    vec2 p = uv * size;

    float tear = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i) * 7.0;
        float mid = fz_hash(vec2(fr, 43.0 + fi + tseed)) * size.y;
        float half_band = 0.5 * mix(TEAR_MIN, TEAR_MAX, fz_hash(vec2(fr, 47.0 + fi + tseed))) * size.y;
        float band_on = i == 0 ? 1.0 : step(0.35, fz_hash(vec2(fr, 41.0 + fi + tseed)));
        tear += band_on * step(abs(p.y - mid), half_band)
            * (fz_hash(vec2(fr, 53.0 + fi + tseed)) < 0.5 ? -1.0 : 1.0)
            * TEAR_PX * ten * (0.4 + 0.6 * fz_hash(vec2(fr, 59.0 + fi + tseed))) * (1.0 + 2.0 * pop);
    }

    float strip_hot = step(0.5, fz_hash(vec2(floor(p.y / 48.0), fr + 5.0 + tseed)));
    float strip = (fz_hash(vec2(floor(p.y / 3.0), fr + tseed)) - 0.5) * 28.0 * strip_hot * ten * ten;
    vec2 tile = floor(p / vec2(64.0, 16.0));
    float hop = step(1.0 - 0.3 * ten, fz_hash(tile + vec2(fr, 17.0 + tseed)));
    float hop_x = floor((fz_hash(tile + vec2(fr, 18.0 + tseed)) - 0.5) * 6.0) * 64.0 * hop;
    vec2 shake = (vec2(fz_hash(vec2(fr, 81.0)), fz_hash(vec2(fr, 82.0))) - 0.5) * 12.0 / size * ten;
    vec2 suv = uv - vec2((tear - strip - hop_x) / max(size.x, 1.0), 0.0) + shake;

    vec4 base = umbriel_sample(suv);
    float shape = umbriel_sample(uv).a;
    vec3 original = fz_unpremul(base);
    float lc = dot(original, LUMA);

    float dx = (1.5 + SPLIT_PX * (0.4 + 1.6 * ten) * (0.35 + 0.65 * roll)) / size.x;
    float la = dot(fz_unpremul(umbriel_sample(suv - vec2(dx, 0.0))), LUMA);
    float lb = dot(fz_unpremul(umbriel_sample(suv + vec2(dx, 0.0))), LUMA);
    vec3 col = original;
    float fringe_amt = clamp(4.0 * ten, 0.0, 1.0);
    col += fringe_amt * (fringe_a * max(la - lc, 0.0) + fringe_b * max(lb - lc, 0.0));
    col *= mix(vec3(1.0), fringe_a, fringe_amt * clamp(lc - la, 0.0, 1.0));
    col *= mix(vec3(1.0), fringe_b, fringe_amt * clamp(lc - lb, 0.0, 1.0));

    col *= mix(1.0, 0.15 + 1.6 * fz_hash(vec2(fr, tseed + 3.0)), ramp);
    col = mix(col, trace * lc * 2.2, 0.55 * ramp);
    col = pow(max(col, vec3(0.0)), vec3(1.0 + 0.9 * ramp));

    vec3 glow = vec3(0.0);
    float seen = 0.0;
    float spread = 5.0 + 26.0 * clamp(surge, 0.0, 1.4) + 30.0 * pop;
    for (int i = 0; i < 12; i++) {
        float a = float(i) * 2.39996 + roll * 6.28318;
        float rad = spread * sqrt((float(i) + 0.5) / 12.0);
        vec3 c = fz_unpremul(umbriel_sample(suv + vec2(cos(a), sin(a)) * rad / size));
        glow += fz_bright(c);
        seen += dot(c, LUMA);
    }
    glow /= 12.0;
    // A mostly dark window has little to burn, so what it has burns harder; a bright one is held back.
    float exposure = 1.8 / (0.3 + 3.0 * seen / 12.0);

    vec3 bleed = vec3(0.0);
    for (int i = 1; i <= 6; i++) {
        float w = exp(-float(i) * 0.35);
        float o = float(i) * (2.0 + 6.0 * clamp(surge, 0.0, 1.4)) / size.x;
        bleed += w * (fz_bright(fz_unpremul(umbriel_sample(suv + vec2(o, 0.0)))) + fz_bright(fz_unpremul(umbriel_sample(suv - vec2(o, 0.0)))));
    }
    bleed *= 0.06;

    // The glow is the palette's, not the picture's, and it keeps burning when the picture cuts out.
    vec3 lit = glow + bleed;
    vec3 phos = mix(lit, trace * dot(lit, vec3(1.0)) * 1.1, 0.7);
    float gain = 1.4 * exposure * ten * mix(0.4, 1.0, vis) * (1.0 + 1.5 * pop);

    float after = exp(-max(lp - POP - pop_len, 0.0) * 16.0) * step(0.4, fz_hash(vec2(fr, tseed + 4.0))) * (1.0 - smoothstep(0.94, 1.0, lp));
    gain = mix(gain, 2.0 * after, gone);

    col = col * (1.0 + 1.6 * pop) + hot * 0.25 * pop;

    // Light piles up softly instead of clipping, so bright windows burn hot without turning to a white wall.
    vec3 emit = (vec3(1.0) - exp(-phos * gain)) * shape;
    float body_a = base.a * vis;
    vec3 rgb = clamp(col * body_a + emit, 0.0, 1.0);
    float a = max(body_a, clamp(max(emit.r, max(emit.g, emit.b)), 0.0, 1.0));
    return vec4(min(rgb, vec3(a)), a);
}
