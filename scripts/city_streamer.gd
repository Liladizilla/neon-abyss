extends Node3D
const CHUNK=preload("res://scripts/city_chunk.gd")
@export_range(1,5) var radius=2
@export_range(1,8) var chunks_per_frame=2
var chunk_size=96.0
var chunks={}
var queue:Array[Vector2i]=[]
var center=Vector2i(999999,999999)
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
    var ps=get_tree().get_nodes_in_group("local_player")
    if ps.is_empty(): return
    var p:Vector3=ps[0].global_position
    var c=Vector2i(floori(p.x/chunk_size),floori(p.z/chunk_size))
    if c!=center:
        center=c
        _queue_ring(c)
        for key in chunks.keys():
            var k:Vector2i=key
            if max(abs(k.x-c.x),abs(k.y-c.y))>radius+1:
                chunks[k].queue_free()
                chunks.erase(k)
        queue=queue.filter(func(k): return max(abs(k.x-c.x),abs(k.y-c.y))<=radius+1)
    var made=0
    while not queue.is_empty() and made<chunks_per_frame:
        var k:Vector2i=queue.pop_front()
        if not chunks.has(k) and max(abs(k.x-c.x),abs(k.y-c.y))<=radius+1:
            var ch=CHUNK.new()
            ch.configure(k,chunk_size,20261021,k.distance_to(c)<=1)
            ch.name="District_%d_%d"%[k.x,k.y]
            add_child(ch)
            chunks[k]=ch
            made+=1
func _queue_ring(c):
    var coords:Array[Vector2i]=[]
    for x in range(-radius,radius+1):
        for z in range(-radius,radius+1): coords.append(c+Vector2i(x,z))
    coords.sort_custom(func(a,b): return a.distance_squared_to(c)<b.distance_squared_to(c))
    for k in coords:
        if not chunks.has(k) and not queue.has(k): queue.append(k)
