--!nonstrict
-- Production-oriented gameplay utilities: input validation, prediction helpers,
-- deterministic randomness, smoothing, and token-bucket rate limiting.

local Gameplay = {}

local function clamp(value: number, low: number, high: number): number
	return math.max(low, math.min(high, value))
end

Gameplay.clamp = clamp

function Gameplay.lerp(a: number, b: number, t: number): number
	return a + (b - a) * clamp(t, 0, 1)
end

function Gameplay.smoothstep(t: number): number
	t = clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Gameplay.smootherstep(t: number): number
	t = clamp(t, 0, 1)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

--- Stable critically-damped spring approximation.
function Gameplay.springStep(current: number, target: number, velocity: number, dt: number, frequency: number)
	local omega = math.max(0.0001, frequency * 2 * math.pi)
	local x = omega * dt
	local exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	local change = current - target
	local temp = (velocity + omega * change) * dt
	local newVelocity = (velocity - omega * temp) * exp
	local newValue = target + (change + temp) * exp
	return newValue, newVelocity
end

local PID = {}
PID.__index = PID

function PID.new(kp: number, ki: number, kd: number, outputMin: number?, outputMax: number?)
	local instance = setmetatable({
		kp = kp,
		ki = ki,
		kd = kd,
		outputMin = outputMin or -math.huge,
		outputMax = outputMax or math.huge,
		integral = 0,
		previousError = nil,
	}, PID)
	return instance
end

function PID:update(error: number, dt: number): number
	assert(dt > 0, "dt must be positive")
	self.integral = clamp(self.integral + error * dt, self.outputMin, self.outputMax)
	local derivative = self.previousError and (error - self.previousError) / dt or 0
	self.previousError = error
	return clamp(self.kp * error + self.ki * self.integral + self.kd * derivative, self.outputMin, self.outputMax)
end

local TokenBucket = {}
TokenBucket.__index = TokenBucket

function Gameplay.newTokenBucket(capacity: number, refillPerSecond: number, initial: number?)
	assert(capacity > 0 and refillPerSecond >= 0, "invalid token-bucket settings")
	return setmetatable({
		capacity = capacity,
		refillPerSecond = refillPerSecond,
		tokens = initial or capacity,
		lastTime = 0,
	}, TokenBucket)
end

function TokenBucket:consume(count: number, now: number): boolean
	count = count or 1
	if now < self.lastTime then
		self.lastTime = now
	end
	local elapsed = now - self.lastTime
	self.tokens = math.min(self.capacity, self.tokens + elapsed * self.refillPerSecond)
	self.lastTime = now
	if self.tokens >= count then
		self.tokens -= count
		return true
	end
	return false
end

--- Strict server-side validation for a client-reported movement step.
function Gameplay.validateMovement(
	previousPosition: { x: number, y: number, z: number },
	nextPosition: { x: number, y: number, z: number },
	deltaTime: number,
	maxSpeed: number,
	tolerance: number?
): (boolean, string?)
	if deltaTime <= 0 or deltaTime > 2 then
		return false, "invalid-dt"
	end
	local dx = nextPosition.x - previousPosition.x
	local dy = nextPosition.y - previousPosition.y
	local dz = nextPosition.z - previousPosition.z
	local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
	local allowed = maxSpeed * deltaTime + math.max(0, tolerance or 0.5)
	if distance > allowed then
		return false, string.format("speed-limit: %.3f > %.3f", distance, allowed)
	end
	return true
end

local InputBuffer = {}
InputBuffer.__index = InputBuffer

function Gameplay.newInputBuffer(maxRows: number?)
	return setmetatable({
		rows = {},
		maxRows = maxRows or 60,
		lastSequence = 0,
	}, InputBuffer)
end

function InputBuffer:push(sequence: number, timestamp: number, state: any): boolean
	if sequence <= self.lastSequence then
		return false
	end
	self.lastSequence = sequence
	table.insert(self.rows, {
		sequence = sequence,
		timestamp = timestamp,
		state = state,
	})
	while #self.rows > self.maxRows do
		table.remove(self.rows, 1)
	end
	return true
end

function InputBuffer:consume(sequence: number)
	for index, row in self.rows do
		if row.sequence == sequence then
			table.remove(self.rows, index)
			return row.state
		end
	end
	return nil
end

local Reconciler = {}
Reconciler.__index = Reconciler

function Gameplay.newReconciler(replay: (state: any, input: any) -> any)
	return setmetatable({
		replay = replay,
		pendingInputs = {},
	}, Reconciler)
end

function Reconciler:record(input: any)
	table.insert(self.pendingInputs, input)
end

function Reconciler:reconcile(authoritativeState: any, acknowledgedSequence: number)
	local kept = {}
	local state = authoritativeState
	for _, input in self.pendingInputs do
		if input.sequence > acknowledgedSequence then
			table.insert(kept, input)
			state = self.replay(state, input)
		end
	end
	self.pendingInputs = kept
	return state
end

local PRNG = {}
PRNG.__index = PRNG

--- Small deterministic PRNG for procedural generation and reproducible tests.
function Gameplay.newPRNG(seed: number)
	assert(seed ~= 0, "seed must be non-zero")
	return setmetatable({
		state = bit32.band(seed, 0xFFFFFFFF),
	}, PRNG)
end

function PRNG:nextUInt32(): number
	local x = self.state
	x = bit32.band(bit32.bxor(x, bit32.lshift(x, 13)), 0xFFFFFFFF)
	x = bit32.bxor(x, bit32.rshift(x, 17))
	x = bit32.band(bit32.bxor(x, bit32.lshift(x, 5)), 0xFFFFFFFF)
	self.state = x
	return x
end

function PRNG:next(): number
	return self:nextUInt32() / 4294967296
end

function PRNG:range(minimum: number, maximum: number): number
	return minimum + (maximum - minimum) * self:next()
end

function PRNG:integer(minimum: number, maximum: number): number
	return math.floor(self:range(minimum, maximum + 1))
end

function Gameplay.weightedChoice(items: { any }, weights: { number }, random: () -> number)
	assert(#items == #weights and #items > 0, "items and weights must align")
	local total = 0
	for _, weight in weights do
		assert(weight >= 0, "weights must be non-negative")
		total += weight
	end
	if total <= 0 then
		return nil
	end
	local pick = random() * total
	for index, weight in weights do
		pick -= weight
		if pick <= 0 then
			return items[index]
		end
	end
	return items[#items]
end

Gameplay.PID = PID

return Gameplay
