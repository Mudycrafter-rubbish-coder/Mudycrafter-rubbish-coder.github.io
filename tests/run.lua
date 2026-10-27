--!nonstrict
-- Run with: luau tests/run.lua

local Pathfinding = require("../src/Pathfinding")
local AI = require("../src/AI")
local Spatial = require("../src/Spatial")
local Gameplay = require("../src/Gameplay")
local Procedural = require("../src/Procedural")

local tests = 0

local function expect(condition: boolean, message: string)
	tests += 1
	if not condition then
		error("FAIL: " .. message, 2)
	end
end

local function equal(actual: any, expected: any, message: string)
	tests += 1
	if actual ~= expected then
		error(string.format("FAIL: %s\nexpected: %s\nactual: %s", message, tostring(expected), tostring(actual)), 2)
	end
end

local rows = {
	"S.........",
	".####.###.",
	"....#.....",
	".##.#.###.",
	"...#....G.",
	"...####...",
}
local grid = Pathfinding.Grid.fromRows(rows)
local start = { x = 1, y = 1 }
local goal = { x = 9, y = 5 }
local expectedCost = 12

local astarPath, expanded = Pathfinding.astar(grid, start, goal, { diagonal = false })
expect(
	#astarPath > 0 and #astarPath - 1 == expectedCost,
	"A* should find the shortest four-way path; got cost " .. tostring(#astarPath - 1)
)
expect(expanded > 0, "A* should expand nodes")
expect(astarPath[1].x == start.x and astarPath[1].y == start.y, "A* path should begin at start")
expect(astarPath[#astarPath].x == goal.x and astarPath[#astarPath].y == goal.y, "A* path should end at goal")

local diagonalPath = Pathfinding.astar(grid, start, goal, { diagonal = true })
expect(#diagonalPath > 0 and #diagonalPath <= #astarPath, "diagonal A* should not be longer than four-way A*")

local dijkstraPath = Pathfinding.dijkstra(grid, start, goal, { diagonal = false })
equal(#dijkstraPath - 1, #astarPath - 1, "Dijkstra and A* should agree on cost")

local bfsPath = Pathfinding.bfs(grid, start, goal, { diagonal = false })
equal(#bfsPath - 1, #astarPath - 1, "BFS should also find the shortest unweighted path")

local dfsPath = Pathfinding.dfs(grid, start, goal, { diagonal = false })
expect(#dfsPath > 0, "DFS should find a path")

local greedyPath = Pathfinding.greedy(grid, start, goal, { diagonal = false })
expect(#greedyPath > 0, "Greedy search should find a path")

local thetaPath = Pathfinding.theta_star(grid, start, goal, { diagonal = true })
expect(#thetaPath > 0, "Theta* should find a path")

local smoothed = Pathfinding.smooth(grid, astarPath)
expect(#smoothed <= #astarPath, "path smoothing should not add waypoints")

local field = Pathfinding.flowField(grid, goal)
expect(field[Pathfinding.key(start.x, start.y)] ~= nil, "flow field should reach the start")
expect(field[Pathfinding.key(start.x, start.y)] > 0, "flow field should grow away from goal")

local blackboard = AI.Blackboard.new({ ammo = 3 })
local observed = nil
local unsubscribe = blackboard:subscribe("ammo", function(value)
	observed = value
end)
blackboard:set("ammo", 2)
equal(observed, 2, "blackboard listener should observe updates")
unsubscribe()

local calls = {}
local fsm = AI.StateMachine.new("idle")
fsm:addState("idle", {
	update = function()
		table.insert(calls, "idle")
	end,
})
fsm:addState("attack", {
	enter = function()
		table.insert(calls, "attack-enter")
	end,
})
fsm:addTransition("idle", "attack", function(context)
	return context.enemyVisible
end)
fsm:update({ enemyVisible = false }, 0.016)
fsm:update({ enemyVisible = true }, 0.016)
equal(fsm.current, "attack", "FSM should follow a guarded transition")
equal(calls[2], "attack-enter", "FSM should invoke enter")

local tree = AI.BehaviorTree.sequence(
	AI.BehaviorTree.condition(function(state)
		return state:get("health") > 0
	end),
	AI.BehaviorTree.action(function()
		return AI.BehaviorTree.Status.Success
	end)
)
equal(tree:tick(AI.Blackboard.new({ health = 10 })), "success", "behavior tree sequence should succeed")

local utility = AI.UtilityAI.new()
utility:addAction("retreat", function(context)
	return 100 - context.health
end, function()
	return "retreat"
end)
utility:addAction("attack", function(context)
	return context.health
end, function()
	return "attack"
end)
local actionName = utility:choose({ health = 10 })
equal(actionName, "retreat", "utility AI should pick the highest score")

local plan = AI.planGOAPOptimal(
	{ hasWood = false, hasAxe = true, hasFire = false },
	{ hasFire = true },
	{
		{
			name = "collect-wood",
			preconditions = { hasAxe = true },
			effects = { hasWood = true },
		},
		{
			name = "light-fire",
			preconditions = { hasWood = true },
			effects = { hasFire = true },
		},
	}
)
expect(plan ~= nil and plan[1] == "collect-wood" and plan[2] == "light-fire", "GOAP should produce a valid plan")
equal(AI.planGOAP({ hasAxe = true }, { hasFire = true }, {
	{
		name = "collect-wood",
		preconditions = { hasAxe = true },
		effects = { hasWood = true },
	},
	{
		name = "light-fire",
		preconditions = { hasWood = true },
		effects = { hasFire = true },
	},
})[1], "collect-wood", "breadth-first GOAP should produce a valid plan")

local boxA = { x = 0, y = 0, width = 10, height = 10 }
local boxB = { x = 9, y = 9, width = 2, height = 2 }
expect(Spatial.aabbIntersects(boxA, boxB), "AABBs should intersect")
expect(Spatial.segmentAABB({ x = -5, y = 5 }, { x = 15, y = 5 }, boxA) ~= nil, "segment should hit AABB")
expect(Spatial.aabbSweep({ x = -5, y = 5 }, { x = 15, y = 5 }, { x = 1, y = 1 }, boxA) ~= nil, "swept AABB should hit")

local hash = Spatial.SpatialHash.new(10)
hash:insert("a", boxA)
hash:insert("b", { x = 50, y = 50, width = 2, height = 2 })
local hits = hash:query(boxB)
equal(#hits, 1, "spatial hash should return one overlapping object")
equal(hits[1], "a", "spatial hash should return the correct object")
hash:remove("a")
equal(#hash:query(boxB), 0, "spatial hash remove should work")

local quadtree = Spatial.Quadtree.new({ x = 0, y = 0, width = 100, height = 100 }, 2)
for index = 1, 20 do
	quadtree:insert({
		id = index,
		bounds = {
			x = (index % 10) * 9,
			y = math.floor(index / 10) * 25,
			width = 2,
			height = 2,
		},
	})
end
expect(#quadtree:query({ x = 0, y = 0, width = 100, height = 100 }) == 20, "quadtree should retain all items")

local bucket = Gameplay.newTokenBucket(3, 0.1, 3)
expect(bucket:consume(2, 1), "token bucket should allow a burst")
expect(bucket:consume(1, 1), "token bucket should allow remaining capacity")
expect(not bucket:consume(1, 1), "token bucket should reject over-limit requests")
expect(bucket:consume(1, 11), "token bucket should refill over time")

local validMove = Gameplay.validateMovement({ x = 0, y = 0, z = 0 }, { x = 10, y = 0, z = 0 }, 0.1, 100, 0)
expect(validMove, "valid movement should pass")
local invalidMove, reason = Gameplay.validateMovement({ x = 0, y = 0, z = 0 }, { x = 100, y = 0, z = 0 }, 0.1, 100, 0)
expect(not invalidMove and reason ~= nil, "speed-hack movement should fail")

local buffer = Gameplay.newInputBuffer()
expect(buffer:push(1, 1, { forward = true }), "input buffer should accept a new sequence")
expect(not buffer:push(1, 2, { forward = false }), "input buffer should reject replayed sequences")

local reconciler = Gameplay.newReconciler(function(state, input)
	return { x = state.x + input.dx, sequence = input.sequence }
end)
reconciler:record({ sequence = 1, dx = 1 })
reconciler:record({ sequence = 2, dx = 1 })
local reconciled = reconciler:reconcile({ x = 100, sequence = 0 }, 0)
equal(reconciled.x, 102, "reconciler should replay unacknowledged inputs")

local prngA = Gameplay.newPRNG(42)
local prngB = Gameplay.newPRNG(42)
equal(prngA:nextUInt32(), prngB:nextUInt32(), "seeded PRNGs should be deterministic")
expect(Gameplay.weightedChoice({ "common", "rare" }, { 0, 1 }, function()
	return 0.5
end) == "rare", "weighted choice should respect zero weights")

local springValue = Gameplay.springStep(0, 10, 0, 0.016, 1)
expect(springValue > 0 and springValue < 10, "spring should move toward target without overshooting immediately")
local pid = Gameplay.PID.new(1, 0, 0, -1, 1)
equal(pid:update(10, 0.1), 1, "PID output should clamp")

local cave = Procedural.cellularCave(32, 32, 0.45, 4, function()
	return 0.5
end)
equal(#cave, 32, "cellular cave should have the requested height")
equal(#cave[1], 32, "cellular cave should have the requested width")

local proceduralRandom = Gameplay.newPRNG(7)
local dungeon = Procedural.roomAndCorridor(48, 32, 20, 4, 8, function(minimum, maximum)
	return proceduralRandom:integer(minimum, maximum)
end)
expect(#dungeon.rooms >= 2, "dungeon generator should place rooms")
expect(#dungeon.rooms > 1 and #dungeon.rooms < 20, "dungeon generator should reject many overlaps")

local noise = Procedural.perlin2D(1.25, 4.75, 42)
expect(noise >= -1 and noise <= 1, "Perlin noise should stay in a normalized range")
local fbm = Procedural.fbm2D(1.25, 4.75, 4, 0.5, 42)
expect(fbm == fbm, "fBm should not produce NaN")

local pity = { rolls = 20, threshold = 10, multiplier = 3 }
local loot = Procedural.lootRoll({
	{ name = "common", weight = 90, rare = false },
	{ name = "rare", weight = 10, rare = true },
}, function()
	return 0.5
end, pity)
expect(loot.name ~= nil, "loot roll should return an item")

-- A small reproducible benchmark, not a claim about Roblox server performance.
local benchmarkGrid = Pathfinding.Grid.new(128, 128)
benchmarkGrid.blocked[64] = {}
for x = 1, 128 do
	benchmarkGrid.blocked[64][x] = x ~= 64
end
local benchmarkStart = os.clock()
local benchmarkExpanded = 0
for _ = 1, 100 do
	local _, count = Pathfinding.astar(benchmarkGrid, { x = 1, y = 1 }, { x = 128, y = 128 }, { diagonal = true })
	benchmarkExpanded += count
end
local benchmarkSeconds = os.clock() - benchmarkStart

print(string.format("PASS %d assertions", tests))
print(string.format("A* benchmark: 100 runs, %.3fs, %.0f nodes expanded", benchmarkSeconds, benchmarkExpanded))
