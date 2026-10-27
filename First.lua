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
