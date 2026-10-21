# NEON ABYSS

Native Godot 4 endless cyberpunk city exploration game.

Includes deterministic streamed districts, MultiMesh architecture, setback tower crowns, skybridges, cylindrical roof tanks, antenna masts, facade windows, rooftop equipment, instanced street lamps, illuminated lamp heads, raised curbs, elevated guideway rails, sparse transit stations and transit-halo landmarks. A four-car elevated train loops through the streamed city with emissive window batches. Rendering includes wet asphalt, emissive neon, filmic tonemapping, glow, distance fog for older GPUs, and directional moon shadows. Gameplay includes first-person movement, flight mode, throwable physics props, ENet host/join, smoothed remote avatars, GPU rain and pooled traffic. Every generated tower registers four rentable units per floor at a physical lobby kiosk; the housing exchange shows occupancy, charges credits, persists contracts on the host, and builds a furnished collision-enabled private apartment interior.

## Run
Install Godot 4.4 or newer, clone this repository and open it in Godot Project Manager.

    git clone https://github.com/Liladizilla/neon-abyss.git
    cd neon-abyss

## Controls
WASD move, Shift sprint, Space jump, F flight, E throw prop, R inspect/rent or exit an apartment, mouse look, Escape release cursor.

## Multiplayer
Host or join on UDP port 27015. Internet play requires a reachable host and inbound UDP access.

## Current milestone: rentable housing
- Each generated tower exposes four units per floor, with floors matching that building's generated height.
- Lobby kiosks open the Housing Exchange; room prices vary by floor and building style.
- A resident can rent one unit, enter a furnished 3D apartment with wall/furniture collision, and return to the city with R.
- Contracts bill every 30 real-world days. The host persists contracts and wallets to user://neon_abyss_rentals.json and synchronizes the ledger to connected clients.
- The creator remains visually absent in solo mode. Visible person avatars exist only during multiplayer, and residents are hidden from other players while using their private apartment instance.
- District streaming now considers all connected player presences so the host can generate rental buildings around remote residents.

## Important limits
This is the housing prototype, not yet a persistent worldwide virtual world. The current host is an ENet session, rental data is stored on that host's local filesystem, and multiplayer identities are temporary peer IDs. A real public world still needs authenticated stable accounts, a dedicated always-on server, a production database with backups, server-authoritative economy/physics, moderation, abuse prevention, and load-tested hosting. The apartment shell is a reusable first interior, not a complete building floorplan editor or customizable home system. Detailed authored architecture, pedestrians, interactive city services and multi-client rental tests remain open milestones.

## World systems roadmap
See [the phased living-world roadmap](docs/living-world-roadmap.md) for the plan covering housing, city services, physics, and worldwide persistence.
