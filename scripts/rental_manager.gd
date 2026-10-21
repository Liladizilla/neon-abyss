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
var return_position=Vector3.ZERO
var return_yaw=0.0
var _bill_clock=0.0
func _ready():
    add_to_group("rental_manager")
    _load_ledger()
    _build_ui()
    multiplayer.peer_connected.connect(_on_peer_connected)
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
func register_building(chunk:Vector2i,index:int,floors:int,entrance:Vector3,style:int):
    var building_id="%d:%d:%d"%[chunk.x,chunk.y,index]
    if buildings.has(building_id):
        return
    buildings[building_id]={"id":building_id,"chunk":chunk,"index":index,"floors":floors,"entrance":entrance,"style":style}
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
    var identity="creator" if not multiplayer.has_multiplayer_peer() else "peer_%d"%peer_id
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
    return "creator" if not multiplayer.has_multiplayer_peer() else "peer_%d"%multiplayer.get_unique_id()
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
    if not contracts.has(room_id):
        _send_status(peer_id,"That lease is no longer active.")
        return
    var identity="creator" if not multiplayer.has_multiplayer_peer() else "peer_%d"%peer_id
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
    return_position=player.global_position
    return_yaw=player.rotation.y
    var interior_origin=Vector3(return_position.x-6.0,10000.0,return_position.z-4.0)
    active_interior=INTERIOR.new()
    active_interior.configure(room_id,interior_origin)
    get_tree().current_scene.add_child(active_interior)
    player.global_position=interior_origin+Vector3(0,0.12,0)
    player.velocity=Vector3.ZERO
    panel.hide()
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
    var network=get_tree().get_first_node_in_group("network_manager")
    if is_instance_valid(network):network.set_local_interior(true)
    status_label.text="Apartment entered. Press R to return to the city."
func _exit_unit():
    if not is_instance_valid(active_interior):return
    active_interior.queue_free()
    active_interior=null
    if is_instance_valid(player):
        player.global_position=return_position
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
