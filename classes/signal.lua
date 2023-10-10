local module = {}
module.__index = module
module.type = "signal"
	
module.new = function()
	return setmetatable({}, module)
end

function module:connect(callback, order)
	local connection = {
		order = order or 10,
		_callback = callback,
		disconnect = function(connection)
			table.remove(self, table.find(self, connection))
		end,
	}
	connection.Disconnect = connection.disconnect
	table.insert(self, connection)
	return connection
end

function module:once(callback)
	local connection connection = self:connect(function(...)
		connection:Disconnect()
			
		coroutine.wrap(callback)(...)
	end)
end

function module:wait()
	local thread = coroutine.running()
	self:once(function(...)
		coroutine.resume(thread, ...)
	end)
	return coroutine.yield()

	-- local returned
	-- self:once(function(...)
	-- 	returned = {...}
	-- end)
	-- while not returned do end
	-- return unpack(returned)
end

local unknownOrder = 25
local doOrderedSignals = true

function module:fire(...)
	if self.debug then
		regularPrint("test -1")
	end
	local args = {...}
	if self.debug then
		regularPrint("test -2")
	end
	if doOrderedSignals then
		local s,e = pcall(function()
			local orderedConnections = {}
			if self.debug then
				regularPrint("test 1")
			end
			for _, connection in pairs(self) do
				if type(connection) == "table" then
					local order = connection.order or unknownOrder
					if not orderedConnections[order] then
						orderedConnections[order] = {}
					end
					table.insert(orderedConnections[order], connection)
				end
			end
			if self.debug then
				regularPrint("test 2")
			end
			local orderList = {}
			for order in pairs(orderedConnections) do
				table.insert(orderList, order)
			end
			table.sort(orderList, function(a,b)
				return a < b
			end)
			-- for i = #orderList, 1, -1 do
			--	local v = orderList[i]
			for i,v in ipairs(orderList) do
				local list = orderedConnections[v]
				for connectionIndex, connection in ipairs(list) do
					coroutine.wrap(connection._callback)(unpack(args))
				end
			end
			if self.debug then
				regularPrint("test end")
			end
		end)
		if self.debug then
			regularPrint(e)
		end
	else
		for _, connection in pairs(self) do
			if type(connection) == "table" then
				coroutine.wrap(connection._callback)(...)
			end
		end
	end
end

function module:destroy()
	local index, task = next(self)
	while index and task ~= nil do
		task:disconnect()
		index, task = next(self)
	end
end

return module