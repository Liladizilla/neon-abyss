extends Node3D
const CHUNK=preload("res://scripts/city_chunk.gd")
@export_range(1,5) var radius=2
@export_range(1,8) var chunks_per_frame=2
var chunk_size=96.0
var chunks={}
var queue:Array[Vector2i]=[]
var active_centers:Array[Vector2i]=[]
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
        var c=Vector2i(floori(p.x/chunk_size),floori(p.z/chunk_size))
        if not next_centers.has(c):
            next_centers.append(c)
    if next_centers.is_empty():
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
            if not _is_near_any(key,active_centers):
                var manager=get_tree().get_first_node_in_group("rental_manager")
                if is_instance_valid(manager):manager.unregister_chunk(key)
                chunks[key].queue_free()
                chunks.erase(key)
        queue=queue.filter(func(k): return _is_near_any(k,active_centers))
    var made=0
    while not queue.is_empty() and made<chunks_per_frame:
        var k:Vector2i=queue.pop_front()
        if chunks.has(k) or not _is_near_any(k,active_centers):
            continue
        var collision_enabled=false
        for c in active_centers:
            if k.distance_to(c)<=1.0:
                collision_enabled=true
                break
        var ch=CHUNK.new()
        ch.configure(k,chunk_size,20261021,collision_enabled)
        ch.name="District_%d_%d"%[k.x,k.y]
        add_child(ch)
        chunks[k]=ch
        made+=1
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
