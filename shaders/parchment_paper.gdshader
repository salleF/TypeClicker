shader_type canvas_item;

// Parchment Paper Shader - Procedural paper grain texture and aged edges
uniform vec4 base_color : source_color = vec4(0.99, 0.91, 0.84, 1.0);
uniform vec4 aged_edge_color : source_color = vec4(0.85, 0.72, 0.58, 1.0);
uniform float grain_strength : hint_range(0.0, 0.15) = 0.04;
uniform float vignette_power : hint_range(0.0, 3.0) = 1.2;

float pseudo_noise(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;

    // Procedural noise for paper fibers
    float n1 = pseudo_noise(uv * 180.0);
    float n2 = pseudo_noise(uv * 320.0 + vec2(43.0, 17.0));
    float grain = (n1 * 0.6 + n2 * 0.4) * grain_strength;

    // Vignette from edges (aged paper look)
    vec2 d = abs(uv - vec2(0.5)) * 2.0;
    float edge_factor = pow(length(d) * 0.7, vignette_power);
    edge_factor = clamp(edge_factor, 0.0, 1.0);

    vec4 final_color = mix(base_color, aged_edge_color, edge_factor);
    final_color.rgb += vec3(grain - (grain_strength * 0.5));

    COLOR = final_color;
}
