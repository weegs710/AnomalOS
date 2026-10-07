// The glitch clock and every glitch constant must match kzzzt.glsl, so the border shudders with its window.
const float STEP = 0.15;
const float SPLIT_PX = 2.5;
const float TEAR_CHANCE = 0.85;
const float TEAR_MIN = 0.06; // fraction of the window height
const float TEAR_MAX = 0.35;
const float TEAR_PX = 6.0;
const float FLINCH_PERIOD = 15.0;
const float FLINCH_LEN = 0.225; // seconds
const float FLINCH_CHANCE = 0.8;
const float SCANLINE_DEPTH = 0.18;
const float GRILLE_DEPTH = 0.12;
const float ROLL_PERIOD = 7.0;
const float ROLL_STRENGTH = 0.06;
const float FLICKER = 0.03;
// The edge, in logical px outside the client.
const float LINE_INNER = 1.5;
const float LINE_OUTER = 4.0;
const float ARC_RADIUS = 2.75;
const float ARC_PERIOD = 160.0;
const float ARC_SPEED = 40.0; // logical px per second
const float DASH_RADIUS = 6.5;
const float DASH_LEN = 7.0;
const float DASH_SPEED = 6.0;
const float TENDRIL_CELL = 18.0;
const float TENDRIL_CHANCE = 0.9;
const float TENDRIL_REACH = 15.0;
const float TUBE = 1.3; // tendrils are hollow, drawn as the two walls of a tube this wide
const float PAD = 2.2;

// The shape works in logical px from the client's top-left, so the prelude's uv distance is mapped back to that frame.
float ring_distance(vec2 p) {
    return umbriel_border_distance(umbriel_border_hole.xy + p / umbriel_size);
}

// Music falls off with frequency, so each band is scaled by a tilt that puts its loud passages near 1.0.
float au_band(float pos) {
    return umbriel_audio_available() * clamp((60.0 + 220.0 * pow(pos, 2.5)) * umbriel_audio_band(pos), 0.0, 1.0);
}

float sr_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 sr_segment(vec2 p, vec2 a, vec2 b) {
    vec2 v = b - a;
    float t = clamp(dot(p - a, v) / max(dot(v, v), 0.001), 0.0, 1.0);
    return vec2(length(p - a - t * v), t * length(v));
}

float sr_line(float d, float center, float width, float aa) {
    return 1.0 - smoothstep(width, width + aa, abs(d - center));
}

// e is (along one side, distance out from it). x: tube walls and pads, y: current.
vec2 sr_tendrils(vec2 e, float len, float side_id, float t, float aa) {
    vec2 acc = vec2(0.0);
    if (e.y < -1.0 || e.y > TENDRIL_REACH + 4.0) return acc;
    float cell = floor(e.x / TENDRIL_CELL);
    for (int i = -1; i <= 1; i++) {
        vec2 key = vec2(cell + float(i), side_id * 13.0);
        if (sr_hash(key) > TENDRIL_CHANCE) continue;
        float u0 = (key.x + 0.2 + 0.6 * sr_hash(key + 1.0)) * TENDRIL_CELL;
        if (u0 < 10.0 || u0 > len - 10.0) continue;
        float o1 = 5.0 + 4.0 * sr_hash(key + 2.0);
        float run = (4.0 + 12.0 * sr_hash(key + 3.0)) * (sr_hash(key + 4.0) < 0.5 ? -1.0 : 1.0);
        float o2 = min(o1 + 2.0 + 4.0 * sr_hash(key + 5.0), TENDRIL_REACH - PAD);
        vec2 a = vec2(u0, LINE_OUTER);
        vec2 b = vec2(u0, o1);
        vec2 c = vec2(u0 + run, o1);
        vec2 d = vec2(c.x, o2);
        vec2 s0 = sr_segment(e, a, b);
        vec2 s1 = sr_segment(e, b, c);
        s1.y += o1 - LINE_OUTER;
        vec2 s2 = sr_segment(e, c, d);
        s2.y += o1 - LINE_OUTER + abs(run);
        vec2 r = s0.x < s1.x ? s0 : s1;
        r = r.x < s2.x ? r : s2;
        float total = o1 - LINE_OUTER + abs(run) + (o2 - o1);
        float walls = sr_line(r.x, TUBE, 0.35, aa) + 0.25 * (1.0 - smoothstep(TUBE - 0.3, TUBE + 0.3, r.x));
        vec2 q = e - d;
        float box = max(abs(q.x), abs(q.y));
        float loop_w = sr_hash(key + 6.0) < 0.35 ? 3.5 : PAD;
        float pad = 1.0 - smoothstep(0.35, 0.35 + aa, abs(box - loop_w));
        float period = 1.5 + 3.0 * sr_hash(key + 7.0);
        float head = fract(t / period + sr_hash(key + 8.0)) * (total + 20.0) - 10.0;
        float pulse = exp(-pow((r.y - head) / 4.0, 2.0)) * exp(-r.x * 0.6);
        acc.x = max(acc.x, max(walls, pad));
        acc.y += pulse;
    }
    return acc;
}

// x: shape coverage, y: hot current.
vec2 sr_shape(vec2 p, vec2 size, float t, float aa) {
    float d = ring_distance(p);
    if (d < -1.0) return vec2(0.0);
    vec2 inset = vec2(max(-p.x, p.x - size.x), max(-p.y, p.y - size.y));
    float s = inset.y > inset.x
        ? (p.y < 0.0 ? p.x : 2.0 * size.x + size.y - p.x)
        : (p.x > size.x ? size.x + p.y : 2.0 * (size.x + size.y) - p.y);

    float lines = max(sr_line(d, LINE_INNER, 0.4, aa), sr_line(d, LINE_OUTER, 0.4, aa));
    float dash = sr_line(d, DASH_RADIUS, 0.8, aa) * step(0.45, fract((s + t * DASH_SPEED) / DASH_LEN));
    float fwd = fract((s - t * ARC_SPEED) / ARC_PERIOD);
    float back = fract((s + t * ARC_SPEED * 0.6) / (ARC_PERIOD * 1.7));
    float arc_a = sin(clamp(fwd / 0.25, 0.0, 1.0) * 3.14159);
    float arc_b = sin(clamp(back / 0.18, 0.0, 1.0) * 3.14159);
    float crescent = max(sr_line(d, ARC_RADIUS, 0.2 + 0.9 * arc_a, aa) * step(0.001, arc_a),
                         sr_line(d, ARC_RADIUS, 0.2 + 0.7 * arc_b, aa) * step(0.001, arc_b));

    vec2 td = sr_tendrils(vec2(p.x, -p.y), size.x, 0.0, t, aa);
    td = max(td, sr_tendrils(vec2(p.x, p.y - size.y), size.x, 1.0, t, aa));
    td = max(td, sr_tendrils(vec2(p.y, -p.x), size.y, 2.0, t, aa));
    td = max(td, sr_tendrils(vec2(p.y, p.x - size.x), size.y, 3.0, t, aa));

    float bpos = clamp(s / max(2.0 * (size.x + size.y), 1.0), 0.0, 1.0);
    float bl = au_band(0.85 * (1.0 - abs(2.0 * bpos - 1.0)));
    float g = smoothstep(0.1, 0.45, bl) * (0.8 + 1.2 * bl);
    return vec2(max(max(lines, dash * 0.7 * (0.6 + 0.4 * g)), max(crescent * (0.6 + 0.4 * g), td.x * (0.45 + 0.55 * g))), (crescent * 0.8 + td.y) * g);
}

vec4 border(vec2 uv) {
    vec2 coords = (uv - umbriel_border_hole.xy) * umbriel_size;
    float t = umbriel_time;
    float scale = max(umbriel_scale, 0.01);
    float aa = 1.0 / scale;
    vec2 size = umbriel_border_hole.zw * umbriel_size;
    // Same seed kzzzt.glsl derives from its own window size, so both pick the same tear bands.
    float seed = sr_hash(floor(size * scale) * 0.013 + 0.5);

    float tick = floor(t / STEP);
    float roll = sr_hash(vec2(tick, 5.3));
    float local = t + seed * FLINCH_PERIOD;
    float slot = floor(local / FLINCH_PERIOD);
    float into = local - slot * FLINCH_PERIOD;
    float start = floor(sr_hash(vec2(slot, seed * 91.0)) * floor((FLINCH_PERIOD - FLINCH_LEN) / STEP)) * STEP;
    float flinch = (into >= start && into < start + FLINCH_LEN
        && sr_hash(vec2(slot, 13.7 + seed)) < FLINCH_CHANCE) ? 1.0 : 0.0;
    // Audio drives it: level lifts the glow, bass pulses the current, treble widens the split. The flinch stays on its timer.
    float au = umbriel_audio_available();
    float lvl = au * clamp(max(umbriel_audio_rms(), 0.5 * umbriel_audio_level()) / 0.045, 0.0, 1.0);
    float bass = au_band(0.08);
    float treble = au_band(0.7);
    float ttick = tick + 13.0 * floor(bass * 5.0 + treble * 3.0);
    float tear_mid = sr_hash(vec2(ttick, 43.0 + seed)) * size.y;
    float tear_half = 0.5 * mix(TEAR_MIN, TEAR_MAX, sr_hash(vec2(ttick, 47.0 + seed))) * size.y;
    float tear = step(sr_hash(vec2(ttick, 41.0 + seed)), TEAR_CHANCE)
        * step(abs(coords.y - tear_mid), tear_half)
        * (sr_hash(vec2(ttick, 53.0 + seed)) < 0.5 ? -1.0 : 1.0)
        * TEAR_PX * (0.5 + 0.5 * sr_hash(vec2(ttick, 59.0 + seed))) * (0.5 + 3.0 * lvl);

    // A zero count means the palette is off, which is how a shader keeps its own colours.
    bool pal = umbriel_palette_count > 0;
    vec3 trace = pal ? umbriel_palette_at(0.0).rgb : vec3(0.22, 1.0, 0.45);
    vec3 fringe_a = pal ? umbriel_palette_at(0.0).rgb : vec3(0.25, 0.9, 1.0);
    vec3 fringe_b = pal ? umbriel_palette_at(0.75).rgb : vec3(1.0, 0.22, 0.3);
    vec3 accent = pal
        ? umbriel_palette_at(roll < 0.5 ? 0.25 : 0.5).rgb
        : (roll < 0.5 ? vec3(0.3, 1.0, 0.4) : vec3(0.95, 0.85, 0.35));
    vec3 hot = mix(trace, vec3(1.0), 0.5);

    vec2 p = coords - vec2(tear, 0.0);
    float split = (0.3 + 0.7 * roll) * SPLIT_PX * (1.0 + flinch + 3.0 * treble);
    vec2 f = sr_shape(p, size, t, aa);
    float ga = max(sr_shape(p - vec2(split, 0.0), size, t, aa).x - f.x, 0.0);
    float gb = max(sr_shape(p + vec2(split, 0.0), size, t, aa).x - f.x, 0.0);

    vec3 col = trace * f.x + hot * min(f.y * (1.0 + 3.0 * bass), 1.0) + fringe_a * ga + fringe_b * gb;
    col = mix(col, accent, min(f.y, 1.0) * 0.25);
    col *= (1.0 + 0.6 * flinch) * (0.85 + 0.9 * lvl);

    float scan = 0.5 + 0.5 * sin(coords.y * scale * 3.14159);
    col *= mix(1.0 - SCANLINE_DEPTH, 1.0, scan);
    float triad = mod(floor(coords.x * scale), 3.0);
    vec3 grille = triad < 1.0 ? vec3(1.0, 0.5, 0.5) : (triad < 2.0 ? vec3(0.5, 1.0, 0.5) : vec3(0.5, 0.5, 1.0));
    col *= mix(vec3(1.0), grille, GRILLE_DEPTH);
    float sweep = exp(-pow((coords.y / max(size.y, 1.0) - (fract(t / ROLL_PERIOD) * 1.4 - 0.2)) / 0.06, 2.0));
    col += trace * sweep * ROLL_STRENGTH;
    col *= 1.0 + FLICKER * (sr_hash(vec2(floor(t * 30.0), 71.0)) - 0.5);

    float alpha = clamp(max(max(f.x, min(f.y, 1.0)), max(ga, gb)), 0.0, 1.0) * (0.85 + 0.15 * clamp(1.5 * lvl, 0.0, 1.0));
    return vec4(clamp(col / max(alpha, 0.001), 0.0, 1.0) * alpha, alpha);
}
