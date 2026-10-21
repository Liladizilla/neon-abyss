extends Node3D
## Per-floor sliding landing doors synchronized with the building's elevator cab.
var floor_number := 1
var door_y := 1.23
var _is_open := false
var _left: AnimatableBody3D
var _right: AnimatableBody3D

func configure(level: int, landing_height: float) -> void:
    floor_number = maxi(1, level)
    door_y = landing_height + 1.08

func _ready() -> void:
    var door_material := StandardMaterial3D.new()
    door_material.albedo_color = Color(0.025, 0.075, 0.12)
    door_material.metallic = 0.72
    door_material.roughness = 0.24
    door_material.emission_enabled = true
    door_material.emission = Color(0.005, 0.11, 0.16)
    door_material.emission_energy_multiplier = 0.8
    var panel_mesh := BoxMesh.new()
    panel_mesh.size = Vector3(0.82, 1.85, 0.09)
    _left = _make_panel("LandingDoorLeft_F%02d" % floor_number, -0.43, panel_mesh, door_material)
    _right = _make_panel("LandingDoorRight_F%02d" % floor_number, 0.43, panel_mesh, door_material)
    var seam_material := StandardMaterial3D.new()
    seam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    seam_material.albedo_color = Color(0.02, 0.78, 1.0)
    seam_material.emission_enabled = true
    seam_material.emission = Color(0.01, 0.45, 1.0)
    seam_material.emission_energy_multiplier = 1.8
    var seam_mesh := BoxMesh.new()
    seam_mesh.size = Vector3(0.025, 1.72, 0.018)
    var seam := MeshInstance3D.new()
    seam.name = "LandingDoorSeam_F%02d" % floor_number
    seam.mesh = seam_mesh
    seam.material_override = seam_material
    seam.position = Vector3(0.0, door_y, 1.835)
    add_child(seam)

func on_travel_started(_target_floor: int) -> void:
    if _is_open:
        close_doors()

func on_floor_arrived(arrived_floor: int) -> void:
    if arrived_floor == floor_number:
        open_doors()

func open_doors(animated: bool = true) -> void:
    _set_open(true, animated)

func close_doors(animated: bool = true) -> void:
    _set_open(false, animated)

func _set_open(open: bool, animated: bool) -> void:
    if not is_instance_valid(_left) or not is_instance_valid(_right):
        return
    _is_open = open
    var left_target := -0.88 if open else -0.43
    var right_target := 0.88 if open else 0.43
    if not animated:
        _left.position.x = left_target
        _right.position.x = right_target
        return
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(_left, "position:x", left_target, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(_right, "position:x", right_target, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _make_panel(panel_name: String, x: float, panel_mesh: BoxMesh, door_material: StandardMaterial3D) -> AnimatableBody3D:
    var body := AnimatableBody3D.new()
    body.name = panel_name
    body.position = Vector3(x, door_y, 1.78)
    var mesh_node := MeshInstance3D.new()
    mesh_node.mesh = panel_mesh
    mesh_node.material_override = door_material
    body.add_child(mesh_node)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = panel_mesh.size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return body
