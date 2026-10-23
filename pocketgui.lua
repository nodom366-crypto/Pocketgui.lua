-- PocketGUI v27.0 (Mobile New Features - No IY)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild("PocketGUI") then pg.PocketGUI:Destroy() end
if pg:FindFirstChild("PocketGUI_Float") then pg.PocketGUI_Float:Destroy() end

local state = {
    flying=false, noclip=false, walkSpeed=16, jumpPower=50,
    speedBoost=false, highJump=false, xray=false, playerEsp=false, mm2Esp=false, antiAfk=false,
    flySpeed=60, tpMode=false, flingMode=false, skeletonEsp=false, selfChams=false,
    flyConn=nil, bodyVelocity=nil, bodyGyro=nil, tpConn=nil, flingConn=nil,
    noclipConn=nil, speedConn=nil, jumpConn=nil,
    playerEspConn=nil, playerHighlights={}, skeletonConn=nil, skeletonDrawings={},
    selfChamsConn=nil, selfChamsHighlight=nil,
    mm2EspConn=nil, mm2Highlights={}, connections={},
    ndsGodmode=false, ndsAutoWin=false, infJump=false,
    hussAutoDodge=false, hussAutoTackle=false, hussEsp=false, hussHighlights={}
}

local function track(c) table.insert(state.connections, c) return c end
local function getRoot() local c=player.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=player.Character return c and c:FindFirstChildOfClass("Humanoid") end

-- FLY
local function setFly(on)
    state.flying = on
    local char = player.Character
    local root = getRoot()
    local hum = getHum()

    if state.flyConn then state.flyConn:Disconnect() state.flyConn = nil end
    if state.bodyVelocity then state.bodyVelocity:Destroy() state.bodyVelocity = nil end
    if state.bodyGyro then state.bodyGyro:Destroy() state.bodyGyro = nil end

    if not on or not root or not hum then 
        if hum then hum.PlatformStand = false end
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
        if not state.flying or not root or not root.Parent then return end
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
        while state.flying do task.wait(0.5) end
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
            hum.PlatformStand = false
        end
    end)
end

-- CLICK TELEPORT
local function enableTapTP(onButton)
    if state.tpConn then state.tpConn:Disconnect() state.tpConn = nil end
    state.tpMode = not state.tpMode
    if not state.tpMode then onButton.Text = "Click Teleport" return end
    onButton.Text = "Tap anywhere..."
    state.tpConn = track(UIS.InputBegan:Connect(function(input)
        if not state.tpMode then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local guiObj = player.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
            for _, obj in ipairs(guiObj) do if obj:IsDescendantOf(pg.PocketGUI) or obj:IsDescendantOf(pg.PocketGUI_Float) then return end end
            local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {player.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
            if result then local root = getRoot(); if root then root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end end
            state.tpMode = false; onButton.Text = "Click Teleport"
            if state.tpConn then state.tpConn:Disconnect() state.tpConn = nil end
        end
    end))
end

-- TOUCH FLING (NEW)
local function enableFling(onButton)
    if state.flingConn then state.flingConn:Disconnect() state.flingConn = nil end
    state.flingMode = not state.flingMode
    if not state.flingMode then onButton.Text = "Touch Fling" return end
    onButton.Text = "Tap player..."
    state.flingConn = track(UIS.InputBegan:Connect(function(input)
        if not state.flingMode then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local guiObj = player.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
            for _, obj in ipairs(guiObj) do if obj:IsDescendantOf(pg.PocketGUI) or obj:IsDescendantOf(pg.PocketGUI_Float) then return end end
            local mouseRay = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {player.Character}
            local result = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, params)
            if result and result.Instance then
                local targetChar = result.Instance:FindFirstAncestorOfClass("Model")
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    targetRoot.AssemblyLinearVelocity = Vector3.new(1000, 1000, 1000)
                end
            end
            state.flingMode = false; onButton.Text = "Touch Fling"
            if state.flingConn then state.flingConn:Disconnect() state.flingConn = nil end
        end
    end))
end

-- NOCLIP
local function setNoclip(on)
    state.noclip=on
    if state.noclipConn then state.noclipConn:Disconnect() state.noclipConn=nil end
    local c = player.Character
    if not c then return end
    if on then
        state.noclipConn=track(RunService.Stepped:Connect(function()
            local char=player.Character; if not char then return end
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
            end
        end))
    else
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end
end

-- SPEED BOOST
local function setSpeedBoost(on)
    state.speedBoost=on
    if state.speedConn then state.speedConn:Disconnect() state.speedConn=nil end
    if not on then 
        local h = getHum()
        if h then h.WalkSpeed = 16 end
        return 
    end
    state.speedConn=track(RunService.Heartbeat:Connect(function()
        local h=getHum(); if h then h.WalkSpeed=state.walkSpeed end
    end))
end

-- HIGH JUMP
local function setHighJump(on)
    state.highJump = on
    if state.jumpConn then state.jumpConn:Disconnect() state.jumpConn = nil end
    if not on then 
        local h = getHum()
        if h then h.JumpPower = 50 end
        return 
    end
    state.jumpConn = track(RunService.Heartbeat:Connect(function()
        local h = getHum()
        if h then h.JumpPower = state.jumpPower end
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

-- SKELETON ESP (NEW)
local function setSkeletonEsp(on)
    state.skeletonEsp = on
    if state.skeletonConn then state.skeletonConn:Disconnect() state.skeletonConn = nil end
    for _, d in pairs(state.skeletonDrawings) do if d and d.Parent then d:Destroy() end end
    state.skeletonDrawings = {}
    if not on then return end
    state.skeletonConn = track(RunService.Heartbeat:Connect(function()
        for _, d in pairs(state.skeletonDrawings) do if d and d.Parent then d:Destroy() end end
        state.skeletonDrawings = {}
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local char = plr.Character
                local root = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local leftArm = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftUpperArm")
                local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
                local leftLeg = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftUpperLeg")
                local rightLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
                
                local function drawLine(p1, p2, color)
                    if p1 and p2 then
                        local dist = (p1.Position - p2.Position).Magnitude
                        local part = Instance.new("Part")
                        part.Size = Vector3.new(0.1, 0.1, dist)
                        part.CFrame = CFrame.new(p1.Position, p2.Position) * CFrame.new(0, 0, -dist/2)
                        part.Anchored = true
                        part.CanCollide = false
                        part.Material = Enum.Material.Neon
                        part.Color = color
                        part.Parent = workspace
                        table.insert(state.skeletonDrawings, part)
                    end
                end
                
                drawLine(head, root, Color3.fromRGB(255, 0, 0))
                drawLine(root, leftArm, Color3.fromRGB(0, 255, 0))
                drawLine(root, rightArm, Color3.fromRGB(0, 255, 0))
                drawLine(root, leftLeg, Color3.fromRGB(0, 0, 255))
                drawLine(root, rightLeg, Color3.fromRGB(0, 0, 255))
            end
        end
    end))
end

-- SELF CHAMS (NEW)
local function setSelfChams(on)
    state.selfChams = on
    if state.selfChamsConn then state.selfChamsConn:Disconnect() state.selfChamsConn = nil end
    if state.selfChamsHighlight then state.selfChamsHighlight:Destroy() state.selfChamsHighlight = nil end
    if not on then return end
    state.selfChamsConn = track(RunService.Heartbeat:Connect(function()
        local char = player.Character
        if char then
            if not state.selfChamsHighlight or state.selfChamsHighlight.Parent ~= char then
                if state.selfChamsHighlight then state.selfChamsHighlight:Destroy() end
                state.selfChamsHighlight = Instance.new("Highlight")
                state.selfChamsHighlight.FillColor = Color3.fromRGB(0, 255, 255)
                state.selfChamsHighlight.OutlineColor = Color3.fromRGB(0, 255, 255)
                state.selfChamsHighlight.FillTransparency = 0.5
                state.selfChamsHighlight.OutlineTransparency = 0
                state.selfChamsHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                state.selfChamsHighlight.Parent = char
            end
        end
    end))
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
                        hl = Instance.new("Highlight"); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillColor = Color3.fromRGB(255, 50, 50); hl.OutlineColor = Color3.fromRGB(255, 100, 100); hl.Parent = plr.Character
                        state.playerHighlights[plr.UserId] = hl
                    end
                end
            end
        end
    end))
end

-- MM2 FEATURES
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

local function mm2KillAll()
    local char = player.Character; if not char then return false end
    local hasKnife = false
    for _, tool in ipairs(char:GetChildren()) do if tool:IsA("Tool") and tool.Name:lower():find("knife") then hasKnife = true break end end
    if not hasKnife then return false end
    local root = getRoot(); if not root then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local pr = plr.Character:FindFirstChild("HumanoidRootPart"); 
            if pr and hum and hum.Health > 0 then pr.CFrame = root.CFrame * CFrame.new(0, 0, -2) end
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

-- ANTI AFK
local function setAntiAfk(on)
    state.antiAfk = on
    if state.antiAfkConn then state.antiAfkConn:Disconnect() state.antiAfkConn = nil end
    if not on then return end
    state.antiAfkConn = track(player.Idled:Connect(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end))
end

-- RESPAWN
local function respawnPlayer()
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
end

local function tpToPlayer(plr)
    local myRoot = getRoot()
    local targetChar = workspace:FindFirstChild(plr.Name)
    local tRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso"))
    if myRoot and tRoot then myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0) end
end

-- DISASTER LOGIC
local function setNDSGodmode(on)
    state.ndsGodmode = on
    if state.ndsGodConn then state.ndsGodConn:Disconnect() state.ndsGodConn = nil end
    if not on then return end
    state.ndsGodConn = track(RunService.Heartbeat:Connect(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and root then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
                if hum:GetState() == Enum.HumanoidStateType.Dead or hum:GetState() == Enum.HumanoidStateType.Physics then
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end
                local bodyForce = root:FindFirstChild("NDS_AntiFling")
                if not bodyForce then
                    bodyForce = Instance.new("BodyForce")
                    bodyForce.Name = "NDS_AntiFling"
                    bodyForce.Force = Vector3.new(0, workspace.Gravity * root:GetMass(), 0)
                    bodyForce.Parent = root
                end
            end
        end
    end))
end

local function setNDSAutoWin(on)
    state.ndsAutoWin = on
    if state.ndsWinConn then state.ndsWinConn:Disconnect() state.ndsWinConn = nil end
    if not on then return end
    state.ndsWinConn = track(RunService.Heartbeat:Connect(function()
        local root = getRoot()
        if not root then return end
        local map = workspace:FindFirstChild("Map")
        if map then
            local winPad = map:FindFirstChild("WinPad")
            if winPad then
                root.CFrame = CFrame.new(winPad.Position + Vector3.new(0, 5, 0))
            end
        end
    end))
end

-- UTILITY LOGIC
local function setInfJump(on)
    state.infJump = on
    if state.infJumpConn then state.infJumpConn:Disconnect() state.infJumpConn = nil end
    if not on then return end
    state.infJumpConn = track(UIS.JumpRequest:Connect(function()
        if state.infJump then
            local hum = getHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))
end

-- HUSS VALLEY LOGIC
local function getHussRole(plr)
    local role = plr:GetAttribute("GameRole")
    if typeof(role) == "string" then return role end
    return "Lobby"
end

local function setHussAutoDodge(on)
    state.hussAutoDodge = on
    if state.hussDodgeConn then state.hussDodgeConn:Disconnect() state.hussDodgeConn = nil end
    if not on then return end
    state.hussDodgeConn = track(RunService.Heartbeat:Connect(function()
        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myRoot or not myHum or myHum.Health <= 0 then return end
        if getHussRole(player) ~= "Runner" then return end
        local closestDist = math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and getHussRole(plr) == "Chaser" then
                local chaserChar = plr.Character
                local chaserRoot = chaserChar and chaserChar:FindFirstChild("HumanoidRootPart")
                if chaserRoot then
                    local dist = (myRoot.Position - chaserRoot.Position).Magnitude
                    if dist < closestDist then closestDist = dist end
                end
            end
        end
        if closestDist < 12 then
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            myHum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))
end

local function setHussAutoTackle(on)
    state.hussAutoTackle = on
    if state.hussTackleConn then state.hussTackleConn:Disconnect() state.hussTackleConn = nil end
    if not on then return end
    state.hussTackleConn = track(RunService.Heartbeat:Connect(function()
        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myRoot or not myHum or myHum.Health <= 0 then return end
        if getHussRole(player) ~= "Chaser" then return end
        local closestRunner = nil
        local closestDist = math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and getHussRole(plr) == "Runner" then
                local runChar = plr.Character
                local runRoot = runChar and runChar:FindFirstChild("HumanoidRootPart")
                if runRoot then
                    local dist = (myRoot.Position - runRoot.Position).Magnitude
                    if dist < closestDist then closestDist = dist; closestRunner = runRoot end
                end
            end
        end
        if closestRunner and closestDist < 10 then
            myRoot.CFrame = closestRunner.CFrame * CFrame.new(0, 0, 2)
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton1(Vector2.new())
        end
    end))
end

local function setHussEsp(on)
    state.hussEsp = on
    if state.hussEspConn then state.hussEspConn:Disconnect() state.hussEspConn = nil end
    for _, h in pairs(state.hussHighlights) do if h and h.Parent then h:Destroy() end end
    state.hussHighlights = {}
    if not on then return end
    state.hussEspConn = track(RunService.Heartbeat:Connect(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local role = getHussRole(plr)
                local hl = state.hussHighlights[plr.UserId]
                if not hl or not hl.Parent then
                    hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = plr.Character
                    state.hussHighlights[plr.UserId] = hl
                end
                if role == "Chaser" then
                    hl.FillColor = Color3.fromRGB(255, 30, 30); hl.OutlineColor = Color3.fromRGB(255, 100, 100)
                elseif role == "Runner" then
                    hl.FillColor = Color3.fromRGB(40, 220, 80); hl.OutlineColor = Color3.fromRGB(100, 255, 140)
                else
                    hl.FillColor = Color3.fromRGB(100, 100, 100); hl.OutlineColor = Color3.fromRGB(150, 150, 150)
                end
            end
        end
    end))
end

-- ==========================================
-- PREMIUM UI BUILD
-- ==========================================
local gui = Instance.new("ScreenGui")
gui.Name="PocketGUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=999; gui.Parent=pg

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 440, 0, 360)
main.Position = UDim2.new(0.5, -220, 0.5, -180)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24); main.BorderSizePixel = 0; main.Active = true; main.Parent = gui
local mainCr = Instance.new("UICorner"); mainCr.CornerRadius = UDim.new(0,16); mainCr.Parent = main
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = Color3.fromRGB(120, 80, 255); mainStroke.Thickness = 2; mainStroke.Transparency = 0.3; mainStroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 45); title.Position = UDim2.new(0, 20, 0, 5)
title.BackgroundTransparency = 1; title.Text = "POCKETGUI v27.0"
title.TextColor3 = Color3.fromRGB(255,255,255); title.Font = Enum.Font.GothamBlack; title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = main
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))}
titleGrad.Parent = title

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Size = UDim2.new(1, -40, 0, 40); tabScroll.Position = UDim2.new(0, 20, 0, 55)
tabScroll.BackgroundTransparency = 1; tabScroll.BorderSizePixel = 0; tabScroll.ScrollBarThickness = 0
tabScroll.CanvasSize = UDim2.new(0,0,0,0); tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
tabScroll.ScrollingDirection = Enum.ScrollingDirection.X; tabScroll.Parent = main

local tabLayout = Instance.new("UIListLayout"); tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0, 8); tabLayout.Parent = tabScroll

local function createTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 85, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42); btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 150, 170); btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.BorderSizePixel = 0; btn.Parent = tabScroll
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = btn
    return btn
end

local tabMove = createTab("MOVE"); local tabVisuals = createTab("VISUALS"); local tabPlayers = createTab("PLAYERS"); local tabMM2 = createTab("MM2")
local tabDisaster = createTab("DISASTER"); local tabUtility = createTab("UTILITY"); local tabHuss = createTab("HUSS")

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -40, 1, -170); content.Position = UDim2.new(0, 20, 0, 110); content.BackgroundTransparency = 1; content.Parent = main

local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0; p.ScrollBarThickness = 2
    p.Visible = false; p.CanvasSize = UDim2.new(0,0,0,0); p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
    return p
end

local pageMove=createPage() local pageVisuals=createPage() local pagePlayers=createPage() local pageMM2=createPage()
local pageDisaster=createPage() local pageUtility=createPage() local pageHuss=createPage()

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

local function createAction(parent, text, posY, color)
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 45); btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(45,45,60); btn.Text = text; btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,8); cr.Parent = btn
    return btn
end

-- PAGE 1: MOVE
local flyBtn, flyBg, flyKnob = createToggle(pageMove, "Enable Fly", 0)
local flySpeedLabel, flySpeedMinus, flySpeedPlus = createStepper(pageMove, "Fly Speed: 60", 60)
local noclipBtn, noclipBg, noclipKnob = createToggle(pageMove, "Noclip", 120)
local speedLabel, speedMinus, speedPlus = createStepper(pageMove, "WalkSpeed: 16", 180)
local speedBtn, speedBg, speedKnob = createToggle(pageMove, "Apply Speed", 240)
local highJumpBtn, highJumpBg, highJumpKnob = createToggle(pageMove, "High Jump", 300)
local antiAfkBtn, antiAfkBg, antiAfkKnob = createToggle(pageMove, "Anti-AFK", 360)
local resetBtn = createAction(pageMove, "Respawn (Reset)", 420, Color3.fromRGB(220, 60, 80))
local tpBtn = createAction(pageMove, "Click Teleport", 475, Color3.fromRGB(80, 60, 180))
local flingBtn = createAction(pageMove, "Touch Fling", 530, Color3.fromRGB(200, 60, 80))

-- PAGE 2: VISUALS
local espBtn, espBg, espKnob = createToggle(pageVisuals, "Player ESP", 0)
local xrayBtn, xrayBg, xrayKnob = createToggle(pageVisuals, "X-Ray", 60)
local skeletonBtn, skeletonBg, skeletonKnob = createToggle(pageVisuals, "Skeleton ESP", 120)
local selfChamsBtn, selfChamsBg, selfChamsKnob = createToggle(pageVisuals, "Self Chams", 180)

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

            local tpPlayerBtn = Instance.new("TextButton")
            tpPlayerBtn.Size = UDim2.new(0, 85, 1, -14); tpPlayerBtn.Position = UDim2.new(1, -100, 0, 7)
            tpPlayerBtn.BackgroundColor3 = Color3.fromRGB(60,120,200); tpPlayerBtn.Text = "Teleport"
            tpPlayerBtn.TextColor3 = Color3.fromRGB(255,255,255); tpPlayerBtn.Font = Enum.Font.GothamBold; tpPlayerBtn.TextSize = 13; tpPlayerBtn.Parent = row
            local tcr = Instance.new("UICorner"); tcr.CornerRadius = UDim.new(0,8); tcr.Parent = tpPlayerBtn

            tpPlayerBtn.MouseButton1Click:Connect(function() tpToPlayer(plr) end)
        end
    end
end
refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

-- PAGE 4: MM2
local mm2EspBtn, mm2EspBg, mm2EspKnob = createToggle(pageMM2, "Role ESP", 0)
local mm2KillBtn = createAction(pageMM2, "Kill All (Knife)", 60, Color3.fromRGB(120,30,40))
local mm2GunBtn = createAction(pageMM2, "Grab Gun", 115, Color3.fromRGB(40,80,120))

-- PAGE 5: DISASTER
local godBtn, godBg, godKnob = createToggle(pageDisaster, "Godmode (Survive All)", 0)
local winBtn, winBg, winKnob = createToggle(pageDisaster, "Auto-Win (TP to Tower)", 60)

-- PAGE 6: UTILITY
local infJumpBtn, infJumpBg, infJumpKnob = createToggle(pageUtility, "Infinite Jump", 0)

-- PAGE 7: HUSS VALLEY
local hussDodgeBtn, hussDodgeBg, hussDodgeKnob = createToggle(pageHuss, "God Runner (Auto Dodge)", 0)
local hussTackleBtn, hussTackleBg, hussTackleKnob = createToggle(pageHuss, "God Chaser (Auto Tackle)", 60)
local hussEspBtn, hussEspBg, hussEspKnob = createToggle(pageHuss, "Role ESP (See Everyone)", 120)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -40, 0, 40); closeBtn.Position = UDim2.new(0, 20, 1, -55)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55); closeBtn.Text = "HIDE MENU"; closeBtn.TextColor3 = Color3.fromRGB(200,200,220)
closeBtn.Font = Enum.Font.GothamBlack; closeBtn.TextSize = 14; closeBtn.BorderSizePixel = 0; closeBtn.Parent = main
local cbCr = Instance.new("UICorner"); cbCr.CornerRadius = UDim.new(0,10); cbCr.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local allTabs = {tabMove, tabVisuals, tabPlayers, tabMM2, tabDisaster, tabUtility, tabHuss}
local allPages = {pageMove, pageVisuals, pagePlayers, pageMM2, pageDisaster, pageUtility, pageHuss}

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

flyBtn.MouseButton1Click:Connect(function() setFly(not state.flying) animateToggle(flyBg, flyKnob, state.flying) end)
noclipBtn.MouseButton1Click:Connect(function() setNoclip(not state.noclip) animateToggle(noclipBg, noclipKnob, state.noclip) end)
speedBtn.MouseButton1Click:Connect(function() setSpeedBoost(not state.speedBoost) animateToggle(speedBg, speedKnob, state.speedBoost) end)
espBtn.MouseButton1Click:Connect(function() setPlayerEsp(not state.playerEsp) animateToggle(espBg, espKnob, state.playerEsp) end)
xrayBtn.MouseButton1Click:Connect(function() setXRay(not state.xray) animateToggle(xrayBg, xrayKnob, state.xray) end)
skeletonBtn.MouseButton1Click:Connect(function() setSkeletonEsp(not state.skeletonEsp) animateToggle(skeletonBg, skeletonKnob, state.skeletonEsp) end)
selfChamsBtn.MouseButton1Click:Connect(function() setSelfChams(not state.selfChams) animateToggle(selfChamsBg, selfChamsKnob, state.selfChams) end)
mm2EspBtn.MouseButton1Click:Connect(function() setMM2Esp(not state.mm2Esp) animateToggle(mm2EspBg, mm2EspKnob, state.mm2Esp) end)
antiAfkBtn.MouseButton1Click:Connect(function() setAntiAfk(not state.antiAfk) animateToggle(antiAfkBg, antiAfkKnob, state.antiAfk) end)
highJumpBtn.MouseButton1Click:Connect(function() setHighJump(not state.highJump) animateToggle(highJumpBg, highJumpKnob, state.highJump) end)

godBtn.MouseButton1Click:Connect(function() setNDSGodmode(not state.ndsGodmode) animateToggle(godBg, godKnob, state.ndsGodmode) end)
winBtn.MouseButton1Click:Connect(function() setNDSAutoWin(not state.ndsAutoWin) animateToggle(winBg, winKnob, state.ndsAutoWin) end)
infJumpBtn.MouseButton1Click:Connect(function() setInfJump(not state.infJump) animateToggle(infJumpBg, infJumpKnob, state.infJump) end)

hussDodgeBtn.MouseButton1Click:Connect(function() setHussAutoDodge(not state.hussAutoDodge) animateToggle(hussDodgeBg, hussDodgeKnob, state.hussAutoDodge) end)
hussTackleBtn.MouseButton1Click:Connect(function() setHussAutoTackle(not state.hussAutoTackle) animateToggle(hussTackleBg, hussTackleKnob, state.hussAutoTackle) end)
hussEspBtn.MouseButton1Click:Connect(function() setHussEsp(not state.hussEsp) animateToggle(hussEspBg, hussEspKnob, state.hussEsp) end)

tpBtn.MouseButton1Click:Connect(function() enableTapTP(tpBtn) end)
flingBtn.MouseButton1Click:Connect(function() enableFling(flingBtn) end)
resetBtn.MouseButton1Click:Connect(function() respawnPlayer() end)

mm2KillBtn.MouseButton1Click:Connect(function() local s=mm2KillAll() mm2KillBtn.Text=s and "Killed ✓" or "Need Knife!" task.delay(1.5,function() mm2KillBtn.Text="Kill All (Knife)" end) end)
mm2GunBtn.MouseButton1Click:Connect(function() local s=mm2GrabGun() mm2GunBtn.Text=s and "Teleported ✓" or "No Gun" task.delay(1.5,function() mm2GunBtn.Text="Grab Gun" end) end)

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

-- FLOATING BUTTON
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

local dragging, dragStart, startPos
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = floatBtn.Position
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
        if delta.Magnitude < 10 then main.Visible = not main.Visible end
    end
end)

print(" thank you for using PocketGUI ")
