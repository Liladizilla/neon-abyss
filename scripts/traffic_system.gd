extends Node3D
## Lightweight pooled traffic with emissive lamps, following the local player across streamed road lanes.
var player:Node3D
var cars:MultiMeshInstance3D
var lamps:MultiMeshInstance3D
var states:Array[Dictionary]=[]
var clock=0.0
func _ready():
    var rng=RandomNumberGenerator.new()
    rng.seed=731902
    var body_mm=MultiMesh.new()
    body_mm.transform_format=MultiMesh.TRANSFORM_3D
    body_mm.use_colors=true
    var body=BoxMesh.new()
    body.size=Vector3(1.9,0.7,4.0)
    body_mm.mesh=body
    body_mm.instance_count=140
    cars=MultiMeshInstance3D.new()
    cars.multimesh=body_mm
    var body_mat=StandardMaterial3D.new()
    body_mat.vertex_color_use_as_albedo=true
    body_mat.metallic=0.72
    body_mat.roughness=0.22
    cars.material_override=body_mat
    add_child(cars)
    var lamp_mm=MultiMesh.new()
    lamp_mm.transform_format=MultiMesh.TRANSFORM_3D
    lamp_mm.use_colors=true
    var lamp_mesh=BoxMesh.new()
    lamp_mesh.size=Vector3(0.28,0.16,0.08)
    lamp_mm.mesh=lamp_mesh
    lamp_mm.instance_count=280
    lamps=MultiMeshInstance3D.new()
    lamps.multimesh=lamp_mm
    var lm=StandardMaterial3D.new()
    lm.vertex_color_use_as_albedo=true
    lm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    lm.emission_enabled=true
    lm.emission=Color.WHITE
    lm.emission_energy_multiplier=2.5
    lamps.material_override=lm
    add_child(lamps)
    for i in 140:
        states.append({"axis":rng.randi_range(0,1),"lane":rng.randi_range(0,1),"offset":rng.randf_range(-95,95),"speed":rng.randf_range(9,28)*(-1.0 if rng.randf()<0.5 else 1.0),"color":[Color(0.02,0.25,0.38),Color(0.22,0.04,0.18),Color(0.18,0.14,0.06),Color(0.12,0.16,0.32)][i%4]})
func _process(delta):
    var ps=get_tree().get_nodes_in_group("local_player")
    if ps.is_empty():return
    player=ps[0]
    clock+=delta
    var p=player.global_position
    for i in states.size():
        var s=states[i]
        s.offset=fposmod(s.offset+s.speed*delta,192.0)
        var lane_coord=(floor(p.x/96.0)*96.0)+48.0+(s.lane*2.0-1.0)*5.0 if s.axis==0 else (floor(p.z/96.0)*96.0)+48.0+(s.lane*2.0-1.0)*5.0
        var along=(floor((p.x if s.axis==0 else p.z)/192.0)*192.0)+s.offset
        var pos=Vector3(along,1.0,lane_coord) if s.axis==0 else Vector3(lane_coord,1.0,along)
        var basis=Basis.IDENTITY
        if (s.axis==0 and s.speed<0) or (s.axis==1 and s.speed>0):basis=Basis(Vector3.UP,PI)
        cars.multimesh.set_instance_transform(i,Transform3D(basis,pos))
        cars.multimesh.set_instance_color(i,s.color)
        var front=pos-basis.z*1.85
        var back=pos+basis.z*1.85
        var tint=Color(0.25,0.75,1.0) if s.speed>0 else Color(1.0,0.04,0.06)
        for side in 2:
            var lamp_index=i*2+side
            var offset=Vector3(-0.62,0.0,0) if side==0 else Vector3(0.62,0.0,0)
            var point=front+ basis*offset if s.speed>0 else back+basis*offset
            lamps.multimesh.set_instance_transform(lamp_index,Transform3D(basis,point))
            lamps.multimesh.set_instance_color(lamp_index,tint)
