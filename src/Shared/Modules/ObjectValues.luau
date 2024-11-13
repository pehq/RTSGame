--Useful for Values in Configurations
local ObjValue = {}

local ValueInstances = { --Switch case table
	["boolean"] = "BoolValue",
	["BrickColor"] = "BrickColorValue",
	["CFrame"] = "CFrameValue",
	["Color3"] = "Color3Value",
	["number"] = "NumberValue",
	["Instance"] = "ObjectValue",
	["Ray"] = "RayValue",
	["string"] = "StringValue",
	["Vector3"] = "Vector3Value"
}

function ObjValue.NewObjValForVal(Val)
	local ObjVal:ValueBase = Instance.new(ValueInstances[typeof(Val)])
	ObjVal.Value = Val
	
	return ObjVal	
end

return ObjValue