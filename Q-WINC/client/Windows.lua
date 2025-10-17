--!native

--[[
rewritten on 23/05/2024 by the original creator @z5rxtcyvui because i thought the spaghetti looked terrible lol
you can view the pocket spaghetti on the legacy module under (this module) > Legacy

this new rewrite of the original module had customizability in mind

you can publish a modified version of this, crediting would be really nice
	* you can publish custom themes and plugins and link this module's page for quick access to what it's used for <--- works well with the roblox marketplace, but idk about github (maybe it has a place to do that that i haven't known of yet)

		DD/MM/YYYY
version	23/08/2025

*#* these changelogs are made when the module was still distributable in the Roblox marketplace *#*
changes:
	-i think i fixed the header double clicking bug
	-double clicking the header now maximizes the window instead of minimizing it
	-:maximize() can now rember!!1
	-fixed memory some leaks in the Spring package
	-by that i meant COMPLETELY REWRITING the spring package
	-some Header plugin adjustments so :maximize() can rember
	-exit button is now a part of the header button function to clean up the code
	-a certain music player app is delayed (delinked from the module, go to the development game to test it at its current state)
	-frametime grapher is here, no icons yet though (used for testing stutters)
	-fixed some memory leaks by letting the destroyer wait for the things inside of the window to deregister themselves
	-windows now turn darker when it's waiting for something before getting destroyed
	-other quality of life updates which i forgot to take notes of
	
	-finally, an update after a long hibernation
	
	---- 02/05/2025 ----
	-fixed header anchor point not resetting to original after snapping into a snap data
	-fixed :minimize() calculating anchor point WRONG
	-new Stagelight theme, a referenced mix between iPadOS and VisionOS windows (with a couple more twists so they're different enough while fitting in)
	
	-those are the 3 things i can do while studio just constantly crashes after playtest
	
	---- 01/04/2025 ----
	-fixed altCursor breaking with UINavigation
	-new SPRING update which overhauls some animations to use spring physics, which allows for overkill smooth animations, most obvious in Color Picker
	-new Spring module packaged as a requirement for spring animations
	-new window.spring() and window:spring(), and window.springInfo() which allows the use of spring physics for the window and any tweenable properties of an instance
	-a few more bug fixes
	
	---- 01/04/2025 ----
	-improved color picker scaling states
	-fixed various bugs:
		header minimizeOnFloor minimized mid-air
		header breaking anchor point
		header not preserving scalar size after resize
		header snap points not scaling properly
		adapt resizing not scaling properly
	-getTheme() can now be called directly from the module along with altMouse()
	
	---- 25/03/2025 ----
	-replaced hideMouse with altMouse() along with new AltMouse theme object
	-did Color Picker app
	-did Window Manager app
	-new icons for some apps
	-fixed the problems that happen when destroying
	-fixed unable to destroy window
	-changed bindEvent to use pcall
	
	---- 28/01/2025 ----
	-renamed getUpdateSpecialMouse to getSpecialMouse
	-updated the App Launcher
	-various bug fixes
		fixed incorrect movements on surface guis with its face set not at the front
		fixed movements being very choppy (set predictiveNavigationWeight to 0 and movement delta checks)
		fixed etc (i forgor)
	-performance improvements
	-new app icons (parts of the updated app launcher)
	-new Server module (still in beta). to be able to use it, require the Windows module in a server script.
	-new Audio Player app (beta since it uses the beta server module)
	-fixed old referrences of the Window table by changing . into : for various functions (which includes getTheme).
		if your script suddenly fails after updating, you should probably check whether if this is the cause and change . into :
	-new snapXToGrid function
	-new checkServer, postServer, getServer, and listenServer functions (part of beta server module)

	---- 21/12/2024 ----
	-fixed most of the notepad app problems
	-fixed speed clicker score label again
	-changed how adding header buttons work (use a . instead of : now)
	-calling header.addButton now returns the button instead of the header plugin
	-removing the header button now just requires the button instance previously returned by calling .addButton
	-new .modifyButtonLabel function in the header plugin which does exactly that
	-changed how header buttons fit themselves

	---- 16/12/2024 ----
	-rewritten the Adapt plugin
	-minimize feature
	-slightly upgraded header plugin
	-fixed speed clicker's initial score label
	-removed the liquidify feature (part of the adapt plugin rewrite)
	-adapt plugin now scales and positions the window relative to the container's border
	-removed the ugly table.inserts for every plugin and replaced them with table[key]
	-microfixes for header and resize

	---- 07/12/2024 ----
	-added predictive navigation. you can change this in the (SystemSettings).predictiveNavPercent or window.settings.predictiveNavPercent)
	-predictive navigation helps to obliterate the feeling input latency while silkening and adds more elasticity to animations
	-fixed one bug
	-included my HapticManager2 module in the module so you don't have to get the module
	-changed "windowId" to "id"
	-enhanced header buttons
	-header and resize now disables the mouse icon temporarily
	-renamed addHeaderButton and removeHeaderButton by deleting "Header" in their names
	-added "FlippedControllerY" which flips the window controls location
	-new "Apps" folder
	-new module:launchApp feature
	-fixed autocomplete showing the legacy version
	-deprecated "window.specialMouse". use "window.getUpdateSpecialMouse" instead
	-enhanced inputs
	-FINALLY FIXED the largest multitouch bugs
]]

local module = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

--variables
module.plugins = {} --plugins
module.screen = nil --the screen gui used
module.space = {} --all registered windows of this module's requiree
module.localData = {} --local data for quick access, should not be trusted. always do data manipulation on the server

module.settings = require(script.SystemSettings)
module.legacy = require(script.Legacy.WindowsLegacy)

local compareStrings = require(module.settings.packages.CompareStrings)
local pointConverter = require(module.settings.packages.PointConverter)

module.path = script

local windowCreatedEvent = Instance.new("BindableEvent")
local windowDestroyedEvent = Instance.new("BindableEvent")

module.windowCreated = windowCreatedEvent.Event
module.windowDestroyed = windowDestroyedEvent.Event

local altCursorInstance --the alternate cursor's instance
local altCursorUpdater --the alternate cursor's updater connection
local altCursorZIndexUpdater --the alternate cursor's ZIndex updater connection
local altCursorDisconnectUpdater --the alternate cursor's disconnect updater

local hasSetupPlugins = false --whether if the module has setup the plugins or not


--shortcuts
module.haptics = module.settings.hapticManager
module.spring = module.settings.spring
module.debug = module.settings.debug

--functions

--@param characters: specified characters to pick from
--@param length: length of the string to generate
function module:genId(characters:string|any, length:number|any)
	local characters = characters or "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	local length = length or 64 --big boi
	
	local random = Random.new()
	local result = ""

	for i = 1, length do
		local randomIndex = random:NextInteger(1, #characters)
		result = result .. characters:sub(randomIndex, randomIndex)
	end

	return result
end

--@param id_or_zIndex: the id or ZIndex of the window to find
function module.findWindow(id_or_zIndex:string|number)
	if typeof(id_or_zIndex) == "string" then
		local tickRecordBegin = tick()
		local budget = module.settings.executionTimeBudget or 1/60
		for i, v in pairs(module.space) do
			if tick() - tickRecordBegin > budget then tickRecordBegin = tick(); task.wait() end
			if v.id == id_or_zIndex then
				return v
			end
		end
	end
	return module.space[id_or_zIndex]
end

--creates a new spring info
--@param bounces: amount of bounces
--@param duration: duration
function module.springInfo(duration:number?, bounces:number?)
	return module.settings.spring.springInfo(duration, bounces)
end

--base
module.baseWindow = {}
module.baseWindow.__index = module.baseWindow

--@param pluginName: plugin name
--@param plug: require(module) -> {[init]: function, [quit]: function, ...}
function module.registerPlugin(pluginName:string, plug)
	module.plugins[pluginName] = plug
end

--sets up plugins
function module.setupPlugins()
	if hasSetupPlugins then return end
	for i, mod in pairs(module.settings.plugins:GetChildren()) do
		module.registerPlugin(mod.Name, require(mod))
	end
	hasSetupPlugins = true
end

--destroys a window
--@param windowId: the window id of the window to destroy
function module.destroyWindow(windowId)
	if not windowId then return end
	local window = module.findWindow(windowId)
	if not window then warn("Invalid window id") return end
	
	coroutine.wrap(function()
		task.wait()
		windowDestroyedEvent:Fire(windowId)
	end)()
	
	local self = window
	
	local tickRecordBegin = tick()
	local budget = self.settings and self.settings.executionTimeBudget or 1/60

	local selfIndex = table.find(module.space, self)
	if selfIndex then
		table.remove(module.space, selfIndex)
		if selfIndex > 0 then
			local search = module.space[selfIndex-1]
			search = search and search or module.space[selfIndex+1]
			if search and search.focus then
				search:focus()
				local searchedInstance = search.instance
				if GuiService.SelectedObject and searchedInstance:FindFirstAncestorWhichIsA("BasePlayerGui") then
					GuiService:Select(searchedInstance)
				end
			end
		end
	end
	self:tween(TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {GroupColor3 = Color3.new(0.5,0.5,0.5), GroupTransparency = 0.25})
	self:fireEvent("destroying")
	task.wait(task.wait()) --do not remove (it helps the destroying connection to fire successfully and for connected functions to receive the signal)
	for i, conn in pairs(self.misc.eventConnections) do
		if tick() - tickRecordBegin > budget then tickRecordBegin = tick(); task.wait() end
		self:removeConnection(i)
	end
	for i, _ in pairs(self.plugins) do
		if tick() - tickRecordBegin > budget then tickRecordBegin = tick(); task.wait() end
		self:unloadPlugin(i)
	end
	for _, eventObj in pairs(self.misc.eventObjects) do
		if tick() - tickRecordBegin > budget then tickRecordBegin = tick(); task.wait() end
		eventObj:Destroy()
	end
	local instance = self.instance
	coroutine.wrap(function()
		task.wait(self.settings and self.settings.anim.primary.Time*0.25)
		if instance then
			instance:Destroy()
		end
	end)()
	for k in pairs(self) do
		self[k] = nil
	end
	pcall(function()
		self.__mode = "kv"
		setmetatable(self, nil)
		table.clear(self)
		table.freeze(self)
	end)
	return nil
end

--gets a theme object
function module.getTheme(objectName:string, theme:string|nil)
	if not objectName then error("Object name is nil") end

	local defaultTheme = module.settings.themes:FindFirstChild(module.settings.defaultTheme)
	if not defaultTheme then error("Default theme is nil") end

	local targetTheme = module.settings.themes:FindFirstChild(tostring(theme))
	if not targetTheme then
		local themes = {}
		for i, v in pairs(module.settings.themes:GetChildren()) do
			local name = v.Name
			themes[name] = name
		end
		local potentialString, percent = compareStrings.suggestString(themes, theme)
		if not targetTheme and potentialString ~= theme then warn("Theme does not exist:", theme, "-> Did you mean: "..potentialString.."? ("..tostring(percent).."% match)") end

		targetTheme = module.settings.themes:FindFirstChild(potentialString)
		if not targetTheme then
			warn("Theme does not exist:", theme)
			targetTheme = defaultTheme
		end
	end

	local object
	local function findObject(themeFolder)
		local objectMap = themeFolder:FindFirstChild(module.settings.themeObjectMapId)
		if objectMap then --prioritize the object map since it's way more predictable
			local map = require(objectMap)
			object = map[objectName]
			map = nil
		else
			object = themeFolder:FindFirstChild(objectName) or defaultTheme:FindFirstChild(objectName)
		end
	end

	findObject(targetTheme)

	if not object then
		--warn("Object \""..objectName.."\" does not exist in theme:", theme)
		findObject(defaultTheme)
	end

	if not object then error("Invalid object: "..objectName) end

	return object
end

--sets the alternate cursor
function module.altCursor(active:boolean, theme:string?)
	if active == nil then
		active = not altCursorUpdater
	end

	UserInputService.MouseIconEnabled = not active
	
	local function destroyCursor()
		if altCursorInstance then altCursorInstance:Destroy() end
		if altCursorUpdater then altCursorUpdater:Disconnect() end
		if altCursorZIndexUpdater then altCursorZIndexUpdater:Disconnect() end
		if altCursorDisconnectUpdater then altCursorDisconnectUpdater:Disconnect() end
	end
	
	destroyCursor()
	if not (active and not UserInputService.TouchEnabled) then
		return
	end
	
	local selfWindow = module.findWindow(#module.space)
	local selfInstance = selfWindow.instance
	if not selfInstance then return end

	local function updateZIndex()
		altCursorInstance.ZIndex = selfInstance.ZIndex+1
	end

	altCursorInstance = module.getTheme("AltCursor", theme and theme or selfWindow.theme):Clone(); altCursorInstance.Parent = selfInstance.Parent; updateZIndex()
	altCursorZIndexUpdater = selfInstance:GetPropertyChangedSignal("ZIndex"):Connect(updateZIndex)
	altCursorUpdater = RunService.PreRender:Connect(function()
		if not (selfWindow and selfWindow.settings) then destroyCursor() return end
		local mouse = selfWindow:getSpecialMouse()
		
		local parent = selfInstance.Parent
		if not parent then return end
		
		local relativePos = Vector2.new(mouse.X,mouse.Y) - parent.AbsolutePosition
		altCursorInstance.Position = UDim2.fromOffset(relativePos.X,relativePos.Y)
	end)
	altCursorDisconnectUpdater = selfInstance.Destroying:Once(destroyCursor)
end

--core

--spawn a new blank window object
--@param theme: the theme to use for this window
function module.new(theme:string|nil) --construct a new window
	local self = setmetatable({}, module.baseWindow)
	
	--initialize variables
	self.theme = theme and theme or module.settings.defaultTheme
	
	--get a specified object with the related theme
	--brute-force changing themes for an existing window is not recommended since we'll need to recreate the entire window
	--@param objectName: the name of the target object
	--@param theme: the name of the theme
	function self:getTheme(objectName:string, theme:string|nil)
		return module.getTheme(objectName, theme and theme or self.theme)
	end
	
	self.pointConverter = pointConverter
	
	--deepcopies a table and returns the copy
	--@param t: the table to deepcopy
	function self.deepCopyTable(t:{any})
		local copy = {}
		for key, value in pairs(t) do
			copy[key] = type(value) == "table" and self.deepCopyTable(value) or value
		end
		return copy
	end
	
	if not module.screen then
		local screen = self:getTheme("Base_Screen"):Clone()
		screen.Parent = module.settings.player.PlayerGui
		module.screen = screen
	end
	
	self.id = module:genId()
	
	local base:CanvasGroup = self:getTheme("Base_Window"):Clone()
	base.Name = self.id
	base.Parent = module.screen
	
	self.settings = module.settings
	self.instance = base::CanvasGroup
	self.subInstance = base:FindFirstChild("UniqueElements")::Folder
	self.canvas = base:FindFirstChild("WindowContent")::Frame
	self.plugins = {}
	self.events = {}::{RBXScriptSignal}
	self.misc = {
		eventObjects = {}::{BindableEvent},
		eventConnections = {}::{RBXScriptConnection}
	}
	
	self.haptics = self.settings.hapticManager
	
	--used for both the maximized state and last known good size and position
	self.lastKnownGoodSize = nil
	self.lastKnownGoodPosition = nil
	
	local function setupCopy() --fixes autocomplete breaking when deepcopy is directly called
		self.settings = self.deepCopyTable(self.settings)
	end
	setupCopy()
	
	--return the origin window
	local function returnWindow()
		return self --module.findWindow(self.instance.ZIndex)
	end
	
	--quickly create a new window
	--@param content: the window content
	--@param size: the window size
	function self:create(content:GuiBase, size:UDim2|any, theme:string|nil)
		local targetContent = self.canvas:FindFirstChildWhichIsA("GuiBase")
		local absSize = self.canvas.AbsoluteSize
		local newWindow = module:create(content or (targetContent and targetContent:Clone()), size or UDim2.fromOffset(absSize.X,absSize.Y), theme or self.theme):setParent(self.instance.Parent)
		newWindow.returnWindow = returnWindow
		return newWindow
	end
	
	--@param instance: instance to parent the window into
	function self:setParent(instance:Instance)
		base.Parent = instance
		return self
	end
	
	--@param instance: instance to add into the contents of this window
	function self:addContent(instance:GuiBase)
		if not instance then return self end
		instance.Parent = self.canvas
		return self
	end
	
	--@param pluginName: plugin name
	function self:checkPlugin(pluginName:string)
		return self.plugins[pluginName]
	end
	
	--@param pluginName: plugin name
	--@param returnPlugin: return plugin instead of the window or not
	function self:loadPlugin(pluginName:string, returnPlugin:boolean|nil)
		if not hasSetupPlugins then module.setupPlugins() end
		
		if self:checkPlugin(pluginName) then warn("Plugin already exists: "..pluginName) return self end
		local plug = module.plugins[pluginName]
		if not plug then
			warn("Plugin not found: "..pluginName)
			return self
		end

		--initialize the plugin with the window instance
		pcall(function()
			plug.init(self)
		end)
		
		--store the plugin
		self.plugins[pluginName] = plug
		
		if plug[self.id] then
			plug[self.id].returnWindow = returnWindow
			if returnPlugin then
				return plug[self.id]
			end
		else
			if returnPlugin then
				warn("Plugin did not return index window id: "..self.id..": "..pluginName)
			end
		end
		return self
	end

	--@param pluginName: plugin name
	function self:getPlugin(pluginName:string)
		local plug = self:checkPlugin(pluginName, true)
		if not plug then warn("Invalid plugin name or plugin has not been loaded yet: "..pluginName) return end
		local bplug = plug[self.id]
		if not bplug then warn("Plugin does not have window id: "..self.id..": "..pluginName) return end
		return bplug
	end

	--@param pluginName: plugin name
	function self:unloadPlugin(pluginName:string)
		local plug = self:checkPlugin(pluginName)
		local quitFunc = plug and plug.quit
		if quitFunc then
			quitFunc(self)
			self.plugins[pluginName] = nil
		end
		return self
	end
	
	--@param pluginName: plugin name
	function self:reloadPlugin(pluginName:string)
		self:unloadPlugin(pluginName)
		self:loadPlugin(pluginName)
		return self
	end
	
	--@param id: string id of the connection
	--@param connection: RBXScriptConnection
	function self:addConnection(connection:RBXScriptConnection, id:string|nil)
		local count = 0
		for _ in pairs(self.misc.eventConnections) do
			count+=1
		end
		self.misc.eventConnections[id or "unnamedConnection_index"..count] = connection
		return self
	end

	--@param id: string id of the connection
	function self:removeConnection(id:string)
		if not self.misc.eventConnections[id] then return self end
		self.misc.eventConnections[id]:Disconnect()
		self.misc.eventConnections[id] = nil
		return self
	end

	--@param func: function to call via task.spawn which will also include self
	--@param ...: ...any
	function self:call(func:(any), ...)
		local args = table.pack(...)
		task.spawn(function()
			func(self, table.unpack(args))
		end)
		return self
	end
	
	--@param func: function to call via task.spawn which will also include self
	--@param ...: ...any
	function self:pcall(func:(any), ...)
		local args = table.pack(...)
		local success, msg = pcall(function()
			func(self, table.unpack(args))
		end)
		if not success then warn(script:GetFullName().." - pcall unsuccessfull:", msg) end
		return self
	end

	--@param eventId: event id to bind
	--@param call: function to call
	--@param id: more specific event id to unbind
	function self:bindEvent(eventId:string, call:(any), id:string|nil)
		self.misc.eventConnections[id or if typeof(eventId) == "string" then eventId..tostring(#self.misc.eventConnections) else eventId] = self.events[eventId]:Connect(function(self2, ...)
			self:pcall(call, self2, ...)
		end)
		return self
	end

	--@param id: event id to unbind
	function self:unbindEvent(id)
		self:removeConnection(id)
		return self
	end

	--@param eventId: event id to add
	function self:addEvent(eventId:string)
		if self.misc.eventObjects[eventId] then return self end

		local event = Instance.new("BindableEvent")
		self.misc.eventObjects[eventId] = event
		self.events[eventId] = event.Event
		return self
	end

	--@param eventId: event id to remove
	function self:removeEvent(eventId:string)
		if not self.misc.eventObjects[eventId] then return self end
		self.events[eventId] = nil
		self.misc.eventObjects[eventId]:Destroy()
		self.misc.eventObjects[eventId] = nil
		return self
	end

	--@param eventId: event id to fire
	--@param ...: ...any
	function self:fireEvent(eventId:string, ...)
		if not self.misc.eventObjects[eventId] then return self end
		self.misc.eventObjects[eventId]:Fire(self, ...)
		return self
	end

	--@param path: path to the target property
	--@param value: value to set the property to
	function self:modifySelf(path:string, value:any)
		local paths = string.split(path, ".") or string.split(path, "/") or string.split(path, " ")

		local d = self
		local dx = d
		for i = 1, #paths - 1 do
			dx = dx[paths[i]]
			if not dx then warn("invalid path: \""..path.."\"") return self end
		end
		local lastKey = paths[#paths]
		if dx[lastKey] == nil and value ~= nil then warn("invalid path: \""..path.."\"") return self end
		dx[lastKey] = value
		self = d
		return self
	end
	
	--get the window's canvas offset
	function self:getContentOffset()
		return (-(self.canvas.AbsoluteSize - self.instance.AbsoluteSize) + self.settings.offsets.contentOffset)::Vector2
	end

	--@param propertyTable: table of properties to set "window.instance" to
	--@param scaleFitContentOffset: whether to scale window canvas instead of the entire window (header offset, etc.)
	function self:snap(propertyTable:{any: any}, scaleFitContentOffset:boolean|nil)
		if scaleFitContentOffset and propertyTable["Size"] then
			local offset = self:getContentOffset()
			propertyTable["Size"] += UDim2.new(0,offset.X,0,offset.Y)
		end
		for i, v in pairs(propertyTable) do
			self.instance[i] = v
		end
		return self
	end

	--@param instance: self or instance to spring
	--@param tweenInfo: TweenInfo
	--@param propertyTable: table of properties to set "window.instance" to
	--@param call: function to call when the tween completes
	--@param scaleFitContentOffset: whether to scale window canvas instead of the entire window (header offset, etc.)
	function self.tween(instance:Instance|{[string]:any}, tweenInfo:TweenInfo, propertyTable:{any: any}, call:(any)|any, scaleFitContentOffset:boolean|nil)
		if typeof(instance) == "table" and instance["instance"] then instance = instance["instance"] end
		if scaleFitContentOffset and propertyTable["Size"] then
			local offset = self:getContentOffset()
			propertyTable["Size"] += UDim2.new(0,offset.X,0,offset.Y)
		end
		local tween = TweenService:Create(
			instance,
			tweenInfo,
			propertyTable
		); tween:Play(); tween.Completed:Once(function()
			if call and self and self.call then self:call(call) end
		end)
		return self
	end
	
	--creates a new spring info
	--@param bounces: amount of bounces
	--@param duration: duration
	function self.springInfo(duration:number?, bounces:number?)
		return self.settings.spring.springInfo(duration, bounces)
	end
	
	--springs an instance
	--@param instance: self or instance to spring
	--@param springInfo: springInfo
	--@param propertyTable: table of properties to apply to the instance
	--@param call: function to call when the tween completes
	--@param scaleFitContentOffset: whether to scale window canvas instead of the entire window (header offset, etc.)
	function self.spring(instance:Instance|{[string]:any}, springInfo:{["duration"]:number,["bounces"]:number}, propertyTable:{any: any}, call:(any)|any, scaleFitContentOffset:boolean|nil)
		if not next(propertyTable) then error(`property table is empty!`) return self end
		if typeof(instance) == "table" and instance["instance"] then instance = instance["instance"] end
		if scaleFitContentOffset and propertyTable["Size"] then
			local offset = self:getContentOffset()
			propertyTable["Size"] += UDim2.new(0,offset.X,0,offset.Y)
		end
		local spring = self.settings.spring.tween(
			instance,
			springInfo,
			propertyTable
		); spring.getCompletedSignal(next(propertyTable)):Once(function()
			if call and self and self.call then self:call(call) end
		end)
		return self
	end

	self:addEvent("destroying")
	function self:destroy()
		return module.destroyWindow(self and self.id)
	end
	
	self:addEvent("focus")
	function self:focus()
		coroutine.wrap(function()
			local selfIndex = table.find(module.space, self)
			if selfIndex then table.remove(module.space, selfIndex) end
			table.insert(module.space, self)

			--self.instance.ZIndex = #module.space + 1
			self:fireEvent("focus")
			
			if #module.space == self.instance.ZIndex then return end

			local tickRecordBegin = tick()
			local budget = self.settings and self.settings.executionTimeBudget or 1/60
			for i, v in ipairs(module.space) do
				if tick() - tickRecordBegin > budget then tickRecordBegin = tick(); task.wait() end
				local v_instance = v.instance
				if not v_instance then continue end
				v_instance.ZIndex = i
				if i == #module.space then continue end
				v:unfocus()
			end
		end)()
		return self
	end
	
	self:addEvent("unfocus")
	function self:unfocus()
		self:fireEvent("unfocus")
		return self
	end
	
	self:addEvent("minimized")
	function self:minimize()
		self:fireEvent("minimized")
		local sizeConstraint = self.instance:FindFirstChildWhichIsA("UISizeConstraint")
		
		self.haptics.impact(0.65, 10, Enum.VibrationMotor.Large)
		
		local containerAbsSize = self.instance.Parent.AbsoluteSize
		local containerAbsPos = self.instance.Parent.AbsolutePosition

		local absSize = self.instance.AbsoluteSize
		local absPos = self.instance.AbsolutePosition
		local anchor = self.instance.AnchorPoint
		
		local relativePos = absPos + absSize*anchor - containerAbsPos

		local targetSize = Vector2.new(absSize.X, sizeConstraint and sizeConstraint.MinSize.Y or 30)
		local targetPos = Vector2.new(relativePos.X, -targetSize.Y*(1-anchor.Y))

		--self:tween(self.settings.anim.tertiary, {Size = UDim2.fromOffset(targetSize.X,targetSize.Y), Position = UDim2.new(relativePos.X/containerAbsSize.X,0,1,targetPos.Y)})
		self:spring(self.settings.springTypes.fifternary, {Size = UDim2.fromOffset(targetSize.X,targetSize.Y)})
		self:spring(self.settings.springTypes.quaternary, {Position = UDim2.new(relativePos.X/containerAbsSize.X,0,1,targetPos.Y)})
		return self
	end
	
	self:addEvent("maximized")
	function self:maximize()
		self:fireEvent("maximized")
		local sizeConstraint = self.instance:FindFirstChildWhichIsA("UISizeConstraint")::UISizeConstraint
		
		self.haptics.impact(1, 5, Enum.VibrationMotor.Large)

		local containerAbsSize = self.instance.Parent.AbsoluteSize
		local anchor = self.instance.AnchorPoint
		
		local targetSize, targetPos
		
		local s_sinfo, p_sinfo
		if self.lastKnownGoodSize or self.lastKnownGoodPosition then
			local ls = self.lastKnownGoodSize
			local lp = self.lastKnownGoodPosition + (ls * anchor)
			
			self.lastKnownGoodSize = nil
			self.lastKnownGoodPosition = nil
			
			targetSize = (ls and UDim2.fromOffset(ls.X, ls.Y) or Vector2.zero)
			targetPos = (lp and UDim2.fromOffset(lp.X, lp.Y) or Vector2.zero)
			
			s_sinfo, p_sinfo = self.settings.springTypes.quaternary, self.settings.springTypes.fifternary
		else
			self.lastKnownGoodSize = self.instance.AbsoluteSize
			self.lastKnownGoodPosition = self.instance.AbsolutePosition
			
			targetSize = UDim2.fromScale(
				(containerAbsSize.X > sizeConstraint.MaxSize.X and sizeConstraint.MaxSize.X or containerAbsSize.X) / containerAbsSize.X,
				containerAbsSize.Y > sizeConstraint.MaxSize.Y and sizeConstraint.MaxSize.Y or containerAbsSize.Y / containerAbsSize.Y
			)
			targetPos = UDim2.fromScale(anchor.X, anchor.Y)
			
			s_sinfo, p_sinfo = self.settings.springTypes.fifternary, self.settings.springTypes.quaternary
		end
		
		self:spring(s_sinfo, {Size = targetSize})
		self:spring(p_sinfo, {Position = targetPos})
		return self
	end
	
	function self:isOnTop()
		return module.findWindow(#module.space).id == self.id
	end
	
	--checks whether if an input is a gamepad and returns its gamepad index
	--@param inputObject: InputObject
	function self.isInputGamepad(inputObject:InputObject)
		local isGamepad
		local typeCache = inputObject.UserInputType
		
		for i = 1, 8, 1 do
			if typeCache == Enum.UserInputType["Gamepad"..i] then isGamepad = i; break end
		end
		return isGamepad
	end
	
	self.mouse = self.settings.player:GetMouse()
	
	--sets the alternate cursor
	--@param active: whether if it's going to be active or not
	function self:altCursor(active:boolean)
		module.altCursor(active, self.theme)
	end
	
	--get the current special mouse properties of a mouse or touch input object
	--@param inputObject: InputObject
	function self:getSpecialMouse(inputObject:InputObject|nil)
		local realMouse = self.mouse
		
		local constructMouse = { --copy the entire thing
			InputObject = inputObject,
			Hit = realMouse.Hit,
			Origin = realMouse.Origin,
			Target = realMouse.Target,
			TargetSurface = realMouse.TargetSurface,
			UnitRay = realMouse.UnitRay,
			X = realMouse.X,
			Y = realMouse.Y,

			Button1Down = realMouse.Button1Down,
			Button1Up = realMouse.Button1Up,
			Button2Down = realMouse.Button2Down,
			Button2Up = realMouse.Button2Up,
			Idle = realMouse.Idle,
			Move = realMouse.Move,
			WheelBackward = realMouse.WheelBackward,
			WheelForward = realMouse.WheelForward
		}
		
		if inputObject and inputObject.UserInputType == Enum.UserInputType.Touch then
			constructMouse.X = inputObject.Position.X
			constructMouse.Y = inputObject.Position.Y

			local ray = workspace.CurrentCamera:ScreenPointToRay(inputObject.Position.X, inputObject.Position.Y)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = {realMouse.TargetFilter, self.settings.player.Character, workspace.Camera}
			local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

			constructMouse.Hit =  raycastResult
			constructMouse.Origin = ray.Origin
			constructMouse.Target = raycastResult and raycastResult.Instance or nil
			constructMouse.UnitRay = ray
		end
		
		local surfaceGui = self.instance:FindFirstAncestorWhichIsA("SurfaceGui")
		if surfaceGui then
			local converted = self.pointConverter.SurfaceGui(surfaceGui, constructMouse)

			constructMouse.X = converted.X
			constructMouse.Y = converted.Y
		end
		
		return constructMouse
	end
	
	--snaps the value of X to grid with defined cell size
	--@param cellSize: number
	--@param ...: number
	function self.snapXToGrid(cellSize:number, ...)
		local result = {}
		for i, x in pairs({...}) do
			local snapped = math.round(x/cellSize)*cellSize
			table.insert(result, snapped == snapped and snapped or x)
		end
		return table.unpack(result)
	end
	
	--checks whether if a server is available
	--@param errors: if it throws an error or not
	function self:checkServer(errors:boolean)
		local timeout = 30
		local isAvailable
		coroutine.wrap(function()
			isAvailable = self.settings.data.QUERY_AVAILABILITY:InvokeServer()
		end)()
		
		local elapsed = 0
		repeat
			elapsed+=RunService.PreRender:Wait()
			if isAvailable then break end
		until elapsed > timeout
		
		if errors and not isAvailable then error("No server available. Insert a server script which requires this module.") end
		return isAvailable
	end
	
	--posts some data to the server version of an app or a plugin
	--@param origin: the origin module
	--@param ...: any
	function self:postServer(origin:ModuleScript, ...)
		self:checkServer(true)
		self.settings.data.POST:FireServer(origin, ...)
		return self
	end
	
	--gets data from the server at the specified path
	--@param ...: keys as strings or as a single string; ("path1/path2/path3") or ("path1", "path2", "path3")
	function self:getServer(...:any|string)
		self:checkServer(true)
		return self.settings.data.GET:InvokeServer(...)
	end
	
	--gets data from the server which involves http requests
	--[CAUTION] do not trust the client
	--@param origin: the origin module
	--@param ...: any
	function self:getHttpServer(origin:ModuleScript, ...)
		self:checkServer(true)
		return self.settings.data.HTTP.GET:InvokeServer(origin, ...)
	end
	
	--returns an event which you can connect functions to (fires on each data change)
	function self:listenServer()
		self:checkServer(true)
		return self.settings.data.LISTEN.OnClientEvent
	end
	
	--destroy along base
	self:addConnection(base.Destroying:Once(function()
		if not self then return end
		self:destroy()
	end))
	
	--finalize
	coroutine.wrap(function()
		task.wait()
		windowCreatedEvent:Fire(self.id)
	end)()
	self:focus()
	
	return self
end

function module:createLegacy(content:GuiBase, size:UDim2|any)
	return module.legacy:create(content, size)
end

--quickly create a new window
--@param content: the window content
--@param size: the window size
function module:create(content:GuiBase|nil, size:UDim2|nil, theme:string|nil)
	local window = module.new(theme)
		:loadPlugin("Resize")
		:loadPlugin("FrostedGlass")
		:loadPlugin("Adapt")
		:loadPlugin("Logs")
		:loadPlugin("Header")
		
	window:snap({Size = size or UDim2.new(0,0,0,0), Position = if size then UDim2.new(0.5,0,0.5,0) else UDim2.new(0.5,0,0.1,0)}, true)
		:loadPlugin("BaseWindow")
	
	--magically fix autocomplete by separating uncertainties
	window:getPlugin("Header"):setLabel(content and content.Name or "Label"):returnWindow()
		:addContent(content) --inserting the content should be at the end to prevent the content from erroring out when trying to access unloaded plugins
	
	return window
end

--launch an app from the Apps folder
--@param appName: the app's name
--@param theme: the theme of the window
--@param ...: any (input to pass into the app)
function module:launchApp(appName:string, theme:string|nil, ...)
	local isModule = typeof(appName) == "Instance" and appName:IsA("ModuleScript")
	appName = tostring(appName)
	
	local window = module:create(nil, UDim2.new(0.5,0,0.5,0), theme)
	local header = window:getPlugin("Header")
		:setLabel(appName)
	
	local appFile = isModule and appName or module.settings.apps:FindFirstChild(appName)
	if not appFile then warn("Application does not exist: ", appName) end
	
	local app = require(appFile)
	if typeof(app) ~= "function" then
		window:destroy()
		error(`App module [{appName}] did not return an init function!`)
	end
	
	return app(window, ...) or window
end

if not RunService:IsServer() then
	module.settings.data.LISTEN.OnClientEvent:Connect(function(vdata)
		module.localData = vdata
	end)
	return module
else
	return require(module.settings.server)
end

--[[
with this module, you can do something cool like this:
```
local window = Windows.new() --create a new window using manual creation
	:loadPlugin("BaseWindow") --load the plugin "BaseWindow"
	:loadPlugin("Header") --load the plugin "Header"
	:getPlugin("Header") --get the plugin "Header" and transition to utilizing it, which is NOT the window
	:addHeaderButton("Among", function() print("among") end) --add a header button using one of the plugin methods
	:returnWindow() --return back to the window object
	:call(function() print("returned") end) --call a function using the window object to confirm that we're back
```



to modify things inside of plugins, you can do something like:
```
local window = Windows:create(...)

local logsPlugin = window:getPlugin("Logs")
logsPlugin.exitButtonBehavor = 2
```

]]
