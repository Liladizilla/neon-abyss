extends SceneTree
func _initialize():
    var paths=[
        "res://scripts/rental_manager.gd",
        "res://scripts/employment_manager.gd",
        "res://scripts/apartment_interior.gd",
        "res://scripts/elevator_car.gd",
        "res://scripts/elevator_landing_door.gd",
        "res://scripts/game_root.gd",
        "res://scripts/city_chunk.gd",
        "res://scripts/city_streamer.gd",
        "res://scripts/network_manager.gd",
        "res://scripts/player_controller.gd",
        "res://scripts/remote_avatar.gd"
    ]
    for path in paths:
        var script=load(path)
        if script==null or not script.can_instantiate():
            push_error("Unable to load script: "+path)
            quit(1)
            return
    print("All core scripts loaded.")
    quit(0)
