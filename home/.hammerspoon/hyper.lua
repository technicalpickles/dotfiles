local alert    = require("hs.alert")
local chooser  = require("hs.chooser")

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

-- https://github.com/jasonrudolph/keyboard/blob/main/hammerspoon/hyper-apps-defaults.lua
hyperModeAppMappings = {
  d = 'Discord',
  f = 'Finder',
  o = 'Obsidian',
  p = 'PS Remote Play',
  s = 'Slack',
  v = 'Visual Studio Code - Insiders',
}

local hyper = {'shift', 'ctrl', 'alt', 'cmd'}

-- https://github.com/jasonrudolph/keyboard/blob/main/hammerspoon/hyper.lua
for key, app in pairs(hyperModeAppMappings) do
  hs.hotkey.bind(hyper, key, function()
    if (type(app) == 'string') then
      hs.application.open(app)
    elseif (type(app) == 'function') then
      app()
    else
      hs.logger.new('hyper'):e('Invalid mapping for Hyper +', key)
    end
  end)
end

local choices = {}
for key, application in pairs(hyperModeAppMappings) do
  local choice = {
    text = application,
    subText = "✧"..key
    -- TODO track down finder
    image = hs.image.iconForFile("/Applications/"..application..".app")
    -- make sure the application name is available, so we don't have to try to figure out later if the name is in the text or subText
    application = application
  }
  table.insert(choices, choice)
end

local chooser = hs.chooser.new(function(choice)
  chooser:query('')
  if not choice then
    return
  end

  hs.application.open(choice["application"])
end)

chooser:searchSubText(false)
chooser:choices(choices)

hs.hotkey.bind(hyper, 'space', function()
  chooser:show()
end)