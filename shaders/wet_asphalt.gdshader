shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec3 base_color:source_color=vec3(0.018,0.022,0.038);
uniform vec3 cyan_color:source_color=vec3(0.015,0.42,0.62);
uniform vec3 magenta_color:source_color=vec3(0.42,0.015,0.22);
float hash21(vec2 p){p=fract(p*vec2(123.34,456.21));p+=dot(p,p+45.32);return fract(p.x*p.y);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 p=UV*48.0;
 float grain=noise(p*3.0)*0.18+noise(p*0.7)*0.12;
 float puddle=smoothstep(0.42,0.78,noise(p*0.38+TIME*0.025));
 vec3 neon=mix(cyan_color,magenta_color,sin(UV.x*18.0+UV.y*9.0)*0.5+0.5);
 ALBEDO=base_color+vec3(grain*0.055)+neon*puddle*0.035;
 METALLIC=mix(0.12,0.62,puddle);
 ROUGHNESS=mix(0.22,0.055,puddle);
 EMISSION=neon*puddle*0.04;
}
