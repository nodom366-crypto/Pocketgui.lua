--[[
    PocketGUI v26.4 — Mobile Edition (with Anti-Fling)
    Changelog vs 26.3:
      - Removed workspace.FallenPartsDestroyHeight = 0/0 (crashed on modern Roblox)
      - Wrapped boot + fling in pcalls
      - P logo centered (AnchorPoint + TextX/YAlignment Center)
      - Shadow scales with button (no drift)
      - Mobile: 60x60 float button, 44px tap targets, no mouse-only events
      - Mobile: drag-vs-tap uses GetMouseLocation() with 12px threshold
      - Mobile: main window drag from title bar
      - Mobile: 92% width / 90% height clamp
      - Character respawn re-applies fly/noclip/speed/jump/antifling
      - ESP/MM2 highlights cleaned up on player leave
      - NEW: Anti-Fling (velocity clamp + BodyVelocity strip + CFrame guard)
]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local StarterGui   = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild("PocketGUI")       then pg.PocketGUI:Destroy() end
if pg:FindFirstChild("PocketGUI_Float") then pg.PocketGUI_Float:Destroy() end

local IS_MOBILE = UIS.TouchEnabled and not UIS.MouseEnabled

-- =========================================================
-- STATE
-- =========================================================
local state = {
    flying=false, noclip=false, walkSpeed=16, jumpPower=50,
    speedBoost=false, highJump=false, xray=false,
    playerEsp=false, mm2Esp=false, antiAfk=false, antiFling=false,
    flySpeed=60, tpMode=false,
    flyConn=nil, bodyVelocity=nil, bodyGyro=nil, tpConn=nil,
    noclipConn=nil, speedConn=nil, jumpConn=nil,
    playerEspConn=nil, playerHighlights={},
    mm2EspConn=nil, mm2Highlights={},
    antiAfkConn=nil, antiFlingConn=nil,
    connections={}
}

local function track(c) table.insert(state.connections, c); return c end
local function getRoot() local c = player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c = player.Character; return c and c:FindFirstChildOfClass("Humanoid") end

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title=title, Text=text, Duration=4 })
    end)
end

-- =========================================================
-- SKIDFLING (instant-kill integrated)
-- =========================================================
local function skidFling(TargetPlayer, instantKill)
    if TargetPlayer == player then return end
    local Character = player.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    if not Humanoid or not RootPart then return end

    local TCharacter = TargetPlayer.Character
    if not TCharacter then return notify("Fling", "Target has no character") end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead     = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle    = Accessory and Accessory:FindFirstChild("Handle")
    if not THumanoid then return notify("Fling", "Target missing humanoid") end

    local OldPos = RootPart.CFrame
    pcall(function() workspace.CurrentCamera.CameraSubject = THead or THumanoid or Handle end)

    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:PivotTo(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity    = Vector3.new(9e7, 9e8, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if not (RootPart and RootPart.Parent and THumanoid and THumanoid.Parent) then break end
            if instantKill and THumanoid.Health > 0 then pcall(function() THumanoid.Health = 0 end) end

            if BasePart.Velocity.Magnitude < 50 then
                Angle = Angle + 100
                local dir = THumanoid.MoveDirection or Vector3.zero
                FPos(BasePart, CFrame.new(0, 1.5, 0) + dir * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0)); task.wait()
                FPos(BasePart, CFrame.new(0,-1.5, 0) + dir * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0)); task.wait()
                FPos(BasePart, CFrame.new(2.25, 1.5,-2.25) + dir * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0)); task.wait()
                FPos(BasePart, CFrame.new(-2.25,-1.5, 2.25) + dir * BasePart.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(Angle),0,0)); task.wait()
            else
                local ws = THumanoid.WalkSpeed or 16
                local tv = (TRootPart and TRootPart.Velocity.Magnitude or BasePart.Velocity.Magnitude)
                FPos(BasePart, CFrame.new(0, 1.5, ws), CFrame.Angles(math.rad(90),0,0)); task.wait()
                FPos(BasePart, CFrame.new(0,-1.5,-ws), CFrame.Angles(0,0,0)); task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, ws), CFrame.Angles(math.rad(90),0,0)); task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, tv/1.25), CFrame.Angles(math.rad(90),0,0)); task.wait()
                FPos(BasePart, CFrame.new(0,-1.5,-tv/1.25), CFrame.Angles(0,0,0)); task.wait()
                FPos(BasePart, CFrame.new(0,-1.5, 0), CFrame.Angles(math.rad(90),0,0)); task.wait()
            end
        until
            BasePart.Velocity.Magnitude > 500
            or BasePart.Parent ~= TCharacter
            or TargetPlayer.Parent ~= Players
            or not TargetPlayer.Character
            or (THumanoid and THumanoid.Sit)
            or (Humanoid and Humanoid.Health <= 0)
            or tick() > Time + TimeToWait
    end

    local BV = Instance.new("BodyVelocity")
    BV.Name = "PocketFlingVel"; BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

    pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)
    pcall(function()
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then SFBasePart(THead) else SFBasePart(TRootPart) end
        elseif TRootPart then SFBasePart(TRootPart)
        elseif THead     then SFBasePart(THead)
        elseif Handle    then SFBasePart(Handle) end
    end)

    pcall(function() BV:Destroy() end)
    pcall(function() Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
    pcall(function() workspace.CurrentCamera.CameraSubject = Humanoid end)

    local startTime = tick()
    repeat
        RootPart.CFrame = OldPos * CFrame.new(0, 0.5, 0)
        pcall(function() Character:PivotTo(OldPos * CFrame.new(0, 0.5, 0)) end)
        pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        for _, x in ipairs(Character:GetChildren()) do
            if x:IsA("BasePart") then x.Velocity = Vector3.zero; x.RotVelocity = Vector3.zero end
        end
        task.wait()
    until (RootPart.Position - OldPos.Position).Magnitude < 25 or tick() > startTime + 3
end

local function killAll()
    local any = false
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            task.spawn(function() pcall(function() skidFling(plr, true) end) end)
            any = true
        end
    end
    return any
end

-- =========================================================
-- ANTI-FLING
-- =========================================================
-- Strategy:
--   1. Clamp HumanoidRootPart velocity every physics step (prevents 9e8 injection)
--   2. Strip any foreign BodyVelocity / BodyAngularVelocity / BodyGyro injected into our root
--   3. If displacement in one frame exceeds MAX_JUMP, snap back to last good CFrame
--   4. Zero out angular velocity
local MAX_SPEED   = 250    -- studs/sec — higher than fly speed so fly works
local MAX_JUMP    = 40     -- studs in a single frame before we consider it a fling
local lastGoodPos = nil

local function setAntiFling(on)
    state.antiFling = on
    if state.antiFlingConn then
        state.antiFlingConn:Disconnect()
        state.antiFlingConn = nil
    end
    lastGoodPos = nil
    if not on then return end

    state.antiFlingConn = track(RunService.Heartbeat:Connect(function()
        local root = getRoot()
        if not root then lastGoodPos = nil; return end

        -- 1. Strip foreign body movers on our root
        for _, child in ipairs(root:GetChildren()) do
            if child:IsA("BodyVelocity")
                or child:IsA("BodyAngularVelocity")
                or child:IsA("BodyGyro")
                or child:IsA("BodyPosition")
                or child:IsA("BodyForce") then
                -- Don't remove OUR fly movers
                if child ~= state.bodyVelocity and child ~= state.bodyGyro then
                    if child.Name ~= "PocketFlingVel" or true then
                        pcall(function() child:Destroy() end)
                    end
                end
            end
        end

        -- 2. Clamp velocity
        local v = root.AssemblyLinearVelocity
        if v.Magnitude > MAX_SPEED then
            root.AssemblyLinearVelocity = v.Unit * MAX_SPEED
        end
        if root.AssemblyAngularVelocity.Magnitude > 50 then
            root.AssemblyAngularVelocity = Vector3.zero
        end

        -- 3. Displacement guard (catches CFrame-based flings)
        if lastGoodPos then
            local delta = (root.Position - lastGoodPos).Magnitude
            if delta > MAX_JUMP then
                pcall(function()
                    root.CFrame = CFrame.new(lastGoodPos)
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
            else
                lastGoodPos = root.Position
            end
        else
            lastGoodPos = root.Position
        end
    end))
end

-- =========================================================
-- FLY
-- =========================================================
local function setFly(on)
    state.flying = on
    local root, hum = getRoot(), getHum()

    if state.flyConn      then state.flyConn:Disconnect()   state.flyConn = nil end
    if state.bodyVelocity then state.bodyVelocity:Destroy() state.bodyVelocity = nil end
    if state.bodyGyro     then state.bodyGyro:Destroy()     state.bodyGyro = nil end

    if not on or not root or not hum then
        if hum then pcall(function() hum.PlatformStand = false end) end
        return
    end

    pcall(function() hum.PlatformStand = true; hum.MaxHealth = math.huge; hum.Health = math.huge end)

    state.bodyVelocity = Instance.new("BodyVelocity")
    state.bodyVelocity.Name = "PocketFlyVel"
    state.bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    state.bodyVelocity.Velocity = Vector3.zero
    state.bodyVelocity.Parent = root

    state.bodyGyro = Instance.new("BodyGyro")
    state.bodyGyro.Name = "PocketFlyGyro"
    state.bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    state.bodyGyro.P = 10000
    state.bodyGyro.CFrame = camera.CFrame
    state.bodyGyro.Parent = root

    state.flyConn = track(RunService.RenderStepped:Connect(function()
        if not state.flying or not root or not root.Parent or not state.bodyVelocity or not state.bodyGyro then return end
        local move = hum.MoveDirection
        local look = camera.CFrame.LookVector
        local horizontal = Vector3.new(move.X, 0, move.Z)
        local vertical   = look.Y * move.Magnitude
        local direction  = horizontal + Vector3.new(0, vertical, 0)
        state.bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * state.flySpeed or Vector3.zero
        state.bodyGyro.CFrame = camera.CFrame
    end))

    task.spawn(function()
        while state.flying do task.wait(0.5) end
        if hum then pcall(function() hum.MaxHealth = 100; hum.Health = 100; hum.PlatformStand = false end) end
    end)
end

-- =========================================================
-- CLICK TELEPORT
-- =========================================================
local function enableTapTP(onButton)
    if state.tpConn then state.tpConn:Disconnect() state.tpConn = nil end
    state.tpMode = not state.tpMode
    if not state.tpMode then onButton.Text = "Click Teleport" return end
    onButton.Text = "Tap anywhere..."

    state.tpConn = track(UIS.InputBegan:Connect(function(input)
        if not state.tpMode then return end
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local guiObj = player.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
        for _, obj in ipairs(guiObj) do if obj:IsDescendantOf(pg.PocketGUI) then return end end
        local ray = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { player.Character }
        local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
        if result then local root = getRoot(); if root then root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end end
        state.tpMode = false; onButton.Text = "Click Teleport"
        if state.tpConn then state.tpConn:Disconnect() state.tpConn = nil end
    end))
end

-- =========================================================
-- NOCLIP / SPEED / JUMP / XRAY / ESP / MM2 / ANTIAFK
-- =========================================================
local function setNoclip(on)
    state.noclip = on
    if state.noclipConn then state.noclipConn:Disconnect() state.noclipConn = nil end
    local c = player.Character
    if not on then
        if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        return
    end
    state.noclipConn = track(RunService.Stepped:Connect(function()
        local char = player.Character; if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
        end
    end))
end

local function setSpeedBoost(on)
    state.speedBoost = on
    if state.speedConn then state.speedConn:Disconnect() state.speedConn = nil end
    if not on then local h = getHum(); if h then h.WalkSpeed = 16 end; return end
    state.speedConn = track(RunService.Heartbeat:Connect(function()
        local h = getHum(); if h then h.WalkSpeed = state.walkSpeed end
    end))
end

local function setHighJump(on)
    state.highJump = on
    if state.jumpConn then state.jumpConn:Disconnect() state.jumpConn = nil end
    if not on then local h = getHum(); if h then h.JumpPower = 50 end; return end
    state.jumpConn = track(RunService.Heartbeat:Connect(function()
        local h = getHum(); if h then h.JumpPower = state.jumpPower end
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
        local seen = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    seen[plr.UserId] = true
                    local hl = state.playerHighlights[plr.UserId]
                    if not hl or not hl.Parent then
                        hl = Instance.new("Highlight")
                        hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.FillColor = Color3.fromRGB(255, 50, 50)
                        hl.OutlineColor = Color3.fromRGB(255, 100, 100)
                        hl.Parent = plr.Character
                        state.playerHighlights[plr.UserId] = hl
                    end
                end
            end
        end
        for uid, hl in pairs(state.playerHighlights) do
            if not seen[uid] then if hl and hl.Parent then hl:Destroy() end; state.playerHighlights[uid] = nil end
        end
    end))
end

local function getMM2Role(plr)
    local char = plr.Character; if not char then return nil end
    local function scan(container)
        if not container then return nil end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") or n:find("dagger") then return "Murderer" end
                if n:find("gun") or n:find("revolver") or n:find("pistol") then return "Sheriff" end
            end
        end
    end
    local r = scan(char) or scan(plr:FindFirstChild("Backpack"))
    if r then return r end
    local role = char:GetAttribute("Role") or char:GetAttribute("role") or plr:GetAttribute("Role")
    if role then
        local s = tostring(role):lower()
        if s:find("murder") then return "Murderer" end
        if s:find("sheriff") or s:find("gun") then return "Sheriff" end
        if s:find("innoc") then return "Innocent" end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then return "Innocent" end
    return nil
end

local function setMM2Esp(on)
    state.mm2Esp = on
    if state.mm2EspConn then state.mm2EspConn:Disconnect() state.mm2EspConn = nil end
    for _, h in pairs(state.mm2Highlights) do if h and h.Parent then h:Destroy() end end
    state.mm2Highlights = {}
    if not on then return end
    state.mm2EspConn = track(RunService.Heartbeat:Connect(function()
        local seen = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    seen[plr.UserId] = true
                    local role = getMM2Role(plr)
                    local hl = state.mm2Highlights[plr.UserId]
                    if not hl or not hl.Parent then
                        hl = Instance.new("Highlight")
                        hl.FillTransparency = 0.55; hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = plr.Character
                        state.mm2Highlights[plr.UserId] = hl
                    end
                    if role == "Murderer" then
                        hl.FillColor = Color3.fromRGB(255,30,30); hl.OutlineColor = Color3.fromRGB(255,100,100)
                    elseif role == "Sheriff" then
                        hl.FillColor = Color3.fromRGB(40,120,255); hl.OutlineColor = Color3.fromRGB(100,180,255)
                    else
                        hl.FillColor = Color3.fromRGB(40,220,80);  hl.OutlineColor = Color3.fromRGB(100,255,140)
                    end
                end
            end
        end
        for uid, hl in pairs(state.mm2Highlights) do
            if not seen[uid] then if hl and hl.Parent then hl:Destroy() end; state.mm2Highlights[uid] = nil end
        end
    end))
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

local function setAntiAfk(on)
    state.antiAfk = on
    if state.antiAfkConn then state.antiAfkConn:Disconnect() state.antiAfkConn = nil end
    if not on then return end
    state.antiAfkConn = track(player.Idled:Connect(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController(); vu:ClickButton2(Vector2.new())
    end))
end

local function respawnPlayer()
    local char = player.Character
    if char then local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.Health = 0 end end
end

local function tpToPlayer(plr)
    local myRoot = getRoot()
    local targetChar = workspace:FindFirstChild(plr.Name)
    local tRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso"))
    if myRoot and tRoot then myRoot.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0) end
end

player.CharacterAdded:Connect(function()
    task.wait(1)
    if state.noclip     then setNoclip(true)     end
    if state.speedBoost then setSpeedBoost(true) end
    if state.highJump   then setHighJump(true)   end
    if state.antiAfk    then setAntiAfk(true)    end
    if state.antiFling  then setAntiFling(true)  end
    if state.flying then state.flying = false; task.wait(0.3); setFly(true) end
end)

-- =========================================================
-- UI BUILD (mobile-first)
-- =========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "PocketGUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.DisplayOrder = 999; gui.Parent = pg

local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0.92, 0, 0.9, 0)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0; main.Active = true; main.Parent = gui

local mainCr = Instance.new("UICorner"); mainCr.CornerRadius = UDim.new(0, 16); mainCr.Parent = main
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(120, 80, 255); mainStroke.Thickness = 2; mainStroke.Transparency = 0.3
mainStroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 44); title.Position = UDim2.new(0, 20, 0, 6)
title.BackgroundTransparency = 1; title.Text = "POCKETGUI"
title.TextColor3 = Color3.fromRGB(255,255,255); title.Font = Enum.Font.GothamBlack
title.TextSize = 24; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = main

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200,100,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100,200,255))
}
titleGrad.Parent = title

-- Title-bar drag
local dragHandle = Instance.new("TextButton")
dragHandle.Size = UDim2.new(1, 0, 0, 44); dragHandle.Position = UDim2.new(0, 0, 0, 0)
dragHandle.BackgroundTransparency = 1; dragHandle.Text = ""; dragHandle.Parent = main
do
    local dragging, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = main.Position
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -40, 0, 44); tabBar.Position = UDim2.new(0, 20, 0, 56)
tabBar.BackgroundTransparency = 1; tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6); tabLayout.Parent = tabBar

local function createTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btn.Text = text; btn.TextColor3 = Color3.fromRGB(150, 150, 170)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.BorderSizePixel = 0
    btn.AutoButtonColor = false; btn.Selectable = false; btn.Parent = tabBar
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = btn
    return btn
end

local tabMove, tabVisuals, tabPlayers, tabMM2, tabHuss =
    createTab("MOVE"), createTab("VISUALS"), createTab("PLAYERS"), createTab("MM2"), createTab("HUSS")

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -40, 1, -176); content.Position = UDim2.new(0, 20, 0, 116)
content.BackgroundTransparency = 1; content.Parent = main

local function createPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 4; p.ScrollingDirection = Enum.ScrollingDirection.Y
    p.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    p.Visible = false; p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.Parent = content
    return p
end

local pageMove, pageVisuals, pagePlayers, pageMM2, pageHuss =
    createPage(), createPage(), createPage(), createPage(), createPage()

local ROW_H = 54
local function createToggle(parent, text, posY)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, ROW_H); f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 38); f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 12); cr.Parent = f

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 1, 0); lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 54, 0, 30); switchBg.Position = UDim2.new(1, -70, 0.5, -15)
    switchBg.BackgroundColor3 = Color3.fromRGB(45,45,60); switchBg.Parent = f
    local sbCr = Instance.new("UICorner"); sbCr.CornerRadius = UDim.new(1, 0); sbCr.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 24, 0, 24); knob.Position = UDim2.new(0, 3, 0.5, -12)
    knob.BackgroundColor3 = Color3.fromRGB(150,150,150); knob.Parent = switchBg
    local kCr = Instance.new("UICorner"); kCr.CornerRadius = UDim.new(1, 0); kCr.Parent = knob

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1
    btn.Text = ""; btn.AutoButtonColor = false; btn.Selectable = false; btn.Parent = f
    return btn, switchBg, knob
end

local function createStepper(parent, text, posY)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, ROW_H); f.Position = UDim2.new(0, 0, 0, posY)
    f.BackgroundColor3 = Color3.fromRGB(28, 28, 38); f.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 12); cr.Parent = f

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -120, 1, 0); lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 44, 0, 44); minus.Position = UDim2.new(1, -100, 0.5, -22)
    minus.BackgroundColor3 = Color3.fromRGB(200, 60, 80); minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255,255,255); minus.Font = Enum.Font.GothamBlack
    minus.TextSize = 22; minus.AutoButtonColor = false; minus.Selectable = false; minus.Parent = f
    local mCr = Instance.new("UICorner"); mCr.CornerRadius = UDim.new(0, 10); mCr.Parent = minus

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 44, 0, 44); plus.Position = UDim2.new(1, -52, 0.5, -22)
    plus.BackgroundColor3 = Color3.fromRGB(60, 180, 90); plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255,255,255); plus.Font = Enum.Font.GothamBlack
    plus.TextSize = 22; plus.AutoButtonColor = false; plus.Selectable = false; plus.Parent = f
    local pCr = Instance.new("UICorner"); pCr.CornerRadius = UDim.new(0, 10); pCr.Parent = plus

    return lbl, minus, plus
end

local function createAction(parent, text, posY, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 48); btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = color or Color3.fromRGB(45,45,60); btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15; btn.AutoButtonColor = false; btn.Selectable = false; btn.Parent = parent
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 10); cr.Parent = btn
    return btn
end

-- PAGE 1: MOVE
local flyBtn,       flyBg,       flyKnob       = createToggle(pageMove, "Enable Fly", 0)
local flySpeedLabel, flySpeedMinus, flySpeedPlus = createStepper(pageMove, "Fly Speed: 60", 62)
local noclipBtn,    noclipBg,    noclipKnob    = createToggle(pageMove, "Noclip", 124)
local speedLabel,   speedMinus,  speedPlus     = createStepper(pageMove, "WalkSpeed: 16", 186)
local speedBtn,     speedBg,     speedKnob     = createToggle(pageMove, "Apply Speed", 248)
local highJumpBtn,  highJumpBg,  highJumpKnob  = createToggle(pageMove, "High Jump", 310)
local antiAfkBtn,   antiAfkBg,   antiAfkKnob   = createToggle(pageMove, "Anti-AFK", 372)
local resetBtn = createAction(pageMove, "Respawn (Reset)", 434, Color3.fromRGB(220, 60, 80))

-- PAGE 2: VISUALS
local tpBtn = createAction(pageVisuals, "Click Teleport", 0, Color3.fromRGB(80, 60, 180))
local espBtn,   espBg,   espKnob   = createToggle(pageVisuals, "Player ESP", 58)
local xrayBtn,  xrayBg,  xrayKnob  = createToggle(pageVisuals, "X-Ray", 120)
local aFlingBtn, aFlingBg, aFlingKnob = createToggle(pageVisuals, "Anti-Fling", 182)

-- PAGE 3: PLAYERS
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, -10, 1, 0); playerListFrame.BackgroundTransparency = 1
playerListFrame.Parent = pagePlayers
local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 6); playerLayout.Parent = playerListFrame

local function refreshPlayerList()
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 54); row.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            row.Parent = playerListFrame
            local rcr = Instance.new("UICorner"); rcr.CornerRadius = UDim.new(0, 12); rcr.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -170, 1, 0); nameLbl.Position = UDim2.new(0, 16, 0, 0)
            nameLbl.BackgroundTransparency = 1; nameLbl.Text = plr.Name
            nameLbl.TextColor3 = Color3.fromRGB(255,255,255); nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 14; nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = row

            local killPlayerBtn = Instance.new("TextButton")
            killPlayerBtn.Size = UDim2.new(0, 72, 0, 40); killPlayerBtn.Position = UDim2.new(1, -160, 0.5, -20)
            killPlayerBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 80); killPlayerBtn.Text = "Kill"
            killPlayerBtn.TextColor3 = Color3.fromRGB(255,255,255); killPlayerBtn.Font = Enum.Font.GothamBold
            killPlayerBtn.TextSize = 13; killPlayerBtn.AutoButtonColor = false
            killPlayerBtn.Selectable = false; killPlayerBtn.Parent = row
            local kcr = Instance.new("UICorner"); kcr.CornerRadius = UDim.new(0, 8); kcr.Parent = killPlayerBtn

            local tpPlayerBtn = Instance.new("TextButton")
            tpPlayerBtn.Size = UDim2.new(0, 72, 0, 40); tpPlayerBtn.Position = UDim2.new(1, -82, 0.5, -20)
            tpPlayerBtn.BackgroundColor3 = Color3.fromRGB(60,120,200); tpPlayerBtn.Text = "TP"
            tpPlayerBtn.TextColor3 = Color3.fromRGB(255,255,255); tpPlayerBtn.Font = Enum.Font.GothamBold
            tpPlayerBtn.TextSize = 13; tpPlayerBtn.AutoButtonColor = false
            tpPlayerBtn.Selectable = false; tpPlayerBtn.Parent = row
            local tcr = Instance.new("UICorner"); tcr.CornerRadius = UDim.new(0, 8); tcr.Parent = tpPlayerBtn

            killPlayerBtn.Activated:Connect(function()
                task.spawn(function() pcall(function() skidFling(plr, true) end) end)
            end)
            tpPlayerBtn.Activated:Connect(function() tpToPlayer(plr) end)
        end
    end
end
refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

-- PAGE 4: MM2
local killAllBtn = createAction(pageMM2, "Kill All (Instant)", 0, Color3.fromRGB(200, 30, 50))
local mm2EspBtn, mm2EspBg, mm2EspKnob = createToggle(pageMM2, "Role ESP", 58)
local mm2GunBtn = createAction(pageMM2, "Grab Gun", 120, Color3.fromRGB(40,80,120))

killAllBtn.Activated:Connect(function()
    killAllBtn.Text = "Flinging & Killing..."
    local success = killAll()
    killAllBtn.Text = success and "Killed All ✓" or "No Players!"
    task.delay(1.5, function() killAllBtn.Text = "Kill All (Instant)" end)
end)
mm2GunBtn.Activated:Connect(function()
    local s = mm2GrabGun()
    mm2GunBtn.Text = s and "Teleported ✓" or "No Gun"
    task.delay(1.5, function() mm2GunBtn.Text = "Grab Gun" end)
end)

-- PAGE 5: HUSS
local hussMunkeBtn = createAction(pageHuss, "Load MunkeHub (Auto Melee/ESP)", 0, Color3.fromRGB(60, 160, 90))
local hussDeltaBtn = createAction(pageHuss, "Load Delta Aim Assist", 60, Color3.fromRGB(60, 120, 200))

hussMunkeBtn.Activated:Connect(function()
    pcall(function() loadstring(game:HttpGet('https://pastefy.app/uHZruyoj/raw'))() end)
end)
hussDeltaBtn.Activated:Connect(function()
    pcall(function() loadstring(game:HttpGet("https://pastefy.app/3pRyePB8/raw"))() end)
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -40, 0, 44); closeBtn.Position = UDim2.new(0, 20, 1, -56)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55); closeBtn.Text = "HIDE MENU"
closeBtn.TextColor3 = Color3.fromRGB(200,200,220); closeBtn.Font = Enum.Font.GothamBlack
closeBtn.TextSize = 14; closeBtn.BorderSizePixel = 0; closeBtn.AutoButtonColor = false
closeBtn.Selectable = false; closeBtn.Parent = main
local cbCr = Instance.new("UICorner"); cbCr.CornerRadius = UDim.new(0, 10); cbCr.Parent = closeBtn
closeBtn.Activated:Connect(function() main.Visible = false end)

local allTabs  = {tabMove, tabVisuals, tabPlayers, tabMM2, tabHuss}
local allPages = {pageMove, pageVisuals, pagePlayers, pageMM2, pageHuss}

local function selectTab(index)
    for i = 1, #allTabs do
        if i == index then
            TweenService:Create(allTabs[i], TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(75,55,140), TextColor3=Color3.fromRGB(255,255,255)}):Play()
            allPages[i].Visible = true
            if i == 3 then refreshPlayerList() end
        else
            TweenService:Create(allTabs[i], TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(30,30,42), TextColor3=Color3.fromRGB(150,150,170)}):Play()
            allPages[i].Visible = false
        end
    end
end
for i, tab in ipairs(allTabs) do tab.Activated:Connect(function() selectTab(i) end) end
selectTab(1)

local function animateToggle(bg, knob, isOn)
    if isOn then
        TweenService:Create(bg,   TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(60,200,100)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position=UDim2.new(0.5, 3, 0.5, -12), BackgroundColor3=Color3.fromRGB(255,255,255)}):Play()
    else
        TweenService:Create(bg,   TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(45,45,60)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {Position=UDim2.new(0, 3, 0.5, -12), BackgroundColor3=Color3.fromRGB(150,150,150)}):Play()
    end
end

flyBtn.Activated:Connect(function()       setFly(not state.flying)               animateToggle(flyBg,       flyKnob,       state.flying)     end)
noclipBtn.Activated:Connect(function()    setNoclip(not state.noclip)            animateToggle(noclipBg,    noclipKnob,    state.noclip)     end)
speedBtn.Activated:Connect(function()     setSpeedBoost(not state.speedBoost)    animateToggle(speedBg,     speedKnob,     state.speedBoost) end)
highJumpBtn.Activated:Connect(function()  setHighJump(not state.highJump)        animateToggle(highJumpBg,  highJumpKnob,  state.highJump)   end)
antiAfkBtn.Activated:Connect(function()   setAntiAfk(not state.antiAfk)          animateToggle(antiAfkBg,   antiAfkKnob,   state.antiAfk)    end)
espBtn.Activated:Connect(function()       setPlayerEsp(not state.playerEsp)      animateToggle(espBg,       espKnob,       state.playerEsp)  end)
xrayBtn.Activated:Connect(function()      setXRay(not state.xray)                animateToggle(xrayBg,      xrayKnob,      state.xray)       end)
mm2EspBtn.Activated:Connect(function()    setMM2Esp(not state.mm2Esp)            animateToggle(mm2EspBg,    mm2EspKnob,    state.mm2Esp)     end)
aFlingBtn.Activated:Connect(function()    setAntiFling(not state.antiFling)      animateToggle(aFlingBg,    aFlingKnob,    state.antiFling)  end)

tpBtn.Activated:Connect(function()    enableTapTP(tpBtn) end)
resetBtn.Activated:Connect(function() respawnPlayer()    end)

speedMinus.Activated:Connect(function()
    state.walkSpeed = math.clamp(state.walkSpeed - 5, 16, 500)
    speedLabel.Text = "WalkSpeed: " .. state.walkSpeed
end)
speedPlus.Activated:Connect(function()
    state.walkSpeed = math.clamp(state.walkSpeed + 5, 16, 500)
    speedLabel.Text = "WalkSpeed: " .. state.walkSpeed
end)
flySpeedMinus.Activated:Connect(function()
    state.flySpeed = math.clamp(state.flySpeed - 50, 10, 1000)
    flySpeedLabel.Text = "Fly Speed: " .. state.flySpeed
end)
flySpeedPlus.Activated:Connect(function()
    state.flySpeed = math.clamp(state.flySpeed + 50, 10, 1000)
    flySpeedLabel.Text = "Fly Speed: " .. state.flySpeed
end)

-- =========================================================
-- FLOATING "P" BUTTON (mobile-tuned)
-- =========================================================
local floatGui = Instance.new("ScreenGui")
floatGui.Name = "PocketGUI_Float"; floatGui.ResetOnSpawn = false
floatGui.DisplayOrder = 1000; floatGui.Parent = pg

local floatBtn = Instance.new("TextButton")
floatBtn.Size = UDim2.new(0, 60, 0, 60)
floatBtn.Position = UDim2.new(0, 20, 0.5, -30)
floatBtn.AnchorPoint = Vector2.new(0, 0.5)
floatBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.Text = ""; floatBtn.BorderSizePixel = 0
floatBtn.AutoButtonColor = false; floatBtn.ClipsDescendants = true
floatBtn.Active = true; floatBtn.Selectable = false
floatBtn.Parent = floatGui

local fbCr = Instance.new("UICorner"); fbCr.CornerRadius = UDim.new(0, 15); fbCr.Parent = floatBtn

local fbGrad = Instance.new("UIGradient")
fbGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(165, 135, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 140, 255))
}
fbGrad.Rotation = 45; fbGrad.Parent = floatBtn

local fbStroke = Instance.new("UIStroke")
fbStroke.Color = Color3.fromRGB(255,255,255); fbStroke.Thickness = 1.5
fbStroke.Transparency = 0.4; fbStroke.Parent = floatBtn

-- Centered "P" logo (shadow + main), both anchored 0.5,0.5 so they stay centered
local logoHolder = Instance.new("Frame")
logoHolder.Size = UDim2.fromScale(1, 1); logoHolder.BackgroundTransparency = 1
logoHolder.Parent = floatBtn

local pShadow = Instance.new("TextLabel")
pShadow.AnchorPoint = Vector2.new(0.5, 0.5)
pShadow.Position    = UDim2.fromScale(0.53, 0.55)
pShadow.Size        = UDim2.fromScale(1, 1)
pShadow.BackgroundTransparency = 1
pShadow.Text = "P"; pShadow.TextColor3 = Color3.fromRGB(0,0,0)
pShadow.TextTransparency = 0.75
pShadow.Font = Enum.Font.GothamBlack; pShadow.TextSize = 36
pShadow.TextXAlignment = Enum.TextXAlignment.Center
pShadow.TextYAlignment = Enum.TextYAlignment.Center
pShadow.ZIndex = 0; pShadow.Parent = logoHolder

local pLogo = Instance.new("TextLabel")
pLogo.AnchorPoint = Vector2.new(0.5, 0.5)
pLogo.Position    = UDim2.fromScale(0.5, 0.5)
pLogo.Size        = UDim2.fromScale(1, 1)
pLogo.BackgroundTransparency = 1
pLogo.Text = "P"; pLogo.TextColor3 = Color3.fromRGB(255,255,255)
pLogo.Font = Enum.Font.GothamBlack; pLogo.TextSize = 36
pLogo.TextXAlignment = Enum.TextXAlignment.Center
pLogo.TextYAlignment = Enum.TextYAlignment.Center
pLogo.ZIndex = 1; pLogo.Parent = logoHolder

-- Press feedback (mobile has no MouseEnter)
local defaultSize = UDim2.new(0, 60, 0, 60)
local pressSize   = UDim2.new(0, 54, 0, 54)
local function sizeTo(sz, dur)
    TweenService:Create(floatBtn, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = sz}):Play()
end

-- Drag vs tap — mobile needs a real threshold
local dragging, dragStartPos, startBtnPos, moved
local TAP_THRESHOLD = 12

floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; moved = false
        dragStartPos = UIS:GetMouseLocation()
        startBtnPos  = floatBtn.Position
        sizeTo(pressSize, 0.1)
    end
end)

floatBtn.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        local cur = UIS:GetMouseLocation()
        local d = cur - dragStartPos
        if d.Magnitude > TAP_THRESHOLD then moved = true end
        floatBtn.Position = UDim2.new(
            startBtnPos.X.Scale, startBtnPos.X.Offset + d.X,
            startBtnPos.Y.Scale, startBtnPos.Y.Offset + d.Y
        )
    end
end)

floatBtn.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not dragging then return end
    dragging = false
    sizeTo(defaultSize, 0.1)
    if not moved then
        main.Visible = not main.Visible
    end
end)

-- Also support .Activated for keyboard/controller and to catch taps that InputEnded might miss
floatBtn.Activated:Connect(function()
    -- Only fire if we didn't just drag (moved flag is reset on next InputBegan)
    if not dragging and not moved then
        main.Visible = not main.Visible
    end
end)

print("[PocketGUI] v26.4 Mobile loaded — Anti-Fling added, P logo centered.")
