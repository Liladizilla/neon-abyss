extends Node3D
const ELEVATOR=preload("res://scripts/elevator_car.gd")
const LANDING_DOORS=preload("res://scripts/elevator_landing_door.gd")
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
        for x in range(5,int(size-5),9):
            tx.append(Transform3D(Basis.IDENTITY,Vector3(float(x),0.015,z)))
    # Perpendicular arterial markings use the same shared dash mesh and continue at the same
    # local cadence in every chunk, so neighbouring chunk edges do not introduce a phase jump.
    for x in [size*0.5-5.0,size*0.5+5.0]:
        for z in range(5,int(size-5),9):
            tx.append(Transform3D(Basis(Vector3(0,0,-1),Vector3.UP,Vector3(1,0,0)),Vector3(x,0.015,float(z))))
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
    _street_furniture()
    _street_detail_kit()
    _street_life_layer()
    _transit_infrastructure()

func _street_detail_kit() -> void:
    # Continuous raised pedestrian edges, drain hardware and marked crossings.
    var sidewalk_tx:Array[Transform3D]=[]
    var sidewalk_colors:Array[Color]=[]
    var curb_tx:Array[Transform3D]=[]
    var curb_colors:Array[Color]=[]
    var drain_tx:Array[Transform3D]=[]
    var drain_colors:Array[Color]=[]
    var bollard_tx:Array[Transform3D]=[]
    var bollard_colors:Array[Color]=[]
    var crossing_tx:Array[Transform3D]=[]
    var crossing_colors:Array[Color]=[]
    var utility_tx:Array[Transform3D]=[]
    var utility_colors:Array[Color]=[]
    var sidewalk_y:=0.02
    for side in [-1.0,1.0]:
        var offset:float=side*9.25
        sidewalk_tx.append(Transform3D(Basis.from_scale(Vector3(2.45,0.24,size)),Vector3(size*0.5+offset,sidewalk_y,size*0.5)))
        sidewalk_tx.append(Transform3D(Basis.from_scale(Vector3(size,0.24,2.45)),Vector3(size*0.5,sidewalk_y,size*0.5+offset)))
        sidewalk_colors.append(Color(0.18,0.2,0.25))
        sidewalk_colors.append(Color(0.18,0.2,0.25))
        curb_tx.append(Transform3D(Basis.from_scale(Vector3(0.22,0.22,size)),Vector3(size*0.5+offset+side*1.34,0.08,size*0.5)))
        curb_tx.append(Transform3D(Basis.from_scale(Vector3(size,0.22,0.22)),Vector3(size*0.5,0.08,size*0.5+offset+side*1.34)))
        curb_colors.append(Color(0.3,0.32,0.38))
        curb_colors.append(Color(0.3,0.32,0.38))
        for along in range(10,int(size)-10,8):
            drain_tx.append(Transform3D(Basis.from_scale(Vector3(0.55,0.055,0.32)),Vector3(float(along),0.13,size*0.5+offset+side*1.52)))
            drain_tx.append(Transform3D(Basis.from_scale(Vector3(0.32,0.055,0.55)),Vector3(size*0.5+offset+side*1.52,0.13,float(along))))
            drain_colors.append(Color(0.035,0.045,0.06))
            drain_colors.append(Color(0.035,0.045,0.06))
            utility_tx.append(Transform3D(Basis.from_scale(Vector3(0.08,0.07,1.2)),Vector3(size*0.5+offset,0.37,float(along))))
            utility_tx.append(Transform3D(Basis.from_scale(Vector3(1.2,0.07,0.08)),Vector3(float(along),0.37,size*0.5+offset)))
            utility_colors.append(Color(0.08,0.45,0.55))
            utility_colors.append(Color(0.08,0.45,0.55))
        for approach in [-1.0,1.0]:
            for stripe in range(7):
                var lane:=float(stripe)*0.72-2.16
                crossing_tx.append(Transform3D(Basis.from_scale(Vector3(0.46,0.035,2.8)),Vector3(size*0.5+lane,0.045,size*0.5+approach*12.4)))
                crossing_tx.append(Transform3D(Basis.from_scale(Vector3(2.8,0.035,0.46)),Vector3(size*0.5+approach*12.4,0.045,size*0.5+lane)))
                crossing_colors.append(Color(0.72,0.76,0.82))
                crossing_colors.append(Color(0.72,0.76,0.82))
            for n in range(4):
                var along:float=size*0.5+approach*(7.4+float(n)*0.72)
                bollard_tx.append(Transform3D(Basis.from_scale(Vector3(0.18,0.78,0.18)),Vector3(size*0.5+side*7.65,0.39,along)))
                bollard_tx.append(Transform3D(Basis.from_scale(Vector3(0.18,0.78,0.18)),Vector3(along,0.39,size*0.5+side*7.65)))
                bollard_colors.append(Color(0.08,0.12,0.18))
                bollard_colors.append(Color(0.08,0.12,0.18))
    _instances("ContinuousSidewalks",sidewalk_tx,sidewalk_colors,Color(0.18,0.2,0.25),false)
    _instances("RaisedSidewalkCurbs",curb_tx,curb_colors,Color(0.3,0.32,0.38),false)
    _instances("RoadDrainGrates",drain_tx,drain_colors,Color(0.035,0.045,0.06),false)
    _instances("ZebraCrossingStripes",crossing_tx,crossing_colors,Color(0.72,0.76,0.82),false)
    _instances("CrossingProtectionBollards",bollard_tx,bollard_colors,Color(0.08,0.12,0.18),false,CylinderMesh.new())
    _instances("SidewalkUtilityRuns",utility_tx,utility_colors,Color(0.08,0.45,0.55),false)
    # Visual-only chunks must not introduce hidden collision into the streaming ring.
    # Keep the detailed curb and sidewalk shapes only in the active 3x3 collision neighborhood.
    if collision_enabled:
        var sidewalk_physics:=StaticBody3D.new()
        sidewalk_physics.name="SidewalkAndCurbCollision"
        sidewalk_physics.collision_layer=1
        sidewalk_physics.collision_mask=1
        for data in sidewalk_tx:
            var shape:=BoxShape3D.new()
            shape.size=data.basis.get_scale()
            var collision:=CollisionShape3D.new()
            collision.shape=shape
            collision.position=data.origin
            sidewalk_physics.add_child(collision)
        for data in curb_tx:
            var shape:=BoxShape3D.new()
            shape.size=data.basis.get_scale()
            var collision:=CollisionShape3D.new()
            collision.shape=shape
            collision.position=data.origin
            sidewalk_physics.add_child(collision)
        add_child(sidewalk_physics)


func _street_life_layer() -> void:
    # Reusable street-level props make the exterior city feel inhabited without spawning NPCs.
    # Placement is deterministic per district, and all visual pieces remain instanced.
    var planter_tx:Array[Transform3D]=[]
    var planter_colors:Array[Color]=[]
    var foliage_tx:Array[Transform3D]=[]
    var foliage_colors:Array[Color]=[]
    var bin_tx:Array[Transform3D]=[]
    var bin_colors:Array[Color]=[]
    var bin_lid_tx:Array[Transform3D]=[]
    var bench_tx:Array[Transform3D]=[]
    var bench_colors:Array[Color]=[]
    var bench_back_tx:Array[Transform3D]=[]
    var bench_leg_tx:Array[Transform3D]=[]
    var utility_tx:Array[Transform3D]=[]
    var utility_colors:Array[Color]=[]
    var utility_trim_tx:Array[Transform3D]=[]
    var colliders:Array[Dictionary]=[]
    var planter_mat:=Color(0.065,0.085,0.105)
    var bench_mat:=Color(0.12,0.15,0.19)
    var utility_mat:=Color(0.045,0.065,0.09)
    var foliage_palette:Array[Color]=[Color(0.055,0.19,0.12),Color(0.09,0.24,0.14),Color(0.13,0.22,0.12)]
    for axis in [0,1]:
        for side in [-1.0,1.0]:
            for slot in range(4):
                var along:float=[16.0,28.0,68.0,80.0][slot]
                var p:Vector3
                if axis==0:
                    p=Vector3(size*0.5+side*9.25,0.0,along)
                else:
                    p=Vector3(along,0.0,size*0.5+side*9.25)
                var yaw:float=PI*0.5 if axis==0 else 0.0
                match slot:
                    0:
                        var planter_size:=Vector3(1.45,0.58,0.72)
                        planter_tx.append(Transform3D(Basis.from_scale(planter_size),p+Vector3(0,0.29,0)))
                        planter_colors.append(planter_mat)
                        var foliage_size:=Vector3(0.64,0.72,0.46)
                        foliage_tx.append(Transform3D(Basis.from_scale(foliage_size),p+Vector3(0,0.88,0)))
                        foliage_colors.append(foliage_palette[posmod(coord.x+coord.y+int(side),foliage_palette.size())])
                        colliders.append({"p":p+Vector3(0,0.29,0),"s":planter_size,"yaw":0.0})
                    1:
                        var bin_size:=Vector3(0.48,0.88,0.48)
                        bin_tx.append(Transform3D(Basis.from_scale(bin_size),p+Vector3(0,0.46,0)))
                        bin_colors.append(Color(0.035,0.055,0.07))
                        bin_lid_tx.append(Transform3D(Basis.from_scale(Vector3(0.56,0.09,0.56)),p+Vector3(0,0.92,0)))
                        colliders.append({"p":p+Vector3(0,0.46,0),"s":Vector3(0.56,0.94,0.56),"yaw":0.0})
                    2:
                        var seat_size:=Vector3(1.55,0.13,0.44)
                        var seat_pos:=p+Vector3(0,0.52,0)
                        var back_size:=Vector3(1.55,0.62,0.12)
                        var basis:=Basis.from_euler(Vector3(0,yaw,0))
                        var back_pos:=p+basis*Vector3(0,0.86,-0.19)
                        bench_tx.append(Transform3D(basis.scaled(seat_size),seat_pos))
                        bench_colors.append(bench_mat)
                        bench_back_tx.append(Transform3D(basis.scaled(back_size),back_pos))
                        for leg_x in [-0.62,0.62]:
                            var leg_size:=Vector3(0.09,0.48,0.09)
                            var leg_pos:=p+basis*Vector3(leg_x,0.25,0)
                            bench_leg_tx.append(Transform3D(basis.scaled(leg_size),leg_pos))
                        colliders.append({"p":seat_pos,"s":seat_size,"yaw":yaw})
                        colliders.append({"p":back_pos,"s":back_size,"yaw":yaw})
                    3:
                        var cabinet_size:=Vector3(0.72,1.05,0.54)
                        var cabinet_pos:=p+Vector3(0,0.53,0)
                        utility_tx.append(Transform3D(Basis.from_scale(cabinet_size),cabinet_pos))
                        utility_colors.append(utility_mat)
                        var trim_size:=Vector3(0.055,0.72,0.035)
                        var trim_pos:=cabinet_pos+Vector3(0.0,0.0,0.29)
                        utility_trim_tx.append(Transform3D(Basis.from_scale(trim_size),trim_pos))
                        colliders.append({"p":cabinet_pos,"s":cabinet_size,"yaw":0.0})
    _instances("StreetPlanterTroughs",planter_tx,planter_colors,planter_mat,false)
    _instances("StreetOvergrowth",foliage_tx,foliage_colors,Color(0.08,0.2,0.12),false,SphereMesh.new())
    _instances("StreetWasteBins",bin_tx,bin_colors,Color(0.035,0.055,0.07),false,CylinderMesh.new())
    _instances("StreetWasteBinLids",bin_lid_tx,[],Color(0.09,0.12,0.16),false)
    _instances("StreetBenchSeats",bench_tx,bench_colors,bench_mat,false)
    _instances("StreetBenchBacks",bench_back_tx,[],bench_mat,false)
    _instances("StreetBenchLegs",bench_leg_tx,[],Color(0.045,0.06,0.08),false)
    _instances("StreetUtilityCabinets",utility_tx,utility_colors,utility_mat,false)
    _instances("StreetUtilityCabinetTrim",utility_trim_tx,[],Color(0.02,0.72,0.88),true)
    # One district body keeps prop collisions cheap; visual-only chunks remain non-solid.
    if collision_enabled:
        var prop_body:=StaticBody3D.new()
        prop_body.name="StreetLifePropCollision"
        prop_body.collision_layer=1
        prop_body.collision_mask=1
        for data in colliders:
            var shape:=BoxShape3D.new()
            shape.size=data.s
            var collision:=CollisionShape3D.new()
            collision.shape=shape
            collision.position=data.p
            collision.rotation.y=float(data.get("yaw",0.0))
            prop_body.add_child(collision)
        add_child(prop_body)

func _transit_infrastructure():
    # Elevated guideway follows the district's east-west arterial.
    var rails:Array[Transform3D]=[]
    var supports:Array[Transform3D]=[]
    for side in [-1.0,1.0]:
        rails.append(Transform3D(Basis.from_scale(Vector3(size,0.28,0.32)),Vector3(size*0.5,12.5,size*0.5+side*1.8)))
    for along in [12.0,36.0,60.0,84.0]:
        supports.append(Transform3D(Basis.from_scale(Vector3(0.8,6.0,0.8)),Vector3(along,6.0,size*0.5)))
    _instances("ElevatedTransitRails",rails,[],Color(0.16,0.2,0.29),false)
    _instances("TransitGuidewayPylons",supports,[],Color(0.12,0.16,0.23),false)

    # Vertical-city infrastructure: three reusable elevated service decks per district.
    # They form a layered silhouette above street level and align exactly with chunk edges.
    var deck_tx:Array[Transform3D]=[]
    var deck_colors:Array[Color]=[]
    var beam_tx:Array[Transform3D]=[]
    var beam_colors:Array[Color]=[]
    var pylon_tx:Array[Transform3D]=[]
    var pylon_colors:Array[Color]=[]
    var cable_tx:Array[Transform3D]=[]
    var cable_colors:Array[Color]=[]
    var deck_heights:Array[float]=[27.0,49.0,73.0]
    for deck_index in range(deck_heights.size()):
        var deck_y:float=deck_heights[deck_index]
        var deck_tint:Array[Color]=[Color(0.10,0.14,0.20),Color(0.075,0.11,0.17),Color(0.055,0.085,0.14)]
        # Longitudinal decks stay clear of the central transit spine and are repeated per chunk.
        for side in [-1.0,1.0]:
            var lane_z:float=size*0.5+side*12.0
            deck_tx.append(Transform3D(Basis.from_scale(Vector3(size,0.72,3.2)),Vector3(size*0.5,deck_y,lane_z)))
            deck_colors.append(deck_tint[deck_index])
            beam_tx.append(Transform3D(Basis.from_scale(Vector3(size,0.18,0.18)),Vector3(size*0.5,deck_y+0.42,lane_z-1.62)))
            beam_tx.append(Transform3D(Basis.from_scale(Vector3(size,0.18,0.18)),Vector3(size*0.5,deck_y+0.42,lane_z+1.62)))
            beam_colors.append(Color(0.02,0.65,0.82))
            beam_colors.append(Color(0.02,0.65,0.82))
            for along in [12.0,36.0,60.0,84.0]:
                pylon_tx.append(Transform3D(Basis.from_scale(Vector3(0.72,deck_y-1.0,0.72)),Vector3(along,deck_y*0.5,lane_z)))
                pylon_colors.append(Color(0.055,0.075,0.11))
            # Thin overhead utility conduits add infrastructure detail without unique meshes.
            cable_tx.append(Transform3D(Basis.from_scale(Vector3(size,0.12,0.12)),Vector3(size*0.5,deck_y+1.15,lane_z)))
            cable_colors.append(Color(0.12,0.25,0.32))
        # Cross-district deck segments use matching heights and repeat on every chunk.
        for side in [-1.0,1.0]:
            var lane_x:float=size*0.5+side*12.0
            deck_tx.append(Transform3D(Basis.from_scale(Vector3(3.2,0.72,size)),Vector3(lane_x,deck_y,size*0.5)))
            deck_colors.append(deck_tint[deck_index])
            beam_tx.append(Transform3D(Basis.from_scale(Vector3(0.18,0.18,size)),Vector3(lane_x-1.62,deck_y+0.42,size*0.5)))
            beam_tx.append(Transform3D(Basis.from_scale(Vector3(0.18,0.18,size)),Vector3(lane_x+1.62,deck_y+0.42,size*0.5)))
            beam_colors.append(Color(0.02,0.65,0.82))
            beam_colors.append(Color(0.02,0.65,0.82))
            for along in [12.0,36.0,60.0,84.0]:
                pylon_tx.append(Transform3D(Basis.from_scale(Vector3(0.72,deck_y-1.0,0.72)),Vector3(lane_x,deck_y*0.5,along)))
                pylon_colors.append(Color(0.055,0.075,0.11))
            cable_tx.append(Transform3D(Basis.from_scale(Vector3(0.12,0.12,size)),Vector3(lane_x,deck_y+1.15,size*0.5)))
            cable_colors.append(Color(0.12,0.25,0.32))
    _instances("StackedSkyLaneDecks",deck_tx,deck_colors,Color(0.08,0.12,0.18),false)
    _instances("SkyLaneGuardBeams",beam_tx,beam_colors,Color(0.02,0.65,0.82),true)
    _instances("SkyLaneStructuralPylons",pylon_tx,pylon_colors,Color(0.055,0.075,0.11),false)
    _instances("ElevatedUtilityConduits",cable_tx,cable_colors,Color(0.12,0.25,0.32),false)

    # Give every elevated deck a matching physical surface in nearby chunks.
    # The visual MultiMeshes remain batched; collision uses one shared unit box shape per deck.
    if collision_enabled:
        var deck_physics:=StaticBody3D.new()
        deck_physics.name="StackedSkyLaneDeckCollision"
        deck_physics.collision_layer=1
        deck_physics.collision_mask=1
        var unit_deck_shape:=BoxShape3D.new()
        unit_deck_shape.size=Vector3.ONE
        for deck_transform in deck_tx:
            var deck_collision:=CollisionShape3D.new()
            deck_collision.shape=unit_deck_shape
            deck_collision.transform=deck_transform
            deck_physics.add_child(deck_collision)
        add_child(deck_physics)

    # Walkable connector ramps: segmented inclines join street-level approaches to the first
    # elevated deck. These are physical ramps, not teleport links; they are repeated per chunk.
    var ramp_tx:Array[Transform3D]=[]
    var ramp_colors:Array[Color]=[]
    var ramp_rail_tx:Array[Transform3D]=[]
    var ramp_rail_colors:Array[Color]=[]
    var ramp_support_tx:Array[Transform3D]=[]
    var ramp_support_colors:Array[Color]=[]
    var ramp_colliders:Array[Dictionary]=[]
    var ramp_start:=Vector3(size*0.5-18.0,0.55,size*0.5+17.0)
    var ramp_end:=Vector3(size*0.5-18.0,27.0,size*0.5+12.0)
    var ramp_delta:=ramp_end-ramp_start
    var ramp_length:=ramp_delta.length()
    var ramp_basis:=Basis(Vector3.RIGHT, ramp_delta.normalized().cross(Vector3.RIGHT).normalized(), ramp_delta.normalized())
    # Use a vertical axis and the incline direction as a stable basis for the long deck pieces.
    var ramp_forward:=ramp_delta.normalized()
    var ramp_right:=Vector3.RIGHT
    var ramp_up:=ramp_right.cross(ramp_forward).normalized()
    ramp_basis=Basis(ramp_right,ramp_up,ramp_forward)
    for segment in range(18):
        var t:float=(float(segment)+0.5)/18.0
        var point:=ramp_start.lerp(ramp_end,t)
        var basis:=ramp_basis
        ramp_tx.append(Transform3D(basis.scaled(Vector3(3.2,0.28,ramp_length/18.0+0.08)),point))
        ramp_colors.append(Color(0.09,0.13,0.19))
        for side in [-1.0,1.0]:
            var rail_point:=point+Vector3(side*1.52,0.72,0)
            ramp_rail_tx.append(Transform3D(Basis.from_scale(Vector3(0.12,1.1,ramp_length/18.0+0.08)),rail_point))
            ramp_rail_colors.append(Color(0.02,0.62,0.82))
    for along in [0.0,0.25,0.5,0.75,1.0]:
        var support_point:=ramp_start.lerp(ramp_end,along)
        var support_height:=maxf(0.8,support_point.y)
        ramp_support_tx.append(Transform3D(Basis.from_scale(Vector3(0.46,support_height,0.46)),Vector3(support_point.x,support_height*0.5,support_point.z)))
        ramp_support_colors.append(Color(0.055,0.075,0.11))
    _instances("SkyLaneAccessRampDeck",ramp_tx,ramp_colors,Color(0.09,0.13,0.19),false)
    _instances("SkyLaneAccessRampRails",ramp_rail_tx,ramp_rail_colors,Color(0.02,0.62,0.82),true)
    _instances("SkyLaneAccessRampSupports",ramp_support_tx,ramp_support_colors,Color(0.055,0.075,0.11),false)

    # Compact stair flights connect the three deck elevations at a protected service core.
    # Their treads are repeated box instances; active chunks also receive matching collision.
    var stair_tx:Array[Transform3D]=[]
    var stair_colors:Array[Color]=[]
    var stair_collision_transforms:Array[Transform3D]=[]
    var stair_levels:Array[Vector2]=[Vector2(27.0,49.0),Vector2(49.0,73.0)]
    for flight in range(stair_levels.size()):
        var lower:float=stair_levels[flight].x
        var upper:float=stair_levels[flight].y
        var flight_x:float=size*0.5+float(flight)*8.0+8.0
        var flight_z:float=size*0.5-15.0
        var steps:int=130
        for step in range(steps):
            var t:float=float(step)/float(steps-1)
            var tread_y:float=lower+1.0+t*(upper-lower)
            var tread_z:float=flight_z-t*36.0
            var tread_transform:=Transform3D(Basis.from_scale(Vector3(2.8,0.28,0.62)),Vector3(flight_x,tread_y,tread_z))
            stair_tx.append(tread_transform)
            stair_colors.append(Color(0.12,0.16,0.22))
            stair_collision_transforms.append(tread_transform)
    _instances("SkyLaneInterdeckStairs",stair_tx,stair_colors,Color(0.12,0.16,0.22),false)
    if collision_enabled:
        var stair_physics:=StaticBody3D.new()
        stair_physics.name="SkyLaneInterdeckStairCollision"
        stair_physics.collision_layer=1
        stair_physics.collision_mask=1
        var unit_tread:=BoxShape3D.new()
        unit_tread.size=Vector3.ONE
        for tread_transform in stair_collision_transforms:
            var tread_collision:=CollisionShape3D.new()
            tread_collision.shape=unit_tread
            tread_collision.transform=tread_transform
            stair_physics.add_child(tread_collision)
        add_child(stair_physics)

    if collision_enabled:
        var ramp_physics:=StaticBody3D.new()
        ramp_physics.name="SkyLaneRampCollision"
        ramp_physics.collision_layer=1
        ramp_physics.collision_mask=1
        for segment in range(18):
            var t:float=(float(segment)+0.5)/18.0
            var point:=ramp_start.lerp(ramp_end,t)
            var shape:=BoxShape3D.new()
            shape.size=Vector3(3.2,0.36,ramp_length/18.0+0.1)
            var collision:=CollisionShape3D.new()
            collision.shape=shape
            collision.transform=Transform3D(ramp_basis,point)
            ramp_physics.add_child(collision)
        add_child(ramp_physics)
    if posmod(coord.x,3)==0:
        var station=Node3D.new()
        station.name="ElevatedTransitStation"
        station.position=Vector3.ZERO
        add_child(station)
        var platform=MeshInstance3D.new()
        var platform_mesh=BoxMesh.new()
        platform_mesh.size=Vector3(34.0,0.7,4.6)
        platform.mesh=platform_mesh
        platform.position=Vector3(size*0.5,10.4,size*0.5+5.2)
        var platform_mat=StandardMaterial3D.new()
        platform_mat.albedo_color=Color(0.08,0.11,0.18)
        platform_mat.metallic=0.48
        platform_mat.roughness=0.34
        platform.material_override=platform_mat
        station.add_child(platform)
        var canopy=MeshInstance3D.new()
        var canopy_mesh=BoxMesh.new()
        canopy_mesh.size=Vector3(34.0,0.28,5.6)
        canopy.mesh=canopy_mesh
        canopy.position=Vector3(size*0.5,15.1,size*0.5+5.2)
        var canopy_mat=StandardMaterial3D.new()
        canopy_mat.albedo_color=Color(0.035,0.06,0.1)
        canopy_mat.metallic=0.7
        canopy_mat.roughness=0.25
        canopy.material_override=canopy_mat
        station.add_child(canopy)
        for along in [size*0.5-15.0,size*0.5+15.0]:
            var pillar=MeshInstance3D.new()
            var pillar_mesh=BoxMesh.new()
            pillar_mesh.size=Vector3(0.45,4.4,0.45)
            pillar.mesh=pillar_mesh
            pillar.position=Vector3(along,13.0,size*0.5+5.2)
            pillar.material_override=platform_mat
            station.add_child(pillar)
        var edge=MeshInstance3D.new()
        var edge_mesh=BoxMesh.new()
        edge_mesh.size=Vector3(33.0,0.12,0.16)
        edge.mesh=edge_mesh
        edge.position=Vector3(size*0.5,10.8,size*0.5+3.0)
        var edge_mat=StandardMaterial3D.new()
        edge_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        edge_mat.albedo_color=Color(0.02,0.78,1.0)
        edge_mat.emission_enabled=true
        edge_mat.emission=Color(0.01,0.55,1.0)
        edge_mat.emission_energy_multiplier=2.0
        edge.material_override=edge_mat
        station.add_child(edge)
func _street_furniture():
    # Street furniture is instanced per district to keep draw calls bounded.
    var poles:Array[Transform3D]=[]
    var arms:Array[Transform3D]=[]
    var emitters:Array[Transform3D]=[]
    var emitter_colors:Array[Color]=[]
    var curbs:Array[Transform3D]=[]
    var curb_colors:Array[Color]=[]
    var ramp_tx:Array[Transform3D]=[]
    var ramp_colors:Array[Color]=[]
    var tactile_tx:Array[Transform3D]=[]
    var tactile_colors:Array[Color]=[]
    var tactile_mat=Color(0.62,0.57,0.39)
    var pole_color=Color(0.13,0.17,0.25)
    for n in range(4):
        var along=12.0+float(n)*24.0
        for side in [-1.0,1.0]:
            var px=size*0.5+side*7.2
            poles.append(Transform3D(Basis.from_scale(Vector3(0.09,2.8,0.09)),Vector3(px,2.8,along)))
            arms.append(Transform3D(Basis.from_scale(Vector3(1.25,0.08,0.08)),Vector3(px-side*0.52,5.45,along)))
            emitters.append(Transform3D(Basis.from_scale(Vector3(0.68,0.1,0.32)),Vector3(px-side*0.95,5.35,along)))
            emitter_colors.append(Color(0.08,0.75,1.0) if (n+int(side))%2==0 else Color(1.0,0.22,0.68))
            poles.append(Transform3D(Basis.from_scale(Vector3(0.09,2.8,0.09)),Vector3(along,2.8,px)))
            arms.append(Transform3D(Basis.from_scale(Vector3(0.08,0.08,1.25)),Vector3(along,5.45,px-side*0.52)))
            emitters.append(Transform3D(Basis.from_scale(Vector3(0.32,0.1,0.68)),Vector3(along,5.35,px-side*0.95)))
            emitter_colors.append(Color(0.08,0.75,1.0) if (n+int(side))%2==0 else Color(1.0,0.22,0.68))
    for side in [-1.0,1.0]:
        for n in range(5):
            var along=18.0+float(n)*15.0
            curbs.append(Transform3D(Basis.from_scale(Vector3(0.45,0.22,4.0)),Vector3(size*0.5+side*9.1,0.08,along)))
            curb_colors.append(Color(0.22,0.25,0.34))
            curbs.append(Transform3D(Basis.from_scale(Vector3(4.0,0.22,0.45)),Vector3(along,0.08,size*0.5+side*9.1)))
            curb_colors.append(Color(0.22,0.25,0.34))
    _instances("StreetLampPoles",poles,[],pole_color,false,CylinderMesh.new())
    _instances("StreetLampArms",arms,[],pole_color,false)
    _instances("StreetLampEmitters",emitters,emitter_colors,Color.WHITE,true)
    # Accessible crossing approaches: shallow ramp panels meet the curb edge, with tactile pads at the sidewalk decision point.
    for side in [-1.0,1.0]:
        for axis in [0,1]:
            for approach in [-1.0,1.0]:
                var p:Vector3
                var ramp_size:Vector3
                var rotation:Vector3=Vector3.ZERO
                if axis==0:
                    p=Vector3(size*0.5+side*8.25,0.08,size*0.5+approach*11.0)
                    ramp_size=Vector3(1.7,0.12,2.0)
                    rotation.z=-side*0.10
                else:
                    p=Vector3(size*0.5+approach*11.0,0.08,size*0.5+side*8.25)
                    ramp_size=Vector3(2.0,0.12,1.7)
                    rotation.x=side*0.10
                ramp_tx.append(Transform3D(Basis.from_euler(rotation).scaled(ramp_size),p))
                ramp_colors.append(Color(0.29,0.32,0.37))
                # Match the rotated panel with a physical collider so the curb cut is not decorative.
                var ramp_body:=StaticBody3D.new()
                ramp_body.name="CurbRampCollision_%d_%d_%d" % [int(side),axis,int(approach)]
                ramp_body.position=p
                ramp_body.rotation=rotation
                var ramp_collision:=CollisionShape3D.new()
                var ramp_shape:=BoxShape3D.new()
                ramp_shape.size=ramp_size
                ramp_collision.shape=ramp_shape
                ramp_body.add_child(ramp_collision)
                add_child(ramp_body)
                var pad_pos=p+Vector3(0,0.09,0)
                tactile_tx.append(Transform3D(Basis.from_scale(Vector3(1.45,0.035,0.55)),pad_pos))
                tactile_colors.append(tactile_mat)
    _instances("RaisedCurbSegments",curbs,curb_colors,Color(0.16,0.18,0.24),false)
    _instances("CrossingCurbRamps",ramp_tx,ramp_colors,Color(0.29,0.32,0.37),false)
    _instances("TactileCrossingPads",tactile_tx,tactile_colors,tactile_mat,false)
func _build():
    var body_tx:Array[Transform3D]=[]
    var body_colors:Array[Color]=[]
    var frontage_glass_tx:Array[Transform3D]=[]
    var frontage_glass_colors:Array[Color]=[]
    var frontage_frame_tx:Array[Transform3D]=[]
    var frontage_frame_colors:Array[Color]=[]
    var service_door_tx:Array[Transform3D]=[]
    var service_door_colors:Array[Color]=[]
    var base_growth_tx:Array[Transform3D]=[]
    var base_growth_colors:Array[Color]=[]
    var district_profile:int=posmod(abs(coord.x*17+coord.y*31+seed_value),4)
    var district_accent:Array[Color]=[Color(0.0,0.72,0.92),Color(1.0,0.25,0.08),Color(0.38,0.95,0.42),Color(0.72,0.32,1.0)]
    var trim_tx:Array[Transform3D]=[]
    var trim_colors:Array[Color]=[]
    var win_tx:Array[Transform3D]=[]
    var win_colors:Array[Color]=[]
    var roof_tx:Array[Transform3D]=[]
    var cylinder_tx:Array[Transform3D]=[]
    var colliders:Array[Dictionary]=[]
    var lift_tx:Array[Transform3D]=[]
    var lift_colors:Array[Color]=[]
    var lift_landing_tx:Array[Transform3D]=[]
    var lift_landing_colors:Array[Color]=[]
    var lift_colliders:Array[Dictionary]=[]
    for ix in range(2):
        for iz in range(2):
            var x=24.0+ix*48.0+rng.randf_range(-3,3)
            var z=24.0+iz*48.0+rng.randf_range(-3,3)
            var w=rng.randf_range(18,27)
            var d=rng.randf_range(18,27)
            var floors=rng.randi_range(18,42)
            var h=float(floors)*rng.randf_range(3.0,4.1)
            var style=rng.randi_range(0,4)
            var building_index=ix*2+iz
            var neon:Color=NEON[rng.randi_range(0,NEON.size()-1)]
            var base_h=h*(0.58 if style==2 or style==4 else 0.72)
            var upper_h=h-base_h
            var upper_w=w*(0.58 if style==1 or style==4 else 0.78)
            var upper_d=d*(0.62 if style==0 or style==3 else 0.78)
            var shell_color=Color(0.68,0.72,0.86).lerp(Color(0.12,0.14,0.23),rng.randf_range(0.25,0.82))
            # District palettes change the identity, not the architectural detail density.
            shell_color=shell_color.lerp(district_accent[district_profile],0.12)
            var frontage_glass_color:Color=[Color(0.025,0.34,0.42),Color(0.34,0.12,0.035),Color(0.06,0.28,0.13),Color(0.22,0.09,0.34)][district_profile]
            var frontage_neon:Color=district_accent[district_profile]
            # Fire-escape towers receive matching open doorway cut-outs at every served floor.
            var has_fire_escape:bool=posmod(building_index,3)==0 and floors>=4
            # Hollow shell replaces the old solid tower mass with walkable floor plates and stairs.
            _append_hollow_tower(body_tx,body_colors,colliders,x,z,w,d,h,floors,base_h,upper_w,upper_d,shell_color,has_fire_escape)
            # Exterior glass elevator core with a visible landing for every generated floor.
            var lift_x=x+w*0.5+4.6
            var floor_height=h/float(floors)
            var lift_car: Node3D = _add_elevator_car(lift_x,z,h,floors,building_index)
            for side_x in [-1.0,1.0]:
                for side_z in [-1.0,1.0]:
                    lift_tx.append(Transform3D(Basis.from_scale(Vector3(0.22,h,0.22)),Vector3(lift_x+side_x*1.35,h*0.5,z+side_z*1.35)))
            lift_tx.append(Transform3D(Basis.from_scale(Vector3(0.08,h,0.08)),Vector3(lift_x-1.35,h*0.5,z)))
            lift_tx.append(Transform3D(Basis.from_scale(Vector3(0.08,h,0.08)),Vector3(lift_x+1.35,h*0.5,z)))
            lift_colors.append(Color(0.08,0.16,0.24))
            lift_colors.append(Color(0.08,0.16,0.24))
            lift_colors.append(Color(0.08,0.16,0.24))
            lift_colors.append(Color(0.08,0.16,0.24))
            lift_colors.append(Color(0.02,0.78,1.0))
            lift_colors.append(Color(0.02,0.78,1.0))
            for floor_level in range(1,floors+1):
                var landing_y=float(floor_level-1)*floor_height+0.15
                lift_landing_tx.append(Transform3D(Basis.from_scale(Vector3(3.7,0.18,3.7)),Vector3(lift_x,landing_y,z)))
                lift_landing_colors.append(Color(0.07,0.12,0.19))
                lift_colliders.append({"p":Vector3(lift_x,landing_y,z),"s":Vector3(3.7,0.18,3.7)})
                # Align each bridge with the actual floor footprint; upper tower setbacks vary by style.
                var floor_wall_height: float = maxf(0.2,floor_height-0.12)
                var floor_mid_y: float = float(floor_level-1)*floor_height+floor_wall_height*0.5
                var floor_width: float = upper_w if floor_mid_y >= base_h else w
                var facade_x: float = x+floor_width*0.5
                var landing_inner_x: float = lift_x-1.85
                var bridge_length: float = maxf(0.8,landing_inner_x-facade_x+0.25)
                var facade_bridge: Vector3 = Vector3((facade_x+landing_inner_x)*0.5,landing_y,z)
                var bridge_size: Vector3 = Vector3(bridge_length,0.18,2.8)
                lift_landing_tx.append(Transform3D(Basis.from_scale(bridge_size),facade_bridge))
                lift_landing_colors.append(Color(0.07,0.12,0.19))
                lift_colliders.append({"p":facade_bridge,"s":bridge_size})
                # Recessed corridor guide strips lead to the elevator opening without blocking movement.
                for guide_side in [-1.0,1.0]:
                    var guide_size: Vector3 = Vector3(maxf(1.0, floor_width*0.5-2.1),0.035,0.055)
                    var guide_pos: Vector3 = Vector3(x+floor_width*0.25,landing_y+0.13,z+guide_side*1.22)
                    lift_landing_tx.append(Transform3D(Basis.from_scale(guide_size),guide_pos))
                    lift_landing_colors.append(Color(0.02,0.48,0.72))
                # Lit doorway trim marks the real opening in the tower's side wall.
                var frame_mat_color: Color = Color(0.02,0.72,0.88)
                for frame_side in [-1.0,1.0]:
                    var frame_size: Vector3 = Vector3(0.12,2.35,0.12)
                    var frame_pos: Vector3 = Vector3(facade_x-0.22,landing_y+1.25,z+frame_side*1.68)
                    lift_landing_tx.append(Transform3D(Basis.from_scale(frame_size),frame_pos))
                    lift_landing_colors.append(frame_mat_color)
                var header_size: Vector3 = Vector3(0.12,0.12,3.48)
                var header_pos: Vector3 = Vector3(facade_x-0.22,landing_y+2.48,z)
                lift_landing_tx.append(Transform3D(Basis.from_scale(header_size),header_pos))
                lift_landing_colors.append(frame_mat_color)
                lift_landing_tx.append(Transform3D(Basis.from_scale(Vector3(3.65,0.06,0.08)),Vector3(lift_x,landing_y+0.12,z-1.82)))
                lift_landing_colors.append(Color(0.02,0.72,1.0))
                # Full-length guardrails follow each bridge, including deeper upper-floor setbacks.
                for rail_side in [-1.0,1.0]:
                    var rail_pos: Vector3 = facade_bridge+Vector3(0.0,0.48,rail_side*1.34)
                    var rail_size: Vector3 = Vector3(bridge_length,0.92,0.10)
                    lift_landing_tx.append(Transform3D(Basis.from_scale(rail_size),rail_pos))
                    lift_landing_colors.append(Color(0.035,0.13,0.19))
                    lift_colliders.append({"p":rail_pos,"s":rail_size})
                # Landing doors are individual meshes so the correct floor can open on arrival.
                var landing_door = LANDING_DOORS.new()
                landing_door.position=Vector3(lift_x,0.0,z)
                landing_door.call("configure",floor_level,landing_y)
                add_child(landing_door)
                lift_car.connect("travel_started",Callable(landing_door,"on_travel_started"))
                lift_car.connect("floor_arrived",Callable(landing_door,"on_floor_arrived"))
                if floor_level==1:
                    landing_door.call("open_doors",false)
                # A vertical floor-call display sits beside the doorway.
                var door_y:float=landing_y+1.08
                var door_z:float=z+1.78
                var display_pos:=Vector3(lift_x+1.28,door_y+0.34,door_z)
                lift_landing_tx.append(Transform3D(Basis.from_scale(Vector3(0.24,0.62,0.08)),display_pos))
                lift_landing_colors.append(Color(0.01,0.035,0.055))
                lift_landing_tx.append(Transform3D(Basis.from_scale(Vector3(0.12,0.025,0.035)),display_pos+Vector3(0,0.13,0.055)))
                lift_landing_colors.append(Color(0.02,0.88,1.0))
                lift_landing_tx.append(Transform3D(Basis.from_scale(Vector3(0.07,0.07,0.035)),display_pos+Vector3(0,-0.12,0.055)))
                lift_landing_colors.append(Color(1.0,0.24,0.12))
                # Explicit floor labels make the landing legible without relying on color alone.
                var floor_label := Label3D.new()
                floor_label.name = "LiftFloorLabel_B%d_F%02d" % [building_index,floor_level]
                floor_label.text = "F%02d" % floor_level
                floor_label.font_size = 32
                floor_label.outline_size = 6
                floor_label.modulate = Color(0.2,0.9,1.0)
                floor_label.position = display_pos+Vector3(0.0,0.0,0.12)
                floor_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
                add_child(floor_label)
            # Service tanks, antenna masts and roof plant add a non-box silhouette layer.
            for tank in range(2):
                var tx=x+rng.randf_range(-w*0.28,w*0.28)
                var tz=z+rng.randf_range(-d*0.28,d*0.28)
                var tank_h=rng.randf_range(1.4,2.4)
                cylinder_tx.append(Transform3D(Basis.from_scale(Vector3(1.8,tank_h,1.8)),Vector3(tx,h+tank_h,tz)))
            cylinder_tx.append(Transform3D(Basis.from_scale(Vector3(0.16,rng.randf_range(5.0,12.0),0.16)),Vector3(x+w*0.22,h+6.0,z-d*0.2)))
            roof_tx.append(Transform3D(Basis.from_scale(Vector3(upper_w*0.78,2,upper_d*0.78)),Vector3(x,h+1,z)))
            roof_tx.append(Transform3D(Basis.from_scale(Vector3(1.1,rng.randf_range(5,15),1.1)),Vector3(x+w*0.22,h+7,z-d*0.2)))
            for level in range(2,floors,2):
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
                if level%8==2:
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
            # Ground-floor use profile is deterministic per building and district.
            # The kit is visual-only; solid tower walls and real doorway collision remain authoritative.
            var frontage_kind:int=posmod(building_index+district_profile,4)
            var building_use:String=["retail","residential_lobby","maintenance","loading"][frontage_kind]
            var frontage_z:float=z-d*0.5-0.30
            var pane_count:int=maxi(3,int(w/3.2))
            var service_x:float=x+w*0.5-1.05
            if frontage_kind==0:
                # Retail frontage: broad panes with a sign band, leaving the central lobby axis clear.
                for pane_index in range(pane_count):
                    var pane_x:float=x-w*0.5+(float(pane_index)+0.5)*w/float(pane_count)
                    if abs(pane_x-x)<1.25 or abs(pane_x-service_x)<1.0:
                        continue
                    var pane_size:=Vector3(maxf(0.8,w/float(pane_count)-0.18),1.55,0.075)
                    frontage_glass_tx.append(Transform3D(Basis.from_scale(pane_size),Vector3(pane_x,1.55,frontage_z)))
                    frontage_glass_colors.append(frontage_glass_color)
                    frontage_frame_tx.append(Transform3D(Basis.from_scale(Vector3(0.09,1.72,0.12)),Vector3(pane_x-w/float(pane_count)*0.5+0.04,1.55,frontage_z-0.04)))
                    frontage_frame_colors.append(Color(0.045,0.065,0.085))
                frontage_frame_tx.append(Transform3D(Basis.from_scale(Vector3(minf(w*0.72,12.0),0.34,0.16)),Vector3(x,3.0,frontage_z-0.08)))
                frontage_frame_colors.append(frontage_neon)
            elif frontage_kind==1:
                # Residential lobby: frame the actual centered shell opening without glazing over it.
                for wing_side in [-1.0,1.0]:
                    frontage_glass_tx.append(Transform3D(Basis.from_scale(Vector3(0.48,1.95,0.075)),Vector3(x+wing_side*1.43,1.20,frontage_z)))
                    frontage_glass_colors.append(Color(0.025,0.12,0.16))
                    frontage_frame_tx.append(Transform3D(Basis.from_scale(Vector3(0.10,2.35,0.14)),Vector3(x+wing_side*1.28,1.22,frontage_z-0.08)))
                    frontage_frame_colors.append(frontage_neon)
                frontage_frame_tx.append(Transform3D(Basis.from_scale(Vector3(2.55,0.16,0.14)),Vector3(x,2.55,frontage_z-0.08)))
                frontage_frame_colors.append(frontage_neon)
            elif frontage_kind==2:
                # Maintenance profile uses the real centered shell opening, not a fake side door in solid wall.
                service_door_tx.append(Transform3D(Basis.from_scale(Vector3(1.28,2.10,0.055)),Vector3(x,1.08,frontage_z-0.07)))
                service_door_colors.append(Color(0.035,0.045,0.06))
                for jamb_side in [-1.0,1.0]:
                    frontage_frame_tx.append(Transform3D(Basis.from_scale(Vector3(0.08,2.22,0.12)),Vector3(x+jamb_side*0.83,1.08,frontage_z-0.12)))
                    frontage_frame_colors.append(frontage_neon)
                frontage_frame_tx.append(Transform3D(Basis.from_scale(Vector3(0.22,0.22,0.12)),Vector3(x,2.38,frontage_z-0.14)))
                frontage_frame_colors.append(Color(1.0,0.18,0.06))
            else:
                # Loading shutter detail stays centered on the existing opening and remains visual-only.
                var shutter_width:float=1.35
                for slat in range(7):
                    frontage_frame_tx.append(Transform3D(Basis.from_scale(Vector3(shutter_width,0.07,0.12)),Vector3(x,0.42+float(slat)*0.25,frontage_z-0.10)))
                    frontage_frame_colors.append(Color(0.22,0.27,0.32))
                for guard_side in [-1.0,1.0]:
                    frontage_frame_tx.append(Transform3D(Basis.from_scale(Vector3(0.12,2.05,0.14)),Vector3(x+guard_side*0.78,1.0,frontage_z-0.10)))
                    frontage_frame_colors.append(frontage_neon)
            # Keep a little vegetation at podium corners, but clear the service/lobby approach.
            for growth_side in [-1.0,1.0]:
                var growth_x:float=x+growth_side*(w*0.5-1.1)
                base_growth_tx.append(Transform3D(Basis.from_scale(Vector3(0.62,0.85,0.55)),Vector3(growth_x,0.48,frontage_z-0.36)))
                base_growth_colors.append(Color(0.055,0.2,0.11) if district_profile!=2 else Color(0.1,0.29,0.13))
            var entrance_local=Vector3(x+w*0.5+2.4,0,z)
            _add_lobby_terminal(entrance_local,building_index)
            if has_fire_escape:
                _add_fire_escape(Vector3(x,0,z-d*0.5-0.18),w,d,h,floors,upper_d,base_h,building_index)
            _add_job_board(entrance_local+Vector3(-1.5,0,1.6),building_index)
            var manager=get_tree().get_first_node_in_group("rental_manager")
            if is_instance_valid(manager):
                manager.register_building(coord,building_index,floors,to_global(entrance_local+Vector3(0,1,0)),style,to_global(Vector3(x,0,z)),Vector3(w,h,d),h/float(floors),to_global(Vector3(lift_x,0,z)).x,upper_w,base_h,building_use)
            var employment=get_tree().get_first_node_in_group("employment_manager")
            if is_instance_valid(employment):
                employment.register_workplace(to_global(entrance_local+Vector3(0,0,1.8)))
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
                # Multiple inhabited sky-lanes turn the gap between towers into vertical urban space.
                # Reuse the same restrained bridge kit at several heights instead of a single token bridge.
                for level_ratio in [0.48,0.72,0.9]:
                    var bridge_pos=Vector3((a["p"].x+b["p"].x)*0.5,bridge_height*level_ratio,(a["p"].z+b["p"].z)*0.5)
                    body_tx.append(Transform3D(Basis.from_scale(Vector3(bridge_len,1.2,3.8)),bridge_pos))
                    body_colors.append(Color(0.13,0.18,0.26))
                    trim_tx.append(Transform3D(Basis.from_scale(Vector3(bridge_len,0.16,4.0)),bridge_pos+Vector3(0,0.68,0)))
                    trim_colors.append(NEON[(i+j)%NEON.size()])
            elif abs(delta.z)>30.0 and abs(delta.x)<15.0:
                var bridge_len=maxf(3.0,abs(delta.z)-(a["s"].z+b["s"].z)*0.5)
                # Cross-axis connections use the same stacked sky-lane levels.
                for level_ratio in [0.48,0.72,0.9]:
                    var bridge_pos=Vector3((a["p"].x+b["p"].x)*0.5,bridge_height*level_ratio,(a["p"].z+b["p"].z)*0.5)
                    body_tx.append(Transform3D(Basis.from_scale(Vector3(3.8,1.2,bridge_len)),bridge_pos))
                    body_colors.append(Color(0.13,0.18,0.26))
                    trim_tx.append(Transform3D(Basis.from_scale(Vector3(4.0,0.16,bridge_len)),bridge_pos+Vector3(0,0.68,0)))
                    trim_colors.append(NEON[(i+j)%NEON.size()])
    _instances("BuildingMasses",body_tx,body_colors,Color(0.2,0.23,0.34),false)
    _instances("GroundFloorShopfrontGlazing",frontage_glass_tx,frontage_glass_colors,Color(0.025,0.34,0.42),false)
    _instances("GroundFloorSignageAndFrames",frontage_frame_tx,frontage_frame_colors,Color(0.08,0.12,0.16),true)
    _instances("GroundFloorServiceDoors",service_door_tx,service_door_colors,Color(0.035,0.045,0.06),false)
    _instances("PodiumReclaimedGrowth",base_growth_tx,base_growth_colors,Color(0.055,0.2,0.11),false,SphereMesh.new())
    _instances("NeonBandsAndSigns",trim_tx,trim_colors,Color(0.2,0.5,0.6),true)
    _instances("WindowGrid",win_tx,win_colors,Color(0,0.65,0.9),true)
    _instances("RooftopMachinery",roof_tx,[],Color(0.09,0.14,0.21),false)
    _instances("CylindricalServiceTanksAndMasts",cylinder_tx,[],Color(0.18,0.23,0.31),false,CylinderMesh.new())
    _instances("ExteriorElevatorFrames",lift_tx,lift_colors,Color(0.1,0.18,0.26),false)
    _instances("ElevatorFloorLandings",lift_landing_tx,lift_landing_colors,Color(0.1,0.18,0.26),false)
    _district_landmark()
    if collision_enabled:
        var physics=StaticBody3D.new()
        physics.name="BuildingCollision"
        for data in colliders+lift_colliders:
            var cs=CollisionShape3D.new()
            var shape=BoxShape3D.new()
            shape.size=data.s
            cs.shape=shape
            cs.position=data.p
            cs.rotation=data.get("r",Vector3.ZERO)
            physics.add_child(cs)
        add_child(physics)
func _append_hollow_tower(tx:Array[Transform3D],colors:Array[Color],colliders:Array[Dictionary],x:float,z:float,w:float,d:float,h:float,floors:int,base_h:float,upper_w:float,upper_d:float,shell_color:Color,fire_escape_enabled:bool=false)->void:
    var floor_height:=h/float(floors)
    var floor_color:=Color(0.045,0.065,0.095)
    var stair_color:=Color(0.12,0.18,0.25)
    var slab:=0.28
    var stair_opening_x:=3.3
    var stair_opening_z:=3.5
    for level in range(floors):
        var y0:=float(level)*floor_height
        var wall_height:=maxf(0.2,floor_height-0.12)
        var cy:=y0+wall_height*0.5
        var upper:=cy>=base_h
        var fw:=upper_w if upper else w
        var fd:=upper_d if upper else d
        var hx:=fw*0.5
        var hz:=fd*0.5
        var side_depth:=maxf(1.0,(fd-stair_opening_z)*0.5)
        var wall_specs:Array[Dictionary]=[
            {"size":Vector3(0.48,wall_height,fd),"pos":Vector3(x-hx+0.24,cy,z)},
            {"size":Vector3(0.48,wall_height,side_depth),"pos":Vector3(x+hx-0.24,cy,z-stair_opening_z*0.5-side_depth*0.5)},
            {"size":Vector3(0.48,wall_height,side_depth),"pos":Vector3(x+hx-0.24,cy,z+stair_opening_z*0.5+side_depth*0.5)},
            {"size":Vector3(fw,wall_height,0.48),"pos":Vector3(x,cy,z+hz-0.24)}
        ]
        # Leave a real opening in the front wall instead of placing a decorative door over solid collision.
        var doorway_width:float=1.55
        var doorway_height:float=minf(2.35,wall_height-0.25)
        var doorway_side_width:float=maxf(0.5,(fw-doorway_width)*0.5)
        wall_specs.append({"size":Vector3(doorway_side_width,wall_height,0.48),"pos":Vector3(x-(doorway_width*0.5+doorway_side_width*0.5),cy,z-hz+0.24)})
        wall_specs.append({"size":Vector3(doorway_side_width,wall_height,0.48),"pos":Vector3(x+(doorway_width*0.5+doorway_side_width*0.5),cy,z-hz+0.24)})
        var header_height:float=wall_height-doorway_height
        wall_specs.append({"size":Vector3(doorway_width,header_height,0.48),"pos":Vector3(x,y0+doorway_height+header_height*0.5,z-hz+0.24)})
        # Cyan jambs and header make the floor exit visible from the landing.
        var exit_trim:Color=Color(0.02,0.72,0.88)
        for jamb_side in [-1.0,1.0]:
            var jamb_size:=Vector3(0.10,doorway_height,0.10)
            var jamb_pos:=Vector3(x+jamb_side*(doorway_width*0.5+0.04),y0+doorway_height*0.5,z-hz-0.035)
            tx.append(Transform3D(Basis.from_scale(jamb_size),jamb_pos))
            colors.append(exit_trim)
        var exit_header_size:=Vector3(doorway_width+0.18,0.10,0.10)
        var exit_header_pos:=Vector3(x,y0+doorway_height+0.04,z-hz-0.035)
        tx.append(Transform3D(Basis.from_scale(exit_header_size),exit_header_pos))
        colors.append(exit_trim)
        for wall in wall_specs:
            var dims:Vector3=wall.size
            var at:Vector3=wall.pos
            tx.append(Transform3D(Basis.from_scale(dims),at))
            colors.append(shell_color)
            colliders.append({"p":at,"s":dims})
        # Four plate segments leave a central stair opening instead of a solid floor slab.
        var side_width:=maxf(1.0,(fw-stair_opening_x)*0.5)
        var end_depth:=maxf(1.0,(fd-stair_opening_z)*0.5)
        var plates:Array[Dictionary]=[
            {"size":Vector3(fw-slab,slab,end_depth),"pos":Vector3(x,y0+slab*0.5,z-(stair_opening_z*0.5+end_depth*0.5))},
            {"size":Vector3(fw-slab,slab,end_depth),"pos":Vector3(x,y0+slab*0.5,z+(stair_opening_z*0.5+end_depth*0.5))},
            {"size":Vector3(side_width,slab,stair_opening_z),"pos":Vector3(x-(stair_opening_x*0.5+side_width*0.5),y0+slab*0.5,z)},
            {"size":Vector3(side_width,slab,stair_opening_z),"pos":Vector3(x+(stair_opening_x*0.5+side_width*0.5),y0+slab*0.5,z)}
        ]
        for plate in plates:
            var dims:Vector3=plate.size
            var at:Vector3=plate.pos
            tx.append(Transform3D(Basis.from_scale(dims),at))
            colors.append(floor_color)
            colliders.append({"p":at,"s":dims})
        # Alternating compact stair flights connect adjacent storeys.
        for step in range(10):
            var direction:=1.0 if level%2==0 else -1.0
            var sx:=x+(0.78 if level%2==0 else -0.78)
            var sz:=z-direction*1.35+direction*float(step)*0.30
            var sy:=y0+slab+float(step+1)*floor_height/10.0-0.12
            var tread_size:=Vector3(1.15,0.22,0.34)
            var tread_at:=Vector3(sx,sy,sz)
            tx.append(Transform3D(Basis.from_scale(tread_size),tread_at))
            colors.append(stair_color)
            colliders.append({"p":tread_at,"s":tread_size})
        # Sloped handrails and upright supports make the stairwell legible in first person.
        var stair_direction:=1.0 if level%2==0 else -1.0
        var rail_color:=Color(0.025,0.62,0.78)
        var rail_angle:=atan(floor_height/2.7)*stair_direction
        var rail_size:=Vector3(0.075,0.075,3.15)
        for rail_side in [-1.0,1.0]:
            var rail_x:float=x+(0.78 if level%2==0 else -0.78)+rail_side*0.68
            var rail_y:float=y0+slab+floor_height*0.52+0.42
            var rail_basis:=Basis.from_euler(Vector3(-rail_angle,0,0)).scaled(rail_size)
            tx.append(Transform3D(rail_basis,Vector3(rail_x,rail_y,z)))
            colors.append(rail_color)
            colliders.append({"p":Vector3(rail_x,rail_y,z),"s":rail_size,"r":Vector3(-rail_angle,0,0)})
            for post_index in range(4):
                var post_t:float=float(post_index)/3.0
                var post_z:float=z-1.35+post_t*2.7
                if level%2==1:
                    post_z=z+1.35-post_t*2.7
                var post_y:float=y0+slab+post_t*floor_height+0.45
                var post_size:=Vector3(0.075,0.9,0.075)
                var post_at:=Vector3(rail_x,post_y,post_z)
                tx.append(Transform3D(Basis.from_scale(post_size),post_at))
                colors.append(rail_color)
                colliders.append({"p":post_at,"s":post_size})
        # A protected stair-foot landing closes the gap between the floor plate and first/last tread.
        var landing_direction:float=1.0 if level%2==0 else -1.0
        var landing_x:float=x+(0.78 if level%2==0 else -0.78)
        var stair_landing_size:=Vector3(2.0,slab,1.2)
        # Keep the stair landing centered on this tower, not near the district origin.
        var stair_landing_at:=Vector3(landing_x,y0+slab*0.5,z-landing_direction*1.75)
        tx.append(Transform3D(Basis.from_scale(stair_landing_size),stair_landing_at))
        colors.append(floor_color)
        colliders.append({"p":stair_landing_at,"s":stair_landing_size})
        var landing_size:=Vector3(2.2,0.22,1.2)
        var landing_at:=Vector3(x+fw*0.5-1.1,y0+0.11,z)
        tx.append(Transform3D(Basis.from_scale(landing_size),landing_at))
        colors.append(floor_color)
        colliders.append({"p":landing_at,"s":landing_size})

func _add_elevator_car(local_x:float,local_z:float,height:float,floors:int,building_index:int):
    var car=AnimatableBody3D.new()
    car.name="ElevatorCab_%d"%building_index
    car.set_script(ELEVATOR)
    car.position=Vector3(local_x,1.315,local_z)
    add_child(car)
    car.configure(floors,height,"%d:%d:%d"%[coord.x,coord.y,building_index],collision_enabled)
    var frame=StandardMaterial3D.new()
    frame.albedo_color=Color(0.035,0.07,0.12)
    frame.metallic=0.78
    frame.roughness=0.22
    var floor_mesh=BoxMesh.new()
    floor_mesh.size=Vector3(2.12,0.14,2.12)
    var floor=MeshInstance3D.new()
    floor.name="CabFloor"
    floor.mesh=floor_mesh
    floor.position=Vector3(0,-1.08,0)
    floor.material_override=frame
    car.add_child(floor)
    var roof_mesh=BoxMesh.new()
    roof_mesh.size=Vector3(2.12,0.12,2.12)
    var roof=MeshInstance3D.new()
    roof.name="CabRoof"
    roof.mesh=roof_mesh
    roof.position=Vector3(0,1.08,0)
    roof.material_override=frame
    car.add_child(roof)
    var post_mesh=BoxMesh.new()
    post_mesh.size=Vector3(0.12,2.18,0.12)
    for px in [-1.0,1.0]:
        for pz in [-1.0,1.0]:
            var post=MeshInstance3D.new()
            post.mesh=post_mesh
            post.position=Vector3(px,0,pz)
            post.material_override=frame
            car.add_child(post)
    var glass_mat=StandardMaterial3D.new()
    glass_mat.albedo_color=Color(0.015,0.38,0.56,0.28)
    glass_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    glass_mat.metallic=0.52
    glass_mat.roughness=0.16
    glass_mat.emission_enabled=true
    glass_mat.emission=Color(0.01,0.19,0.34)
    glass_mat.emission_energy_multiplier=0.8
    for side in [-1.0,1.0]:
        var glass=MeshInstance3D.new()
        var pane=BoxMesh.new()
        pane.size=Vector3(0.035,1.85,1.85)
        glass.mesh=pane
        glass.position=Vector3(side*1.01,0,0)
        glass.material_override=glass_mat
        car.add_child(glass)
    var rear_glass=MeshInstance3D.new()
    var rear_pane=BoxMesh.new()
    rear_pane.size=Vector3(1.85,1.85,0.035)
    rear_glass.mesh=rear_pane
    rear_glass.position=Vector3(0,0,-1.01)
    rear_glass.material_override=glass_mat
    car.add_child(rear_glass)
    var door_line=MeshInstance3D.new()
    var door_mesh=BoxMesh.new()
    door_mesh.size=Vector3(1.75,0.06,0.045)
    door_line.mesh=door_mesh
    door_line.position=Vector3(0,0.1,1.0)
    var neon=StandardMaterial3D.new()
    neon.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    neon.albedo_color=Color(0.02,0.78,1.0)
    neon.emission_enabled=true
    neon.emission=Color(0.01,0.55,1.0)
    neon.emission_energy_multiplier=2.2
    door_line.material_override=neon
    car.add_child(door_line)
    return car
func _add_lobby_terminal(local_position:Vector3,building_index:int):
    var kiosk=Node3D.new()
    kiosk.name="RentalTerminal_%d"%building_index
    kiosk.position=local_position
    add_child(kiosk)
    var body=MeshInstance3D.new()
    var body_mesh=BoxMesh.new()
    body_mesh.size=Vector3(0.9,1.35,0.55)
    body.mesh=body_mesh
    var shell=StandardMaterial3D.new()
    shell.albedo_color=Color(0.025,0.045,0.075)
    shell.metallic=0.72
    shell.roughness=0.24
    body.material_override=shell
    body.position.y=0.68
    kiosk.add_child(body)
    var screen=MeshInstance3D.new()
    var screen_mesh=BoxMesh.new()
    screen_mesh.size=Vector3(0.07,0.72,0.38)
    screen.mesh=screen_mesh
    var display=StandardMaterial3D.new()
    display.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    display.albedo_color=Color(0.0,0.8,1.0)
    display.emission_enabled=true
    display.emission=Color(0.0,0.62,1.0)
    display.emission_energy_multiplier=2.4
    screen.material_override=display
    screen.position=Vector3(0.47,0.88,0)
    kiosk.add_child(screen)
    var indicator=MeshInstance3D.new()
    var indicator_mesh=BoxMesh.new()
    indicator_mesh.size=Vector3(0.12,0.08,0.62)
    indicator.mesh=indicator_mesh
    indicator.material_override=display
    indicator.position=Vector3(0,1.39,0)
    kiosk.add_child(indicator)
func _add_job_board(local_position:Vector3,building_index:int):
    var board=Node3D.new()
    board.name="EmploymentBoard_%d"%building_index
    board.position=local_position
    add_child(board)
    var body=MeshInstance3D.new()
    var housing=BoxMesh.new()
    housing.size=Vector3(0.72,1.55,0.22)
    body.mesh=housing
    var shell=StandardMaterial3D.new()
    shell.albedo_color=Color(0.045,0.035,0.045)
    shell.metallic=0.62
    shell.roughness=0.3
    body.material_override=shell
    body.position.y=0.78
    board.add_child(body)
    var display_mesh=BoxMesh.new()
    display_mesh.size=Vector3(0.58,0.92,0.035)
    var display=MeshInstance3D.new()
    display.mesh=display_mesh
    display.position=Vector3(0,0.93,-0.13)
    var screen=StandardMaterial3D.new()
    screen.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    screen.albedo_color=Color(1.0,0.36,0.08)
    screen.emission_enabled=true
    screen.emission=Color(1.0,0.22,0.035)
    screen.emission_energy_multiplier=2.2
    display.material_override=screen
    board.add_child(display)
    var base=MeshInstance3D.new()
    var base_mesh=BoxMesh.new()
    base_mesh.size=Vector3(0.9,0.12,0.42)
    base.mesh=base_mesh
    base.position.y=0.08
    base.material_override=shell
    board.add_child(base)
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

func _district_landmark():
    # Landmark families are deterministic, sparse, and distributed on a five-chunk grid.
    # This gives distant districts different silhouettes without making every block a landmark.
    if posmod(coord.x,5)!=0 or posmod(coord.y,5)!=0:
        return
    var landmark=Node3D.new()
    var family:int=posmod(abs(coord.x*7+coord.y*13+seed_value),3)
    landmark.name=["AbyssTransitHalo","FloodlightSpire","CollapsedSkybridgeMonument"][family]
    landmark.position=Vector3(size*0.5,0,size*0.5)
    add_child(landmark)
    if family==1:
        var spire_mat:=StandardMaterial3D.new()
        spire_mat.albedo_color=Color(0.045,0.065,0.095)
        spire_mat.metallic=0.78
        var beam_mat:=StandardMaterial3D.new()
        beam_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        beam_mat.albedo_color=Color(1.0,0.24,0.08)
        beam_mat.emission_enabled=true
        beam_mat.emission=Color(1.0,0.12,0.025)
        beam_mat.emission_energy_multiplier=2.6
        for i in range(3):
            var mast:=MeshInstance3D.new()
            var mast_mesh:=BoxMesh.new()
            mast_mesh.size=Vector3(1.1,42.0-float(i)*5.0,1.1)
            mast.mesh=mast_mesh
            mast.position=Vector3(float(i-1)*5.0,21.0-float(i)*2.5,0)
            mast.material_override=spire_mat
            landmark.add_child(mast)
        var crossbar:=MeshInstance3D.new()
        var crossbar_mesh:=BoxMesh.new()
        crossbar_mesh.size=Vector3(17.0,0.38,0.42)
        crossbar.mesh=crossbar_mesh
        crossbar.position=Vector3(0,35,0)
        crossbar.material_override=beam_mat
        landmark.add_child(crossbar)
        return
    if family==2:
        var ruin_mat:=StandardMaterial3D.new()
        ruin_mat.albedo_color=Color(0.09,0.105,0.13)
        ruin_mat.metallic=0.58
        for side in [-1.0,1.0]:
            var pier:=MeshInstance3D.new()
            var pier_mesh:=BoxMesh.new()
            pier_mesh.size=Vector3(2.8,23.0,3.4)
            pier.mesh=pier_mesh
            pier.position=Vector3(side*10.0,11.5,0)
            pier.rotation_degrees.z=side*4.0
            pier.material_override=ruin_mat
            landmark.add_child(pier)
        var deck:=MeshInstance3D.new()
        var deck_mesh:=BoxMesh.new()
        deck_mesh.size=Vector3(24.0,1.4,5.0)
        deck.mesh=deck_mesh
        deck.position=Vector3(0,22.0,0)
        deck.rotation_degrees.z=-3.0
        deck.material_override=ruin_mat
        landmark.add_child(deck)
        var warning:=MeshInstance3D.new()
        var warning_mesh:=BoxMesh.new()
        warning_mesh.size=Vector3(18.0,0.22,5.1)
        warning.mesh=warning_mesh
        warning.position=Vector3(0,22.9,0)
        var warning_mat:=StandardMaterial3D.new()
        warning_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
        warning_mat.albedo_color=Color(1.0,0.16,0.04)
        warning_mat.emission_enabled=true
        warning_mat.emission=Color(0.8,0.05,0.01)
        warning_mat.emission_energy_multiplier=2.0
        warning.material_override=warning_mat
        landmark.add_child(warning)
        return
    var steel=StandardMaterial3D.new()
    steel.albedo_color=Color(0.035,0.055,0.095)
    steel.metallic=0.82
    steel.roughness=0.24
    var glow=StandardMaterial3D.new()
    glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    glow.albedo_color=Color(0.04,0.72,1.0)
    glow.emission_enabled=true
    glow.emission=Color(0.02,0.58,1.0)
    glow.emission_energy_multiplier=3.2
    for ring_index in range(2):
        var ring=MeshInstance3D.new()
        var torus=TorusMesh.new()
        torus.inner_radius=0.72
        torus.outer_radius=1.0
        torus.ring_segments=48
        torus.rings=8
        ring.mesh=torus
        ring.material_override=glow if ring_index==0 else steel
        ring.position=Vector3(0,29,0)
        ring.rotation_degrees=Vector3(90,0,0) if ring_index==0 else Vector3(90,0,90)
        ring.scale=Vector3(19,25,1.0) if ring_index==0 else Vector3(16,22,1.0)
        landmark.add_child(ring)
    for side in [-1.0,1.0]:
        var pylon=MeshInstance3D.new()
        var mesh=BoxMesh.new()
        mesh.size=Vector3(2.4,29,2.4)
        pylon.mesh=mesh
        pylon.position=Vector3(side*18,14.5,0)
        pylon.material_override=steel
        landmark.add_child(pylon)
        var stripe=MeshInstance3D.new()
        var stripe_mesh=BoxMesh.new()
        stripe_mesh.size=Vector3(2.5,0.22,2.5)
        stripe.mesh=stripe_mesh
        stripe.position=Vector3(side*18,24,0)
        stripe.material_override=glow
        landmark.add_child(stripe)


func _add_fire_escape(anchor:Vector3,building_width:float,building_depth:float,total_height:float,floors:int,upper_depth:float,base_height:float,building_index:int)->void:
    # Shared exterior fire-escape kit: landings, alternating flights, guardrails and cage posts.
    # Geometry is intentionally modular so streamed buildings reuse the same small set of parts.
    var escape:=Node3D.new()
    escape.name="FireEscape_B%03d" % building_index
    escape.position=anchor
    add_child(escape)
    var collision_root:StaticBody3D
    if collision_enabled:
        collision_root=StaticBody3D.new()
        collision_root.name="FireEscapeCollision"
        collision_root.collision_layer=1
        collision_root.collision_mask=1
        escape.add_child(collision_root)
    var steel:=StandardMaterial3D.new()
    steel.albedo_color=Color(0.075,0.095,0.12)
    steel.metallic=0.78
    steel.roughness=0.36
    var safety:=StandardMaterial3D.new()
    safety.albedo_color=Color(0.95,0.34,0.09)
    safety.metallic=0.42
    safety.roughness=0.44
    var levels: int=mini(floors,12)
    var floor_step:float=total_height/float(maxi(1,floors))
    var landing_width:float=clampf(building_depth*0.48,2.6,4.2)
    var landing_depth:float=1.5
    var offset_x:float=0.0
    for level in range(levels):
        var y:float=float(level)*floor_step+0.18
        var side:float=-1.0 if level%2==0 else 1.0
        var landing:=MeshInstance3D.new()
        var landing_mesh:=BoxMesh.new()
        landing_mesh.size=Vector3(landing_width,0.16,landing_depth)
        landing.mesh=landing_mesh
        landing.material_override=steel
        landing.position=Vector3(offset_x,y,0)
        escape.add_child(landing)
        _add_fire_escape_box_collision(collision_root,"LandingCollision_%02d" % level,landing.position,Vector3(landing_width,0.16,landing_depth))
        # Upper tower floors may step back from the podium. Bridge the real setback to the matching door.
        var floor_mid_y:float=float(level)*floor_step+(floor_step-0.12)*0.5
        var floor_depth:float=upper_depth if floor_mid_y>=base_height else building_depth
        var door_distance:float=(building_depth-floor_depth)*0.5+0.18
        if door_distance>landing_depth*0.5+0.05:
            var bridge_start:float=landing_depth*0.5-0.20
            var bridge_length:float=door_distance-bridge_start
            var bridge_size:=Vector3(1.55,0.14,bridge_length)
            var bridge_pos:=Vector3(offset_x*0.5,y,(door_distance+bridge_start)*0.5)
            var bridge:=MeshInstance3D.new()
            bridge.name="FloorDoorBridge_%02d" % level
            var bridge_mesh:=BoxMesh.new()
            bridge_mesh.size=bridge_size
            bridge.mesh=bridge_mesh
            bridge.material_override=steel
            bridge.position=bridge_pos
            escape.add_child(bridge)
            _add_fire_escape_box_collision(collision_root,"FloorDoorBridgeCollision_%02d" % level,bridge_pos,bridge_size)
            # Keep the connector open at both ends and protect its exposed sides.
            for bridge_side in [-1.0,1.0]:
                var bridge_rail:=MeshInstance3D.new()
                bridge_rail.name="FloorDoorBridgeRail_%02d_%s" % [level,"L" if bridge_side<0.0 else "R"]
                var bridge_rail_mesh:=BoxMesh.new()
                bridge_rail_mesh.size=Vector3(0.07,0.95,bridge_length)
                bridge_rail.mesh=bridge_rail_mesh
                bridge_rail.material_override=safety if bridge_side>0.0 else steel
                bridge_rail.position=Vector3(bridge_pos.x+bridge_side*0.78,y+0.52,bridge_pos.z)
                escape.add_child(bridge_rail)
                _add_fire_escape_box_collision(collision_root,"FloorDoorBridgeRailCollision_%02d_%s" % [level,"L" if bridge_side<0.0 else "R"],bridge_rail.position,bridge_rail_mesh.size)
        for rail_side in [-1.0,1.0]:
            # The front edge faces the tower doorway; a guardrail here would block access.
            if rail_side>0.0:
                continue
            var rail:=MeshInstance3D.new()
            var rail_mesh:=BoxMesh.new()
            rail_mesh.size=Vector3(landing_width,0.95,0.07)
            rail.mesh=rail_mesh
            rail.material_override=safety if rail_side==1.0 else steel
            rail.position=Vector3(offset_x,y+0.52,rail_side*landing_depth*0.46)
            escape.add_child(rail)
            _add_fire_escape_box_collision(collision_root,"LandingRailCollision_%02d_%s" % [level,"L" if rail_side<0.0 else "R"],rail.position,rail_mesh.size)
            for post_x in [-0.45,0.45]:
                var post:=MeshInstance3D.new()
                var post_mesh:=BoxMesh.new()
                post_mesh.size=Vector3(0.07,0.95,0.07)
                post.mesh=post_mesh
                post.material_override=steel
                post.position=Vector3(offset_x+post_x*landing_width,y+0.52,rail_side*landing_depth*0.46)
                escape.add_child(post)
                _add_fire_escape_box_collision(collision_root,"LandingPostCollision_%02d_%s_%s" % [level,"L" if rail_side<0.0 else "R","A" if post_x<0.0 else "B"],post.position,post_mesh.size)
        if level<levels-1:
            # Build the flight from reusable individual treads instead of one ramp-like slab.
            var tread_count:int=8
            var flight_width:float=landing_width*0.72
            var flight_rise:float=maxf(0.8,floor_step-0.28)
            for tread_index in range(tread_count):
                var tread:=MeshInstance3D.new()
                tread.name="Tread_%02d_%02d" % [level,tread_index]
                var tread_mesh:=BoxMesh.new()
                tread_mesh.size=Vector3(flight_width/float(tread_count)+0.035,0.12,0.72)
                tread.mesh=tread_mesh
                tread.material_override=steel
                var progress:float=(float(tread_index)+0.5)/float(tread_count)
                tread.position=Vector3(offset_x+side*progress*flight_width,y+0.18+progress*flight_rise,0)
                escape.add_child(tread)
                _add_fire_escape_box_collision(collision_root,"TreadCollision_%02d_%02d" % [level,tread_index],tread.position,tread_mesh.size)
            # Paired continuous handrails follow the stair pitch; short uprights tie them back to the flight.
            var rail_length:float=flight_width+0.18
            var rail_pitch:float=atan2(flight_rise,flight_width)
            for handrail_side in [-1.0,1.0]:
                var handrail:=MeshInstance3D.new()
                handrail.name="Handrail_%02d_%s" % [level,"L" if handrail_side<0.0 else "R"]
                var handrail_mesh:=BoxMesh.new()
                handrail_mesh.size=Vector3(rail_length,0.09,0.09)
                handrail.mesh=handrail_mesh
                handrail.material_override=safety
                handrail.position=Vector3(offset_x+side*flight_width*0.5,y+0.18+flight_rise*0.5+0.92,handrail_side*0.48)
                handrail.rotation.z=side*rail_pitch
                escape.add_child(handrail)
                _add_fire_escape_box_collision(collision_root,"HandrailCollision_%02d_%s" % [level,"L" if handrail_side<0.0 else "R"],handrail.position,handrail_mesh.size,handrail.rotation.z)
                for support_index in range(3):
                    var support_progress:float=0.18+float(support_index)*0.32
                    var support:=MeshInstance3D.new()
                    support.name="HandrailPost_%02d_%s_%d" % [level,"L" if handrail_side<0.0 else "R",support_index]
                    var support_mesh:=BoxMesh.new()
                    support_mesh.size=Vector3(0.075,0.94,0.075)
                    support.mesh=support_mesh
                    support.material_override=steel
                    support.position=Vector3(offset_x+side*support_progress*flight_width,y+0.18+support_progress*flight_rise+0.43,handrail_side*0.48)
                    escape.add_child(support)
                    _add_fire_escape_box_collision(collision_root,"HandrailPostCollision_%02d_%s_%d" % [level,"L" if handrail_side<0.0 else "R",support_index],support.position,support_mesh.size)
            offset_x+=side*landing_width*0.18


func _add_fire_escape_box_collision(parent:Node3D,collision_name:String,local_position:Vector3,box_size:Vector3,rotation_z:float=0.0)->void:
    # Consolidate the many fire-escape primitives under one static body per escape.
    # Every detailed tread, rail and support retains its own precise box shape.
    if not collision_enabled or not is_instance_valid(parent):
        return
    var collision:=CollisionShape3D.new()
    collision.name=collision_name
    collision.position=local_position
    collision.rotation.z=rotation_z
    var shape:=BoxShape3D.new()
    shape.size=box_size
    collision.shape=shape
    parent.add_child(collision)
