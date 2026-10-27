-- CAR HUB | CHECK CAR + BOOST + MOBILE BUTTON

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Car Hub", SubTitle = "Check Car + Boost",
    TabWidth = 160, Size = UDim2.fromOffset(580, 520),
    Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({Title = "Main", Icon = "car"}),
    Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
}

local BoostSpeed, BoostCooldown, IsBoosting = 250, 1, false

-- CHECK CAR
local function CheckSpawnedCars()
    local folder = workspace:FindFirstChild("SpawnedCars")
    if not folder then return nil, "ไม่พบ workspace.SpawnedCars" end

    local myCars, otherCars, unknownCars = {}, {}, {}
    for _, car in ipairs(folder:GetChildren()) do
        if car:IsA("Model") then
            local owner = car:GetAttribute("SpawnedBy")
            local info = {Name = car.Name, Owner = owner == nil and "Unknown" or tostring(owner)}
            if owner == nil then
                table.insert(unknownCars, info)
            elseif tonumber(owner) == LocalPlayer.UserId then
                table.insert(myCars, info)
            else
                table.insert(otherCars, info)
            end
        end
    end
    return {MyCars = myCars, OtherCars = otherCars, UnknownCars = unknownCars}
end

local function FormatCars(cars)
    if #cars == 0 then return "ไม่มี" end
    local lines = {}
    for i, car in ipairs(cars) do
        lines[#lines + 1] = string.format("%d. %s | SpawnedBy: %s", i, car.Name, car.Owner)
    end
    return table.concat(lines, "\n")
end

local function ShowCarResults()
    local result, err = CheckSpawnedCars()
    if not result then
        Fluent:Notify({Title = "Check Car", Content = err, Duration = 5})
        return
    end

    local content = string.format(
        "รถของคุณ: %d คัน\nรถคนอื่น: %d คัน\nไม่ทราบเจ้าของ: %d คัน\n\n" ..
        "===== รถของคุณ =====\n%s\n\n===== รถคนอื่น =====\n%s\n\n===== ไม่ทราบเจ้าของ =====\n%s",
        #result.MyCars, #result.OtherCars, #result.UnknownCars,
        FormatCars(result.MyCars), FormatCars(result.OtherCars), FormatCars(result.UnknownCars)
    )
    print("========== CHECK CAR ==========")
    print(content)
    print("================================")
    Fluent:Notify({
        Title = "Check Car",
        Content = string.format("รถคุณ %d | รถคนอื่น %d | ไม่ทราบ %d",
            #result.MyCars, #result.OtherCars, #result.UnknownCars),
        Duration = 6
    })
end

-- FIND THE PLAYER'S CURRENT CAR
local function GetMyCurrentCar()
    local folder = workspace:FindFirstChild("SpawnedCars")
    if not folder then return nil, nil, "ไม่พบ SpawnedCars" end

    local character = LocalPlayer.Character
    if not character then return nil, nil, "ไม่พบ Character" end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or not humanoid.SeatPart then return nil, nil, "กรุณาขึ้นรถก่อน" end

    local seat = humanoid.SeatPart
    for _, car in ipairs(folder:GetChildren()) do
        if car:IsA("Model") and tonumber(car:GetAttribute("SpawnedBy")) == LocalPlayer.UserId then
            local driveSeat = car:FindFirstChild("DriveSeat", true)
            if driveSeat and driveSeat == seat then return car, driveSeat, nil end
        end
    end
    return nil, nil, "ไม่พบรถของคุณที่กำลังขับ"
end

-- BOOST
local function BoostCurrentCar()
    if IsBoosting then return end

    local car, driveSeat, err = GetMyCurrentCar()
    if not car then
        Fluent:Notify({Title = "Car Boost", Content = err, Duration = 4})
        return
    end
    if not driveSeat:IsA("BasePart") then
        Fluent:Notify({Title = "Car Boost", Content = "DriveSeat ไม่ใช่ BasePart", Duration = 4})
        return
    end

    local root = car.PrimaryPart or driveSeat
    if not root:IsA("BasePart") then return end

    IsBoosting = true
    local direction = root.CFrame.LookVector
    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(
        direction.X * BoostSpeed, velocity.Y, direction.Z * BoostSpeed
    )

    Fluent:Notify({
        Title = "BOOST ACTIVATED",
        Content = string.format("รถ: %s | Speed: %d studs/s", car.Name, BoostSpeed),
        Duration = 3
    })
    task.delay(BoostCooldown, function() IsBoosting = false end)
end

-- MOBILE BUTTON: touch to boost, drag to move
local function CreateMobileBoostButton()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local oldGui = playerGui:FindFirstChild("CarHubMobileBoost")
    if oldGui then oldGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "CarHubMobileBoost"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Enabled = UserInputService.TouchEnabled
    gui.Parent = playerGui

    local button = Instance.new("TextButton")
    button.Name = "MobileBoostButton"
    button.Size = UDim2.fromOffset(125, 58)
    button.Position = UDim2.new(1, -150, 0.65, 0)
    button.BackgroundColor3 = Color3.fromRGB(255, 85, 45)
    button.Text = "BOOST"
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 20
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = true
    button.Active = true
    button.Selectable = true
    button.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = button
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 190, 100)
    stroke.Thickness = 2
    stroke.Parent = button

    local dragging, dragStart, startPosition = false, nil, nil
    local activeTouch, moved, suppressActivation = nil, false, false
    local threshold = 8

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            dragStart = input.Position
            startPosition = button.Position
            activeTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    activeTouch = nil
                    if moved then
                        suppressActivation = true
                        task.delay(0.2, function() suppressActivation = false end)
                    end
                end
            end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseMovement then
            activeTouch = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input == activeTouch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > threshold or math.abs(delta.Y) > threshold then moved = true end
            if moved then
                button.Position = UDim2.new(
                    startPosition.X.Scale, startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
                )
            end
        end
    end)

    button.Activated:Connect(function()
        if suppressActivation or moved then
            moved = false
            return
        end
        BoostCurrentCar()
    end)
end

CreateMobileBoostButton()

-- MAIN UI
Tabs.Main:AddParagraph({
    Title = "Check Car",
    Content = "ตรวจสอบเจ้าของรถจาก Attribute SpawnedBy"
})
Tabs.Main:AddButton({
    Title = "Check Car",
    Description = "สแกนรถทั้งหมดใน SpawnedCars",
    Callback = ShowCarResults
})

Tabs.Main:AddSlider("BoostSpeedSlider", {
    Title = "Boost Speed",
    Description = "ความเร็วพุ่ง (studs/s)",
    Default = 250, Min = 50, Max = 1000, Rounding = 0,
    Callback = function(Value) BoostSpeed = Value end
})
Tabs.Main:AddSlider("BoostCooldownSlider", {
    Title = "Boost Cooldown",
    Description = "เวลาป้องกันการกดซ้ำ (วินาที)",
    Default = 1, Min = 0.5, Max = 5, Rounding = 1,
    Callback = function(Value) BoostCooldown = Value end
})
Tabs.Main:AddButton({
    Title = "BOOST NOW",
    Description = "พุ่งไปข้างหน้าตามความเร็วที่เลือก",
    Callback = BoostCurrentCar
})
Tabs.Main:AddKeybind("CarBoostKey", {
    Title = "Boost Keybind",
    Mode = "Toggle",
    Default = "B",
    Callback = function(pressed)
        if pressed then BoostCurrentCar() end
    end
})

-- SETTINGS
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/CarHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- START
Window:SelectTab(1)
Fluent:Notify({
    Title = "Car Hub",
    Content = "Check Car + Boost Speed + Mobile Button โหลดเรียบร้อย",
    Duration = 5
})
SaveManager:LoadAutoloadConfig()
