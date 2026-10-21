extends CharacterBody3D
@export var walk_speed=7.0
@export var sprint_speed=12.5
@export var jump_velocity=8.4
@export var gravity=23.0
@export var flight_speed=34.0
@export var mouse_sensitivity=0.0018
var flight_mode=false
var _pitch=0.0
var _bob=0.0
@onready var pivot=$Pivot
@onready var camera=$Pivot/Camera3D
@onready var body_mesh=$Body
func _ready():
    add_to_group("local_player")
    add_to_group("city_presence")
    body_mesh.visible=false
    floor_snap_length=0.35
func _unhandled_input(event):
    if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x*mouse_sensitivity)
        _pitch=clampf(_pitch-event.relative.y*mouse_sensitivity,-1.48,1.48)
        pivot.rotation.x=_pitch
    if event.is_action_pressed("toggle_flight"):
        flight_mode=not flight_mode
        velocity=Vector3.ZERO
    if event.is_action_pressed("throw_prop"): _throw_prop()
func _physics_process(delta):
    var axis=Input.get_vector("move_left","move_right","move_forward","move_back")
    var wish=(global_basis.x*axis.x-global_basis.z*axis.y).normalized()
    var speed=sprint_speed if Input.is_action_pressed("sprint") else walk_speed
    if flight_mode:
        velocity=wish*flight_speed
        velocity.y+=(float(Input.is_action_pressed("jump"))-float(Input.is_key_pressed(KEY_CTRL)))*flight_speed
    else:
        velocity.x=move_toward(velocity.x,wish.x*speed,18.0*delta)
        velocity.z=move_toward(velocity.z,wish.z*speed,18.0*delta)
        if not is_on_floor(): velocity.y-=gravity*delta
        elif velocity.y<0: velocity.y=-0.4
        if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y=jump_velocity
    move_and_slide()
    if is_on_floor() and Vector2(velocity.x,velocity.z).length()>0.5 and not flight_mode:
        _bob+=delta*10.0
        pivot.position.y=1.58+sin(_bob)*0.035
    else: pivot.position.y=move_toward(pivot.position.y,1.58,delta*3)
func _throw_prop():
    var prop=RigidBody3D.new()
    prop.name="ThrownNeonCrate"
    prop.mass=2.0
    var mesh=MeshInstance3D.new()
    var box=BoxMesh.new()
    box.size=Vector3.ONE*0.55
    mesh.mesh=box
    var mat=StandardMaterial3D.new()
    mat.albedo_color=Color(0.025,0.16,0.2)
    mat.metallic=0.65
    mat.emission_enabled=true
    mat.emission=Color(0,0.85,1)
    mat.emission_energy_multiplier=2.2
    mesh.material_override=mat
    prop.add_child(mesh)
    var cs=CollisionShape3D.new()
    var shape=BoxShape3D.new()
    shape.size=box.size
    cs.shape=shape
    prop.add_child(cs)
    get_tree().current_scene.add_child(prop)
    prop.global_position=camera.global_position-camera.global_basis.z*1.4
    prop.apply_central_impulse(-camera.global_basis.z*14+Vector3.UP*4+velocity*0.4)
    get_tree().create_timer(18.0).timeout.connect(prop.queue_free)

func set_avatar_visible(show_avatar:bool):
    if is_instance_valid(body_mesh):body_mesh.visible=show_avatar
