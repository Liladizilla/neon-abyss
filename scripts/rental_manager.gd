extends Node
## Deterministic room registry with host-authoritative rental ownership.
## This is a prototype persistence layer; stable accounts and a production database come later.
signal rental_status(message:String)
const SAVE_PATH="user://neon_abyss_rentals.json"
const INTERIOR=preload("res://scripts/apartment_interior.gd")
const UNITS_PER_FLOOR=4
const CONTRACT_SECONDS=2592000
var player:Node3D
var buildings:Dictionary={}
var contracts:Dictionary={}
var wallets:Dictionary={"creator":2500}
var profile_id="creator"
var nearest_building=""
var panel:CanvasLayer
var list_box:VBoxContainer
var info_label:Label
var status_label:Label
var wallet_label:Label
var active_interior:Node3D
var active_room_id=""
var interior_rooms_by_peer:Dictionary={}
var return_position=Vector3.ZERO
var return_yaw=0.0
var _bill_clock=0.0
func _ready():
    add_to_group("rental_manager")
    _load_ledger()
    _build_ui()
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(func(): _request_ledger.rpc_id(1))
func set_player(p):
    player=p
func _process(delta):
    if not is_instance_valid(player) or not player.visible:
        return
    var best=""
    var best_distance=7.0
    for building_id in buildings:
        var entry:Dictionary=buildings[building_id]
        var distance=player.global_position.distance_to(entry.entrance)
        if distance<best_distance:
            best_distance=distance
            best=building_id
    nearest_building=best
    if is_instance_valid(info_label):
        if best!="":
            info_label.text="ROOMS AVAILABLE  •  Press R to inspect / rent"
            info_label.visible=not panel.visible
        else:
            info_label.visible=false
    _bill_clock+=delta
    if _bill_clock>=10.0:
        _bill_clock=0.0
        if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
            _process_due_rent()
func _unhandled_input(event):
    if not is_instance_valid(player) or not player.visible:
        return
    if event.is_action_pressed("interact"):
        if panel.visible:
            panel.hide()
            Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
        elif is_instance_valid(active_interior):
            _exit_unit()
            get_viewport().set_input_as_handled()
        elif nearest_building!="":
            _open_building(nearest_building)
            Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
            get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_cancel") and panel.visible:
        panel.hide()
        Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
        get_viewport().set_input_as_handled()
func register_building(chunk:Vector2i,index:int,floors:int,entrance:Vector3,style:int,center:Vector3,dimensions:Vector3,floor_height:float):
    var building_id="%d:%d:%d"%[chunk.x,chunk.y,index]
    if buildings.has(building_id):
        return
    buildings[building_id]={"id":building_id,"chunk":chunk,"index":index,"floors":floors,"entrance":entrance,"style":style,"center":center,"dimensions":dimensions,"floor_height":floor_height}
func unregister_chunk(chunk:Vector2i):
    for building_id in buildings.keys():
        var entry:Dictionary=buildings[building_id]
        if entry.chunk==chunk:
            buildings.erase(building_id)
    if nearest_building!="" and not buildings.has(nearest_building):
        nearest_building=""
func _build_ui():
    panel=CanvasLayer.new()
    panel.layer=20
    add_child(panel)
    var shade=ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color=Color(0.004,0.008,0.02,0.76)
    panel.add_child(shade)
    var center=CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(center)
    var card=PanelContainer.new()
    card.custom_minimum_size=Vector2(600,560)
    center.add_child(card)
    var style=StyleBoxFlat.new()
    style.bg_color=Color(0.018,0.035,0.07,0.99)
    style.border_color=Color(0.0,0.75,0.9)
    style.set_border_width_all(1)
    style.set_content_margin_all(22)
    card.add_theme_stylebox_override("panel",style)
    var stack=VBoxContainer.new()
    stack.add_theme_constant_override("separation",10)
    card.add_child(stack)
    var title=Label.new()
    title.text="ABYSS HOUSING EXCHANGE"
    title.add_theme_font_size_override("font_size",24)
    title.add_theme_color_override("font_color",Color(0.15,0.9,1.0))
    stack.add_child(title)
    wallet_label=Label.new()
    stack.add_child(wallet_label)
    var note=Label.new()
    note.text="Four private units per floor. Contracts last 30 real-world days."
    note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(note)
    var scroll=ScrollContainer.new()
    scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
    stack.add_child(scroll)
    list_box=VBoxContainer.new()
    list_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    scroll.add_child(list_box)
    status_label=Label.new()
    status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(status_label)
    var close=Button.new()
    close.text="CLOSE  [ESC]"
    close.pressed.connect(func(): panel.hide(); Input.mouse_mode=Input.MOUSE_MODE_CAPTURED)
    stack.add_child(close)
    panel.hide()
    info_label=Label.new()
    info_label.position=Vector2(0,0)
    info_label.anchor_left=0.5
    info_label.anchor_right=0.5
    info_label.offset_left=-240
    info_label.offset_right=240
    info_label.offset_top=95
    info_label.offset_bottom=125
    info_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    info_label.add_theme_color_override("font_color",Color(0.2,0.95,1))
    info_label.add_theme_font_size_override("font_size",16)
    add_child(info_label)
    info_label.visible=false
func _open_building(building_id:String):
    if not buildings.has(building_id):
        return
    var building:Dictionary=buildings[building_id]
    wallet_label.text="WALLET  •  %d ABYSS CREDITS"%_wallet()
    status_label.text="Building %s  •  %d floors  •  %d possible units"%[building_id,building.floors,building.floors*UNITS_PER_FLOOR]
    for child in list_box.get_children():
        child.queue_free()
    var owned_room=""
    for room_id in contracts:
        if str(contracts[room_id].get("owner",""))==_identity():
            owned_room=room_id
            break
    if owned_room!="":
        var owned=Button.new()
        owned.text="MY RENTED UNIT  •  "+owned_room
        owned.pressed.connect(_enter_unit.bind(owned_room))
        list_box.add_child(owned)
        var release=Button.new()
        release.text="RELEASE LEASE  •  NO REFUND"
        release.pressed.connect(_release_lease.bind(owned_room))
        list_box.add_child(release)
    var shown=0
    for floor_number in range(1,int(building.floors)+1):
        for unit_number in range(1,UNITS_PER_FLOOR+1):
            var room_id=_room_id(building_id,floor_number,unit_number)
            var rent=_rent_for(building,floor_number,unit_number)
            var line=HBoxContainer.new()
            list_box.add_child(line)
            var label=Label.new()
            label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
            var contract:Dictionary=contracts.get(room_id,{})
            if contract.is_empty():
                label.text="F%02d / UNIT %d    •    %d credits / 30 days"%[floor_number,unit_number,rent]
            elif str(contract.get("owner",""))==_identity():
                label.text="F%02d / UNIT %d    •    YOUR CONTRACT"%[floor_number,unit_number]
            else:
                label.text="F%02d / UNIT %d    •    OCCUPIED"%[floor_number,unit_number]
            line.add_child(label)
            var button=Button.new()
            button.custom_minimum_size.x=104
            if contract.is_empty():
                button.text="RENT"
                button.disabled=not _can_request_here(building_id) or _wallet()<rent or _has_contract()
                button.pressed.connect(_rent.bind(room_id,building_id,rent))
            elif str(contract.get("owner",""))==_identity():
                button.text="ENTER"
                button.pressed.connect(_enter_unit.bind(room_id))
            else:
                button.text="TAKEN"
                button.disabled=true
            line.add_child(button)
            shown+=1
    panel.show()
func _can_request_here(building_id:String)->bool:
    if not buildings.has(building_id) or not is_instance_valid(player):
        return false
    return player.global_position.distance_to(buildings[building_id].entrance)<10.0
func _has_contract()->bool:
    for room_id in contracts:
        if str(contracts[room_id].get("owner",""))==_identity():
            return true
    return false
func _room_id(building_id:String,floor_number:int,unit_number:int)->String:
    return "%s/F%02d/U%d"%[building_id,floor_number,unit_number]
func _rent_for(building:Dictionary,floor_number:int,unit_number:int)->int:
    return 100+floor_number*12+unit_number*5+int(building.style)*8
func _rent(room_id:String,building_id:String,price:int):
    if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
        var pieces=room_id.split("/")
        var floor_number=int(str(pieces[1]).substr(1,2))
        var unit_number=int(str(pieces[2]).substr(1))
        _request_rent.rpc_id(1,room_id,building_id,floor_number,unit_number)
        status_label.text="Rental request sent to the city host..."
        return
    var pieces=room_id.split("/")
    var floor_number=int(str(pieces[1]).substr(1,2))
    var unit_number=int(str(pieces[2]).substr(1))
    _server_rent(room_id,building_id,floor_number,unit_number,1)
func _server_rent(room_id:String,building_id:String,floor_number:int,unit_number:int,peer_id:int):
    if not buildings.has(building_id) or contracts.has(room_id):
        _send_status(peer_id,"That unit is no longer available.")
        return
    var building:Dictionary=buildings[building_id]
    if floor_number<1 or floor_number>int(building.floors) or unit_number<1 or unit_number>UNITS_PER_FLOOR or room_id!=_room_id(building_id,floor_number,unit_number):
        _send_status(peer_id,"Invalid room selection.")
        return
    if not _can_peer_reach(peer_id,building_id):
        _send_status(peer_id,"Move closer to this building's rental terminal.")
        return
    var price=_rent_for(building,floor_number,unit_number)
    var identity="creator" if not multiplayer.has_multiplayer_peer() or peer_id==1 else "peer_%d"%peer_id
    if _has_contract_for(identity):
        _send_status(peer_id,"You already have a unit. Release it before renting another.")
        return
    var current=int(wallets.get(identity,2500))
    if current<price:
        _send_status(peer_id,"Insufficient credits.")
        return
    wallets[identity]=current-price
    contracts[room_id]={"owner":identity,"rent":price,"next_due":int(Time.get_unix_time_from_system())+CONTRACT_SECONDS,"building":building_id}
    _save_ledger()
    if multiplayer.has_multiplayer_peer():_sync_ledger.rpc(contracts,wallets)
    _send_status(peer_id,"Lease secured. Your unit is reserved for 30 days.")
    if peer_id==1:_open_building(building_id)
func _can_peer_reach(peer_id:int,building_id:String)->bool:
    if not buildings.has(building_id):return false
    if not multiplayer.has_multiplayer_peer() or peer_id==1:
        return is_instance_valid(player) and player.global_position.distance_to(buildings[building_id].entrance)<10.0
    var network=get_tree().get_first_node_in_group("network_manager")
    if not is_instance_valid(network) or not network.avatars.has(peer_id):return false
    return network.avatars[peer_id].global_position.distance_to(buildings[building_id].entrance)<10.0
func _has_contract_for(identity:String)->bool:
    for room_id in contracts:
        if str(contracts[room_id].get("owner",""))==identity:return true
    return false
func _identity()->String:
    return "creator" if not multiplayer.has_multiplayer_peer() or multiplayer.is_server() else "peer_%d"%multiplayer.get_unique_id()
func _wallet()->int:
    return int(wallets.get(_identity(),2500))
func _send_status(peer_id:int,message:String):
    if multiplayer.has_multiplayer_peer() and multiplayer.is_server() and peer_id!=1:
        _status_to_peer.rpc_id(peer_id,message)
    else:
        status_label.text=message
@rpc("any_peer","call_remote","reliable")
func _request_rent(room_id:String,building_id:String,floor_number:int,unit_number:int):
    if not multiplayer.is_server():return
    var peer_id=multiplayer.get_remote_sender_id()
    _server_rent(room_id,building_id,floor_number,unit_number,peer_id)
func _release_lease(room_id:String):
    if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
        _request_release.rpc_id(1,room_id)
        status_label.text="Lease release requested..."
        return
    _server_release(room_id,1)
func _server_release(room_id:String,peer_id:int):
    if interior_rooms_by_peer.values().has(room_id):
        _send_status(peer_id,"Exit the apartment before releasing its lease.")
        return
    if not contracts.has(room_id):
        _send_status(peer_id,"That lease is no longer active.")
        return
    var identity="creator" if not multiplayer.has_multiplayer_peer() or peer_id==1 else "peer_%d"%peer_id
    if str(contracts[room_id].get("owner",""))!=identity:
        _send_status(peer_id,"You do not own that lease.")
        return
    contracts.erase(room_id)
    _save_ledger()
    if multiplayer.has_multiplayer_peer():_sync_ledger.rpc(contracts,wallets)
    _send_status(peer_id,"Lease released. No refund is issued.")
    if peer_id==1 and buildings.has(nearest_building):_open_building(nearest_building)
@rpc("any_peer","call_remote","reliable")
func _request_release(room_id:String):
    if not multiplayer.is_server():return
    _server_release(room_id,multiplayer.get_remote_sender_id())
@rpc("authority","call_remote","reliable")
func _sync_ledger(new_contracts:Dictionary,new_wallets:Dictionary):
    contracts=new_contracts.duplicate(true)
    wallets=new_wallets.duplicate(true)
    if panel.visible and nearest_building!="":_open_building(nearest_building)
@rpc("authority","call_remote","reliable")
func _status_to_peer(message:String):
    status_label.text=message
@rpc("any_peer","call_remote","reliable")
func _request_ledger():
    if not multiplayer.is_server():return
    _sync_ledger.rpc_id(multiplayer.get_remote_sender_id(),contracts,wallets)
func _on_peer_connected(id:int):
    if multiplayer.is_server():
        _sync_ledger.rpc_id(id,contracts,wallets)
func _on_peer_disconnected(id:int):
    if multiplayer.is_server():
        interior_rooms_by_peer.erase(id)
func _process_due_rent():
    var now=int(Time.get_unix_time_from_system())
    var changed=false
    for room_id in contracts.keys():
        var contract:Dictionary=contracts[room_id]
        if int(contract.get("next_due",0))>now:continue
        var owner=str(contract.get("owner",""))
        var rent=int(contract.get("rent",0))
        var balance=int(wallets.get(owner,0))
        if balance>=rent:
            wallets[owner]=balance-rent
            contract.next_due=now+CONTRACT_SECONDS
            contracts[room_id]=contract
        else:
            contracts.erase(room_id)
        changed=true
    if changed:
        _save_ledger()
        if multiplayer.has_multiplayer_peer():_sync_ledger.rpc(contracts,wallets)
func _enter_unit(room_id:String):
    if not contracts.has(room_id) or str(contracts[room_id].get("owner",""))!=_identity():
        status_label.text="You do not hold this lease."
        return
    if not is_instance_valid(player):return
    if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
        status_label.text="Validating your lease with the city host..."
        _request_enter_unit.rpc_id(1,room_id)
        return
    if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
        _server_enter_unit(room_id,1)
        return
    _open_unit_local(room_id)
@rpc("any_peer","call_remote","reliable")
func _request_enter_unit(room_id:String):
    if not multiplayer.is_server():return
    _server_enter_unit(room_id,multiplayer.get_remote_sender_id())
func _server_enter_unit(room_id:String,peer_id:int):
    if not contracts.has(room_id):
        _send_status(peer_id,"That lease is no longer active.")
        return
    var identity=_identity_for_peer(peer_id)
    if str(contracts[room_id].get("owner",""))!=identity:
        _send_status(peer_id,"The city host rejected entry: this lease does not belong to you.")
        return
    if interior_rooms_by_peer.has(peer_id):
        _send_status(peer_id,"Exit your current apartment before entering another.")
        return
    var building_id=str(contracts[room_id].get("building",""))
    if not buildings.has(building_id):
        _send_status(peer_id,"This tower is not currently streamed. Return to its lobby and try again.")
        return
    interior_rooms_by_peer[peer_id]=room_id
    if peer_id==1:
        _open_unit_local(room_id)
    else:
        _grant_unit_entry.rpc_id(peer_id,room_id)
@rpc("authority","call_remote","reliable")
func _grant_unit_entry(room_id:String):
    if not contracts.has(room_id) or str(contracts[room_id].get("owner",""))!=_identity():
        status_label.text="Entry cancelled: the lease is no longer valid."
        return
    if not is_instance_valid(player) or is_instance_valid(active_interior):
        status_label.text="Cannot open the apartment while another interior is active."
        return
    _open_unit_local(room_id)
@rpc("any_peer","call_remote","reliable")
func _request_exit_unit(room_id:String):
    if not multiplayer.is_server():return
    var peer_id=multiplayer.get_remote_sender_id()
    if str(interior_rooms_by_peer.get(peer_id,""))==room_id:
        interior_rooms_by_peer.erase(peer_id)
func _identity_for_peer(peer_id:int)->String:
    if not multiplayer.has_multiplayer_peer() or peer_id==1:return "creator"
    return "peer_%d"%peer_id
func _open_unit_local(room_id:String):
    if not contracts.has(room_id) or str(contracts[room_id].get("owner",""))!=_identity():
        status_label.text="You do not hold this lease."
        return
    if not is_instance_valid(player) or is_instance_valid(active_interior):return
    return_position=player.global_position
    return_yaw=player.rotation.y
    active_room_id=room_id
    var room_parts=room_id.split("/")
    var floor_number=int(str(room_parts[1]).substr(1,2))
    var contract:Dictionary=contracts[room_id]
    var building_id=str(contract.get("building",""))
    if not buildings.has(building_id):
        active_room_id=""
        status_label.text="Return to the tower lobby to reconnect to this building."
        return
    var building:Dictionary=buildings[building_id]
    var floor_height:float=float(building.get("floor_height",3.6))
    var building_center:Vector3=building.center
    var dimensions:Vector3=building.dimensions
    var style:int=int(building.style)
    var base_height:float=dimensions.y*(0.58 if style==2 or style==4 else 0.72)
    var upper_width:float=dimensions.x*(0.58 if style==1 or style==4 else 0.78)
    var floor_mid_y:float=float(floor_number-1)*floor_height+maxf(0.2,floor_height-0.12)*0.5
    var floor_width:float=upper_width if floor_mid_y>=base_height else dimensions.x
    var facade_x:float=building_center.x+floor_width*0.5
    var lift_x:float=building_center.x+dimensions.x*0.5+4.6
    var unit_number:int=int(str(room_parts[2]).substr(1))
    var unit_offsets:Dictionary={1:-18.3,2:-6.1,3:6.1,4:18.3}
    var unit_z:float=building_center.z+float(unit_offsets.get(unit_number,0.0))
    var interior_origin:Vector3=Vector3(facade_x+8.5,float(building.entrance.y)-1.0+float(floor_number-1)*floor_height+0.24,unit_z)
    active_interior=INTERIOR.new()
    active_interior.name="PrivateApartment_%s"%room_id.replace("/","_")
    active_interior.configure(room_id,interior_origin)
    active_interior.rotation.y=PI*0.5
    get_tree().current_scene.add_child(active_interior)
    _build_apartment_access(facade_x,lift_x,unit_z,building_center.z,interior_origin.y,room_id)
    player.global_position=Vector3(lift_x,interior_origin.y,building_center.z)
    player.rotation.y=PI if unit_z>building_center.z else 0.0
    player.add_to_group("private_interior")
    player.velocity=Vector3.ZERO
    panel.hide()
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
    var network=get_tree().get_first_node_in_group("network_manager")
    if is_instance_valid(network):network.set_local_interior(true)
    status_label.text="Access corridor opened. Follow the floor lights to your unit; press R to return to the city."
func _build_apartment_access(facade_x:float,lift_x:float,unit_z:float,center_z:float,floor_y:float,room_id:String)->void:
    var access:=Node3D.new()
    access.name="ApartmentAccess_%s"%room_id.replace("/","_")
    get_tree().current_scene.add_child(access)
    var floor_mat:=StandardMaterial3D.new()
    floor_mat.albedo_color=Color(0.045,0.075,0.11)
    floor_mat.metallic=0.68
    floor_mat.roughness=0.28
    var rail_mat:=StandardMaterial3D.new()
    rail_mat.albedo_color=Color(0.02,0.48,0.62)
    rail_mat.emission_enabled=true
    rail_mat.emission=Color(0.01,0.22,0.34)
    rail_mat.emission_energy_multiplier=1.2
    var corridor_mid_z:float=(center_z+unit_z)*0.5
    var corridor_length:float=maxf(1.0,absf(unit_z-center_z))
    _add_access_segment(access,"LandingCorridor",Vector3(lift_x,floor_y-0.09,corridor_mid_z),Vector3(2.8,0.18,corridor_length+2.8),floor_mat,true)
    var door_x:float=facade_x+4.5
    var connector_length:float=maxf(0.8,absf(lift_x-door_x))
    _add_access_segment(access,"UnitConnector",Vector3((lift_x+door_x)*0.5,floor_y-0.09,unit_z),Vector3(connector_length+0.6,0.18,2.8),floor_mat,true)
    for side in [-1.0,1.0]:
        _add_access_segment(access,"CorridorRail",Vector3(lift_x+side*1.34,floor_y+0.42,corridor_mid_z),Vector3(0.10,0.92,corridor_length+2.8),rail_mat,true)
        _add_access_segment(access,"ConnectorRail",Vector3((lift_x+door_x)*0.5,floor_y+0.42,unit_z+side*1.34),Vector3(connector_length+0.6,0.92,0.10),rail_mat,true)
    if is_instance_valid(active_interior):
        active_interior.set_meta("access_corridor",access)
func _add_access_segment(parent:Node3D,label:String,at:Vector3,dimensions:Vector3,material:Material,collide:bool)->void:
    var mesh_node:=MeshInstance3D.new()
    mesh_node.name=label
    var mesh:=BoxMesh.new()
    mesh.size=dimensions
    mesh_node.mesh=mesh
    mesh_node.material_override=material
    mesh_node.position=at
    parent.add_child(mesh_node)
    if collide:
        var body:=StaticBody3D.new()
        body.name=label+"_Collision"
        var shape:=CollisionShape3D.new()
        var box:=BoxShape3D.new()
        box.size=dimensions
        shape.shape=box
        body.position=at
        body.add_child(shape)
        parent.add_child(body)
func _exit_unit():
    if not is_instance_valid(active_interior):return
    var leaving_room=active_room_id
    if multiplayer.has_multiplayer_peer():
        if multiplayer.is_server():
            if str(interior_rooms_by_peer.get(1,""))==leaving_room:interior_rooms_by_peer.erase(1)
        else:
            _request_exit_unit.rpc_id(1,leaving_room)
    active_room_id=""
    if active_interior.has_meta("access_corridor"):
        var access:Node3D=active_interior.get_meta("access_corridor")
        if is_instance_valid(access):access.queue_free()
    active_interior.queue_free()
    active_interior=null
    if is_instance_valid(player):
        player.global_position=return_position
        player.remove_from_group("private_interior")
        player.rotation.y=return_yaw
        player.velocity=Vector3.ZERO
    var network=get_tree().get_first_node_in_group("network_manager")
    if is_instance_valid(network):network.set_local_interior(false)
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func _save_ledger():
    var file=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"contracts":contracts,"wallets":wallets}))
func _load_ledger():
    if not FileAccess.file_exists(SAVE_PATH):return
    var file=FileAccess.open(SAVE_PATH,FileAccess.READ)
    if not file:return
    var parsed=JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        contracts=parsed.get("contracts",{})
        wallets=parsed.get("wallets",{"creator":2500})
