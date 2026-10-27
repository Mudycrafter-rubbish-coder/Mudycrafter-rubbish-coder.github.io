# Luau Systems Developer

## Positioning

I build Luau gameplay systems where movement, AI, spatial queries, and server authority have to work together.

My focus is not one-off visual scripting. I turn gameplay requirements into modules with explicit data flow, testable rules, and clear server-client boundaries.

## Core areas

### Pathfinding and world queries

- A*, Dijkstra, BFS, DFS, greedy best-first, and Theta*
- flow fields for shared destination movement
- path smoothing and line-of-sight checks
- spatial hashing and quadtree broad phase
- segment and swept-AABB collision helpers

### Game AI

- finite state machines and guarded transitions
- blackboards
- behavior trees
- utility-based decision making
- GOAP planning

### Server-authoritative gameplay

- movement speed validation
- sequence-numbered input buffers
- client-side prediction reconciliation
- token-bucket rate limiting
- deterministic random selection

### Procedural systems

- seeded PRNG
- Perlin noise and fBm
- cellular-automata caves
- room-and-corridor generation
- pity-aware weighted loot

## Featured build: Luau Systems Lab

A portable Luau repository with 47 passing runtime assertions and clean static analysis.

The code has no framework lock-in. Algorithms are separated from Roblox adapters, which makes the logic fast to test and straightforward to move into a live project.

### Deliverable quality

- deterministic tests for edge behavior
- explicit edge-case handling
- measured benchmarks without inflated performance claims
- modular APIs suitable for code review

## Selected evidence

| Check | Result |
| --- | --- |
| Runtime assertions | 47 passed |
| Static analysis | Clean with Luau 0.744 |
| A* benchmark | 100 runs, 128 x 128 grid, about 0.22 s |
| Search coverage | optimal, non-optimal, any-angle, and flow-field methods |
| AI coverage | state, behavior, utility, and planning approaches |

## Engagement model

1. Clarify the player-facing behavior and failure cases.
2. Define a small first milestone with a testable result.
3. Build the module and adapter inside the existing project structure.
4. Verify behavior, review performance, and document handoff.

## Contact

For a scoped project, send the gameplay requirement, current codebase context, deadline, and target platform. The portfolio link and code samples are available below.
