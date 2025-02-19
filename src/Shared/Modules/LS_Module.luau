local module = {}

local ts = game:GetService("TweenService")

function SpawnLighting(p1:Vector3,p2:Vector3,parent,size, timeD)
	local part = Instance.new("Part",parent)
	part.Anchored = true
	part.Color = Color3.fromRGB(69, 174, 255)
	part.Material = "Neon"
	part.CanCollide = false
	part.CanTouch = false
	
	local dist = (p2-p1).Magnitude
	
	part.Size = Vector3.new(size,size,dist)
	part.CFrame = CFrame.new(p1,p2) * CFrame.new(0,0,-dist/2)
	
	ts:Create(part,TweenInfo.new(timeD,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = Vector3.new(0,0,dist)}):Play()
	delay(timeD + .2,function()
		part:Destroy()
	end)
end

module.Bolt = function(p1,p2,num,offset,size)

	local Points = {}
	
	for i= 0, num do
		
		local OffSet = Vector3.new(math.random(-offset,offset),math.random(-offset,offset),math.random(-offset,offset))
		
		if i == 0 or i == num then
			OffSet = Vector3.new(0,0,0)
		end
		
		local part = Instance.new("Part", workspace.Effects.WayPoints)
		part.Anchored = true
		part.Material = "Neon"
		part.Color = Color3.fromRGB(0, 255, 255)
		part.Size = Vector3.new(.5,.5,.5)
		part.Transparency = 1
		
		part.Position = p1 + (p2 - p1).Unit * i * (p2 - p1).Magnitude/num + OffSet --wtf did i just wrote
		
		table.insert(Points,part.Position)
	end
	
	for i, p in pairs(Points) do
		if Points[i+1] ~= nil then
			SpawnLighting(Points[i],Points[i+1],workspace.Effects,size, 1.2)
		end
	end
	workspace.Effects.WayPoints:ClearAllChildren()
end

return module
