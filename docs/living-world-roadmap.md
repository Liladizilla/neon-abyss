# NEON ABYSS: living-world roadmap

The goal is a persistent, shared dystopian jungle-city where every resident can rent a home and participate in a functioning urban world. This roadmap separates implemented systems from future production work; listing a system here does not mean it already exists.

## Milestone A — shared city and transit (foundation)
- Deterministic streamed districts and shared player-centered streaming.
- Procedural tower profiles, roads, raised curbs, street lights, rooftop plant, skybridges and selected skyline landmarks.
- Rain, wet asphalt, fog, neon emission, pooled traffic and an animated elevated train.
- ENet host/join and remote player presence. Multi-client production reliability remains unverified.

## Milestone B — housing and tenancy (current)
- Every generated tower has four logical units per generated floor.
- Lobby rental kiosks, a housing exchange, credits, occupancy checks and one active lease per identity.
- Host-side rental validation and JSON ledger persistence, with contract synchronization to connected clients.
- Thirty-day real-time contracts and lease release.
- Reusable furnished apartment interiors with collision; the resident's street avatar is hidden while inside.
- Current limitation: peer IDs are temporary and the ledger lives on the host machine. This is not yet global account-based persistence.

## Milestone C — building interiors and access
- Replace private off-map interior instances with floor-accurate apartment layouts inside buildings.
- Working elevators, stairs, access control, doors, apartment customization, storage and furniture placement.
- Multiple unit sizes, accessible routes, fire exits, service rooms and building maintenance.

## Milestone D — complete city services
- Shops, markets, restaurants, cafes, bars, hotels and delivery services.
- Clinics, hospitals, pharmacies, fire stations, police/security services and emergency response.
- Schools, libraries, universities, public administration and community spaces.
- Offices, factories, construction sites, jobs, wages, crafting and player-owned businesses.
- Power generation and distribution, water supply, sewerage, waste collection, drainage, street maintenance and network connectivity.
- Parks, jungle overgrowth, gardens, wildlife, waterways, weather hazards and environmental recovery.
- Roads, intersections, traffic signals, parking, sidewalks, pedestrian crossings, rail stations, trains, buses, taxis and freight logistics.
- Public signage, maps, wayfinding, local news, events, communication, accessibility options and multilingual UI.

## Milestone E — believable physical simulation
- Collision and rigid-body interaction for relevant props, vehicles, doors and furniture.
- Vehicle handling, braking, tire grip, suspension, damage and repair.
- Pedestrian navigation and crowd simulation only after the game has an explicit population design; no ambient people are spawned by default.
- Material-aware footsteps, rain impacts, water accumulation, drainage and constrained destruction where it is safe and performant.
- Deterministic server-authoritative movement, interaction, economy and anti-cheat validation.

## Milestone F — persistent worldwide world
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
