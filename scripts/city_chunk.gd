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
    position=Vector3(c.x*s,0,c.y*s)
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
    side_mat.roughness=0.8
    for e in range(4):
        var side=MeshInstance3D.new()
        var box=BoxMesh.new()
        box.size=Vector3(size,0.35,5.5) if e<2 else Vector3(5.5,0.35,size)
        side.mesh=box
        side.material_override=side_mat
        side.position=Vector3(size/2,0.06,2.75 if e==0 else size-2.75) if e<2 else Vector3(2.75 if e==2 else size-2.75,0.06,size/2)
        add_child(side)
    var mm=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    var dash=BoxMesh.new()
    dash.size=Vector3(0.22,0.025,3.2)
    mm.mesh=dash
    var tx:Array[Transform3D]=[]
    for z in [size*0.5-5.0,size*0.5+5.0]:
        for x in range(5,int(size-5),9): tx.append(Transform3D(Basis.IDENTITY,Vector3(float(x),0.015,z)))
    mm.instance_count=tx.size()
    for i in tx.size(): mm.set_instance_transform(i,tx[i])
    var marks=MultiMeshInstance3D.new()
    marks.multimesh=mm
    var lm=StandardMaterial3D.new()
    lm.albedo_color=Color(0.8,0.65,0.28)
    lm.emission_enabled=true
    lm.emission=Color(0.22,0.12,0.025)
    lm.emission_energy_multiplier=0.8
    marks.material_override=lm
    add_child(marks)
func _build():
    var body_tx:Array[Transform3D]=[]
    var body_colors:Array[Color]=[]
    var trim_tx:Array[Transform3D]=[]
    var trim_colors:Array[Color]=[]
    var win_tx:Array[Transform3D]=[]
    var win_colors:Array[Color]=[]
    var roof_tx:Array[Transform3D]=[]
    var cylinder_tx:Array[Transform3D]=[]
    var colliders:Array[Dictionary]=[]
    for ix in range(2):
        for iz in range(2):
            var x=24.0+ix*48.0+rng.randf_range(-3,3)
            var z=24.0+iz*48.0+rng.randf_range(-3,3)
            var w=rng.randf_range(18,27)
            var d=rng.randf_range(18,27)
            var floors=rng.randi_range(7,34)
            var h=float(floors)*rng.randf_range(3.0,4.1)
            var style=rng.randi_range(0,4)
            var neon:Color=NEON[rng.randi_range(0,NEON.size()-1)]
            var base_h=h*(0.58 if style==2 or style==4 else 0.72)
            body_tx.append(Transform3D(Basis.from_scale(Vector3(w,base_h,d)),Vector3(x,base_h/2,z)))
            body_colors.append(Color(0.68,0.72,0.86).lerp(Color(0.12,0.14,0.23),rng.randf_range(0.25,0.82)))
            # Setback crowns and podiums turn each mass into a distinct skyline silhouette.
            body_tx.append(Transform3D(Basis.from_scale(Vector3(w*1.08,2.4,d*1.08)),Vector3(x,1.2,z)))
            body_colors.append(Color(0.12,0.16,0.25))
            var upper_h=h-base_h
            var upper_w=w*(0.58 if style==1 or style==4 else 0.78)
            var upper_d=d*(0.62 if style==0 or style==3 else 0.78)
            body_tx.append(Transform3D(Basis.from_scale(Vector3(upper_w,upper_h,upper_d)),Vector3(x,base_h+upper_h/2,z)))
            body_colors.append(Color(0.58,0.66,0.82).lerp(Color(0.09,0.11,0.19),rng.randf()))
            colliders.append({"p":Vector3(x,h/2,z),"s":Vector3(w,h,d)})
            # Service tanks, antenna masts and roof plant add a non-box silhouette layer.
            for tank in range(2):
                var tx=x+rng.randf_range(-w*0.28,w*0.28)
                var tz=z+rng.randf_range(-d*0.28,d*0.28)
                var tank_h=rng.randf_range(1.4,2.4)
                cylinder_tx.append(Transform3D(Basis.from_scale(Vector3(1.8,tank_h,1.8)),Vector3(tx,h+tank_h,tz)))
            cylinder_tx.append(Transform3D(Basis.from_scale(Vector3(0.16,rng.randf_range(5.0,12.0),0.16)),Vector3(x+w*0.22,h+6.0,z-d*0.2)))
            roof_tx.append(Transform3D(Basis.from_scale(Vector3(upper_w*0.78,2,upper_d*0.78)),Vector3(x,h+1,z)))
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
            # Roof plant, vents, aerials, facade billboards and corner light bars.
            for n in range(rng.randi_range(3,7)):
                var rx=x+rng.randf_range(-w*0.36,w*0.36)
                var rz=z+rng.randf_range(-d*0.36,d*0.36)
                var rh=rng.randf_range(1.0,5.0)
                roof_tx.append(Transform3D(Basis.from_scale(Vector3(rng.randf_range(1.0,3.0),rh,rng.randf_range(1.0,3.0))),Vector3(rx,h+rh/2,rz)))
            for sign_i in range(rng.randi_range(1,3)):
                var side=rng.randi_range(0,3)
                var pos=Vector3(x,rng.randf_range(4,minf(h-1,18)),z)
                var sz=Vector3(0.35,rng.randf_range(2,5),d*0.7) if side<2 else Vector3(w*0.7,rng.randf_range(2,5),0.35)
                pos.x+=(w/2+0.22)*(-1.0 if side==0 else 1.0) if side<2 else 0.0
                pos.z+=(d/2+0.22)*(-1.0 if side==2 else 1.0) if side>=2 else 0.0
                trim_tx.append(Transform3D(Basis.from_scale(sz),pos))
                trim_colors.append(neon)
    # Skybridges join adjacent towers only when both have tall enough structural cores.
    for i in colliders.size():
        for j in range(i+1,colliders.size()):
            var a=colliders[i]
            var b=colliders[j]
            var delta:Vector3=b["p"]-a["p"]
            var bridge_height=minf(a["s"].y,b["s"].y)
            if bridge_height<70.0: continue
            if abs(delta.x)>30.0 and abs(delta.z)<15.0:
                var bridge_len=maxf(3.0,abs(delta.x)-(a["s"].x+b["s"].x)*0.5)
                var bridge_pos=Vector3((a["p"].x+b["p"].x)*0.5,bridge_height*0.72,(a["p"].z+b["p"].z)*0.5)
                body_tx.append(Transform3D(Basis.from_scale(Vector3(bridge_len,1.2,3.8)),bridge_pos))
                body_colors.append(Color(0.13,0.18,0.26))
                trim_tx.append(Transform3D(Basis.from_scale(Vector3(bridge_len,0.16,4.0)),bridge_pos+Vector3(0,0.68,0)))
                trim_colors.append(NEON[(i+j)%NEON.size()])
            elif abs(delta.z)>30.0 and abs(delta.x)<15.0:
                var bridge_len=maxf(3.0,abs(delta.z)-(a["s"].z+b["s"].z)*0.5)
                var bridge_pos=Vector3((a["p"].x+b["p"].x)*0.5,bridge_height*0.72,(a["p"].z+b["p"].z)*0.5)
                body_tx.append(Transform3D(Basis.from_scale(Vector3(3.8,1.2,bridge_len)),bridge_pos))
                body_colors.append(Color(0.13,0.18,0.26))
                trim_tx.append(Transform3D(Basis.from_scale(Vector3(4.0,0.16,bridge_len)),bridge_pos+Vector3(0,0.68,0)))
                trim_colors.append(NEON[(i+j)%NEON.size()])
    _instances("BuildingMasses",body_tx,body_colors,Color(0.2,0.23,0.34),false)
    _instances("NeonBandsAndSigns",trim_tx,trim_colors,Color(0.2,0.5,0.6),true)
    _instances("WindowGrid",win_tx,win_colors,Color(0,0.65,0.9),true)
    _instances("RooftopMachinery",roof_tx,[],Color(0.09,0.14,0.21),false)
    _instances("CylindricalServiceTanksAndMasts",cylinder_tx,[],Color(0.18,0.23,0.31),false,CylinderMesh.new())
    if collision_enabled:
        var physics=StaticBody3D.new()
        physics.name="BuildingCollision"
        for data in colliders:
            var cs=CollisionShape3D.new()
            var shape=BoxShape3D.new()
            shape.size=data.s
            cs.shape=shape
            cs.position=data.p
            physics.add_child(cs)
        add_child(physics)
func _instances(label,tx:Array[Transform3D],colors:Array[Color],tint:Color,emissive:bool,mesh:Mesh=null):
    var mm=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.use_colors=true
    mm.mesh=mesh if mesh!=null else BoxMesh.new()
    mm.instance_count=tx.size()
    for i in tx.size():
        mm.set_instance_transform(i,tx[i])
        if i<colors.size(): mm.set_instance_color(i,colors[i])
    var inst=MultiMeshInstance3D.new()
    inst.name=label
    inst.multimesh=mm
    if emissive:
        var mat=ShaderMaterial.new()
        mat.shader=load("res://shaders/neon_instances.gdshader")
        mat.set_shader_parameter("emission_energy",2.0 if label=="WindowGrid" else 1.5)
        inst.material_override=mat
    else:
        var mat=StandardMaterial3D.new()
        mat.albedo_color=tint
        mat.vertex_color_use_as_albedo=true
        mat.metallic=0.68
        mat.roughness=0.28
        inst.material_override=mat
    add_child(inst)
