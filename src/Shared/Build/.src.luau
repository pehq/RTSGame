--UNDER NO CIRCUMSTANCES SHOULD THIS BE RUN IN GAME, IN FACT IM PUTTING A FAILSAFE!
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	error("Cannot be used in production!")
end

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Services = {
	[ReplicatedFirst] = "ReplicatedFirst",
	[ReplicatedStorage] = "ReplicatedStorage",
	[ServerScriptService] = "ServerScriptService",
	[ServerStorage] = "ServerStorage",
	[StarterPack] = "StarterPack",
	[StarterGui] = "StarterGui",
	[StarterPlayer.StarterPlayerScripts] = "StarterPlayerScripts",
	[StarterPlayer.StarterCharacterScripts] = "StarterCharacterScripts",
}

local InstallerExceptions = {
	[ReplicatedStorage.Animations] = ReplicatedStorage,
	[ReplicatedStorage.EntityData] = ReplicatedStorage,
	[ReplicatedStorage.Models] = ReplicatedStorage,
	[ReplicatedStorage.Presets] = ServerStorage,
	[ReplicatedStorage.Sounds] = ReplicatedStorage
}

local SOURCE = script.MainModule
local LOADER = script["STRATEGIS Loader"]

local Build = {}

function Build.Build()
	local Source = SOURCE:Clone()
	local Loader = LOADER:Clone()
	
	local Core = Instance.new("Folder")
	Core.Name = "Core"
	
	for Service, Name in pairs(Services) do
		local Folder = Instance.new("Folder")
		Folder.Name = Name
		Folder.Parent = Core
		
		for i, v:Instance in pairs(Service:GetChildren()) do
			if v == script then --skip this script in the build process
				continue
			end
			if InstallerExceptions[v] ~= nil then
				local ExceptedClone = v:Clone()
				
				local ServiceObj = Instance.new("ObjectValue")
				ServiceObj.Name = "Service"
				ServiceObj.Value = InstallerExceptions[v]
				ServiceObj.Parent = ExceptedClone
				
				ExceptedClone.Parent = Loader.Installer
				
				continue
			end
			
			
			v:Clone().Parent = Folder
		end
	end
	
	Core.Parent = Source
	
	local Plugins_Folder = Instance.new("Folder")
	Plugins_Folder.Name = "Plugins"
	Plugins_Folder.Parent = Loader.Installer
	
	Source.Parent = workspace
	Loader.Parent = workspace
	
	print(Source, Loader)
end

return Build