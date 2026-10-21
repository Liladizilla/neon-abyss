extends SceneTree

const CHUNK = preload("res://scripts/city_chunk.gd")
const RENTAL = preload("res://scripts/rental_manager.gd")
const VALID_PROFILES = ["retail", "residential_lobby", "maintenance", "loading"]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var manager = RENTAL.new()
    manager.name = "RentalManager"
    root.add_child(manager)
    var chunk = CHUNK.new()
    chunk.configure(Vector2i.ZERO, 96.0, 20261021, false)
    chunk.name = "HeadlessValidationChunk"
    root.add_child(chunk)

    # Allow _ready() to finish and register generated building footprints.
    await process_frame
    await process_frame

    var failures: Array[String] = []
    if manager.buildings.is_empty():
        failures.append("Generated chunk did not register any rentable buildings.")

    var checked_profiles := {}
    for building_id in manager.buildings:
        var building: Dictionary = manager.buildings[building_id]
        var profile := str(building.get("use_profile", ""))
        if not VALID_PROFILES.has(profile):
            failures.append("Building %s has invalid use profile '%s'." % [building_id, profile])
        if int(building.get("floors", 0)) < 1:
            failures.append("Building %s has no rentable floors." % building_id)
        checked_profiles[profile] = true

    if failures.is_empty():
        print("CITY_SMOKE_OK buildings=%d profiles=%s" % [manager.buildings.size(), str(checked_profiles.keys())])
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)
