extends Node
signal connection_status(message:String)
const AVATAR=preload("res://scenes/remote_player.tscn")
var peer:ENetMultiplayerPeer
var local_player:Node3D
var avatars={}
var clock=0.0
func set_local_player(p): local_player=p
func _ready():
    multiplayer.peer_connected.connect(_peer_joined)
    multiplayer.peer_disconnected.connect(_peer_left)
    multiplayer.connected_to_server.connect(func(): connection_status.emit("Connected"))
    multiplayer.connection_failed.connect(func(): connection_status.emit("Connection failed"))
    multiplayer.server_disconnected.connect(func(): connection_status.emit("Server disconnected"))
func host_game(port=27015,max_players=12)->Error:
    peer=ENetMultiplayerPeer.new()
    var err=peer.create_server(port,clampi(max_players,2,32))
    if err!=OK:return err
    multiplayer.multiplayer_peer=peer
    _spawn(1)
    return OK
func join_game(address,port=27015)->Error:
    peer=ENetMultiplayerPeer.new()
    var err=peer.create_client(address.strip_edges(),port)
    if err!=OK:return err
    multiplayer.multiplayer_peer=peer
    return OK
func _process(delta):
    if not is_instance_valid(local_player) or not local_player.visible or multiplayer.multiplayer_peer==null:return
    clock+=delta
    if clock<0.05:return
    clock=0.0
    var pos=local_player.global_position
    var yaw=local_player.rotation.y
    if multiplayer.is_server():
        _apply(1,pos,yaw)
        _relay.rpc(1,pos,yaw)
    else:_submit.rpc_id(1,pos,yaw)
func _peer_joined(id):
    if not multiplayer.is_server():return
    _spawn_avatar.rpc_id(id,1)
    for old in multiplayer.get_peers():
        if old!=id:_spawn_avatar.rpc_id(id,old)
    _spawn(id)
    _spawn_avatar.rpc(id)
func _peer_left(id):
    _despawn(id)
    if multiplayer.is_server():_despawn_avatar.rpc(id)
func _spawn(id):
    if avatars.has(id):return
    var a=AVATAR.instantiate()
    a.name="Peer_%d"%id
    a.set_multiplayer_authority(id)
    get_tree().current_scene.add_child(a)
    avatars[id]=a
func _despawn(id):
    if avatars.has(id):
        if is_instance_valid(avatars[id]):avatars[id].queue_free()
        avatars.erase(id)
func _apply(id,pos,yaw):
    if avatars.has(id) and is_instance_valid(avatars[id]):avatars[id].set_network_state(pos,yaw)
@rpc("any_peer","call_remote","unreliable")
func _submit(pos,yaw):
    if not multiplayer.is_server():return
    var id=multiplayer.get_remote_sender_id()
    _apply(id,pos,yaw)
    _relay.rpc(id,pos,yaw)
@rpc("authority","call_remote","unreliable")
func _relay(id,pos,yaw):_apply(id,pos,yaw)
@rpc("authority","call_remote","reliable")
func _spawn_avatar(id):_spawn(id)
@rpc("authority","call_remote","reliable")
func _despawn_avatar(id):_despawn(id)
