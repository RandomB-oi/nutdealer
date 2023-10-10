local module = {}

local scene
module.init = function()
	scene = mainGame:getScene("main-menu")
	scene:unpause()
	scene:enable()

    local mainMenu = instance.new("gui", scene)
    mainMenu.position = udim2.fromScale(0.5, 0.5)
    mainMenu.size = udim2.new(0.5, -12, 1, -12)
    mainMenu.anchorPoint = vector2.new(0.5, 0.5)
    mainMenu.color = color.new(1,1,1,0.5)

    function module.askSaveFile()
        local dialog = mainGame:getScene("dialog")

        local savedNames = nutDealerData:getAsync("saveFileNames") or {}
        local lastSlotIsCreate
        if #savedNames < 6 then
            lastSlotIsCreate = true
            table.insert(savedNames, "+ Create New")
        end

        dialog.doDialog("Select a save file")
        local response = dialog.askQuestion(savedNames)
        local name = savedNames[response]

        if response == #savedNames and lastSlotIsCreate then
            -- ask them for a name
            name = "Save File "..tostring(response)

            savedNames[response] = name
            nutDealerData:setAsync("saveFileNames", savedNames)

            return module.askSaveFile()
        end
        
        if not nutDealerData:getAsync("SAVE_"..name) then
            nutDealerData:setAsync("SAVE_"..name, {})
        end

        return savedNames[response]
    end
end

module.start = function()
    local saveFileName = module.askSaveFile()
    mainGame:loadSave(saveFileName)
end

return module