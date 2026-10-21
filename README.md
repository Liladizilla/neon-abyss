# NEON ABYSS

Native Godot 4 endless cyberpunk city exploration game.

Includes deterministic streamed districts, hollow procedural tower shells with split floor plates and compact stair flights with handrails, setback upper floors, skybridges, cylindrical roof tanks, antenna masts, facade windows, rooftop equipment, instanced street lamps, illuminated lamp heads, raised curbs, elevated guideway rails, sparse transit stations and transit-halo landmarks. A four-car elevated train loops through the streamed city with emissive window batches. Rendering includes wet asphalt, emissive neon, filmic tonemapping, glow, distance fog for older GPUs, and directional moon shadows. Gameplay includes first-person movement, flight mode, throwable physics props, ENet host/join, smoothed remote avatars, GPU rain and pooled traffic. Every generated tower registers four rentable units per floor at a physical lobby kiosk; the housing exchange shows occupancy, charges credits, persists contracts on the host, and builds a furnished collision-enabled private apartment interior.

## Run
Install Godot 4.4 or newer, clone this repository and open it in Godot Project Manager.

    git clone https://github.com/Liladizilla/neon-abyss.git
    cd neon-abyss

## Controls
WASD move, Shift sprint, Space jump, F flight, E throw prop, R inspect/rent or exit an apartment, T civic job board near tower lobbies, G call/select an elevator floor beside a tower lift shaft, mouse look, Escape release cursor.

## Multiplayer
Host or join on UDP port 27015. Internet play requires a reachable host and inbound UDP access.

## Current milestone: rentable housing
- Each generated tower exposes four units per floor, with floors matching that building's generated height.
- Lobby kiosks open the Housing Exchange; room prices vary by floor and building style.
- A resident can rent one unit and enter a furnished suite at the selected floor's elevation beside a visible exterior elevator core. The suite connects to the landing through a collision-enabled bridge; press R to return to the street.
- Tower shells have walkable floor plates, a central stair opening with alternating stair treads, and an elevator-side access gap on each floor. Glass elevator cabs have physical floors and a G-key floor selector. The host validates floor requests and broadcasts lift travel to clients.
- Contracts bill every 30 real-world days. The host persists contracts and wallets to user://neon_abyss_rentals.json and synchronizes the ledger to connected clients.
- The creator remains visually absent in solo mode. Visible person avatars exist only during multiplayer, and residents are hidden from other players while using their private apartment instance.
- District streaming now considers all connected player presences so the host can generate rental buildings around remote residents.

## Civic employment prototype
- Press **T** near a tower lobby to open the civic job board. Roles include district maintenance, express courier, and network technician.
- Start one shift at a time. The host validates the request at the lobby and awards wages every 60 seconds while the session is active; wages go into the same credit wallet used for rent.
- Shift progress is session-bound and currently resets on clock-out or server restart. Jobs are player systems, not simulated NPC workers.

## Important limits
This is the housing prototype, not yet a persistent worldwide virtual world. The current host is an ENet session, rental data is stored on that host's local filesystem, and multiplayer identities are temporary peer IDs. A real public world still needs authenticated stable accounts, a dedicated always-on server, a production database with backups, server-authoritative economy/physics, moderation, abuse prevention, and load-tested hosting. Tower floors and compact stair flights are now generated as a hollow walkable shell, but they are procedural structural spaces, not detailed authored rooms. The furnished rental suite is still a separate instance beside the tower rather than a fully integrated unit carved into its floor plan. Elevator doors, stair rails, apartment customization/storage, pedestrians, interactive city services and multi-client rental tests remain open milestones.

## World systems roadmap
See [the phased living-world roadmap](docs/living-world-roadmap.md) for the plan covering housing, city services, physics, and worldwide persistence.
