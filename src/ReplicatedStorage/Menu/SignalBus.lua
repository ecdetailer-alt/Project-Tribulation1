local SignalBus = {}
SignalBus.__index = SignalBus

local sharedBus

local function getEvent(self, eventName)
	local event = self._events[eventName]
	if event then
		return event
	end

	event = Instance.new("BindableEvent")
	event.Name = eventName
	self._events[eventName] = event
	return event
end

function SignalBus.new()
	local self = setmetatable({}, SignalBus)
	self._events = {}
	return self
end

function SignalBus:Connect(eventName, handler)
	return getEvent(self, eventName).Event:Connect(handler)
end

function SignalBus:Fire(eventName, payload)
	getEvent(self, eventName):Fire(payload)
end

function SignalBus:Destroy()
	for _, event in pairs(self._events) do
		event:Destroy()
	end
	table.clear(self._events)
end

function SignalBus.getShared()
	if not sharedBus then
		sharedBus = SignalBus.new()
	end

	return sharedBus
end

return SignalBus
