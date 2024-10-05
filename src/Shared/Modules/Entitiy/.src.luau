local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EntityData = ReplicatedStorage.EntityData

local Entity = {}
Entity.__index = Entity

Entity.EntitiesDirectory = {}
for i, v in pairs(EntityData:GetChildren()) do
	local Required
	
	if v:IsA("ModuleScript") then
		Required = require(v)
		Entity.EntitiesDirectory[Required.Values.Name] = Required
	end
	
	Required = nil
end

local EntityIdCount = 1

function Entity.new(Values:{})
	local self = {}
	setmetatable(self, Entity)
		
	self.EntityId = EntityIdCount
	EntityIdCount += 1
	
	self.Owner = Values.Owner or nil
	self.Team = Values.Owner.Team or nil
	self.Object = Values.Object:Clone()
	
	--TODO: This is very memory costly. If used en masse, then server might crash.
	for i, v in pairs(Values) do
		if typeof(v) == "table" then
			v = table.clone(v) --Copy the table rather than reference it
		end
		if self[i] == nil then
			self[i] = v
		end
	end
	
	return self
end


return Entity