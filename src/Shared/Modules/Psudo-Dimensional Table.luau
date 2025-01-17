--Pehq
--A more memory efficient method to dimensional tables (or matrices)
local PseudoTable = {}
PseudoTable.__index = PseudoTable

local VectorToTableFuncs = {
	["number"] = function(args:number)
		return args
	end,
	["Vector2"] = function(args:Vector2)
		return {args.X, args.Y}
	end,
	["Vector2int16"] = function(args:Vector2int16)
		return {args.X, args.Y}
	end,
	["Vector3"] = function(args:Vector3)
		return {args.X, args.Y, args.Z}
	end,
	["Vector3int16"] = function(args:Vector3int16)
		return {args.X, args.Y, args.Z}
	end,
	["table"] = function(args:{})
		return args
	end,
}

function PseudoTable.New(...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args)
	
	local self = setmetatable({}, PseudoTable)
	self.Table = {}
	self.Dimensions = Args
	
	return
end

function PseudoTable:GetIndexByCoord(...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args)

	local function Recurse(axis:number)
		local Result = nil
		if axis > #self.Dimensions or axis > #Args then
			return 0
		end

		local LastDimsLength = 1
		if axis ~= 1 then
			for i = 1, #axis - 1 do
				Result *= self.Dimensions[i]
			end
		end

		return Args[axis] * LastDimsLength + Recurse(axis + 1)
	end
	
	return Recurse(1)
end

function PseudoTable:SetByCoordinate(Value, ...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args)
	
	self.Table[self:GetIndexByCoord(...)] = Value
	
	return self
end

function PseudoTable:ReturnDimension(...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args) --TODO: left off here
end

function PseudoTable.__eq(self, otherPseudoTable)
	if self == otherPseudoTable then
		return true
	end
	
	local Equal = true
	
	local dim1 = self.Dimensions
	local dim2 = otherPseudoTable.Dimensions
	
	for i = 1, #dim1 do
		if dim1[i] == nil or dim2[i] == nil or dim1[i] ~= dim2[i] then
			Equal = false
			break
		end
	end

	return Equal
end

function PseudoTable.__add(self, otherPseudoTable)
	local dim1 = self.Dimensions
	local dim2 = otherPseudoTable.Dimensions
	
	--TODO: wth???
end

return PseudoTable