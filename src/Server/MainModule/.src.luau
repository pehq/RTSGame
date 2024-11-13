--Uses code from trek installer
local module = {}
shared.StrategisStatus = {}

local function install(folder1,folder2)
	for i,v in pairs(folder1:GetChildren()) do
		v.Parent = folder2
	end
end 

local function checkService(name)
	local service

	local s,f = pcall(function()
		service = game:GetService(name)
	end)

	return (s and service or nil)
end

local function core()
	for i, folder in pairs(script.Core:GetChildren()) do
		local service = checkService(folder.Name)
		if service then install(folder, service) end
	end

	install(script.Core.StarterCharacterScripts, game.StarterPlayer.StarterCharacterScripts)
	install(script.Core.StarterPlayerScripts, game.StarterPlayer.StarterPlayerScripts)
end

local function recurse(Patch,Source)
	for _, Item in ipairs(Patch:GetChildren()) do

		local SourceItem = Source:FindFirstChild(Item.Name)
		-- If item doesn't exist in source, we don't care, just clone
		if not SourceItem then
			Item:Clone().Parent = Source
			Item:Destroy()
		else
			-- Item exists
			-- If it's a folder, recurse.
			if Item:IsA("Folder") then
				recurse(Item, SourceItem)
			else
				SourceItem:Destroy()
				Item:Clone().Parent = Source
				Item:Destroy()
			end
		end
	end
end

local function others()
	for i, folder in ipairs(script:GetChildren()) do
		if folder.Name == 'Core' then continue end

		recurse(folder, script.Core)
	end
end

local function loadMissingConfigValues(targ, src)
	for index, value in pairs(src) do
		if targ[index] == nil then
			targ[index] = value
		end
	end
end

function module.run(source)
	local AutoloadValue = game.Players.CharacterAutoLoads
	game.Players.CharacterAutoLoads = false
	
	source.Animations.Parent = script.Core.ReplicatedStorage
	source.EntityData.Parent = script.Core.ReplicatedStorage
	source.Models.Parent = script.Core.ReplicatedStorage
	source.Sounds.Parent = script.Core.ReplicatedStorage
	source.Presets.Parent = script.Core.ServerStorage
	
	for i,plug in pairs(source.Plugins:GetChildren()) do --Install plugins
		plug.Parent = script
	end
		
	others()
	core()
	
	game.Players.CharacterAutoLoads = AutoloadValue
	if AutoloadValue == true then
		for i, plr in pairs(game.Players:GetPlayers()) do
			plr:LoadCharacter()
		end
	end
	
	shared.StrategisStatus.Installed = true
	
	script:Destroy()
end

return module