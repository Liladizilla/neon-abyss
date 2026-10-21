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


## Building traversal milestone: continuous floor-to-lift access
- [x] Size each tower-to-elevator bridge from the actual floor footprint so upper-floor setbacks do not leave visual or physical gaps.
- [x] Extend collision-enabled guardrails across the complete bridge span, including deeper upper-level setbacks.
- [x] Add restrained illuminated corridor guide strips that lead toward the elevator opening without obstructing the walking path.
- [x] Mark the tower-side elevator opening with a consistent lit doorway frame on each floor.
- [x] Add readable floor-number labels beside each elevator landing display.
- [x] Extend CI structural assertions for setback-aware bridges, guide strips, doorway trim and floor labels.
- [ ] Verify traversal visually in first person across low and upper floors, including stair transitions and door clearance.
- [ ] Connect a rented unit's interior entrance directly to its matching floor landing instead of treating the interior as a separate scene transition.


## Accessible street crossing pass
- [x] Add reusable curb-ramp panels at the four arterial crossing approaches.
- [x] Add tactile paving pads to make crossing decision points visually legible.
- [x] Add physical collision shapes to the curb-ramp panels, matching each panel's placement and rotation.
- [ ] Test ramp slope and landing alignment against the player controller in a graphical session.
- [ ] Replace prototype panels with a shared crossing kit that aligns with all procedural road widths and stacked street elevations.


## Exterior fire-escape kit
- [x] Add reusable exterior landing, guardrail, post and stair-flight geometry to a deterministic subset of taller buildings.
- [x] Vary the landing direction by floor to suggest switchback circulation and break up repetitive tower silhouettes.
- [x] Replace prototype flight slabs with eight individual tread meshes per flight and matching collision shapes; add collision to landing platforms.
- [x] Add paired continuous sloped handrails with intermediate support posts along each stair flight.
- [x] Add collision to landing guardrails, guardrail posts, sloped handrails and handrail supports.
- [x] Add real front-wall doorway openings and illuminated jambs on fire-escape-enabled towers, aligned to centered exterior landings.
- [x] Add collision-enabled connector bridges where upper-floor setbacks leave a gap between fire-escape landings and the matching doorway.
- [x] Keep the tower-facing landing edge open and add collision-enabled safety rails along connector bridge sides.
- [ ] Validate façade clearance, landing overlap and traversal in a graphical first-person playtest.


## Six-task apartment and stair traversal pass
- [x] Raise stair treads so the top step meets the next floor plate instead of leaving a small vertical lip.
- [x] Add collision-enabled stair-foot landings that join the alternating flights to each storey.
- [x] Add rotated collision shapes for the sloped stair handrails.
- [x] Keep the apartment-to-lift bridge walkable, collision-enabled, and marked with low-profile guide strips.
- [x] Align rented-suite placement to the registered tower footprint and spawn residents just inside the actual entry doorway.
- [x] Add proximity-triggered sliding apartment doors with matching collision and CI checks for the traversal components.
- [ ] Graphically test the complete street → lift → floor landing → apartment → return route, including stair transitions and door clearance.


## Six-task apartment-to-lift alignment pass
- [x] Register each generated tower's actual lift center, upper-floor width and podium/setback height with the housing registry.
- [x] Compute the apartment threshold from the selected floor's real façade width instead of a fixed guessed offset.
- [x] Rotate the suite so its outward-facing entry and access bridge point toward the elevator landing.
- [x] Align the apartment floor surface vertically with the collision-enabled landing platform.
- [x] Size the bridge, side rails and guide strips to the actual gap between the floor façade and lift landing, including upper-floor setbacks.
- [x] Extend CI assertions for registered footprint data, façade placement, suite orientation and variable bridge geometry.
- [ ] Graphically walk the bridge from a rented unit into the matching lift landing on podium and recessed upper floors; headless tests cannot certify this route.


## Six-task elevator continuity pass
- [x] Track the current destination floor explicitly while the lift is travelling.
- [x] Send late-joining peers a snapshot of the authoritative cab height, movement state, destination and door state.
- [x] Resume an in-progress trip from the replicated cab position instead of leaving a late joiner with a stale idle lift.
- [x] Clamp received cab height to the configured shaft range before applying the snapshot.
- [x] Reject invalid replicated destinations before mutating local lift state.
- [x] Disable floor-selection buttons during travel, block same-floor trips, and add CI assertions for the elevator state guards.
- [ ] Test two clients joining at different points during a lift trip in a graphical multiplayer session.


## Six-task exterior city street pass
- [x] Add continuous raised sidewalk strips along both sides of the two crossing arterial streets in every streamed district chunk.
- [x] Give sidewalk slabs and curb runs physical collision instead of leaving the pedestrian edge as decoration.
- [x] Add repeated zebra-crossing stripes at the four approaches to the central junction.
- [x] Add reusable drain grates along the curb line to support the wet, rain-soaked street look.
- [x] Add corner bollards as visible protection between pedestrian approaches and vehicle lanes.
- [x] Add exposed utility conduits and CI assertions for the complete street-detail kit.
- [ ] Graphically verify sidewalk height, ramp transitions, bollard clearance and crossings at chunk boundaries in first person.

## First-person traversal and quality-preserving performance pass
- [x] Correct first-person forward/backward input-vector direction.
- [x] Process mouse motion before UI can consume the event.
- [x] Explicitly configure player, apartment wall/floor/furniture, and sliding-door collision layers and masks.
- [ ] Run graphical Godot traversal from both sides of every apartment wall and through the entry doorway.
- [x] Correct diagonal-neighbor chunk collision activation so visible buildings in all eight adjacent directions retain collision.
- [x] Rebuild nearby streamed chunks when their collision requirement changes, preventing previously visual-only chunks from staying non-solid after the player approaches.
- [x] Correct stair-foot landing placement so the collision landing is positioned relative to its tower rather than the district origin.
- [ ] Verify collision on tower shells, stair treads, elevator floors, bridge rails, sidewalks, curbs and streamed district boundaries.
- [ ] Capture baseline frame time, draw calls, object count, physics-body count and memory use on the target integrated GPU before tuning.
- [ ] Optimize measured hotspots with shared resources, instancing, bounded shadow casting and distance-aware detail; do not reduce close-range asset quality.
- [ ] Confirm streaming never leaves the player's active district without collision, and profile collision cost before expanding the physics radius.

### First-person collision and input follow-up

- Mouse pointer recaptures on a left click during active gameplay after ESC releases it; clicks consumed by visible UI controls remain UI interactions.
- Every hollow tower floor now has a real, narrow facade doorway built from side-wall and header segments with matching collision, instead of leaving the entire facade open on towers without a fire escape.
- Preserve render meshes and material detail. Continue to optimize physics separately by measuring shape count and frame time before consolidating collision primitives.
- Automated CI passed for commit `c5090a1`; the follow-up input and doorway commits still require a fresh CI run and in-engine graphical verification before the controls/collision fixes can be called complete.

### Quality-preserving physics optimization

- Fire escapes now keep detailed per-tread, per-landing, per-rail, and per-support box collision shapes under one shared StaticBody3D per escape instead of creating a separate physics body for every piece.
- Visual-only streamed chunks no longer create hidden sidewalk/curb collision bodies or fire-escape collision shapes; the active 3x3 collision neighborhood remains responsible for solid world geometry.
- Render meshes and individual collision shapes remain detailed; this reduces physics-body overhead without simplifying the visible city.
- Verify in Godot that stair treads, landings, bridges, rails, sidewalks, curbs, and doorway access still collide as intended. Measure physics-body count and frame time before/after on the same district.

## Street-level city life: reusable exterior props
- [x] Add instanced sidewalk planters with overgrowth, waste bins, benches, and utility cabinets at deterministic positions in each streamed district.
- [x] Reuse meshes and materials through MultiMesh batches so repeated small props do not create a separate render node each.
- [x] Group active-district prop collision under one StaticBody3D while keeping visual-only streamed chunks non-solid.
- [ ] Graphically verify prop placement against curb ramps, crossings, and building entrances; check that benches and cabinets do not obstruct accessible routes.
- [ ] Add varied street-front shopfronts, service entrances, and block-specific ground-floor uses without spawning ambient human NPCs.
