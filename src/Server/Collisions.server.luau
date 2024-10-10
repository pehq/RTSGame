--Code from Roblox docs: https://create.roblox.com/docs/workspace/collisions#disabling-character-collisions
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

PhysicsService:RegisterCollisionGroup("Entity")
PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)
PhysicsService:CollisionGroupSetCollidable("Entity", "Characters", false)

local function onDescendantAdded(descendant)
	-- Set collision group for any part descendant
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