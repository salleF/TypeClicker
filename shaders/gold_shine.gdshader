shader_type canvas_item;

// Gold Shine Shader - Diagonal gleaming shimmer ray across cards and book covers
uniform vec4 shine_color : source_color = vec4(1.0, 0.95, 0.7, 0.6);
uniform float shine_speed : hint_range(0.1, 5.0) = 1.0;
uniform float shine_width : hint_range(0.01, 0.5) = 0.12;
uniform float pause_duration : hint_range(0.5, 6.0) = 3.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Diagonal coordinate
    float diag = (UV.x + UV.y) * 0.5;

    // Cycle with pause
    float cycle_time = mod(TIME * shine_speed, pause_duration);
    float beam_pos = cycle_time; // moves from 0.0 to 1.0+

    float dist = abs(diag - beam_pos);
    float shine = smoothstep(shine_width, 0.0, dist);

    COLOR = tex_color + (shine_color * shine * tex_color.a);
}
