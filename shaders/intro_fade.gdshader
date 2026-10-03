shader_type canvas_item;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float edge = smoothstep(0.48, 1.25, length(centered));
	COLOR = vec4(vec3(edge), COLOR.a);
}
