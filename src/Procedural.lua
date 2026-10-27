--!nonstrict
-- Small procedural-generation demonstrations for Luau environments.

local Procedural = {}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function fade(t: number): number
	return t * t * t * (t * (t * 6 - 15) + 10)
end

local function gradient(hash: number, x: number, y: number): number
	local direction = bit32.band(hash, 3)
	if direction == 0 then
		return x + y
	elseif direction == 1 then
		return -x + y
	elseif direction == 2 then
		return x - y
	end
	return -x - y
end

--- Seeded 2D Perlin-style gradient noise.
function Procedural.perlin2D(x: number, y: number, seed: number?): number
	seed = seed or 0
	local x0 = math.floor(x)
	local y0 = math.floor(y)
	local xf = x - x0
	local yf = y - y0

	local function hash(xi: number, yi: number): number
		local n = bit32.band(xi * 374761393 + yi * 668265263 + seed * 1442695041, 0xFFFFFFFF)
		n = bit32.bxor(n, bit32.rshift(n, 13)) * 1274126177
		return bit32.band(n, 0xFFFFFFFF)
	end

	local top = lerp(
		gradient(hash(x0, y0), xf, yf),
		gradient(hash(x0 + 1, y0), xf - 1, yf),
		fade(xf)
	)
	local bottom = lerp(
		gradient(hash(x0, y0 + 1), xf, yf - 1),
		gradient(hash(x0 + 1, y0 + 1), xf - 1, yf - 1),
		fade(xf)
	)
	return lerp(top, bottom, fade(yf))
end

function Procedural.fbm2D(x: number, y: number, octaves: number?, persistence: number?, seed: number?): number
	octaves = octaves or 5
	persistence = persistence or 0.5
	local amplitude = 1
	local frequency = 1
	local total = 0
	local normalization = 0
	for octave = 1, octaves do
		total += Procedural.perlin2D(x * frequency, y * frequency, (seed or 0) + octave * 101) * amplitude
		normalization += amplitude
		amplitude *= persistence
		frequency *= 2
	end
	return total / math.max(normalization, 0.0001)
end

--- Generates a cave mask. 1 means floor, 0 means wall.
function Procedural.cellularCave(
	width: number,
	height: number,
	fillChance: number,
	steps: number,
	random: () -> number
): { { number } }
	local map = {}
	for y = 1, height do
		map[y] = {}
		for x = 1, width do
			map[y][x] = random() < fillChance and 1 or 0
		end
	end

	for _ = 1, steps do
		local nextMap = {}
		for y = 1, height do
			nextMap[y] = {}
			for x = 1, width do
				local walls = 0
				for ny = y - 1, y + 1 do
					for nx = x - 1, x + 1 do
						if nx ~= x or ny ~= y then
							if nx < 1 or ny < 1 or nx > width or ny > height or map[ny][nx] == 0 then
								walls += 1
							end
						end
					end
				end
				nextMap[y][x] = walls >= 5 and 0 or 1
			end
		end
		map = nextMap
	end

	for x = 1, width do
		map[1][x] = 0
		map[height][x] = 0
	end
	for y = 1, height do
		map[y][1] = 0
		map[y][width] = 0
	end
	return map
end

--- Places non-overlapping rooms and connects them with L-shaped corridors.
function Procedural.roomAndCorridor(
	width: number,
	height: number,
	roomAttempts: number,
	minRoomSize: number,
	maxRoomSize: number,
	integer: (minimum: number, maximum: number) -> number
): { map: { { number } }, rooms: { { x: number, y: number, width: number, height: number } } }
	assert(minRoomSize >= 3 and maxRoomSize >= minRoomSize, "invalid room sizes")
	local map = {}
	for y = 1, height do
		map[y] = {}
		for x = 1, width do
			map[y][x] = 0
		end
	end
	local rooms = {}

	for _ = 1, roomAttempts do
		local roomWidth = integer(minRoomSize, maxRoomSize)
		local roomHeight = integer(minRoomSize, maxRoomSize)
		local x = integer(2, width - roomWidth - 1)
		local y = integer(2, height - roomHeight - 1)
		local room = {
			x = x,
			y = y,
			width = roomWidth,
			height = roomHeight,
		}
		local overlaps = false
		for _, existing in rooms do
			if x < existing.x + existing.width + 1
				and x + roomWidth + 1 > existing.x
				and y < existing.y + existing.height + 1
				and y + roomHeight + 1 > existing.y
			then
				overlaps = true
				break
			end
		end
		if not overlaps then
			table.insert(rooms, room)
			for cy = y, y + roomHeight - 1 do
				for cx = x, x + roomWidth - 1 do
					map[cy][cx] = 1
				end
			end
		end
	end

	local function carve(x1: number, y1: number, x2: number, y2: number)
		for x = math.min(x1, x2), math.max(x1, x2) do
			map[y1][x] = 1
		end
		for y = math.min(y1, y2), math.max(y1, y2) do
			map[y][x2] = 1
		end
	end

	for index = 2, #rooms do
		local previous = rooms[index - 1]
		local current = rooms[index]
		carve(
			math.floor(previous.x + previous.width / 2),
			math.floor(previous.y + previous.height / 2),
			math.floor(current.x + current.width / 2),
			math.floor(current.y + current.height / 2)
		)
	end

	return {
		map = map,
		rooms = rooms,
	}
end

--- Weighted loot selection with a pity counter that raises non-rare odds.
function Procedural.lootRoll(
	loot: { { name: string, weight: number, rare: boolean? } },
	random: () -> number,
	pity: { rolls: number, threshold: number, multiplier: number }
)
	pity.rolls += 1
	local boosted = pity.rolls >= pity.threshold
	local total = 0
	local effectiveWeights = {}
	for index, item in loot do
		local weight = item.weight
		if boosted and not item.rare then
			weight *= pity.multiplier
		end
		effectiveWeights[index] = weight
		total += weight
	end

	local pick = random() * total
	for index, weight in effectiveWeights do
		pick -= weight
		if pick <= 0 then
			if loot[index].rare then
				pity.rolls = 0
			end
			return loot[index]
		end
	end

	local fallback = loot[#loot]
	if fallback.rare then
		pity.rolls = 0
	end
	return fallback
end

return Procedural
