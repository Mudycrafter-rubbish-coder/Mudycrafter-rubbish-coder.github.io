# Discord Application Copy

These are drafts for Roblox development hiring channels. Read each server's pinned rules first. Post once in the correct channel and do not mass-DM members.

## Short introduction

> Hi, I'm a Luau systems developer focused on gameplay architecture, pathfinding, and server-authoritative mechanics. I have a tested Luau technical resume covering A*, Dijkstra, BFS/DFS, Theta*, FSM, behavior trees, GOAP, spatial hashing, movement validation, prediction reconciliation, and procedural generation.  
> Code and test evidence: `{{PORTFOLIO_URL}}`  
> Available for scoped paid work. I can start with a small milestone so the fit is easy to verify.

## Reply to a job post

> Hi, I can help with this.  
> Relevant fit: Luau gameplay systems, pathfinding/navigation, AI state or behavior trees, spatial queries, server-side movement validation, and client prediction/reconciliation.  
> Portfolio: `{{PORTFOLIO_URL}}`  
> To quote accurately, could you share: (1) the core gameplay loop, (2) whether the work is server, client, or both, (3) the current codebase or prototype, and (4) the deadline? I can propose a small first milestone with a fixed scope.

## Technical screening answer

> I use Luau as the implementation language, but the important part is the system boundary. For movement, I keep the server authoritative, validate distance over time with tolerances, sequence client inputs, and reconcile only unacknowledged predictions. For AI, I separate perception, decision-making, and action execution so each can be tested independently. For pathfinding, I choose the representation and heuristic based on the map: A* for individual routes, flow fields for shared goals, and hierarchical methods when the navigation graph is large.

## When asked for a rate

Use the user's chosen rate. Do not invent one in this file.

Suggested structure:

- Small, clearly scoped module: fixed milestone price
- Larger feature with unknown integration: paid discovery milestone, then fixed quote
- Ongoing work: hourly rate with a weekly cap

## Screening questions

- What should the player see when the system fails or cannot find a path?
- Which Roblox services and existing frameworks are already in use?
- Is movement client-authoritative, partially replicated, or fully server-driven?
- What is the target concurrent player count and device tier?
- What counts as a successful first milestone?

## Accuracy rules

- Do not claim years of experience, shipped titles, team history, or testimonials unless they are true.
- Do not claim all 270 listed techniques are production expertise.
- Link runnable evidence instead of relying on adjective stacking.
- Answer provenance questions accurately if asked directly.
