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
  ["Discord"] = {
    key = "d",
  },
  ["Finder"] = {
    key = "f",
    image = "/System/Library/CoreServices/Dock.app/Contents/Resources/finder@2x.png",
  },
  ["Obsidian"] = {
    key = "o",
  },
  ["Slack"] = {
    key = "s",
  },
  ["Visual Studio Code - Insiders"] = {
    key = "v",
  }
}

local hyper = {'shift', 'ctrl', 'alt', 'cmd'}

-- https://github.com/jasonrudolph/keyboard/blob/main/hammerspoon/hyper.lua
local choices = {}
for name, app in pairs(hyperModeAppMappings) do
  local key = app.key
  hs.hotkey.bind(hyper, key, function()
    if (type(app) == 'string') then
      hs.application.open(name)
    elseif (type(app) == 'function') then
      app()
    else
      hs.logger.new('hyper'):e('Invalid mapping for Hyper +', key)
    end
  end)


  local image
  if app.image then
    image = hs.image.imageFromPath(app.image)
  else
    image = hs.image.iconForFile("/Applications/"..name..".app")
  end

  local choice = {
    text = name,
    subText = "✧"..key,
    -- TODO track down finder
    image = image,
    -- make sure the application name is available, so we don't have to try to figure out later if the name is in the text or subText
    application = name,
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