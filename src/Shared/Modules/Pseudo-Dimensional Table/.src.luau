--Pehq
--A more memory efficient method to dimensional tables (or matrices)
--TODO: Refactor
local MoreVectors = require(script.MoreVectors)

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
	["nil"] = function(args:nil)
		return {}
	end,
}

function PseudoTable.new(...)
	local Args = {...}
	print(Args)
	Args = VectorToTableFuncs[typeof(Args[1])](Args)
	
	local self = setmetatable({}, PseudoTable)
	self.Table = {}
	self.Dimensions = MoreVectors.new(Args)
	self.Data = {}
	
	return self
end

function PseudoTable:ValidateBounds(...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args)
	for i, coord in ipairs(Args) do
		if coord < 1 or coord > self.Dimensions[i] then
			error(("Coordinate out of bounds: Dimension %d has size %d but received %d"):format(i, self.Dimensions[i], coord))
		end
	end
end

function PseudoTable:SetAll(val)
	local Factor = 1
	for i = 1, #self.Dimensions do
		Factor *= self.Dimensions[i]
	end
	
	print(Factor)
	
	self.Table = table.create(Factor, val)
	
	return self
end

function PseudoTable:GetIndexByCoord(...)
    local Args = {...}
    local converter = VectorToTableFuncs[typeof(Args[1])]
    assert(converter, "Invalid type for Args[1]")
    Args = converter(Args)

    -- Validate Args length
    if #Args > #self.Dimensions then
        error("Too many coordinates provided")
    end

    -- Recursive helper function
    local function Recurse(axis)
        if axis > #self.Dimensions or axis > #Args then
            return 0
        end

        -- Calculate product of previous dimensions
        local LastDimsLength = 1
        if axis > 1 then
            for i = 1, axis - 1 do
                LastDimsLength *= self.Dimensions[i]
            end
        end

        -- Calculate current index and recurse
        local currentIndex = (Args[axis] - 1) * LastDimsLength
        return currentIndex + Recurse(axis + 1)
    end

    return Recurse(1) + 1
end

function PseudoTable:GetByCoordinate(...)
	local index = self:GetIndexByCoord(...)
	return self.Table[index]
end

function PseudoTable:SetByCoordinate(Value, ...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args)
	
	self.Table[self:GetIndexByCoord(...)] = Value
	
	return self
end

--If the dimensions are being resized smaller, then it'll discard the values out of bounds.
function PseudoTable:Resize(newDimensions)
	local newTable = PseudoTable.new(unpack(newDimensions))
	for i = 1, #self.Table do
		local coords = self:GetCoordsByIndex(i)
		if self:IsValidCoordinate(coords, newDimensions) then
			newTable:SetByCoordinate(self.Table[i], unpack(coords))
		end
	end
	self.Table = newTable.Table
	self.Dimensions = newDimensions
end

function PseudoTable:Serialize()
	return {
		Dimensions = self.Dimensions,
		Table = self.Table,
	}
end

function PseudoTable.Deserialize(data)
	local obj = PseudoTable.new(unpack(data.Dimensions))
	obj.Table = data.Table
	return obj
end

function PseudoTable:AddDimension(size)
	table.insert(self.Dimensions, size)
	self:SetAll(nil) -- Reset the table to match new dimensions
end

--Extract a "slice" of the table along a specific dimension or range.
function PseudoTable:GetSlice(dimension, startIndex, endIndex)
	local slice = {}
	for i = startIndex, endIndex do
		for coords, value in self:Iterate() do
			if coords[dimension] == i then
				table.insert(slice, value)
			end
		end
	end
	return slice
end

--Store only non-default values to save memory for large sparse tables.
function PseudoTable:SetByCoordinateSparse(value, ...)
	local index = self:GetIndexByCoord(...)
	if value == nil or value == 0 then
		self.Table[index] = nil -- Remove default or empty values
	else
		self.Table[index] = value
	end
end

function PseudoTable:GetByCoordinateSparse(...)
	local index = self:GetIndexByCoord(...)
	return self.Table[index] or 0 -- Return default value
end

--Apply a function to all elements.
--pt:Map(function(x) return x * 2 end) --> Doubles all values
function PseudoTable:Map(func)
	for index, value in ipairs(self.Table) do
		self.Table[index] = func(value)
	end
end

--Cache dimension products for faster index calculations.
--Update GetIndexByCoord to use these precomputed values.
function PseudoTable:PrecomputeProducts()
	self.DimensionProducts = {}
	self.DimensionProducts[1] = 1
	for i = 2, #self.Dimensions do
		self.DimensionProducts[i] = self.DimensionProducts[i - 1] * self.Dimensions[i - 1]
	end
end

--Create table elements only when accessed or modified, further improving memory efficiency for large dimensions.
function PseudoTable:GetOrSet(index, defaultValue)
	if not self.Table[index] then
		self.Table[index] = defaultValue
	end
	return self.Table[index]
end

--Allow exporting the PseudoTable into a Lua-style nested table.
function PseudoTable:ToNestedTable()
	if #self.Dimensions > 3 then
		warn("YOUR MEMORY IS AT RISK!!! Avoid converting **hyper**-dimensional tables into a regualar table, unless if you know what you are doing then you can comment this line out. (ONLY COMMENT YOU KNOW WHAT YOU ARE [bass.wav] DOING!!! \n Look, this modules allows you to use tables that are 50 layers deep or so without it being actually 50 layers deep, using this function for this use case defeats the purpouse of this module. But hey, I can't stop you from doing so...")
	end
	local function build(dimensions, depth)
		if depth > #dimensions then return nil end
		local tbl = {}
		for i = 1, dimensions[depth] do
			tbl[i] = build(dimensions, depth + 1)
		end
		return tbl
	end
	return build(self.Dimensions, 1)
end

--Since lua's tables are anonymous, this function changes the index of a table even if the index isn't matching in memory.
function PseudoTable:SetDimensionData(Value, ...)
	local Args = {...}
	Args = VectorToTableFuncs[typeof(Args[1])](Args)
	
	local OldIndex = MoreVectors.CheckTablesIndexesForVector(self.Data, Args)
	if self.Dimensions == Args and OldIndex == nil then
		self.Data[Args] = Value
	elseif self.Dimensions == Args and OldIndex ~= nil then
		self.Data[OldIndex] = Value
	end
end

--Visualize the PseudoTable in a grid or matrix format.
function PseudoTable:PrettyPrint() --DEBUG ONLY
	local output = {}
	for coords, value in self:Iterate() do
		table.insert(output, string.format("(%s): %s", table.concat(coords, ", "), tostring(value)))
	end
	print(table.concat(output, "\n"))
end

--Provide tools to validate dimensions and data integrity.
function PseudoTable:Validate() --DEBUG ONLY
	for index, value in ipairs(self.Table) do
		local coords = self:GetCoordsByIndex(index)
		assert(#coords == #self.Dimensions, "Invalid dimensions detected")
	end
end

--Allow filtered or dimension-based iteration.
--for coords, value in pt:IterateFiltered(function(x) return x > 0 end) do
	--print(coords, value)
--end
function PseudoTable:IterateFiltered(predicate)
	local index = 0
	return function()
		index += 1
		while index <= #self.Table and not predicate(self.Table[index]) do
			index += 1
		end
		if index <= #self.Table then
			local coords = self:GetCoordsByIndex(index)
			return coords, self.Table[index]
		end
	end
end

function PseudoTable:Add(other)
	assert(self == other, "Dimensions do not match for addition")
	local result = PseudoTable.new(unpack(self.Dimensions))
	for i = 1, #self.Table do
		result.Table[i] = self.Table[i] + other.Table[i]
	end
	return result
end

function PseudoTable.__eq(self, other)
	if getmetatable(other) ~= PseudoTable then --not using this module
		return false
	end
	if #self.Dimensions ~= #other.Dimensions then --not the same dimensions
		return false
	end
	for i = 1, #self.Dimensions do --dimensions aren't equal
		if self.Dimensions[i] ~= other.Dimensions[i] then
			return false
		end
	end
	return true
end

--Provides functionaliyu to loops through all elements
function PseudoTable:Iterate() 
	local index = 0
	local size = #self.Table
	return function()
		index += 1
		if index <= size then
			local coords = self:GetCoordsByIndex(index)
			return coords, self.Table[index]
		end
	end
end

return PseudoTable