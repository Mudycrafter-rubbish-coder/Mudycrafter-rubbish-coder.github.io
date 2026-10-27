# Luau Algorithm Capability Map

This map separates code that exists in this repository from techniques I can design and implement in a scoped project.

## Verified in this repository

These are implemented and covered by runtime tests.

### Pathfinding and navigation

- A* search
- Dijkstra's algorithm
- breadth-first search
- depth-first search
- greedy best-first search
- Theta*
- grid line-of-sight checks
- path smoothing
- flow-field generation
- binary min-heap priority queue

### AI architecture

- finite state machine
- guarded transitions
- blackboard with listeners
- behavior tree sequence and selector nodes
- utility AI
- goal-oriented action planning

### Spatial and collision

- AABB overlap
- point-in-AABB
- segment/AABB cast
- swept AABB
- uniform spatial hash
- quadtree broad phase

### Gameplay, network, and control

- server-side movement validation
- sequence-numbered input buffer
- client prediction reconciliation
- token-bucket rate limiting
- linear interpolation
- smoothstep and smootherstep
- damped spring
- PID controller
- deterministic PRNG
- weighted choice

### Procedural generation

- Perlin-style gradient noise
- fractal Brownian motion
- cellular-automata caves
- room-and-corridor generation
- pity-aware weighted loot

## Strong implementation range

These are areas where I can reason about the algorithm, build a tested Luau module, and integrate it with Roblox systems. They are not presented as existing commercial projects.

### Search, planning, and learning

- JPS and HPA* pathfinding
- hierarchical search on navigation graphs
- influence maps
- pursuit and evasion
- steering behavior composition
- MCTS and minimax with alpha-beta pruning
- Q-learning prototypes
- HTN planning

### Game AI and perception

- hierarchical state machines
- perception systems
- behavior-tree decorators and services
- goal selection and scheduling
- target scoring and threat evaluation

### Collision and physics support

- Roblox raycasts, sphere casts, and block casts
- swept collision checks
- 2D SAT
- broad-phase/narrow-phase separation
- BVH and uniform-grid partitioning
- object pooling for transient probes

### Motion and animation

- quaternion-aware rotation math
- slerp and catmull-rom interpolation
- spring and PID tuning
- projectile ballistics
- numerical integration
- inverse kinematics integration with Roblox constraints

### Procedural generation

- Simplex-style and Worley noise
- Voronoi regions
- Marching Squares
- Poisson-disk and blue-noise sampling
- WFC and BSP dungeon generation
- L-systems
- MST-based room connection

### Engine, data, and performance

- ECS-style storage
- object pools
- LOD and culling policies
- event-driven scheduling
- memoization, caching, and incremental updates
- priority queues, ring buffers, and double buffering
- quadtree, octree, k-d tree, and hash-table structures

### Network and anti-cheat fundamentals

- authoritative server state
- snapshot and entity interpolation
- delta and quantized state encoding
- dead reckoning
- lag-compensated hit validation
- remote validation and state invariants
- impossible-movement and replay rejection
- rate limits and backoff

### Game economy and optimization

- weighted tables and alias sampling
- Fisher-Yates shuffle
- reservoir sampling
- Elo, Glicko-2, and TrueSkill concepts
- dynamic programming
- Bellman-Ford and Floyd-Warshall
- flow and matching algorithms
- simulated annealing and genetic algorithms

## Use carefully or prototype first

For these areas I would first define a narrow acceptance test. I would not claim production-hardened expertise before the target project's constraints are known.

- production-grade 3D GJK/EPA collision
- robust computational geometry without a proven library
- large-scale rollback netcode
- deterministic lockstep for a full action game
- MMO-scale interest management
- production anomaly detection and trust scoring
- extended Kalman filters
- fluid or shallow-water simulation
- full WFC content pipelines with large tile sets
- automatic generation of complex, hand-authored-looking level art

## Operating rule

I do not hide an unknown algorithm behind vague language. I write down its assumptions, complexity, edge cases, and a testable acceptance criterion before shipping it.
