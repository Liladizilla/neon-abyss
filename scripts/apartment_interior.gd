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
    # Compact kitchenette: durable cabinets, counter, sink, hob and a fridge.
    var cabinet_mat=_material(Color(0.055,0.075,0.095),0.34,0.62)
    var counter_mat=_material(Color(0.24,0.27,0.3),0.24,0.42)
    _box("KitchenBaseCabinets",Vector3(2.5,0.82,0.62),Vector3(4.45,0.42,1.65),cabinet_mat,true)
    _box("KitchenCounter",Vector3(2.62,0.12,0.72),Vector3(4.45,0.9,1.65),counter_mat,true)
    _box("KitchenBacksplash",Vector3(2.55,0.72,0.08),Vector3(4.45,1.35,2.0),wall_mat,false)
    _box("KitchenUpperCabinets",Vector3(2.35,0.62,0.42),Vector3(4.45,2.15,1.76),cabinet_mat,true)
    _box("KitchenSink",Vector3(0.62,0.045,0.42),Vector3(4.05,0.99,1.62),_material(Color(0.42,0.48,0.54),0.18,0.82),false)
    _box("Cooktop",Vector3(0.65,0.045,0.48),Vector3(4.92,0.99,1.62),_material(Color(0.015,0.02,0.03),0.16,0.45),false)
    _box("CooktopBurnerA",Vector3(0.22,0.018,0.22),Vector3(4.78,1.02,1.52),trim_mat,false)
    _box("CooktopBurnerB",Vector3(0.22,0.018,0.22),Vector3(5.05,1.02,1.72),trim_mat,false)
    _box("Refrigerator",Vector3(0.72,1.95,0.72),Vector3(5.18,0.98,2.75),_material(Color(0.16,0.2,0.25),0.22,0.72),true)
    _box("FridgeHandle",Vector3(0.035,0.62,0.045),Vector3(4.98,1.08,2.38),trim_mat,false)
    # Small washroom zone; low partitions preserve sightlines while providing a usable layout.
    var tile_mat=_material(Color(0.11,0.14,0.18),0.62,0.18)
    _box("WashroomFloor",Vector3(2.25,0.08,2.25),Vector3(-4.45,0.03,2.45),tile_mat,false)
    _box("WashroomPartitionSide",Vector3(0.12,2.25,2.2),Vector3(-5.12,1.1,2.15),wall_mat,true)
    _box("WashroomPartitionBack",Vector3(2.1,2.25,0.12),Vector3(-4.12,1.1,3.48),wall_mat,true)
    _box("ShowerTray",Vector3(0.82,0.12,0.82),Vector3(-4.72,0.16,2.95),counter_mat,true)
    var shower_glass=_material(Color(0.18,0.45,0.52,0.24),0.12,0.25)
    shower_glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    _box("ShowerGlass",Vector3(0.04,1.8,0.82),Vector3(-4.28,1.05,2.95),shower_glass,false)
    _box("WashroomVanity",Vector3(0.78,0.72,0.42),Vector3(-3.7,0.38,2.92),cabinet_mat,true)
    _box("WashroomBasin",Vector3(0.62,0.08,0.38),Vector3(-3.7,0.78,2.92),counter_mat,false)
    _box("ToiletBase",Vector3(0.42,0.42,0.62),Vector3(-4.0,0.24,1.75),_material(Color(0.55,0.61,0.67),0.24,0.08),true)
    _box("ToiletSeat",Vector3(0.46,0.08,0.64),Vector3(-4.0,0.48,1.75),_material(Color(0.72,0.76,0.79),0.22,0.04),false)
    # Finish details make the apartment read as a lived-in unit, not a prop showroom.
    _box("EntryFrameLeft",Vector3(0.12,2.65,0.28),Vector3(-1.72,1.32,3.94),trim_mat,false)
    _box("EntryFrameRight",Vector3(0.12,2.65,0.28),Vector3(1.72,1.32,3.94),trim_mat,false)
    _box("EntryThreshold",Vector3(3.25,0.07,0.42),Vector3(0,0.015,4.03),counter_mat,false)
    _box("KitchenDrawerLineA",Vector3(0.72,0.025,0.025),Vector3(3.72,0.46,1.325),trim_mat,false)
    _box("KitchenDrawerLineB",Vector3(0.72,0.025,0.025),Vector3(4.55,0.46,1.325),trim_mat,false)
    _box("KitchenDrawerLineC",Vector3(0.72,0.025,0.025),Vector3(3.72,0.7,1.325),trim_mat,false)
    _box("KitchenDrawerLineD",Vector3(0.72,0.025,0.025),Vector3(4.55,0.7,1.325),trim_mat,false)
    # Visible tap and shower hardware are separate meshes for readable silhouettes.
    var chrome_mat=_material(Color(0.48,0.58,0.66),0.16,0.86)
    _box("KitchenTapStem",Vector3(0.055,0.18,0.055),Vector3(4.05,1.105,1.43),chrome_mat,false)
    _box("KitchenTapSpout",Vector3(0.055,0.045,0.22),Vector3(4.05,1.19,1.52),chrome_mat,false)
    _box("ShowerPipe",Vector3(0.045,1.25,0.045),Vector3(-5.0,1.0,2.95),chrome_mat,false)
    _box("ShowerHead",Vector3(0.3,0.08,0.22),Vector3(-4.88,1.62,2.95),chrome_mat,false)
    _box("VanityMirror",Vector3(0.62,0.68,0.045),Vector3(-3.7,1.52,3.0),_material(Color(0.12,0.35,0.43),0.12,0.7),false)
    _box("BedsideCabinet",Vector3(0.58,0.62,0.58),Vector3(-5.0,0.31,-1.15),furniture_mat,true)
    _box("BedsideTop",Vector3(0.64,0.07,0.64),Vector3(-5.0,0.655,-1.15),counter_mat,false)
    _box("Wardrobe",Vector3(1.15,2.35,0.62),Vector3(-5.0,1.175,-2.65),furniture_mat,true)
    _box("WardrobeDoorSeam",Vector3(0.025,2.1,0.025),Vector3(-5.0,1.2,-2.325),trim_mat,false)
    _box("WardrobeHandle",Vector3(0.035,0.32,0.045),Vector3(-4.78,1.2,-2.3),chrome_mat,false)
    _box("DeskShelf",Vector3(1.8,0.09,0.28),Vector3(3.45,2.35,-3.25),furniture_mat,true)
    _box("WindowSill",Vector3(4.15,0.12,0.28),Vector3(0,1.02,-3.76),counter_mat,false)
    # Recessed ceiling fixtures add layered practical light without heavy real-time effects.
    for lamp_x in [-3.8,0.0,3.8]:
        var lamp=_box("CeilingDownlight",Vector3(0.32,0.06,0.32),Vector3(lamp_x,3.2,-0.2),trim_mat,false)
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
