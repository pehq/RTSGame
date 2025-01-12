local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.RTSGame:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.RTSGame)