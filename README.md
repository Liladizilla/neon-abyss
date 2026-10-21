# NEON ABYSS

Native Godot 4 endless cyberpunk city exploration game.

Includes deterministic streamed districts, MultiMesh architecture, setback tower crowns, skybridges, cylindrical roof tanks, antenna masts, facade windows, rooftop equipment, instanced street lamps, illuminated lamp heads, raised curbs, and sparse transit-halo landmarks. Rendering includes wet asphalt, emissive neon, filmic tonemapping, glow, distance fog for older GPUs, and directional moon shadows. Gameplay includes first-person movement, flight mode, throwable physics props, ENet host/join, smoothed remote avatars, GPU rain and pooled traffic.

## Run
Install Godot 4.4 or newer, clone this repository and open it in Godot Project Manager.

    git clone https://github.com/Liladizilla/neon-abyss.git
    cd neon-abyss

## Controls
WASD move, Shift sprint, Space jump, F flight, E throw prop, mouse look, Escape release cursor.

## Multiplayer
Host or join on UDP port 27015. Internet play requires a reachable host and inbound UDP access.

## Current milestone
The environment pass now adds street-level furniture and a recognizable elevated transit-halo landmark to the deterministic streamed city. Multiplayer avoids creating a second avatar for the local peer. The city is still procedural geometry rather than a finished AAA asset library; bespoke hero buildings, detailed vehicles and pedestrians, and real multi-client network playtests remain open milestones.
