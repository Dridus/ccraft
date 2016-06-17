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
monitor.write("Bioreactor monitor\n")

rednet.open(rednetSide)
rednet.host("brm", hostname)

monitor.write("Rednet open: " .. os.getComputerID() .. "\n")

local bioreactors = {}
for side in bioreactorSides do
  local bioreactor = peripheral.wrap(side)
  if bioreactor == nil then
    monitor.write("Bioreactor " .. side .. " missing!\n")
  else
    monitor.write("Bioreactor " .. side .. " found.\n")
  end
  bioreactors[side] = bioreactor
end

for side,reactor in pairs(bioreactors) do
  monitor.write("Disabling " .. side .. "\n")
  redstone.setOutput(side, true)
end

monitor.write("Disabling item feeds\n")
redstone.setBundledOutput(bundleSide, 0)

sleep(5)

function main()
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
  monitor.clear()
  monitor.write("BRM " .. hostname .. " (" .. tostring(os.getComputerID) .. ")")

  monitor.write("---------------\n")

  function tern(b) do
    if b then return "|" else return " " end
  end

  monitor.write("Inv: S " .. tern(inventory.seed1)
                          .. tern(inventory.seed2)
                          .. tern(inventory.seed3) .. " "
             .. "C " .. tern(inventory.carrot) .. " "
             .. "P " .. tern(inventory.potato) .. "\n")
end




