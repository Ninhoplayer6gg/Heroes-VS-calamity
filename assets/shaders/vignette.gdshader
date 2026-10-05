shader_type canvas_item;
// Vinheta escura nas bordas. "danger" pulsa em vermelho com pouca vida;
// "slowmo" dá um tom dourado durante a Câmera Lenta.

uniform float danger = 0.0;
uniform float slowmo = 0.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.0, 0.85));
	float v = smoothstep(0.42, 0.85, d);
	vec3 col = mix(vec3(0.02, 0.01, 0.03), vec3(0.85, 0.12, 0.12), danger * 0.8);
	float a = v * (0.7 + danger * 0.25);
	col = mix(col, vec3(1.0, 0.75, 0.2), slowmo * 0.5);
	a = max(a, slowmo * (0.1 + v * 0.35));
	COLOR = vec4(col, a);
}
