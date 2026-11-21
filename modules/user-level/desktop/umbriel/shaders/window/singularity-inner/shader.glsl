// The inside of the singularity disc, drawn over the window's edge as the border's overlay: the rim gradient and its boiling plasma, hue from the scheme.
// Logical px per ring px for the inside: a thin band that hugs the border and stays clear of the window's content.
const float K_SCALE = 0.12;
// Logical px per ring px along the edge: the plasma keeps the pattern size it had before the band was thinned.
const float TH_SCALE = 0.45;
const float CORNER_REF = 3.0;
const float QUARTER = 1.5708;
// Logical px over which the two edges' plasma is blended across a corner diagonal.
const float BLEND = 40.0;
// Ring px over which the rim's whiteness climbs to the limb's (0.278 at r = 0).
const float LIMB_SOFT = 6.0;
const float LIMB_W = 0.278;
// The corner match shared with the border shader.
const float CORNER_DIM = 0.81;
const float CORNER_R0 = 3.0;
const float CORNER_R1 = 8.0;
// Ring px per theta sample.
const float SAMPLE = 0.86488;
// Ring px in from the limb where the plasma has faded into the flat core.
const float DEPTH = 100.0;
// Ring px over which the plasma fades out at the inner end of the band.
const float FADE = 30.0;
// Cell size in theta samples and ring px, and seconds per unit of boil.
const float CELL_TH = 150.0;
const float CELL_R = 35.0;
const float BOIL = 0.65;
// Weights of the cell walls and the slow haze in the plasma swing.
const float WALL = 2.4;
const float HAZE = 2.4;
// Where a void's dark centre turns into its bright wall, in cell units, and the wall's mean so the swing stays centred.
const float EDGE_LO = 0.25;
const float EDGE_HI = 0.55;
const float WALL_MEAN = 0.74;
// Scale of the slow haze relative to the cells.
const float HAZE_SCALE = 0.5;
// How much of the plasma swing survives in the deep core.
const float DEEP = 0.3;
// The fine grain that changes frame to frame: size in theta samples and ring px, seconds per unit, weight.
const float DET_TH = 18.0;
const float DET_R = 7.0;
const float DET_T = 0.12;
const float DET = 1.7;
// Extra fast grain right at the limb, where it flickers hardest frame to frame.
const float LIMB_DET = 2.0;
const float SPEED = 1.0;

// A feed that is connected but silent counts as no feed, the same gate the border uses.
const float SILENCE_LOW = 0.02;
const float SILENCE_HIGH = 0.10;
// The same hit the cursor surges on: loudness or the lowest bass, whichever is stronger, from where it starts to where it is full, and how much further the band reaches on a full hit (the cursor's 9 to 15 px swell).
const float HIT0 = 0.05;
const float HIT1 = 0.5;
const float SURGE = 0.67;

float audio_level() {
    float sum = 0.0;
    for (int i = 0; i < 8; i++) {
        sum += umbriel_audio_spectrum((float(i) + 0.5) / 8.0);
    }
    return sum * 0.125;
}

float se_hash3(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float se_noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = mix(mix(se_hash3(i), se_hash3(i + vec3(1.0, 0.0, 0.0)), f.x), mix(se_hash3(i + vec3(0.0, 1.0, 0.0)), se_hash3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
    float b = mix(mix(se_hash3(i + vec3(0.0, 0.0, 1.0)), se_hash3(i + vec3(1.0, 0.0, 1.0)), f.x), mix(se_hash3(i + vec3(0.0, 1.0, 1.0)), se_hash3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
    return mix(a, b, f.z);
}

vec3 se_cell_point(vec3 c) {
    return vec3(se_hash3(c), se_hash3(c + 17.3), se_hash3(c + 41.9));
}

// Distance to the nearest of a jittered lattice of points, in cell units.
float se_worley(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    float d = 8.0;
    for (int z = -1; z <= 1; z++) {
        for (int y = -1; y <= 1; y++) {
            for (int x = -1; x <= 1; x++) {
                vec3 o = vec3(float(x), float(y), float(z));
                vec3 v = o + se_cell_point(i + o) - f;
                d = min(d, dot(v, v));
            }
        }
    }
    return sqrt(d);
}

// Dark round voids with soft bright walls between them, zero mean and about unit spread.
float se_plasma(float th, float r, float t) {
    vec3 p = vec3(th / CELL_TH, r / CELL_R, t / BOIL);
    vec3 w = vec3(se_noise3(p * 0.9 + 3.1), se_noise3(p * 0.9 + 7.7), 0.0) - 0.5;
    float wall = smoothstep(EDGE_LO, EDGE_HI, se_worley(p + 0.6 * w));
    float haze = se_noise3(p * HAZE_SCALE + 11.0);
    vec3 pd = vec3(th / DET_TH, r / DET_R, t / DET_T) + 0.5 * w;
    float det = se_noise3(pd) * 0.6 + se_noise3(pd * 2.03 + 5.0) * 0.4;
    return (wall - WALL_MEAN) * WALL + (haze - 0.5) * HAZE + (det - 0.5) * DET * (1.0 + LIMB_DET * smoothstep(-10.0, 0.0, r));
}

// The position along the client outline for a point inside the window, measured off one edge (0 top, 1 right, 2 bottom, 3 left), the same parametrisation and radii the border uses.
float se_outline_edge(float e, vec2 p, vec2 size) {
    vec4 r = umbriel_corner_radius;
    vec4 ra = r + vec4(CORNER_REF);
    float o1 = size.x - r.x - r.y;
    float o2 = o1 + QUARTER * ra.y;
    float o3 = o2 + size.y - r.y - r.z;
    float o4 = o3 + QUARTER * ra.z;
    float o5 = o4 + size.x - r.z - r.w;
    float o6 = o5 + QUARTER * ra.w;
    if (e < 0.5) return p.x - r.x;
    if (e < 1.5) return o2 + p.y - r.y;
    if (e < 2.5) return o4 + size.x - r.z - p.x;
    return o6 + size.y - r.w - p.y;
}

// The disc's brightness by ring px in from the limb.
float se_inner_v(float x) {
    if (x <= -100.0) return 0.10732;
    if (x < -98.0) return mix(0.10732, 0.10767, (x - -100.0) / 2.0);
    if (x < -96.0) return mix(0.10767, 0.10823, (x - -98.0) / 2.0);
    if (x < -94.0) return mix(0.10823, 0.10879, (x - -96.0) / 2.0);
    if (x < -92.0) return mix(0.10879, 0.10969, (x - -94.0) / 2.0);
    if (x < -90.0) return mix(0.10969, 0.11056, (x - -92.0) / 2.0);
    if (x < -88.0) return mix(0.11056, 0.11169, (x - -90.0) / 2.0);
    if (x < -86.0) return mix(0.11169, 0.11306, (x - -88.0) / 2.0);
    if (x < -84.0) return mix(0.11306, 0.11456, (x - -86.0) / 2.0);
    if (x < -82.0) return mix(0.11456, 0.11628, (x - -84.0) / 2.0);
    if (x < -80.0) return mix(0.11628, 0.11815, (x - -82.0) / 2.0);
    if (x < -78.0) return mix(0.11815, 0.12031, (x - -80.0) / 2.0);
    if (x < -76.0) return mix(0.12031, 0.12268, (x - -78.0) / 2.0);
    if (x < -74.0) return mix(0.12268, 0.1251, (x - -76.0) / 2.0);
    if (x < -72.0) return mix(0.1251, 0.1279, (x - -74.0) / 2.0);
    if (x < -70.0) return mix(0.1279, 0.1312, (x - -72.0) / 2.0);
    if (x < -68.0) return mix(0.1312, 0.13466, (x - -70.0) / 2.0);
    if (x < -66.0) return mix(0.13466, 0.13862, (x - -68.0) / 2.0);
    if (x < -64.0) return mix(0.13862, 0.14297, (x - -66.0) / 2.0);
    if (x < -62.0) return mix(0.14297, 0.14803, (x - -64.0) / 2.0);
    if (x < -60.0) return mix(0.14803, 0.15386, (x - -62.0) / 2.0);
    if (x < -58.0) return mix(0.15386, 0.16063, (x - -60.0) / 2.0);
    if (x < -56.0) return mix(0.16063, 0.16807, (x - -58.0) / 2.0);
    if (x < -54.0) return mix(0.16807, 0.17612, (x - -56.0) / 2.0);
    if (x < -52.0) return mix(0.17612, 0.18508, (x - -54.0) / 2.0);
    if (x < -50.0) return mix(0.18508, 0.19566, (x - -52.0) / 2.0);
    if (x < -48.0) return mix(0.19566, 0.20733, (x - -50.0) / 2.0);
    if (x < -46.0) return mix(0.20733, 0.22038, (x - -48.0) / 2.0);
    if (x < -44.0) return mix(0.22038, 0.23472, (x - -46.0) / 2.0);
    if (x < -42.0) return mix(0.23472, 0.25079, (x - -44.0) / 2.0);
    if (x < -40.0) return mix(0.25079, 0.26868, (x - -42.0) / 2.0);
    if (x < -38.0) return mix(0.26868, 0.28827, (x - -40.0) / 2.0);
    if (x < -36.0) return mix(0.28827, 0.31042, (x - -38.0) / 2.0);
    if (x < -34.0) return mix(0.31042, 0.3351, (x - -36.0) / 2.0);
    if (x < -32.0) return mix(0.3351, 0.36185, (x - -34.0) / 2.0);
    if (x < -30.0) return mix(0.36185, 0.39114, (x - -32.0) / 2.0);
    if (x < -28.0) return mix(0.39114, 0.42427, (x - -30.0) / 2.0);
    if (x < -26.0) return mix(0.42427, 0.46209, (x - -28.0) / 2.0);
    if (x < -24.0) return mix(0.46209, 0.50471, (x - -26.0) / 2.0);
    if (x < -22.0) return mix(0.50471, 0.5533, (x - -24.0) / 2.0);
    if (x < -20.0) return mix(0.5533, 0.60716, (x - -22.0) / 2.0);
    if (x < -18.0) return mix(0.60716, 0.66353, (x - -20.0) / 2.0);
    if (x < -16.0) return mix(0.66353, 0.72055, (x - -18.0) / 2.0);
    if (x < -14.0) return mix(0.72055, 0.77506, (x - -16.0) / 2.0);
    if (x < -12.0) return mix(0.77506, 0.82491, (x - -14.0) / 2.0);
    if (x < -10.0) return mix(0.82491, 0.86761, (x - -12.0) / 2.0);
    if (x < -8.0) return mix(0.86761, 0.90453, (x - -10.0) / 2.0);
    if (x < -6.0) return mix(0.90453, 0.93541, (x - -8.0) / 2.0);
    if (x < -4.0) return mix(0.93541, 0.95875, (x - -6.0) / 2.0);
    if (x < -2.0) return mix(0.95875, 0.96752, (x - -4.0) / 2.0);
    if (x < 0.0) return mix(0.96752, 0.96638, (x - -2.0) / 2.0);
    return 0.96638;
}

// How hard the plasma swings at that depth.
float se_inner_sd(float x) {
    if (x <= -100.0) return 0.043978;
    if (x < -98.0) return mix(0.043978, 0.044565, (x - -100.0) / 2.0);
    if (x < -96.0) return mix(0.044565, 0.045298, (x - -98.0) / 2.0);
    if (x < -94.0) return mix(0.045298, 0.045811, (x - -96.0) / 2.0);
    if (x < -92.0) return mix(0.045811, 0.046528, (x - -94.0) / 2.0);
    if (x < -90.0) return mix(0.046528, 0.047191, (x - -92.0) / 2.0);
    if (x < -88.0) return mix(0.047191, 0.048258, (x - -90.0) / 2.0);
    if (x < -86.0) return mix(0.048258, 0.049069, (x - -88.0) / 2.0);
    if (x < -84.0) return mix(0.049069, 0.050217, (x - -86.0) / 2.0);
    if (x < -82.0) return mix(0.050217, 0.051189, (x - -84.0) / 2.0);
    if (x < -80.0) return mix(0.051189, 0.052404, (x - -82.0) / 2.0);
    if (x < -78.0) return mix(0.052404, 0.053945, (x - -80.0) / 2.0);
    if (x < -76.0) return mix(0.053945, 0.055404, (x - -78.0) / 2.0);
    if (x < -74.0) return mix(0.055404, 0.056949, (x - -76.0) / 2.0);
    if (x < -72.0) return mix(0.056949, 0.058417, (x - -74.0) / 2.0);
    if (x < -70.0) return mix(0.058417, 0.06012, (x - -72.0) / 2.0);
    if (x < -68.0) return mix(0.06012, 0.061467, (x - -70.0) / 2.0);
    if (x < -66.0) return mix(0.061467, 0.062951, (x - -68.0) / 2.0);
    if (x < -64.0) return mix(0.062951, 0.06482, (x - -66.0) / 2.0);
    if (x < -62.0) return mix(0.06482, 0.067255, (x - -64.0) / 2.0);
    if (x < -60.0) return mix(0.067255, 0.069768, (x - -62.0) / 2.0);
    if (x < -58.0) return mix(0.069768, 0.073168, (x - -60.0) / 2.0);
    if (x < -56.0) return mix(0.073168, 0.076606, (x - -58.0) / 2.0);
    if (x < -54.0) return mix(0.076606, 0.080601, (x - -56.0) / 2.0);
    if (x < -52.0) return mix(0.080601, 0.085076, (x - -54.0) / 2.0);
    if (x < -50.0) return mix(0.085076, 0.091113, (x - -52.0) / 2.0);
    if (x < -48.0) return mix(0.091113, 0.098206, (x - -50.0) / 2.0);
    if (x < -46.0) return mix(0.098206, 0.1064, (x - -48.0) / 2.0);
    if (x < -44.0) return mix(0.1064, 0.11521, (x - -46.0) / 2.0);
    if (x < -42.0) return mix(0.11521, 0.12424, (x - -44.0) / 2.0);
    if (x < -40.0) return mix(0.12424, 0.13364, (x - -42.0) / 2.0);
    if (x < -38.0) return mix(0.13364, 0.14268, (x - -40.0) / 2.0);
    if (x < -36.0) return mix(0.14268, 0.15175, (x - -38.0) / 2.0);
    if (x < -34.0) return mix(0.15175, 0.16015, (x - -36.0) / 2.0);
    if (x < -32.0) return mix(0.16015, 0.16807, (x - -34.0) / 2.0);
    if (x < -30.0) return mix(0.16807, 0.17518, (x - -32.0) / 2.0);
    if (x < -28.0) return mix(0.17518, 0.18203, (x - -30.0) / 2.0);
    if (x < -26.0) return mix(0.18203, 0.18745, (x - -28.0) / 2.0);
    if (x < -24.0) return mix(0.18745, 0.18891, (x - -26.0) / 2.0);
    if (x < -22.0) return mix(0.18891, 0.1859, (x - -24.0) / 2.0);
    if (x < -20.0) return mix(0.1859, 0.17895, (x - -22.0) / 2.0);
    if (x < -18.0) return mix(0.17895, 0.16768, (x - -20.0) / 2.0);
    if (x < -16.0) return mix(0.16768, 0.15338, (x - -18.0) / 2.0);
    if (x < -14.0) return mix(0.15338, 0.13666, (x - -16.0) / 2.0);
    if (x < -12.0) return mix(0.13666, 0.11867, (x - -14.0) / 2.0);
    if (x < -10.0) return mix(0.11867, 0.099545, (x - -12.0) / 2.0);
    if (x < -8.0) return mix(0.099545, 0.080955, (x - -10.0) / 2.0);
    if (x < -6.0) return mix(0.080955, 0.062755, (x - -8.0) / 2.0);
    if (x < -4.0) return mix(0.062755, 0.045718, (x - -6.0) / 2.0);
    if (x < -2.0) return mix(0.045718, 0.032845, (x - -4.0) / 2.0);
    if (x < 0.0) return mix(0.032845, 0.038402, (x - -2.0) / 2.0);
    return 0.038402;
}

// The rim's whiteness, min channel over max.
float se_inner_w(float x) {
    if (x <= -100.0) return 0.0054114;
    if (x < -98.0) return mix(0.0054114, 0.0053969, (x - -100.0) / 2.0);
    if (x < -96.0) return mix(0.0053969, 0.0055499, (x - -98.0) / 2.0);
    if (x < -94.0) return mix(0.0055499, 0.0054973, (x - -96.0) / 2.0);
    if (x < -92.0) return mix(0.0054973, 0.0051971, (x - -94.0) / 2.0);
    if (x < -90.0) return mix(0.0051971, 0.005038, (x - -92.0) / 2.0);
    if (x < -88.0) return mix(0.005038, 0.0050036, (x - -90.0) / 2.0);
    if (x < -86.0) return mix(0.0050036, 0.0048811, (x - -88.0) / 2.0);
    if (x < -84.0) return mix(0.0048811, 0.0047842, (x - -86.0) / 2.0);
    if (x < -82.0) return mix(0.0047842, 0.0046989, (x - -84.0) / 2.0);
    if (x < -80.0) return mix(0.0046989, 0.0044424, (x - -82.0) / 2.0);
    if (x < -78.0) return mix(0.0044424, 0.0045554, (x - -80.0) / 2.0);
    if (x < -76.0) return mix(0.0045554, 0.0048168, (x - -78.0) / 2.0);
    if (x < -74.0) return mix(0.0048168, 0.004944, (x - -76.0) / 2.0);
    if (x < -72.0) return mix(0.004944, 0.0052513, (x - -74.0) / 2.0);
    if (x < -70.0) return mix(0.0052513, 0.0054444, (x - -72.0) / 2.0);
    if (x < -68.0) return mix(0.0054444, 0.0057363, (x - -70.0) / 2.0);
    if (x < -66.0) return mix(0.0057363, 0.0056428, (x - -68.0) / 2.0);
    if (x < -64.0) return mix(0.0056428, 0.0057478, (x - -66.0) / 2.0);
    if (x < -62.0) return mix(0.0057478, 0.0064244, (x - -64.0) / 2.0);
    if (x < -60.0) return mix(0.0064244, 0.0067692, (x - -62.0) / 2.0);
    if (x < -58.0) return mix(0.0067692, 0.0071148, (x - -60.0) / 2.0);
    if (x < -56.0) return mix(0.0071148, 0.0074003, (x - -58.0) / 2.0);
    if (x < -54.0) return mix(0.0074003, 0.0075747, (x - -56.0) / 2.0);
    if (x < -52.0) return mix(0.0075747, 0.0076582, (x - -54.0) / 2.0);
    if (x < -50.0) return mix(0.0076582, 0.0077529, (x - -52.0) / 2.0);
    if (x < -48.0) return mix(0.0077529, 0.0082712, (x - -50.0) / 2.0);
    if (x < -46.0) return mix(0.0082712, 0.008913, (x - -48.0) / 2.0);
    if (x < -44.0) return mix(0.008913, 0.0092593, (x - -46.0) / 2.0);
    if (x < -42.0) return mix(0.0092593, 0.0097527, (x - -44.0) / 2.0);
    if (x < -40.0) return mix(0.0097527, 0.010244, (x - -42.0) / 2.0);
    if (x < -38.0) return mix(0.010244, 0.010832, (x - -40.0) / 2.0);
    if (x < -36.0) return mix(0.010832, 0.011632, (x - -38.0) / 2.0);
    if (x < -34.0) return mix(0.011632, 0.012625, (x - -36.0) / 2.0);
    if (x < -32.0) return mix(0.012625, 0.013558, (x - -34.0) / 2.0);
    if (x < -30.0) return mix(0.013558, 0.014322, (x - -32.0) / 2.0);
    if (x < -28.0) return mix(0.014322, 0.015463, (x - -30.0) / 2.0);
    if (x < -26.0) return mix(0.015463, 0.016906, (x - -28.0) / 2.0);
    if (x < -24.0) return mix(0.016906, 0.018091, (x - -26.0) / 2.0);
    if (x < -22.0) return mix(0.018091, 0.02018, (x - -24.0) / 2.0);
    if (x < -20.0) return mix(0.02018, 0.02269, (x - -22.0) / 2.0);
    if (x < -18.0) return mix(0.02269, 0.025296, (x - -20.0) / 2.0);
    if (x < -16.0) return mix(0.025296, 0.029613, (x - -18.0) / 2.0);
    if (x < -14.0) return mix(0.029613, 0.034057, (x - -16.0) / 2.0);
    if (x < -12.0) return mix(0.034057, 0.039442, (x - -14.0) / 2.0);
    if (x < -10.0) return mix(0.039442, 0.045372, (x - -12.0) / 2.0);
    if (x < -8.0) return mix(0.045372, 0.052984, (x - -10.0) / 2.0);
    if (x < -6.0) return mix(0.052984, 0.062727, (x - -8.0) / 2.0);
    if (x < -4.0) return mix(0.062727, 0.073767, (x - -6.0) / 2.0);
    if (x < -2.0) return mix(0.073767, 0.091905, (x - -4.0) / 2.0);
    if (x < 0.0) return mix(0.091905, 0.27851, (x - -2.0) / 2.0);
    return 0.27851;
}

vec3 se_base() {
    return umbriel_palette_count > 0 ? umbriel_palette_at(0.0).rgb : vec3(1.0, 0.165, 0.133);
}

vec3 se_colour(float v, float w, vec3 base) {
    float hi = max(base.r, max(base.g, base.b));
    float lo = min(base.r, min(base.g, base.b));
    vec3 hue = hi - lo > 0.001 ? (base - lo) / (hi - lo) : vec3(1.0);
    float wp = hi > 0.001 ? lo / hi : 1.0;
    float wo = 1.0 - (1.0 - w) * (1.0 - wp);
    return v * mix(hue, vec3(1.0), wo);
}

vec4 window(vec2 uv) {
    vec4 src = umbriel_sample(uv);
    vec2 size = umbriel_size;
    vec2 p = uv * size;
    // Depth in from the window's rounded edge, where every contour is the outline pulled inward with the window's own corner radius, so corners stay round instead of creasing.
    vec2 pc = p - 0.5 * size;
    vec4 cr = umbriel_corner_radius;
    float rc = pc.y < 0.0 ? (pc.x < 0.0 ? cr.x : cr.y) : (pc.x < 0.0 ? cr.w : cr.z);
    vec2 q = min(p, size - p);
    float dq = q.x - q.y;
    float din = abs(dq) < rc ? 0.5 * (q.x + q.y + sqrt(2.0 * rc * rc - dq * dq)) - rc : min(q.x, q.y);
    if (din < 0.0) return src;
    vec4 ed = vec4(p.y, size.x - p.x, size.y - p.y, p.x);
    float e1 = 0.0; float m1 = ed.x;
    if (ed.y < m1) { e1 = 1.0; m1 = ed.y; }
    if (ed.z < m1) { e1 = 2.0; m1 = ed.z; }
    if (ed.w < m1) { e1 = 3.0; m1 = ed.w; }
    float t = umbriel_time * SPEED;
    // The same spectrum layout as the border and cursor: bass along the top, treble along the bottom.
    float lvl0 = audio_level();
    float au = umbriel_audio_available() * smoothstep(SILENCE_LOW, SILENCE_HIGH, lvl0);
    float bl = au * umbriel_audio_spectrum(0.85 * clamp(p.y / max(size.y, 1.0), 0.0, 1.0));
    float lvl = au * lvl0;
    float bass = au * umbriel_audio_spectrum(0.08);
    // The band reaches deeper with the spectrum under it and bass, and brightens with loudness, like the corona outside.
    float lift = 1.0 + au * (0.3 + 0.9 * bl + 0.6 * bass) + SURGE * smoothstep(HIT0, HIT1, au * max(lvl0, umbriel_audio_spectrum(0.05)));
    float flare = mix(1.0, 0.9 + 0.5 * lvl, au);
    float r = -din / K_SCALE / lift;
    if (r < -DEPTH || din < 0.0) return src;
    // The two nearest edges each carry their own run of plasma; they are blended across the corner diagonal so it has no seam.
    float e2 = mod(e1 + 1.0, 4.0); float m2 = e2 < 0.5 ? ed.x : (e2 < 1.5 ? ed.y : (e2 < 2.5 ? ed.z : ed.w));
    float e3 = mod(e1 + 3.0, 4.0); float m3 = e3 < 0.5 ? ed.x : (e3 < 1.5 ? ed.y : (e3 < 2.5 ? ed.z : ed.w));
    if (m3 < m2) { e2 = e3; m2 = m3; }
    float k1 = 1.0 / (SAMPLE * TH_SCALE);
    float bw = smoothstep(0.0, BLEND, m2 - m1);
    float pl = se_plasma(se_outline_edge(e1, p, size) * k1, r, t);
    // Past BLEND from the diagonal the second edge carries no weight, so its plasma is only run near a corner.
    if (bw < 1.0) pl = mix(se_plasma(se_outline_edge(e2, p, size) * k1, r, t), pl, 0.5 + 0.5 * bw);
    // The unit-spread plasma overshoots the fitted swing in the deep core, so it is eased off there.
    float v = se_inner_v(r) + se_inner_sd(r) * pl * mix(1.0, DEEP, 1.0 - smoothstep(-65.0, -35.0, r));
    v = clamp(v, 0.0, 1.0);
    // The plasma is added as light over the window rather than painted over it, so the window stays readable through it.
    float a = smoothstep(-DEPTH, -DEPTH + FADE, r);
    // Whiteness climbs toward the plateau's as it nears the limb, meeting the border's ramp halfway.
    float wl = mix(se_inner_w(r), LIMB_W, smoothstep(-LIMB_SOFT, 0.0, r));
    vec3 c = min(se_colour(v, wl, se_base()) * flare, vec3(1.0)) * a;
    // The same corner match as the border: whole pixels round the corner come down to what the antialiased ones can show.
    vec2 qe = abs(pc) - 0.5 * size + vec2(rc);
    float edge = length(max(qe, 0.0)) + min(max(qe.x, qe.y), 0.0) - rc;
    c *= abs(edge) < 0.45 ? 1.0 : mix(CORNER_DIM, 1.0, smoothstep(CORNER_R0, CORNER_R1, length(q)));
    return vec4(min(src.rgb + c, vec3(1.0)), src.a);
}
