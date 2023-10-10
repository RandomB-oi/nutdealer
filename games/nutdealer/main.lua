local module = {}

module.init = function()
	mainGame = game.new("NutDealer")
	nutDealerData = datastore:getDatastore("nutDealer")

	mainGame:setSceneOrder({"main-menu", "main-game", "dialog"})
	gameData = nil
	
	slotLoaded = signal.new()
	slotLoaded.debug = true

    local flagMaids = {}

    function mainGame:createFlag(name, f)
        if gameData.flags[name] then -- they done reached dat flag DONT DO IT
            return
        end

        local flagMaid = flagMaids[name]

        if not flagMaid then
            flagMaid = maid.new()
            flagMaids[name] = flagMaid
            flagMaid:giveTask(function()
                flagMaids[name] = nil
            end)
        end

        coroutine.wrap(function()f(flagMaid)end)()
    end

    function mainGame:reachFlag(name)
        gameData.flags[name] = true

        if flagMaids[name] then
            flagMaids[name]:destroy()
        end
    end

    function mainGame:clearFlags()
        for flag, flagMaid in pairs(flagMaids) do
            flagMaid:destroy()
        end
    end

	local loadedSave
    function mainGame:loadSave(saveName)
		loadedSave = saveName
		gameData = nutDealerData:getAsync("SAVE_"..saveName)
		gameData.flags = gameData.flags or {}

		local mainMenu = mainGame:getScene("main-menu")
		mainMenu:disable()
		mainMenu:pause()

		local mainGame = mainGame:getScene("main-game")
		mainGame:enable()
		mainGame:unpause()
		
		slotLoaded:fire(saveName, gameData)
    end
	
	function mainGame:saveSlot(closeSave)
		gameData.playerPosition = {
			x = mainCharacter.position.x,
			y = mainCharacter.position.y,
		}

		nutDealerData:setAsync("SAVE_"..loadedSave, gameData)
		if closeSave then
			gameData = nil
			mainGame:clearFlags()

			local mainMenu = mainGame:getScene("main-menu")
			mainMenu:enable()
			mainMenu:unpause()

			local mainGame = mainGame:getScene("main-game")
			mainGame:disable()
			mainGame:pause()
		end
	end
end

module.start = function()
	mainGame:setWindowSize(vector2.new(600, 400))
end

return module