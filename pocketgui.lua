-- PocketGUI v12.1 (Instant Kill + Trolls)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
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

-- INSTANT KILL (No explosion, just kills them)
local function instantKill(targetPlayer)
    local targetChar = workspace:FindFirstChild(targetPlayer.Name)
    if not targetChar then return end
    
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if hum then
        -- Break joints so they ragdoll
        for _, v in ipairs(targetChar:GetDescendants()) do
            if v:IsA("Motor6D") then v.Part0 = nil end
        end
        -- Kill them
        hum.Health = 0
    end
end

-- NEW TROLLS
local function brickHead(targetPlayer)
    local targetChar = workspace:FindFirstChild(targetPlayer.Name)
    if not targetChar then return end
    local head = targetChar:FindFirstChild("Head")
    if not head then return end
    local brick = Instance.new("Part")
    brick.Size = Vector3.new(10, 10, 10); brick.Color = Color3.fromRGB(255, 0, 0); brick.Material = Enum.Material.Neon; brick.CanCollide = false
    brick.Position = head.Position + Vector3.new(0, 5, 0); brick.Parent = targetChar
    local weld = Instance.new("Weld", brick); weld.Part0 = head; weld.Part1 = brick
    task.delay(5, function() if brick then brick:Destroy() end end)
end

local function trollBlind(targetPlayer)
    local targetChar = workspace:FindFirstChild(targetPlayer.Name)
    if not targetChar then return end
    local head = targetChar:FindFirstChild("Head")
    if not head then return end
    local blind = Instance.new("Part")
    blind.Size = Vector3.new(10, 10, 1); blind.Transparency = 0; blind.Color = Color3.fromRGB(0, 0, 0); blind.CanCollide = false
    blind.Position = head.Position + (head.CFrame.LookVector * 2); blind.Parent = targetChar
    local weld = Instance.new("Weld", blind); weld.Part0 = head; weld.Part1 = blind
    task.delay(3, function() if blind then blind:Destroy() end end)
end

local function trollOrbit(targetPlayer)
    local targetChar = workspace:FindFirstChild(targetPlayer.Name)
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    local myRoot = getRoot()
    if not targetRoot or not myRoot then return end
    task.spawn(function()
        for i = 1, 200 do
            if targetRoot and targetRoot.Parent and myRoot and myRoot.Parent then
                local angle = i * 0.5
                targetRoot.CFrame = myRoot.CFrame * CFrame.new(math.cos(angle) * 15, 5, math.sin(angle) * 15)
                task.wait(0.03)
            end
        end
    end)
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

-- SPEED BOOST
local function setSpeedBoost(on)
    state.speedBoost=on
    if state.speedConn then state.speedConn:Disconnect() state.speedConn=nil end
    if not on then return end
    state.speedConn=track(RunService.Heartbeat:Connect(function()
        local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end
    end))
end

-- XRAY
local function setXRay(on)
    state.xray = on
    if on then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Transparency < 0.8 then
                obj:SetAttribute("origTrans", obj.Transparency)
                obj.Transparency = 0.7
            end
        end
    else
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:GetAttribute("origTrans") then
                obj.Transparency = obj:GetAttribute("origTrans")
                obj:SetAttribute("origTrans", nil)
            end
        end
    end
end

-- PLAYER ESP
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
                        hl = Instance.new("Highlight")
                        hl.FillTransparency = 0.55
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillColor = Color3.fromRGB(255, 60, 60)
                        hl.OutlineColor = Color3.fromRGB(255, 140, 140)
                        hl.Parent = plr.Character
                        state.playerHighlights[plr.UserId] = hl
                    end
                end
            end
        end
    end))
end

-- KILL AURA
local function setKillAura(on)
    state.killAura=on
    if state.auraConn then state.auraConn:Disconnect() state.auraConn=nil end
    if not on then return end
    state.auraConn=track(RunService.Heartbeat:Connect(function()
        local root=getRoot(); if not root then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local ph=p.Character:FindFirstChildOfClass("Humanoid")
                local pr=p.Character:FindFirstChild("HumanoidRootPart")
                if ph and pr and ph.Health>0 and (pr.Position-root.Position).Magnitude<=state.reach then
                    pr.CFrame=root.CFrame
                end
            end
        end
    end))
end

-- HITBOX
local function setHitbox(on)
    state.hitbox=on
    if state.hitboxConn then state.hitboxConn:Disconnect() state.hitboxConn=nil end
    local function expand()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                for _,part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                        if on then
                            if not part:GetAttribute("origSize") then
                                part:SetAttribute("origSize", part.Size)
                                part:SetAttribute("origTrans", part.Transparency)
                            end
                            part.Size=Vector3.new(15,15,15)
                            part.Transparency=1
                            part.CanCollide=false
                        else
                            local orig=part:GetAttribute("origSize")
                            if orig then
                                part.Size=orig
                                part.Transparency=part:GetAttribute("origTrans") or 0
                                part.CanCollide=true
                                part:SetAttribute("origSize", nil)
                                part:SetAttribute("origTrans", nil)
                            end
                        end
                    end
                end
            end
        end
    end
    if on then expand() state.hitboxConn=track(RunService.Heartbeat:Connect(expand)) else expand() end
end

-- GUI BUILD
local gui = Instance.new("ScreenGui")
gui.Name="PocketGUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=999; gui.Parent=pg

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 320)
main.Position = UDim2.new(0.5, -200, 0.5, -160)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
local mainCr = Instance.new("UICorner"); mainCr.CornerRadius = UDim.new(0, 12); mainCr.Parent = main
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(60, 60, 80); mainStroke.Thickness = 1.5; mainStroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1
title.Text = "PocketGUI"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))}
titleGrad.Parent = title

local tabBar = Instance.new("ScrollingFrame")
tabBar.Size = UDim2.new(1, -30, 0, 35)
tabBar.Position = UDim2.new(0, 15, 0, 45)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 0
tabBar.ScrollDirection = Enum.ScrollDirection.Horizontal
tabBar.CanvasSize = UDim2.new(0,0,0,0)
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 4); tabLayout.Parent = tabBar

local function createTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 65, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(170, 170, 190)
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = tabBar
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 6); cr.Parent = btn
    return btn
end

local tabMove = createTab("MOVE")
local tabVisuals = createTab("VISUAL")
local tabCombat = createTab("COMBAT")
local tabPlayers = createTab("PLAYERS")
local tabTrolls = createTab("TROLLS")

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -30, 1, -130)
content.Position = UDim2.new(0, 15, 0, 90)
content.BackgroundTransparency = 1
content.Parent = main

local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    p.Visible = false
    p.CanvasSize = UDim2.new(0,0,0,0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Parent = content
    return p
end

local pageMove = createPage()
local pageVisuals = createPage()
local pageCombat = createPage()
local pagePlayers = createPage()
local pageTrolls = createPage()

local function createToggle(parent, text, posY)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 35)
    f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = f
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 1, -8)
    btn.Position = UDim2.new(1, -60, 0, 4)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(150, 150, 165)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = f
    local bcr = Instance.new("UICorner"); bcr.CornerRadius = UDim.new(0,4); bcr.Parent = btn
    return btn
end

local function createStepper(parent, text, posY)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 35)
    f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = f
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -90, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = f
    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 25, 1, -8)
    minus.Position = UDim2.new(1, -60, 0, 4)
    minus.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255,255,255)
    minus.Font = Enum.Font.GothamBlack
    minus.TextSize = 14
    minus.BorderSizePixel = 0
    minus.Parent = f
    local mCr = Instance.new("UICorner"); mCr.CornerRadius = UDim.new(0,4); mCr.Parent = minus
    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 25, 1, -8)
    plus.Position = UDim2.new(1, -30, 0, 4)
    plus.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255,255,255)
    plus.Font = Enum.Font.GothamBlack
    plus.TextSize = 14
    plus.BorderSizePixel = 0
    plus.Parent = f
    local pCr = Instance.new("UICorner"); pCr.CornerRadius = UDim.new(0,4); pCr.Parent = plus
    return lbl, minus, plus
end

local function createAction(parent, text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(35, 35, 48)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = btn
    return btn
end

-- PAGE 1: MOVE
local noclipBtn = createToggle(pageMove, "Noclip", 0)
local jpLabel, jpMinus, jpPlus = createStepper(pageMove, "JumpPower: 50", 40)
local speedBtn = createToggle(pageMove, "Speed Boost", 80)

-- PAGE 2: VISUAL
local invisBtn = createToggle(pageVisuals, "Invisibility", 0)
local wsLabel, wsMinus, wsPlus = createStepper(pageVisuals, "WalkSpeed: 16", 40)
local espBtn = createToggle(pageVisuals, "Player ESP", 80)
local xrayBtn = createToggle(pageVisuals, "X-Ray", 120)

-- PAGE 3: COMBAT
local killBtn = createToggle(pageCombat, "Kill Aura", 0)
local reachLabel, reachMinus, reachPlus = createStepper(pageCombat, "Reach: 3.5", 40)
local hitboxBtn = createToggle(pageCombat, "Hitbox Expander", 80)

-- PAGE 4: PLAYERS
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
            row.Size = UDim2.new(1, 0, 0, 35)
            row.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
            row.Parent = playerListFrame
            local rcr = Instance.new("UICorner"); rcr.CornerRadius = UDim.new(0,6); rcr.Parent = row
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -130, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = plr.Name
            nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 12
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = row
            local explodeBtn = Instance.new("TextButton")
            explodeBtn.Size = UDim2.new(0, 55, 1, -8)
            explodeBtn.Position = UDim2.new(1, -120, 0, 4)
            explodeBtn.BackgroundColor3 = Color3.fromRGB(220,60,80)
            explodeBtn.Text = "Kill"
            explodeBtn.TextColor3 = Color3.fromRGB(255,255,255)
            explodeBtn.Font = Enum.Font.GothamBlack
            explodeBtn.TextSize = 10
            explodeBtn.BorderSizePixel = 0
            explodeBtn.Parent = row
            local fcr = Instance.new("UICorner"); fcr.CornerRadius = UDim.new(0,4); fcr.Parent = explodeBtn
            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 55, 1, -8)
            tpBtn.Position = UDim2.new(1, -60, 0, 4)
            tpBtn.BackgroundColor3 = Color3.fromRGB(60,120,180)
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
            tpBtn.Font = Enum.Font.GothamBlack
            tpBtn.TextSize = 10
            tpBtn.BorderSizePixel = 0
            tpBtn.Parent = row
            local tcr = Instance.new("UICorner"); tcr.CornerRadius = UDim.new(0,4); tcr.Parent = tpBtn
            explodeBtn.MouseButton1Click:Connect(function() instantKill(plr) end)
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

-- PAGE 5: TROLLS
local brickBtn = createAction(pageTrolls, "Brick Head", 0, Color3.fromRGB(255, 100, 100))
local blindBtn = createAction(pageTrolls, "Blindness", 40, Color3.fromRGB(50, 50, 50))
local orbitBtn = createAction(pageTrolls, "Orbit Target", 80, Color3.fromRGB(200, 100, 200))

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -30, 0, 35)
closeBtn.Position = UDim2.new(0, 15, 1, -45)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,48,90)
closeBtn.Text = "Hide Menu"
closeBtn.TextColor3 = Color3.fromRGB(215,205,250)
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = main
local cbCr = Instance.new("UICorner"); cbCr.CornerRadius = UDim.new(0,6); cbCr.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local allTabs = {tabMove, tabVisuals, tabCombat, tabPlayers, tabTrolls}
local allPages = {pageMove, pageVisuals, pageCombat, pagePlayers, pageTrolls}

local function selectTab(index)
    for i = 1, #allTabs do
        if i == index then
            allTabs[i].BackgroundColor3 = Color3.fromRGB(75,62,125)
            allTabs[i].TextColor3 = Color3.fromRGB(255,255,255)
            allPages[i].Visible = true
            if i == 4 then refreshPlayerList() end
        else
            allTabs[i].BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            allTabs[i].TextColor3 = Color3.fromRGB(170, 170, 190)
            allPages[i].Visible = false
        end
    end
end

for i, tab in ipairs(allTabs) do tab.MouseButton1Click:Connect(function() selectTab(i) end) end
selectTab(1)

local function updateToggle(btn,on,onC,offC)
    if on then btn.BackgroundColor3=onC; btn.Text="ON" else btn.BackgroundColor3=offC; btn.Text="OFF" end
end
local GREEN = Color3.fromRGB(60, 200, 100)
local PURPLE = Color3.fromRGB(150, 80, 255)
local RED = Color3.fromRGB(220, 60, 80)
local OFF = Color3.fromRGB(40, 40, 50)

noclipBtn.MouseButton1Click:Connect(function() setNoclip(not state.noclip) updateToggle(noclipBtn,state.noclip,GREEN,OFF) end)
invisBtn.MouseButton1Click:Connect(function() toggleInvis() updateToggle(invisBtn,state.invisible,PURPLE,OFF) end)
speedBtn.MouseButton1Click:Connect(function() setSpeedBoost(not state.speedBoost) updateToggle(speedBtn,state.speedBoost,GREEN,OFF) end)
espBtn.MouseButton1Click:Connect(function() setPlayerEsp(not state.playerEsp) updateToggle(espBtn,state.playerEsp,RED,OFF) end)
xrayBtn.MouseButton1Click:Connect(function() setXRay(not state.xray) updateToggle(xrayBtn,state.xray,GREEN,OFF) end)
killBtn.MouseButton1Click:Connect(function() setKillAura(not state.killAura) updateToggle(killBtn,state.killAura,RED,OFF) end)
hitboxBtn.MouseButton1Click:Connect(function() setHitbox(not state.hitbox) updateToggle(hitboxBtn,state.hitbox,RED,OFF) end)

brickBtn.MouseButton1Click:Connect(function() for _, p in ipairs(Players:GetPlayers()) do if p ~= player then brickHead(p) break end end end)
blindBtn.MouseButton1Click:Connect(function() for _, p in ipairs(Players:GetPlayers()) do if p ~= player then trollBlind(p) break end end end)
orbitBtn.MouseButton1Click:Connect(function() for _, p in ipairs(Players:GetPlayers()) do if p ~= player then trollOrbit(p) break end end end)

wsPlus.MouseButton1Click:Connect(function() state.walkSpeed=math.clamp(state.walkSpeed+5,16,200); wsLabel.Text="WalkSpeed: "..state.walkSpeed; local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end end)
wsMinus.MouseButton1Click:Connect(function() state.walkSpeed=math.clamp(state.walkSpeed-5,16,200); wsLabel.Text="WalkSpeed: "..state.walkSpeed; local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end end)
jpPlus.MouseButton1Click:Connect(function() state.jumpPower=math.clamp(state.jumpPower+10,0,500); jpLabel.Text="JumpPower: "..state.jumpPower; local h=getHum(); if h then h.JumpPower=state.jumpPower end end)
jpMinus.MouseButton1Click:Connect(function() state.jumpPower=math.clamp(state.jumpPower-10,0,500); jpLabel.Text="JumpPower: "..state.jumpPower; local h=getHum(); if h then h.JumpPower=state.jumpPower end end)
reachPlus.MouseButton1Click:Connect(function() state.reach=math.clamp(state.reach+1,1,50); reachLabel.Text="Reach: "..state.reach end)
reachMinus.MouseButton1Click:Connect(function() state.reach=math.clamp(state.reach-1,1,50); reachLabel.Text="Reach: "..state.reach end)

local floatGui = Instance.new("ScreenGui")
floatGui.Name="PocketGUI_Float"
floatGui.ResetOnSpawn=false
floatGui.DisplayOrder=1000
floatGui.Parent=pg
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 45, 0, 45)
floatBtn.Position = UDim2.new(0, 20, 0.5, -22.5)
floatBtn.BackgroundColor3 = Color3.fromRGB(100,70,240)
floatBtn.Text = ""
floatBtn.BorderSizePixel = 0
floatBtn.Parent = floatGui
local fbCr = Instance.new("UICorner"); fbCr.CornerRadius = UDim.new(1, 0); fbCr.Parent = floatBtn
local fbIcon = Instance.new("Frame")
fbIcon.Size = UDim2.new(0, 18, 0, 15)
fbIcon.Position = UDim2.new(0.5, -9, 0.5, -7.5)
fbIcon.BackgroundTransparency = 1
fbIcon.Parent = floatBtn
for i = 0, 2 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 0, i * 6)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BorderSizePixel = 0
    line.Parent = fbIcon
end

floatBtn.MouseButton1Click:Connect(function() main.Visible = main.Visible == false end)

print("[PocketGUI] v12.1 Loaded! Instant Kill active.")
