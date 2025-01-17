--Pehq
--TODO: add vector functions

local MoreVectors = {}
MoreVectors.__index = MoreVectors

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
	["nil"] = function(args:nil)
		return {}
	end,
}

function MoreVectors.new(...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args)
	
	local self = setmetatable({}, MoreVectors)
	self = Args
	
	return self
end

function MoreVectors.CheckTablesIndexesForVector(TableWithVectorIndex, ...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args)

	for i, v in pairs(TableWithVectorIndex) do
		if i == Args then
			return i
		end
	end
	
	return nil
end

function MoreVectors.__eq(self, other)
	local Res = true
	
	local Prioritized = #self <= #other and self or other --

	for i = 1, #Prioritized do
		if self[i] ~= other[i] then
			return
		end
	end
	
	return Res
end

return MoreVectors