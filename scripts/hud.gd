extends CanvasLayer
var player
var top
var sub
var right
var elapsed=0.0
var frames=0
var fps=60.0
func _ready():
    layer=5
    var root=Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    top=Label.new()
    top.position=Vector2(26,22)
    top.add_theme_font_size_override("font_size",17)
    top.add_theme_color_override("font_color",Color(0.35,0.95,1))
    root.add_child(top)
    sub=Label.new()
    sub.position=Vector2(26,78)
    sub.add_theme_color_override("font_color",Color(0.95,0.28,0.78))
    root.add_child(sub)
    right=Label.new()
    right.anchor_left=1
    right.anchor_right=1
    right.offset_left=-300
    right.offset_right=-24
    right.offset_top=24
    right.offset_bottom=100
    right.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
    root.add_child(right)
    var cross=ColorRect.new()
    cross.size=Vector2(5,5)
    cross.position=get_viewport().get_visible_rect().size*0.5-cross.size*0.5
    cross.color=Color(0.35,0.95,1)
    root.add_child(cross)
    var footer=Label.new()
    footer.anchor_top=1
    footer.anchor_bottom=1
    footer.offset_left=24
    footer.offset_top=-48
    footer.offset_right=900
    footer.offset_bottom=-16
    footer.text="WASD MOVE / SHIFT SPRINT / SPACE JUMP / F FLIGHT / E THROW / R HOUSING / ESC MENU"
    footer.add_theme_font_size_override("font_size",12)
    root.add_child(footer)
    hide()
func set_player(p):player=p
func show_hud():show()
func _process(delta):
    elapsed+=delta
    frames+=1
    if elapsed<0.5:return
    fps=float(frames)/elapsed
    elapsed=0
    frames=0
    if is_instance_valid(player):
        var p=player.global_position
        var speed=Vector2(player.velocity.x,player.velocity.z).length()*3.6
        if player.is_in_group("private_interior"):
            top.text="NEON ABYSS // PRIVATE RESIDENCE"
            sub.text="LEASED UNIT    •    PRESS R TO RETURN TO CITY"
        else:
            top.text="NEON ABYSS // GRID %d : %d"%[floori(p.x/96),floori(p.z/96)]
            sub.text="ALT %04d M    VEL %03d KM/H"%[roundi(p.y),roundi(speed)]
        right.text="%d FPS\n%s"%[roundi(fps),"FLIGHT MODE" if player.flight_mode else "ON FOOT"]
