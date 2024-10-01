local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PresetUnit = {}

PresetUnit.Values = {
	["Attacks"] = {
		[1] = { --One will always be the passive attack, you could change attack modes
			["AttackName"] = "Basic",
			["AnimationName"] = "Attack",
			["Firerate"] = 1,
		}
	},
	["Abilities"] = { --Abilities this entity has access to
		
	},
	["EntityType"] = "Unit", --Building or unit?
	["Name"] = "PresetUnit",
	["Object"] = ReplicatedStorage.Models:FindFirstChild(""), --TODO: addsomehting here
	["Animations"] = {
		["Walk"] = "rbxassetid://00000000", --Walking animation
		["Idle"] = "rbxassetid://00000000", --Idle animation
		["Attack"] = "rbxassetid://00000000", --Attack animation
		["Emote"] = { --Picks a random emote
			"rbxassetid://00000000",
			"rbxassetid://00000000",
			"rbxassetid://00000000",
		},
	},
	["BuildTime"] = 5,
}




return PresetUnit
