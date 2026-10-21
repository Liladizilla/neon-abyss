extends Node3D
const PLAYER=preload("res://scenes/player.tscn")
const CITY=preload("res://scripts/city_streamer.gd")
const NET=preload("res://scripts/network_manager.gd")
const HUD=preload("res://scripts/hud.gd")
const MENU=preload("res://scripts/main_menu.gd")
var player
var network
var hud
var menu
func _ready():
    _inputs()
    _lighting()
    var city=CITY.new()
    city.name="CityStreamer"
    add_child(city)
    player=PLAYER.instantiate()
    player.name="LocalPlayer"
    add_child(player)
    network=NET.new()
    network.name="NetworkManager"
    add_child(network)
    network.set_local_player(player)
    hud=HUD.new()
    add_child(hud)
    hud.set_player(player)
    menu=MENU.new()
    add_child(menu)
    menu.start_requested.connect(_start)
    menu.host_requested.connect(_host)
    menu.join_requested.connect(_join)
    menu.quit_requested.connect(func(): get_tree().quit())
    player.visible=false
    player.set_physics_process(false)
func _inputs():
    var mapping={"move_forward":[KEY_W,KEY_UP],"move_back":[KEY_S,KEY_DOWN],"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"sprint":[KEY_SHIFT],"jump":[KEY_SPACE],"toggle_flight":[KEY_F],"throw_prop":[KEY_E],"ui_cancel":[KEY_ESCAPE]}
    for action in mapping:
        if not InputMap.has_action(action): InputMap.add_action(action)
        for key in mapping[action]:
            var ev=InputEventKey.new()
            ev.physical_keycode=key
            if not InputMap.action_has_event(action,ev): InputMap.action_add_event(action,ev)
func _lighting():
    var env=Environment.new()
    var sky=Sky.new()
    var sm=ProceduralSkyMaterial.new()
    sm.sky_top_color=Color(0.012,0.009,0.045)
    sm.sky_horizon_color=Color(0.16,0.035,0.19)
    sm.ground_bottom_color=Color(0.008,0.006,0.018)
    sm.ground_horizon_color=Color(0.06,0.018,0.075)
    sky.sky_material=sm
    env.background_mode=Environment.BG_SKY
    env.sky=sky
    env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy=0.42
    env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    env.glow_enabled=true
    env.glow_intensity=0.8
    env.ssao_enabled=true
    env.ssao_radius=2.0
    env.ssao_intensity=1.7
    env.ssil_enabled=true
    env.volumetric_fog_enabled=true
    env.volumetric_fog_density=0.018
    env.volumetric_fog_albedo=Color(0.21,0.12,0.34)
    var we=WorldEnvironment.new()
    we.environment=env
    add_child(we)
    var moon=DirectionalLight3D.new()
    moon.rotation_degrees=Vector3(-42,-28,0)
    moon.light_color=Color(0.34,0.48,1.0)
    moon.light_energy=0.65
    moon.shadow_enabled=true
    moon.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
    moon.directional_shadow_max_distance=220
    add_child(moon)
func _start():
    menu.hide_menu()
    player.visible=true
    player.set_physics_process(true)
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
    hud.show_hud()
func _host(port,players):
    var err=network.host_game(port,players)
    menu.set_status("Hosting world" if err==OK else error_string(err))
    if err==OK: _start()
func _join(address,port):
    var err=network.join_game(address,port)
    menu.set_status("Connecting..." if err==OK else error_string(err))
    if err==OK: _start()
func _unhandled_input(event):
    if event.is_action_pressed("ui_cancel"):
        Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
        if Input.mouse_mode==Input.MOUSE_MODE_VISIBLE: menu.show_menu()
        else: menu.hide_menu()
