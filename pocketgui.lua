-- PocketGUI v13.0 (Bulletproof UI + Instant Kill)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild("PocketGUI") then pg.PocketGUI:Destroy() end
if pg:FindFirstChild("PocketGUI_Float") then pg.PocketGUI_Float:Destroy() end

local state = {
    invisible=false, noclip=false, walkSpeed=16, jumpPower=50,
    speedBoost=false, xray=false, playerEsp=false, killAura=false, reach=3.5, hitbox=false,
    noclipConn=nil, speedConn=nil, auraConn=nil, hitboxConn=nil,
    playerEspConn=nil, playerHighlights={}, connections={}
}

local function track(c) table.insert(state.connections, c) return c end
local function getRoot() local c=player.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=player.Character return c and c:FindFirstChildOfClass("Humanoid") end

-- INSTANT KILL
local function instantKill(targetPlayer)
    local targetChar = workspace:FindFirstChild(targetPlayer.Name)
    if not targetChar then return end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, v in ipairs(targetChar:GetDescendants()) do
            if v:IsA("Motor6D") then v.Part0 = nil end
        end
        hum.Health = 0
    end
end

-- NOCLIP
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

-- INVIS
local function toggleInvis()
    state.invisible=not state.invisible
    local c=player.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then
            p.LocalTransparencyModifier=state.invisible and 1 or 0
        elseif p:IsA("Decal") then p.Transparency=state.invisible and 1 or 0 end
    end
end

-- SPEED
local function setSpeedBoost(on)
    state.speedBoost=on
    if state.speedConn then state.speedConn:Disconnect() state.speedConn=nil end
    if not on then return end
    state.speedConn=track(RunService.Heartbeat:Connect(function()
        local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end
    end))
end

-- XRAY
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

-- ESP
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
                        hl = Instance.new("Highlight"); hl.FillTransparency = 0.55; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillColor = Color3.fromRGB(255, 60, 60); hl.OutlineColor = Color3.fromRGB(255, 140, 140); hl.Parent = plr.Character
                        state.playerHighlights[plr.UserId] = hl
                    end
                end
            end
        end
    end))
end

-- ==========================================
-- SIMPLE BULLETPROOF GUI
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name="PocketGUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=999; gui.Parent=pg

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 300)
main.Position = UDim2.new(0.5, -200, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
local mainCr = Instance.new("UICorner"); mainCr.CornerRadius = UDim.new(0, 10); mainCr.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "PocketGUI"
title.TextColor3 = Color3.fromRGB(200, 100, 255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

-- SIMPLE TAB BAR (Fixed Layout, No Scrolling)
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 35)
tabBar.Position = UDim2.new(0, 10, 0, 45)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 4); tabLayout.Parent = tabBar

local function createTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(170, 170, 190)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = tabBar
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 6); cr.Parent = btn
    return btn
end

local tabMove = createTab("MOVE")
local tabVisuals = createTab("VISUAL")
local tabPlayers = createTab("PLAYERS")

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -130)
content.Position = UDim2.new(0, 10, 0, 90)
content.BackgroundTransparency = 1
content.Parent = main

local pageMove = Instance.new("ScrollingFrame")
pageMove.Size = UDim2.new(1, 0, 1, 0); pageMove.BackgroundTransparency = 1; pageMove.Visible = false; pageMove.Parent = content
pageMove.CanvasSize = UDim2.new(0,0,0,0); pageMove.AutomaticCanvasSize = Enum.AutomaticSize.Y

local pageVisuals = Instance.new("ScrollingFrame")
pageVisuals.Size = UDim2.new(1, 0, 1, 0); pageVisuals.BackgroundTransparency = 1; pageVisuals.Visible = false; pageVisuals.Parent = content
pageVisuals.CanvasSize = UDim2.new(0,0,0,0); pageVisuals.AutomaticCanvasSize = Enum.AutomaticSize.Y

local pagePlayers = Instance.new("ScrollingFrame")
pagePlayers.Size = UDim2.new(1, 0, 1, 0); pagePlayers.BackgroundTransparency = 1; pagePlayers.Visible = false; pagePlayers.Parent = content
pagePlayers.CanvasSize = UDim2.new(0,0,0,0); pagePlayers.AutomaticCanvasSize = Enum.AutomaticSize.Y

local function createToggle(parent, text, posY)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 40)
    f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = f
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 1, -10)
    btn.Position = UDim2.new(1, -70, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(150, 150, 165)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.Parent = f
    local bcr = Instance.new("UICorner"); bcr.CornerRadius = UDim.new(0,4); bcr.Parent = btn
    return btn
end

-- PAGE 1: MOVE
local noclipBtn = createToggle(pageMove, "Noclip", 0)
local speedBtn = createToggle(pageMove, "Speed Boost (16)", 45)

-- PAGE 2: VISUAL
local invisBtn = createToggle(pageVisuals, "Invisibility", 0)
local espBtn = createToggle(pageVisuals, "Player ESP", 45)
local xrayBtn = createToggle(pageVisuals, "X-Ray", 90)

-- PAGE 3: PLAYERS
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, -10, 1, 0)
playerListFrame.BackgroundTransparency = 1
playerListFrame.Parent = pagePlayers
local playerLayout = Instance.new("UIListLayout"); playerLayout.Padding = UDim.new(0, 4); playerLayout.Parent = playerListFrame

local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 40)
            row.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
            row.Parent = playerListFrame
            local rcr = Instance.new("UICorner"); rcr.CornerRadius = UDim.new(0,6); rcr.Parent = row
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -130, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = plr.Name
            nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 13
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = row
            
            local killBtn = Instance.new("TextButton")
            killBtn.Size = UDim2.new(0, 55, 1, -10)
            killBtn.Position = UDim2.new(1, -120, 0, 5)
            killBtn.BackgroundColor3 = Color3.fromRGB(220,60,80)
            killBtn.Text = "Kill"
            killBtn.TextColor3 = Color3.fromRGB(255,255,255)
            killBtn.Font = Enum.Font.GothamBlack
            killBtn.TextSize = 12
            killBtn.Parent = row
            local kcr = Instance.new("UICorner"); kcr.CornerRadius = UDim.new(0,4); kcr.Parent = killBtn
            
            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 55, 1, -10)
            tpBtn.Position = UDim2.new(1, -60, 0, 5)
            tpBtn.BackgroundColor3 = Color3.fromRGB(60,120,180)
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
            tpBtn.Font = Enum.Font.GothamBlack
            tpBtn.TextSize = 12
            tpBtn.Parent = row
            local tcr = Instance.new("UICorner"); tcr.CornerRadius = UDim.new(0,4); tcr.Parent = tpBtn
            
            killBtn.MouseButton1Click:Connect(function() instantKill(plr) end)
            tpBtn.MouseButton1Click:Connect(function()
                local myRoot = getRoot()
                local targetChar = workspace:FindFirstChild(plr.Name)
                local tRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso"))
                if myRoot and tRoot then myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0) end
            end)
        end
    end
end
refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -20, 0, 35)
closeBtn.Position = UDim2.new(0, 10, 1, -45)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 48, 90)
closeBtn.Text = "Hide Menu"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.Parent = main
local cbCr = Instance.new("UICorner"); cbCr.CornerRadius = UDim.new(0,6); cbCr.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local allTabs = {tabMove, tabVisuals, tabPlayers}
local allPages = {pageMove, pageVisuals, pagePlayers}

local function selectTab(index)
    for i = 1, #allTabs do
        if i == index then
            allTabs[i].BackgroundColor3 = Color3.fromRGB(70, 60, 120)
            allTabs[i].TextColor3 = Color3.fromRGB(255,255,255)
            allPages[i].Visible = true
            if i == 3 then refreshPlayerList() end
        else
            allTabs[i].BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            allTabs[i].TextColor3 = Color3.fromRGB(170, 170, 190)
            allPages[i].Visible = false
        end
    end
end

for i, tab in ipairs(allTabs) do tab.MouseButton1Click:Connect(function() selectTab(i) end) end
selectTab(1)

local function updateToggle(btn,on)
    if on then btn.BackgroundColor3 = Color3.fromRGB(60, 200, 100); btn.Text = "ON"
    else btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55); btn.Text = "OFF" end
end

noclipBtn.MouseButton1Click:Connect(function() setNoclip(not state.noclip) updateToggle(noclipBtn, state.noclip) end)
invisBtn.MouseButton1Click:Connect(function() toggleInvis() updateToggle(invisBtn, state.invisible) end)
speedBtn.MouseButton1Click:Connect(function() setSpeedBoost(not state.speedBoost) updateToggle(speedBtn, state.speedBoost) end)
espBtn.MouseButton1Click:Connect(function() setPlayerEsp(not state.playerEsp) updateToggle(espBtn, state.playerEsp) end)
xrayBtn.MouseButton1Click:Connect(function() setXRay(not state.xray) updateToggle(xrayBtn, state.xray) end)

-- FLOATING CIRCLE
local floatGui = Instance.new("ScreenGui")
floatGui.Name="PocketGUI_Float"; floatGui.ResetOnSpawn=false; floatGui.DisplayOrder=1000; floatGui.Parent=pg
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 45, 0, 45); floatBtn.Position = UDim2.new(0, 20, 0.5, -22.5)
floatBtn.BackgroundColor3 = Color3.fromRGB(100,70,240); floatBtn.Text = ""; floatBtn.BorderSizePixel = 0; floatBtn.Parent = floatGui
local fbCr = Instance.new("UICorner"); fbCr.CornerRadius = UDim.new(1, 0); fbCr.Parent = floatBtn
floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

print("[PocketGUI] Simple Version Loaded!")
