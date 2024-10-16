-- Helper function to wrap the modem on the bottom and find the monitor on its network
function findMonitorOnBottomModem()
    local modem = peripheral.wrap("bottom") -- Specify the modem on the "bottom"
    if not modem then
        error("No modem found on the bottom side!")
    end

    -- Get a list of remote peripherals connected through this modem
    local peripherals = modem.getNamesRemote()
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "monitor" then
            return peripheral.wrap(name)
        end
    end

    error("No monitor found on the network connected to the modem on the bottom side!")
end

-- Helper function to wrap the modem and get the turtle's network name
function getTurtleNameFromModem()
    local modem = peripheral.wrap("bottom") -- Assuming the modem is on the bottom of the turtle
    if modem then
        return modem.getNameLocal()
    else
        error("No modem found on the bottom side!")
    end
end

-- Helper function to find peripherals by name pattern
function findInjectors()
    local injectors = {}
    
    for _, name in ipairs(peripheral.getNames()) do
        if string.find(name, "draconicevolution:crafting_injector_") then
            table.insert(injectors, peripheral.wrap(name))
        end
    end

    if #injectors == 8 then
        print("Found 8 crafting injectors.")
    else
        error("Could not find 8 injectors. Found " .. #injectors .. " injectors.")
    end

    return injectors
end

-- Helper function to find the fusion crafting core by name pattern
function findCraftingCore()
    for _, name in ipairs(peripheral.getNames()) do
        if string.find(name, "draconicevolution:fusion_crafting_core_") then
            return peripheral.wrap(name)
        end
    end
    error("Could not find the crafting core on the network!")
end

-- Function to briefly output a redstone signal from the front of the turtle
function triggerRedstoneSignal()
    redstone.setOutput("front", true)
    sleep(0.1) -- Redstone signal active for 0.1 seconds
    redstone.setOutput("front", false)
    print("Redstone signal sent to start crafting process.")
end

-- Helper function to wrap text and center it on the screen
function wrapAndCenterText(text, width)
    local wrappedText = {}
    local currentLine = ""

    for word in text:gmatch("%S+") do
        if #currentLine + #word + 1 > width then
            -- Center the line
            local padding = math.floor((width - #currentLine) / 2)
            currentLine = string.rep(" ", padding) .. currentLine
            table.insert(wrappedText, currentLine)
            currentLine = word
        else
            if #currentLine > 0 then
                currentLine = currentLine .. " " .. word
            else
                currentLine = word
            end
        end
    end

    if #currentLine > 0 then
        local padding = math.floor((width - #currentLine) / 2)
        currentLine = string.rep(" ", padding) .. currentLine
        table.insert(wrappedText, currentLine)
    end

    return wrappedText
end

-- Function to update monitor status with centered text
function updateMonitor(monitor, message, color, width, height)
    monitor.clear()
    monitor.setTextScale(1) -- Set text scale for readability
    monitor.setTextColor(color)
    
    local wrappedLines = wrapAndCenterText(message, width)
    
    for i = 1, math.min(#wrappedLines, height) do
        monitor.setCursorPos(1, i)
        monitor.write(wrappedLines[i])
    end
end

-- Function to flash the monitor's background color and keep the text displayed
function flashMonitorBackground(monitor, message, width, height)
    local isWhite = false
    local color = colors.blue -- Text color while flashing

    local wrappedLines = wrapAndCenterText(message, width)

    while true do
        if isWhite then
            monitor.setBackgroundColor(colors.black)
        else
            monitor.setBackgroundColor(colors.white)
        end
        monitor.clear()

        -- Redraw the centered message
        monitor.setTextColor(color)
        for i = 1, math.min(#wrappedLines, height) do
            monitor.setCursorPos(1, i)
            monitor.write(wrappedLines[i])
        end

        isWhite = not isWhite
        sleep(0.5) -- Flash every 0.5 seconds
    end
end

-- Main fusion crafting function
function fusionCraft(monitor, monitorWidth, monitorHeight)
    -- Step 1: Find all injectors
    local injectors = findInjectors()

    -- Step 2: Find the crafting core on the network
    local craftingCore = findCraftingCore()
    print("Found the fusion crafting core.")

    -- Step 3: Get the turtle's network name from the modem on the bottom
    local turtleName = getTurtleNameFromModem()
    print("Using turtle name from modem: " .. turtleName)

    -- Step 4: Idle state check, ensure slot 9 has an item before continuing
    updateMonitor(monitor, "Idle: Waiting for item in slot 9...", colors.yellow, monitorWidth, monitorHeight)
    while turtle.getItemCount(9) == 0 do
        print("Idle state: Waiting for item in slot 9...")
        sleep(2) -- Check every 2 seconds
    end
    updateMonitor(monitor, "Item detected. Starting crafting process...", colors.green, monitorWidth, monitorHeight)
    print("Item detected in slot 9, starting crafting process...")

    -- Step 5: Place items from turtle's slots 1-8 into injectors' slot 1
    updateMonitor(monitor, "Distributing items to injectors...", colors.yellow, monitorWidth, monitorHeight)
    for i = 1, 8 do
        if turtle.getItemCount(i) == 0 then
            error("Slot " .. i .. " in the turtle is empty. Expected an item for crafting.")
        end

        local injector = injectors[i]
        if injector.pullItems(turtleName, i, 64, 1) == 0 then
            error("Failed to move item from turtle slot " .. i .. " to injector " .. i)
        end
    end
    updateMonitor(monitor, "Items distributed. Placing item in crafting core...", colors.green, monitorWidth, monitorHeight)
    print("All items distributed to injectors.")

    -- Step 6: Place item from slot 9 into slot 1 of the crafting core
    if craftingCore.pullItems(turtleName, 9, 64, 1) == 0 then
        error("Failed to move item from turtle slot 9 to the crafting core.")
    end
    print("Item from slot 9 placed into the crafting core.")

    -- Step 7: Trigger a redstone signal to start the crafting process
    updateMonitor(monitor, "Sending redstone signal to start crafting...", colors.yellow, monitorWidth, monitorHeight)
    triggerRedstoneSignal()

    -- Step 8: Monitor the crafting core for an item in slot 2 using getItem() and flash the background
    parallel.waitForAny(
        function()
            while craftingCore.getItem(2) == nil do
                print("Waiting for crafting to complete...")
                sleep(1) -- Check every second
            end
        end,
        function()
            flashMonitorBackground(monitor, "Crafting in progress. Waiting for completion...", monitorWidth, monitorHeight)
        end
    )

    -- Return background to black when crafting is complete
    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    updateMonitor(monitor, "Crafting complete! Retrieving item...", colors.green, monitorWidth, monitorHeight)
    print("Crafting complete! Item detected in the crafting core's slot 2.")

    -- Step 9: Move the crafted item from the crafting core's slot 2 to turtle's slot 15
    if craftingCore.pushItems(turtleName, 2, 64, 15) == 0 then
        error("Failed to push crafted item to turtle slot 15.")
    end
    updateMonitor(monitor, "Item retrieved. Returning to idle state.", colors.green, monitorWidth, monitorHeight)
    print("Crafted item moved to turtle's slot 15. Returning to idle state.")
end

-- Main loop
function main()
    -- Find the monitor on the network connected through the bottom modem
    local monitor = findMonitorOnBottomModem()

    -- Get the monitor's size (width and height)
    local monitorWidth, monitorHeight = monitor.getSize()

    while true do
        fusionCraft(monitor, monitorWidth, monitorHeight) -- Run the crafting process with monitor
        print("Fusion crafting process complete. Returning to idle.")
    end
end

main()
