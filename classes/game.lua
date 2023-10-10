local sceneClass = {}
sceneClass.__index = sceneClass
sceneClass.type = "scene"

sceneClass.new = function(game, name)
	local self = setmetatable({}, sceneClass)

	self.name = name
	self.game = game
	
	self.isPaused = false
	self.enabled = true
	
	self.update = signal.new()
	self.draw = signal.new()
	self.guiDraw = signal.new()

	self.guiInputBegan = signal.new()
	self.guiInputEnded = signal.new()
	self.inputBegan = signal.new()
	self.inputEnded = signal.new()
	
	self.maid = maid.new()

	self.maid:giveTask(self.update)
	self.maid:giveTask(self.draw)
	self.maid:giveTask(self.guiDraw)
	self.maid:giveTask(self.guiInputBegan)
	self.maid:giveTask(self.guiInputEnded)
	self.maid:giveTask(self.inputBegan)
	self.maid:giveTask(self.inputEnded)
	
	self.camera = instance.new("camera", self)
	self.maid:giveTask(self.camera)

	return self
end

function sceneClass:pause()
	self.isPaused = true
end
function sceneClass:unpause()
	self.isPaused = false
end
function sceneClass:enable()
	self.enabled = true
end
function sceneClass:disable()
	self.enabled = false
end

function sceneClass:destroy()
	self.maid:destroy()
end

local gameClass = {}
gameClass.__index = gameClass
gameClass.type = "game"

gameClass.new = function(gameName)
	local self = setmetatable({
		maid = maid.new(),
		name = gameName,
		scenes = {},
		sceneOrder = {},

		showFPS = true,
		speed = 1,
	}, gameClass)

	if self.name then
		love.window.setTitle(self.name)
	end

	local lastDeltaTime = 1/60
	self.maid:giveTask(mainUpdate:connect(function(dt)
		dt = dt * self.speed
		for i = 1, #self.sceneOrder do
			local scene = self.scenes[self.sceneOrder[i]]
			if scene and scene.enabled and not scene.isPaused then
				scene.update:fire(dt)
			end
		end
		lastDeltaTime = dt
	end))

	local goodFPS = color.from255(0, 255, 0)
	local okFPS = color.from255(255, 255, 0)
	local stinkyFPS = color.from255(255, 0, 0)
	self.maid:giveTask(mainDraw:connect(function()
		for i = 1, #self.sceneOrder do
			local scene = self.scenes[self.sceneOrder[i]]
			if scene and scene.enabled then
				love.graphics.push()
				love.graphics.translate(-scene.camera.position.x, -scene.camera.position.y)
				scene.draw:fire()
				love.graphics.pop()
			end
		end
		for i = 1, #self.sceneOrder do
			local scene = self.scenes[self.sceneOrder[i]]
			if scene and scene.enabled then
				scene.guiDraw:fire()
			end
		end
		if self.showFPS then
			local fps = math.floor(1/lastDeltaTime + 1)
			if fps < 15 then
				stinkyFPS:apply()
			elseif fps < 30 then
				okFPS:apply()
			else
				goodFPS:apply()
			end
			love.graphics.drawCustomText(tostring(fps), 20, 20, 1)
		end
	end))

	self.maid:giveTask(guiInputBegan:connect(function(...)
		for i = 1, #self.sceneOrder do
			local scene = self.scenes[self.sceneOrder[i]]
			if scene and scene.enabled and not scene.isPaused then
				scene.guiInputBegan:fire(...)
			end
		end
	end))
	self.maid:giveTask(guiInputEnded:connect(function(...)
		for i = 1, #self.sceneOrder do
			local scene = self.scenes[self.sceneOrder[i]]
			if scene and scene.enabled and not scene.isPaused then
				scene.guiInputEnded:fire(...)
			end
		end
	end))
	
	self.maid:giveTask(inputBegan:connect(function(...)
		for i = 1, #self.sceneOrder do
			local scene = self.scenes[self.sceneOrder[i]]
			if scene and scene.enabled and not scene.isPaused then
				scene.inputBegan:fire(...)
			end
		end
	end))
	self.maid:giveTask(inputEnded:connect(function(...)
		for i = 1, #self.sceneOrder do
			local scene = self.scenes[self.sceneOrder[i]]
			if scene and scene.enabled and not scene.isPaused then
				scene.inputEnded:fire(...)
			end
		end
	end))
	
	do
		local maxOutputMessages = 20
		local outputMessages = {}
		local outputSerial = 0

		local outputScene = self:getScene("_CONSOLEOUTPUT_")
		outputScene:disable()
		outputScene:unpause()
		local frame = instance.new("gui", outputScene)
		frame.size = udim2.new(1, -12, 1, -12)
		frame.position = udim2.fromScale(0.5, 0.5)
		frame.anchorPoint = vector2.new(0.5, 0.5)
		frame.color = color.from255(0, 0, 0, 100)

		local list = instance.new("gui", outputScene)
		list.parent = frame
		list.size = udim2.new(1, 0, 1, -25)
		list.position = udim2.fromScale(0.5, 1)
		list.anchorPoint = vector2.new(0.5, 1)
		list.color = color.from255(0, 0, 0, 0)

		local clearOutput = instance.new("gui", outputScene)
		clearOutput.parent = frame
		clearOutput.size = udim2.fromOffset(50, 25)
		clearOutput.position = udim2.fromScale(1, 0)
		clearOutput.anchorPoint = vector2.new(1, 0)
		clearOutput.color = color.from255(255, 0, 0)
		
		local clearTextLabel = instance.new("text", outputScene)
		clearTextLabel.parent = clearOutput
		clearTextLabel.size = udim2.new(1, -4, 1, -4)
		clearTextLabel.position = udim2.fromScale(0.5, 0.5)
		clearTextLabel.anchorPoint = vector2.new(0.5, 0.5)
		clearTextLabel:setText("Clear")

		local function resetOutput()
			outputSerial = 0
			for i,v in ipairs(outputMessages) do
				v:setText("")
			end
		end

		clearOutput.clicked:connect(resetOutput)

		for i = 1, maxOutputMessages do
			local newLabel = instance.new("text", outputScene)
			newLabel.parent = list
			newLabel.size = udim2.new(1, 0, 1/maxOutputMessages, 0)
			newLabel.position = udim2.fromScale(0.5, (i-1)/maxOutputMessages)
			newLabel.anchorPoint = vector2.new(0.5, 0)
			newLabel.xAlign = "left"
			newLabel:setText("")
			table.insert(outputMessages, newLabel)
		end
		resetOutput()

		self.maid:giveTask(inputBegan:connect(function(input)
			if input == "f9" or input == "f1" then
				outputScene.enabled = not outputScene.enabled
			end
		end))

		self.maid:giveTask(outputMessage:connect(function(outputType, ...)
			local textColor
			if outputType == "e" then
				textColor = color.from255(255, 25, 25)
			elseif outputType == "w" then
				textColor = color.from255(255, 170, 0)
			elseif outputType == "p" then
				textColor = color.from255(220, 220, 220)
			else
				textColor = color.from255(100, 100, 100)
			end
			outputSerial = outputSerial + 1
			if outputSerial > maxOutputMessages then
				resetOutput()
				outputSerial = 1
			end

			local newStr = table.concat({...}, " ")
			local messages = string.split(newStr, "\n")

			if #messages > 1 then
				for i,v in ipairs(messages) do
					outputMessage:fire(outputType, v)
				end
				return
			end
			
			local label = outputMessages[outputSerial]
			label:setText(newStr)
			label.color = textColor
		end))
	end

	return self
end

function gameClass:setWindowSize(size)
	love.window.setMode(size.x, size.y)
end

function gameClass:setSceneOrder(newOrder)
	self.customSceneOrder = true
	self.sceneOrder = newOrder

	if not table.find(newOrder, "_CONSOLEOUTPUT_") then
		table.insert(newOrder, "_CONSOLEOUTPUT_")
	end
end

function gameClass:getScene(sceneName)
	if self.scenes[sceneName] then
		return self.scenes[sceneName]
	end
	local newScene = sceneClass.new(self, sceneName)
	self.scenes[sceneName] = newScene
	if not self.customSceneOrder then
		table.insert(self.sceneOrder, sceneName)
	end
	return newScene
end

return gameClass