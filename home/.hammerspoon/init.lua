hs.loadSpoon('ControlEscape'):start() -- Load Hammerspoon bits from https://github.com/jasonrudolph/ControlEscape.spoo



-- require("hs.ipc")
-- require("hs.application")
-- require("hs.screen")

-- hs.ipc.cliInstall()


-- package.path = package.path .. ';/usr/local/opt/lua@5.3/share/lua/5.3/?.lua'

-- require("luarocks.loader")
-- inspect = require('inspect')


-- n

-- hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
--   hs.alert.show("Hello World!")
-- end)


-- builtinDisplayUUid = '6181C699-AA52-3121-0329-525DB9D7B278'
-- deskThunderboltDisplayUUID = 'D8F4FDE2-0EA9-67C9-D3EF-BD33B72FD6B1'

-- screenWatcher = hs.screen.watcher.newWithActiveScreen(function(screenLayoutChange)
-- 	-- nil means screen layout change
-- 	local screenLayoutChange = screenLayoutChange == nil
-- 	if screenLayoutChange then
-- 		local thunderboltDisplay = hs.screen.find(deskThunderboltDisplayUUID)
-- 		if thunderboltDisplay then
-- 			local builtinDisplay = hs.screen.find(builtinDisplayUUid)
-- 			builtinDisplay:setBrightness(1)
-- 			hs.alert.show("Set laptop brightness to 100%")
-- 		end
-- 	end
-- end)
-- screenWatcher:start()

-- function relocateMacbreakzActivityWindow()
--   local app = hs.application.get("net.publicspace.mb5")
--   app:activate()
  

--   local activityWindow = app:focusedWindow()
--   local screen = hs.screen.primaryScreen()
--   local frame = activityWindow:frame()
--   local max = screen:fullFrame()
  
--   local cornerPoint = hs.geometry.point(max.x, max.y)
--   local corner = screen:localToAbsolute()
  
--   -- reminder: 0,0 is top left
--   frame.x = max.x
--   frame.y = max.y
--   activityWindow:setFrame(frame)
-- end
 
--  -- relocateMacbreakzActivityWindow()

