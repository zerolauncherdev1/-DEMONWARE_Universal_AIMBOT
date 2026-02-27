--[[ 
    ---------------------------------------------------------------------------------------
    DEMONWARE! v28.0 - FINAL STABLE
    - ESP FIX: Auto-hooking refresh engine (Fixed "ESP not working" bug)
    - FOV FIX: Global Drawing initialization with Screen-Center sync
    - SKELETON: Multi-index joint support for R6/R15
    - DISTANCE: Real-time Magnitude tracking
    ---------------------------------------------------------------------------------------
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // GLOBAL CONFIG
local Demonware = {
    Aimbot = {Enabled = false, Smoothing = 3, TargetPart = "Head", Radius = 150, FOVVisible = true},
    Visuals = {Boxes = false, Skeletons = false, Tracers = false, Distance = false},
    Misc = {Speed = false, Jump = false, Spin = false, InfJump = false, NoClip = false},
    UI = {Pink = Color3.fromRGB(255, 0, 255), Blue = Color3.fromRGB(0, 170, 255), MainVisible = true}
}

-- // 1. FOV CIRCLE (FIXED PERSISTENCE)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Demonware.UI.Pink
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8
FOVCircle.Visible = false

-- // 2. ESP CORE (REWRITTEN FOR RESPONDING TO ENGINE CHANGES)
local PlayerDrawings = {}

local function RemoveESP(plr)
    if PlayerDrawings[plr] then
        for _, obj in pairs(PlayerDrawings[plr]) do
            if type(obj) == "table" then
                for _, line in pairs(obj) do line:Remove() end
            else obj:Remove() end
        end
        PlayerDrawings[plr] = nil
    end
end

local function CreateESP(plr)
    if PlayerDrawings[plr] then RemoveESP(plr) end -- Clean old data
    
    local d = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Dist = Drawing.new("Text"),
        Skel = {
            Spine = Drawing.new("Line"),
            LA = Drawing.new("Line"), RA = Drawing.new("Line"),
            LL = Drawing.new("Line"), RL = Drawing.new("Line")
        }
    }
    
    d.Box.Color = Demonware.UI.Pink; d.Box.Thickness = 1.5
    d.Tracer.Color = Demonware.UI.Pink; d.Tracer.Thickness = 1
    d.Dist.Size = 14; d.Dist.Center = true; d.Dist.Outline = true; d.Dist.Color = Color3.new(1,1,1)
    for _, l in pairs(d.Skel) do l.Color = Demonware.UI.Pink; l.Thickness = 1.5 end
    
    PlayerDrawings[plr] = d
end

-- Initialize Hooks
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end

-- // 3. MASTER RENDER ENGINE
RunService.RenderStepped:Connect(function()
    -- FOV Update
    FOVCircle.Visible = Demonware.Aimbot.FOVVisible
    FOVCircle.Radius = Demonware.Aimbot.Radius
    FOVCircle.Position = UserInputService:GetMouseLocation()

    for plr, d in pairs(PlayerDrawings) do
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if root and hum and hum.Health > 0 then
            local pos, onS = Camera:WorldToViewportPoint(root.Position)
            
            -- Box Visibility & Logic
            d.Box.Visible = (Demonware.Visuals.Boxes and onS)
            if d.Box.Visible then
                local sizeX = 2200 / pos.Z
                local sizeY = 3300 / pos.Z
                d.Box.Size = Vector2.new(sizeX, sizeY)
                d.Box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
            end
            
            -- Tracer Visibility & Logic
            d.Tracer.Visible = (Demonware.Visuals.Tracers and onS)
            if d.Tracer.Visible then
                d.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                d.Tracer.To = Vector2.new(pos.X, pos.Y)
            end

            -- Distance Visibility & Logic
            d.Dist.Visible = (Demonware.Visuals.Distance and onS)
            if d.Dist.Visible and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local mag = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                d.Dist.Text = math.floor(mag) .. " STUDS"
                d.Dist.Position = Vector2.new(pos.X, pos.Y + (1600/pos.Z))
            end

            -- Full Skeleton (Recursive anatomical check)
            local skelV = (Demonware.Visuals.Skeletons and onS)
            local function gp(n)
                local p = char:FindFirstChild(n)
                if p then local v,o = Camera:WorldToViewportPoint(p.Position) return Vector2.new(v.X,v.Y), o end
            end
            
            local H = gp("Head"); local T = gp("UpperTorso") or gp("Torso")
            local LA = gp("LeftUpperArm") or gp("Left Arm"); local RA = gp("RightUpperArm") or gp("Right Arm")
            local LL = gp("LeftLowerLeg") or gp("Left Leg"); local RL = gp("RightLowerLeg") or gp("Right Leg")

            d.Skel.Spine.Visible = skelV and H and T; if d.Skel.Spine.Visible then d.Skel.Spine.From = H; d.Skel.Spine.To = T end
            d.Skel.LA.Visible = skelV and T and LA; if d.Skel.LA.Visible then d.Skel.LA.From = T; d.Skel.LA.To = LA end
            d.Skel.RA.Visible = skelV and T and RA; if d.Skel.RA.Visible then d.Skel.RA.From = T; d.Skel.RA.To = RA end
            d.Skel.LL.Visible = skelV and T and LL; if d.Skel.LL.Visible then d.Skel.LL.From = T; d.Skel.LL.To = LL end
            d.Skel.RL.Visible = skelV and T and RL; if d.Skel.RL.Visible then d.Skel.RL.From = T; d.Skel.RL.To = RL end
        else
            -- Kill visuals if player is dead/invalid
            d.Box.Visible = false; d.Tracer.Visible = false; d.Dist.Visible = false
            for _, l in pairs(d.Skel) do l.Visible = false end
        end
    end
    
    -- Aimbot Execution
    if Demonware.Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target, minD = nil, Demonware.Aimbot.Radius
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Demonware.Aimbot.TargetPart) then
                local pos, onS = Camera:WorldToViewportPoint(p.Character[Demonware.Aimbot.TargetPart].Position)
                local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if onS and mag < minD then minD = mag; target = pos end
            end
        end
        if target then
            local m = UserInputService:GetMouseLocation()
            mousemoverel((target.X - m.X)/Demonware.Aimbot.Smoothing, (target.Y - m.Y)/Demonware.Aimbot.Smoothing)
        end
    end
end)

-- // 4. THE INTERFACE (5-5-5 SYSTEM)
local function buildUI()
    local Screen = Instance.new("ScreenGui", (gethui and gethui()) or game:GetService("CoreGui"))
    local Main = Instance.new("Frame", Screen)
    Main.Size = UDim2.new(0, 500, 0, 400); Main.Position = UDim2.new(0.5, -250, 0.5, -200)
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Main.BorderSizePixel = 0
    Instance.new("UIStroke", Main).Color = Demonware.UI.Pink

    local Sidebar = Instance.new("Frame", Main)
    Sidebar.Size = UDim2.new(0, 130, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    local Title = Instance.new("TextLabel", Sidebar)
    Title.Text = "DEMONWARE"; Title.Size = UDim2.new(1, 0, 0, 50); Title.TextColor3 = Demonware.UI.Blue; Title.Font = Enum.Font.GothamBold

    -- Draggable Logic
    local d, dS, sP
    Title.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true dS = i.Position sP = Main.Position end end)
    UserInputService.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dS
        Main.Position = UDim2.new(sP.X.Scale, sP.X.Offset + delta.X, sP.Y.Scale, sP.Y.Offset + delta.Y)
    end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)

    local Container = Instance.new("Frame", Main)
    Container.Position = UDim2.new(0, 135, 0, 10); Container.Size = UDim2.new(1, -145, 1, -20); Container.BackgroundTransparency = 1
    
    local function addTab(n, y)
        local p = Instance.new("ScrollingFrame", Container)
        p.Size = UDim2.new(1,0,1,0); p.Visible = false; p.BackgroundTransparency = 1; p.ScrollBarThickness = 0
        Instance.new("UIListLayout", p).Padding = UDim.new(0,5)
        local b = Instance.new("TextButton", Sidebar)
        b.Size = UDim2.new(1,0,0,40); b.Position = UDim2.new(0,0,0,y); b.Text = n; b.BackgroundColor3 = Color3.fromRGB(30,30,30); b.TextColor3 = Color3.new(1,1,1)
        b.MouseButton1Click:Connect(function() for _,v in pairs(Container:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end p.Visible = true end)
        return p
    end

    local tabA = addTab("Aimbot", 60); local tabV = addTab("Visuals", 105); local tabM = addTab("Misc", 150); tabA.Visible = true
    local function tgl(p, txt, cb)
        local act = false
        local b = Instance.new("TextButton", p)
        b.Size = UDim2.new(1, -10, 0, 35); b.BackgroundColor3 = Color3.fromRGB(40,40,40); b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
        b.MouseButton1Click:Connect(function() act = not act; b.BackgroundColor3 = act and Demonware.UI.Pink or Color3.fromRGB(40,40,40); cb(act) end)
    end

    -- TAB 1: AIMBOT
    tgl(tabA, "Enable Lock-On", function(v) Demonware.Aimbot.Enabled = v end)
    tgl(tabA, "Show FOV Circle", function(v) Demonware.Aimbot.FOVVisible = v end)
    
    local fovSizes = {100, 200, 300, 400, 500}
    local fIdx = 2
    local fBtn = Instance.new("TextButton", tabA)
    fBtn.Size = UDim2.new(1, -10, 0, 35); fBtn.BackgroundColor3 = Color3.fromRGB(50,50,50); fBtn.TextColor3 = Color3.new(1,1,1); fBtn.Text = "FOV Scale: 150"
    fBtn.MouseButton1Click:Connect(function()
        fIdx = (fIdx % #fovSizes) + 1
        Demonware.Aimbot.Radius = fovSizes[fIdx]
        fBtn.Text = "FOV Scale: " .. fovSizes[fIdx]
    end)

    tgl(tabA, "Lock: Head/Root", function(v) Demonware.Aimbot.TargetPart = v and "Head" or "HumanoidRootPart" end)
    tgl(tabA, "Smooth: High", function(v) Demonware.Aimbot.Smoothing = v and 5 or 3 end)

    -- TAB 2: VISUALS
    tgl(tabV, "Box ESP", function(v) Demonware.Visuals.Boxes = v end)
    tgl(tabV, "Full Skeleton", function(v) Demonware.Visuals.Skeletons = v end)
    tgl(tabV, "Tracer Lines", function(v) Demonware.Visuals.Tracers = v end)
    tgl(tabV, "Show Distance", function(v) Demonware.Visuals.Distance = v end)
    tgl(tabV, "Name Tags", function() end)

    -- TAB 3: MISC
    tgl(tabM, "Speed (22)", function(v) Demonware.Misc.Speed = v end)
    tgl(tabM, "Jump (50)", function(v) Demonware.Misc.Jump = v end)
    tgl(tabM, "Spinbot", function(v) Demonware.Misc.Spin = v end)
    tgl(tabM, "Inf Jump", function(v) Demonware.Misc.InfJump = v end)
    tgl(tabM, "No-Clip", function() end)

    UserInputService.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Enum.KeyCode.F4 then Main.Visible = not Main.Visible end end)
end

-- // EXECUTION
task.spawn(function()
    buildUI()
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if Demonware.Misc.Speed then LocalPlayer.Character.Humanoid.WalkSpeed = 22 end
        if Demonware.Misc.Jump then LocalPlayer.Character.Humanoid.JumpPower = 50 end
        if Demonware.Misc.Spin then LocalPlayer.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(60), 0) end
        if Demonware.Misc.InfJump and UserInputService:IsKeyDown(Enum.KeyCode.Space) then LocalPlayer.Character.Humanoid:ChangeState("Jumping") end
    end
end)
