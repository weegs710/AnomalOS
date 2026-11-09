// Falloffs are read off the clip (1080p), the hue is the colour scheme's red, px are logical px at scale 1.
// Logical px outward from the client edge where the ring peaks; everything inside is the disc's red rim.
const float RIM_D = 1.5;
// Reach with no audio, and the most the corona can flare to; REACH must stay under border width + padding.
const float IDLE_REACH = 15.0;
const float REACH = 24.0;
const float HAIR_CAP = 17.0;
const float TUFT_CAP = 21.0;
// A feed that is connected but silent counts as no feed, so the effect keeps its idle look.
const float SILENCE_LOW = 0.02;
const float SILENCE_HIGH = 0.10;
// Fine hairs round the ring.
const float HAIR_CELL = 3.4;
const float HAIR_H = 10.0;
const float HAIR_W = 2.1;
// Blunt tufts that all swell and fall back together on a ~4 s breath.
const float TUFT_CELL = 22.0;
const float TUFT_H = 13.0;
const float TUFT_W = 4.6;
const float BREATH = 4.0;
// Slows or speeds every flicker together.
const float SPEED = 1.0;
// Extra radius used to space hairs round a corner, so they fan out instead of bunching.
const float CORNER_REF = 3.0;
const float QUARTER = 1.5708;

// The spectrum has no single level, so the gate and the loudness scale use its mean over eight evenly spaced bands.
float audio_level() {
    float sum = 0.0;
    for (int i = 0; i < 8; i++) {
        sum += umbriel_audio_spectrum((float(i) + 0.5) / 8.0);
    }
    return sum * 0.125;
}

float audio_live() {
    return umbriel_audio_available() * smoothstep(SILENCE_LOW, SILENCE_HIGH, audio_level());
}

float au_band(float pos) {
    return audio_live() * umbriel_audio_spectrum(pos);
}

float se_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth value noise along one axis, 0 to 1.
float se_vn(float x, float seed) {
    float i = floor(x);
    float f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(se_hash(vec2(i, seed)), se_hash(vec2(i + 1.0, seed)), f);
}

// Smooth value noise on a plane, 0 to 1.
float se_n2(vec2 p, float seed) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    vec2 o = vec2(seed * 7.13, seed * 3.71);
    return mix(mix(se_hash(i + o), se_hash(i + vec2(1.0, 0.0) + o), f.x), mix(se_hash(i + vec2(0.0, 1.0) + o), se_hash(i + vec2(1.0, 1.0) + o), f.x), f.y);
}

// The shape works in logical px from the client's top-left, so the prelude's uv distance is mapped back to that frame.
float ring_distance(vec2 p) {
    return umbriel_border_distance(umbriel_border_hole.xy + p / umbriel_size);
}

// x: position along the client outline (clockwise from the end of the top-left corner), y: outline length.
// Corners are measured by angle so hairs fan out of them rather than smearing across a wedge.
vec2 se_outline(vec2 p, vec2 size) {
    vec4 r = umbriel_border_radius;
    vec4 ra = r + vec4(CORNER_REF);
    float o1 = size.x - r.x - r.y;
    float o2 = o1 + QUARTER * ra.y;
    float o3 = o2 + size.y - r.y - r.z;
    float o4 = o3 + QUARTER * ra.z;
    float o5 = o4 + size.x - r.z - r.w;
    float o6 = o5 + QUARTER * ra.w;
    float o7 = o6 + size.y - r.w - r.x;
    float perim = o7 + QUARTER * ra.x;

    float s;
    if (p.x < r.x && p.y < r.x) {
        vec2 v = p - vec2(r.x);
        s = o7 + clamp(atan(-v.y, -v.x), 0.0, QUARTER) * ra.x;
    } else if (p.x > size.x - r.y && p.y < r.y) {
        vec2 v = p - vec2(size.x - r.y, r.y);
        s = o1 + clamp(atan(v.x, -v.y), 0.0, QUARTER) * ra.y;
    } else if (p.x > size.x - r.z && p.y > size.y - r.z) {
        vec2 v = p - vec2(size.x - r.z, size.y - r.z);
        s = o3 + clamp(atan(v.y, v.x), 0.0, QUARTER) * ra.z;
    } else if (p.x < r.w && p.y > size.y - r.w) {
        vec2 v = p - vec2(r.w, size.y - r.w);
        s = o5 + clamp(atan(-v.x, v.y), 0.0, QUARTER) * ra.w;
    } else {
        vec2 inset = vec2(max(-p.x, p.x - size.x), max(-p.y, p.y - size.y));
        if (inset.y > inset.x) {
            s = p.y < 0.0 ? p.x - r.x : o4 + size.x - r.z - p.x;
        } else {
            s = p.x > size.x ? o2 + p.y - r.y : o6 + size.y - r.w - p.y;
        }
    }
    return vec2(s, perim);
}

// One layer of tapered spikes, one per cell round the outline. x: coverage, y: 1 at the base and 0 at the tip.
vec2 se_spikes(float s, float d, float perim, float cell, float h_max, float lift, float cap, float w_base, float chance, float breath, float tip, float seed, float t, float aa) {
    float n = max(floor(perim / cell + 0.5), 1.0);
    float cw = perim / n;
    float idx0 = floor(s / cw);
    vec2 acc = vec2(0.0);
    for (int k = -1; k <= 1; k++) {
        float idx = idx0 + float(k);
        float id = mod(idx, n);
        vec2 key = vec2(id, seed);
        if (se_hash(key) > chance) continue;

        float life = se_vn(t * (0.55 + 0.45 * se_hash(key + 1.0)) + 17.0 * se_hash(key + 2.0), id + seed);
        float flick = se_vn(t * (3.5 + 3.0 * se_hash(key + 3.0)) + 29.0 * se_hash(key + 4.0), id * 1.7 + seed);
        // breath is how much of the height follows the shared swell instead of the cell's own life
        float swell = 0.5 + 0.5 * cos(6.2832 * (t / BREATH + 0.18 * se_hash(key + 10.0)));
        float live = mix(smoothstep(0.0, 0.5, life), 0.3 + 0.7 * smoothstep(0.2, 0.9, swell), breath);
        float hgt = min(h_max * lift * (0.55 + 0.45 * se_hash(key + 5.0)) * live * (0.8 + 0.4 * flick), cap);
        if (d >= hgt) continue;
        float u = d / hgt;

        float drift = (se_vn(t * 0.5 + 11.0 * se_hash(key + 6.0), id + seed + 3.0) - 0.5) * 0.5 * cw;
        float lean = (se_vn(t * 1.4 + 7.0 * se_hash(key + 7.0), id + seed + 5.0) - 0.5) * 2.0 * w_base;
        float center = (idx + 0.2 + 0.6 * se_hash(key + 9.0)) * cw + drift + lean * u;
        float w = w_base * pow(max(1.0 - u, 0.0001), tip);
        float cov = 1.0 - smoothstep(w - aa, w + aa, abs(s - center));
        acc.x = max(acc.x, cov);
        acc.y = max(acc.y, cov * (1.0 - u));
    }
    return acc;
}

// The palette's first colour is accent_primary.
vec3 se_base() {
    return umbriel_palette_count > 0 ? umbriel_palette_at(0.0).rgb : vec3(1.0, 0.165, 0.133);
}

// 0 is deep red, 0.5 the scheme red, 1 the hot core.
vec3 se_ramp(float h, vec3 base) {
    vec3 hot = mix(base, vec3(1.0), 0.14);
    return h < 0.5 ? mix(base * 0.3, base, h * 2.0) : mix(base, hot, h * 2.0 - 1.0);
}

// Heat one px apart, read off the clip's brightness, so the table follows the clip's falloff.
float se_inner(float x) {
    float h = 1.0;
    h = mix(h, 0.86, clamp(x, 0.0, 1.0));
    h = mix(h, 0.5, clamp(x - 1.0, 0.0, 1.0));
    h = mix(h, 0.28, clamp(x - 2.0, 0.0, 1.0));
    return h;
}

float se_outer(float x) {
    float h = 1.0;
    h = mix(h, 0.8, clamp(x, 0.0, 1.0));
    h = mix(h, 0.56, clamp(x - 1.0, 0.0, 1.0));
    h = mix(h, 0.4, clamp(x - 2.0, 0.0, 1.0));
    return h;
}

vec4 border(vec2 uv) {
    vec2 coords = (uv - umbriel_border_hole.xy) * umbriel_size;
    vec2 size = umbriel_border_hole.zw * umbriel_size;
    float d = ring_distance(coords);
    if (d < -1.0 || d > REACH) return vec4(0.0);

    float au = audio_live();
    float reach = mix(IDLE_REACH, REACH, au);
    if (d > reach) return vec4(0.0);

    float t = umbriel_time * SPEED;
    vec2 o = se_outline(coords, size);
    float s = o.x;
    // The same spectrum layout as kzzzt-ring: bass at the start of the outline, rising to the middle and mirrored back.
    float bl = au_band(0.85 * (1.0 - abs(2.0 * clamp(s / max(o.y, 1.0), 0.0, 1.0) - 1.0)));
    float lvl = au * audio_level();
    float bass = au_band(0.08);
    float treble = au_band(0.7);

    vec3 base = se_base();
    vec3 hot = mix(base, vec3(1.0), 0.22);
    float side = d - RIM_D;
    // The ring is beaded: bright blobs crawl round it.
    float bead = 0.9 + 0.1 * se_vn(s / 40.0 + t * 0.3, 8.0);
    float knot = smoothstep(0.35, 1.0, se_n2(vec2(s / 5.0 - t * 1.2, 0.5), 5.0)) * (1.0 + 0.7 * treble);
    float core = exp(-side * side / 2.0);
    float flare = mix(1.0, 0.9 + 0.5 * lvl, au);
    vec3 c;
    float a;
    if (side <= 0.0) {
        float x = -side;
        // Plasma streams along inside the ring, bright against deep red.
        vec2 pp = vec2(s / 8.0 - t * 0.7 + x * 0.3, x / 2.2);
        float wisp = smoothstep(0.3, 0.75, 0.6 * se_n2(pp, 1.0) + 0.4 * se_n2(pp * 2.3 + vec2(-t * 0.9, 0.0), 2.0));
        c = se_ramp(se_inner(x), base) * mix(1.0, 0.78 + 0.45 * wisp, smoothstep(0.0, 2.0, x));
        c = mix(c, mix(base, hot, 0.5), wisp * 0.55 * (1.0 - x / 1.5));
        c = mix(c, hot, min(knot * core * 0.55, 1.0));
        c = min(c * flare, vec3(1.0));
        a = 1.0;
    } else {
        // Bass pushes the glow out from the ring.
        c = se_ramp(se_outer(side), base) * exp(-max(side - 2.0, 0.0) / (2.2 + 3.0 * bass));
        c = mix(c, hot, min(knot * core * 0.55, 1.0));
        float fade = smoothstep(reach, reach - 2.5, d);
        // The hairs and tufts grow out of the ring and cool as they go; the spectrum under each stretches them.
        float hair_lift = 1.0 + au * (0.3 + 0.9 * bl);
        float tuft_lift = 1.0 + au * (0.4 + 1.2 * clamp(bass + 0.5 * bl, 0.0, 1.0));
        vec2 hair = se_spikes(s, side, o.y, HAIR_CELL, HAIR_H, hair_lift, HAIR_CAP, HAIR_W, mix(0.9, 1.0, au), 0.0, 0.8, 1.0, t, 0.8);
        vec2 tuft = se_spikes(s, side, o.y, TUFT_CELL, TUFT_H, tuft_lift, TUFT_CAP, TUFT_W, mix(0.8, 1.0, au), 1.0, 0.55, 2.0, t, 2.0);
        vec3 hc = mix(base * 0.5, mix(base, hot, 0.5), hair.y);
        vec3 tc = mix(base * 0.55, mix(base, hot, 0.65), tuft.y);
        c = max(c, max(hc * hair.x, tc * tuft.x));
        c = min(c * flare, vec3(1.0)) * fade;
        a = max(c.r, max(c.g, c.b));
    }
    c *= bead;
    return vec4(c, a);
}
