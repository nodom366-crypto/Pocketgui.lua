-- PocketGUI v10.7 (Safe Fling + Kill + All Features)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild("PocketGUI") then pg.PocketGUI:Destroy() end
if pg:FindFirstChild("PocketGUI_Float") then pg.PocketGUI_Float:Destroy() end

local state = {
    invisible=false, noclip=false, walkSpeed=16, jumpPower=50,
    speedBoost=false, infJump=false, xray=false, nofog=false, playerEsp=false,
    killAura=false, reach=3.5, hitbox=false, gravity=196, lowGravity=false,
    savedPos=nil, tpMode=false, mm2Esp=false, mm2Farm=false,
    noclipConn=nil, speedConn=nil, jumpConn=nil, auraConn=nil, hitboxConn=nil, tpConn=nil,
    playerEspConn=nil, playerHighlights={}, mm2EspConn=nil, mm2FarmConn=nil,
    mm2Highlights={}, connections={}
}

local function track(c) table.insert(state.connections, c) return c end
local function getRoot() local c=player.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=player.Character return c and c:FindFirstChildOfClass("Humanoid") end

-- SAFE FLING KILL
local function flingKill(targetPlayer)
    local targetChar = workspace:FindFirstChild(targetPlayer.Name)
    if not targetChar then return end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
    if not targetRoot then return end

    local flingPart = Instance.new("Part")
    flingPart.Size = Vector3.new(2, 2, 2)
    flingPart.Transparency = 1
    flingPart.CanCollide = false
    flingPart.Massless = true
    flingPart.Parent = targetChar

    local weld = Instance.new("Weld")
    weld.Part0 = targetRoot
    weld.Part1 = flingPart
    weld.C0 = CFrame.new(0, 0, 0)
    weld.Parent = flingPart

    task.spawn(function()
        for i = 1, 15 do
            if flingPart and flingPart.Parent then
                flingPart.Velocity = Vector3.new(math.random(-10000, 10000), 10000, math.random(-10000, 10000))
                flingPart.RotVelocity = Vector3.new(math.random(-10000, 10000), math.random(-10000, 10000), math.random(-10000, 10000))
            end
            task.wait(0.05)
        end
        if flingPart then flingPart:Destroy() end
    end)
end

-- TOUCH KILL (The "Kill" button)
local function touchKill(targetPlayer)
    local myRoot = getRoot()
    local targetChar = workspace:FindFirstChild(targetPlayer.Name)
    if not myRoot or not targetChar then return end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
    if not targetRoot then return end

    -- Teleport to them and instantly kill
    myRoot.CFrame = targetRoot.CFrame
    
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if hum then
        -- Break joints to make sure they die
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

-- BOOSTS
local function setSpeedBoost(on)
    state.speedBoost=on
    if state.speedConn then state.speedConn:Disconnect() state.speedConn=nil end
    if not on then return end
    state.speedConn=track(RunService.Heartbeat:Connect(function()
        local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end
    end))
end

local function setInfJump(on)
    state.infJump=on
    if state.jumpConn then state.jumpConn:Disconnect() state.jumpConn=nil end
    if not on then return end
    state.jumpConn=track(UIS.JumpRequest:Connect(function()
        local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
end

-- XRAY & FOG
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
                        hl = Instance.new("Highlight"); hl.FillTransparency = 0.55; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillColor = Color3.fromRGB(255, 60, 60); hl.OutlineColor = Color3.fromRGB(255, 140, 140); hl.Parent = plr.Character
                        state.playerHighlights[plr.UserId] = hl
                    end
                end
            end
        end
    end))
end

-- MM2 ESP
local function getMM2Role(plr)
    local char = plr.Character; if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local n = tool.Name:lower()
            if n:find("knife") or n:find("dagger") then return "Murderer" end
            if n:find("gun") or n:find("revolver") or n:find("pistol") then return "Sheriff" end
        end
    end
    local role = char:GetAttribute("Role") or char:GetAttribute("role") or plr:GetAttribute("Role")
    if role then
        local r = tostring(role):lower()
        if r:find("murder") then return "Murderer" end
        if r:find("sheriff") or r:find("gun") then return "Sheriff" end
        if r:find("innoc") then return "Innocent" end
    end
    local backpack = plr:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") or n:find("dagger") then return "Murderer" end
                if n:find("gun") or n:find("revolver") or n:find("pistol") then return "Sheriff" end
            end
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid"); if hum and hum.Health > 0 then return "Innocent" end
    return nil
end

local function setMM2Esp(on)
    state.mm2Esp = on
    if state.mm2EspConn then state.mm2EspConn:Disconnect() state.mm2EspConn = nil end
    for _, h in pairs(state.mm2Highlights) do if h and h.Parent then h:Destroy() end end
    state.mm2Highlights = {}
    if not on then return end
    state.mm2EspConn = track(RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local role = getMM2Role(plr); local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local hl = state.mm2Highlights[plr.UserId]
                    if not hl or not hl.Parent then
                        hl = Instance.new("Highlight"); hl.FillTransparency = 0.55; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = plr.Character; state.mm2Highlights[plr.UserId] = hl
                    end
                    if role == "Murderer" then hl.FillColor = Color3.fromRGB(255, 30, 30); hl.OutlineColor = Color3.fromRGB(255, 100, 100)
                    elseif role == "Sheriff" then hl.FillColor = Color3.fromRGB(40, 120, 255); hl.OutlineColor = Color3.fromRGB(100, 180, 255)
                    else hl.FillColor = Color3.fromRGB(40, 220, 80); hl.OutlineColor = Color3.fromRGB(100, 255, 140) end
                end
            end
        end
    end))
end

-- COMBAT
local function setKillAura(on)
    state.killAura=on; if state.auraConn then state.auraConn:Disconnect() state.auraConn=nil end
    if not on then return end
    state.auraConn=track(RunService.Heartbeat:Connect(function()
        local root=getRoot(); if not root then return end
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local ph=p.Character:FindFirstChildOfClass("Humanoid"); local pr=p.Character:FindFirstChild("HumanoidRootPart")
                if ph and pr and ph.Health>0 and (pr.Position-root.Position).Magnitude<=state.reach then pr.CFrame=root.CFrame end
            end
        end
    end))
end

local function setHitbox(on)
    state.hitbox=on; if state.hitboxConn then state.hitboxConn:Disconnect() state.hitboxConn=nil end
    local function expand()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                for _,part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                        if on then
                            if not part:GetAttribute("origSize") then
                                part:SetAttribute("origSize", part.Size); part:SetAttribute("origTrans", part.Transparency); part:SetAttribute("origCollide", part.CanCollide)
                            end
                            part.Size=Vector3.new(15,15,15); part.Transparency=1; part.CanCollide=false
                        else
                            local orig=part:GetAttribute("origSize")
                            if orig then
                                part.Size=orig; part.Transparency=part:GetAttribute("origTrans") or 0; part.CanCollide=part:GetAttribute("origCollide") ~= false
                                part:SetAttribute("origSize", nil); part:SetAttribute("origTrans", nil); part:SetAttribute("origCollide", nil)
                            end
                        end
                    end
                end
            end
        end
    end
    if on then expand() state.hitboxConn=track(RunService.Heartbeat:Connect(expand)) else expand() end
end

local function setLowGravity(on) state.lowGravity=on; workspace.Gravity = on and 50 or state.gravity end

-- TELEPORT
local function tpOffset(n) local r=getRoot(); if r then r.CFrame=r.CFrame+Vector3.new(0,n,0) end end
local function savePos() local r=getRoot(); if r then state.savedPos=r.CFrame end end
local function loadPos() local r=getRoot(); if r and state.savedPos then r.CFrame=state.savedPos end end
local function enableTapTP(onButton)
    if state.tpConn then state.tpConn:Disconnect() state.tpConn=nil end
    state.tpMode = not state.tpMode
    if not state.tpMode then onButton.Text="Tap to TP" return end
    onButton.Text="Tap anywhere..."
    state.tpConn = track(UIS.InputBegan:Connect(function(input)
        if not state.tpMode then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local guiObj = player.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
            for _, obj in ipairs(guiObj) do if obj:IsDescendantOf(pg.PocketGUI) then return end end
            local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
            local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {player.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
            if result then local root = getRoot(); if root then root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end end
            state.tpMode = false; onButton.Text = "Tap to TP"
            if state.tpConn then state.tpConn:Disconnect() state.tpConn = nil end
        end
    end))
end

local function setMM2Farm(on)
    state.mm2Farm = on; if state.mm2FarmConn then state.mm2FarmConn:Disconnect() state.mm2FarmConn = nil end
    if not on then return end
    state.mm2FarmConn = track(RunService.Heartbeat:Connect(function()
        local root = getRoot(); if not root then return end
        local nearest, nearestDist = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("coin") or obj.Name:lower():find("cash")) then
                local dist = (obj.Position - root.Position).Magnitude
                if dist < nearestDist then nearest = obj; nearestDist = dist end
            end
        end
        if nearest and nearestDist < 500 then root.CFrame = CFrame.new(nearest.Position) end
    end))
end
local function mm2KillAll()
    local char = player.Character; if not char then return false end
    local hasKnife = false
    for _, tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") and tool.Name:lower():find("knife") then hasKnife = true break end end
    if not hasKnife then return false end
    local root = getRoot(); if not root then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local pr = plr.Character:FindFirstChild("HumanoidRootPart"); if pr then pr.CFrame = root.CFrame * CFrame.new(0, 0, -2) end
        end
    end
    return true
end
local function mm2GrabGun()
    local root = getRoot(); if not root then return false end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and (obj.Name:lower():find("gun") or obj.Name:lower():find("revolver")) then
            root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0)); return true
        end
    end
    return false
end
local function mm2TpLobby()
    local root = getRoot(); if not root then return end
    local spawn = workspace:FindFirstChild("SpawnLocation")
    if spawn then root.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0)) return end
    root.CFrame = root.CFrame + Vector3.new(0, 50, 0)
end

-- ==========================================
-- GUI BUILD
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name="PocketGUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=999; gui.Parent=pg

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 450, 0, 300)
main.Position = UDim2.new(0.5, -225, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(20,20,26); main.BorderSizePixel = 0; main.Active = true; main.Parent = gui
local mainCr = Instance.new("UICorner"); mainCr.CornerRadius = UDim.new(0,12); mainCr.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40); title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1; title.Text = "PocketGUI"; title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBlack; title.TextSize = 18; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = main

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 35); tabBar.Position = UDim2.new(0, 10, 0, 45); tabBar.BackgroundTransparency = 1; tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 4); tabLayout.Parent = tabBar

local function createTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 65, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(38,38,50); btn.Text = text
    btn.TextColor3 = Color3.fromRGB(180,180,200); btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.BorderSizePixel = 0; btn.Parent = tabBar
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = btn
    return btn
end

local tabMove = createTab("MOVE"); local tabVisuals = createTab("VISUAL")
local tabCombat = createTab("COMBAT"); local tabPlayers = createTab("PLAYERS"); local tabTele = createTab("TP"); local tabMM2 = createTab("MM2")

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -125); content.Position = UDim2.new(0, 10, 0, 90); content.BackgroundTransparency = 1; content.Parent = main

local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0; p.ScrollBarThickness = 2
    p.Visible = false; p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
    return p
end

local pageMove=createPage() local pageVisuals=createPage()
local pageCombat=createPage() local pagePlayers=createPage() local pageTele=createPage() local pageMM2=createPage()

local function createToggle(parent, text, posY)
    local f = Instance.new("Frame"); f.Size = UDim2.new(1, -10, 0, 35); f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(32,32,42); f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = f
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -90, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 60, 1, -8); btn.Position = UDim2.new(1, -70, 0, 4)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,55); btn.Text = "OFF"; btn.TextColor3 = Color3.fromRGB(150,150,165)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.Parent = f
    local bcr = Instance.new("UICorner"); bcr.CornerRadius = UDim.new(0,4); bcr.Parent = btn
    return btn
end

local function createStepper(parent, text, posY)
    local f = Instance.new("Frame"); f.Size = UDim2.new(1, -10, 0, 35); f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(32,32,42); f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = f
    local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -90, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
    local minus = Instance.new("TextButton"); minus.Size = UDim2.new(0, 30, 1, -8); minus.Position = UDim2.new(1, -70, 0, 4)
    minus.BackgroundColor3 = Color3.fromRGB(180,60,80); minus.Text = "-"; minus.TextColor3 = Color3.fromRGB(255,255,255); minus.Parent = f
    local mCr = Instance.new("UICorner"); mCr.CornerRadius = UDim.new(0,4); mCr.Parent = minus
    local plus = Instance.new("TextButton"); plus.Size = UDim2.new(0, 30, 1, -8); plus.Position = UDim2.new(1, -36, 0, 4)
    plus.BackgroundColor3 = Color3.fromRGB(60,180,90); plus.Text = "+"; plus.TextColor3 = Color3.fromRGB(255,255,255); plus.Parent = f
    local pCr = Instance.new("UICorner"); pCr.CornerRadius = UDim.new(0,4); pCr.Parent = plus
    return lbl, minus, plus
end

local function createAction(parent, text, posY, color)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 35); btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(45,45,60); btn.Text = text; btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = btn
    return btn
end

-- PAGE 1: MOVE
local noclipToggle = createToggle(pageMove, "Noclip", 0)
local jpLabel, jpMinus, jpPlus = createStepper(pageMove, "JumpPower: 50", 45)
local speedBoostToggle = createToggle(pageMove, "Speed Boost", 90)

-- PAGE 2: VISUAL
local invisToggle = createToggle(pageVisuals, "Invisibility", 0)
local wsLabel, wsMinus, wsPlus = createStepper(pageVisuals, "WalkSpeed: 16", 45)
local espToggle = createToggle(pageVisuals, "Player ESP", 90)
local xrayToggle = createToggle(pageVisuals, "X-Ray", 135)

-- PAGE 3: COMBAT
local killAuraToggle = createToggle(pageCombat, "Kill Aura", 0)
local reachLabel, reachMinus, reachPlus = createStepper(pageCombat, "Reach: 3.5", 45)
local hitboxToggle = createToggle(pageCombat, "Hitbox", 90)

-- PAGE 4: PLAYERS LIST
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, -10, 1, 0); playerListFrame.BackgroundTransparency = 1; playerListFrame.Parent = pagePlayers
local playerLayout = Instance.new("UIListLayout"); playerLayout.Padding = UDim.new(0, 4); playerLayout.Parent = playerListFrame

local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 35); row.BackgroundColor3 = Color3.fromRGB(32,32,42); row.Parent = playerListFrame
            local rcr = Instance.new("UICorner"); rcr.CornerRadius = UDim.new(0,6); rcr.Parent = row
            
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -130, 1, 0); nameLbl.Position = UDim2.new(0, 10, 0, 0)
            nameLbl.BackgroundTransparency = 1; nameLbl.Text = plr.Name; nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
            nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 12; nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.Parent = row
            
            local killBtn = Instance.new("TextButton")
            killBtn.Size = UDim2.new(0, 55, 1, -8); killBtn.Position = UDim2.new(1, -120, 0, 4)
            killBtn.BackgroundColor3 = Color3.fromRGB(220,60,80); killBtn.Text = "Kill"
            killBtn.TextColor3 = Color3.fromRGB(255,255,255); killBtn.Font = Enum.Font.GothamBold; killBtn.TextSize = 11; killBtn.Parent = row
            local fcr = Instance.new("UICorner"); fcr.CornerRadius = UDim.new(0,4); fcr.Parent = killBtn
            
            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 55, 1, -8); tpBtn.Position = UDim2.new(1, -60, 0, 4)
            tpBtn.BackgroundColor3 = Color3.fromRGB(60,120,180); tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.fromRGB(255,255,255); tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 11; tpBtn.Parent = row
            local tcr = Instance.new("UICorner"); tcr.CornerRadius = UDim.new(0,4); tcr.Parent = tpBtn
            
            killBtn.MouseButton1Click:Connect(function() touchKill(plr) end)
            
            tpBtn.MouseButton1Click:Connect(function()
                local myRoot = getRoot()
                local targetChar = workspace:FindFirstChild(plr.Name)
                local tRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso"))
                if myRoot and tRoot then 
                    myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0) 
                end
            end)
        end
    end
end
refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

-- PAGE 5: TELEPORT
local tpTapBtn = createAction(pageTele, "Tap to TP", 0, Color3.fromRGB(55,45,100))
local tpUpBtn = createAction(pageTele, "TP Up 50", 45, Color3.fromRGB(35,65,50))
local savePosBtn = createAction(pageTele, "Save Pos", 90, Color3.fromRGB(50,50,70))
local loadPosBtn = createAction(pageTele, "Load Pos", 135, Color3.fromRGB(50,50,70))

-- PAGE 6: MM2
local mm2EspToggle = createToggle(pageMM2, "Role ESP", 0)
local mm2KillBtn = createAction(pageMM2, "Kill All (Knife)", 45, Color3.fromRGB(120,30,40))
local mm2GunBtn = createAction(pageMM2, "Grab Gun", 90, Color3.fromRGB(40,80,120))

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -20, 0, 35); closeBtn.Position = UDim2.new(0, 10, 1, -45)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,48,90); closeBtn.Text = "Hide Menu"; closeBtn.TextColor3 = Color3.fromRGB(215,205,250)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 12; closeBtn.Parent = main
local cbCr = Instance.new("UICorner"); cbCr.CornerRadius = UDim.new(0,6); cbCr.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local allTabs = {tabMove, tabVisuals, tabCombat, tabPlayers, tabTele, tabMM2}
local allPages = {pageMove, pageVisuals, pageCombat, pagePlayers, pageTele, pageMM2}

local function selectTab(index)
    for i = 1, #allTabs do
        if i == index then
            allTabs[i].BackgroundColor3 = Color3.fromRGB(75,62,125); allTabs[i].TextColor3 = Color3.fromRGB(255,255,255); allPages[i].Visible = true
            if i == 4 then refreshPlayerList() end
        else
            allTabs[i].BackgroundColor3 = Color3.fromRGB(38,38,50); allTabs[i].TextColor3 = Color3.fromRGB(180,180,200); allPages[i].Visible = false
        end
    end
end

for i, tab in ipairs(allTabs) do tab.MouseButton1Click:Connect(function() selectTab(i) end) end
selectTab(1)

local function updateToggle(btn,on,onC,offC)
    if on then btn.BackgroundColor3=onC; btn.Text="ON" else btn.BackgroundColor3=offC; btn.Text="OFF" end
end
local GREEN=Color3.fromRGB(60,200,100); local RED=Color3.fromRGB(220,60,80); local OFF=Color3.fromRGB(45,45,55)

noclipToggle.MouseButton1Click:Connect(function() setNoclip(not state.noclip) updateToggle(noclipToggle,state.noclip,GREEN,OFF) end)
invisToggle.MouseButton1Click:Connect(function() toggleInvis() updateToggle(invisToggle,state.invisible,Color3.fromRGB(150,80,255),OFF) end)
speedBoostToggle.MouseButton1Click:Connect(function() setSpeedBoost(not state.speedBoost) updateToggle(speedBoostToggle,state.speedBoost,GREEN,OFF) end)
espToggle.MouseButton1Click:Connect(function() setPlayerEsp(not state.playerEsp) updateToggle(espToggle,state.playerEsp,RED,OFF) end)
xrayToggle.MouseButton1Click:Connect(function() setXRay(not state.xray) updateToggle(xrayToggle,state.xray,GREEN,OFF) end)
killAuraToggle.MouseButton1Click:Connect(function() setKillAura(not state.killAura) updateToggle(killAuraToggle,state.killAura,RED,OFF) end)
hitboxToggle.MouseButton1Click:Connect(function() setHitbox(not state.hitbox) updateToggle(hitboxToggle,state.hitbox,RED,OFF) end)
mm2EspToggle.MouseButton1Click:Connect(function() setMM2Esp(not state.mm2Esp) updateToggle(mm2EspToggle,state.mm2Esp,RED,OFF) end)
mm2KillBtn.MouseButton1Click:Connect(function() local s=mm2KillAll() mm2KillBtn.Text=s and "Killed ✓" or "Need Knife!" task.delay(1.5,function() mm2KillBtn.Text="Kill All (Knife)" end) end)
mm2GunBtn.MouseButton1Click:Connect(function() local s=mm2GrabGun() mm2GunBtn.Text=s and "Teleported ✓" or "No Gun" task.delay(1.5,function() mm2GunBtn.Text="Grab Gun" end) end)

wsPlus.MouseButton1Click:Connect(function() state.walkSpeed=math.clamp(state.walkSpeed+5,16,200); wsLabel.Text="WalkSpeed: "..state.walkSpeed; local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end end)
wsMinus.MouseButton1Click:Connect(function() state.walkSpeed=math.clamp(state.walkSpeed-5,16,200); wsLabel.Text="WalkSpeed: "..state.walkSpeed; local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end end)
jpPlus.MouseButton1Click:Connect(function() state.jumpPower=math.clamp(state.jumpPower+10,0,500); jpLabel.Text="JumpPower: "..state.jumpPower; local h=getHum(); if h then h.JumpPower=state.jumpPower end end)
jpMinus.MouseButton1Click:Connect(function() state.jumpPower=math.clamp(state.jumpPower-10,0,500); jpLabel.Text="JumpPower: "..state.jumpPower; local h=getHum(); if h then h.JumpPower=state.jumpPower end end)
reachPlus.MouseButton1Click:Connect(function() state.reach=math.clamp(state.reach+1,1,50); reachLabel.Text="Reach: "..state.reach end)
reachMinus.MouseButton1Click:Connect(function() state.reach=math.clamp(state.reach-1,1,50); reachLabel.Text="Reach: "..state.reach end)

tpTapBtn.MouseButton1Click:Connect(function() enableTapTP(tpTapBtn) end)
tpUpBtn.MouseButton1Click:Connect(function() tpOffset(50) end)
savePosBtn.MouseButton1Click:Connect(function() savePos() savePosBtn.Text="Saved ✓" task.delay(1,function() savePosBtn.Text="Save Pos" end) end)
loadPosBtn.MouseButton1Click:Connect(function() loadPos() loadPosBtn.Text="Loaded ✓" task.delay(1,function() loadPosBtn.Text="Load Pos" end) end)

-- FLOATING CIRCLE
local floatGui = Instance.new("ScreenGui")
floatGui.Name="PocketGUI_Float"; floatGui.ResetOnSpawn=false; floatGui.DisplayOrder=1000; floatGui.Parent=pg
local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 40, 0, 40); floatBtn.Position = UDim2.new(0, 20, 0.5, -20)
floatBtn.BackgroundColor3 = Color3.fromRGB(100,70,240); floatBtn.Text = ""; floatBtn.BorderSizePixel = 0; floatBtn.Parent = floatGui
local fbCr = Instance.new("UICorner"); fbCr.CornerRadius = UDim.new(1, 0); fbCr.Parent = floatBtn
local fbIcon = Instance.new("Frame"); fbIcon.Size = UDim2.new(0, 16, 0, 13); fbIcon.Position = UDim2.new(0.5, -8, 0.5, -6.5)
fbIcon.BackgroundTransparency = 1; fbIcon.Parent = floatBtn
for i = 0, 2 do
    local line = Instance.new("Frame"); line.Size = UDim2.new(1, 0, 0, 2); line.Position = UDim2.new(0, 0, 0, i * 5)
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255); line.BorderSizePixel = 0; line.Parent = fbIcon
end

floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

print("[PocketGUI] v10.7 Loaded! Kill button added.")
