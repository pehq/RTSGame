--[[
	@class ServerMain
]]
local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.Nevermore:FindFirstChild("LoaderUtils", true).Parent
local require = require(loader).bootstrapGame(ServerScriptService.Nevermore)

local serviceBag = require("ServiceBag").new()
serviceBag:GetService(require("NevermoreExampleService"))
serviceBag:Init()
serviceBag:Start()

local FakeSkybox = require("FakeSkybox")
local Skybox = Instance.new("Sky")

local x = FakeSkybox.new(Skybox)