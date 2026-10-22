-- PocketGUI v15.1 (Console Logs + Speed Fix)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild("PocketGUI") then pg.PocketGUI:Destroy() end
if pg:FindFirstChild("PocketGUI_Float") then pg.PocketGUI_Float:Destroy() end

local state = {
    invisible=false, noclip=false, walkSpeed=16, jumpPower=50,
    speedBoost=false, infJump=false, xray=false, nofog=false, lowGravity=false,
    playerEsp=false, spectating=false, 
    noclipConn=nil, speedConn=nil, jumpConn=nil, 
    playerEspConn=nil, playerHighlights={}, connections={}
}

local function track(c) table.insert(state.connections, c) return c end
local function getRoot() local c=player.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=player.Character return c and c:FindFirstChildOfClass("Humanoid") end

-- FEATURES
local function setNoclip(on)
    state.noclip=on
    if state.noclipConn then state.noclipConn:Disconnect() state.noclipConn=nil end
    if not on then return end
    state.noclipConn=track(RunService.Stepped:Connect(function()
        local c=player.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end
    end))
end

local function toggleInvis()
    state.invisible=not state.invisible
    local c=player.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
            p.LocalTransparencyModifier=state.invisible and 1 or 0
        elseif p:IsA("Decal") then p.Transparency=state.invisible and 1 or 0 end
    end
end

-- SPEED BOOST (WITH CONSOLE LOGS)
local function setSpeedBoost(on)
    state.speedBoost=on
    if state.speedConn then state.speedConn:Disconnect() state.speedConn=nil end
    
    if not on then 
        print("[PocketGUI] Speed Boost: DISABLED")
        return 
    end
    
    print("[PocketGUI] Speed Boost: ENABLED. Attempting to set speed to: " .. state.walkSpeed)
    
    state.speedConn=track(RunService.Heartbeat:Connect(function()
        local h=getHum()
        if h then 
            h.WalkSpeed=state.walkSpeed 
        end
    end))
    
    -- Wait 1 second, then check if the game reverted the speed
    task.delay(1, function()
        local h = getHum()
        if h then
            if h.WalkSpeed >= state.walkSpeed then
                print("[PocketGUI] SUCCESS: Speed is holding at " .. h.WalkSpeed)
            else
                warn("[PocketGUI] BLOCKED: The game anti-cheat reverted your speed back to " .. h.WalkSpeed)
            end
        end
    end)
end

local function setInfJump(on)
    state.infJump=on
    if state.jumpConn then state.jumpConn:Disconnect() state.jumpConn=nil end
    if not on then return end
    state.jumpConn=track(UIS.JumpRequest:Connect(function()
        local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
end

local xrayOriginals = {}
local function setXRay(on)
    state.xray = on
    if on then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 0.8 then
                xrayOriginals[obj] = obj.Transparency; obj.Transparency = 0.7
            end
        end
    else
        for obj, orig in pairs(xrayOriginals) do if obj and obj.Parent then obj.Transparency = orig end end
        xrayOriginals = {}
    end
end

local se, ss
local function setNoFog(on)
    state.nofog=on
    if on then se=Lighting.FogEnd; ss=Lighting.FogStart; Lighting.FogEnd=1e5; Lighting.FogStart=1e5
    else if se then Lighting.FogEnd=se end; if ss then Lighting.FogStart=ss end end
end

local function setLowGravity(on)
    state.lowGravity=on
    workspace.Gravity = on and 50 or 196.2
end

local function setPlayerEsp(on)
    state.playerEsp = on
    if state.playerEspConn then state.playerEspConn:Disconnect() state.playerEspConn = nil end
    for _, h in pairs(state.playerHighlights) do if h and h.Parent then h:Destroy() end end
    state.playerHighlights = {}
    if not on then return end
    state.playerEspConn = track(RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local hl = state.playerHighlights[plr.UserId]
                    if not hl or not hl.Parent then
                        hl = Instance.new("Highlight"); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillColor = Color3.fromRGB(255, 50, 50); hl.OutlineColor = Color3.fromRGB(255, 100, 100); hl.Parent = plr.Character
                        state.playerHighlights[plr.UserId] = hl
                    end
                end
            end
        end
    end))
end

local function tpToPlayer(plr)
    local myRoot = getRoot()
    local targetChar = workspace:FindFirstChild(plr.Name)
    local tRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso"))
    if myRoot and tRoot then myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0) end
end

local function spectatePlayer(plr)
    state.spectating = not state.spectating
    local targetChar = workspace:FindFirstChild(plr.Name)
    if state.spectating and targetChar then
        local hum = targetChar:FindFirstChildOfClass("Humanoid")
        if hum then camera.CameraSubject = hum end
    else
        local myHum = getHum()
        if myHum then camera.CameraSubject = myHum end
        state.spectating = false
    end
end

-- ==========================================
-- PREMIUM UI BUILD
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name="PocketGUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=999; gui.Parent=pg

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 420, 0, 320)
main.Position = UDim2.new(0.5, -210, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(16, 16, 22); main.BorderSizePixel = 0; main.Active = true; main.Parent = gui
local mainCr = Instance.new("UICorner"); mainCr.CornerRadius = UDim.new(0,12); mainCr.Parent = main
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(80, 80, 110); mainStroke.Thickness = 1.5; mainStroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 45); title.Position = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1; title.Text = "POCKETGUI"
title.TextColor3 = Color3.fromRGB(255,255,255); title.Font = Enum.Font.GothamBlack; title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = main
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))}
titleGrad.Parent = title

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -30, 0, 40); tabBar.Position = UDim2.new(0, 15, 0, 50); tabBar.BackgroundTransparency = 1; tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 6); tabLayout.Parent = tabBar

local function createTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 85, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35); btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 150, 170); btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.BorderSizePixel = 0; btn.Parent = tabBar
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 8); cr.Parent = btn
    return btn
end

local tabMove = createTab("MOVE"); local tabVisuals = createTab("VISUALS")
local tabCombat = createTab("PLAYERS"); local tabMisc = createTab("MISC")

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -30, 1, -130); content.Position = UDim2.new(0, 15, 0, 100); content.BackgroundTransparency = 1; content.Parent = main

local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0; p.ScrollBarThickness = 2
    p.Visible = false; p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
    return p
end

local pageMove=createPage() local pageVisuals=createPage() local pageCombat=createPage() local pageMisc=createPage()

local function createToggle(parent, text, posY)
    local f = Instance.new("Frame"); f.Size = UDim2.new(1, -10, 0, 45); f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 35); f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,8); cr.Parent = f
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -90, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 60, 1, -14); btn.Position = UDim2.new(1, -75, 0, 7)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,50); btn.Text = "OFF"; btn.TextColor3 = Color3.fromRGB(120,120,140)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.Parent = f
    local bcr = Instance.new("UICorner"); bcr.CornerRadius = UDim.new(0,6); bcr.Parent = btn
    return btn
end

local function createAction(parent, text, posY, color)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 40); btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(35, 35, 48); btn.Text = text; btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,8); cr.Parent = btn
    return btn
end

-- PAGE 1: MOVE
local noclipBtn = createToggle(pageMove, "Noclip", 0)
local speedBtn = createToggle(pageMove, "Speed Boost", 55)
local infJumpBtn = createToggle(pageMove, "Infinite Jump", 110)
local lowGravBtn = createToggle(pageMove, "Low Gravity", 165)

-- PAGE 2: VISUALS
local invisBtn = createToggle(pageVisuals, "Invisibility", 0)
local espBtn = createToggle(pageVisuals, "Player ESP", 55)
local xrayBtn = createToggle(pageVisuals, "X-Ray", 110)
local nofogBtn = createToggle(pageVisuals, "No Fog", 165)

-- PAGE 3: PLAYERS
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, -10, 1, 0); playerListFrame.BackgroundTransparency = 1; playerListFrame.Parent = pageCombat
local playerLayout = Instance.new("UIListLayout"); playerLayout.Padding = UDim.new(0, 6); playerLayout.Parent = playerListFrame

local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 45); row.BackgroundColor3 = Color3.fromRGB(25, 25, 35); row.Parent = playerListFrame
            local rcr = Instance.new("UICorner"); rcr.CornerRadius = UDim.new(0,8); rcr.Parent = row
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -140, 1, 0); nameLbl.Position = UDim2.new(0, 15, 0, 0)
            nameLbl.BackgroundTransparency = 1; nameLbl.Text = plr.Name; nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
            nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 14; nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.Parent = row
            
            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 60, 1, -10); tpBtn.Position = UDim2.new(1, -130, 0, 5)
            tpBtn.BackgroundColor3 = Color3.fromRGB(60,120,180); tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.fromRGB(255,255,255); tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 12; tpBtn.Parent = row
            local tcr = Instance.new("UICorner"); tcr.CornerRadius = UDim.new(0,6); tcr.Parent = tpBtn
            
            local specBtn = Instance.new("TextButton")
            specBtn.Size = UDim2.new(0, 60, 1, -10); specBtn.Position = UDim2.new(1, -65, 0, 5)
            specBtn.BackgroundColor3 = Color3.fromRGB(150,60,180); specBtn.Text = "Watch"
            specBtn.TextColor3 = Color3.fromRGB(255,255,255); specBtn.Font = Enum.Font.GothamBold; specBtn.TextSize = 12; specBtn.Parent = row
            local scr = Instance.new("UICorner"); scr.CornerRadius = UDim.new(0,6); scr.Parent = specBtn
            
            tpBtn.MouseButton1Click:Connect(function() tpToPlayer(plr) end)
            specBtn.MouseButton1Click:Connect(function() spectatePlayer(plr) end)
        end
    end
end
refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

-- PAGE 4: MISC
local resetCamBtn = createAction(pageMisc, "Reset Camera", 0, Color3.fromRGB(60, 180, 100))
resetCamBtn.MouseButton1Click:Connect(function()
    state.spectating = false
    local h = getHum()
    if h then camera.CameraSubject = h end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -30, 0, 40); closeBtn.Position = UDim2.new(0, 15, 1, -50)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,48,90); closeBtn.Text = "HIDE MENU"; closeBtn.TextColor3 = Color3.fromRGB(215,205,250)
closeBtn.Font = Enum.Font.GothamBlack; closeBtn.TextSize = 14; closeBtn.BorderSizePixel = 0; closeBtn.Parent = main
local cbCr = Instance.new("UICorner"); cbCr.CornerRadius = UDim.new(0,8); cbCr.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local allTabs = {tabMove, tabVisuals, tabCombat, tabMisc}
local allPages = {pageMove, pageVisuals, pageCombat, pageMisc}

local function selectTab(index)
    for i = 1, #allTabs do
        if i == index then
            TweenService:Create(allTabs[i], TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60,50,100), TextColor3 = Color3.fromRGB(255,255,255)}):Play()
            allPages[i].Visible = true
            if i == 3 then refreshPlayerList() end
        else
            TweenService:Create(allTabs[i], TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(25, 25, 35), TextColor3 = Color3.fromRGB(150, 150, 170)}):Play()
            allPages[i].Visible = false
        end
    end
end

for i, tab in ipairs(allTabs) do tab.MouseButton1Click:Connect(function() selectTab(i) end) end
selectTab(1)

local function updateToggle(btn,on)
    if on then 
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60,200,100)}):Play()
        btn.Text = "ON" 
    else 
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,50)}):Play()
        btn.Text = "OFF" 
    end
end

noclipBtn.MouseButton1Click:Connect(function() setNoclip(not state.noclip) updateToggle(noclipBtn, state.noclip) end)
invisBtn.MouseButton1Click:Connect(function() toggleInvis() updateToggle(invisBtn, state.invisible) end)
speedBtn.MouseButton1Click:Connect(function() setSpeedBoost(not state.speedBoost) updateToggle(speedBtn, state.speedBoost) end)
espBtn.MouseButton1Click:Connect(function() setPlayerEsp(not state.playerEsp) updateToggle(espBtn, state.playerEsp) end)
xrayBtn.MouseButton1Click:Connect(function() setXRay(not state.xray) updateToggle(xrayBtn, state.xray) end)
infJumpBtn.MouseButton1Click:Connect(function() setInfJump(not state.infJump) updateToggle(infJumpBtn, state.infJump) end)
lowGravBtn.MouseButton1Click:Connect(function() setLowGravity(not state.lowGravity) updateToggle(lowGravBtn, state.lowGravity) end)
nofogBtn.MouseButton1Click:Connect(function() setNoFog(not state.nofog) updateToggle(nofogBtn, state.nofog) end)

-- FLOATING CIRCLE
local floatGui = Instance.new("ScreenGui")
floatGui.Name="PocketGUI_Float"; floatGui.ResetOnSpawn=false; floatGui.DisplayOrder=1000; floatGui.Parent=pg
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 50, 0, 50); floatBtn.Position = UDim2.new(0, 20, 0.5, -25)
floatBtn.BackgroundColor3 = Color3.fromRGB(100,70,240); floatBtn.Text = ""; floatBtn.BorderSizePixel = 0; floatBtn.Parent = floatGui
local fbCr = Instance.new("UICorner"); fbCr.CornerRadius = UDim.new(1, 0); fbCr.Parent = floatBtn
local fbStroke = Instance.new("UIStroke"); fbStroke.Color = Color3.fromRGB(180, 140, 255); fbStroke.Thickness = 2; fbStroke.Parent = floatBtn
floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

print("[PocketGUI] v15.1 Loaded! Test the Speed Boost and check the console.")
