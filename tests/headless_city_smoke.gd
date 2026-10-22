extends SceneTree

const CHUNK = preload("res://scripts/city_chunk.gd")
const RENTAL = preload("res://scripts/rental_manager.gd")
const INTERIOR = preload("res://scripts/apartment_interior.gd")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const VALID_PROFILES = ["retail", "residential_lobby", "maintenance", "loading"]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var manager = RENTAL.new()
    manager.name = "RentalManager"
    root.add_child(manager)
    var chunk = CHUNK.new()
    chunk.configure(Vector2i.ZERO, 96.0, 20261021, false)
    chunk.name = "HeadlessValidationChunk"
    root.add_child(chunk)

    # Allow _ready() to finish and register generated building footprints.
    await process_frame
    await process_frame

    var failures: Array[String] = []
    if manager.buildings.is_empty():
        failures.append("Generated chunk did not register any rentable buildings.")

    var checked_profiles := {}
    for building_id in manager.buildings:
        var building: Dictionary = manager.buildings[building_id]
        var profile := str(building.get("use_profile", ""))
        if not VALID_PROFILES.has(profile):
            failures.append("Building %s has invalid use profile '%s'." % [building_id, profile])
        if int(building.get("floors", 0)) < 1:
            failures.append("Building %s has no rentable floors." % building_id)
        checked_profiles[profile] = true

    # Regression-test forward/backward movement without synthesizing keyboard hardware.
    var movement_player = PLAYER_SCENE.instantiate()
    movement_player.name = "HeadlessMovementPlayer"
    root.add_child(movement_player)
    var forward_wish: Vector3 = movement_player.movement_wish_from_axis(Vector2(0, -1))
    var backward_wish: Vector3 = movement_player.movement_wish_from_axis(Vector2(0, 1))
    if forward_wish.dot(Vector3.FORWARD) < 0.99:
        failures.append("Forward input does not move toward -Z.")
    if backward_wish.dot(Vector3.BACK) < 0.99:
        failures.append("Backward input does not move toward +Z.")

    # Mouse-look should update yaw and pitch while captured, even if UI nodes exist.
    var previous_mouse_mode = Input.mouse_mode
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    var mouse_event = InputEventMouseMotion.new()
    mouse_event.relative = Vector2(10, -5)
    movement_player._input(mouse_event)
    if absf(movement_player.rotation.y + 10.0 * movement_player.mouse_sensitivity) > 0.0001:
        failures.append("Mouse horizontal motion did not rotate player yaw.")
    if absf(movement_player._pitch - 5.0 * movement_player.mouse_sensitivity) > 0.0001:
        failures.append("Mouse vertical motion did not update camera pitch.")
    Input.mouse_mode = previous_mouse_mode
    movement_player.queue_free()

    # Exercise an apartment's physical shell without rendering the city.
    for action_name in ["move_left", "move_right", "move_forward", "move_back", "sprint", "jump", "toggle_flight", "throw_prop", "interact", "ui_cancel"]:
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)

    var interior = INTERIOR.new()
    interior.configure("HEADLESS/F01/U1", Vector3(0, 0, 0), 4.5)
    interior.rotation.y = PI * 0.5
    root.add_child(interior)
    var player = PLAYER_SCENE.instantiate()
    player.name = "HeadlessCollisionPlayer"
    player.add_to_group("local_player")
    player.visible = true
    player.set_physics_process(false)
    root.add_child(player)
    player.global_position = interior.to_global(Vector3(0, 1.0, -2.8))
    await physics_frame
    var wall_body = interior.find_child("BackWall_Collision", true, false)
    var wall_has_shape := false
    if is_instance_valid(wall_body):
        for child in wall_body.get_children():
            if child is CollisionShape3D and child.shape != null:
                wall_has_shape = true
    if not wall_has_shape:
        failures.append("Apartment back wall is missing its collision shape.")
    else:
        var target_position: Vector3 = interior.to_global(Vector3(0, 1.0, -5.0))
        var collision = player.move_and_collide(target_position - player.global_position)
        if collision == null:
            failures.append("Player passed through the apartment back wall.")

    # Door panels must have physics shapes and slide open when the player approaches.
    if interior.entry_door_panels.size() != 2:
        failures.append("Apartment entry did not create two sliding door panels.")
    else:
        var door_has_collision := true
        var closed_positions: Array[float] = []
        for panel_data in interior.entry_door_panels:
            var door: AnimatableBody3D = panel_data.body
            closed_positions.append(door.position.x)
            var panel_has_shape := false
            for child in door.get_children():
                if child is CollisionShape3D and child.shape != null:
                    panel_has_shape = true
            if not panel_has_shape:
                door_has_collision = false
        if not door_has_collision:
            failures.append("One or more apartment door panels lack collision shapes.")
        player.global_position = interior.to_global(Vector3(0, 1.0, 3.9))
        interior.update_entry_doors(1.0)
        # AnimatableBody3D applies its synchronized transform on the next physics frame.
        await physics_frame
        await process_frame
        var opened := false
        for i in range(interior.entry_door_panels.size()):
            var door: AnimatableBody3D = interior.entry_door_panels[i].body
            if absf(door.position.x - closed_positions[i]) > 0.01:
                opened = true
        if not opened:
            failures.append("Apartment sliding doors did not respond to nearby player.")

    if failures.is_empty():
        print("CITY_SMOKE_OK buildings=%d profiles=%s apartment_collision=ok sliding_doors=ok" % [manager.buildings.size(), str(checked_profiles.keys())])
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)
