extends Node3D
## Camera-following rain volume; GPU particles keep cost bounded near the player.
var target: Node3D
func set_target(node: Node3D) -> void:
    target=node
func _ready() -> void:
    var rain=GPUParticles3D.new()
    rain.name="RainField"
    rain.amount=1800
    rain.lifetime=1.1
    rain.local_coords=true
    rain.emitting=true
    var process=ParticleProcessMaterial.new()
    process.direction=Vector3(0,-1,0)
    process.initial_velocity_min=28.0
    process.initial_velocity_max=42.0
    process.gravity=Vector3(0,-10,0)
    process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents=Vector3(48,28,48)
    rain.process_material=process
    var streak=QuadMesh.new()
    streak.size=Vector2(0.025,0.85)
    var material=StandardMaterial3D.new()
    material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color=Color(0.28,0.62,0.9,0.52)
    material.emission_enabled=true
    material.emission=Color(0.12,0.28,0.55)
    material.emission_energy_multiplier=0.35
    streak.material=material
    rain.draw_pass_1=streak
    add_child(rain)
func _process(_delta: float) -> void:
    if is_instance_valid(target):
        global_position=target.global_position+Vector3(0,12,0)
