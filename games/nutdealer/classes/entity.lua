local module = {}
module.__index = module

local shadowColor = color.new(0,0,0,0.5)

module.new = function(scene)
	local self = setmetatable({}, module)
	self.maid = maid.new()
	self.scene = scene

	self.position = vector2.new(0, 0)
	self.velocity = vector2.new(0, 0)
	self.size = vector2.new(100, 100)

	self.hasShadow = true
	self.facing = "n"
	self.faceDirection = vector2.new(0, -1)
	
	self.data = {}
	self.colliding = {}
	
	local directions = {
		n = vector2.new(0, -1),
		e = vector2.new(1, 0),
		s = vector2.new(0, 1),
		w = vector2.new(-1, 0),
	}
	self.maid.faceDirectionUpdater = self.scene.update:connect(function(dt)
		local newDir = directions[self.facing]
		if newDir then
			self.faceDirection = newDir
		else
			self.facing = "n"
		end
	end)

	local physicsFPS = 60
	self.maid.velocitySolver = self.scene.update:connect(function(dt)
		local smoothing = math.clamp(math.round(physicsFPS - (1/dt)), 1, physicsFPS)
		for i = 1, smoothing do
			self:solveVelocity(dt/smoothing)
		end
	end)

	self.maid.renderShadow = self.scene.draw:connect(function() 
		if self.hasShadow then
			self:renderShadow(true)
		end	
	end, 10)
	
	local mainColor = color.new(1,1,1,1)
	self.maid.draw = self.scene.draw:connect(function()
		local size = self.size
		local pos = self.position
		local cf = cframe.new(pos.x, pos.y)
		
		love.graphics.push()
		love.graphics.translate(cf.x+size.x/2, cf.y+size.y/2)
		love.graphics.rotate(cf.r)
		
		local color = (self.color or mainColor) --* self:getLightColor()
		color:apply()
		if self.image then
			love.graphics.cleanDrawImage(self.image, -size/2, size)
		else
			love.graphics.rectangle("fill", -size.x/2, -size.y/2, size.x, size.y)
		end

		local dirBlockPos = self.faceDirection * (size/2 + vector2.new(10, 10))
		love.graphics.circle("fill", dirBlockPos.x, dirBlockPos.y, 10)
		love.graphics.pop()
	end, 11)
	
	return self
end

function module:renderShadow(doTransform)
	local size = self.size
	if doTransform then
		local pos = self.position
		local cf = cframe.new(pos.x, pos.y)
		
		love.graphics.push()
		love.graphics.translate(cf.x+size.x/2, cf.y+size.y/2)
		love.graphics.rotate(cf.r)
	end
	local shadowSize = vector2.new(1, 0.3) * size.magnitude/2
	local shadowPos = size*vector2.new(0, 0.6)
	shadowColor:apply()
	love.graphics.ellipse("fill", shadowPos.x, shadowPos.y, shadowSize.x, shadowSize.y)
	if doTransform then
		love.graphics.pop()
	end
end

function module:solveVelocity(dt)
	local terminalVelocity = vector2.new(1000,1000)
	self.velocity.x = math.clamp(self.velocity.x, -terminalVelocity.x, terminalVelocity.x)
	self.velocity.y = math.clamp(self.velocity.y, -terminalVelocity.y, terminalVelocity.y)
	
	local pos = self.position:copy()
	local newPos = pos + self.velocity * dt

	local canXAxis = self:canFitPosition(vector2.new(newPos.x, pos.y))
	if canXAxis then
		pos.x = newPos.x
		self.position.x = pos.x
	else
		self.position.x = pos.x
		self.velocity.x = 0
	end
		
	local canYAxis = self:canFitPosition(vector2.new(pos.x, newPos.y))
	if canYAxis then
		pos.y = newPos.y
		self.position.y = pos.y
	else
		self.position.y = pos.y
		self.velocity.y = 0
	end
	
	-- self.position.x = math.round(self.position.x*100)/100
	-- self.position.y = math.round(self.position.y*100)/100
end

function module:isIntersecting(blockPosition, blockSize, playerPosition)
	local playerSize = self.size
	local playerCenter = (playerPosition or self.position) + playerSize/2
	
	local blockCenter = blockPosition + blockSize/2

	local posDiff = blockCenter - playerCenter
	local posDiffABS = vector2.new(math.abs(posDiff.x), math.abs(posDiff.y))
	
	local sizeRange = (playerSize + blockSize)/2
	
	return posDiffABS < sizeRange
end

function module:canFitPosition(position)
	for id, object in pairs(instance.getClass("box").all) do
		if self:isIntersecting(object.position, object.size, position) then
			if not self.colliding[object.id] then
				self.colliding[object.id] = true
				object.touched:fire(self)
			end
			if object.collidable then
				return false
			end
		else
			if self.colliding[object.id] then
				self.colliding[object.id] = nil
				object.touchEnded:fire(self)
			end
		end
	end
	return true
end	

function module:destroy()
	self.maid:destroy()
end

module.init = function()
	instance.addClass("entity", module)
end

return module