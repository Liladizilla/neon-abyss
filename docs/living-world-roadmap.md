# NEON ABYSS: living-world roadmap

The goal is a persistent, shared dystopian jungle-city where every resident can rent a home and participate in a functioning urban world. This roadmap separates implemented systems from future production work; listing a system here does not mean it already exists.

## Milestone A — shared city and transit (foundation)
- Deterministic streamed districts and shared player-centered streaming.
- Procedural tower profiles, roads, raised curbs, street lights, rooftop plant, skybridges and selected skyline landmarks.
- Rain, wet asphalt, fog, neon emission, pooled traffic and an animated elevated train.
- ENet host/join and remote player presence. Multi-client production reliability remains unverified.

## Milestone B — housing and tenancy (implemented prototype)
- Every generated tower has four logical units per generated floor.
- Lobby rental kiosks, a housing exchange, credits, occupancy checks and one active lease per identity.
- Host-side rental validation and JSON ledger persistence, with contract synchronization to connected clients.
- Thirty-day real-time contracts and lease release.
- Reusable furnished apartment interiors with collision; the resident's street avatar is hidden while inside.
- Current limitation: peer IDs are temporary and the ledger lives on the host machine. This is not yet global account-based persistence.

## Milestone C — employment and the shared city economy (first slice)
- Civic job board at tower lobbies with maintenance, courier and network technician roles.
- Host-validated clock-in and clock-out, one active role per resident, and wages credited to the same wallet used for rent.
- Wages accrue in 60-second online intervals; partial intervals are not paid and shift progress is session-bound.
- Current limitation: this is a minimal employment loop, not full job simulation, player businesses, offline wages or a durable labor contract.

## Milestone D — building interiors and access (first vertical-access slice)
- Exterior elevator cores on generated towers, animated glass elevator cars, physical cab floors, and collision-enabled floor landings.
- G opens a floor selector near a lift shaft. Requests are checked by the host, then lift travel is broadcast to connected clients.
- Rented apartments are positioned at the selected tower-floor elevation beside the lift core, with a collision-enabled access bridge and a return route to the street.
- Tower shells now use split floor plates, exterior wall segments with elevator-side openings, a central stairwell void, and alternating collision-enabled stair treads between floors.
- Tower geometry and floor height are stored in the building registry so room entry is tied to a generated building and floor rather than an off-map void.
- Still outstanding: detailed room layouts and corridor doors, accessible routes, elevator door animation, fire exits, apartment integration into the tower floor plan, customization and storage. Stair traversal and elevator travel still need an actual in-engine playtest.

## Milestone E — complete city services
- Shops, markets, restaurants, cafes, bars, hotels and delivery services.
- Clinics, hospitals, pharmacies, fire stations, police/security services and emergency response.
- Schools, libraries, universities, public administration and community spaces.
- Offices, factories, construction sites, jobs, wages, crafting and player-owned businesses.
- Power generation and distribution, water supply, sewerage, waste collection, drainage, street maintenance and network connectivity.
- Parks, jungle overgrowth, gardens, wildlife, waterways, weather hazards and environmental recovery.
- Roads, intersections, traffic signals, parking, sidewalks, pedestrian crossings, rail stations, trains, buses, taxis and freight logistics.
- Public signage, maps, wayfinding, local news, events, communication, accessibility options and multilingual UI.

## Milestone F — believable physical simulation
- Collision and rigid-body interaction for relevant props, vehicles, doors and furniture.
- Vehicle handling, braking, tire grip, suspension, damage and repair.
- Pedestrian navigation and crowd simulation only after the game has an explicit population design; no ambient people are spawned by default.
- Material-aware footsteps, rain impacts, water accumulation, drainage and constrained destruction where it is safe and performant.
- Deterministic server-authoritative movement, interaction, economy and anti-cheat validation.

## Milestone G — persistent worldwide world
- Stable authenticated accounts, durable resident identities, account recovery and moderation tools.
- Dedicated always-on authoritative servers, a production database, backups, migration strategy and observability.
- Region/shard strategy, instance handoff, replication interest management, rate limits and abuse prevention.
- Load tests, reconnect recovery, crash recovery, privacy/security review and public beta operations.

## Non-negotiable design rules
- No ambient human NPCs in the early world. Visible people are actual connected players.
- Solo creator mode remains empty of visible people; multiplayer avatars appear when players connect.
- Housing, ownership, money and interactions must be server-authoritative before public release.
- Build within a measured performance budget for integrated graphics, then scale detail by distance and hardware.
- Do not claim a city service, physical simulation or worldwide persistence is finished until it is implemented and tested.


## Building access milestone: elevator landing readability
- [x] Add paired door panels and illuminated center seams at each generated elevator landing.
- [x] Add a floor-call display panel beside each landing door.
- [x] Animate cab door panels closed before lift travel and open after arrival.
- [ ] Animate landing doors with authoritative states synchronized to elevator arrival and departure.
- [ ] Connect each landing directly to a consistently sized corridor and apartment entrance.
- [ ] Validate first-person traversal and lift boarding in a graphical Godot session.


## Building access milestone: animated landings and protected bridges
- [x] Publish elevator departure and arrival signals, and reject new floor requests while the cab is moving.
- [x] Replace static landing door panels with individual sliding door pairs on every generated floor.
- [x] Synchronize landing-door closure on departure and opening only at the destination floor.
- [x] Add collision-enabled guardrails along both exposed sides of each elevator access bridge.
- [x] Preserve the per-floor call display and indicator details beside the animated doors.
- [x] Extend core-script parsing and CI structural checks for the landing controller, signals and bridge colliders.
- [ ] Connect each landing to a clearly traversable tower corridor and the apartment entrance.
- [ ] Validate first-person boarding, door clearance, stairs and return routes in a graphical Godot session.
