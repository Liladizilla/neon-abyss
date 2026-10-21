extends Node3D
## Reusable private apartment shell with collision and a small furnishing kit.
var room_id=""
var entry_door_panels:Array[Dictionary]=[]
var access_bridge_length:float=5.4
func configure(unit_id:String,world_origin:Vector3,bridge_length:float=5.4):
    room_id=unit_id
    position=world_origin
    access_bridge_length=maxf(2.8,bridge_length)
func _ready():
    _build_room()
func _process(delta:float):
    if entry_door_panels.is_empty():
        return
    var local_player=get_tree().get_first_node_in_group("local_player")
    var door_point=to_global(Vector3(0,1.0,3.9))
    var should_open=is_instance_valid(local_player) and local_player.global_position.distance_to(door_point)<2.4
    for panel_data in entry_door_panels:
        var door:AnimatableBody3D=panel_data.body
        var side:float=panel_data.side
        var closed_x:float=panel_data.closed_x
        var target_x:float=closed_x+side*(1.05 if should_open else 0.0)
        door.position.x=move_toward(door.position.x,target_x,delta*3.0)
func _build_room():
    var floor_mat=_material(Color(0.045,0.065,0.095),0.38,0.72)
    var wall_mat=_material(Color(0.07,0.085,0.12),0.28,0.58)
    var trim_mat=_material(Color(0.0,0.68,0.82),0.32,0.7,true)
    var furniture_mat=_material(Color(0.12,0.14,0.19),0.22,0.62)
    _box("Floor",Vector3(12,0.25,8),Vector3(0,-0.125,0),floor_mat,true)
    _box("Ceiling",Vector3(12,0.18,8),Vector3(0,3.35,0),wall_mat,false)
    _box("BackWall",Vector3(12,3.4,0.22),Vector3(0,1.6,-4),wall_mat,true)
    _box("LeftWall",Vector3(0.22,3.4,8),Vector3(-6,1.6,0),wall_mat,true)
    _box("RightWall",Vector3(0.22,3.4,8),Vector3(6,1.6,0),wall_mat,true)
    # Front wall leaves a proper doorway rather than trapping the player in a sealed box.
    _box("FrontWallLeft",Vector3(5.1,3.4,0.22),Vector3(-3.45,1.6,4),wall_mat,true)
    _box("FrontWallRight",Vector3(5.1,3.4,0.22),Vector3(3.45,1.6,4),wall_mat,true)
    _box("DoorHeader",Vector3(3.4,0.45,0.22),Vector3(0,3.0,4),wall_mat,true)
    _box("EntryFrameLeft",Vector3(0.12,2.45,0.16),Vector3(-0.96,1.18,3.88),trim_mat,false)
    _box("EntryFrameRight",Vector3(0.12,2.45,0.16),Vector3(0.96,1.18,3.88),trim_mat,false)
    _box("EntryFrameTop",Vector3(2.0,0.12,0.16),Vector3(0,2.42,3.88),trim_mat,false)
    _build_entry_doors(trim_mat)
    # Size the collision-enabled bridge to reach the actual floor landing, including tower setbacks.
    var bridge_center_z:float=4.0+access_bridge_length*0.5
    _box("ElevatorAccessBridge",Vector3(2.8,0.16,access_bridge_length),Vector3(0,-0.08,bridge_center_z),floor_mat,true)
    _box("BridgeRailLeft",Vector3(0.12,0.95,access_bridge_length),Vector3(-1.34,0.43,bridge_center_z),trim_mat,true)
    _box("BridgeRailRight",Vector3(0.12,0.95,access_bridge_length),Vector3(1.34,0.43,bridge_center_z),trim_mat,true)
    var guide_length:float=maxf(1.0,access_bridge_length-0.6)
    var guide_center_z:float=4.0+access_bridge_length*0.5
    _box("BridgeGuideLeft",Vector3(0.055,0.025,guide_length),Vector3(-1.02,0.015,guide_center_z),trim_mat,false)
    _box("BridgeGuideRight",Vector3(0.055,0.025,guide_length),Vector3(1.02,0.015,guide_center_z),trim_mat,false)
    _box("WindowFrameTop",Vector3(4.2,0.12,0.16),Vector3(0,2.9,-3.84),trim_mat,false)
    _box("WindowFrameBottom",Vector3(4.2,0.12,0.16),Vector3(0,1.0,-3.84),trim_mat,false)
    _box("WindowFrameLeft",Vector3(0.12,1.9,0.16),Vector3(-2.05,1.95,-3.84),trim_mat,false)
    _box("WindowFrameRight",Vector3(0.12,1.9,0.16),Vector3(2.05,1.95,-3.84),trim_mat,false)
    var glass=StandardMaterial3D.new()
    glass.albedo_color=Color(0.02,0.42,0.58,0.25)
    glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.metallic=0.55
    glass.roughness=0.16
    _box("PanoramicWindow",Vector3(3.95,1.72,0.06),Vector3(0,1.95,-3.9),glass,false)
    # Furnishings are fixed collision props for now, not a final customizable furniture system.
    _box("BedBase",Vector3(2.3,0.42,2.8),Vector3(-3.6,0.28,-2.1),furniture_mat,true)
    _box("BedMattress",Vector3(2.2,0.2,2.7),Vector3(-3.6,0.58,-2.1),_material(Color(0.18,0.2,0.27),0.9,0.04),false)
    _box("BedHeadboard",Vector3(2.35,1.1,0.16),Vector3(-3.6,0.62,-3.45),wall_mat,true)
    _box("WorkDesk",Vector3(2.2,0.12,0.85),Vector3(3.45,0.95,-2.65),furniture_mat,true)
    for x in [2.55,4.35]:
        for z in [-2.95,-2.35]:
            _box("DeskLeg",Vector3(0.1,0.9,0.1),Vector3(x,0.45,z),wall_mat,true)
    _box("WallDisplay",Vector3(1.5,0.85,0.08),Vector3(3.4,1.9,-3.84),trim_mat,false)
    _box("Sofa",Vector3(2.4,0.65,0.9),Vector3(1.9,0.34,1.3),furniture_mat,true)
    _box("SofaBack",Vector3(2.4,0.75,0.18),Vector3(1.9,0.9,1.68),wall_mat,true)
    _box("CoffeeTable",Vector3(1.4,0.12,0.7),Vector3(1.9,0.55,0.0),furniture_mat,true)
    _box("CeilingLight",Vector3(2.8,0.06,0.18),Vector3(0,3.18,0),trim_mat,false)
    var light=OmniLight3D.new()
    light.name="ApartmentPracticalLight"
    light.position=Vector3(0,2.85,0)
    light.light_color=Color(0.25,0.72,1.0)
    light.light_energy=0.85
    light.omni_range=9.0
    add_child(light)
    var sign_label=Label3D.new()
    sign_label.name="UnitIdentifier"
    sign_label.text=room_id
    sign_label.position=Vector3(0,2.7,3.78)
    sign_label.pixel_size=0.006
    sign_label.modulate=Color(0.1,0.88,1.0)
    add_child(sign_label)
func _build_entry_doors(mat:Material):
    for side in [-1.0,1.0]:
        var door:=AnimatableBody3D.new()
        door.name="SlidingEntryDoorLeft" if side<0.0 else "SlidingEntryDoorRight"
        door.sync_to_physics = true
        door.collision_layer = 1
        door.collision_mask = 1
        door.position = Vector3(side * 0.46, 1.12, 3.88)
        var mesh_node:=MeshInstance3D.new()
        mesh_node.name="DoorPanel"
        var panel_mesh:=BoxMesh.new()
        panel_mesh.size=Vector3(0.94,2.18,0.12)
        mesh_node.mesh=panel_mesh
        mesh_node.material_override=mat
        door.add_child(mesh_node)
        var collision:=CollisionShape3D.new()
        var shape:=BoxShape3D.new()
        shape.size=panel_mesh.size
        collision.shape=shape
        door.add_child(collision)
        add_child(door)
        entry_door_panels.append({"body":door,"side":side,"closed_x":side*0.46})
func _material(color:Color,roughness:float,metallic:float,emissive:bool=false)->StandardMaterial3D:
    var mat=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.roughness=roughness
    mat.metallic=metallic
    if emissive:
        mat.emission_enabled=true
        mat.emission=color
        mat.emission_energy_multiplier=1.8
    return mat
func _box(label:String,dimensions:Vector3,at:Vector3,mat:Material,collide:bool):
    var mesh_node=MeshInstance3D.new()
    mesh_node.name=label
    var mesh=BoxMesh.new()
    mesh.size=dimensions
    mesh_node.mesh=mesh
    mesh_node.material_override=mat
    mesh_node.position=at
    add_child(mesh_node)
    if collide:
        var body := StaticBody3D.new()
        body.name = label + "_Collision"
        body.collision_layer = 1
        body.collision_mask = 1
        var shape := CollisionShape3D.new()
        var box=BoxShape3D.new()
        box.size=dimensions
        shape.shape=box
        body.add_child(shape)
        body.position=at
        add_child(body)
