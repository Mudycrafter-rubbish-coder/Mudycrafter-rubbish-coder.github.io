# Luau Systems Developer

Technical resume and tested Luau building blocks for Roblox gameplay systems:

- pathfinding and flow fields
- game AI architecture
- spatial queries and collision helpers
- server-authoritative movement validation
- deterministic procedural generation

The repository is intentionally engine-agnostic. The modules run under Lune for fast tests and use only APIs available to Luau code in Roblox. Roblox-specific adapters can be added without changing the core algorithms.

## Verified build

Last verified: 2026-10-27

- 47 assertions passing
- Luau 0.744 static analysis clean
- A* benchmark: 100 runs over a 128 by 128 grid in about 0.22 seconds, 57,500 nodes expanded

The benchmark is a workstation result from Lune, not a promise about Roblox server performance.

## Included systems

| Area | Implemented in this repository |
| --- | --- |
| Pathfinding | A*, Dijkstra, BFS, DFS, greedy best-first, Theta*, flow field, path smoothing, grid line of sight |
| AI | finite state machine, blackboard, behavior tree, utility AI, GOAP |
| Spatial | AABB overlap, segment/AABB cast, swept AABB, spatial hash, quadtree |
| Gameplay | token-bucket rate limit, movement validation, input sequencing, client reconciliation, spring, PID |
| Procedural | seeded PRNG, Perlin/fBm, cellular caves, rooms and corridors, pity-weighted loot |

## Run the tests

```powershell
.\scripts\test.ps1
```

The script downloads pinned Luau and Lune binaries into the temporary directory, verifies their SHA-256 hashes, runs static analysis, and executes the test suite.

## Project layout

```text
src/       Portable Luau modules
tests/     Runtime assertions and benchmark
doc/       Portfolio copy and capability notes
site/      Static portfolio page
scripts/   Reproducible test runner
```

See [doc/ALGORITHM_MAP.md](doc/ALGORITHM_MAP.md) for the exact capability boundary.
