--!nonstrict
-- Spatial queries and collision helpers with no Roblox-API dependency.

local Spatial = {}

export type AABB = {
	x: number,
	y: number,
	width: number,
	height: number,
}

export type Vec2 = {
	x: number,
	y: number,
}

function Spatial.aabbIntersects(a: AABB, b: AABB): boolean
	return a.x < b.x + b.width
		and a.x + a.width > b.x
		and a.y < b.y + b.height
		and a.y + a.height > b.y
end

function Spatial.pointInAABB(x: number, y: number, box: AABB): boolean
	return x >= box.x
		and x <= box.x + box.width
		and y >= box.y
		and y <= box.y + box.height
end

--- Slab-based segment/AABB intersection. Returns entry time or nil.
function Spatial.segmentAABB(start: Vec2, finish: Vec2, box: AABB): number?
	local dx = finish.x - start.x
	local dy = finish.y - start.y
	local tMin = 0
	local tMax = 1

	local function clip(origin: number, delta: number, low: number, high: number): boolean
		if math.abs(delta) < 1e-9 then
			return origin >= low and origin <= high
		end
		local t1 = (low - origin) / delta
		local t2 = (high - origin) / delta
		if t1 > t2 then
			t1, t2 = t2, t1
		end
		tMin = math.max(tMin, t1)
		tMax = math.min(tMax, t2)
		return tMin <= tMax
	end

	if not clip(start.x, dx, box.x, box.x + box.width) then
		return nil
	end
	if not clip(start.y, dy, box.y, box.y + box.height) then
		return nil
	end
	return tMin
end

function Spatial.aabbSweep(start: Vec2, finish: Vec2, halfSize: Vec2, obstacle: AABB): number?
	return Spatial.segmentAABB(start, finish, {
		x = obstacle.x - halfSize.x,
		y = obstacle.y - halfSize.y,
		width = obstacle.width + halfSize.x * 2,
		height = obstacle.height + halfSize.y * 2,
	})
end

local SpatialHash = {}
SpatialHash.__index = SpatialHash

--- Uniform-grid broad phase for fast overlap candidate generation.
function SpatialHash.new(cellSize: number)
	assert(cellSize > 0, "cell size must be positive")
	return setmetatable({
		cellSize = cellSize,
		cells = {},
		objects = {},
		stamps = {},
		stamp = 0,
	}, SpatialHash)
end

function SpatialHash:cellRange(box: AABB)
	return math.floor(box.x / self.cellSize),
		math.floor(box.y / self.cellSize),
		math.floor((box.x + box.width) / self.cellSize),
		math.floor((box.y + box.height) / self.cellSize)
end

function SpatialHash:insert(id: any, box: AABB)
	self:remove(id)
	self.objects[id] = box
	local minX, minY, maxX, maxY = self:cellRange(box)
	for cellY = minY, maxY do
		for cellX = minX, maxX do
			local cellKey = string.format("%d,%d", cellX, cellY)
			local cell = self.cells[cellKey]
			if not cell then
				cell = {}
				self.cells[cellKey] = cell
			end
			cell[id] = true
		end
	end
end

function SpatialHash:remove(id: any)
	local box = self.objects[id]
	if not box then
		return
	end
	local minX, minY, maxX, maxY = self:cellRange(box)
	for cellY = minY, maxY do
		for cellX = minX, maxX do
			local cellKey = string.format("%d,%d", cellX, cellY)
			local cell = self.cells[cellKey]
			if cell then
				cell[id] = nil
			end
		end
	end
	self.objects[id] = nil
end

function SpatialHash:query(box: AABB): { any }
	self.stamp += 1
	local stamp = self.stamp
	local result = {}
	local minX, minY, maxX, maxY = self:cellRange(box)
	for cellY = minY, maxY do
		for cellX = minX, maxX do
			local cellKey = string.format("%d,%d", cellX, cellY)
			for id in self.cells[cellKey] or {} do
				if self.stamps[id] ~= stamp then
					self.stamps[id] = stamp
					if Spatial.aabbIntersects(box, self.objects[id]) then
						table.insert(result, id)
					end
				end
			end
		end
	end
	return result
end

local Quadtree = {}
Quadtree.__index = Quadtree

function Quadtree.new(bounds: AABB, capacity: number?, depth: number?)
	return setmetatable({
		bounds = bounds,
		capacity = capacity or 8,
		depth = depth or 0,
		maxDepth = 8,
		items = {},
		children = nil,
	}, Quadtree)
end

function Quadtree:subdivide()
	local b = self.bounds
	local halfWidth = b.width / 2
	local halfHeight = b.height / 2
	local nextDepth = self.depth + 1
	self.children = {
		Quadtree.new({ x = b.x, y = b.y, width = halfWidth, height = halfHeight }, self.capacity, nextDepth),
		Quadtree.new({ x = b.x + halfWidth, y = b.y, width = halfWidth, height = halfHeight }, self.capacity, nextDepth),
		Quadtree.new({ x = b.x, y = b.y + halfHeight, width = halfWidth, height = halfHeight }, self.capacity, nextDepth),
		Quadtree.new({
			x = b.x + halfWidth,
			y = b.y + halfHeight,
			width = halfWidth,
			height = halfHeight,
		}, self.capacity, nextDepth),
	}
end

function Quadtree:childFor(box: AABB)
	if not self.children then
		return nil
	end
	for _, child in self.children do
		if Spatial.aabbIntersects(box, child.bounds) then
			local inside = box.x >= child.bounds.x
				and box.y >= child.bounds.y
				and box.x + box.width <= child.bounds.x + child.bounds.width
				and box.y + box.height <= child.bounds.y + child.bounds.height
			if inside then
				return child
			end
		end
	end
	return nil
end

function Quadtree:insert(item: { id: any, bounds: AABB })
	if not Spatial.aabbIntersects(item.bounds, self.bounds) then
		return false
	end
	if not self.children and self.depth < self.maxDepth and #self.items >= self.capacity then
		self:subdivide()
		for _, existing in self.items do
			local child = self:childFor(existing.bounds)
			if child then
				table.insert(child.items, existing)
			end
		end
		local crossBoundary = {}
		for _, existing in self.items do
			if not self:childFor(existing.bounds) then
				table.insert(crossBoundary, existing)
			end
		end
		self.items = crossBoundary
	end

	local child = self:childFor(item.bounds)
	if child then
		return child:insert(item)
	end
	table.insert(self.items, item)
	return true
end

function Quadtree:query(bounds: AABB): { { id: any, bounds: AABB } }
	local result = {}
	if not Spatial.aabbIntersects(bounds, self.bounds) then
		return result
	end
	for _, item in self.items do
		if Spatial.aabbIntersects(bounds, item.bounds) then
			table.insert(result, item)
		end
	end
	if self.children then
		for _, child in self.children do
			for _, item in child:query(bounds) do
				table.insert(result, item)
			end
		end
	end
	return result
end

Spatial.SpatialHash = SpatialHash
Spatial.Quadtree = Quadtree

return Spatial
