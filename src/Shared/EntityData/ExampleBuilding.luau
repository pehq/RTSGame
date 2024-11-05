local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = {}

Data.Values = {
	["EntityType"] = "Building",
	["Data"] = script,
	["Name"] = "ExampleBuilding",
	["CanBuildUnits"] = true,
	["Object"] = ReplicatedStorage.Models.ExampleBuilding,
	["MaxHealth"] = 100,
	["Health"] = 100,
	["MaxShield"] = 500,
	["Shield"] = 500,
	
	["BuildSlots"] = {
		{ --Slot 1
			["DataName"] = "PresetUnit", --Name of unit's module
			["Icon"] = "rbxasset://5004731269", --rbxassetid://###########, if you don't have image then put it as nil or false
			["Object"] = ReplicatedStorage.Models.PresetUnit,
			["BuildTime"] = 0,
			["UpgradesRequired"] = nil, --TODO: Add upgrades.
		},
	},
}

return Data