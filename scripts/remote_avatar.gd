extends Node3D
var target_position=Vector3.ZERO
var target_yaw=0.0
var initialized=false
func _ready():
    add_to_group("city_presence")
    var mat=StandardMaterial3D.new()
    mat.albedo_color=Color(0.04,0.12,0.2)
    mat.metallic=0.55
    mat.emission_enabled=true
    mat.emission=Color(0,0.55,0.8)
    mat.emission_energy_multiplier=1.4
    $Body.material_override=mat
func set_network_state(pos,yaw):
    target_position=pos
    target_yaw=yaw
    if not initialized:
        global_position=pos
        rotation.y=yaw
        initialized=true
func _process(delta):
    global_position=global_position.lerp(target_position,1.0-exp(-12.0*delta))
    rotation.y=lerp_angle(rotation.y,target_yaw,1.0-exp(-12.0*delta))
