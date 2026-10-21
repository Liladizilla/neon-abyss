extends Node3D
## Reusable private apartment shell with collision and a small furnishing kit.
var room_id=""
func configure(unit_id:String,world_origin:Vector3):
    room_id=unit_id
    position=world_origin
func _ready():
    _build_room()
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
    _box("FrontWallLeft",Vector3(4.3,3.4,0.22),Vector3(-3.85,1.6,4),wall_mat,true)
    _box("FrontWallRight",Vector3(4.3,3.4,0.22),Vector3(3.85,1.6,4),wall_mat,true)
    _box("DoorHeader",Vector3(3.4,0.45,0.22),Vector3(0,3.0,4),wall_mat,true)
    # Exterior access bridge aligns with the tower's elevator landing at this floor.
    _box("ElevatorAccessBridge",Vector3(2.8,0.16,5.4),Vector3(0,-0.08,6.7),floor_mat,true)
    _box("BridgeRailLeft",Vector3(0.12,0.95,5.4),Vector3(-1.34,0.43,6.7),trim_mat,true)
    _box("BridgeRailRight",Vector3(0.12,0.95,5.4),Vector3(1.34,0.43,6.7),trim_mat,true)
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
        var body=StaticBody3D.new()
        body.name=label+"_Collision"
        var shape=CollisionShape3D.new()
        var box=BoxShape3D.new()
        box.size=dimensions
        shape.shape=box
        body.add_child(shape)
        body.position=at
        add_child(body)
