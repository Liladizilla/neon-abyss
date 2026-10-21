# NEON ABYSS

Native Godot 4 endless cyberpunk city exploration game.

Includes deterministic streamed districts, MultiMesh architecture, setback tower crowns, skybridges, cylindrical roof tanks, antenna masts, facade windows, rooftop equipment, wet asphalt shader, filmic tonemapping, glow, distance fog for older GPUs, and directional moon shadows, first-person movement, flight mode, throwable physics props, ENet host/join, remote avatar interpolation, GPU rain and pooled traffic.

## Run
Install Godot 4.4 or newer, clone this repository and open it in Godot Project Manager.

    git clone https://github.com/Liladizilla/neon-abyss.git
    cd neon-abyss

## Controls
WASD move, Shift sprint, Space jump, F flight, E throw prop, mouse look, Escape release cursor.

## Multiplayer
Host or join on UDP port 27015. Internet play requires a reachable host and inbound UDP access.

## Status
This is the initial native foundation, not finished AAA content. Runtime validation and multi-client playtesting remain required. The current city uses layered procedural geometry and shaders; detailed licensed asset packs and authored landmark models are planned for later passes.
