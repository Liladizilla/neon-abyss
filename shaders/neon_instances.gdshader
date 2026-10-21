shader_type spatial;
render_mode cull_back, unshaded;
uniform float emission_energy : hint_range(0.0, 6.0) = 2.0;
varying vec3 instance_tint;
void vertex() {
    instance_tint = COLOR.rgb;
}
void fragment() {
    ALBEDO = instance_tint * 0.12;
    EMISSION = instance_tint * emission_energy;
}
