-- for personal use

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer


local Library = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()

local Window = Library:CreateWindow({
    Title = "Gankware",
    SubTitle = "fuck you",
    TabWidth = 160,
    Size = UDim2.fromOffset(540, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "eye" })
local SettingsTab = Window:AddTab({ Title = "Settings", Icon = "settings" })

Window:SelectTab(MainTab)

SettingsTab:AddParagraph({
    Title = "UI Toggle",
    Content = "Press LEFT CTRL to open / close the menu"
})


local ESP_ENABLED = false
local SHOW_HEALTH_BAR = true
local SHOW_HEALTH_TEXT = true
local SHOW_DISTANCE_TEXT = true

local ESP_COLOR = Color3.fromRGB(255,255,255)
local INFO_COLOR = Color3.fromRGB(200,200,200)


local BASE_FOV = 70
local ESP = {}

local function createESP(player)
    if player == LocalPlayer then return end

    ESP[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Info = Drawing.new("Text"),
        Health = Drawing.new("Square"),
        HealthOutline = Drawing.new("Square")
    }

    local e = ESP[player]

    e.Box.Thickness = 1
    e.Box.Filled = false
    e.Box.Color = ESP_COLOR

    e.Name.Size = 13
    e.Name.Center = true
    e.Name.Outline = true
    e.Name.Color = ESP_COLOR
    e.Name.Text = player.Name

    e.Info.Size = 12
    e.Info.Center = true
    e.Info.Outline = true
    e.Info.Color = INFO_COLOR

    e.Health.Filled = true
    e.HealthOutline.Thickness = 1
    e.HealthOutline.Color = Color3.fromRGB(0,0,0)
end

local function removeESP(player)
    if ESP[player] then
        for _, d in pairs(ESP[player]) do
            d:Remove()
        end
        ESP[player] = nil
    end
end


MainTab:AddToggle("ESPEnabled", {
    Title = "Enable ESP",
    Default = false,
    Callback = function(v)
        ESP_ENABLED = v
        if not v then
            for _, e in pairs(ESP) do
                for _, d in pairs(e) do
                    d.Visible = false
                end
            end
        end
    end
})

MainTab:AddToggle("HealthBar", {
    Title = "Show Health Bar",
    Default = true,
    Callback = function(v)
        SHOW_HEALTH_BAR = v
    end
})

MainTab:AddToggle("HealthText", {
    Title = "Show Health Text",
    Default = true,
    Callback = function(v)
        SHOW_HEALTH_TEXT = v
    end
})

MainTab:AddToggle("DistanceText", {
    Title = "Show Distance",
    Default = true,
    Callback = function(v)
        SHOW_DISTANCE_TEXT = v
    end
})

MainTab:AddColorpicker("ESPColor", {
    Title = "ESP Color",
    Default = ESP_COLOR,
    Callback = function(col)
        ESP_COLOR = col
        for _, e in pairs(ESP) do
            e.Box.Color = col
            e.Name.Color = col
        end
    end
})


RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then return end

    for player, e in pairs(ESP) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if hum and root and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if not onScreen then
                for _, d in pairs(e) do d.Visible = false end
                continue
            end

            local dist = (Camera.CFrame.Position - root.Position).Magnitude
            local scale = BASE_FOV / Camera.FieldOfView
            local height = math.clamp((2200 / dist) * scale, 30, 300)
            local width = height * 0.55
            local x = pos.X - width / 2
            local y = pos.Y - height / 2

            e.Box.Size = Vector2.new(width, height)
            e.Box.Position = Vector2.new(x, y)
            e.Box.Visible = true

            e.Name.Position = Vector2.new(pos.X, y - 14)
            e.Name.Visible = true


            if SHOW_HEALTH_BAR then
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local barH = height * hp

                e.HealthOutline.Size = Vector2.new(4, height)
                e.HealthOutline.Position = Vector2.new(x - 6, y)
                e.HealthOutline.Visible = true

                e.Health.Size = Vector2.new(2, barH)
                e.Health.Position = Vector2.new(x - 5, y + (height - barH))
                e.Health.Color = Color3.fromRGB(
                    255 * (1 - hp),
                    255 * hp,
                    0
                )
                e.Health.Visible = true
            else
                e.Health.Visible = false
                e.HealthOutline.Visible = false
            end


            local parts = {}

            if SHOW_HEALTH_TEXT then
                table.insert(parts,
                    math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                )
            end

            if SHOW_DISTANCE_TEXT then
                table.insert(parts,
                    math.floor(dist) .. "m"
                )
            end

            if #parts > 0 then
                e.Info.Text = table.concat(parts, " | ")
                e.Info.Position = Vector2.new(pos.X, y + height + 2)
                e.Info.Visible = true
            else
                e.Info.Visible = false
            end
        else
            for _, d in pairs(e) do d.Visible = false end
        end
    end
end)


for _, p in ipairs(Players:GetPlayers()) do
    createESP(p)
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)


local spectating = nil

local function getPlayerNames()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

local SpectateDropdown = MainTab:AddDropdown("SpectatePlayer", {
    Title = "Spectate Player",
    Values = getPlayerNames(),
    Multi = false,
    Default = nil,
    Callback = function(name)
        local player = Players:FindFirstChild(name)
        if not player then return end

        if spectating == player then
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            spectating = nil
            SpectateDropdown:SetValue(nil)
        else
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                Camera.CameraSubject = hum
                spectating = player
            end
        end
    end
})

MainTab:AddButton({
    Title = "Stop Spectating",
    Callback = function()
        Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        spectating = nil
        SpectateDropdown:SetValue(nil)
    end
})

local function refreshSpectateList()
    SpectateDropdown:SetValues(getPlayerNames())
end

Players.PlayerAdded:Connect(refreshSpectateList)
Players.PlayerRemoving:Connect(refreshSpectateList)
