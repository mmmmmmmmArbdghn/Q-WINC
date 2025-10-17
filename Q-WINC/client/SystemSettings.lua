local set = {}

set.player = game.Players.LocalPlayer
set.server = script.Parent.Server
set.data = script.Parent.ServerData
set.apps = script.Parent.Apps
set.plugins = script.Parent.Plugins
set.packages = script.Parent.Packages
set.themes  = script.Parent.Themes

set.defaultTheme = "Dark"
set.themeObjectMapId = "_OBJECT_MAP"

set.interpolateWindowContentTriggerFrameTimeDeltaDelta = 0.5 --interpolate window content using EditableImages when changing size if the frame delta time's delta exceeds this, -1 to disable (does nothing for now since editableimages currently have HORRENDOUS performance)
set.executionTimeBudget = (game:GetService("RunService").Heartbeat:Wait() * 0.25) --execution time budget to prevent stuttering (seconds)
set.altCursor = true --show the alternate cursor when interacting with some plugins
set.debug = require(script.Parent.Packages.Debug) --debug
set.hapticManager = require(script.Parent.Packages.HapticManager2) --haptic manager
set.spring = require(script.Parent.Packages.SpringV2) --spring module
set.keyboardUINavMult = 10 --the speed of the keyboard UI navigation
set.predictiveNavPercent = 0.025 --weight percent of predictive navigation to obliterate input lag at the cost of noticeable stutters (set to 0 to disable)
set.compareResolution = Vector2.new(1280, 720) --resolution to compare
set.grid = Vector2.new(0,0) --the grid cell size (set to 0 for no grids), disables predictive navigation if magnitude > 0 since they aren't compatible
set.resample = {
	primarySteps = 1000,
	secondarySteps = 500,
	tertiarySteps = 200,
	quaternarySteps = 100,
}
set.anim = {
	primary = TweenInfo.new(0.325, Enum.EasingStyle.Back),
	secondary = TweenInfo.new(0.325, Enum.EasingStyle.Exponential),
	tertiary = TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
	quaternary = TweenInfo.new(1, Enum.EasingStyle.Bounce),
	ease_fast = TweenInfo.new(0.25, Enum.EasingStyle.Back),
	linear = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
}
set.springTypes = {
	primary = set.spring.springInfo(0.5,2),
	secondary = set.spring.springInfo(1,3),
	tertiary = set.spring.springInfo(1.25,3),
	quaternary = set.spring.springInfo(1,4),
	fifternary = set.spring.springInfo(1.5,4)
}
set.offsets = {
	contentOffset = Vector2.new(0,2)
}
set.transparency = { --window transparency
	active = 0.5,
	inactive = 0.75
}

return set
