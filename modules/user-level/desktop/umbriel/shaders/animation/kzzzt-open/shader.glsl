const float DURATION = 0.9; // seconds; must match [animation.windows_in] duration_ms
const float FPS = 30.0; // the surge steps in hard frames, never smoothly
const float STRIKE_FR = 3.0; // frame of the overexposed strike; nothing is drawn before it
const float PEAK = 0.36; // progress at which the surge crests and the tension starts to drain
const float SPLIT_PX = 9.0;
const float TEAR_PX = 60.0;
const float TEAR_MIN = 0.06; // fraction of the window height
const float TEAR_MAX = 0.35;
const float CELL = 56.0;
const float TRACE_CHANCE = 0.9;
const float EDGE_BAND = 64.0; // logical px
const float STAGGER = 0.08; // seconds; how far apart the traces catch after the strike
const float ATTACK = 0.14;
const float DECAY_RATE = 4.5;
const float FLICKER_HZ = 32.0;
const float JITTER_PX = 5.0;
const float TRACE_SPLIT_PX = 2.5;
const float ATTACK_SPLIT_PX = 6.0;
const float PACKET_SPEED = 180.0;
const float TRACE_STRENGTH = 0.9;
const float SURGE_GAIN = 1.5;
const float PHOSPHOR_HOLD = 0.45; // share of the line's decay the glow skips, so it outlives the line
const float PHOSPHOR_BLOOM = 0.35;
const float PHOSPHOR_CORE = 0.3; // how far the core burns toward white
const float PIN_PITCH = 6.0;
const float PIN_STRENGTH = 0.35;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

float ko_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ko_sq(float x) {
    return x * x;
}

vec3 ko_unpremul(vec4 c) {
    return c.rgb / max(c.a, 0.0001);
}

// Only what is already bright burns into the glow.
vec3 ko_bright(vec3 c) {
    return c * max(dot(c, LUMA) - 0.12, 0.0);
}

vec2 ko_segment(vec2 p, vec2 a, vec2 b) {
    vec2 v = b - a;
    float t = clamp(dot(p - a, v) / max(dot(v, v), 0.001), 0.0, 1.0);
    return vec2(length(p - a - t * v), t * length(v));
}

// Main route a-b-c-d-e plus one branch h-g; unused points collapse onto their neighbour.
void ko_trace(float cell, vec2 gk, float len, out vec2 a, out vec2 b, out vec2 c, out vec2 d, out vec2 e,
              out vec2 h, out vec2 g, out float lanes, out float pad) {
    float u0 = (cell + 0.2 + 0.6 * ko_hash(gk + 1.0)) * CELL;
    float d1 = 4.0 + ko_hash(gk + 2.0) * 22.0;
    float jog = 4.0 + ko_hash(gk + 3.0) * 16.0;
    float run = 10.0 + pow(ko_hash(gk + 4.0), 1.3) * 76.0;
    float side = ko_hash(gk + 5.0) < 0.5 ? -1.0 : 1.0;
    float kind = floor(ko_hash(gk + 6.0) * 5.0);
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
            h = mix(c, d, 0.3 + 0.4 * ko_hash(gk + 9.0));
            g = h + vec2(0.0, 3.0 + jog * 0.4);
        }
    }
    lanes = ko_hash(gk + 7.0) < 0.3 ? 2.0 : 1.0;
    pad = 1.5 + 2.0 * ko_hash(gk + 8.0);
}

// Distance to the route, and arc length along it from the root.
vec2 ko_route(vec2 p, vec2 a, vec2 b, vec2 c, vec2 d, vec2 e, vec2 h, vec2 g) {
    float lab = length(b - a);
    float lbc = length(c - b);
    float lcd = length(d - c);
    vec2 r = ko_segment(p, a, b);
    vec2 s = ko_segment(p, b, c);
    s.y += lab;
    r = s.x < r.x ? s : r;
    s = ko_segment(p, c, d);
    s.y += lab + lbc;
    r = s.x < r.x ? s : r;
    s = ko_segment(p, d, e);
    s.y += lab + lbc + lcd;
    r = s.x < r.x ? s : r;
    s = ko_segment(p, h, g);
    s.y += lab + lbc + length(h - c);
    return s.x < r.x ? s : r;
}

// q0 is (along the edge, depth inward); dir is screen +x in edge space. acc: core, current, halo, pad. ghost: split fringes.
void ko_edge(vec2 q0, vec2 dir, float len, float edge_id, float t, float aa, float split,
             inout vec4 acc, inout vec2 ghost) {
    if (q0.y > EDGE_BAND + 24.0) return;
    float cell = floor(q0.x / CELL);
    for (int i = -2; i <= 2; i++) {
        vec2 key = vec2(cell + float(i), edge_id * 17.0 + umbriel_random_seed.y * 50.0);
        if (ko_hash(key) > TRACE_CHANCE) continue;
        float age = t - STRIKE_FR / FPS - ko_hash(key + 3.1) * STAGGER;
        if (age < 0.0) continue;
        vec2 a, b, c, d, e, h, g;
        float lanes, padsize;
        ko_trace(key.x, key, len, a, b, c, d, e, h, g, lanes, padsize);
        float attack = 1.0 - smoothstep(ATTACK * 0.7, ATTACK, age);
        float flick = floor(age * FLICKER_HZ);
        // Phosphor never drops to black between flicker frames.
        float on = age < ATTACK ? mix(0.3, 1.0, step(0.35, ko_hash(key + vec2(flick, 21.0)))) : 1.0;
        float power = age < ATTACK ? 1.6 : exp(-(age - ATTACK) * DECAY_RATE);
        float k = on * power;
        float linger = age < ATTACK ? 1.0 : exp((age - ATTACK) * DECAY_RATE * PHOSPHOR_HOLD);
        vec2 q = q0 - vec2((ko_hash(key + vec2(flick, 33.0)) - 0.5) * 2.0 * JITTER_PX * attack, 0.0);
        float s = split + ATTACK_SPLIT_PX * attack;
        float lane = lanes > 1.5 ? 1.7 : 0.0;
        vec2 r = ko_route(q, a, b, c, d, e, h, g);
        float total = length(b - a) + length(c - b) + length(d - c) + length(e - d);
        total = max(total, length(b - a) + length(c - b) + length(h - c) + length(g - h));
        float drawn = total * smoothstep(0.0, ATTACK * 0.6, age);
        float reveal = 1.0 - smoothstep(drawn - 3.0, drawn, r.y);
        float core = (1.0 - smoothstep(0.8, 0.8 + aa, abs(r.x - lane))) * reveal;
        float ca = (1.0 - smoothstep(0.8, 0.8 + aa, abs(ko_route(q - dir * s, a, b, c, d, e, h, g).x - lane))) * reveal;
        float cb = (1.0 - smoothstep(0.8, 0.8 + aa, abs(ko_route(q + dir * s, a, b, c, d, e, h, g).x - lane))) * reveal;
        float halo = (exp(-r.x * 0.25) + PHOSPHOR_BLOOM * exp(-r.x * 0.07)) * reveal * linger;
        float head = (age - ATTACK) * PACKET_SPEED;
        float packet = exp(-ko_sq((r.y - head) / 10.0)) * exp(-r.x * 0.3) * step(ATTACK, age);
        vec2 pe = q - e;
        vec2 pg = q - g;
        float ring = max(
            1.0 - smoothstep(0.7, 0.7 + aa, abs(max(abs(pe.x), abs(pe.y)) - padsize)),
            (1.0 - smoothstep(0.7, 0.7 + aa, abs(max(abs(pg.x), abs(pg.y)) - padsize))) * step(0.5, length(g - h)));
        ring *= step(total, drawn + 0.5);
        float arrive = exp(-ko_sq((total - head) / 14.0));
        acc.x = max(acc.x, max(core, ring) * k);
        acc.y += (packet + attack * core) * k;
        acc.z += halo * k;
        acc.w += ring * (0.4 + 1.2 * arrive) * k;
        ghost.x = max(ghost.x, max(ca - core, 0.0) * k);
        ghost.y = max(ghost.y, max(cb - core, 0.0) * k);
    }
}

vec4 animation(vec2 uv) {
    float lp = clamp(umbriel_linear_progress, 0.0, 1.0);
    float t = lp * DURATION;
    float fr = floor(t * FPS);
    float tseed = umbriel_random_seed.z * 50.0;
    float roll = ko_hash(vec2(fr, umbriel_random_seed.x * 100.0));

    float live = step(STRIKE_FR, fr);
    float strike = live * (1.0 - step(STRIKE_FR + 1.0, fr));

    // Per-frame spikes and dips keep the surge from reading as a smooth ramp.
    float climb = pow(clamp(lp / PEAK, 0.0, 1.0), 1.5);
    float drain = exp(-max(lp - PEAK, 0.0) * 5.0) * (1.0 - smoothstep(0.8, 1.0, lp));
    float env = lp < PEAK ? mix(0.25, 1.0, climb) : drain;
    float spike = ko_hash(vec2(fr, tseed + 1.0));
    float surge = env * (spike < 0.14 ? 0.1 : 0.35 + 1.65 * spike) * live;
    float ten = max(clamp(surge, 0.0, 1.4), 0.9 * strike);
    float od = min(ten, 1.0);

    // A rising duty makes the picture stutter in instead of fading in.
    float duty = mix(0.4, 1.0, smoothstep(STRIKE_FR / (DURATION * FPS), 0.7 * PEAK, lp));
    float on = lp >= PEAK ? 1.0 : step(ko_hash(vec2(fr, tseed + 2.0)), duty);
    float vis = max(on * live, strike);

    // A zero count means the palette is off, which is how a shader keeps its own colours.
    bool pal = umbriel_palette_count > 0;
    vec3 trace = pal ? umbriel_palette_at(0.0).rgb : vec3(0.22, 1.0, 0.45);
    vec3 fringe_a = pal ? umbriel_palette_at(0.0).rgb : vec3(0.25, 0.9, 1.0);
    vec3 fringe_b = pal ? umbriel_palette_at(0.75).rgb : vec3(1.0, 0.22, 0.3);
    vec3 accent = pal
        ? umbriel_palette_at(roll < 0.5 ? 0.25 : 0.5).rgb
        : (roll < 0.5 ? vec3(0.3, 1.0, 0.4) : vec3(0.95, 0.85, 0.35));
    vec3 hot = mix(trace, vec3(1.0), 0.7);
    vec3 hot_trace = mix(trace, vec3(1.0), 0.5);

    float scale = max(umbriel_scale, 0.01);
    float aa = 1.0 / scale;
    vec2 size = umbriel_size;
    vec2 p = uv * size;

    float tear = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i) * 7.0;
        float mid = ko_hash(vec2(fr, 43.0 + fi + tseed)) * size.y;
        float half_band = 0.5 * mix(TEAR_MIN, TEAR_MAX, ko_hash(vec2(fr, 47.0 + fi + tseed))) * size.y;
        float band_on = i == 0 ? 1.0 : step(0.35, ko_hash(vec2(fr, 41.0 + fi + tseed)));
        tear += band_on * step(abs(p.y - mid), half_band)
            * (ko_hash(vec2(fr, 53.0 + fi + tseed)) < 0.5 ? -1.0 : 1.0)
            * TEAR_PX * ten * (0.4 + 0.6 * ko_hash(vec2(fr, 59.0 + fi + tseed))) * (1.0 + 2.0 * strike);
    }

    float strip_hot = step(0.5, ko_hash(vec2(floor(p.y / 48.0), fr + 5.0 + tseed)));
    float strip = (ko_hash(vec2(floor(p.y / 3.0), fr + tseed)) - 0.5) * 28.0 * strip_hot * ten * ten;
    vec2 tile = floor(p / vec2(64.0, 16.0));
    float hop = step(1.0 - 0.3 * ten, ko_hash(tile + vec2(fr, 17.0 + tseed)));
    float hop_x = floor((ko_hash(tile + vec2(fr, 18.0 + tseed)) - 0.5) * 6.0) * 64.0 * hop;
    vec2 shake = (vec2(ko_hash(vec2(fr, 81.0)), ko_hash(vec2(fr, 82.0))) - 0.5) * 12.0 / size * ten;
    vec2 suv = uv - vec2((tear - strip - hop_x) / max(size.x, 1.0), 0.0) + shake;

    vec4 base = umbriel_sample(suv);
    float shape = umbriel_sample(uv).a;
    vec3 original = ko_unpremul(base);
    float lc = dot(original, LUMA);

    float dx = (1.5 + SPLIT_PX * (0.4 + 1.6 * ten) * (0.35 + 0.65 * roll)) / size.x;
    float la = dot(ko_unpremul(umbriel_sample(suv - vec2(dx, 0.0))), LUMA);
    float lb = dot(ko_unpremul(umbriel_sample(suv + vec2(dx, 0.0))), LUMA);
    vec3 col = original;
    float fringe_amt = clamp(4.0 * ten, 0.0, 1.0);
    col += fringe_amt * (fringe_a * max(la - lc, 0.0) + fringe_b * max(lb - lc, 0.0));
    col *= mix(vec3(1.0), fringe_a, fringe_amt * clamp(lc - la, 0.0, 1.0));
    col *= mix(vec3(1.0), fringe_b, fringe_amt * clamp(lc - lb, 0.0, 1.0));

    col *= mix(1.0, 0.15 + 1.6 * ko_hash(vec2(fr, tseed + 3.0)), od);
    col = mix(col, trace * lc * 2.2, 0.55 * od);
    col = pow(max(col, vec3(0.0)), vec3(1.0 + 0.9 * od));

    vec3 glow = vec3(0.0);
    float seen = 0.0;
    float spread = 5.0 + 26.0 * clamp(surge, 0.0, 1.4) + 30.0 * strike;
    for (int i = 0; i < 12; i++) {
        float a = float(i) * 2.39996 + roll * 6.28318;
        float rad = spread * sqrt((float(i) + 0.5) / 12.0);
        vec3 c = ko_unpremul(umbriel_sample(suv + vec2(cos(a), sin(a)) * rad / size));
        glow += ko_bright(c);
        seen += dot(c, LUMA);
    }
    glow /= 12.0;
    // A mostly dark window has little to burn, so what it has burns harder; a bright one is held back.
    float exposure = 1.8 / (0.3 + 3.0 * seen / 12.0);

    vec3 bleed = vec3(0.0);
    for (int i = 1; i <= 6; i++) {
        float w = exp(-float(i) * 0.35);
        float o = float(i) * (2.0 + 6.0 * clamp(surge, 0.0, 1.4)) / size.x;
        bleed += w * (ko_bright(ko_unpremul(umbriel_sample(suv + vec2(o, 0.0)))) + ko_bright(ko_unpremul(umbriel_sample(suv - vec2(o, 0.0)))));
    }
    bleed *= 0.06;

    // The glow is the palette's, not the picture's, and it keeps burning on the frames the picture is out.
    vec3 lit = glow + bleed;
    vec3 phos = mix(lit, trace * dot(lit, vec3(1.0)) * 1.1, 0.7);
    float gain = 1.4 * exposure * ten * mix(0.4, 1.0, vis) * (1.0 + 1.5 * strike);

    col = col * (1.0 + 1.6 * strike) + hot * 0.25 * strike;

    // The traces draw on the frames where the picture is out too.
    float split = (0.3 + 0.7 * roll) * TRACE_SPLIT_PX * (1.0 + 3.0 * strike);
    vec2 pt = p - vec2(tear, 0.0);
    vec4 f = vec4(0.0);
    vec2 gh = vec2(0.0);
    ko_edge(pt, vec2(1.0, 0.0), size.x, 0.0, t, aa, split, f, gh);
    ko_edge(vec2(pt.x, size.y - pt.y), vec2(1.0, 0.0), size.x, 1.0, t, aa, split, f, gh);
    ko_edge(vec2(pt.y, pt.x), vec2(0.0, 1.0), size.y, 2.0, t, aa, split, f, gh);
    ko_edge(vec2(pt.y, size.x - pt.x), vec2(0.0, -1.0), size.y, 3.0, t, aa, split, f, gh);
    float protect = 1.0 - 0.7 * smoothstep(0.4, 0.95, lc);
    vec2 pin_cell = mod(p, PIN_PITCH) - 0.5 * PIN_PITCH;
    float pin = (1.0 - smoothstep(0.6, 0.6 + aa, length(pin_cell))) * min(f.z, 1.0) * PIN_STRENGTH;
    vec3 tglow = trace * (f.z * 0.18 + pin)
        + hot_trace * f.y * 0.8
        + accent * f.w
        + (fringe_a * gh.x + fringe_b * gh.y) * 0.8;
    vec3 tcore = mix(trace, vec3(1.0), PHOSPHOR_CORE) * min(f.x, 1.0) * 0.6;
    float fade = 1.0 - smoothstep(0.7, 1.0, lp);
    vec3 spark = (tcore + tglow * protect) * TRACE_STRENGTH * SURGE_GAIN * fade * shape;

    // Light piles up softly instead of clipping, so bright windows burn hot without turning to a white wall.
    vec3 emit = (vec3(1.0) - exp(-phos * gain)) * shape;
    float body_a = base.a * vis;
    vec3 rgb = clamp(col * body_a + emit + spark, 0.0, 1.0);
    float a = max(body_a, clamp(max(max(emit.r, max(emit.g, emit.b)), max(spark.r, max(spark.g, spark.b))), 0.0, 1.0));
    return vec4(min(rgb, vec3(a)), a);
}
