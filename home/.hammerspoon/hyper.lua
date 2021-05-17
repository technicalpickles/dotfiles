-- https://github.com/jasonrudolph/keyboard/blob/main/hammerspoon/hyper-apps-defaults.lua
hyperModeAppMappings = {
  { 'd', 'Discord' },
  { 'f', 'Finder' },
  { 'o', 'Obsidian' },
  { 'p', 'PS Remote Play' },
  { 's', 'Slack' },
  { 'v', 'Visual Studio Code - Insiders' },
}

-- https://github.com/jasonrudolph/keyboard/blob/main/hammerspoon/hyper.lua
for i, mapping in ipairs(hyperModeAppMappings) do
  local key = mapping[1]
  local app = mapping[2]
  hs.hotkey.bind({'shift', 'ctrl', 'alt', 'cmd'}, key, function()
    if (type(app) == 'string') then
      hs.application.open(app)
    elseif (type(app) == 'function') then
      app()
    else
      hs.logger.new('hyper'):e('Invalid mapping for Hyper +', key)
    end
  end)
end