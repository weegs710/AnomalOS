vec4 animation(vec2 uv) {
  float shown = umbriel_direction > 0.0 ? umbriel_clamped_progress : 1.0 - umbriel_clamped_progress;
  vec2 from = vec2(uv.x, uv.y + 1.0 - shown);
  return from.y > 1.0 ? vec4(0.0) : umbriel_sample(from);
}
