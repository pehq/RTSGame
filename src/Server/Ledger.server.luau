--PehqDev
--Stores all entities
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EntityModule =  require(ReplicatedStorage.Modules.Entitiy)
local UnitModule =  require(ReplicatedStorage.Modules.Entitiy.Unit)
local BuildingModule =  require(ReplicatedStorage.Modules.Entitiy.Building)

local EntityDataList = {}
for i, v in pairs(ReplicatedStorage.EntityData:GetChildren()) do
	if v:IsA("ModuleScript") ~= true then
		continue
	end
	EntityDataList[v.Name] = require(v)
end

local EntityList = {}

--Start up
task.wait(5)
for i, v in pairs(Players:GetPlayers()) do
	local Folder = Instance.new("Folder")
	Folder.Name = v.UserId
	Folder.Parent = workspace
end