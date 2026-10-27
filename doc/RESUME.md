# Luau Systems Developer

## Technical Resume

Remote gameplay systems developer focused on Luau, algorithms, navigation, game AI, spatial queries, server authority, and procedural generation.

## Core capabilities

- Luau systems design with modular, testable APIs
- shortest-path search, flow fields, path smoothing, and line-of-sight checks
- state machines, behavior trees, utility AI, blackboard data flow, and GOAP
- AABB tests, segment and swept casts, spatial hashing, and quadtree broad phase
- server-side movement validation, input sequencing, prediction reconciliation, and rate limiting
- deterministic PRNG, noise, cellular generation, room layouts, and weighted loot
- Git-based delivery, static analysis, deterministic tests, and GitHub Actions

## Representative work

### Pathfinding and flow fields

Implemented A*, Dijkstra, BFS, DFS, greedy best-first, Theta*, BFS flow fields, path smoothing, and grid line of sight. Verified shortest-path behavior against a maze fixture.

- Source: `src/Pathfinding.lua`
- Evidence: shortest-path comparison tests and a 128 by 128 benchmark

### AI decision systems

Implemented guarded finite state machines, observable blackboards, behavior-tree sequences and selectors, utility action selection, and goal-oriented planning.

- Source: `src/AI.lua`
- Evidence: state transition, behavior-tree, utility, and planner assertions

### Spatial broad phase and collision helpers

Implemented a spatial hash, quadtree, AABB overlap, segment/AABB cast, and swept-AABB tests.

- Source: `src/Spatial.lua`
- Evidence: overlap, candidate filtering, removal, and traversal assertions

### Server-authoritative movement

Implemented distance-over-time movement validation, sequence-numbered input buffering, prediction reconciliation, and token-bucket rate limiting.

- Source: `src/Gameplay.lua`
- Evidence: speed-limit rejection, replay rejection, reconciliation, and rate-limit assertions

### Procedural systems

Implemented a deterministic PRNG, Perlin-style noise, fBm, cellular caves, room-and-corridor layouts, and pity-aware weighted loot.

- Source: `src/Procedural.lua`
- Evidence: deterministic PRNG, dungeon, noise, and loot assertions

## Algorithm coverage

### Implemented and tested

- A*, Dijkstra, BFS, DFS, greedy best-first, Theta*
- flow field, path smoothing, grid line of sight
- finite state machine, behavior tree, utility AI, GOAP, blackboard
- spatial hash, quadtree, AABB, segment cast, swept AABB
- server validation, input sequencing, reconciliation, token bucket
- PID, damped spring, deterministic PRNG, weighted choice
- Perlin/fBm, cellular caves, room generation, pity loot

### Ready for scoped implementation

- JPS, HPA*, hierarchical navigation
- minimax, alpha-beta pruning, MCTS, Q-learning, HTN
- perception systems, influence maps, steering, pursuit and evasion
- BVH, octree, k-d tree, SAT, GJK integration
- Simplex/Worley noise, Voronoi, WFC, BSP, L-systems
- snapshot interpolation, lag compensation, dead reckoning
- Elo, Glicko-2, matching, flow, and optimization algorithms

## Verified results

- 47 runtime assertions passing
- Luau 0.744 static analysis clean
- A* benchmark: 100 runs on a 128 by 128 grid in about 0.22 seconds
- GitHub Actions verification and Pages deployment successful

The benchmark is a workstation result and is not a Roblox server performance guarantee.

## Availability

- Remote contract work
- scoped first milestone
- fixed-price milestone or ongoing hourly work after scope review
- contact through GitHub or the recruiting server
