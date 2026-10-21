# Architecture

- game_root.gd composes lighting, player, world, UI and network lifecycle.
- city_streamer.gd queues deterministic chunks, limits generation per frame and evicts distant chunks.
- city_chunk.gd builds deterministic tower variants, facade windows, roof machinery, skybridges, street furniture, wet roads, a sparse transit-halo landmark and nearby collision.
- player_controller.gd provides movement, jumping, flight and throwable props.
- network_manager.gd handles ENet peers, remote avatar lifecycle and 20 Hz transform replication; it skips a duplicate avatar for the local peer and hides remote presence while a resident is in a private interior.
- UI scripts provide host/join menu and runtime telemetry.

Rendering uses filmic tonemapping, glow, distance fog, and a four-split directional moon light; the Compatibility renderer is selected for older integrated GPUs. MultiMesh facade instances reduce draw calls. Multiplayer needs multi-client playtesting before production readiness.


## Environment milestone
Street lamps, raised curbs and the transit-halo landmark are instanced or generated per chunk. The Compatibility renderer prioritizes broad hardware support; emissive signage and glow carry much of the neon look without relying on volumetric fog. Authored hero buildings, pedestrians, detailed vehicle meshes and multi-client playtests remain future milestones.


## Housing prototype limits
Housing records are persisted to the host process filesystem and replicated to currently connected peers. Peer IDs are not durable identities; a public-world release needs account-backed identities and a server database. Apartment interiors are isolated local instances and currently hide the resident avatar from other players while occupied. This avoids replicating a private interior as if it were part of the shared street map.
