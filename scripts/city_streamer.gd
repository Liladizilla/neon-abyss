extends Node3D
const CHUNK=preload("res://scripts/city_chunk.gd")
@export_range(1,5) var radius=2
@export_range(1,8) var chunks_per_frame=2
var chunk_size=96.0
var chunks={}
var queue:Array[Vector2i]=[]
var active_centers:Array[Vector2i]=[]
var generated_this_frame:=0
var last_stream_center_count:=0
func _ready():
    var floor=StaticBody3D.new()
    floor.name="InfiniteGround"
    var cs=CollisionShape3D.new()
    var boundary=WorldBoundaryShape3D.new()
    boundary.plane=Plane(Vector3.UP,0.0)
    cs.shape=boundary
    floor.add_child(cs)
    add_child(floor)
    _queue_ring(Vector2i.ZERO)
func _process(_delta):
    var presences=get_tree().get_nodes_in_group("city_presence")
    if presences.is_empty():
        presences=get_tree().get_nodes_in_group("local_player")
    var next_centers:Array[Vector2i]=[]
    for node in presences:
        if not is_instance_valid(node) or not node.visible:
            continue
        var p:Vector3=node.global_position
        var c:Vector2i=_chunk_coord_for_position(p)
        if not next_centers.has(c):
            next_centers.append(c)
    if next_centers.is_empty():
        _handle_no_active_centers()
        return
    next_centers.sort_custom(func(a,b):
        if a.x==b.x:return a.y<b.y
        return a.x<b.x
    )
    if next_centers!=active_centers:
        active_centers=next_centers
        for c in active_centers:
            _queue_ring(c)
        for key in chunks.keys():
            var chunk_node=chunks[key]
            var keep_chunk:bool=_is_near_any(key,active_centers)
            var needs_collision:bool=_needs_collision(key,active_centers)
            if not keep_chunk or chunk_node.collision_enabled!=needs_collision:
                # Rebuild whenever visual-only/solid status changes; stale physics must never persist.
                _remove_chunk(key, keep_chunk)
        queue=queue.filter(func(k): return _is_near_any(k,active_centers))
        _prioritize_queue()
    # Reconcile even if player visibility or collision state changed without a center change.
    _reconcile_chunk_collision()
    var made=0
    while not queue.is_empty() and made<chunks_per_frame:
        var k:Vector2i=queue.pop_front()
        if chunks.has(k) or not _is_near_any(k,active_centers):
            continue
        var collision_enabled:bool=_needs_collision(k,active_centers)
        var ch=CHUNK.new()
        ch.configure(k,chunk_size,20261021,collision_enabled)
        ch.name="District_%d_%d"%[k.x,k.y]
        add_child(ch)
        chunks[k]=ch
        made+=1
    generated_this_frame=made
    last_stream_center_count=active_centers.size()
func _chunk_coord_for_position(p:Vector3)->Vector2i:
    # floori is intentional: truncation misroutes positions just below zero.
    return Vector2i(floori(p.x / chunk_size), floori(p.z / chunk_size))

func _remove_chunk(key:Vector2i, rebuild:bool) -> void:
    var chunk_node = chunks.get(key)
    if is_instance_valid(chunk_node):
        var manager = get_tree().get_first_node_in_group("rental_manager")
        if is_instance_valid(manager): manager.unregister_chunk(key)
        var employment = get_tree().get_first_node_in_group("employment_manager")
        if is_instance_valid(employment): employment.unregister_chunk(key)
        chunk_node.queue_free()
    chunks.erase(key)
    if rebuild and not queue.has(key):
        queue.append(key)

func _reconcile_chunk_collision() -> void:
    for key in chunks.keys():
        var chunk_node = chunks[key]
        var keep_chunk:bool = _is_near_any(key, active_centers)
        var needs_collision:bool = _needs_collision(key, active_centers)
        if not keep_chunk or chunk_node.collision_enabled != needs_collision:
            _remove_chunk(key, keep_chunk)

func _prioritize_queue() -> void:
    queue = queue.filter(func(k): return not chunks.has(k) and _is_near_any(k, active_centers))
    queue.sort_custom(func(a:Vector2i, b:Vector2i):
        var da := _distance_squared_to_nearest_center(a)
        var db := _distance_squared_to_nearest_center(b)
        if da == db:
            if a.x == b.x: return a.y < b.y
            return a.x < b.x
        return da < db
    )

func _distance_squared_to_nearest_center(k:Vector2i) -> int:
    var best := 2147483647
    for center in active_centers:
        best = mini(best, k.distance_squared_to(center))
    return best

func get_streaming_diagnostics() -> Dictionary:
    return {"loaded_chunks": chunks.size(), "queued_chunks": queue.size(),
        "active_player_centers": last_stream_center_count, "generated_this_frame": generated_this_frame,
        "collision_chunks": _collision_chunk_count(),\n        "static_bodies": _physics_node_count(StaticBody3D),\n        "collision_shapes": _physics_node_count(CollisionShape3D)}

func _collision_chunk_count() -> int:
    var total := 0
    for key in chunks:
        if is_instance_valid(chunks[key]) and chunks[key].collision_enabled:
            total += 1
    return total

func _needs_collision(k:Vector2i,centers:Array[Vector2i])->bool:
    for center in centers:
        # Collision follows the full 3x3 neighborhood around each active player.
        if max(abs(k.x-center.x),abs(k.y-center.y))<=1:
            return true
    return false

func _is_near_any(k:Vector2i,centers:Array[Vector2i])->bool:
    for c in centers:
        if max(abs(k.x-c.x),abs(k.y-c.y))<=radius+1:
            return true
    return false
func _queue_ring(c:Vector2i):
    var coords:Array[Vector2i]=[]
    for x in range(-radius,radius+1):
        for z in range(-radius,radius+1):
            coords.append(c+Vector2i(x,z))
    coords.sort_custom(func(a,b): return a.distance_squared_to(c)<b.distance_squared_to(c))
    for k in coords:
        if not chunks.has(k) and not queue.has(k):
            queue.append(k)


func _handle_no_active_centers() -> void:
    # No connected, visible players means no district should retain live collision
    # or registry footprints. The spawn ring is queued again when a player appears.
    active_centers.clear()
    last_stream_center_count = 0
    generated_this_frame = 0
    queue.clear()
    for key in chunks.keys():
        _remove_chunk(key, false)


func _physics_node_count(node_type: Variant) -> int:
    # Called only when diagnostics are requested, never as part of the per-frame stream loop.
    var total := 0
    for chunk_node in chunks.values():
        if is_instance_valid(chunk_node):
            total += _count_descendants_of_type(chunk_node, node_type)
    return total

func _count_descendants_of_type(parent: Node, node_type: Variant) -> int:
    var total := 1 if is_instance_valid(parent) and parent is node_type else 0
    for child in parent.get_children():
        total += _count_descendants_of_type(child, node_type)
    return total
