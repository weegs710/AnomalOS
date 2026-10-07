const float CELL = 56.0;
const float TRACE_CHANCE = 0.9;
const float EDGE_BAND = 64.0; // logical px
const float ACTIVE_TRACES = 40.0; // an average, not a cap
const float LIFE = 2.6;
const float ATTACK = 0.28;
const float DECAY_RATE = 2.2;
const float FLICKER_HZ = 32.0;
const float JITTER_PX = 5.0;
const float ATTACK_SPLIT_PX = 6.0;
const float PACKET_SPEED = 90.0;
const float TRACE_STRENGTH = 0.9;
const float BREATH_RATE = 1.2566; // radians per second
const float PHOSPHOR_HOLD = 0.45; // share of the line's decay the glow skips, so it outlives the line
const float PHOSPHOR_BLOOM = 0.35;
const float PHOSPHOR_CORE = 0.3; // how far the core burns toward white
// Measured off the frames of a SHODAN reference gif.
const float STEP = 0.15; // 3 frames at 20 fps
const float SPLIT_PX = 2.5;
const float TEAR_CHANCE = 0.85;
const float TEAR_MIN = 0.06; // fraction of the window height
const float TEAR_MAX = 0.35;
const float TEAR_PX = 6.0;
const float FLINCH_PERIOD = 15.0;
const float FLINCH_LEN = 0.225; // seconds
const float FLINCH_CHANCE = 0.8;
const float FLINCH_PX = 3.0;
const float PIN_PITCH = 6.0;
const float PIN_STRENGTH = 0.35;
// barrulus's crt.glsl minus the barrel warp, shallow enough to read text through.
const float SCANLINE_DEPTH = 0.18;
const float GRILLE_DEPTH = 0.12;
const float VIGNETTE = 0.25;
const float ROLL_PERIOD = 7.0;
const float ROLL_STRENGTH = 0.06;
const float FLICKER = 0.03;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

// Music falls off with frequency, so each band is scaled by a tilt that puts its loud passages near 1.0.
float au_band(float pos) {
    return umbriel_audio_available() * clamp((60.0 + 220.0 * pow(pos, 2.5)) * umbriel_audio_band(pos), 0.0, 1.0);
}

float sh_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 sh_segment(vec2 p, vec2 a, vec2 b) {
    vec2 v = b - a;
    float t = clamp(dot(p - a, v) / max(dot(v, v), 0.001), 0.0, 1.0);
    return vec2(length(p - a - t * v), t * length(v));
}

// Main route a-b-c-d-e plus one branch h-g; unused points collapse onto their neighbour.
void sh_trace(float cell, vec2 gk, float len, out vec2 a, out vec2 b, out vec2 c, out vec2 d, out vec2 e,
              out vec2 h, out vec2 g, out float lanes, out float pad) {
    float u0 = (cell + 0.2 + 0.6 * sh_hash(gk + 1.0)) * CELL;
    float d1 = 4.0 + sh_hash(gk + 2.0) * 22.0;
    float jog = 4.0 + sh_hash(gk + 3.0) * 16.0;
    float run = 10.0 + pow(sh_hash(gk + 4.0), 1.3) * 76.0;
    float side = sh_hash(gk + 5.0) < 0.5 ? -1.0 : 1.0;
    float kind = floor(sh_hash(gk + 6.0) * 5.0);
    float reach = u0 + side * (jog * 1.8 + run);
    if (reach < 8.0 || reach > len - 8.0) side = -side;
    a = vec2(u0, -2.0);
    b = vec2(u0, d1);
    c = b;
    d = b;
    e = b;
    h = b;
    g = b;
    if (kind < 0.5) {
        b = vec2(u0, d1 + jog);
        c = b;
        d = b;
        e = b;
        h = b;
        g = b;
    } else {
        c = b + vec2(side * jog, jog);
        d = c + vec2(side * run, 0.0);
        e = d;
        h = c;
        g = c;
        if (kind > 1.5 && kind < 2.5) e = d + vec2(side * jog * 0.8, -jog * 0.8);
        if (kind > 2.5 && kind < 3.5) g = c - vec2(side * run * 0.6, 0.0);
        if (kind > 3.5) {
            h = mix(c, d, 0.3 + 0.4 * sh_hash(gk + 9.0));
            g = h + vec2(0.0, 3.0 + jog * 0.4);
        }
    }
    lanes = sh_hash(gk + 7.0) < 0.3 ? 2.0 : 1.0;
    pad = 1.5 + 2.0 * sh_hash(gk + 8.0);
}

// Distance to the route, and arc length along it from the root.
vec2 sh_route(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d, vec2 e, vec2 h, vec2 g) {
    float lab = length(b - a);
    float lbc = length(c - b);
    float lcd = length(d - c);
    vec2 r = sh_segment(p, a, b);
    vec2 s = sh_segment(p, b, c);
    s.y += lab;
    r = s.x < r.x ? s : r;
    s = sh_segment(p, c, d);
    s.y += lab + lbc;
    r = s.x < r.x ? s : r;
    s = sh_segment(p, d, e);
    s.y += lab + lbc + lcd;
    r = s.x < r.x ? s : r;
    s = sh_segment(p, h, g);
    s.y += lab + lbc + length(h - c);
    return s.x < r.x ? s : r;
}

// q0 is (along the edge, depth inward); dir is screen +x in edge space. acc: core, current, halo, pad. ghost: split fringes.
void sh_edge(vec2 q0, vec2 dir, float len, float edge_id, float t, float period, float aa, float split,
             inout vec4 acc, inout vec2 ghost) {
    if (q0.y > EDGE_BAND + 24.0) return;
    float cell = floor(q0.x / CELL);
    for (int i = -2; i <= 2; i++) {
        vec2 key = vec2(cell + float(i), edge_id * 17.0);
        if (sh_hash(key) > TRACE_CHANCE) continue;
        float clock = t / period + sh_hash(key + 3.1);
        float cycle = floor(clock);
        float age = (clock - cycle) * period - sh_hash(key + vec2(cycle, 9.0)) * (period - LIFE);
        if (age < 0.0 || age > LIFE) continue;
        vec2 a, b, c, d, e, h, g;
        float lanes, padsize;
        sh_trace(key.x, key + cycle * vec2(7.13, 3.71), len, a, b, c, d, e, h, g, lanes, padsize);
        float bpos = (edge_id == 0.0 ? 0.0 : (edge_id == 3.0 ? 0.25 : (edge_id == 1.0 ? 0.5 : 0.75))) + 0.25 * clamp(a.x / max(len, 1.0), 0.0, 1.0);
        float bl = au_band(0.85 * (1.0 - abs(2.0 * bpos - 1.0)));
        float attack = 1.0 - smoothstep(ATTACK * 0.7, ATTACK, age);
        float flick = floor(age * FLICKER_HZ);
        // Phosphor never drops to black between flicker frames.
        float on = age < ATTACK ? mix(0.3, 1.0, step(0.35, sh_hash(key + vec2(flick, 21.0)))) : 1.0;
        float power = age < ATTACK ? 1.6
            : exp(-(age - ATTACK) * DECAY_RATE) * (1.0 - smoothstep(LIFE - 0.3, LIFE, age));
        float k = on * power * smoothstep(0.1, 0.45, bl) * (0.8 + 1.2 * bl);
        float linger = age < ATTACK ? 1.0 : exp((age - ATTACK) * DECAY_RATE * PHOSPHOR_HOLD);
        vec2 q = q0 - vec2((sh_hash(key + vec2(flick, 33.0)) - 0.5) * 2.0 * JITTER_PX * attack, 0.0);
        float s = split + ATTACK_SPLIT_PX * attack;
        float lane = lanes > 1.5 ? 1.7 : 0.0;
        vec2 r = sh_route(q, a, b, c, d, e, h, g);
        float total = length(b - a) + length(c - b) + length(d - c) + length(e - d);
        total = max(total, length(b - a) + length(c - b) + length(h - c) + length(g - h));
        float drawn = total * smoothstep(0.0, ATTACK * 0.6, age);
        float reveal = 1.0 - smoothstep(drawn - 3.0, drawn, r.y);
        float core = (1.0 - smoothstep(0.8, 0.8 + aa, abs(r.x - lane))) * reveal;
        float ca = (1.0 - smoothstep(0.8, 0.8 + aa, abs(sh_route(q - dir * s, a, b, c, d, e, h, g).x - lane))) * reveal;
        float cb = (1.0 - smoothstep(0.8, 0.8 + aa, abs(sh_route(q + dir * s, a, b, c, d, e, h, g).x - lane))) * reveal;
        float halo = (exp(-r.x * 0.25) + PHOSPHOR_BLOOM * exp(-r.x * 0.07)) * reveal * linger;
        float head = (age - ATTACK) * PACKET_SPEED;
        float packet = exp(-pow((r.y - head) / 10.0, 2.0)) * exp(-r.x * 0.3) * step(ATTACK, age);
        vec2 pe = q - e;
        vec2 pg = q - g;
        float ring = max(
            1.0 - smoothstep(0.7, 0.7 + aa, abs(max(abs(pe.x), abs(pe.y)) - padsize)),
            (1.0 - smoothstep(0.7, 0.7 + aa, abs(max(abs(pg.x), abs(pg.y)) - padsize))) * step(0.5, length(g - h)));
        ring *= step(total, drawn + 0.5);
        float arrive = exp(-pow((total - head) / 14.0, 2.0));
        acc.x = max(acc.x, max(core, ring) * k);
        acc.y += (packet + attack * core) * k;
        acc.z += halo * k;
        acc.w += ring * (0.4 + 1.2 * arrive) * k;
        ghost.x = max(ghost.x, max(ca - core, 0.0) * k);
        ghost.y = max(ghost.y, max(cb - core, 0.0) * k);
    }
}

vec4 window(vec2 coords) {
    float scale = max(umbriel_scale, 0.01);
    vec2 size = umbriel_size;
    vec2 p = coords * size;
    float t = umbriel_time;
    float aa = 1.0 / scale;
    // umbriel_time is shared by every window, so the size is the only per-window seed available.
    float seed = sh_hash(floor(size * scale) * 0.013 + 0.5);

    float tick = floor(t / STEP);
    float roll = sh_hash(vec2(tick, 5.3));
    float local = t + seed * FLINCH_PERIOD;
    float slot = floor(local / FLINCH_PERIOD);
    float into = local - slot * FLINCH_PERIOD;
    float start = floor(sh_hash(vec2(slot, seed * 91.0)) * floor((FLINCH_PERIOD - FLINCH_LEN) / STEP)) * STEP;
    float flinch = (into >= start && into < start + FLINCH_LEN
        && sh_hash(vec2(slot, 13.7 + seed)) < FLINCH_CHANCE) ? 1.0 : 0.0;
    // Audio drives it: level lifts the glow, bass pulses the current, treble widens the split. The flinch stays on its timer.
    float au = umbriel_audio_available();
    float lvl = au * clamp(max(umbriel_audio_rms(), 0.5 * umbriel_audio_level()) / 0.045, 0.0, 1.0);
    float bass = au_band(0.08);
    float treble = au_band(0.7);

    float tear_mid = sh_hash(vec2(tick, 43.0 + seed)) * size.y;
    float tear_half = 0.5 * mix(TEAR_MIN, TEAR_MAX, sh_hash(vec2(tick, 47.0 + seed))) * size.y;
    float tear = step(sh_hash(vec2(tick, 41.0 + seed)), TEAR_CHANCE)
        * step(abs(p.y - tear_mid), tear_half)
        * (sh_hash(vec2(tick, 53.0 + seed)) < 0.5 ? -1.0 : 1.0)
        * TEAR_PX * (0.5 + 0.5 * sh_hash(vec2(tick, 59.0 + seed)));

    vec2 uv = coords - vec2(flinch * tear / max(size.x, 1.0), 0.0);
    vec4 source = umbriel_sample(uv);

    // A zero count means the palette is off, which is how a shader keeps its own colours.
    bool pal = umbriel_palette_count > 0;
    vec3 trace = pal ? umbriel_palette_at(0.0).rgb : vec3(0.22, 1.0, 0.45);
    vec3 fringe_a = pal ? umbriel_palette_at(0.0).rgb : vec3(0.25, 0.9, 1.0);
    vec3 fringe_b = pal ? umbriel_palette_at(0.75).rgb : vec3(1.0, 0.22, 0.3);
    vec3 accent = pal
        ? umbriel_palette_at(roll < 0.5 ? 0.25 : 0.5).rgb
        : (roll < 0.5 ? vec3(0.3, 1.0, 0.4) : vec3(0.95, 0.85, 0.35));
    vec3 hot = mix(trace, vec3(1.0), 0.5);

    vec3 original = source.rgb / max(source.a, 0.0001);
    float lc = dot(original, LUMA);
    vec3 result = original;

    if (flinch > 0.5) {
        float dx = FLINCH_PX / max(size.x, 1.0);
        vec4 sa = umbriel_sample(uv - vec2(dx, 0.0));
        vec4 sb = umbriel_sample(uv + vec2(dx, 0.0));
        float la = dot(sa.rgb / max(sa.a, 0.0001), LUMA);
        float lb = dot(sb.rgb / max(sb.a, 0.0001), LUMA);
        result += fringe_a * max(la - lc, 0.0) + fringe_b * max(lb - lc, 0.0);
        result *= mix(vec3(1.0), fringe_a, clamp(lc - la, 0.0, 1.0));
        result *= mix(vec3(1.0), fringe_b, clamp(lc - lb, 0.0, 1.0));
    }

    float edge = min(min(p.x, p.y), min(size.x - p.x, size.y - p.y));
    if (edge < EDGE_BAND + 24.0 + TEAR_PX) {
        // Respawn spacing scales with the wiring so ACTIVE_TRACES holds on any window size.
        float wired = 2.0 * (size.x + size.y) / CELL * TRACE_CHANCE;
        float period = max(wired * LIFE / ACTIVE_TRACES, LIFE + 1.0);
        float split = (0.3 + 0.7 * roll) * SPLIT_PX * (1.0 + flinch + 3.0 * treble);
        vec2 pt = p - vec2(tear, 0.0);
        vec4 f = vec4(0.0);
        vec2 gh = vec2(0.0);
        sh_edge(pt, vec2(1.0, 0.0), size.x, 0.0, t, period, aa, split, f, gh);
        sh_edge(vec2(pt.x, size.y - pt.y), vec2(1.0, 0.0), size.x, 1.0, t, period, aa, split, f, gh);
        sh_edge(vec2(pt.y, pt.x), vec2(0.0, 1.0), size.y, 2.0, t, period, aa, split, f, gh);
        sh_edge(vec2(pt.y, size.x - pt.x), vec2(0.0, -1.0), size.y, 3.0, t, period, aa, split, f, gh);
        float breath = 0.85 + 0.15 * sin(t * BREATH_RATE);
        // Bright content keeps its contrast, so glow is held back where text already is.
        float protect = 1.0 - 0.7 * smoothstep(0.4, 0.95, lc);
        vec2 pin_cell = mod(p, PIN_PITCH) - 0.5 * PIN_PITCH;
        float pin = (1.0 - smoothstep(0.6, 0.6 + aa, length(pin_cell))) * min(f.z, 1.0) * PIN_STRENGTH;
        vec3 glow = trace * (f.z * 0.18 + pin) * breath
            + hot * f.y * 0.8
            + accent * f.w * breath
            + (fringe_a * gh.x + fringe_b * gh.y) * 0.8;
        result = mix(result, mix(trace, vec3(1.0), PHOSPHOR_CORE), min(f.x, 1.0) * 0.6 * TRACE_STRENGTH);
        result += glow * protect * TRACE_STRENGTH * (1.0 + 0.6 * flinch) * (0.5 + 2.0 * lvl);
    }

    float scan = 0.5 + 0.5 * sin(p.y * scale * 3.14159);
    result *= mix(1.0 - SCANLINE_DEPTH, 1.0, scan);
    float triad = mod(floor(p.x * scale), 3.0);
    vec3 grille = triad < 1.0 ? vec3(1.0, 0.5, 0.5) : (triad < 2.0 ? vec3(0.5, 1.0, 0.5) : vec3(0.5, 0.5, 1.0));
    result *= mix(vec3(1.0), grille, GRILLE_DEPTH);
    vec2 cc = coords - 0.5;
    result *= 1.0 - VIGNETTE * smoothstep(0.1, 0.5, dot(cc, cc));
    float sweep = exp(-pow((coords.y - (fract(t / ROLL_PERIOD) * 1.4 - 0.2)) / 0.06, 2.0));
    result += trace * sweep * ROLL_STRENGTH;
    result *= 1.0 + FLICKER * (sh_hash(vec2(floor(t * 30.0), 71.0)) - 0.5);

    return vec4(clamp(result, 0.0, 1.0) * source.a, source.a);
}
