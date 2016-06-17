hostname        = "brm"
monitorSide     = "front"
rednetSide      = "bottom"
bundleSide      = "top"
bioreactorSides = {"left", "back", "right"}
seed1Actuator   = colors.red
seed1Measure    = colors.gray
seed2Actuator   = colors.blue
seed2Measure    = colors.pink
seed3Actuator   = colors.purple
seed3Measure    = colors.lime
potatoColor     = colors.brown
potatoMeasure   = colors.lightGray
carrotColor     = colors.green
carrotMeasure   = colors.cyan

local monitor = peripheral.wrap(monitorSide)
monitor.setTextScale(0.5)
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
redstone.setBundledOutput(bundleSide, 0)

sleep(5)

function main()
  while true do
    local inventory = readInventory()
    local allReactorContents = readAllReactorContents()
    updateDisplay(inventory, allReactorContents)
    sleep(1)
  end
end

function readAllReactorContents()
  local reactants = {}
  for side,reactor in pairs(bioreactors) do
    local q = {}
    local r = {}
    for slot = 1,reactor.getInventorySize() do
      local item = reactor.getStackInSlot(queueSlot)
      if item != nil then
        local id = string.gsub(item.id, "[^:]+:", "")
        local t = nil
        if slot > 9 then
          t = r
        else
          t = q
        end
        local prevQty = q[id]
        if prevQty == nil then prevQty = 0 end
        if item.qty == 64 then q[id] = prevQty + 1 end
      end
    end
    reactants[side] = { queue = q, reactants = r }
  end
  return reactants
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

function updateDisplay(inventory, allReactorContents)
  local y = 1
  monitor.setCursorPos(1,y); y = y + 1
  monitor.setBackgroundColor(colors.gray)
  monitor.clearLine()
  monitor.write(hostname .. " (" .. tostring(os.getComputerID()) .. ")")

  monitor.setBackgroundColor(colors.black)

  function tern (b, s)
    if b then return s else return " " end
  end

  monitor.setCursorPos(1,y); y = y + 1
  monitor.clearLine()
  monitor.write("S " .. tern(inventory.seed1, "1")
                     .. tern(inventory.seed2, "2")
                     .. tern(inventory.seed3, "3") .. " "
             .. "C " .. tern(inventory.carrot, "1") .. " "
             .. "P " .. tern(inventory.potato, "1"))

  monitor.setCursorPos(1,y); y = y + 1
  monitor.write("---------scpSCP")

  for side, reactorContents in pairs(allReactorContents) do
    monitor.setCursorPos(1,y)
    monitor.clearLine()
    monitor.write(side)
    monitor.setCursorPos(9,y)
    monitor.write(tostring(allReactorContents.queue.seed)
               .. tostring(allReactorContents.queue.carrot)
               .. tostring(allReactorContents.queue.potato)
               .. tostring(allReactorContents.reactants.seed)
               .. tostring(allReactorContents.reactants.carrot)
               .. tostring(allReactorContents.reactants.potato))
    y = y + 1
  end
end

main()

