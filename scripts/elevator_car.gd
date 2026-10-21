extends AnimatableBody3D
## Host-validated tower lift with floor selection and a physical moving cab.
const BASE_Y := 1.315
var floor_count := 8
var floor_height := 3.4
var tower_height := 27.2
var building_id := ""
var lift_tween: Tween
var panel: CanvasLayer
var floor_list: VBoxContainer
var status_label: Label
var _busy := false
var _target_floor := 1
var _door_left: MeshInstance3D
var _door_right: MeshInstance3D
var _doors_open := true
signal travel_started(target_floor: int)
signal floor_arrived(floor_number: int)

func configure(floors: int, height: float, index: String, enable_physics: bool) -> void:
    floor_count = maxi(1, floors)
    tower_height = height
    floor_height = height / float(floor_count)
    building_id = index
    position.y = BASE_Y
    if not enable_physics:
        collision_layer = 0
        collision_mask = 0

func _ready() -> void:
    add_to_group("elevator_car")
    _build_controls()
    if collision_layer != 0:
        _build_cab_collision()
    _build_cab_doors()
    multiplayer.peer_connected.connect(_on_peer_connected)

func _build_cab_doors() -> void:
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.025, 0.075, 0.12)
    material.metallic = 0.72
    material.roughness = 0.24
    material.emission_enabled = true
    material.emission = Color(0.005, 0.11, 0.16)
    material.emission_energy_multiplier = 0.8
    var panel_mesh := BoxMesh.new()
    panel_mesh.size = Vector3(0.92, 2.05, 0.075)
    _door_left = MeshInstance3D.new()
    _door_left.name = "CabDoorLeft"
    _door_left.mesh = panel_mesh
    _door_left.material_override = material
    _door_left.position = Vector3(-0.46, 0.0, 1.015)
    add_child(_door_left)
    _door_right = MeshInstance3D.new()
    _door_right.name = "CabDoorRight"
    _door_right.mesh = panel_mesh
    _door_right.material_override = material
    _door_right.position = Vector3(0.46, 0.0, 1.015)
    add_child(_door_right)
    var seam_material := StandardMaterial3D.new()
    seam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    seam_material.albedo_color = Color(0.02, 0.78, 1.0)
    seam_material.emission_enabled = true
    seam_material.emission = Color(0.01, 0.45, 1.0)
    seam_material.emission_energy_multiplier = 1.8
    for side in [-1.0, 1.0]:
        var seam := MeshInstance3D.new()
        var seam_mesh := BoxMesh.new()
        seam_mesh.size = Vector3(0.025, 1.9, 0.018)
        seam.mesh = seam_mesh
        seam.material_override = seam_material
        seam.position = Vector3(side * 0.04, 0.0, 1.06)
        add_child(seam)

func _build_cab_collision() -> void:
    var shape_node := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2.05, 0.16, 2.05)
    shape_node.shape = shape
    shape_node.position = Vector3(0, -1.08, 0)
    add_child(shape_node)

func _build_controls() -> void:
    panel = CanvasLayer.new()
    panel.layer = 24
    add_child(panel)
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.004, 0.008, 0.02, 0.78)
    panel.add_child(shade)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(center)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(440, 520)
    center.add_child(card)
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.018, 0.035, 0.07, 0.99)
    skin.border_color = Color(0.02, 0.75, 1.0)
    skin.set_border_width_all(1)
    skin.set_content_margin_all(20)
    card.add_theme_stylebox_override("panel", skin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 10)
    card.add_child(stack)
    var title := Label.new()
    title.text = "ABYSS TRANSIT  /  ELEVATOR"
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color(0.08, 0.84, 1.0))
    stack.add_child(title)
    var note := Label.new()
    note.text = "Select a destination floor. The lift is host-authoritative."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(note)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(scroll)
    floor_list = VBoxContainer.new()
    floor_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(floor_list)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(status_label)
    var close := Button.new()
    close.text = "CLOSE  [ESC]"
    close.pressed.connect(_close_panel)
    stack.add_child(close)
    panel.hide()

func _unhandled_input(event: InputEvent) -> void:
    if not event.is_action_pressed("elevator_use"):
        if event.is_action_pressed("ui_cancel") and panel.visible:
            _close_panel()
            get_viewport().set_input_as_handled()
        return
    var local_player := get_tree().get_first_node_in_group("local_player") as Node3D
    if not is_instance_valid(local_player) or not local_player.visible:
        return
    if _nearest_lift(local_player) != self or not _near_shaft(local_player.global_position):
        return
    if panel.visible:
        _close_panel()
    else:
        _open_panel()
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_viewport().set_input_as_handled()

func _nearest_lift(local_player: Node3D) -> Node:
    var nearest: Node = null
    var nearest_distance := 6.0
    for lift in get_tree().get_nodes_in_group("elevator_car"):
        if not is_instance_valid(lift):
            continue
        var delta: Vector3 = lift.global_position - local_player.global_position
        var horizontal := Vector2(delta.x, delta.z).length()
        if horizontal < nearest_distance:
            nearest_distance = horizontal
            nearest = lift
    return nearest

func _near_shaft(world_position: Vector3) -> bool:
    var delta := global_position - world_position
    return Vector2(delta.x, delta.z).length() < 5.8 and world_position.y >= -1.0 and world_position.y <= tower_height + 4.0

func _open_panel() -> void:
    for child in floor_list.get_children():
        child.queue_free()
    for floor_number in range(1, floor_count + 1):
        var button := Button.new()
        button.text = "FLOOR %02d%s" % [floor_number, "  •  CURRENT" if absf(position.y - _floor_y(floor_number)) < 0.7 else ""]
        button.custom_minimum_size.y = 36
        var is_current_floor := absf(position.y - _floor_y(floor_number)) < 0.25
        button.disabled = _busy or is_current_floor
        button.pressed.connect(_request_floor.bind(floor_number))
        floor_list.add_child(button)
    status_label.text = "Lift moving..." if _busy else "Ready  •  Tower %s" % building_id
    panel.show()

func _close_panel() -> void:
    panel.hide()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _request_floor(floor_number: int) -> void:
    if floor_number < 1 or floor_number > floor_count:
        return
    if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
        _request_floor_rpc.rpc_id(1, floor_number)
        status_label.text = "Request sent to city host..."
    else:
        _server_request_floor(floor_number, 1)

func _server_request_floor(floor_number: int, peer_id: int) -> void:
    if floor_number < 1 or floor_number > floor_count:
        _send_status(peer_id, "Invalid destination floor.")
        return
    var requester: Node3D
    if not multiplayer.has_multiplayer_peer() or peer_id == 1:
        requester = get_tree().get_first_node_in_group("local_player") as Node3D
    else:
        var network := get_tree().get_first_node_in_group("network_manager")
        if is_instance_valid(network) and network.avatars.has(peer_id):
            requester = network.avatars[peer_id] as Node3D
    if not is_instance_valid(requester) or not _near_shaft(requester.global_position):
        _send_status(peer_id, "Stand beside this tower's elevator shaft first.")
        return
    if _busy:
        _send_status(peer_id, "Lift is already moving. Wait for it to arrive.")
        return
    if absf(position.y - _floor_y(floor_number)) < 0.25:
        _send_status(peer_id, "The lift is already at that floor.")
        return
    if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
        _begin_travel(floor_number)
        _broadcast_floor.rpc(floor_number)
    else:
        _begin_travel(floor_number)

func _begin_travel(floor_number: int) -> void:
    if floor_number < 1 or floor_number > floor_count:
        return
    _target_floor = floor_number
    if is_instance_valid(lift_tween) and lift_tween.is_running():
        lift_tween.kill()
    _busy = true
    travel_started.emit(floor_number)
    lift_tween = create_tween()
    if _doors_open:
        lift_tween.tween_callback(_set_doors_open.bind(false))
        lift_tween.tween_interval(0.32)
    var duration := maxf(1.5, absf(position.y - _floor_y(floor_number)) / 5.0)
    lift_tween.tween_property(self, "position:y", _floor_y(floor_number), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    lift_tween.tween_interval(0.12)
    lift_tween.tween_callback(_set_doors_open.bind(true))
    lift_tween.finished.connect(func() -> void:
        _busy = false
        floor_arrived.emit(floor_number)
        if panel.visible:
            _open_panel()
    )

func _set_doors_open(open: bool) -> void:
    _doors_open = open
    if not is_instance_valid(_door_left) or not is_instance_valid(_door_right):
        return
    var door_tween := create_tween()
    door_tween.set_parallel(true)
    var target_left := -0.92 if open else -0.46
    var target_right := 0.92 if open else 0.46
    door_tween.tween_property(_door_left, "position:x", target_left, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    door_tween.tween_property(_door_right, "position:x", target_right, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _floor_y(floor_number: int) -> float:
    return BASE_Y + float(floor_number - 1) * floor_height

func _send_status(peer_id: int, message: String) -> void:
    if multiplayer.has_multiplayer_peer() and multiplayer.is_server() and peer_id != 1:
        _status_rpc.rpc_id(peer_id, message)
    elif is_instance_valid(status_label):
        status_label.text = message

func _on_peer_connected(peer_id: int) -> void:
    if not multiplayer.is_server() or peer_id == 1:
        return
    _receive_lift_snapshot.rpc_id(peer_id, position.y, _busy, _target_floor, _doors_open)

@rpc("any_peer", "call_remote", "reliable")
func _request_floor_rpc(floor_number: int) -> void:
    if multiplayer.is_server():
        _server_request_floor(floor_number, multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func _broadcast_floor(floor_number: int) -> void:
    _begin_travel(floor_number)

@rpc("authority", "call_remote", "reliable")
func _receive_lift_snapshot(cab_y: float, moving: bool, destination_floor: int, doors_open: bool) -> void:
    if destination_floor < 1 or destination_floor > floor_count:
        return
    if is_instance_valid(lift_tween) and lift_tween.is_running():
        lift_tween.kill()
    position.y = clampf(cab_y, BASE_Y, BASE_Y + float(floor_count - 1) * floor_height)
    _target_floor = destination_floor
    _busy = false
    _set_doors_open(doors_open and not moving)
    if moving:
        _begin_travel(destination_floor)
    elif panel.visible:
        _open_panel()

@rpc("authority", "call_remote", "reliable")
func _status_rpc(message: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = message
