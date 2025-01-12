--repeat task.wait() until shared.StrategisStatus.Installed
--Code from Roblox docs: https://create.roblox.com/docs/workspace/collisions#disabling-character-collisions
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollisionStrings = {
	"Characters",
	"Entity",
	"Unit",
	"Building",
	"InactiveUnit",
}

for i = 1, #CollisionStrings do
	PhysicsService:RegisterCollisionGroup(CollisionStrings[i])
end

for i = 1, #CollisionStrings do
	local value = CollisionStrings[i]
	
	PhysicsService:CollisionGroupSetCollidable(value, "Characters", false)
	if value == "Characters" then
		continue
	end
	
	PhysicsService:CollisionGroupSetCollidable(value, "Entity", true)
end

PhysicsService:CollisionGroupSetCollidable("InactiveUnit", "InactiveUnit", false)
PhysicsService:CollisionGroupSetCollidable("InactiveUnit", "Unit", false)

local function onDescendantAdded(descendant)
	--Set collision group for any part descendant
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = "Characters"
	end
end

local function onCharacterAdded(character)
	-- Process existing and new descendants for physics setup
	for _, descendant in character:GetDescendants() do
		onDescendantAdded(descendant)
	end
	character.DescendantAdded:Connect(onDescendantAdded)
end

Players.PlayerAdded:Connect(function(player)
	-- Detect when the player's character is added
	player.CharacterAdded:Connect(onCharacterAdded)
end)

for i, v in pairs(ReplicatedStorage.Models:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CollisionGroup = "Entity"
	end
end

--=hel