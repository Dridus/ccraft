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
  os.queueEvent("start")
  while true do
    local event, p1, p2, p3, p4 = os.pullEvent()
    local inventory = readInventory()
    local reactants = readReactants()
    updateDisplay(inventory, reactants)
    os.startTimer(1)
  end
end

function readReactants()
  return {}
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

function updateDisplay(inventory, reactants)
  local y = 1
  monitor.clear()
  monitor.setCursorPos(1,y); y = y + 1
  monitor.write("BRM " .. hostname .. " (" .. tostring(os.getComputerID) .. ")")

  monitor.setCursorPos(1,y); y = y + 1
  monitor.write("---------------")

  function tern (b)
    if b then return "|" else return " " end
  end

  monitor.setCursorPos(1,y); y = y + 1
  monitor.write("Inv: S " .. tern(inventory.seed1)
                          .. tern(inventory.seed2)
                          .. tern(inventory.seed3) .. " "
             .. "C " .. tern(inventory.carrot) .. " "
             .. "P " .. tern(inventory.potato))
end

main()

