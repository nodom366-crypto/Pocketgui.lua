-- PocketGUI v17.1 (Super Cool Floating Button + Premium UI)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild("PocketGUI") then pg.PocketGUI:Destroy() end
if pg:FindFirstChild("PocketGUI_Float") then pg.PocketGUI_Float:Destroy() end

local state = {
    invisible=false, noclip=false, walkSpeed=16, 
    speedBoost=false, xray=false, playerEsp=false,
    noclipConn=nil, speedConn=nil,
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

local function setSpeedBoost(on)
    state.speedBoost=on
    if state.speedConn then state.speedConn:Disconnect() state.speedConn=nil end
    if not on then return end
    state.speedConn=track(RunService.Heartbeat:Connect(function()
        local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end
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

-- ==========================================
-- PREMIUM UI BUILD
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name="PocketGUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=999; gui.Parent=pg

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 420, 0, 320)
main.Position = UDim2.new(0.5, -210, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24); main.BorderSizePixel = 0; main.Active = true; main.Parent = gui
local mainCr = Instance.new("UICorner"); mainCr.CornerRadius = UDim.new(0,16); mainCr.Parent = main
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(120, 80, 255); mainStroke.Thickness = 2; mainStroke.Transparency = 0.3; mainStroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 45); title.Position = UDim2.new(0, 20, 0, 5)
title.BackgroundTransparency = 1; title.Text = "POCKETGUI"
title.TextColor3 = Color3.fromRGB(255,255,255); title.Font = Enum.Font.GothamBlack; title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = main
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))}
titleGrad.Parent = title

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -40, 0, 40); tabBar.Position = UDim2.new(0, 20, 0, 55); tabBar.BackgroundTransparency = 1; tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 8); tabLayout.Parent = tabBar

local function createTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 85, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42); btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 150, 170); btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.BorderSizePixel = 0; btn.Parent = tabBar
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = btn
    return btn
end

local tabMove = createTab("MOVE"); local tabVisuals = createTab("VISUALS"); local tabPlayers = createTab("PLAYERS")

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -40, 1, -130); content.Position = UDim2.new(0, 20, 0, 110); content.BackgroundTransparency = 1; content.Parent = main

local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0; p.ScrollBarThickness = 2
    p.Visible = false; p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
    return p
end

local pageMove=createPage() local pageVisuals=createPage() local pagePlayers=createPage()

local function createToggle(parent, text, posY)
    local f = Instance.new("Frame"); f.Size = UDim2.new(1, -10, 0, 50); f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 38); f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,10); cr.Parent = f
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -100, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    
    local switchBg = Instance.new("Frame"); switchBg.Size = UDim2.new(0, 50, 0, 28); switchBg.Position = UDim2.new(1, -65, 0.5, -14)
    switchBg.BackgroundColor3 = Color3.fromRGB(45,45,60); switchBg.Parent = f
    local sbCr = Instance.new("UICorner"); sbCr.CornerRadius = UDim.new(1, 0); sbCr.Parent = switchBg
    
    local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, 22, 0, 22); knob.Position = UDim2.new(0, 3, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(150,150,150); knob.Parent = switchBg
    local kCr = Instance.new("UICorner"); kCr.CornerRadius = UDim.new(1, 0); kCr.Parent = knob
    
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.Parent = f
    return btn, switchBg, knob
end

local function createStepper(parent, text, posY)
    local f = Instance.new("Frame"); f.Size = UDim2.new(1, -10, 0, 50); f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 38); f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,10); cr.Parent = f
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -110, 1, 0); lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 14; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local minus = Instance.new("TextButton"); minus.Size = UDim2.new(0, 35, 0, 35); minus.Position = UDim2.new(1, -85, 0.5, -17.5)
    minus.BackgroundColor3 = Color3.fromRGB(200,60,80); minus.Text = "-"; minus.TextColor3 = Color3.fromRGB(255,255,255); minus.Font = Enum.Font.GothamBlack; minus.TextSize = 18; minus.Parent = f
    local mCr = Instance.new("UICorner"); mCr.CornerRadius = UDim.new(0,8); mCr.Parent = minus
    local plus = Instance.new("TextButton"); plus.Size = UDim2.new(0, 35, 0, 35); plus.Position = UDim2.new(1, -45, 0.5, -17.5)
    plus.BackgroundColor3 = Color3.fromRGB(60,180,90); plus.Text = "+"; plus.TextColor3 = Color3.fromRGB(255,255,255); plus.Font = Enum.Font.GothamBlack; plus.TextSize = 18; plus.Parent = f
    local pCr = Instance.new("UICorner"); pCr.CornerRadius = UDim.new(0,8); pCr.Parent = plus
    return lbl, minus, plus
end

-- PAGE 1: MOVE
local noclipBtn, noclipBg, noclipKnob = createToggle(pageMove, "Noclip", 0)
local speedLabel, speedMinus, speedPlus = createStepper(pageMove, "WalkSpeed: 16", 60)
local speedBtn, speedBg, speedKnob = createToggle(pageMove, "Apply Speed", 120)

-- PAGE 2: VISUALS
local invisBtn, invisBg, invisKnob = createToggle(pageVisuals, "Invisibility", 0)
local espBtn, espBg, espKnob = createToggle(pageVisuals, "Player ESP", 60)
local xrayBtn, xrayBg, xrayKnob = createToggle(pageVisuals, "X-Ray", 120)

-- PAGE 3: PLAYERS
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, -10, 1, 0); playerListFrame.BackgroundTransparency = 1; playerListFrame.Parent = pagePlayers
local playerLayout = Instance.new("UIListLayout"); playerLayout.Padding = UDim.new(0, 6); playerLayout.Parent = playerListFrame

local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50); row.BackgroundColor3 = Color3.fromRGB(28, 28, 38); row.Parent = playerListFrame
            local rcr = Instance.new("UICorner"); rcr.CornerRadius = UDim.new(0,10); rcr.Parent = row
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -120, 1, 0); nameLbl.Position = UDim2.new(0, 15, 0, 0)
            nameLbl.BackgroundTransparency = 1; nameLbl.Text = plr.Name; nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
            nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 14; nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.Parent = row
            
            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 85, 1, -14); tpBtn.Position = UDim2.new(1, -100, 0, 7)
            tpBtn.BackgroundColor3 = Color3.fromRGB(60,120,200); tpBtn.Text = "Teleport"
            tpBtn.TextColor3 = Color3.fromRGB(255,255,255); tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 13; tpBtn.Parent = row
            local tcr = Instance.new("UICorner"); tcr.CornerRadius = UDim.new(0,8); tcr.Parent = tpBtn
            
            tpBtn.MouseButton1Click:Connect(function() tpToPlayer(plr) end)
        end
    end
end
refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -40, 0, 40); closeBtn.Position = UDim2.new(0, 20, 1, -55)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55); closeBtn.Text = "HIDE MENU"; closeBtn.TextColor3 = Color3.fromRGB(200,200,220)
closeBtn.Font = Enum.Font.GothamBlack; closeBtn.TextSize = 14; closeBtn.BorderSizePixel = 0; closeBtn.Parent = main
local cbCr = Instance.new("UICorner"); cbCr.CornerRadius = UDim.new(0,10); cbCr.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local allTabs = {tabMove, tabVisuals, tabPlayers}
local allPages = {pageMove, pageVisuals, pagePlayers}

local function selectTab(index)
    for i = 1, #allTabs do
        if i == index then
            TweenService:Create(allTabs[i], TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(75, 55, 140), TextColor3 = Color3.fromRGB(255,255,255)}):Play()
            allPages[i].Visible = true
            if i == 3 then refreshPlayerList() end
        else
            TweenService:Create(allTabs[i], TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 42), TextColor3 = Color3.fromRGB(150, 150, 170)}):Play()
            allPages[i].Visible = false
        end
    end
end

for i, tab in ipairs(allTabs) do tab.MouseButton1Click:Connect(function() selectTab(i) end) end
selectTab(1)

local function animateToggle(bg, knob, isOn)
    if isOn then
        TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60,200,100)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 3, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255,255,255)}):Play()
    else
        TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45,45,60)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -11), BackgroundColor3 = Color3.fromRGB(150,150,150)}):Play()
    end
end

noclipBtn.MouseButton1Click:Connect(function() setNoclip(not state.noclip) animateToggle(noclipBg, noclipKnob, state.noclip) end)
invisBtn.MouseButton1Click:Connect(function() toggleInvis() animateToggle(invisBg, invisKnob, state.invisible) end)
speedBtn.MouseButton1Click:Connect(function() setSpeedBoost(not state.speedBoost) animateToggle(speedBg, speedKnob, state.speedBoost) end)
espBtn.MouseButton1Click:Connect(function() setPlayerEsp(not state.playerEsp) animateToggle(espBg, espKnob, state.playerEsp) end)
xrayBtn.MouseButton1Click:Connect(function() setXRay(not state.xray) animateToggle(xrayBg, xrayKnob, state.xray) end)

speedMinus.MouseButton1Click:Connect(function()
    state.walkSpeed = math.clamp(state.walkSpeed - 5, 16, 500)
    speedLabel.Text = "WalkSpeed: " .. state.walkSpeed
end)
speedPlus.MouseButton1Click:Connect(function()
    state.walkSpeed = math.clamp(state.walkSpeed + 5, 16, 500)
    speedLabel.Text = "WalkSpeed: " .. state.walkSpeed
end)

-- SUPER COOL DRAGGABLE FLOATING BUTTON
local floatGui = Instance.new("ScreenGui")
floatGui.Name="PocketGUI_Float"; floatGui.ResetOnSpawn=false; floatGui.DisplayOrder=1000; floatGui.Parent=pg
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 55, 0, 55); floatBtn.Position = UDim2.new(0, 20, 0.5, -27.5)
floatBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 180); floatBtn.Text = ""; floatBtn.BorderSizePixel = 0; floatBtn.Parent = floatGui
local fbCr = Instance.new("UICorner"); fbCr.CornerRadius = UDim.new(1, 0); fbCr.Parent = floatBtn

local fbGrad = Instance.new("UIGradient")
fbGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 80, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 150, 255))}
fbGrad.Parent = floatBtn

local fbStroke = Instance.new("UIStroke"); fbStroke.Color = Color3.fromRGB(200, 180, 255); fbStroke.Thickness = 2; fbStroke.Transparency = 0.2; fbStroke.Parent = floatBtn

local fbIcon = Instance.new("Frame"); fbIcon.Size = UDim2.new(0, 22, 0, 18); fbIcon.Position = UDim2.new(0.5, -11, 0.5, -9)
fbIcon.BackgroundTransparency = 1; fbIcon.Parent = floatBtn
for i = 0, 2 do
    local line = Instance.new("Frame"); line.Size = UDim2.new(1, 0, 0, 3); line.Position = UDim2.new(0, 0, 0, i * 7)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255); line.BorderSizePixel = 0; line.Parent = fbIcon
end

-- DRAG LOGIC
local dragging, dragStart, startPos
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = floatBtn.Position
    end
end)
floatBtn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        floatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
floatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        local delta = input.Position - dragStart
        if delta.Magnitude < 10 then
            main.Visible = not main.Visible
        end
    end
end)

print("[PocketGUI] v17.1 Loaded! Super Cool Floating Button active.")
