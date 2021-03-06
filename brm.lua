hostname        = "brm"
monitorSide     = "front"
rednetSide      = "bottom"
bundleSide      = "top"
bioreactorSides = {"left", "back", "right"}
seed1Feed       = colors.red
seed1Measure    = colors.gray
seed2Feed       = colors.blue
seed2Measure    = colors.pink
seed3Feed       = colors.purple
seed3Measure    = colors.lime
potatoFeed      = colors.brown
potatoMeasure   = colors.lightGray
carrotFeed      = colors.green
carrotMeasure   = colors.cyan

allFeed = seed1Feed + seed2Feed + seed3Feed + carrotFeed + potatoFeed

ingredients = {"seed", "potato", "carrot"}

local monitor = peripheral.wrap(monitorSide)
monitor.setTextScale(0.5)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.clear()
local y = 1
monitor.setCursorPos(1,y); y = y + 1
monitor.write("BRM host " .. hostname)

rednet.open(rednetSide)
rednet.host("brm", hostname)

local bioreactors = {}
for i = 1,#bioreactorSides do
  local side = bioreactorSides[i]
  local bioreactor = peripheral.wrap(side)
  monitor.setCursorPos(1,y); y = y + 1
  if bioreactor == nil then
    monitor.write("BR " .. side .. " missing!")
  else
    monitor.write("BR " .. side .. " found.")
  end
  bioreactors[side] = bioreactor
end

for side,reactor in pairs(bioreactors) do
  monitor.setCursorPos(1,y); y = y + 1
  monitor.write("Disabling " .. side)
  redstone.setOutput(side, true)
end
monitor.setCursorPos(1,y)
monitor.write("Disabling feeds")
redstone.setBundledOutput(bundleSide, allFeed)

function main()
  monitor.clear()
  while true do
    local inventory = readInventory()
    local allReactorContents = readAllReactorContents()
    local feedStatus = feedReactors(inventory, allReactorContents)
    local activationStatus = activateReactors(allReactorContents)
    updateDisplay(inventory, allReactorContents, feedStatus, activationStatus)
    sleep(1)
  end
end

function readAllReactorContents()
  local arc = {}
  for side,reactor in pairs(bioreactors) do
    local fill = 0
    local q = {seed = 0, carrot = 0, potato = 0}
    local r = {seed = 0, carrot = 0, potato = 0}
    for slot = 1,reactor.getInventorySize() do
      local item = reactor.getStackInSlot(slot)
      if item ~= nil then
        local id = string.gsub(item.id, "[^:]+:", "")
        local t = nil
        if slot > 9 then
          t = r
        else
          t = q
        end
        if item.qty > 0 then fill = fill + 1 end
        if item.qty > 0 then
          if t[id] ~= nil then
            t[id] = t[id] + 1
          end
        end
      end
    end
    arc[side] = { queue = q, reactants = r, fill = fill }
  end
  return arc
end

function readInventory()
  local signal = redstone.getBundledInput(bundleSide)
  local inventory = {}
  inventory.seed1 = colors.test(signal, seed1Measure)
  inventory.seed2 = colors.test(signal, seed2Measure)
  inventory.seed3 = colors.test(signal, seed3Measure)
  inventory.carrot = colors.test(signal, carrotMeasure)
  inventory.potato = colors.test(signal, potatoMeasure)
  return inventory
end

function feedReactors(inventory, allReactorContents)
  local status = {}
  local feed = allFeed
  for side,reactorContents in pairs(allReactorContents) do
    if reactorContents.fill <= 12 then
      status[side] = false

      function tryFeed(ingredient, inventoryType, feedBit)
        if reactorContents.reactants[ingredient] == 0 and inventory[inventoryType] then
          status[side] = true
          feed = colors.subtract(feed, feedBit)
        end
      end

      tryFeed("carrot", "carrot", carrotFeed)
      tryFeed("potato", "potato", potatoFeed)
      tryFeed("seed", "seed1", seed1Feed)
      tryFeed("seed", "seed2", seed2Feed)
      tryFeed("seed", "seed3", seed3Feed)

      if not status[side] then
        if inventory.seed1  then feed = colors.subtract(feed, seed1Feed) end
        if inventory.seed2  then feed = colors.subtract(feed, seed2Feed) end
        if inventory.seed3  then feed = colors.subtract(feed, seed3Feed) end
        if inventory.carrot then feed = colors.subtract(feed, carrotFeed) end
        if inventory.potato then feed = colors.subtract(feed, potatoFeed) end
        status[side] = true
      end
    end
  end
  status.feed = feed
  redstone.setBundledOutput(bundleSide, feed)
  return status
end

function activateReactors(allReactorContents)
  local status = {}
  for side,reactorContents in pairs(allReactorContents) do
    local bestFill = 9 + reactorContents.reactants.seed + reactorContents.reactants.potato + reactorContents.reactants.carrot
    local newState = reactorContents.fill >= bestFill
    redstone.setOutput(side, not newState)
    status[side] = newState
  end
  return status
end

function updateDisplay(inventory, allReactorContents, feedState, activationState)
  local y = 1
  monitor.setTextColor(colors.white)
  monitor.setCursorPos(1,y); y = y + 1
  monitor.setBackgroundColor(colors.lightGray)
  monitor.clearLine()
  monitor.write(hostname .. " (" .. tostring(os.getComputerID()) .. ")")

  monitor.setBackgroundColor(colors.black)

  function tern (b, s)
    if b then return s else return " " end
  end

  monitor.setCursorPos(1,y); y = y + 1
  monitor.setBackgroundColor(colors.gray)
  monitor.clearLine()
  monitor.write("Seed Carr Pota")
  monitor.setCursorPos(1,y)
  monitor.clearLine()
  if colors.test(feedState.feed, seed1Feed) then monitor.setBackgroundColor(colors.red) else monitor.setBackgroundColor(colors.black) end
  monitor.write(tern(inventory.seed1, "1"))
  monitor.setCursorPos(2,y)
  if colors.test(feedState.feed, seed2Feed) then monitor.setBackgroundColor(colors.red) else monitor.setBackgroundColor(colors.black) end
  monitor.write(tern(inventory.seed2, "2"))
  monitor.setCursorPos(3,y)
  if colors.test(feedState.feed, seed3Feed) then monitor.setBackgroundColor(colors.red) else monitor.setBackgroundColor(colors.black) end
  monitor.write(tern(inventory.seed3, "3"))
  monitor.setCursorPos(6,y)
  if colors.test(feedState.feed, carrotFeed) then monitor.setBackgroundColor(colors.red) else monitor.setBackgroundColor(colors.black) end
  monitor.write(tern(inventory.carrot, "1"))
  monitor.setCursorPos(11,y)
  if colors.test(feedState.feed, potatoFeed) then monitor.setBackgroundColor(colors.red) else monitor.setBackgroundColor(colors.black) end
  monitor.write(tern(inventory.potato, "1"))

  y = y + 1

  for side, reactorContents in pairs(allReactorContents) do
    monitor.setCursorPos(1,y)
    monitor.setBackgroundColor(colors.black)
    monitor.clearLine()
    monitor.setTextColor(colors.white)
    monitor.write(string.sub(side,1,1))

    monitor.setTextColor(colors.black)

    if activationState[side] then
      monitor.setBackgroundColor(colors.red)
      monitor.setCursorPos(3,y)
      monitor.write("A")
    end

    if feedState[side] then
      monitor.setBackgroundColor(colors.blue)
      monitor.setCursorPos(4,y)
      monitor.write("F")
    end

    monitor.setCursorPos(6,y)
    monitor.setBackgroundColor(colors.cyan)
    monitor.write(tostring(reactorContents.fill))
    monitor.setBackgroundColor(colors.brown)
    monitor.setCursorPos(9,y)
    monitor.write(tostring(reactorContents.queue.seed))
    monitor.setCursorPos(12,y)
    monitor.write(tostring(reactorContents.reactants.seed))
    monitor.setBackgroundColor(colors.orange)
    monitor.setCursorPos(9,y)
    monitor.setCursorPos(10,y)
    monitor.write(tostring(reactorContents.queue.carrot))
    monitor.setCursorPos(13,y)
    monitor.write(tostring(reactorContents.reactants.carrot))
    monitor.setBackgroundColor(colors.yellow)
    monitor.setCursorPos(11,y)
    monitor.write(tostring(reactorContents.queue.potato))
    monitor.setCursorPos(14,y)
    monitor.write(tostring(reactorContents.reactants.potato))
    y = y + 1
  end
end

main()
