const float DURATION = 1.8; // seconds; must match [animation.windows_in] duration_ms
const float PEAK = 0.36;
const float STEP = 0.15; // seconds; the SHODAN reference gif's 3-frame beat at 20 fps
const float SURGE_BAND = 0.30; // fraction of the shorter side the bolts reach in
const float CELL = 48.0;
const float SPLIT_PX = 9.0;
const float FLASH = 0.55;
// Same tear as the flinch in anomalos.glsl, held on for the whole animation.
const float TEAR_PX = 18.0;
const float TEAR_MIN = 0.06; // fraction of the window height
const float TEAR_MAX = 0.35;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

// Music falls off with frequency, so each band is scaled by a tilt that puts its loud passages near 1.0.
float au_band(float pos) {
    return umbriel_audio_available() * clamp((60.0 + 220.0 * pow(pos, 2.5)) * umbriel_audio_band(pos), 0.0, 1.0);
}

float so_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 so_segment(vec2 p, vec2 a, vec2 b) {
    vec2 v = b - a;
    float t = clamp(dot(p - a, v) / max(dot(v, v), 0.001), 0.0, 1.0);
    return vec2(length(p - a - t * v), t * length(v));
}

// e is (along the edge, depth inward); returns core, halo.
vec2 so_edge(vec2 e, float len, float edge_id, float reach, float grow, float beat, float energy) {
    vec2 acc = vec2(0.0);
    if (e.y > reach + 30.0) return acc;
    float cell = floor(e.x / CELL);
    for (int i = -1; i <= 1; i++) {
        float id = cell + float(i);
        vec2 key = vec2(id, edge_id * 17.0 + umbriel_random_seed.y * 50.0);
        if (so_hash(vec2(so_hash(key), beat)) > 0.35 + 0.55 * energy) continue;
        float u0 = (id + 0.2 + 0.6 * so_hash(key + 1.0)) * CELL;
        if (u0 < 8.0 || u0 > len - 8.0) continue;
        float bpos = (edge_id == 0.0 ? 0.0 : (edge_id == 3.0 ? 0.25 : (edge_id == 1.0 ? 0.5 : 0.75))) + 0.25 * clamp(u0 / max(len, 1.0), 0.0, 1.0);
        float bl = au_band(0.85 * (1.0 - abs(2.0 * bpos - 1.0)));
        float k = smoothstep(0.1, 0.45, bl) * (0.8 + 1.2 * bl);
        float d1 = reach * (0.15 + 0.3 * so_hash(key + 2.0));
        float jog = 6.0 + so_hash(key + 3.0) * 26.0;
        float side = so_hash(key + 4.0) < 0.5 ? -1.0 : 1.0;
        float d2 = reach * (0.2 + 0.6 * pow(so_hash(key + 5.0), 1.5));
        vec2 a = vec2(u0, -2.0);
        vec2 b = vec2(u0, d1);
        vec2 c = vec2(u0 + side * jog, d1 + jog);
        vec2 d = vec2(c.x, c.y + d2);
        vec2 s0 = so_segment(e, a, b);
        vec2 s1 = so_segment(e, b, c);
        s1.y += d1 + 2.0;
        vec2 s2 = so_segment(e, c, d);
        s2.y += d1 + 2.0 + jog * 1.41421356;
        vec2 r = s0.x < s1.x ? s0 : s1;
        r = r.x < s2.x ? r : s2;
        float total = d1 + 2.0 + jog * 1.41421356 + d2;
        float cut = total * grow;
        float on = 1.0 - smoothstep(cut - 4.0, cut, r.y);
        acc.x = max(acc.x, (1.0 - smoothstep(0.9, 1.9, r.x)) * on * k);
        acc.y += exp(-r.x * 0.12) * on * k;
    }
    return acc;
}

vec4 animation(vec2 uv) {
    float lp = clamp(umbriel_linear_progress, 0.0, 1.0);
    float rise = pow(clamp(lp / PEAK, 0.0, 1.0), 2.2);
    float fall = exp(-max(lp - PEAK, 0.0) * 7.0) * (1.0 - smoothstep(0.85, 1.0, lp));
    float energy = lp < PEAK ? rise : fall;
    // Audio drives it: level lifts the glow, bass pulses the current, treble widens the split. The flinch stays on its timer.
    float au = umbriel_audio_available();
    float lvl = au * clamp(max(umbriel_audio_rms(), 0.5 * umbriel_audio_level()) / 0.045, 0.0, 1.0);
    float bass = au_band(0.08);
    float treble = au_band(0.7);
    energy = clamp(energy * (0.4 + 1.3 * lvl), 0.0, 1.0);
    float reveal = smoothstep(0.04, PEAK, lp);
    float grow = clamp(lp / PEAK, 0.0, 1.0);
    float flinch = smoothstep(0.0, 0.03, lp) * (1.0 - smoothstep(0.85, 0.98, lp));
    float beat = floor(lp * DURATION / STEP) + 13.0 * floor(bass * 5.0 + treble * 3.0);
    float roll = so_hash(vec2(beat, umbriel_random_seed.x * 100.0));
    float tseed = umbriel_random_seed.z * 50.0;

    // A zero count means the palette is off, which is how a shader keeps its own colours.
    bool pal = umbriel_palette_count > 0;
    vec3 trace = pal ? umbriel_palette_at(0.0).rgb : vec3(0.22, 1.0, 0.45);
    vec3 fringe_a = pal ? umbriel_palette_at(0.0).rgb : vec3(0.25, 0.9, 1.0);
    vec3 fringe_b = pal ? umbriel_palette_at(0.75).rgb : vec3(1.0, 0.22, 0.3);
    vec3 hot = mix(trace, vec3(1.0), 0.7);

    vec2 size = umbriel_size;
    vec2 p = uv * size;
    float tear = 0.0;
    for (int i = 0; i < 2; i++) {
        float fi = float(i) * 7.0;
        float mid = so_hash(vec2(beat, 43.0 + fi + tseed)) * size.y;
        float half_band = 0.5 * mix(TEAR_MIN, TEAR_MAX, so_hash(vec2(beat, 47.0 + fi + tseed))) * size.y;
        float on = i == 0 ? 1.0 : step(0.5, so_hash(vec2(beat, 41.0 + tseed)));
        tear += on * step(abs(p.y - mid), half_band)
            * (so_hash(vec2(beat, 53.0 + fi + tseed)) < 0.5 ? -1.0 : 1.0)
            * TEAR_PX * flinch * (0.4 + 0.6 * so_hash(vec2(beat, 59.0 + fi + tseed)));
    }
    vec2 suv = uv - vec2(tear / max(size.x, 1.0), 0.0);

    vec4 base = umbriel_sample(suv);
    vec3 original = base.rgb / max(base.a, 0.0001);
    float lc = dot(original, LUMA);
    float dx = max(energy, flinch) * (0.35 + 0.65 * roll) * SPLIT_PX / max(size.x, 1.0);
    vec4 sa = umbriel_sample(suv - vec2(dx, 0.0));
    vec4 sb = umbriel_sample(suv + vec2(dx, 0.0));
    float la = dot(sa.rgb / max(sa.a, 0.0001), LUMA);
    float lb = dot(sb.rgb / max(sb.a, 0.0001), LUMA);
    vec3 col = original;
    col += fringe_a * max(la - lc, 0.0) + fringe_b * max(lb - lc, 0.0);
    col *= mix(vec3(1.0), fringe_a, clamp(lc - la, 0.0, 1.0));
    col *= mix(vec3(1.0), fringe_b, clamp(lc - lb, 0.0, 1.0));
    col *= reveal;

    vec2 pt = p - vec2(tear, 0.0);
    float reach = SURGE_BAND * min(size.x, size.y);
    vec2 f = so_edge(pt, size.x, 0.0, reach, grow, beat, energy)
        + so_edge(vec2(pt.x, size.y - pt.y), size.x, 1.0, reach, grow, beat, energy)
        + so_edge(vec2(pt.y, pt.x), size.y, 2.0, reach, grow, beat, energy)
        + so_edge(vec2(pt.y, size.x - pt.x), size.y, 3.0, reach, grow, beat, energy);
    float edge = min(min(p.x, p.y), min(size.x - p.x, size.y - p.y));
    float rim = exp(-edge / (18.0 + 60.0 * energy));

    col += trace * (f.y * 0.25 + rim * 0.6) * energy;
    col += hot * f.x * min(energy * 1.5, 1.0);
    col += hot * FLASH * pow(energy, 4.0) * (0.35 + 0.65 * rim);

    return vec4(clamp(col, 0.0, 1.0) * base.a, base.a);
}
