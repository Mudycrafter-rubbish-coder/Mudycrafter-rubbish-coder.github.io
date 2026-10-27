--!nonstrict
-- Compact, engine-agnostic AI building blocks for Luau gameplay code.

local AI = {}

local Blackboard = {}
Blackboard.__index = Blackboard

function Blackboard.new(initial: { [string]: any }?)
	return setmetatable({
		data = initial or {},
		listeners = {},
	}, Blackboard)
end

function Blackboard:get(key: string)
	return self.data[key]
end

function Blackboard:set(key: string, value: any)
	local oldValue = self.data[key]
	self.data[key] = value
	for _, listener in self.listeners[key] or {} do
		listener(value, oldValue, key)
	end
end

function Blackboard:subscribe(key: string, listener: (newValue: any, oldValue: any, key: string) -> ())
	local listeners = self.listeners[key]
	if not listeners then
		listeners = {}
		self.listeners[key] = listeners
	end
	table.insert(listeners, listener)
	return function()
		local index = table.find(listeners, listener)
		if index then
			table.remove(listeners, index)
		end
	end
end

local StateMachine = {}
StateMachine.__index = StateMachine

--- Finite state machine with guarded transitions.
function StateMachine.new(initialState: string)
	return setmetatable({
		current = initialState,
		states = {},
		transitions = {},
	}, StateMachine)
end

function StateMachine:addState(name: string, state: {
	enter: ((context: any) -> ())?,
	update: ((context: any, dt: number) -> ())?,
	exit: ((context: any) -> ())?,
})
	self.states[name] = state
end

function StateMachine:addTransition(from: string, to: string, guard: ((context: any) -> boolean)?)
	local list = self.transitions[from]
	if not list then
		list = {}
		self.transitions[from] = list
	end
	table.insert(list, {
		to = to,
		guard = guard,
	})
end

function StateMachine:transition(to: string, context: any)
	assert(self.states[to], "unknown state: " .. to)
	local oldState = self.states[self.current]
	if oldState and oldState.exit then
		oldState.exit(context)
	end
	self.current = to
	local newState = self.states[to]
	if newState and newState.enter then
		newState.enter(context)
	end
end

function StateMachine:update(context: any, dt: number)
	for _, transition in self.transitions[self.current] or {} do
		if not transition.guard or transition.guard(context) then
			self:transition(transition.to, context)
			break
		end
	end

	local state = self.states[self.current]
	if state and state.update then
		state.update(context, dt)
	end
end

local BehaviorTree = {}
BehaviorTree.__index = BehaviorTree

BehaviorTree.Status = {
	Success = "success",
	Failure = "failure",
	Running = "running",
}

local function evaluateChild(child: any, blackboard: any)
	if type(child) == "function" then
		return child(blackboard)
	end
	return child:tick(blackboard)
end

function BehaviorTree.sequence(...: any)
	local children = { ... }
	return {
		tick = function(_self: any, blackboard: any)
			for _, child in children do
				local result = evaluateChild(child, blackboard)
				if result ~= BehaviorTree.Status.Success then
					return result
				end
			end
			return BehaviorTree.Status.Success
		end,
	}
end

function BehaviorTree.selector(...: any)
	local children = { ... }
	return {
		tick = function(_self: any, blackboard: any)
			for _, child in children do
				local result = evaluateChild(child, blackboard)
				if result ~= BehaviorTree.Status.Failure then
					return result
				end
			end
			return BehaviorTree.Status.Failure
		end,
	}
end

function BehaviorTree.condition(predicate: (blackboard: any) -> boolean)
	return function(blackboard: any)
		return predicate(blackboard)
				and BehaviorTree.Status.Success
			or BehaviorTree.Status.Failure
	end
end

function BehaviorTree.action(
	fn: (blackboard: any, dt: number) -> string,
	lastRun: { value: number }?
)
	local state = lastRun or { value = 0 }
	return function(blackboard: any, dt: number)
		state.value += dt or 0
		return fn(blackboard, dt or 0)
	end
end

local UtilityAI = {}
UtilityAI.__index = UtilityAI

function UtilityAI.new()
	return setmetatable({
		actions = {},
	}, UtilityAI)
end

function UtilityAI:addAction(name: string, score: (context: any) -> number, run: (context: any) -> any)
	table.insert(self.actions, {
		name = name,
		score = score,
		run = run,
	})
end

function UtilityAI:choose(context: any)
	local best = nil
	local bestScore = -math.huge
	for _, action in self.actions do
		local score = action.score(context)
		if score > bestScore then
			bestScore = score
			best = action
		end
	end
	if best then
		return best.name, best.run(context), bestScore
	end
	return nil, nil, bestScore
end

local function conditionMet(value: any, expected: any): boolean
	if type(expected) == "function" then
		return expected(value) == true
	end
	return value == expected
end

local function stateMatches(state: { [string]: any }, required: { [string]: any }): boolean
	for key, expected in required do
		if not conditionMet(state[key], expected) then
			return false
		end
	end
	return true
end

local function applyEffects(state: { [string]: any }, effects: { [string]: any }): { [string]: any }
	local result = {}
	for key, value in state do
		result[key] = value
	end
	for key, value in effects do
		result[key] = type(value) == "function" and value(result[key]) or value
	end
	return result
end

--- Goal-oriented action planner. Returns a sequence of action names.
function AI.planGOAP(
	initialState: { [string]: any },
	goal: { [string]: any },
	actions: {
		{
			name: string,
			preconditions: { [string]: any },
			effects: { [string]: any },
			cost: number?,
		}
	},
	maxDepth: number?
): { string }?
	local queue = {
		{
			state = initialState,
			path = {},
			cost = 0,
		},
	}
	local depth = maxDepth or 12

	for index = 1, depth do
		local nextQueue = {}
		for _, planNode in queue do
			for _, action in actions do
				if stateMatches(planNode.state, action.preconditions) then
					local nextState = applyEffects(planNode.state, action.effects)
					local nextCost = planNode.cost + (action.cost or 1)
					local nextPath = table.clone(planNode.path)
					table.insert(nextPath, action.name)
					if stateMatches(nextState, goal) then
						return nextPath
					end
					table.insert(nextQueue, {
						state = nextState,
						path = nextPath,
						cost = nextCost,
					})
				end
			end
		end
		queue = nextQueue
		if #queue == 0 then
			break
		end
	end

	return nil
end

--- Finds the cheapest plan with Dijkstra-style expansion.
function AI.planGOAPOptimal(
	initialState: { [string]: any },
	goal: { [string]: any },
	actions: {
		{
			name: string,
			preconditions: { [string]: any },
			effects: { [string]: any },
			cost: number?,
		}
	}
): { string }?
	local bestForState = {}
	local queue = {
		{
			state = initialState,
			path = {},
			cost = 0,
		},
	}

	while #queue > 0 do
		table.sort(queue, function(a, b)
			return a.cost < b.cost
		end)
		local current = table.remove(queue, 1)
		if stateMatches(current.state, goal) then
			return current.path
		end

		local stateKeyParts = {}
		for key, value in current.state do
			table.insert(stateKeyParts, tostring(key) .. "=" .. tostring(value))
		end
		table.sort(stateKeyParts)
		local stateKey = table.concat(stateKeyParts, "|")
		if current.cost < (bestForState[stateKey] or math.huge) then
			bestForState[stateKey] = current.cost
			for _, action in actions do
				if stateMatches(current.state, action.preconditions) then
					local path = table.clone(current.path)
					table.insert(path, action.name)
					table.insert(queue, {
						state = applyEffects(current.state, action.effects),
						path = path,
						cost = current.cost + (action.cost or 1),
					})
				end
			end
		end
	end

	return nil
end

AI.Blackboard = Blackboard
AI.StateMachine = StateMachine
AI.BehaviorTree = BehaviorTree
AI.UtilityAI = UtilityAI

return AI
