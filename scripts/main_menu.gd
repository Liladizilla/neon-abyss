extends CanvasLayer
signal start_requested
signal host_requested(port:int,max_players:int)
signal join_requested(address:String,port:int)
signal quit_requested
var status
var address
var port
var players
func _ready():
    layer=10
    var bg=ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color=Color(0.008,0.004,0.022,0.92)
    add_child(bg)
    var center=CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)
    var panel=PanelContainer.new()
    panel.custom_minimum_size=Vector2(520,610)
    center.add_child(panel)
    var style=StyleBoxFlat.new()
    style.bg_color=Color(0.025,0.025,0.065,0.98)
    style.border_color=Color(0.08,0.78,0.94)
    style.set_border_width_all(1)
    style.set_content_margin_all(30)
    panel.add_theme_stylebox_override("panel",style)
    var stack=VBoxContainer.new()
    stack.add_theme_constant_override("separation",14)
    panel.add_child(stack)
    var title=Label.new()
    title.text="NEON ABYSS"
    title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",46)
    title.add_theme_color_override("font_color",Color(0.2,0.92,1))
    stack.add_child(title)
    var sub=Label.new()
    sub.text="ENDLESS CITY // MULTIPLAYER EXPLORATION"
    sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    stack.add_child(sub)
    _button(stack,"ENTER CITY",func():start_requested.emit())
    _button(stack,"HOST WORLD",func():host_requested.emit(int(port.value),int(players.value)))
    var row=HBoxContainer.new()
    stack.add_child(row)
    address=LineEdit.new()
    address.text="127.0.0.1"
    address.placeholder_text="Server address"
    address.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    row.add_child(address)
    port=SpinBox.new()
    port.min_value=1024
    port.max_value=65535
    port.value=27015
    row.add_child(port)
    players=SpinBox.new()
    players.min_value=2
    players.max_value=32
    players.value=12
    stack.add_child(players)
    _button(stack,"JOIN WORLD",func():join_requested.emit(address.text,int(port.value)))
    status=Label.new()
    status.text="A CITY WITH NO EDGE."
    status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    stack.add_child(status)
    _button(stack,"QUIT",func():quit_requested.emit())
func _button(parent,label,callback):
    var b=Button.new()
    b.text=label
    b.custom_minimum_size.y=44
    var st=StyleBoxFlat.new()
    st.bg_color=Color(0.035,0.075,0.11)
    st.border_color=Color(0,0.68,0.84)
    st.set_border_width_all(1)
    b.add_theme_stylebox_override("normal",st)
    b.pressed.connect(callback)
    parent.add_child(b)
func set_status(msg):
    if is_instance_valid(status):status.text=msg
func hide_menu():hide()
func show_menu():show()
