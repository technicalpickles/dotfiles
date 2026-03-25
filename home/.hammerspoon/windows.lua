-- Window management with cycling sizes, replicating Rectangle's repeated-key behavior

hs.window.animationDuration = 0  -- disable window move/resize animations

local cycleSizes = {
  left = {
    { x = 0,     y = 0, w = 0.5, h = 1 },  -- half
    { x = 0,     y = 0, w = 1/3, h = 1 },  -- third
    { x = 0,     y = 0, w = 2/3, h = 1 },  -- two-thirds
  },
  right = {
    { x = 0.5,   y = 0, w = 0.5, h = 1 },  -- half
    { x = 2/3,   y = 0, w = 1/3, h = 1 },  -- third
    { x = 1/3,   y = 0, w = 2/3, h = 1 },  -- two-thirds
  },
  up = {
    { x = 0, y = 0,   w = 1, h = 0.5 },    -- top half
    { x = 0, y = 0,   w = 1, h = 1/3 },    -- top third
    { x = 0, y = 0,   w = 1, h = 2/3 },    -- top two-thirds
  },
  down = {
    { x = 0, y = 0.5, w = 1, h = 0.5 },    -- bottom half
    { x = 0, y = 2/3, w = 1, h = 1/3 },    -- bottom third
    { x = 0, y = 1/3, w = 1, h = 2/3 },    -- bottom two-thirds
  },
}

local state = {}
local CYCLE_TIMEOUT = 1.5  -- seconds before resetting cycle

local function cycleWindow(direction)
  local win = hs.window.focusedWindow()
  if not win then return end

  local screen = win:screen():frame()
  local s = state[direction] or { step = 0, time = 0 }
  local now = hs.timer.secondsSinceEpoch()

  if now - s.time > CYCLE_TIMEOUT then
    s.step = 0
  end

  local sizes = cycleSizes[direction]
  local size = sizes[(s.step % #sizes) + 1]

  win:setFrame({
    x = screen.x + size.x * screen.w,
    y = screen.y + size.y * screen.h,
    w = size.w * screen.w,
    h = size.h * screen.h,
  })

  state[direction] = { step = s.step + 1, time = now }
end

hs.hotkey.bind({ 'ctrl', 'alt' }, 'left',  function() cycleWindow('left')  end)
hs.hotkey.bind({ 'ctrl', 'alt' }, 'right', function() cycleWindow('right') end)
hs.hotkey.bind({ 'ctrl', 'alt' }, 'up',    function() cycleWindow('up')    end)
hs.hotkey.bind({ 'ctrl', 'alt' }, 'down',  function() cycleWindow('down')  end)

local savedFrames = {}

hs.hotkey.bind({ 'ctrl', 'alt' }, 'return', function()
  local win = hs.window.focusedWindow()
  if not win then return end

  local id = win:id()
  local screen = win:screen():frame()
  local current = win:frame()

  if savedFrames[id] then
    win:setFrame(savedFrames[id])
    savedFrames[id] = nil
  else
    savedFrames[id] = current
    win:setFrame(screen)
  end
end)
