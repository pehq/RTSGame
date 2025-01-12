--DO NOT PUT ANY CONNECTIONS HERE, ONLY USE FOR DATA!!!
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PresetUnit = {}

--TODO: Values with `--*` means that this value must be included

PresetUnit.Values = {
	["DataName"] = script.Name,
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
	["Name"] = "Preset Unit",
	["Object"] = ReplicatedStorage.Models:FindFirstChild("rigged Assault destroyer"), --TODO: addsomehting here
	["Animations"] = { --TODO: Note, if skins are enabled then animations will be overrided by skin.
		--["Walk"] = "rbxassetid://00000000", --Walking animation
		["Idle"] = "rbxassetid://00000000", --Idle animation
		["Attack"] = "rbxassetid://00000000", --Attack animation
		["Emote"] = { --Picks a random emote
			"rbxassetid://00000000",
			"rbxassetid://00000000",
			"rbxassetid://00000000",
		},
	},
	["BuildTime"] = 5,
	["Speed"] = 16,
	["MaxHealth"] = 100, --*
	["Health"] = 100, --*
	["MaxShield"] = 500, --*
	["Shield"] = 500, --*
	["CanBuild"] = true,
	["BuildRange"] = 5, --In studs
	["BuildSlots"] = {
		[1] = {
			["EntityDataName"] = "ExampleBuilding",
			["Object"] = ReplicatedStorage.Models.ExampleBuilding,
			["Icon"] = "rbxassetid://00000000",
			["BuildTime"] = 5,
		}
	},
	
	--Squadrons
	["CanJoinSquadron"] = true,
	["SquadronLimit"] = 5,
	["SquadronRadiusSizeMinMax"] = Vector2.new(5, 5), --In studs
	["SquadronUnitRotation"] = 0, --In degrees, how much the units in the squadron rotates
	["SquadronDiscRotation"] = 0 ,--How much the disc rotates
	["ReverseSquadronUnitRotationDirection"] = false, --If false, will rotate counter-clockwise, otherwise clockwise 
	["ReverseSquadronDiscRotationDirection"] = false,
	["SquadronDiscTiltAngle"] = 0, --In degrees
}

return PresetUnit