--!nonstrict
-- Portable Luau pathfinding toolkit used by the portfolio test suite.

local Pathfinding = {}

local INF = math.huge

local function key(x: number, y: number): string
	return string.format("%d,%d", x, y)
end

local MinHeap = {}
MinHeap.__index = MinHeap

function MinHeap.new()
	return setmetatable({
		items = {},
		count = 0,
	}, MinHeap)
end

function MinHeap:push(value: any, priority: number)
	local index = self.count + 1
	self.count = index
	self.items[index] = {
		value = value,
		priority = priority,
	}

	while index > 1 do
		local parent = index // 2
		if self.items[parent].priority <= self.items[index].priority then
			break
		end
		self.items[parent], self.items[index] = self.items[index], self.items[parent]
		index = parent
	end
end

function MinHeap:pop()
	if self.count == 0 then
		return nil
	end

	local root = self.items[1]
	local last = self.items[self.count]
	self.items[self.count] = nil
	self.count -= 1

	if self.count > 0 then
		self.items[1] = last
		local index = 1
		while true do
			local left = index * 2
			local right = left + 1
			local smallest = index

			if left <= self.count and self.items[left].priority < self.items[smallest].priority then
				smallest = left
			end
			if right <= self.count and self.items[right].priority < self.items[smallest].priority then
				smallest = right
			end
			if smallest == index then
				break
			end

			self.items[index], self.items[smallest] = self.items[smallest], self.items[index]
			index = smallest
		end
	end

	return root.value, root.priority
end

function MinHeap:isEmpty(): boolean
	return self.count == 0
end

local Grid = {}
Grid.__index = Grid

function Grid.new(width: number, height: number, blocked: { { boolean } }?)
	assert(width > 0 and height > 0, "grid dimensions must be positive")
	local cells = blocked or {}
	return setmetatable({
		width = width,
		height = height,
		blocked = cells,
	}, Grid)
end

function Grid.fromRows(rows: { string })
	local height = #rows
	local width = height > 0 and #rows[1] or 0
	local blocked = {}
	for y = 1, height do
		assert(#rows[y] == width, "all map rows must have equal width")
		blocked[y] = {}
		for x = 1, width do
			blocked[y][x] = string.sub(rows[y], x, x) == "#"
		end
	end
	return Grid.new(width, height, blocked)
end

function Grid:inBounds(x: number, y: number): boolean
	return x >= 1 and y >= 1 and x <= self.width and y <= self.height
end

function Grid:isBlocked(x: number, y: number): boolean
	if not self:inBounds(x, y) then
		return true
	end
	local row = self.blocked[y]
	return row ~= nil and row[x] == true
end

local DIRECTIONS_4 = {
	{ x = 1, y = 0 },
	{ x = -1, y = 0 },
	{ x = 0, y = 1 },
	{ x = 0, y = -1 },
}

local DIRECTIONS_8 = {
	{ x = 1, y = 0 },
	{ x = -1, y = 0 },
	{ x = 0, y = 1 },
	{ x = 0, y = -1 },
	{ x = 1, y = 1 },
	{ x = -1, y = 1 },
	{ x = 1, y = -1 },
	{ x = -1, y = -1 },
}

function Grid:neighbors(node: { x: number, y: number }, options: { diagonal: boolean?, cornerCutting: boolean? }?)
	options = options or {}
	local diagonals = options.diagonal == true
	local cornerCutting = options.cornerCutting == true
	local directions = diagonals and DIRECTIONS_8 or DIRECTIONS_4
	local result = {}

	for _, direction in directions do
		local nx = node.x + direction.x
		local ny = node.y + direction.y
		if not self:isBlocked(nx, ny) then
			local isDiagonal = direction.x ~= 0 and direction.y ~= 0
			if not isDiagonal or cornerCutting
				or (not self:isBlocked(node.x + direction.x, node.y)
					and not self:isBlocked(node.x, node.y + direction.y))
			then
				table.insert(result, {
					x = nx,
					y = ny,
					cost = isDiagonal and math.sqrt(2) or 1,
				})
			end
		end
	end

	return result
end

local function heuristic(a: { x: number, y: number }, b: { x: number, y: number }, diagonal: boolean): number
	local dx = math.abs(a.x - b.x)
	local dy = math.abs(a.y - b.y)
	if diagonal then
		return (dx + dy) + (math.sqrt(2) - 2) * math.min(dx, dy)
	end
	return dx + dy
end

local function reconstruct(goalKey: string, parents: { [string]: any })
	local path = {}
	local currentKey: string? = goalKey

	while currentKey do
		local node = parents[currentKey]
		if not node then
			break
		end
		table.insert(path, 1, {
			x = node.x,
			y = node.y,
		})
		currentKey = node.parent
	end

	return path
end

local function prepare(grid: any, start: { x: number, y: number }, goal: { x: number, y: number })
	assert(grid:inBounds(start.x, start.y), "start is outside the grid")
	assert(grid:inBounds(goal.x, goal.y), "goal is outside the grid")
	assert(not grid:isBlocked(start.x, start.y), "start is blocked")
	assert(not grid:isBlocked(goal.x, goal.y), "goal is blocked")
	return key(start.x, start.y), key(goal.x, goal.y)
end

--- Finds a shortest path using A*.
function Pathfinding.astar(
	grid: any,
	start: { x: number, y: number },
	goal: { x: number, y: number },
	options: { diagonal: boolean?, cornerCutting: boolean? }?
): ({ { x: number, y: number } }, number)
	options = options or {}
	local startKey, goalKey = prepare(grid, start, goal)
	local open = MinHeap.new()
	local parents = {
		[startKey] = {
			x = start.x,
			y = start.y,
			parent = nil,
		},
	}
	local gScore = { [startKey] = 0 }
	local expanded = 0

	open:push(start, heuristic(start, goal, options.diagonal == true))

	while not open:isEmpty() do
		local current = open:pop()
		local currentKey = key(current.x, current.y)
		local currentG = gScore[currentKey] or INF
		expanded += 1

		if currentKey == goalKey then
			return reconstruct(goalKey, parents), expanded
		end

		for _, neighbor in grid:neighbors(current, options) do
			local neighborKey = key(neighbor.x, neighbor.y)
			local tentativeG = currentG + neighbor.cost
			if tentativeG < (gScore[neighborKey] or INF) then
				gScore[neighborKey] = tentativeG
				parents[neighborKey] = {
					x = neighbor.x,
					y = neighbor.y,
					parent = currentKey,
				}
				local f = tentativeG + heuristic(neighbor, goal, options.diagonal == true)
				open:push(neighbor, f)
			end
		end
	end

	return {}, expanded
end

--- Finds a shortest path for weighted grids. The grid currently uses unit costs.
function Pathfinding.dijkstra(
	grid: any,
	start: { x: number, y: number },
	goal: { x: number, y: number },
	options: { diagonal: boolean?, cornerCutting: boolean? }?
): ({ { x: number, y: number } }, number)
	options = options or {}
	local startKey, goalKey = prepare(grid, start, goal)
	local open = MinHeap.new()
	local parents = {
		[startKey] = {
			x = start.x,
			y = start.y,
			parent = nil,
		},
	}
	local distance = { [startKey] = 0 }
	local expanded = 0
	open:push(start, 0)

	while not open:isEmpty() do
		local current = open:pop()
		local currentKey = key(current.x, current.y)
		local currentDistance = distance[currentKey] or INF
		expanded += 1
		if currentKey == goalKey then
			return reconstruct(goalKey, parents), expanded
		end

		for _, neighbor in grid:neighbors(current, options) do
			local neighborKey = key(neighbor.x, neighbor.y)
			local candidate = currentDistance + neighbor.cost
			if candidate < (distance[neighborKey] or INF) then
				distance[neighborKey] = candidate
				parents[neighborKey] = {
					x = neighbor.x,
					y = neighbor.y,
					parent = currentKey,
				}
				open:push(neighbor, candidate)
			end
		end
	end

	return {}, expanded
end

--- Breadth-first search for unweighted grids.
function Pathfinding.bfs(
	grid: any,
	start: { x: number, y: number },
	goal: { x: number, y: number },
	options: { diagonal: boolean?, cornerCutting: boolean? }?
): ({ { x: number, y: number } }, number)
	options = options or {}
	local startKey, goalKey = prepare(grid, start, goal)
	local queue = { start }
	local head = 1
	local visited = { [startKey] = true }
	local parents = {
		[startKey] = {
			x = start.x,
			y = start.y,
			parent = nil,
		},
	}
	local expanded = 0

	while head <= #queue do
		local current = queue[head]
		head += 1
		expanded += 1
		local currentKey = key(current.x, current.y)

		if currentKey == goalKey then
			return reconstruct(goalKey, parents), expanded
		end

		for _, neighbor in grid:neighbors(current, options) do
			local neighborKey = key(neighbor.x, neighbor.y)
			if not visited[neighborKey] then
				visited[neighborKey] = true
				parents[neighborKey] = {
					x = neighbor.x,
					y = neighbor.y,
					parent = currentKey,
				}
				table.insert(queue, {
					x = neighbor.x,
					y = neighbor.y,
				})
			end
		end
	end

	return {}, expanded
end

--- Depth-first search. The result is complete, but not guaranteed shortest.
function Pathfinding.dfs(
	grid: any,
	start: { x: number, y: number },
	goal: { x: number, y: number },
	options: { diagonal: boolean?, cornerCutting: boolean? }?
): ({ { x: number, y: number } }, number)
	options = options or {}
	local startKey, goalKey = prepare(grid, start, goal)
	local stack = { start }
	local visited = {}
	local parents = {
		[startKey] = {
			x = start.x,
			y = start.y,
			parent = nil,
		},
	}
	local expanded = 0

	while #stack > 0 do
		local current = table.remove(stack)
		local currentKey = key(current.x, current.y)
		if not visited[currentKey] then
			visited[currentKey] = true
			expanded += 1

			if currentKey == goalKey then
				return reconstruct(goalKey, parents), expanded
			end

			for _, neighbor in grid:neighbors(current, options) do
				local neighborKey = key(neighbor.x, neighbor.y)
				if not visited[neighborKey] then
					parents[neighborKey] = {
						x = neighbor.x,
						y = neighbor.y,
						parent = currentKey,
					}
					table.insert(stack, {
						x = neighbor.x,
						y = neighbor.y,
					})
				end
			end
		end
	end

	return {}, expanded
end

--- Greedy best-first search. Fast, but the result is not guaranteed shortest.
function Pathfinding.greedy(
	grid: any,
	start: { x: number, y: number },
	goal: { x: number, y: number },
	options: { diagonal: boolean?, cornerCutting: boolean? }?
): ({ { x: number, y: number } }, number)
	options = options or {}
	local startKey, goalKey = prepare(grid, start, goal)
	local open = MinHeap.new()
	local visited = {}
	local parents = {
		[startKey] = {
			x = start.x,
			y = start.y,
			parent = nil,
		},
	}
	local expanded = 0
	open:push(start, heuristic(start, goal, options.diagonal == true))

	while not open:isEmpty() do
		local current = open:pop()
		local currentKey = key(current.x, current.y)
		if not visited[currentKey] then
			visited[currentKey] = true
			expanded += 1
			if currentKey == goalKey then
				return reconstruct(goalKey, parents), expanded
			end

			for _, neighbor in grid:neighbors(current, options) do
				local neighborKey = key(neighbor.x, neighbor.y)
				if not visited[neighborKey] then
					parents[neighborKey] = {
						x = neighbor.x,
						y = neighbor.y,
						parent = currentKey,
					}
					open:push(neighbor, heuristic(neighbor, goal, options.diagonal == true))
				end
			end
		end
	end

	return {}, expanded
end

--- Theta* improves A* paths by allowing any-angle shortcuts when visibility permits.
function Pathfinding.theta_star(
	grid: any,
	start: { x: number, y: number },
	goal: { x: number, y: number },
	options: { diagonal: boolean?, cornerCutting: boolean? }?
): ({ { x: number, y: number } }, number)
	options = options or {}
	local startKey, goalKey = prepare(grid, start, goal)
	local open = MinHeap.new()
	local gScore = { [startKey] = 0 }
	local parents = {
		[startKey] = {
			x = start.x,
			y = start.y,
			parent = nil,
		},
	}
	local closed = {}
	local expanded = 0
	open:push(start, heuristic(start, goal, options.diagonal == true))

	while not open:isEmpty() do
		local current = open:pop()
		local currentKey = key(current.x, current.y)
		if not closed[currentKey] then
			closed[currentKey] = true
			expanded += 1
			if currentKey == goalKey then
				return reconstruct(goalKey, parents), expanded
			end

			for _, neighbor in grid:neighbors(current, options) do
				local neighborKey = key(neighbor.x, neighbor.y)
				local parentKey = parents[currentKey].parent
				local selectedParent = currentKey
				local candidateG = (gScore[currentKey] or INF) + neighbor.cost

				if parentKey then
					local grandparent = parents[parentKey]
					if Pathfinding.gridLineOfSight(grid, grandparent, neighbor) then
						local directCost = heuristic(grandparent, neighbor, true)
						local viaGrandparent = (gScore[parentKey] or INF) + directCost
						if viaGrandparent < candidateG then
							candidateG = viaGrandparent
							selectedParent = parentKey
						end
					end
				end

				if candidateG < (gScore[neighborKey] or INF) then
					gScore[neighborKey] = candidateG
					parents[neighborKey] = {
						x = neighbor.x,
						y = neighbor.y,
						parent = selectedParent,
					}
					open:push(neighbor, candidateG + heuristic(neighbor, goal, options.diagonal == true))
				end
			end
		end
	end

	return {}, expanded
end

--- Connectivity test used by Theta*, path smoothing, and line-of-sight checks.
function Pathfinding.gridLineOfSight(
	grid: any,
	a: { x: number, y: number },
	b: { x: number, y: number }
): boolean
	local dx = b.x - a.x
	local dy = b.y - a.y
	local steps = math.max(math.abs(dx), math.abs(dy))
	if steps == 0 then
		return true
	end
	local prevX = a.x
	local prevY = a.y

	for step = 1, steps do
		local x = math.floor(a.x + dx * step / steps + 0.5)
		local y = math.floor(a.y + dy * step / steps + 0.5)
		if grid:isBlocked(x, y) then
			return false
		end
		if x ~= prevX and y ~= prevY and (grid:isBlocked(x, prevY) or grid:isBlocked(prevX, y)) then
			return false
		end
		prevX = x
		prevY = y
	end

	return true
end

--- Removes unnecessary waypoints from a path.
function Pathfinding.smooth(grid: any, path: { { x: number, y: number } })
	if #path <= 2 then
		return path
	end

	local result = { path[1] }
	local index = 1
	while index < #path do
		local farthest = index + 1
		for candidate = #path, index + 2, -1 do
			if Pathfinding.gridLineOfSight(grid, path[index], path[candidate]) then
				farthest = candidate
				break
			end
		end
		table.insert(result, path[farthest])
		index = farthest
	end
	return result
end

--- Builds a distance/flow field from a goal with BFS.
function Pathfinding.flowField(
	grid: any,
	goal: { x: number, y: number },
	options: { diagonal: boolean?, cornerCutting: boolean? }?
): { [string]: number }
	options = options or {}
	assert(not grid:isBlocked(goal.x, goal.y), "flow-field goal is blocked")
	local field = { [key(goal.x, goal.y)] = 0 }
	local queue = { goal }
	local head = 1

	while head <= #queue do
		local current = queue[head]
		head += 1
		local currentDistance = field[key(current.x, current.y)] or 0
		for _, neighbor in grid:neighbors(current, options) do
			local neighborKey = key(neighbor.x, neighbor.y)
			if field[neighborKey] == nil then
				field[neighborKey] = currentDistance + 1
				table.insert(queue, {
					x = neighbor.x,
					y = neighbor.y,
				})
			end
		end
	end

	return field
end

Pathfinding.MinHeap = MinHeap
Pathfinding.Grid = Grid
Pathfinding.key = key

return Pathfinding
