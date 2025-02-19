local Handler = {}

for _, Mod in pairs(script:GetChildren()) do
	if Mod:IsA("ModuleScript") == false then
		continue
	end
	Handler[Mod.Name] = require(Mod)
end

return Handler