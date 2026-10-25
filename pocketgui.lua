local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild("PocketGUI") then
    pg.PocketGUI:Destroy()
end
if pg:FindFirstChild("PocketGUI_Float") then
    pg.PocketGUI_Float:Destroy()
end

local state = {}
state.flying = false
state.noclip = false
state.walkSpeed = 16
state.jumpPower = 50
state.speedBoost = false
state.highJump = false
state.xray = false
state.playerEsp = false
state.mm2Esp = false
state.antiAfk = false
state.flySpeed = 60
state.tpMode = false
state.flyConn = nil
state.bodyVelocity = nil
state.bodyGyro = nil
state.tpConn = nil
state.noclipConn = nil
state.speedConn = nil
state.jumpConn = nil
state.playerEspConn = nil
state.playerHighlights = {}
state.mm2EspConn = nil
state.mm2Highlights = {}
state.antiAfkConn = nil
state.connections = {}

local function track(c)
    table.insert(state.connections, c)
    return c
end

local function getRoot()
    local c = player.Character
    if c then
        return c:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function getHum()
    local c = player.Character
    if c then
        return c:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, 
            Text = text, 
            Duration = 4
        })
    end)
end

local function serverFling(TargetPlayer)
    if TargetPlayer == player then
        return
    end
    local myChar = player.Character
    if not myChar then
        return
    end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        return
    end
    local targetChar = TargetPlayer.Character
    if not targetChar then
        return
    end
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then
        return
    end
    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHum then
        return
    end
    local flingPart = Instance.new("Part")
    flingPart.Size = Vector3.new(2, 2, 2)
    flingPart.Transparency = 1
    flingPart.CanCollide = false
    flingPart.Massless = true
    flingPart.Name = "FlingPart"
    flingPart.Parent = targetChar
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = targetHRP
    weld.Part1 = flingPart
    weld.Parent = flingPart
    for i = 1, 20 do
        if not flingPart.Parent then
            break
        end
        if not targetHRP.Parent then
            break
        end
        if not targetHum.Parent then
            break
        end
        targetHum.Health = 0
        targetHum.Health = targetHum.MaxHealth
        task.wait(0.01)
        targetHum.Health = 0
        myRoot.CFrame = targetHRP.CFrame
        myRoot.Velocity = Vector3.new(50000, 50000, 50000)
        firetouchinterest(myRoot, flingPart, 0)
        task.wait()
        firetouchinterest(myRoot, flingPart, 1)
        task.wait()
    end
    flingPart:Destroy()
    myRoot.Velocity = Vector3.zero
end

local function killAll()
    local success = false
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if plr.Character then
                task.spawn(function()
                    pcall(function()
                        serverFling(plr)
                    end)
                end)
                success = true
            end
        end
    end
    return success
end

local function setFly(on)
    state.flying = on
    local char = player.Character
    local root = getRoot()
    local hum = getHum()
    if state.flyConn then
        state.flyConn:Disconnect()
        state.flyConn = nil
    end
    if state.bodyVelocity then
        state.bodyVelocity:Destroy()
        state.bodyVelocity = nil
    end
    if state.bodyGyro then
        state.bodyGyro:Destroy()
        state.bodyGyro = nil
    end
    if not on then
        if hum then
            hum.PlatformStand = false
        end
        return
    end
    if not root then
        return
    end
    if not hum then
        return
    end
    hum.PlatformStand = true
    hum.MaxHealth = math.huge
    hum.Health = math.huge
    state.bodyVelocity = Instance.new("BodyVelocity")
    state.bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    state.bodyVelocity.Velocity = Vector3.zero
    state.bodyVelocity.Parent = root
    state.bodyGyro = Instance.new("BodyGyro")
    state.bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    state.bodyGyro.P = 10000
    state.bodyGyro.CFrame = camera.CFrame
    state.bodyGyro.Parent = root
    state.flyConn = track(RunService.RenderStepped:Connect(function()
        if not state.flying then
            return
        end
        if not root then
            return
        end
        if not root.Parent then
            return
        end
        local move = hum.MoveDirection
        local look = camera.CFrame.LookVector
        local horizontal = Vector3.new(move.X, 0, move.Z)
        local vertical = look.Y * move.Magnitude
        local direction = horizontal + Vector3.new(0, vertical, 0)
        if direction.Magnitude > 0 then
            state.bodyVelocity.Velocity = direction.Unit * state.flySpeed
        else
            state.bodyVelocity.Velocity = Vector3.zero
        end
        state.bodyGyro.CFrame = camera.CFrame
    end))
    task.spawn(function()
        while state.flying do
            task.wait(0.5)
        end
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
            hum.PlatformStand = false
        end
    end)
end

local function setNoclip(on)
    state.noclip = on
    if state.noclipConn then
        state.noclipConn:Disconnect()
        state.noclipConn = nil
    end
    local c = player.Character
    if not c then
        return
    end
    if on then
        state.noclipConn = track(RunService.Stepped:Connect(function()
            local char = player.Character
            if not char then
                return
            end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    if p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end
        end))
    else
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = true
            end
        end
    end
end

local function setSpeedBoost(on)
    state.speedBoost = on
    if state.speedConn then
        state.speedConn:Disconnect()
        state.speedConn = nil
    end
    if not on then
        local h = getHum()
        if h then
            h.WalkSpeed = 16
        end
        return
    end
    state.speedConn = track(RunService.Heartbeat:Connect(function()
        local h = getHum()
        if h then
            h.WalkSpeed = state.walkSpeed
        end
    end))
end

local function setHighJump(on)
    state.highJump = on
    if state.jumpConn then
        state.jumpConn:Disconnect()
        state.jumpConn = nil
    end
    if not on then
        local h = getHum()
        if h then
            h.JumpPower = 50
        end
        return
    end
    state.jumpConn = track(RunService.Heartbeat:Connect(function()
        local h = getHum()
        if h then
            h.JumpPower = state.jumpPower
        end
    end))
end

local function enableTapTP(onButton)
    if state.tpConn then
        state.tpConn:Disconnect()
        state.tpConn = nil
    end
    state.tpMode = not state.tpMode
    if not state.tpMode then
        onButton.Text = "Click Teleport"
        return
    end
    onButton.Text = "Tap anywhere..."
    state.tpConn = track(UIS.InputBegan:Connect(function(input)
        if not state.tpMode then
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch then
            local guiObj = player.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
            for _, obj in ipairs(guiObj) do
                if obj:IsDescendantOf(pg.PocketGUI) then
                    return
                end
            end
            local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {player.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
            if result then
                local root = getRoot()
                if root then
                    root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
                end
            end
            state.tpMode = false
            onButton.Text = "Click Teleport"
            if state.tpConn then
                state.tpConn:Disconnect()
                state.tpConn = nil
            end
        end
    end))
end

local function respawnPlayer()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        end
    end
end

local function tpToPlayer(plr)
    local myRoot = getRoot()
    if not myRoot then
        return
    end
    local targetChar = workspace:FindFirstChild(plr.Name)
    if not targetChar then
        return
    end
    local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not tRoot then
        return
    end
    myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
end

local xrayOriginals = {}
local function setXRay(on)
    state.xray = on
    if on then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                if obj.Transparency < 0.8 then
                    xrayOriginals[obj] = obj.Transparency
                    obj.Transparency = 0.7
                end
            end
        end
    else
        for obj, orig in pairs(xrayOriginals) do
            if obj then
                if obj.Parent then
                    obj.Transparency = orig
                end
            end
        end
        xrayOriginals = {}
    end
end

local function setPlayerEsp(on)
    state.playerEsp = on
    if state.playerEspConn then
        state.playerEspConn:Disconnect()
        state.playerEspConn = nil
    end
    for _, h in pairs(state.playerHighlights) do
        if h then
            if h.Parent then
                h:Destroy()
            end
        end
    end
    state.playerHighlights = {}
    if not on then
        return
    end
    state.playerEspConn = track(RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                if plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        if hum.Health > 0 then
                            local hl = state.playerHighlights[plr.UserId]
                            if not hl then
                                hl = Instance.new("Highlight")
                                hl.FillTransparency = 0.5
                                hl.OutlineTransparency = 0
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.FillColor = Color3.fromRGB(255, 50, 50)
                                hl.OutlineColor = Color3.fromRGB(255, 100, 100)
                                hl.Parent = plr.Character
                                state.playerHighlights[plr.UserId] = hl
                            end
                        end
                    end
                end
            end
        end
    end))
end

local function getMM2Role(plr)
    local char = plr.Character
    if not char then
        return nil
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            if n:find("knife") then
                return "Murderer"
            end
            if n:find("dagger") then
                return "Murderer"
            end
            if n:find("gun") then
                return "Sheriff"
            end
            if n:find("revolver") then
                return "Sheriff"
            end
            if n:find("pistol") then
                return "Sheriff"
            end
        end
    end
    return nil
end

local function setMM2Esp(on)
    state.mm2Esp = on
    if state.mm2EspConn then
        state.mm2EspConn:Disconnect()
        state.mm2EspConn = nil
    end
    for _, h in pairs(state.mm2Highlights) do
        if h then
            if h.Parent then
                h:Destroy()
            end
        end
    end
    state.mm2Highlights = {}
    if not on then
        return
    end
    state.mm2EspConn = track(RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                if plr.Character then
                    local role = getMM2Role(plr)
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        if hum.Health > 0 then
                            local hl = state.mm2Highlights[plr.UserId]
                            if not hl then
                                hl = Instance.new("Highlight")
                                hl.FillTransparency = 0.55
                                hl.OutlineTransparency = 0
                                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Parent = plr.Character
                                state.mm2Highlights[plr.UserId] = hl
                            end
                            if role == "Murderer" then
                                hl.FillColor = Color3.fromRGB(255, 30, 30)
                                hl.OutlineColor = Color3.fromRGB(255, 100, 100)
                            elseif role == "Sheriff" then
                                hl.FillColor = Color3.fromRGB(40, 120, 255)
                                hl.OutlineColor = Color3.fromRGB(100, 180, 255)
                            else
                                hl.FillColor = Color3.fromRGB(40, 220, 80)
                                hl.OutlineColor = Color3.fromRGB(100, 255, 140)
                            end
                        end
                    end
                end
            end
        end
    end))
end

local function mm2GrabGun()
    local root = getRoot()
    if not root then
        return false
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            local n = obj.Name:lower()
            if n:find("gun") then
                root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                return true
            end
            if n:find("revolver") then
                root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                return true
            end
        end
    end
    return false
end

local function setAntiAfk(on)
    state.antiAfk = on
    if state.antiAfkConn then
        state.antiAfkConn:Disconnect()
        state.antiAfkConn = nil
    end
    if not on then
        return
    end
    state.antiAfkConn = track(player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end))
end

local gui = Instance.new("ScreenGui")
gui.Name = "PocketGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = pg

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 440, 0, 360)
main.Position = UDim2.new(0.5, -220, 0.5, -180)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local mainCr = Instance.new("UICorner")
mainCr.CornerRadius = UDim.new(0, 16)
mainCr.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(120, 80, 255)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.3
mainStroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 45)
title.Position = UDim2.new(0, 20, 0, 5)
title.BackgroundTransparency = 1
title.Text = "POCKETGUI"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))
}
titleGrad.Parent = title

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -40, 0, 40)
tabBar.Position = UDim2.new(0, 20, 0, 55)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.Parent = tabBar

local function createTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 75, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 150, 170)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    local cr = Instance.new("UICorner")
    cr.CornerRadius = UDim.new(0, 10)
    cr.Parent = btn
    return btn
end

local tabMove = createTab("MOVE")
local tabVisuals = createTab("VISUALS")
local tabPlayers = createTab("PLAYERS")
local tabMM2 = createTab("MM2")
local tabHuss = createTab("HUSS")

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -40, 1, -170)
content.Position = UDim2.new(0, 20, 0, 110)
content.BackgroundTransparency = 1
content.Parent = main

local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 2
    p.Visible = false
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Parent = content
    return p
end

local pageMove = createPage()
local pageVisuals = createPage()
local pagePlayers = createPage()
local pageMM2 = createPage()
local pageHuss = createPage()

local function createToggle(parent, text, posY)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 50)
    f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    f.Parent = parent
    local cr = Instance.new("UICorner")
    cr.CornerRadius = UDim.new(0, 10)
    cr.Parent = f
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 50, 0, 28)
    switchBg.Position = UDim2.new(1, -65, 0.5, -14)
    switchBg.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    switchBg.Parent = f
    local sbCr = Instance.new("UICorner")
    sbCr.CornerRadius = UDim.new(1, 0)
    sbCr.Parent = switchBg
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = UDim2.new(0, 3, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    knob.Parent = switchBg
    local kCr = Instance.new("UICorner")
    kCr.CornerRadius = UDim.new(1, 0)
    kCr.Parent = knob
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f
    return btn, switchBg, knob
end

local function createStepper(parent, text, posY)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 50)
    f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    f.Parent = parent
    local cr = Instance.new("UICorner")
    cr.CornerRadius = UDim.new(0, 10)
    cr.Parent = f
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -110, 1, 0)
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 35, 0, 35)
    minus.Position = UDim2.new(1, -85, 0.5, -17.5)
    minus.BackgroundColor3 = Color3.fromRGB(200, 60, 80)
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255, 255, 255)
    minus.Font = Enum.Font.GothamBlack
    minus.TextSize = 18
    minus.Parent = f
    local mCr = Instance.new("UICorner")
    mCr.CornerRadius = UDim.new(0, 8)
    mCr.Parent = minus
    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 35, 0, 35)
    plus.Position = UDim2.new(1, -45, 0.5, -17.5)
    plus.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255, 255, 255)
    plus.Font = Enum.Font.GothamBlack
    plus.TextSize = 18
    plus.Parent = f
    local pCr = Instance.new("UICorner")
    pCr.CornerRadius = UDim.new(0, 8)
    pCr.Parent = plus
    return lbl, minus, plus
end

local function createAction(parent, text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 60)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent
    local cr = Instance.new("UICorner")
    cr.CornerRadius = UDim.new(0, 8)
    cr.Parent = btn
    return btn
end

local flyBtn, flyBg, flyKnob = createToggle(pageMove, "Enable Fly", 0)
local flySpeedLabel, flySpeedMinus, flySpeedPlus = createStepper(pageMove, "Fly Speed: 60", 60)
local noclipBtn, noclipBg, noclipKnob = createToggle(pageMove, "Noclip", 120)
local speedLabel, speedMinus, speedPlus = createStepper(pageMove, "WalkSpeed: 16", 180)
local speedBtn, speedBg, speedKnob = createToggle(pageMove, "Apply Speed", 240)
local highJumpBtn, highJumpBg, highJumpKnob = createToggle(pageMove, "High Jump", 300)
local antiAfkBtn, antiAfkBg, antiAfkKnob = createToggle(pageMove, "Anti-AFK", 360)
local resetBtn = createAction(pageMove, "Respawn (Reset)", 420, Color3.fromRGB(220, 60, 80))

local tpBtn = createAction(pageVisuals, "Click Teleport", 0, Color3.fromRGB(80, 60, 180))
local espBtn, espBg, espKnob = createToggle(pageVisuals, "Player ESP", 60)
local xrayBtn, xrayBg, xrayKnob = createToggle(pageVisuals, "X-Ray", 120)

local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, -10, 1, 0)
playerListFrame.BackgroundTransparency = 1
playerListFrame.Parent = pagePlayers
local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 6)
playerLayout.Parent = playerListFrame

local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            row.Parent = playerListFrame
            local rcr = Instance.new("UICorner")
            rcr.CornerRadius = UDim.new(0, 10)
            rcr.Parent = row
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -170, 1, 0)
            nameLbl.Position = UDim2.new(0, 15, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = plr.Name
            nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 14
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = row
            local killPlayerBtn = Instance.new("TextButton")
            killPlayerBtn.Size = UDim2.new(0, 70, 1, -14)
            killPlayerBtn.Position = UDim2.new(1, -160, 0, 7)
            killPlayerBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 80)
            killPlayerBtn.Text = "Kill"
            killPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            killPlayerBtn.Font = Enum.Font.GothamBold
            killPlayerBtn.TextSize = 13
            killPlayerBtn.Parent = row
            local kcr = Instance.new("UICorner")
            kcr.CornerRadius = UDim.new(0, 8)
            kcr.Parent = killPlayerBtn
            local tpPlayerBtn = Instance.new("TextButton")
            tpPlayerBtn.Size = UDim2.new(0, 70, 1, -14)
            tpPlayerBtn.Position = UDim2.new(1, -85, 0, 7)
            tpPlayerBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
            tpPlayerBtn.Text = "TP"
            tpPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tpPlayerBtn.Font = Enum.Font.GothamBold
            tpPlayerBtn.TextSize = 13
            tpPlayerBtn.Parent = row
            local tcr = Instance.new("UICorner")
            tcr.CornerRadius = UDim.new(0, 8)
            tcr.Parent = tpPlayerBtn
            killPlayerBtn.MouseButton1Click:Connect(function()
                killPlayerBtn.Text = "..."
                task.spawn(function()
                    pcall(function()
                        serverFling(plr)
                    end)
                    killPlayerBtn.Text = "Kill"
                end)
            end)
            tpPlayerBtn.MouseButton1Click:Connect(function()
                tpToPlayer(plr)
            end)
        end
    end
end

refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

local killAllBtn = createAction(pageMM2, "Kill All (Instant)", 0, Color3.fromRGB(200, 30, 50))
local mm2EspBtn, mm2EspBg, mm2EspKnob = createToggle(pageMM2, "Role ESP", 60)
local mm2GunBtn = createAction(pageMM2, "Grab Gun", 120, Color3.fromRGB(40, 80, 120))

killAllBtn.MouseButton1Click:Connect(function()
    killAllBtn.Text = "Flinging..."
    local success = killAll()
    if success then
        killAllBtn.Text = "Killed All"
    else
        killAllBtn.Text = "No Players!"
    end
    task.delay(2, function()
        killAllBtn.Text = "Kill All (Instant)"
    end)
end)

mm2GunBtn.MouseButton1Click:Connect(function()
    local s = mm2GrabGun()
    if s then
        mm2GunBtn.Text = "Teleported"
    else
        mm2GunBtn.Text = "No Gun"
    end
    task.delay(1.5, function()
        mm2GunBtn.Text = "Grab Gun"
    end)
end)

local hussMunkeBtn = createAction(pageHuss, "Load MunkeHub", 0, Color3.fromRGB(60, 160, 90))
local hussDeltaBtn = createAction(pageHuss, "Load Delta Aim Assist", 60, Color3.fromRGB(60, 120, 200))

hussMunkeBtn.MouseButton1Click:Connect(function()
    pcall(function()
        loadstring(game:HttpGet('https://pastefy.app/uHZruyoj/raw'))()
    end)
end)
hussDeltaBtn.MouseButton1Click:Connect(function()
    pcall(function()
        loadstring(game:HttpGet("https://pastefy.app/3pRyePB8/raw"))()
    end)
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -40, 0, 40)
closeBtn.Position = UDim2.new(0, 20, 1, -55)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
closeBtn.Text = "HIDE MENU"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = main
local cbCr = Instance.new("UICorner")
cbCr.CornerRadius = UDim.new(0, 10)
cbCr.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

local allTabs = {tabMove, tabVisuals, tabPlayers, tabMM2, tabHuss}
local allPages = {pageMove, pageVisuals, pagePlayers, pageMM2, pageHuss}

local function selectTab(index)
    for i = 1, #allTabs do
        if i == index then
            TweenService:Create(allTabs[i], TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(75, 55, 140),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            allPages[i].Visible = true
            if i == 3 then
                refreshPlayerList()
            end
        else
            TweenService:Create(allTabs[i], TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 42),
                TextColor3 = Color3.fromRGB(150, 150, 170)
            }):Play()
            allPages[i].Visible = false
        end
    end
end

for i, tab in ipairs(allTabs) do
    tab.MouseButton1Click:Connect(function()
        selectTab(i)
    end)
end
selectTab(1)

local function animateToggle(bg, knob, isOn)
    if isOn then
        TweenService:Create(bg, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(60, 200, 100)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = UDim2.new(0.5, 3, 0.5, -11), 
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    else
        TweenService:Create(bg, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(45, 45, 60)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = UDim2.new(0, 3, 0.5, -11), 
            BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        }):Play()
    end
end

flyBtn.MouseButton1Click:Connect(function()
    setFly(not state.flying)
    animateToggle(flyBg, flyKnob, state.flying)
end)
noclipBtn.MouseButton1Click:Connect(function()
    setNoclip(not state.noclip)
    animateToggle(noclipBg, noclipKnob, state.noclip)
end)
speedBtn.MouseButton1Click:Connect(function()
    setSpeedBoost(not state.speedBoost)
    animateToggle(speedBg, speedKnob, state.speedBoost)
end)
espBtn.MouseButton1Click:Connect(function()
    setPlayerEsp(not state.playerEsp)
    animateToggle(espBg, espKnob, state.playerEsp)
end)
xrayBtn.MouseButton1Click:Connect(function()
    setXRay(not state.xray)
    animateToggle(xrayBg, xrayKnob, state.xray)
end)
mm2EspBtn.MouseButton1Click:Connect(function()
    setMM2Esp(not state.mm2Esp)
    animateToggle(mm2EspBg, mm2EspKnob, state.mm2Esp)
end)
antiAfkBtn.MouseButton1Click:Connect(function()
    setAntiAfk(not state.antiAfk)
    animateToggle(antiAfkBg, antiAfkKnob, state.antiAfk)
end)
highJumpBtn.MouseButton1Click:Connect(function()
    setHighJump(not state.highJump)
    animateToggle(highJumpBg, highJumpKnob, state.highJump)
end)
tpBtn.MouseButton1Click:Connect(function()
    enableTapTP(tpBtn)
end)
resetBtn.MouseButton1Click:Connect(function()
    respawnPlayer()
end)

speedMinus.MouseButton1Click:Connect(function()
    state.walkSpeed = math.clamp(state.walkSpeed - 5, 16, 500)
    speedLabel.Text = "WalkSpeed: " .. state.walkSpeed
end)
speedPlus.MouseButton1Click:Connect(function()
    state.walkSpeed = math.clamp(state.walkSpeed + 5, 16, 500)
    speedLabel.Text = "WalkSpeed: " .. state.walkSpeed
end)
flySpeedMinus.MouseButton1Click:Connect(function()
    state.flySpeed = math.clamp(state.flySpeed - 50, 10, 1000)
    flySpeedLabel.Text = "Fly Speed: " .. state.flySpeed
end)
flySpeedPlus.MouseButton1Click:Connect(function()
    state.flySpeed = math.clamp(state.flySpeed + 50, 10, 1000)
    flySpeedLabel.Text = "Fly Speed: " .. state.flySpeed
end)

local dragging = false
local dragInput, mousePos, framePos
local dragArea = Instance.new("Frame")
dragArea.Size = UDim2.new(1, 0, 0, 55)
dragArea.Position = UDim2.new(0, 0, 0, 0)
dragArea.BackgroundTransparency = 1
dragArea.Parent = main

dragArea.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

dragArea.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput then
        if dragging then
            local delta = input.Position - mousePos
            main.Position = UDim2.new(
                framePos.X.Scale, 
                framePos.X.Offset + delta.X, 
                framePos.Y.Scale, 
                framePos.Y.Offset + delta.Y
            )
        end
    end
end)

local floatGui = Instance.new("ScreenGui")
floatGui.Name = "PocketGUI_Float"
floatGui.ResetOnSpawn = false
floatGui.DisplayOrder = 1000
floatGui.Parent = pg

local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 55, 0, 55)
floatBtn.Position = UDim2.new(0, 20, 0.5, -27.5)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.Text = ""
floatBtn.BorderSizePixel = 0
floatBtn.AutoButtonColor = false
floatBtn.Parent = floatGui

local fbCr = Instance.new("UICorner")
fbCr.CornerRadius = UDim.new(0, 16)
fbCr.Parent = floatBtn

local fbGrad = Instance.new("UIGradient")
fbGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(165, 135, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255))
}
fbGrad.Rotation = 45
fbGrad.Parent = floatBtn

local fbStroke = Instance.new("UIStroke")
fbStroke.Color = Color3.fromRGB(255, 255, 255)
fbStroke.Thickness = 1.5
fbStroke.Transparency = 0.4
fbStroke.Parent = floatBtn

local pLogo = Instance.new("TextLabel")
pLogo.Size = UDim2.new(1, 0, 1, 0)
pLogo.BackgroundTransparency = 1
pLogo.Text = "P"
pLogo.TextColor3 = Color3.fromRGB(255, 255, 255)
pLogo.Font = Enum.Font.GothamBlack
pLogo.TextSize = 38
pLogo.TextXAlignment = Enum.TextXAlignment.Center
pLogo.TextYAlignment = Enum.TextYAlignment.Center
pLogo.ZIndex = 1
pLogo.Parent = floatBtn

local pShadow = pLogo:Clone()
pShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
pShadow.TextTransparency = 0.6
pShadow.Position = UDim2.new(0, 1, 0, 2)
pShadow.ZIndex = 0
pShadow.Parent = floatBtn

local defaultSize = UDim2.new(0, 55, 0, 55)
local hoverSize = UDim2.new(0, 60, 0, 60)
local clickSize = UDim2.new(0, 50, 0, 50)

floatBtn.MouseEnter:Connect(function()
    TweenService:Create(floatBtn, TweenInfo.new(0.15), {Size = hoverSize}):Play()
end)
floatBtn.MouseLeave:Connect(function()
    TweenService:Create(floatBtn, TweenInfo.new(0.15), {Size = defaultSize}):Play()
end)

local fbDragging, fbDragStart, fbStartPos
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        fbDragging = true
        fbDragStart = input.Position
        fbStartPos = floatBtn.Position
        TweenService:Create(floatBtn, TweenInfo.new(0.1), {Size = clickSize}):Play()
    end
end)
floatBtn.InputChanged:Connect(function(input)
    if fbDragging then
        if input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - fbDragStart
            floatBtn.Position = UDim2.new(
                fbStartPos.X.Scale, 
                fbStartPos.X.Offset + delta.X, 
                fbStartPos.Y.Scale, 
                fbStartPos.Y.Offset + delta.Y
            )
        end
    end
end)
floatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        fbDragging = false
        TweenService:Create(floatBtn, TweenInfo.new(0.1), {Size = defaultSize}):Play()
        local delta = input.Position - fbDragStart
        if delta.Magnitude < 10 then
            main.Visible = not main.Visible
        end
    end
end)

print("[PocketGUI] v27.2 Loaded. Fully Expanded Code.")
