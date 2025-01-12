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

local function ServiceLoadInsert(Containers)
	for i, v:Instance in pairs(Containers) do
		if v.Name == "Plugins" then
			return
		end

		local ServiceVal = v:FindFirstChildWhichIsA("ObjectValue")
		if ServiceVal ~= nil or ServiceVal.Name == "Service" or string.match(ServiceVal.Value.Name:GetFullName(), "%.") ~= nil then --Checks if it's a service
			continue
		end

		--Check if service already has the value
		local Match = script.Core[ServiceVal.Value.Name]:FindFirstChild(v.Name)
		if Match == nil then
			v.Parent = ServiceVal.Value
		else --Match found
			for i, v in pairs(v:GetChildren()) do
				v.Parent = Match
			end
			v:Destroy()
		end
	end
end

function module.run(source:Script)
	local AutoloadValue = game.Players.CharacterAutoLoads
	game.Players.CharacterAutoLoads = false
	
	ServiceLoadInsert(source:GetChildren())
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