local MenuSignals = {}
MenuSignals.__index = MenuSignals

local sharedSignals = nil

function MenuSignals.new()
	local self = setmetatable({}, MenuSignals)
	self._events = {}
	return self
end

function MenuSignals:_getEvent(eventName)
	local event = self._events[eventName]
	if event then
		return event
	end

	local created = Instance.new("BindableEvent")
	self._events[eventName] = created
	return created
end

function MenuSignals:Connect(eventName, handler)
	local event = self:_getEvent(eventName)
	return event.Event:Connect(handler)
end

function MenuSignals:Fire(eventName, payload)
	local event = self._events[eventName]
	if event then
		event:Fire(payload)
	end
end

function MenuSignals:Destroy()
	for eventName, event in pairs(self._events) do
		event:Destroy()
		self._events[eventName] = nil
	end
end

function MenuSignals.getShared()
	if not sharedSignals then
		sharedSignals = MenuSignals.new()
	end
	return sharedSignals
end

return MenuSignals
