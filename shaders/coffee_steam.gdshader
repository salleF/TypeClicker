shader_type canvas_item;

// Coffee Steam Shader - Silky rising organic steam distortion
uniform vec4 steam_color : source_color = vec4(0.99, 0.91, 0.84, 0.45);
uniform float speed : hint_range(0.1, 4.0) = 1.2;
uniform float wave_frequency : hint_range(1.0, 30.0) = 12.0;
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.035;

void fragment() {
    vec2 uv = UV;

    // Upward drift
    float time_drift = TIME * speed;

    // Horizontal sinusoidal wave distortion that expands as it rises
    float rise_factor = 1.0 - uv.y; // 0 at bottom, 1 at top
    float wave = sin(uv.y * wave_frequency - time_drift) * wave_amplitude * rise_factor;
    uv.x += wave;

    // Fade out at top and edges
    float alpha = sin(clamp(uv.x, 0.0, 1.0) * PI) * sin(clamp(uv.y, 0.0, 1.0) * PI);
    alpha *= (1.0 - (uv.y * 0.4)); // softer at top

    COLOR = vec4(steam_color.rgb, steam_color.a * alpha);
}
