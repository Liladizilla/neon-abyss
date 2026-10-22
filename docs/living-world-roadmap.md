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


## Six-task district identity and exterior frontage pass
- [x] Give each deterministic district a restrained palette identity while retaining full facade, window, roof-plant and structural detail.
- [x] Add instanced ground-floor glazing, sign bands, service doors and lit jambs to distinguish commercial and service frontage from blank tower bases.
- [x] Add small reclaimed-growth pockets at podium corners without filling the central lobby approach.
- [x] Add perpendicular arterial lane dashes using the same instanced mesh and consistent local spacing across streamed chunks.
- [x] Expand sparse deterministic skyline landmarks into transit halos, floodlight spires and damaged skybridge monuments.
- [ ] Graphically verify that storefront panels do not cover actual door openings, that district landmarks remain visible at distance, and that markings align across all chunk boundaries.
- [ ] Next: replace generic frontage strips with per-building use profiles (retail, housing lobby, maintenance, loading) and add collision only for real solid elements.

## Six-task building-use and street-continuity pass
- [x] Assign deterministic per-building ground-floor profiles for retail, residential lobby, maintenance, and loading frontage.
- [x] Keep retail glazing away from the central lobby axis and reserve the maintenance door for its own profile.
- [x] Add residential lobby framing and wayfinding accents without replacing the registered lobby terminal.
- [x] Add a segmented loading-shutter visual that reads as closed infrastructure rather than a walk-through opening.
- [x] Keep frontage details instanced and visual-only so they do not create extra physics bodies or pretend to be functional doors.
- [x] Preserve the existing detailed tower shell, floor openings, elevator bridges, and active-chunk collision path.
- [ ] In-engine verify each frontage profile against the real shell doorway, lift access and street props; confirm the lobby remains reachable.
- [ ] Verify sidewalks, ramps, lane markings and vegetation remain clear and visually continuous across neighboring chunks.
- [ ] Next: add profile-specific functional interactions only after actual doors, shutters and collision are wired to authoritative building access.

## Doorway-alignment and traversal-safety pass
- [x] Keep residential lobby glazing on side wings so the centered shell doorway remains visually open.
- [x] Move maintenance-door visuals onto the existing centered opening instead of depicting a side door over solid wall.
- [x] Center loading-shutter slats and guards on the existing opening; do not imply an unrelated opening in the facade.
- [x] Keep the frontage kit visual-only; the hollow tower shell remains the authority for collision.
- [ ] In-engine inspect all four frontage profiles at eye level and from the street approach.
- [ ] Confirm closed-looking decorative panels do not mislead players into assuming a working door; next implementation should connect actual access state to the rental/building interaction system.
- [ ] Walk from street to lobby, elevator landing, and apartment interior on multiple generated floors.
- [ ] Check that crosswalks, tactile pads, street furniture, and vegetation leave a continuous accessible route.


## Six-task elevated junction and station pass
- [x] Add a transfer plaza at each of the three elevated sky-lane heights, joining the two district axes.
- [x] Give each plaza collision geometry in collision-enabled chunks.
- [x] Add illuminated guardrails to the inter-deck stair flights.
- [x] Add repeatable elevated transit station shells beside the transfer plazas at all three heights.
- [x] Extend headless smoke checks to require the plazas, stairs, rails, and station shell MultiMeshes.
- [x] Keep the gameplay boundary explicit: station shells are not yet functional trains, and visual existence plus collision-shape presence do not prove comfortable traversal or seamless chunk-to-chunk routes.
- [ ] Next: add verified building-side access points, route continuity across chunk edges, and actual transit boarding/elevator behavior.

## Six-task connected vertical access pass
- [x] Add collision surfaces for elevated decks in collision-enabled chunks, matching the reusable deck transforms.
- [x] Add repeated stair treads between the 27 m, 49 m, and 73 m sky-lane levels.
- [x] Give stair treads collision shapes in active chunks so the inter-deck route has physical surfaces.
- [x] Refine the stair flight to a longer run with smaller tread spacing rather than a short, implausibly steep stack.
- [x] Extend the headless city smoke test to require deck, inter-deck stair, and street-to-deck ramp collision components.
- [x] Keep the elevated-access components documented as first-pass connections; graphical traversal and full junction continuity remain unverified.

## Six-task elevated access pass
- [x] Add a segmented inclined access ramp from street level toward the first elevated sky-lane.
- [x] Reuse instanced deck segments, guard rails, and structural supports rather than creating a unique mesh for each segment.
- [x] Align the ramp geometry to its incline direction for a coherent sloped surface.
- [x] Add collision shapes for ramp deck segments only in collision-enabled active chunks.
- [x] Keep ramp generation deterministic and chunk-local so streaming districts can repeat the same infrastructure recipe.
- [x] Document the current access route and its limits: the ramp reaches the first elevated level, but does not yet connect every stacked deck or building entrance.
- [ ] Validate ramp walkability and collision in a graphical session; headless parsing cannot prove a player can traverse the incline comfortably.

## Six-task stacked infrastructure pass
- [x] Add three repeatable elevated deck heights at 27, 49, and 73 metres in each streamed district.
- [x] Lay decks along both district axes so the vertical network is not limited to one direction.
- [x] Add reusable guard beams with neon emissive accents to give elevated routes a readable silhouette.
- [x] Add structural pylons at deterministic intervals to visually support each deck.
- [x] Add slim elevated utility conduits to suggest power and service routing above the street canyon.
- [x] Keep all new pieces in MultiMesh batches and reuse existing box geometry/material handling to limit draw-call growth.
- [ ] Check deck intersections, silhouettes, and frame time in graphical play; these decks are currently visual infrastructure and do not yet provide walkable collision or route navigation.

## Six-task vertical abyss scale pass
- [x] Raise procedural tower height to 18–42 floors so each block holds substantially more rentable homes.
- [x] Increase facade window-grid frequency to every second floor for a denser inhabited-window rhythm.
- [x] Stack sky-lane bridges at 48%, 72%, and 90% of each eligible tower pair's shared height.
- [x] Apply the same stacked connections across both district axes to avoid a one-direction-only skyline.
- [x] Reuse the existing bridge and neon-trim meshes so the added skyline layers do not require unique assets per bridge.
- [ ] Validate skyline silhouettes and frame time in a graphical session; the taller towers and denser windows add rendering work.
- [ ] Next: add varied intermediate podiums, occupied mid-level infrastructure, and a true distant vertical city backdrop without spawning ambient NPCs.

## Six-task registered building-use pass
- [x] Derive one deterministic use-profile key for each generated building: retail, residential lobby, maintenance, or loading.
- [x] Store the profile in the authoritative local building registry alongside footprint, floor height and lift coordinates.
- [x] Preserve the four-unit-per-floor rental model for every building regardless of its ground-floor frontage.
- [x] Display the registered ground-floor use in the housing exchange so the visual profile and building record can be compared during playtests.
- [x] Keep the profile argument backward-compatible for any other registration callers by providing a residential-lobby default.
- [ ] Validate the registry label against generated frontages and rental kiosk positions in a graphical Godot session.
- [ ] Follow-up: wire actual entrance access states to doors and collision; these profile labels are metadata, not functional locks or shutters.
