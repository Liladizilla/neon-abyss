extends Node3D
const NEON=[Color(0,0.92,1),Color(1,0.08,0.72),Color(1,0.56,0.04),Color(0.34,0.2,1),Color(0.12,1,0.48)]
var coord=Vector2i.ZERO
var size=96.0
var seed_value=1
var collision_enabled=true
var rng=RandomNumberGenerator.new()
func configure(c,s,seed_in,collide):
    coord=c
    size=s
    seed_value=seed_in
    collision_enabled=collide
func _ready():
    rng.seed=hash(Vector3i(coord.x,seed_value,coord.y))
    _roads()
    _build()
func _roads():
    var road=MeshInstance3D.new()
    var plane=PlaneMesh.new()
    plane.size=Vector2(size,size)
    road.mesh=plane
    road.position=Vector3(size/2,-0.035,size/2)
    var shader=ShaderMaterial.new()
    shader.shader=load("res://shaders/wet_asphalt.gdshader")
    road.material_override=shader
    add_child(road)
    var side_mat=StandardMaterial3D.new()
    side_mat.albedo_color=Color(0.1,0.11,0.17)
    for e in range(4):
        var side=MeshInstance3D.new()
        var box=BoxMesh.new()
        box.size=Vector3(size,0.35,5.5) if e<2 else Vector3(5.5,0.35,size)
        side.mesh=box
        side.material_override=side_mat
        side.position=Vector3(size/2,0.06,2.75 if e==0 else size-2.75) if e<2 else Vector3(2.75 if e==2 else size-2.75,0.06,size/2)
        add_child(side)
func _build():
    var body_tx:Array[Transform3D]=[]
    var body_colors:Array[Color]=[]
    var trim_tx:Array[Transform3D]=[]
    var trim_colors:Array[Color]=[]
    var win_tx:Array[Transform3D]=[]
    var win_colors:Array[Color]=[]
    var roof_tx:Array[Transform3D]=[]
    var colliders:Array[Dictionary]=[]
    for ix in range(2):
        for iz in range(2):
            var x=24.0+ix*48.0+rng.randf_range(-3,3)
            var z=24.0+iz*48.0+rng.randf_range(-3,3)
            var w=rng.randf_range(18,27)
            var d=rng.randf_range(18,27)
            var floors=rng.randi_range(7,34)
            var h=float(floors)*rng.randf_range(3.0,4.1)
            var neon:Color=NEON[rng.randi_range(0,NEON.size()-1)]
            body_tx.append(Transform3D(Basis.from_scale(Vector3(w,h,d)),Vector3(x,h/2,z)))
            body_colors.append(Color(0.68,0.72,0.86).lerp(Color(0.12,0.14,0.23),rng.randf()))
            colliders.append({"p":Vector3(x,h/2,z),"s":Vector3(w,h,d)})
            roof_tx.append(Transform3D(Basis.from_scale(Vector3(w*0.62,2,d*0.62)),Vector3(x,h+1,z)))
            roof_tx.append(Transform3D(Basis.from_scale(Vector3(1.1,rng.randf_range(5,15),1.1)),Vector3(x+w*0.22,h+7,z-d*0.2)))
            for level in range(2,floors,3):
                var y=float(level)*h/float(floors)
                for side in range(4):
                    var fx=side<2
                    var sign=-1.0 if side%2==0 else 1.0
                    var count=maxi(2,int((d if fx else w)/2.1))
                    for wi in range(count):
                        if rng.randf()<0.17: continue
                        var u=(float(wi)+0.5)/count-0.5
                        var sz=Vector3(0.075,0.9,0.72) if fx else Vector3(0.72,0.9,0.075)
                        var pos=Vector3(x+sign*(w/2+0.035),y,z+u*d) if fx else Vector3(x+u*w,y,z+sign*(d/2+0.035))
                        win_tx.append(Transform3D(Basis.from_scale(sz),pos))
                        win_colors.append(neon if rng.randf()>0.28 else Color(0.015,0.02,0.035))
                if level%6==2:
                    trim_tx.append(Transform3D(Basis.from_scale(Vector3(w*1.025,0.18,d*1.025)),Vector3(x,y,z)))
                    trim_colors.append(neon)
            for sign_i in range(rng.randi_range(1,3)):
                var side=rng.randi_range(0,3)
                var pos=Vector3(x,rng.randf_range(4,minf(h-1,18)),z)
                var sz=Vector3(0.35,rng.randf_range(2,5),d*0.7) if side<2 else Vector3(w*0.7,rng.randf_range(2,5),0.35)
                pos.x+=(w/2+0.22)*(-1.0 if side==0 else 1.0) if side<2 else 0.0
                pos.z+=(d/2+0.22)*(-1.0 if side==2 else 1.0) if side>=2 else 0.0
                trim_tx.append(Transform3D(Basis.from_scale(sz),pos))
                trim_colors.append(neon)
    _instances("BuildingMasses",body_tx,body_colors,Color(0.2,0.23,0.34),false)
    _instances("NeonBandsAndSigns",trim_tx,trim_colors,Color(0.2,0.5,0.6),true)
    _instances("WindowGrid",win_tx,win_colors,Color(0,0.65,0.9),true)
    _instances("RooftopMachinery",roof_tx,[],Color(0.09,0.14,0.21),false)
    if collision_enabled:
        var physics=StaticBody3D.new()
        for data in colliders:
            var cs=CollisionShape3D.new()
            var shape=BoxShape3D.new()
            shape.size=data.s
            cs.shape=shape
            cs.position=data.p
            physics.add_child(cs)
        add_child(physics)
func _instances(label,tx:Array[Transform3D],colors:Array[Color],tint:Color,emissive:bool):
    var mm=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.use_colors=true
    var box=BoxMesh.new()
    mm.mesh=box
    mm.instance_count=tx.size()
    for i in tx.size():
        mm.set_instance_transform(i,tx[i])
        if i<colors.size(): mm.set_instance_color(i,colors[i])
    var inst=MultiMeshInstance3D.new()
    inst.name=label
    inst.multimesh=mm
    var mat=StandardMaterial3D.new()
    mat.albedo_color=tint
    mat.vertex_color_use_as_albedo=true
    mat.metallic=0.68
    mat.roughness=0.28
    if emissive:
        mat.emission_enabled=true
        mat.emission=Color.WHITE
        mat.emission_energy_multiplier=1.8
    inst.material_override=mat
    add_child(inst)
