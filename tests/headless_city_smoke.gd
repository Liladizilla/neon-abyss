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
    chunk.configure(Vector2i.ZERO, 96.0, 20261021, true)
    chunk.name = "HeadlessValidationChunk"
    root.add_child(chunk)

    # Allow _ready() to finish and register generated building footprints.
    await process_frame
    await process_frame

    var failures: Array[String] = []
    for physics_name in ["StackedSkyLaneDeckCollision", "SkyLaneInterdeckStairCollision", "SkyLaneRampCollision"]:
        var physics_node = chunk.find_child(physics_name, true, false)
        if not is_instance_valid(physics_node) or not physics_node is StaticBody3D:
            failures.append("Missing physical elevated access component: %s." % physics_name)
        elif physics_node.get_child_count() == 0:
            failures.append("Elevated access component has no collision shapes: %s." % physics_name)
    var wayfinding = chunk.find_child("VerticalAccessWayfindingPylons", true, false)
    if not is_instance_valid(wayfinding) or not wayfinding is MultiMeshInstance3D or wayfinding.multimesh == null or wayfinding.multimesh.instance_count != 12:
        failures.append("Vertical access wayfinding must generate 12 markers across three levels.")
    var entrance_canopies = chunk.find_child("BuildingEntranceCanopies", true, false)
    if not is_instance_valid(entrance_canopies) or not entrance_canopies is MultiMeshInstance3D or entrance_canopies.multimesh == null or entrance_canopies.multimesh.instance_count != 20:
        failures.append("Four generated buildings must each receive a five-piece entrance canopy kit.")
    var entrance_lights = chunk.find_child("BuildingEntranceLightBars", true, false)
    if not is_instance_valid(entrance_lights) or not entrance_lights is MultiMeshInstance3D or entrance_lights.multimesh == null or entrance_lights.multimesh.instance_count != 4:
        failures.append("Each generated building must have one entrance light bar.")
    var threshold_collision = chunk.find_child("BuildingEntranceThresholdCollision", true, false)
    if not is_instance_valid(threshold_collision) or not threshold_collision is StaticBody3D or threshold_collision.get_child_count() != 4:
        failures.append("Active chunks must have one physical entrance threshold per generated building.")
    var sidewalk_collision = chunk.find_child("SidewalkAndCurbCollision", true, false)
    if not is_instance_valid(sidewalk_collision) or not sidewalk_collision is StaticBody3D:
        failures.append("Active chunks must provide physical sidewalk and curb collision.")
    var active_ramp_colliders := 0
    for node in chunk.find_children("CurbRampCollision_*", "StaticBody3D", true, false):
        active_ramp_colliders += 1
        if node.collision_layer != 1 or node.collision_mask != 1:
            failures.append("Active curb-ramp collision must use the world/player collision layer and mask.")
        if node.get_child_count() != 1 or not node.get_child(0) is CollisionShape3D:
            failures.append("Each active curb-ramp body must have exactly one matching shape.")
    if active_ramp_colliders != 8:
        failures.append("Active district must generate eight physical curb-cut ramp colliders.")

    # Outer visual-only districts must preserve ramp visuals without retaining hidden physics.
    var visual_chunk = CHUNK.new()
    visual_chunk.configure(Vector2i(1, 0), 96.0, 20261021, false)
    visual_chunk.name = "HeadlessVisualOnlyChunk"
    root.add_child(visual_chunk)
    await process_frame
    await process_frame
    var visual_ramp_colliders = visual_chunk.find_children("CurbRampCollision_*", "StaticBody3D", true, false)
    if not visual_ramp_colliders.is_empty():
        failures.append("Visual-only district created curb-ramp physics outside the collision ring.")
    var visual_ramp_meshes = visual_chunk.find_children("CrossingCurbRamps", "MultiMeshInstance3D", true, false)
    if visual_ramp_meshes.is_empty():
        failures.append("Visual-only district lost curb-ramp visuals while omitting collision.")
    visual_chunk.queue_free()

    if manager.buildings.is_empty():
        failures.append("Generated chunk did not register any rentable buildings.")
    if manager.buildings.size() != 4:
        failures.append("Expected four registered buildings in the deterministic 2x2 chunk.")
    if is_instance_valid(threshold_collision):
        for building_id in manager.buildings:
            var building:Dictionary = manager.buildings[building_id]
            var entrance:Vector3 = building.get("entrance", Vector3.INF)
            var center:Vector3 = building.get("center", Vector3.INF)
            var footprint:Vector3 = building.get("dimensions", Vector3.ZERO)
            var expected_side_offset:float=footprint.x*0.5+1.9
            if absf(entrance.z-center.z)>0.05 or absf(absf(entrance.x-center.x)-expected_side_offset)>0.15:
                failures.append("Registered entrance %s is not aligned with its arterial-facing X-wall opening." % building_id)
            var near_threshold := false
            for child in threshold_collision.get_children():
                if child is CollisionShape3D and child.shape != null and child.global_position.distance_to(entrance) < 1.2:
                    near_threshold = true
                    break
            if not near_threshold:
                failures.append("Registered rental entrance %s is not aligned with a physical threshold." % building_id)

            # Match this building's own threshold before checking sidewalk overlap.
            # A different entrance must not accidentally make this building pass.
            var matching_threshold: CollisionShape3D = null
            var matching_distance := INF
            for threshold_shape in threshold_collision.get_children():
                if not threshold_shape is CollisionShape3D or not threshold_shape.shape is BoxShape3D:
                    continue
                var distance: float = threshold_shape.global_position.distance_to(entrance)
                if distance < matching_distance:
                    matching_distance = distance
                    matching_threshold = threshold_shape
            var threshold_reaches_sidewalk := false
            if is_instance_valid(matching_threshold) and matching_distance < 1.2 and is_instance_valid(sidewalk_collision):
                var threshold_pos: Vector3 = matching_threshold.global_position
                var threshold_size: Vector3 = matching_threshold.shape.size
                for sidewalk_shape in sidewalk_collision.get_children():
                    if not sidewalk_shape is CollisionShape3D or not sidewalk_shape.shape is BoxShape3D:
                        continue
                    var sidewalk_pos: Vector3 = sidewalk_shape.global_position
                    var sidewalk_size: Vector3 = sidewalk_shape.shape.size
                    var overlap_x: float = (threshold_size.x + sidewalk_size.x) * 0.5 - absf(threshold_pos.x - sidewalk_pos.x)
                    var overlap_y: float = (threshold_size.y + sidewalk_size.y) * 0.5 - absf(threshold_pos.y - sidewalk_pos.y)
                    var overlap_z: float = (threshold_size.z + sidewalk_size.z) * 0.5 - absf(threshold_pos.z - sidewalk_pos.z)
                    var threshold_top: float = threshold_pos.y + threshold_size.y * 0.5
                    var sidewalk_top: float = sidewalk_pos.y + sidewalk_size.y * 0.5
                    # Horizontal overlap alone can hide a raised or sunken threshold.
                    # Require physical intersection in 3D and nearly flush walkable top faces.
                    if overlap_x > 0.0 and overlap_y > 0.0 and overlap_z > 0.0 and absf(threshold_top - sidewalk_top) <= 0.05:
                        threshold_reaches_sidewalk = true
                        break
            if not threshold_reaches_sidewalk:
                failures.append("Registered rental entrance %s does not physically overlap the sidewalk collider in 3D." % building_id)

    var checked_profiles := {}
    for building_id in manager.buildings:
        var building: Dictionary = manager.buildings[building_id]
        var profile := str(building.get("use_profile", ""))
        if not VALID_PROFILES.has(profile):
            failures.append("Building %s has invalid use profile '%s'." % [building_id, profile])
        if int(building.get("floors", 0)) < 1:
            failures.append("Building %s has no rentable floors." % building_id)
        checked_profiles[profile] = true

    for action_name in ["move_left", "move_right", "move_forward", "move_back", "sprint", "jump", "toggle_flight", "throw_prop", "interact", "ui_cancel"]:
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)

    # Streaming regression checks: negative coordinates, collision ring, queue priority, and diagnostics.
    var streamer_script = load("res://scripts/city_streamer.gd")
    var streamer = streamer_script.new()
    streamer.name = "HeadlessStreamingValidation"
    streamer.radius = 2
    streamer.chunk_size = 96.0
    root.add_child(streamer)
    if streamer._chunk_coord_for_position(Vector3(-0.1, 0.0, -96.1)) != Vector2i(-1, -2):
        failures.append("Negative world positions map to the wrong streamed district.")
    if not streamer._needs_collision(Vector2i(1, -1), [Vector2i(0, 0)]):
        failures.append("Collision neighborhood excludes a diagonal adjacent district.")
    if streamer._needs_collision(Vector2i(2, 0), [Vector2i(0, 0)]):
        failures.append("Collision neighborhood extends beyond the intended 3x3 ring.")
    streamer.active_centers = [Vector2i(5, 5), Vector2i(0, 0)]
    streamer.queue = [Vector2i(5, 7), Vector2i(0, 2), Vector2i(5, 6), Vector2i(0, 1)]
    streamer._prioritize_queue()
    if streamer.queue.is_empty() or streamer.queue[0] != Vector2i(0, 1):
        failures.append("Stream queue does not prioritize the nearest district deterministically.")
    var stream_stats:Dictionary = streamer.get_streaming_diagnostics()
    for stat_name in ["loaded_chunks", "queued_chunks", "active_player_centers", "generated_this_frame", "collision_chunks"]:
        if not stream_stats.has(stat_name):
            failures.append("Streaming diagnostics missing counter: %s." % stat_name)
    streamer.queue_free()

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
    var diagonal_wish: Vector3 = movement_player.movement_wish_from_axis(Vector2(1, -1))
    if absf(diagonal_wish.length() - 1.0) > 0.001:
        failures.append("Diagonal movement is not normalized and may be faster than straight movement.")
    movement_player.rotation.y = PI * 0.5
    var rotated_forward: Vector3 = movement_player.movement_wish_from_axis(Vector2(0, -1))
    if rotated_forward.dot(Vector3.LEFT) < 0.99:
        failures.append("Forward movement does not follow player yaw after turning.")
    movement_player.rotation.y = 0.0

    # Mouse-look should update yaw and pitch and clamp pitch before the camera flips.
    var mouse_delta := Vector2(10, -5)
    movement_player.apply_mouse_motion(mouse_delta)
    if absf(movement_player.rotation.y + mouse_delta.x * movement_player.mouse_sensitivity) > 0.0001:
        failures.append("Mouse horizontal motion did not rotate player yaw.")
    if absf(movement_player._pitch + mouse_delta.y * movement_player.mouse_sensitivity) > 0.0001:
        failures.append("Mouse vertical motion did not update camera pitch.")
    movement_player.apply_mouse_motion(Vector2(0, -100000))
    if movement_player._pitch > 1.481:
        failures.append("Mouse pitch was not clamped at the upper look limit.")
    if movement_player.collision_layer != 1 or movement_player.collision_mask != 1:
        failures.append("Player collision layer/mask no longer matches generated world geometry.")
    movement_player.queue_free()

    # Exercise an apartment's physical shell without rendering the city.
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
            failures.append("Player passed through the apartment back wall when approaching from inside.")
        # Repeat the same wall crossing in the opposite direction. One-way collision bugs
        # are still collision bugs, regardless of which side the player starts on.
        player.global_position = interior.to_global(Vector3(0, 1.0, -5.0))
        await physics_frame
        var reverse_target: Vector3 = interior.to_global(Vector3(0, 1.0, -2.8))
        var reverse_collision = player.move_and_collide(reverse_target - player.global_position)
        if reverse_collision == null:
            failures.append("Player passed through the apartment back wall when approaching from outside.")

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
        var left_door: AnimatableBody3D = interior.entry_door_panels[0].body
        var right_door: AnimatableBody3D = interior.entry_door_panels[1].body
        var clear_gap: float = absf(right_door.position.x - left_door.position.x) - 0.94
        var player_shape_node = player.get_node_or_null("CollisionShape3D")
        var player_capsule: CapsuleShape3D = player_shape_node.shape if is_instance_valid(player_shape_node) and player_shape_node.shape is CapsuleShape3D else null
        if player_capsule == null:
            failures.append("Player collision capsule is missing.")
        elif clear_gap < player_capsule.radius * 2.0 + 0.2:
            failures.append("Open apartment doorway is narrower than the player capsule plus clearance margin.")
        var bridge_body = interior.find_child("ElevatorAccessBridge_Collision", true, false)
        if not is_instance_valid(bridge_body) or not bridge_body is StaticBody3D or bridge_body.get_child_count() == 0:
            failures.append("Apartment access bridge is missing physical collision.")
        var bridge_rail_left = interior.find_child("BridgeRailLeft_Collision", true, false)
        var bridge_rail_right = interior.find_child("BridgeRailRight_Collision", true, false)
        if not is_instance_valid(bridge_rail_left) or not is_instance_valid(bridge_rail_right):
            failures.append("Apartment access bridge must retain collision on both safety rails.")
        if interior.access_bridge_length < 2.8:
            failures.append("Apartment access bridge is shorter than the minimum landing span.")

    if failures.is_empty():
        print("CITY_SMOKE_OK buildings=%d profiles=%s apartment_collision=ok sliding_doors=ok" % [manager.buildings.size(), str(checked_profiles.keys())])
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)
