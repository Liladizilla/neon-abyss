extends Node
## Online-session employment board. Wages use the shared housing wallet.
## Shift progress is deliberately session-bound until authenticated persistent accounts exist.
const SHIFT_SECONDS := 60.0
const JOBS := [
    {"id":"maintenance","name":"District maintenance","wage":45,"description":"Inspect infrastructure and keep the district systems running."},
    {"id":"courier","name":"Express courier","wage":60,"description":"Move urgent parcels through the neon grid."},
    {"id":"systems","name":"Network technician","wage":75,"description":"Monitor the city's public data and transit systems."}
]
var player: Node3D
var economy: Node
var workplaces: Array[Vector3] = []
var active_jobs: Dictionary = {}
var shift_progress: Dictionary = {}
var panel: CanvasLayer
var rows: VBoxContainer
var status_label: Label
var wallet_label: Label
var hint: Label
var _pay_clock := 0.0

func _ready() -> void:
    add_to_group("employment_manager")
    panel = CanvasLayer.new()
    panel.layer = 21
    add_child(panel)
    _build_ui()
    multiplayer.peer_connected.connect(_on_peer_connected)

func set_player(value: Node3D) -> void:
    player = value

func set_economy(value: Node) -> void:
    economy = value

func register_workplace(position: Vector3) -> void:
    for existing in workplaces:
        if existing.distance_to(position) < 2.0:
            return
    workplaces.append(position)

func unregister_chunk(chunk: Vector2i) -> void:
    var size := 96.0
    var min_x := float(chunk.x) * size
    var min_z := float(chunk.y) * size
    var max_x := min_x + size
    var max_z := min_z + size
    workplaces = workplaces.filter(func(p: Vector3) -> bool:
        return not (p.x >= min_x and p.x < max_x and p.z >= min_z and p.z < max_z)
    )

func _process(delta: float) -> void:
    if not is_instance_valid(player) or not player.visible:
        return
    var near := _near_workplace(player.global_position)
    if is_instance_valid(hint):
        hint.visible = near and not panel.visible
    if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
        _pay_clock += delta
        if _pay_clock >= 1.0:
            _pay_clock = 0.0
            _process_shifts()

func _unhandled_input(event: InputEvent) -> void:
    if not is_instance_valid(player) or not player.visible:
        return
    if event.is_action_pressed("work_board"):
        if panel.visible:
            panel.hide()
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        elif _near_workplace(player.global_position):
            _open_board()
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_cancel") and panel.visible:
        panel.hide()
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        get_viewport().set_input_as_handled()

func _near_workplace(position: Vector3) -> bool:
    for workplace in workplaces:
        if Vector2(position.x - workplace.x, position.z - workplace.z).length() < 9.0:
            return true
    return false

func _build_ui() -> void:
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.004, 0.008, 0.02, 0.78)
    panel.add_child(shade)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(center)
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(620, 500)
    center.add_child(card)
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.018, 0.035, 0.07, 0.99)
    skin.border_color = Color(1.0, 0.48, 0.12)
    skin.set_border_width_all(1)
    skin.set_content_margin_all(22)
    card.add_theme_stylebox_override("panel", skin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    card.add_child(stack)
    var title := Label.new()
    title.text = "ABYSS CIVIC EMPLOYMENT"
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color(1.0, 0.56, 0.2))
    stack.add_child(title)
    wallet_label = Label.new()
    stack.add_child(wallet_label)
    var note := Label.new()
    note.text = "Choose a role and start a shift. Wages are paid every 60 seconds while connected. No NPC workforce is simulated."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(note)
    rows = VBoxContainer.new()
    rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(rows)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(status_label)
    var close := Button.new()
    close.text = "CLOSE  [ESC]"
    close.pressed.connect(func() -> void:
        panel.hide()
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    )
    stack.add_child(close)
    panel.hide()
    hint = Label.new()
    hint.anchor_left = 0.5
    hint.anchor_right = 0.5
    hint.offset_left = -250
    hint.offset_right = 250
    hint.offset_top = 130
    hint.offset_bottom = 160
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.text = "CIVIC JOB BOARD  •  PRESS T"
    hint.add_theme_color_override("font_color", Color(1.0, 0.58, 0.2))
    hint.add_theme_font_size_override("font_size", 16)
    add_child(hint)
    hint.visible = false

func _open_board() -> void:
    for child in rows.get_children():
        child.queue_free()
    wallet_label.text = "WALLET  •  %d ABYSS CREDITS" % _wallet()
    var identity := _identity()
    var current_job := str(active_jobs.get(identity, ""))
    for job in JOBS:
        var line := HBoxContainer.new()
        rows.add_child(line)
        var text_block := VBoxContainer.new()
        text_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        line.add_child(text_block)
        var title := Label.new()
        title.text = "%s  •  %d credits / minute" % [job.name, job.wage]
        text_block.add_child(title)
        var description := Label.new()
        description.text = job.description
        description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        text_block.add_child(description)
        var action := Button.new()
        action.custom_minimum_size.x = 140
        if current_job == job.id:
            action.text = "CLOCK OUT"
            action.pressed.connect(_request_clock_out)
        elif current_job != "":
            action.text = "ON SHIFT"
            action.disabled = true
        else:
            action.text = "START SHIFT"
            action.pressed.connect(_request_clock_in.bind(str(job.id)))
        line.add_child(action)
    var progress := float(shift_progress.get(identity, 0.0))
    status_label.text = "Current shift: %s  •  progress %d / %d seconds" % [current_job if current_job != "" else "none", int(progress), int(SHIFT_SECONDS)]
    panel.show()

func _request_clock_in(job_id: String) -> void:
    if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
        _rpc_clock_in.rpc_id(1, job_id)
        status_label.text = "Shift request sent to the city host..."
    else:
        _server_clock_in(job_id, 1)

func _request_clock_out() -> void:
    if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
        _rpc_clock_out.rpc_id(1)
        status_label.text = "Clock-out request sent..."
    else:
        _server_clock_out(1)

func _server_clock_in(job_id: String, peer_id: int) -> void:
    if not _valid_job(job_id):
        _status(peer_id, "Unknown job role.")
        return
    if not _peer_near_workplace(peer_id):
        _status(peer_id, "Use the job board beside a tower lobby.")
        return
    var identity := _identity_for_peer(peer_id)
    if str(active_jobs.get(identity, "")) != "":
        _status(peer_id, "Clock out before changing roles.")
        return
    active_jobs[identity] = job_id
    shift_progress[identity] = 0.0
    _sync_state()
    _status(peer_id, "Shift started. Wages arrive after 60 seconds online.")

func _server_clock_out(peer_id: int) -> void:
    var identity := _identity_for_peer(peer_id)
    if str(active_jobs.get(identity, "")) == "":
        _status(peer_id, "You are not currently clocked in.")
        return
    active_jobs.erase(identity)
    shift_progress.erase(identity)
    _sync_state()
    _status(peer_id, "Shift ended. Any partial minute was not paid.")

func _process_shifts() -> void:
    var changed := false
    for identity in active_jobs.keys():
        shift_progress[identity] = float(shift_progress.get(identity, 0.0)) + 1.0
        if float(shift_progress[identity]) < SHIFT_SECONDS:
            continue
        shift_progress[identity] = 0.0
        var job_id := str(active_jobs[identity])
        var wage := 0
        for job in JOBS:
            if str(job.id) == job_id:
                wage = int(job.wage)
                break
        if is_instance_valid(economy):
            economy.wallets[identity] = int(economy.wallets.get(identity, 2500)) + wage
        changed = true
    if changed and is_instance_valid(economy):
        economy._save_ledger()
        _sync_state()
        if panel.visible:
            _open_board()

func _peer_near_workplace(peer_id: int) -> bool:
    if not multiplayer.has_multiplayer_peer() or peer_id == 1:
        return is_instance_valid(player) and _near_workplace(player.global_position)
    var network := get_tree().get_first_node_in_group("network_manager")
    if not is_instance_valid(network) or not network.avatars.has(peer_id):
        return false
    return _near_workplace(network.avatars[peer_id].global_position)

func _valid_job(job_id: String) -> bool:
    for job in JOBS:
        if str(job.id) == job_id:
            return true
    return false

func _identity_for_peer(peer_id: int) -> String:
    if not multiplayer.has_multiplayer_peer() or peer_id == 1:
        return "creator"
    return "peer_%d" % peer_id

func _identity() -> String:
    return _identity_for_peer(multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1)

func _wallet() -> int:
    if not is_instance_valid(economy):
        return 0
    return int(economy.wallets.get(_identity(), 2500))

func _status(peer_id: int, message: String) -> void:
    if multiplayer.has_multiplayer_peer() and multiplayer.is_server() and peer_id != 1:
        _status_to_peer.rpc_id(peer_id, message)
    else:
        status_label.text = message

func _sync_state() -> void:
    if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
        _sync_jobs.rpc(active_jobs, shift_progress, economy.wallets)
    if panel.visible:
        _open_board()

func _on_peer_connected(id: int) -> void:
    if multiplayer.is_server():
        _sync_jobs.rpc_id(id, active_jobs, shift_progress, economy.wallets)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_clock_in(job_id: String) -> void:
    if multiplayer.is_server():
        _server_clock_in(job_id, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func _rpc_clock_out() -> void:
    if multiplayer.is_server():
        _server_clock_out(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func _sync_jobs(jobs: Dictionary, progress: Dictionary, wallets: Dictionary) -> void:
    active_jobs = jobs.duplicate(true)
    shift_progress = progress.duplicate(true)
    if is_instance_valid(economy):
        economy.wallets = wallets.duplicate(true)
    if panel.visible:
        _open_board()

@rpc("authority", "call_remote", "reliable")
func _status_to_peer(message: String) -> void:
    status_label.text = message
