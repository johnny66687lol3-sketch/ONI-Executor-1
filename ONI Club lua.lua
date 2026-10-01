-- [[ ONI Club ]]
-- Hotkeys: RightControl Hide Menu | E+LeftClick Teleport

repeat task.wait() until game:IsLoaded()
local lp = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local mouse = lp:GetMouse()

-- [ Environment Cleanup ]
for _, v in pairs(game.CoreGui:GetChildren()) do
    if v.Name:find("OniV") or v.Name == "OniFOV_Gui" then v:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "OniClub_Ultimate"

-- [ FOV Circle Render System ]
local FOVGui = Instance.new("ScreenGui", game.CoreGui)
FOVGui.Name = "OniFOV_Gui"
FOVGui.IgnoreGuiInset = true 
FOVGui.DisplayOrder = 999   

local FOVFrame = Instance.new("Frame", FOVGui)
FOVFrame.BackgroundTransparency = 1
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5) 
FOVFrame.Visible = false

local FOVStroke = Instance.new("UIStroke", FOVFrame)
FOVStroke.Color = Color3.fromRGB(255, 50, 50)
FOVStroke.Thickness = 2
local FOVCorner = Instance.new("UICorner", FOVFrame)
FOVCorner.CornerRadius = UDim.new(1, 0) 

-- ==================== [ Global Variables ] ====================
_G.FOV_Enabled = false
_G.FOV_Visible = false 
_G.Dist_Enabled = false
_G.WallCheck = false -- Wall check toggle
_G.LockKey = Enum.UserInputType.MouseButton2
_G.KeyType = "Mouse"
_G.Radius = 150
_G.AimSmoothness = 0.5 
_G.TargetPart = "Head" 

_G.EspBox = false
_G.EspTracer = false
_G.EspName = false
local espObjects = {}

_G.SpeedEnabled = false
_G.CustomSpeed = 100
_G.Flying = false
_G.FlySpeed = 2.5
_G.InfJump = false
_G.Noclip = false 
local noclipConnection = nil

-- Fun Variables
_G.Spinbot = false
_G.SpinSpeed = 50

-- ==================== [ Functions ] ====================
-- ESP Setup
local function createEsp(player)
    if espObjects[player] then return end
    espObjects[player] = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text")
    }
    local obj = espObjects[player]
    obj.Box.Thickness = 1.5; obj.Box.Color = Color3.fromRGB(255, 50, 50); obj.Box.Visible = false
    obj.Tracer.Thickness = 1; obj.Tracer.Color = Color3.fromRGB(255, 50, 50); obj.Tracer.Visible = false
    obj.Name.Size = 16; obj.Name.Center = true; obj.Name.Outline = true; obj.Name.Color = Color3.new(1,1,1); obj.Name.Visible = false
end

for _, p in pairs(game.Players:GetPlayers()) do if p ~= lp then createEsp(p) end end
game.Players.PlayerAdded:Connect(createEsp)
game.Players.PlayerRemoving:Connect(function(p) if espObjects[p] then for _,v in pairs(espObjects[p]) do v:Remove() end espObjects[p] = nil end end)

-- New: Wall Check Function (Raycast)
local function IsVisible(targetPart)
    if not _G.WallCheck then return true end -- If disabled, assume always visible
    
    local rayOrigin = cam.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin)
    
    local raycastParams = RaycastParams.new()
    -- Ignore self and target, check for obstacles in between
    raycastParams.FilterDescendantsInstances = {lp.Character, targetPart.Parent} 
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    -- If result is nil, no wall detected
    return raycastResult == nil 
end

-- ==================== [ UI System ] ====================
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 700, 0, 480); Main.Position = UDim2.new(0.5, -350, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18); Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke", Main); Stroke.Color = Color3.fromRGB(255, 40, 40); Stroke.Thickness = 1.5

local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 60); Header.BackgroundTransparency = 1
local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0, 300, 1, 0); Title.Position = UDim2.new(0, 25, 0, 0)
Title.Text = "ONI Club"
Title.TextColor3 = Color3.fromRGB(255, 50, 50); Title.TextSize = 28; Title.Font = Enum.Font.GothamBlack; Title.BackgroundTransparency = 1; Title.TextXAlignment = "Left"

-- Window Dragging
local d, ds, sp
Header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; ds = i.Position; sp = Main.Position; i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end) end end)
UIS.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - ds; Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y) end end)

local Sidebar = Instance.new("Frame", Main); Sidebar.Position = UDim2.new(0, 20, 0, 75); Sidebar.Size = UDim2.new(0, 160, 1, -95); Sidebar.BackgroundTransparency = 1; Instance.new("UIListLayout", Sidebar).Padding = UDim.new(0, 12)
local Container = Instance.new("Frame", Main); Container.Position = UDim2.new(0, 195, 0, 75); Container.Size = UDim2.new(1, -215, 1, -95); Container.BackgroundTransparency = 1

local function CreateTab(name)
    local Page = Instance.new("ScrollingFrame", Container); Page.Size = UDim2.new(1, 0, 1, 0); Page.BackgroundTransparency = 1; Page.Visible = false; Page.ScrollBarThickness = 3; Page.ScrollBarImageColor3 = Color3.fromRGB(255, 50, 50); Page.AutomaticCanvasSize = Enum.AutomaticSize.Y; Instance.new("UIListLayout", Page).Padding = UDim.new(0, 12)
    local B = Instance.new("TextButton", Sidebar); B.Size = UDim2.new(1, 0, 0, 40); B.BackgroundColor3 = Color3.fromRGB(25, 25, 30); B.Text = "  " .. name; B.TextColor3 = Color3.fromRGB(150, 150, 150); B.TextSize = 16; B.Font = Enum.Font.GothamBold; B.TextXAlignment = "Left"; Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)
    B.MouseButton1Click:Connect(function() for _,v in pairs(Container:GetChildren()) do v.Visible = false end; for _,v in pairs(Sidebar:GetChildren()) do if v:IsA("TextButton") then TS:Create(v, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundColor3 = Color3.fromRGB(25, 25, 30)}):Play() end end; Page.Visible = true; TS:Create(B, TweenInfo.new(0.2), {TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(200, 40, 40)}):Play() end)
    return Page
end

local function AddToggle(p, t, c)
    local F = Instance.new("Frame", p); F.Size = UDim2.new(0.98, 0, 0, 40); F.BackgroundColor3 = Color3.fromRGB(22, 22, 26); Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)
    local L = Instance.new("TextLabel", F); L.Size = UDim2.new(0.7, 10, 1, 0); L.Position = UDim2.new(0, 15, 0, 0); L.Text = t; L.TextColor3 = Color3.new(1,1,1); L.TextSize = 15; L.Font = Enum.Font.GothamMedium; L.TextXAlignment = "Left"; L.BackgroundTransparency = 1
    local B = Instance.new("TextButton", F); B.Size = UDim2.new(0, 44, 0, 22); B.Position = UDim2.new(1, -55, 0.5, -11); B.BackgroundColor3 = Color3.fromRGB(40, 40, 45); B.Text = ""; Instance.new("UICorner", B).CornerRadius = UDim.new(1, 0)
    local D = Instance.new("Frame", B); D.Size = UDim2.new(0, 16, 0, 16); D.Position = UDim2.new(0, 3, 0.5, -8); D.BackgroundColor3 = Color3.new(1,1,1); Instance.new("UICorner", D).CornerRadius = UDim.new(1, 0)
    local s = false; B.MouseButton1Click:Connect(function() s = not s; c(s); TS:Create(D, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Position = s and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play(); TS:Create(B, TweenInfo.new(0.2), {BackgroundColor3 = s and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(40, 40, 45)}):Play() end)
end

local function AddCycleButton(p, t, options, c)
    local F = Instance.new("Frame", p); F.Size = UDim2.new(0.98, 0, 0, 40); F.BackgroundColor3 = Color3.fromRGB(22, 22, 26); Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)
    local L = Instance.new("TextLabel", F); L.Size = UDim2.new(0.5, 10, 1, 0); L.Position = UDim2.new(0, 15, 0, 0); L.Text = t; L.TextColor3 = Color3.new(1,1,1); L.TextSize = 15; L.Font = Enum.Font.GothamMedium; L.TextXAlignment = "Left"; L.BackgroundTransparency = 1
    local B = Instance.new("TextButton", F); B.Size = UDim2.new(0, 130, 0, 26); B.Position = UDim2.new(1, -145, 0.5, -13); B.BackgroundColor3 = Color3.fromRGB(40, 40, 45); B.TextColor3 = Color3.fromRGB(255, 50, 50); B.Font = Enum.Font.GothamBold; B.TextSize = 13; Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
    local index = 1; B.Text = options[index]
    B.MouseButton1Click:Connect(function() index = index + 1; if index > #options then index = 1 end; B.Text = options[index]; c(options[index]) end)
end

local function AddSlider(p, t, min, max, def, isFloat, c)
    local F = Instance.new("Frame", p); F.Size = UDim2.new(0.98, 0, 0, 55); F.BackgroundColor3 = Color3.fromRGB(22, 22, 26); Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)
    local L = Instance.new("TextLabel", F); L.Size = UDim2.new(1, -30, 0, 25); L.Position = UDim2.new(0, 15, 0, 5); L.Text = t .. " : " .. def; L.TextColor3 = Color3.new(1,1,1); L.TextSize = 14; L.Font = Enum.Font.GothamMedium; L.BackgroundTransparency = 1; L.TextXAlignment = "Left"
    local S = Instance.new("TextButton", F); S.Size = UDim2.new(1, -30, 0, 6); S.Position = UDim2.new(0, 15, 0, 35); S.BackgroundColor3 = Color3.fromRGB(40, 40, 45); S.Text = ""; S.AutoButtonColor = false; Instance.new("UICorner", S).CornerRadius = UDim.new(1, 0)
    local Fill = Instance.new("Frame", S); Fill.Size = UDim2.new((def-min)/(max-min), 0, 1, 0); Fill.BackgroundColor3 = Color3.fromRGB(255, 50, 50); Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    S.MouseButton1Down:Connect(function() local m; m = UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then local x = math.clamp((i.Position.X - S.AbsolutePosition.X) / S.AbsoluteSize.X, 0, 1); Fill.Size = UDim2.new(x, 0, 1, 0); local v = min + (max - min) * x; v = isFloat and math.floor(v * 10) / 10 or math.floor(v); L.Text = t .. " : " .. v; c(v) end end); UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then m:Disconnect() end end) end)
end

local function AddBind(p, t, defaultKey, c)
    local F = Instance.new("Frame", p); F.Size = UDim2.new(0.98, 0, 0, 40); F.BackgroundColor3 = Color3.fromRGB(22, 22, 26); Instance.new("UICorner", F).CornerRadius = UDim.new(0, 6)
    local L = Instance.new("TextLabel", F); L.Size = UDim2.new(0.5, 10, 1, 0); L.Position = UDim2.new(0, 15, 0, 0); L.Text = t; L.TextColor3 = Color3.new(1,1,1); L.TextSize = 15; L.Font = Enum.Font.GothamMedium; L.TextXAlignment = "Left"; L.BackgroundTransparency = 1
    local B = Instance.new("TextButton", F); B.Size = UDim2.new(0, 100, 0, 26); B.Position = UDim2.new(1, -115, 0.5, -13); B.BackgroundColor3 = Color3.fromRGB(40, 40, 45); B.TextColor3 = Color3.fromRGB(255, 50, 50); B.Font = Enum.Font.GothamBold; B.TextSize = 13; Instance.new("UICorner", B).CornerRadius = UDim.new(0, 4)
    local keyName = defaultKey.Name
    if keyName:find("MouseButton") then keyName = keyName:gsub("MouseButton", "MB") end
    B.Text = keyName
    local binding = false
    B.MouseButton1Click:Connect(function()
        if binding then return end
        binding = true
        B.Text = "..."
        task.wait(0.1) 
        local conn
        conn = UIS.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType.Name:find("MouseButton") then
                local newKey = (i.UserInputType == Enum.UserInputType.Keyboard) and i.KeyCode or i.UserInputType
                local newType = (i.UserInputType == Enum.UserInputType.Keyboard) and "Keyboard" or "Mouse"
                local displayName = newKey.Name
                if displayName:find("MouseButton") then displayName = displayName:gsub("MouseButton", "MB") end
                B.Text = displayName; c(newKey, newType); binding = false; conn:Disconnect()
            end
        end)
    end)
end

local Combat = CreateTab("Combat")
local Visuals = CreateTab("Visuals")
local Movement = CreateTab("Movement")
local Fun = CreateTab("Fun") 

-- [ Combat Content ]
AddToggle(Combat, "Enable FOV Lock-on", function(v) _G.FOV_Enabled = v end)
AddToggle(Combat, "Show FOV Circle", function(v) _G.FOV_Visible = v end)
AddToggle(Combat, "Nearest Target Lock-on", function(v) _G.Dist_Enabled = v end)
-- New Wall Check Button:
AddToggle(Combat, "Wall Check", function(v) _G.WallCheck = v end) 
AddBind(Combat, "Lock-on Hotkey", _G.LockKey, function(key, kType) _G.LockKey = key; _G.KeyType = kType end)
AddCycleButton(Combat, "Target Part", {"Head", "HumanoidRootPart"}, function(v) _G.TargetPart = v end)
AddSlider(Combat, "FOV Radius", 50, 800, 150, false, function(v) _G.Radius = v end)
AddSlider(Combat, "Aim Smoothness", 0.1, 1, 0.5, true, function(v) _G.AimSmoothness = v end)

-- [ Visuals Content ]
AddToggle(Visuals, "ESP Box", function(v) _G.EspBox = v end)
AddToggle(Visuals, "ESP Tracer", function(v) _G.EspTracer = v end)
AddToggle(Visuals, "ESP Name", function(v) _G.EspName = v end)

-- [ Movement Content ]
AddToggle(Movement, "Noclip", function(v) 
    _G.Noclip = v 
    if _G.Noclip then
        if not noclipConnection then
            noclipConnection = RS.Stepped:Connect(function()
                if lp.Character then
                    for _, part in pairs(lp.Character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
        end
    else
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        if lp.Character then 
            for _, part in pairs(lp.Character:GetDescendants()) do 
                if part:IsA("BasePart") then part.CanCollide = true end 
            end 
        end
    end
end)
AddToggle(Movement, "CFrame Fly", function(v) _G.Flying = v end)
AddSlider(Movement, "Fly Speed", 1, 20, 3, false, function(v) _G.FlySpeed = v end)

-- [ Fun Content ]
AddToggle(Fun, "Spinbot", function(v) 
    _G.Spinbot = v 
    if v then
        lp.CameraMode = Enum.CameraMode.Classic
        if lp.CameraMinZoomDistance < 8 then lp.CameraMinZoomDistance = 8 end
    else
        lp.CameraMinZoomDistance = 0.5
    end
end)
AddSlider(Fun, "Spin Speed", 10, 150, 50, false, function(v) _G.SpinSpeed = v end)

-- ==================== [ Core Loop System ] ====================
RS.RenderStepped:Connect(function()
    local char = lp.Character; if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart; local hum = char:FindFirstChildOfClass("Humanoid")

    -- 1. FOV Update
    local mouseLoc = UIS:GetMouseLocation()
    FOVFrame.Visible = (_G.FOV_Visible and not Main.Visible)
    FOVFrame.Size = UDim2.new(0, _G.Radius * 2, 0, _G.Radius * 2)
    FOVFrame.Position = UDim2.new(0, mouseLoc.X, 0, mouseLoc.Y)

    -- 2. Spinbot
    if _G.Spinbot then
        local savedCamCFrame = cam.CFrame 
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(_G.SpinSpeed), 0)
        cam.CFrame = savedCamCFrame
    end

    -- 3. Lock-on Logic (with Wall Check)
    local is_down = (_G.KeyType == "Mouse" and UIS:IsMouseButtonPressed(_G.LockKey)) or (_G.KeyType == "Keyboard" and UIS:IsKeyDown(_G.LockKey))
    if (_G.FOV_Enabled or _G.Dist_Enabled) and is_down then
        local target, dist = nil, math.huge
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= lp and v.Character and v.Character:FindFirstChild(_G.TargetPart) then
                local aimPart = v.Character[_G.TargetPart]
                if _G.FOV_Enabled then
                    local p, on = cam:WorldToViewportPoint(aimPart.Position)
                    if on then
                        local d = (Vector2.new(p.X, p.Y) - mouseLoc).Magnitude
                        -- Add IsVisible(aimPart) check
                        if d < dist and d <= _G.Radius and IsVisible(aimPart) then dist = d; target = aimPart end
                    end
                elseif _G.Dist_Enabled then
                    local d = (hrp.Position - aimPart.Position).Magnitude
                    -- Add IsVisible(aimPart) check
                    if d < dist and IsVisible(aimPart) then dist = d; target = aimPart end
                end
            end
        end
        if target then 
            cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, target.Position), _G.AimSmoothness) 
        end
    end

    -- 4. Fly Logic
    if _G.Flying then
        hum.PlatformStand = true; local m = Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then m = m + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then m = m - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then m = m - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then m = m + cam.CFrame.RightVector end
        hrp.Velocity = Vector3.zero; hrp.CFrame = hrp.CFrame + (m * _G.FlySpeed)
    else if hum then hum.PlatformStand = false end end

    -- 5. ESP Render (Fixed Name Display)
    for p, obj in pairs(espObjects) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
            local pos, on = cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            local sX, sY = 2000/pos.Z, 3500/pos.Z
            
            if on then
                -- Box
                if _G.EspBox then
                    obj.Box.Size = Vector2.new(sX, sY); obj.Box.Position = Vector2.new(pos.X-sX/2, pos.Y-sY/2); obj.Box.Visible = true
                else obj.Box.Visible = false end
                
                -- Tracer
                if _G.EspTracer then
                    obj.Tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y); obj.Tracer.To = Vector2.new(pos.X, pos.Y); obj.Tracer.Visible = true
                else obj.Tracer.Visible = false end
                
                -- Name 
                if _G.EspName then
                    obj.Name.Text = p.Name
                    -- Place right above the box
                    obj.Name.Position = Vector2.new(pos.X, pos.Y - (sY/2) - 18) 
                    obj.Name.Visible = true
                else obj.Name.Visible = false end
                
            else 
                obj.Box.Visible = false; obj.Tracer.Visible = false; obj.Name.Visible = false 
            end
        else 
            obj.Box.Visible = false; obj.Tracer.Visible = false; obj.Name.Visible = false 
        end
    end
end)

UIS.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.RightControl then Main.Visible = not Main.Visible end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        if UIS:IsKeyDown(Enum.KeyCode.E) and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0,3,0))
        end
    end
end)

Combat.Visible = true
print("ONI Club working🟢")