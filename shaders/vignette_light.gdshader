shader_type canvas_item;

// Cozy Cafe Ambient Vignette & Warm Lamp Glow
uniform vec4 vignette_color : source_color = vec4(0.18, 0.08, 0.07, 0.55);
uniform vec4 warm_glow_color : source_color = vec4(0.98, 0.69, 0.58, 0.15);
uniform float inner_radius : hint_range(0.0, 1.0) = 0.35;
uniform float outer_radius : hint_range(0.5, 2.0) = 1.1;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);

    float vignette = smoothstep(inner_radius, outer_radius, dist);
    vec4 col = mix(warm_glow_color, vignette_color, vignette);

    COLOR = col;
}
