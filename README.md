# NEON ABYSS

Native Godot 4 endless cyberpunk city exploration game.

## Current foundation
- Deterministic streamed procedural districts.
- MultiMesh architecture, roof equipment, facade windows and neon signage.
- Procedural wet asphalt shader.
- Filmic tonemapping, glow, SSAO, SSIL, volumetric fog and directional moon shadows.
- First-person movement, sprint, jump, flight mode and throwable physics props.
- ENet host/join and remote avatar transform replication.
- Grid/speed/altitude/FPS HUD.

## Run
Install Godot 4.4 or newer, clone this repository and open it in Godot Project Manager.

    git clone https://github.com/Liladizilla/neon-abyss.git
    cd neon-abyss

## Controls
WASD move, Shift sprint, Space jump, F flight, E throw prop, mouse look, Escape release cursor.

## Multiplayer
Host or join on UDP port 27015. Internet play requires a reachable host and inbound UDP access.

## Status
This is the initial native foundation, not finished AAA content. Visual runtime testing and multi-client playtesting remain required. The current city uses procedural geometry; detailed licensed asset packs will be added in later passes.
