--[[

// server submodule
// version 07/07/2025

// best practices:
	1. DO NOT trust the client.
	  > exposing GET requests to the client may let them to reverse-engineer your online services' APIs while
	    also giving them the ability to DDOS and slow down your services.
	
	  > exposing POST requests to the client will open the 7 gates all at once, giving them access to post
	    modified data (i.e. coins) to your services, fill up your service's storage with garbage data, or even
	    post content to your services that should not be allowed.
	
	2. prioritize server authority.
	  > the server is always on your side (except if you did the stupid of allowing the client to control the
	    server), so do all of the security-related things there.
	
	3. DO NOT store private API keys anywhere which are replicated to the client (in ReplicatedStorage, etc.)
	  > the player can just access it through their client since these are copied (replicated) to the client.
	
// this submodule is still in beta so expect bugs and changes

]]

local server = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local tostring2 = require(script.Parent.Packages.Debug.ToString2)

local testDataOnStudio = true --test data on studio mode

local separators = {".", "/"}

local ram = {}

local data = {}
data.service = game:GetService("DataStoreService")
data.events = script.Parent.ServerData

data.stores = {}
data.stores.StudioData = {
	store = data.service:GetDataStore("WindowsData_Studio"),
	structure = {
		dversion = "dev1",
		pluginData = {},
		appData = {}
	}
}
data.stores.PlayerData = {
	store = data.service:GetDataStore("WindowsData"),
	structure = {
		dversion = "release",
		pluginData = {},
		appData = {}
	}
}

local targetDataStore = testDataOnStudio and RunService:IsStudio() and data.stores.StudioData or data.stores.PlayerData

function data:speakChange(player, vdata)
	self.events.LISTEN:FireClient(player, vdata)
end

function data:getRam(player:Player)
	local userId = player.UserId
	return ram[userId], userId
end

function data:setRam(player:Player, vdata)
	local userId = player.UserId
	ram[userId] = vdata
	if not player.Character then player.CharacterAdded:Wait() end
	self:speakChange(player, ram[userId])
end

function data:load(player:Player, store:{ ["store"]:DataStore, ["structure"]:{["dversion"]:string}})
	local userId = tostring(player.UserId)
	local success, vdata = pcall(function()
		return store.store:GetAsync(userId)
	end)

	if success and vdata then
		if vdata.dversion ~= store.structure.dversion then
			vdata = store.structure
		end
	else
		vdata = store.structure
	end

	return vdata
end

function data:save(player:Player, store:{ ["store"]:DataStore, ["structure"]:{["dversion"]:string}})
	local vdata, userId = self:getRam(player)
	local success, errorMessage = pcall(function()
		store.store:SetAsync(userId, vdata)
	end)

	if not success then
		warn("Failed to save data for player " .. player.Name .. ": " .. errorMessage)
	end
end

function data:save_clearFromRam(player:Player, store)
	self:save(player, store)
	self:setRam(player, nil)
end

function data:load_toRam(player:Player, store)
	local d = self:load(player, store)
	self:setRam(player, d)
	return d
end

function data:modifyRam(player, path, value)
	if not player then
		warn("syntax: player, path, value")
		warn("example: data:modifyRam(game.Players.z5rxtcyvui, \"statistics.coins\", 123456)")
		warn("ram contents:")

		local contents = string.split(tostring2(ram), "<br/>")
		for i, content in pairs(contents) do
			warn(content)
		end

		return
	end
	
	local keys = {path}
	if #keys == 1 and typeof(keys[1]) == "string" then
		print("string mode")
		local path = keys[1]
		for i, separator in pairs(separators) do
			keys = string.split(path, separator)
			if keys[1] ~= path then break end
		end
	end

	local d = self:getRam(player)
	local dx = d
	for i = 1, #keys - 1 do
		dx = dx[keys[i]]
		if not dx then warn("Data: Invalid path: " .. path) return end
	end
	local lastKey = keys[#keys]
	if dx[lastKey] == nil then warn("Data: Invalid path: " .. path) return end
	dx[lastKey] = value
	self:setRam(player, d)
end

data.events.GET.OnServerInvoke = function(player:Player, ...:any|string)
	local keys = {...}
	if #keys == 1 and typeof(keys[1]) == "string" then
		local path = keys[1]
		for i, separator in pairs(separators) do
			keys = string.split(path, separator)
			if keys[1] ~= path then break end
		end
	end
	
	local dx = data:getRam(player)
	for i, v in pairs(keys) do
		if typeof(v) ~= "string" then warn("Data: Type mismatch: "..player.Name) return end
		local dy = dx[v]
		dx = dy
		--[[if not dy then
			warn("Data: Invalid key \""..v.."\": "..player.Name)
		end]]
	end
	return dx
end

local function requestModule(requestFunctionName:string, player:Player, origin:ModuleScript, ...)
	local originFolder = origin.Parent and origin.Parent.Name
	if not originFolder then player:Kick("Malformed request") end
	local targetFolder = script:FindFirstChild(originFolder)
	if not targetFolder then player:Kick("Malformed request") end
	local targetModule = targetFolder:FindFirstChild(origin.Name)
	if not (targetModule and targetModule:IsA("ModuleScript")) then player:Kick("Malformed request") end --basic sanity checks

	local fs = require(targetModule)
	if not fs or typeof(fs) ~= "table" then warn("Required module did not return a table of functions") return end

	local tfunc = fs[requestFunctionName]
	if not tfunc or typeof(tfunc) ~= "function" then error("Module did not include the requested function "..(requestFunctionName and tostring(requestFunctionName) or "")) end

	return tfunc(player, ...)
end

data.events.POST.OnServerEvent:Connect(function(player, origin:ModuleScript, ...)
	requestModule("LSPOST", player, origin, ...)
end)

data.events.HTTP.GET.OnServerInvoke = function(player, origin:ModuleScript, ...)
	return requestModule("GET", player, origin, ...)
end

server.data = data

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Wait()
	server.data:load_toRam(player, targetDataStore)
end)
Players.PlayerRemoving:Connect(function(player)
	server.data:save_clearFromRam(player, targetDataStore)
end)

server.data.events.QUERY_AVAILABILITY.OnServerInvoke = function() return true end

return server