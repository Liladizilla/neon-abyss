# Architecture

- game_root.gd composes lighting, player, world, UI and network lifecycle.
- city_streamer.gd queues deterministic chunks, limits generation per frame and evicts distant chunks.
- city_chunk.gd builds district architecture, emissive facades, roads and nearby collision.
- player_controller.gd provides movement, jumping, flight and throwable props.
- network_manager.gd handles ENet peers, remote avatar lifecycle and 20 Hz transform replication.
- UI scripts provide host/join menu and runtime telemetry.

Rendering uses filmic tonemapping, glow, SSAO, SSIL, volumetric fog and a four-split directional moon light. MultiMesh facade instances reduce draw calls. Multiplayer needs multi-client playtesting before production readiness.
