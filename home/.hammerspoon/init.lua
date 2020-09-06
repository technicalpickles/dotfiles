require("hs.ipc")
hs.ipc.cliInstall()

hs.loadSpoon('ControlEscape'):start() -- Load Hammerspoon bits from https://github.com/jasonrudolph/ControlEscape.spoon

hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  hs.alert.show("Hello World!")
end)


builtinDisplayUUid = '6181C699-AA52-3121-0329-525DB9D7B278'
deskThunderboltDisplayUUID = 'D8F4FDE2-0EA9-67C9-D3EF-BD33B72FD6B1'

screenWatcher = hs.screen.watcher.newWithActiveScreen(function(screenLayoutChange)
	-- nil means screen layout change
	local screenLayoutChange = screenLayoutChange == nil
	if screenLayoutChange then
		local thunderboltDisplay = hs.screen.find(deskThunderboltDisplayUUID)
		if thunderboltDisplay then
			local builtinDisplay = hs.screen.find(builtinDisplayUUid)
			builtinDisplay:setBrightness(1)
			hs.alert.show("Set laptop brightness to 100%")
		end
	end
end)
screenWatcher:start()
