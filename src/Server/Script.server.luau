--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.Nevermore:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.Nevermore)

local serviceBag = require("ServiceBag").new()
serviceBag:Init()
serviceBag:Start()

local x = require("Binder")
local y = x.new()

y