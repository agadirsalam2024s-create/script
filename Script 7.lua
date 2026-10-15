--=================================================================
-- RAVEN'S VOIDSCOPE MOD  v8.5  —  Held Gun + Waist Display
--=================================================================

local ok, err = xpcall(function()

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local RunSvc   = game:GetService("RunService")

local PLR  = Players.LocalPlayer
local PGUI = PLR:WaitForChild("PlayerGui", 30); if not PGUI then error("PlayerGui missing") end

local C = {
    BG0=Color3.fromRGB(6,10,20),  BG1=Color3.fromRGB(13,18,34),
    BG2=Color3.fromRGB(20,27,48), BG3=Color3.fromRGB(28,36,62),
    BORDER=Color3.fromRGB(48,64,118),
    BLUE=Color3.fromRGB(77,107,254), BLUE_D=Color3.fromRGB(46,66,200),
    BLUE_L=Color3.fromRGB(120,152,255), ACCENT=Color3.fromRGB(124,92,255),
    TEXT=Color3.fromRGB(232,238,252), DIM=Color3.fromRGB(140,155,195),
    DANGER=Color3.fromRGB(255,84,110),
}

local function tw(o,p,t,s,d) TweenSvc:Create(o,TweenInfo.new(t or .2,s or Enum.EasingStyle.Quad,d or Enum.EasingDirection.Out),p):Play() end
local function cr(p,r) local c=Instance.new("UICorner"); c.CornerRadius=(typeof(r)=="UDim" and r) or UDim.new(0,r or 10); c.Parent=p; return c end
local function sk(p,c,t,tr) local s=Instance.new("UIStroke"); s.Color=c or C.BORDER; s.Thickness=t or 1; s.Transparency=tr or 0; s.Parent=p; return s end
local function px(s) s=tostring(s):gsub("#",""):upper(); if #s~=6 then return nil end
    local r,g,b=tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16)
    return (r and g and b) and {r/255,g/255,b/255} or nil end
local function hx(c) return string.format("%02X%02X%02X",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)) end

--== THEME =====================================================
local themeGrads, themeSolids, themeImgs, themeBtnGrads = {}, {}, {}, {}
local function makeTG(parent, spec, rot)
    local g = Instance.new("UIGradient"); g.Rotation = rot or 0; g.Parent = parent
    local kps = {}
    for i, key in ipairs(spec) do
        local t = #spec==1 and 0 or (i-1)/(#spec-1)
        kps[i] = ColorSequenceKeypoint.new(t, C[key])
    end
    g.Color = ColorSequence.new(kps)
    themeGrads[#themeGrads+1] = {grad=g, spec=spec}
    return g
end
local function regS(o, prop, key) themeSolids[#themeSolids+1] = {obj=o, prop=prop, key=key} end
local function regI(o, prop, key) themeImgs[#themeImgs+1] = {obj=o, prop=prop, key=key} end
local function regBG(g, key) themeBtnGrads[#themeBtnGrads+1] = {grad=g, key=key} end
local function applyTheme()
    for _, e in ipairs(themeGrads) do
        local kps = {}
        for i, key in ipairs(e.spec) do
            local t = #e.spec==1 and 0 or (i-1)/(#e.spec-1)
            kps[i] = ColorSequenceKeypoint.new(t, C[key])
        end
        e.grad.Color = ColorSequence.new(kps)
    end
    for _, e in ipairs(themeSolids) do pcall(function() e.obj[e.prop] = C[e.key] end) end
    for _, e in ipairs(themeImgs) do pcall(function() e.obj[e.prop] = C[e.key] end) end
    for _, e in ipairs(themeBtnGrads) do
        local base = C[e.key]
        e.grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, base:Lerp(Color3.new(1,1,1), .12)),
            ColorSequenceKeypoint.new(1, base:Lerp(Color3.new(0,0,0), .22)),
        })
    end
end
local function setThemeHue(h)
    C.BLUE   = Color3.fromHSV(h, .70, 1.00)
    C.BLUE_D = Color3.fromHSV(h, .80, .78)
    C.BLUE_L = Color3.fromHSV(h, .50, 1.00)
    C.ACCENT = Color3.fromHSV((h+.08)%1, .65, .95)
    applyTheme()
end

--== TARGET ====================================================
local TARGET_NAME     = "Gun"            -- held Tool
local TARGET_REF_NAME = "DisplayRefGun"  -- waist display ObjectValue

local currentTool
local currentDisplay
local currentColor = Color3.fromRGB(77,107,254)
local replaceTexture = true

local chromaOn, chromaHue = false, 0
local CHROMA_SPEED, CHROMA_HZ = 0.35, 30
local CHROMA_INTERVAL = 1 / CHROMA_HZ
local brightness = 1.0

local PRESETS = {
    { name="MAGMA",  base=Color3.fromRGB(255,90,20),  material=Enum.Material.CorrodedMetal, glow=Color3.fromRGB(255,60,0),  glowT=.35, light=Color3.fromRGB(255,90,30),  bright=4, range=14, pulse=true  },
    { name="FIRE",   base=Color3.fromRGB(255,170,50), material=Enum.Material.Neon,          glow=Color3.fromRGB(255,120,20),glowT=.25, light=Color3.fromRGB(255,160,60), bright=5, range=16, pulse=true  },
    { name="ICE",    base=Color3.fromRGB(150,220,255),material=Enum.Material.Glass,         glow=Color3.fromRGB(180,240,255),glowT=.4, light=Color3.fromRGB(150,200,255),bright=3, range=12, pulse=false },
    { name="GALAXY", base=Color3.fromRGB(120,60,220), material=Enum.Material.ForceField,    glow=Color3.fromRGB(160,90,255),glowT=.3, light=Color3.fromRGB(140,80,255), bright=4, range=15, pulse=true  },
    { name="NEON",   base=Color3.fromRGB(0,255,220),  material=Enum.Material.Neon,          glow=Color3.fromRGB(0,255,220), glowT=.15,light=Color3.fromRGB(0,255,220),  bright=6, range=18, pulse=false },
    { name="GOLD",   base=Color3.fromRGB(255,200,60), material=Enum.Material.Foil,          glow=Color3.fromRGB(255,220,120),glowT=.5,light=Color3.fromRGB(255,200,80), bright=2, range=10, pulse=false },
    { name="TOXIC",  base=Color3.fromRGB(120,255,60), material=Enum.Material.Neon,          glow=Color3.fromRGB(140,255,60),glowT=.2, light=Color3.fromRGB(120,255,60), bright=5, range=15, pulse=true  },
    { name="VOID",   base=Color3.fromRGB(40,10,80),   material=Enum.Material.ForceField,    glow=Color3.fromRGB(80,30,140), glowT=.35,light=Color3.fromRGB(80,20,160),  bright=3, range=14, pulse=true  },
}
local activePreset
local effects = {}
local originalTextures, originalColors = {}, {}

--== TARGET FINDERS ============================================
local function findMyGun()
    local c = PLR.Character
    if c then local t = c:FindFirstChild(TARGET_NAME); if t and t:IsA("Tool") then return t end end
    local b = PLR:FindFirstChildOfClass("Backpack")
    if b then local t = b:FindFirstChild(TARGET_NAME); if t and t:IsA("Tool") then return t end end
end
local function findDisplayTarget()
    local c = PLR.Character
    if not c then return nil end
    local ref = c:FindFirstChild(TARGET_REF_NAME)
    if not ref or not ref:IsA("ObjectValue") then return nil end
    return ref.Value
end

local function snapshotOriginals(target)
    if not target then return end
    for _, d in ipairs(target:GetDescendants()) do
        if d:IsA("MeshPart") then
            if not originalTextures[d] then originalTextures[d]=d.TextureID end
            if not originalColors[d] then originalColors[d]=d.Color end
        elseif d:IsA("BasePart") then
            if not originalColors[d] then originalColors[d]=d.Color end
        elseif d:IsA("Texture") then
            if not originalTextures[d] then originalTextures[d]=d.Texture end
            if not originalColors[d] then originalColors[d]=d.Color3 end
        elseif d:IsA("Decal") then
            if not originalTextures[d] then originalTextures[d]=d.Texture end
            if not originalColors[d] then originalColors[d]=d.Color3 end
        end
    end
    if target:IsA("MeshPart") then
        if not originalTextures[target] then originalTextures[target]=target.TextureID end
        if not originalColors[target] then originalColors[target]=target.Color end
    elseif target:IsA("BasePart") then
        if not originalColors[target] then originalColors[target]=target.Color end
    end
end

local function clearEffects(target)
    if not target then return end
    local e = effects[target]
    if e then
        pcall(function() if e.highlight then e.highlight:Destroy() end end)
        pcall(function() if e.light then e.light:Destroy() end end)
        effects[target] = nil
    end
end

local function applyToInstance(inst, color, replace, preset)
    pcall(function()
        if inst:IsA("MeshPart") then
            if preset then inst.Color = preset.base; inst.Material = preset.material; inst.TextureID = ""
            else inst.Color = color; if replace then inst.TextureID = "" end end
        elseif inst:IsA("BasePart") then
            if preset then inst.Color = preset.base; inst.Material = preset.material else inst.Color = color end
        elseif inst:IsA("Texture") then
            if preset then inst.Texture = ""; inst.Color3 = preset.base
            else if replace then inst.Texture = "" end; inst.Color3 = color end
        elseif inst:IsA("Decal") then
            if preset then inst.Texture = ""; inst.Color3 = preset.base
            else if replace then inst.Texture = "" end; inst.Color3 = color end
        elseif inst:IsA("SpecialMesh") then
            local c = preset and preset.base or color
            inst.VertexColor = Vector3.new(c.R, c.G, c.B)
        elseif inst:IsA("SurfaceAppearance") then
            inst.Color = preset and preset.base or color
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail") then
            inst.Color = ColorSequence.new(preset and preset.base or color)
        end
    end)
end

local function installEffect(target, preset)
    if not target or not preset then return end
    local e = effects[target]; if not e then e = {}; effects[target] = e end
    if not e.highlight or not e.highlight.Parent then
        local hl = Instance.new("Highlight")
        hl.Name = "__RavenGlow"; hl.Adornee = target
        hl.OutlineTransparency = 1; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = target; e.highlight = hl
    end
    e.highlight.FillColor = preset.glow
    e.highlight.FillTransparency = preset.glowT
    local handle
    if target:IsA("BasePart") then handle = target
    elseif target:IsA("Model") then
        handle = target:FindFirstChild("Handle") or target:FindFirstChildWhichIsA("BasePart")
    end
    if handle then
        if not e.light or not e.light.Parent then
            local pl = Instance.new("PointLight"); pl.Name = "__RavenLight"; pl.Parent = handle; e.light = pl
        end
        e.light.Color = preset.light; e.light.Brightness = preset.bright
        e.light.Range = preset.range; e.light.Shadows = false
    end
end

local function restoreOriginals()
    for inst, tex in pairs(originalTextures) do
        if inst.Parent then pcall(function()
            if inst:IsA("MeshPart") then inst.TextureID = tex
            elseif inst:IsA("Texture") then inst.Texture = tex
            elseif inst:IsA("Decal") then inst.Texture = tex end end) end
    end
    for inst, col in pairs(originalColors) do
        if inst.Parent then pcall(function()
            if inst:IsA("BasePart") or inst:IsA("MeshPart") then inst.Color = col
            elseif inst:IsA("Texture") or inst:IsA("Decal") then inst.Color3 = col end end) end
    end
end

local function applyBrightness(c)
    return Color3.new(math.clamp(c.R*brightness,0,1), math.clamp(c.G*brightness,0,1), math.clamp(c.B*brightness,0,1))
end
local function activeColor() return applyBrightness(chromaOn and Color3.fromHSV(chromaHue,1,1) or currentColor) end

-- Paint a single target (Tool, BasePart, or Model) — safe against nil
local function paintTarget(target, col, p)
    if not target or not target.Parent then return end
    if target:IsA("BasePart") then
        applyToInstance(target, col, replaceTexture, p)
    end
    for _, d in ipairs(target:GetDescendants()) do
        applyToInstance(d, col, replaceTexture, p)
    end
    if p then installEffect(target, p) else clearEffects(target) end
end

local function applyColor()
    local col = activeColor(); local p = activePreset
    paintTarget(currentTool, col, p)
    paintTarget(currentDisplay, col, p)
end

local function refreshTool()
    -- Held tool
    local t = findMyGun()
    if t ~= currentTool then
        if currentTool then clearEffects(currentTool) end
        currentTool = t
        if t then
            snapshotOriginals(t)
            print("[Raven] Bound held: "..t:GetFullName())
        end
    end
    -- Waist display
    local d = findDisplayTarget()
    if d ~= currentDisplay then
        if currentDisplay then clearEffects(currentDisplay) end
        currentDisplay = d
        if d then
            snapshotOriginals(d)
            print("[Raven] Bound waist: "..d:GetFullName())
        end
    end
end

refreshTool()

-- Respawn handling
PLR.CharacterAdded:Connect(function()
    task.wait(.8)
    refreshTool()
    applyColor()
end)

-- Backpack hooks
local function hookBag(bag)
    bag.ChildAdded:Connect(function(c) if c.Name==TARGET_NAME then task.wait(.2); refreshTool(); applyColor() end end)
    bag.ChildRemoved:Connect(function(c) if c.Name==TARGET_NAME then task.wait(.2); refreshTool(); applyColor() end end)
end
local bag = PLR:FindFirstChildOfClass("Backpack"); if bag then hookBag(bag) end
PLR.ChildAdded:Connect(function(c) if c:IsA("Backpack") then hookBag(c) end end)

-- Character hooks: tool added/removed, and DisplayRefGun appear/change
local function hookChar(c)
    if not c then return end

    local function wireRef(ref)
        if not ref:IsA("ObjectValue") then return end
        ref:GetPropertyChangedSignal("Value"):Connect(function()
            task.wait(.1)
            refreshTool(); applyColor()
        end)
    end
    local existing = c:FindFirstChild(TARGET_REF_NAME)
    if existing then wireRef(existing) end

    c.ChildAdded:Connect(function(ch)
        if ch.Name == TARGET_NAME and ch:IsA("Tool") then
            task.wait(.2); refreshTool(); applyColor()
        elseif ch.Name == TARGET_REF_NAME then
            task.wait(.1); wireRef(ch); refreshTool(); applyColor()
        end
    end)
    c.ChildRemoved:Connect(function(ch)
        if ch.Name == TARGET_NAME and ch:IsA("Tool") then
            task.wait(.2); refreshTool(); applyColor()
        end
    end)
end
if PLR.Character then hookChar(PLR.Character) end
PLR.CharacterAdded:Connect(hookChar)

-- 30Hz loop: paints both targets + pulses preset lights
task.spawn(function()
    local lastClock = os.clock()
    while PGUI and PGUI.Parent do
        task.wait(CHROMA_INTERVAL)
        local now = os.clock(); local dt = now - lastClock; lastClock = now
        if chromaOn and not activePreset then chromaHue = (chromaHue + CHROMA_SPEED*dt) % 1 end
        -- Rescan if either target went stale
        if (not currentTool or not currentTool.Parent) or (not currentDisplay or not currentDisplay.Parent) then
            refreshTool()
        end
        local col = activeColor(); local p = activePreset
        pcall(function()
            paintTarget(currentTool, col, p)
            paintTarget(currentDisplay, col, p)
        end)
        if p and p.pulse then
            for _, e in pairs(effects) do
                if e.light and e.light.Parent then
                    e.light.Brightness = p.bright * (0.85 + 0.15 * math.sin(now * 3))
                end
            end
        end
    end
end)

--== GUI ========================================================
local oldGui = PGUI:FindFirstChild("VoidscopeUI"); if oldGui then oldGui:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "VoidscopeUI"; gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PGUI

local shell, shellScale

--== Mini floating button — CIRCLE ==============================
local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0,48,0,48); mini.Position = UDim2.new(0,20,.5,-24)
mini.BackgroundColor3 = C.BLUE; mini.Text = "🎨"
mini.TextColor3 = Color3.new(1,1,1); mini.TextSize = 24
mini.Font = Enum.Font.GothamBold; mini.BorderSizePixel = 0
mini.AutoButtonColor = false; mini.Visible = false
mini.ZIndex = 100; mini.Active = true; mini.Parent = gui
cr(mini, UDim.new(1,0))
regS(mini, "BackgroundColor3", "BLUE")
local miniStroke = sk(mini, C.BLUE_L, 2, .3)
miniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
regS(miniStroke, "Color", "BLUE_L")
makeTG(mini, {"BLUE_D","BLUE","ACCENT"}, 45)

local miniGlow = Instance.new("ImageLabel")
miniGlow.Size = UDim2.new(1,26,1,26); miniGlow.Position = UDim2.new(0,-13,0,-13)
miniGlow.BackgroundTransparency = 1; miniGlow.Image = "rbxassetid://5028857472"
miniGlow.ImageColor3 = C.BLUE; miniGlow.ImageTransparency = .4
miniGlow.ZIndex = 99; miniGlow.Parent = mini
cr(miniGlow, UDim.new(1,0))
regI(miniGlow, "ImageColor3", "BLUE")

task.spawn(function() while gui.Parent do
    tw(miniGlow,{ImageTransparency=.75},1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut); task.wait(1.5)
    tw(miniGlow,{ImageTransparency=.4},1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut); task.wait(1.5)
end end)

--== Drag helper ===============================================
local function attachDrag(handle, target, tapFn, tapTol)
    tapTol = tapTol or 6
    local dragStart, startPos, dragging, moved
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragStart = i.Position; startPos = target.Position
            dragging = true; moved = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - dragStart
            if math.abs(d.X) > tapTol or math.abs(d.Y) > tapTol then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if dragging and not moved and tapFn then tapFn() end
            dragging = false
        end
    end)
    return function() return dragging end
end

local miniIsDragging = attachDrag(mini, mini, function()
    if shell and shellScale then
        mini.Visible = false; shell.Visible = true; shellScale.Scale = .85
        tw(shellScale,{Scale=1},.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    end
end)
mini.MouseEnter:Connect(function() if not miniIsDragging() then tw(mini,{Size=UDim2.new(0,54,0,54)},.15,Enum.EasingStyle.Back) end end)
mini.MouseLeave:Connect(function() if not miniIsDragging() then tw(mini,{Size=UDim2.new(0,48,0,48)},.15,Enum.EasingStyle.Back) end end)

--== Main shell — SQUARE =======================================
shell = Instance.new("Frame")
shell.AnchorPoint = Vector2.new(.5,.5); shell.Position = UDim2.new(.5,0,.5,0)
shell.Size = UDim2.new(0,420,0,860); shell.BackgroundColor3 = C.BG1
shell.BorderSizePixel = 0; shell.ClipsDescendants = true; shell.Parent = gui
cr(shell, 0)
shellScale = Instance.new("UIScale"); shellScale.Scale = .85; shellScale.Parent = shell
local SHELL_FULL = UDim2.new(0,420,0,860)
local SHELL_MIN  = UDim2.new(0,420,0,60)
local minimized = false

local shellGrad = Instance.new("UIGradient")
shellGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,C.BG1),ColorSequenceKeypoint.new(1,C.BG0)})
shellGrad.Rotation = 90; shellGrad.Parent = shell

local shellStroke = sk(shell, C.BLUE, 1.5, .3)
local strokeGrad = makeTG(shellStroke, {"BLUE","ACCENT","BLUE_L"}, 0)
task.spawn(function() local t=0 while gui.Parent do t=(t+.004)%1; strokeGrad.Rotation=t*360; task.wait(.03) end end)

--== Title bar — SQUARE ========================================
local title = Instance.new("Frame")
title.Size = UDim2.new(1,0,0,60); title.BackgroundColor3 = C.BLUE
title.BorderSizePixel = 0; title.ZIndex = 2; title.Parent = shell
cr(title, 0)
local titleGrad = makeTG(title, {"BLUE_D","BLUE","ACCENT"}, 0)

local titleCover = Instance.new("Frame")
titleCover.Size = UDim2.new(1,0,0,20); titleCover.Position = UDim2.new(0,0,1,-20)
titleCover.BackgroundColor3 = C.BLUE; titleCover.BorderSizePixel = 0
titleCover.ZIndex = 2; titleCover.Parent = title
regS(titleCover, "BackgroundColor3", "BLUE")
local coverGrad = makeTG(titleCover, {"BLUE_D","BLUE","ACCENT"}, 0)

task.spawn(function() local t=0 while gui.Parent do
    t=(t+.006)%1; local off=t*.9-.45
    titleGrad.Offset = Vector2.new(off,0); coverGrad.Offset = Vector2.new(off,0); task.wait(.03)
end end)

local grip = Instance.new("TextLabel")
grip.Size = UDim2.new(0,16,1,0); grip.Position = UDim2.new(0,6,0,0)
grip.BackgroundTransparency = 1; grip.Font = Enum.Font.GothamBold
grip.Text = "⋮⋮"; grip.TextColor3 = Color3.new(1,1,1); grip.TextTransparency = .35
grip.TextSize = 14; grip.ZIndex = 3; grip.Parent = title

local titleIcon = Instance.new("Frame")
titleIcon.Size = UDim2.new(0,10,0,10); titleIcon.Position = UDim2.new(0,26,.5,-5)
titleIcon.BackgroundColor3 = Color3.new(1,1,1); titleIcon.BorderSizePixel = 0
titleIcon.ZIndex = 3; titleIcon.Parent = title
cr(titleIcon, UDim.new(1,0))

local titleText = Instance.new("TextLabel")
titleText.BackgroundTransparency = 1
titleText.Size = UDim2.new(1,-180,0,22); titleText.Position = UDim2.new(0,44,0,10)
titleText.Font = Enum.Font.GothamBold; titleText.Text = "Raven's Voidscope Mod"
titleText.TextColor3 = Color3.new(1,1,1); titleText.TextSize = 17
titleText.TextXAlignment = Enum.TextXAlignment.Left; titleText.ZIndex = 3; titleText.Parent = title

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Size = UDim2.new(1,-180,0,14); subtitle.Position = UDim2.new(0,44,0,32)
subtitle.Font = Enum.Font.Gotham; subtitle.Text = "v8.5  •  held + waist display"
subtitle.TextColor3 = Color3.new(1,1,1); subtitle.TextTransparency = .3
subtitle.TextSize = 11; subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 3; subtitle.Parent = title

local function titleBtn(xOffset, text, size)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,34,0,34)
    b.Position = UDim2.new(1, xOffset, .5, -17)
    b.BackgroundColor3 = Color3.new(1,1,1); b.BackgroundTransparency = .85
    b.Text = text; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold; b.TextSize = size or 16
    b.BorderSizePixel = 0; b.AutoButtonColor = false; b.ZIndex = 4; b.Parent = title
    cr(b, 0)
    return b
end
local minBtn   = titleBtn(-156, "—", 18)
local gearBtn  = titleBtn(-118, "⚙", 18)
local closeBtn = titleBtn(-80,  "✕", 16)

minBtn.MouseEnter:Connect(function() tw(minBtn,{BackgroundTransparency=.05},.15) end)
minBtn.MouseLeave:Connect(function() tw(minBtn,{BackgroundTransparency=.85},.15) end)
gearBtn.MouseEnter:Connect(function() tw(gearBtn,{BackgroundTransparency=.05,Rotation=45},.25,Enum.EasingStyle.Back) end)
gearBtn.MouseLeave:Connect(function() tw(gearBtn,{BackgroundTransparency=.85,Rotation=0},.25,Enum.EasingStyle.Back) end)
closeBtn.MouseEnter:Connect(function() tw(closeBtn,{BackgroundColor3=C.DANGER,BackgroundTransparency=.05,Rotation=90},.2,Enum.EasingStyle.Back) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn,{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.85,Rotation=0},.2,Enum.EasingStyle.Back) end)

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    tw(shell, {Size = minimized and SHELL_MIN or SHELL_FULL}, 0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    minBtn.Text = minimized and "□" or "—"
end)

closeBtn.MouseButton1Click:Connect(function()
    tw(shellScale,{Scale=.85},.18); tw(shell,{BackgroundTransparency=1},.18); task.wait(.18)
    shell.Visible = false; shell.BackgroundTransparency = 0; mini.Visible = true
    tw(mini,{Size=UDim2.new(0,62,0,62)},.25,Enum.EasingStyle.Back); task.wait(.25)
    tw(mini,{Size=UDim2.new(0,48,0,48)},.2,Enum.EasingStyle.Back)
end)

attachDrag(title, shell, function()
    minimized = not minimized
    tw(shell, {Size = minimized and SHELL_MIN or SHELL_FULL}, 0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    minBtn.Text = minimized and "□" or "—"
end, 8)

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-60); content.Position = UDim2.new(0,0,0,60)
content.BackgroundTransparency = 1; content.Parent = shell

--== SETTINGS PANEL ============================================
local settingsPanel = Instance.new("Frame")
settingsPanel.Size = UDim2.new(1,0,1,0); settingsPanel.Position = UDim2.new(1,0,0,0)
settingsPanel.BackgroundColor3 = C.BG1; settingsPanel.BorderSizePixel = 0
settingsPanel.ZIndex = 60; settingsPanel.Visible = false; settingsPanel.Parent = shell
local spG = Instance.new("UIGradient")
spG.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,C.BG1),ColorSequenceKeypoint.new(1,C.BG0)})
spG.Rotation = 90; spG.Parent = settingsPanel

local spH = Instance.new("Frame")
spH.Size = UDim2.new(1,0,0,60); spH.BackgroundColor3 = C.BLUE
spH.BorderSizePixel = 0; spH.ZIndex = 61; spH.Parent = settingsPanel
cr(spH, 0)
makeTG(spH, {"BLUE_D","BLUE","ACCENT"}, 0)
local spHC = Instance.new("Frame")
spHC.Size = UDim2.new(1,0,0,20); spHC.Position = UDim2.new(0,0,1,-20)
spHC.BackgroundColor3 = C.BLUE; spHC.BorderSizePixel = 0
spHC.ZIndex = 61; spHC.Parent = spH
regS(spHC, "BackgroundColor3", "BLUE")
makeTG(spHC, {"BLUE_D","BLUE","ACCENT"}, 0)

local spBack = Instance.new("TextButton")
spBack.Size = UDim2.new(0,34,0,34); spBack.Position = UDim2.new(0,16,.5,-17)
spBack.BackgroundColor3 = Color3.new(1,1,1); spBack.BackgroundTransparency = .85
spBack.Text = "←"; spBack.TextColor3 = Color3.new(1,1,1)
spBack.Font = Enum.Font.GothamBold; spBack.TextSize = 18
spBack.BorderSizePixel = 0; spBack.AutoButtonColor = false
spBack.ZIndex = 62; spBack.Parent = spH
cr(spBack, 0)
spBack.MouseEnter:Connect(function() tw(spBack,{BackgroundTransparency=.05},.15) end)
spBack.MouseLeave:Connect(function() tw(spBack,{BackgroundTransparency=.85},.15) end)

local spT = Instance.new("TextLabel")
spT.BackgroundTransparency = 1
spT.Size = UDim2.new(1,-60,1,0); spT.Position = UDim2.new(0,60,0,0)
spT.Font = Enum.Font.GothamBold; spT.Text = "SETTINGS"
spT.TextColor3 = Color3.new(1,1,1); spT.TextSize = 18
spT.TextXAlignment = Enum.TextXAlignment.Left; spT.ZIndex = 62; spT.Parent = spH

local spC = Instance.new("Frame")
spC.Size = UDim2.new(1,0,1,-60); spC.Position = UDim2.new(0,0,0,60)
spC.BackgroundTransparency = 1; spC.ZIndex = 61; spC.Parent = settingsPanel

local spL1 = Instance.new("TextLabel")
spL1.Size = UDim2.new(1,-40,0,18); spL1.Position = UDim2.new(0,20,0,20)
spL1.BackgroundTransparency = 1; spL1.Font = Enum.Font.GothamBold
spL1.Text = "UI THEME COLOR"; spL1.TextColor3 = C.BLUE_L; spL1.TextSize = 11
spL1.TextXAlignment = Enum.TextXAlignment.Left; spL1.ZIndex = 62; spL1.Parent = spC
regS(spL1, "TextColor3", "BLUE_L")

local TH_R, TH_TH = 140, 22
local thO, thI = TH_R/2, TH_R/2 - TH_TH
local thM = (thO + thI)/2
local thSegs = 72
local themeRing = Instance.new("Frame")
themeRing.Size = UDim2.new(0,TH_R,0,TH_R); themeRing.Position = UDim2.new(.5,-TH_R/2,0,50)
themeRing.BackgroundTransparency = 1; themeRing.ZIndex = 62; themeRing.Parent = spC
for i=0,thSegs-1 do
    local a=(i/thSegs)*math.pi*2; local h=i/thSegs
    local c=Color3.fromHSV(h,1,1)
    local len=(2*math.pi*thM)/thSegs+3
    local sg=Instance.new("Frame")
    sg.AnchorPoint=Vector2.new(.5,.5); sg.Size=UDim2.new(0,TH_TH+2,0,len)
    sg.Position=UDim2.new(.5,math.cos(a)*thM,.5,math.sin(a)*thM)
    sg.Rotation=math.deg(a); sg.BackgroundColor3=c; sg.BorderSizePixel=0
    sg.ZIndex=62; sg.Parent=themeRing
end
local themeCenter = Instance.new("Frame")
themeCenter.Size = UDim2.new(0,thI*2,0,thI*2)
themeCenter.AnchorPoint=Vector2.new(.5,.5); themeCenter.Position=UDim2.new(.5,0,.5,0)
themeCenter.BackgroundColor3 = C.BLUE; themeCenter.BorderSizePixel = 0
themeCenter.ZIndex = 63; themeCenter.Parent = themeRing
cr(themeCenter, UDim.new(1,0))
regS(themeCenter, "BackgroundColor3", "BLUE")
local themeSel = Instance.new("Frame")
themeSel.Size = UDim2.new(0,16,0,16); themeSel.AnchorPoint=Vector2.new(.5,.5)
themeSel.BackgroundColor3 = C.BLUE; themeSel.BorderSizePixel = 0
themeSel.ZIndex = 64; themeSel.Parent = themeRing
cr(themeSel, UDim.new(1,0))
sk(themeSel, Color3.new(1,1,1), 2, 0)
regS(themeSel, "BackgroundColor3", "BLUE")
local themeClick = Instance.new("TextButton")
themeClick.Size = UDim2.new(1,0,1,0); themeClick.BackgroundTransparency = 1
themeClick.Text = ""; themeClick.ZIndex = 65; themeClick.Parent = themeRing
do
    local dragging = false
    local function process(pos)
        local ap = themeRing.AbsolutePosition; local sz = themeRing.AbsoluteSize.X
        local cx, cy = ap.X+sz/2, ap.Y+sz/2
        local a = math.atan2(pos.Y-cy, pos.X-cx)
        themeSel.Position = UDim2.new(.5, math.cos(a)*thM, .5, math.sin(a)*thM)
        setThemeHue((a/(math.pi*2))%1)
    end
    local function begin(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging = true; process(i.Position)
        end
    end
    themeClick.InputBegan:Connect(begin); themeSel.InputBegan:Connect(begin)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then process(i.Position) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging = false end
    end)
end

local spL2 = Instance.new("TextLabel")
spL2.Size = UDim2.new(1,-40,0,18); spL2.Position = UDim2.new(0,20,0,210)
spL2.BackgroundTransparency = 1; spL2.Font = Enum.Font.GothamBold
spL2.Text = "QUICK PRESETS"; spL2.TextColor3 = C.BLUE_L
spL2.TextSize = 11; spL2.TextXAlignment = Enum.TextXAlignment.Left
spL2.ZIndex = 62; spL2.Parent = spC
regS(spL2, "TextColor3", "BLUE_L")

local QUICK = {
    {.638, "DeepSeek", Color3.fromRGB(77,107,254)},
    {.75,  "Purple",   Color3.fromRGB(150,100,255)},
    {0,    "Red",      Color3.fromRGB(255,80,90)},
    {.08,  "Orange",   Color3.fromRGB(255,140,60)},
    {.14,  "Yellow",   Color3.fromRGB(255,215,80)},
    {.35,  "Green",    Color3.fromRGB(90,230,120)},
    {.50,  "Cyan",     Color3.fromRGB(80,220,255)},
    {.88,  "Pink",     Color3.fromRGB(255,120,200)},
}
for i, q in ipairs(QUICK) do
    local idx = i - 1
    local row = math.floor(idx/4); local col = idx % 4
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,88,0,40)
    btn.Position = UDim2.new(0, 20+col*(88+8), 0, 238+row*(40+6))
    btn.BackgroundColor3 = C.BG2; btn.Text = q[2]
    btn.TextColor3 = C.TEXT; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10; btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.ZIndex = 62; btn.Parent = spC
    cr(btn, 0)
    local s = sk(btn, C.BORDER, 1, .4)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,10,0,10); dot.Position = UDim2.new(0,6,.5,-5)
    dot.BackgroundColor3 = q[3]; dot.BorderSizePixel = 0; dot.ZIndex = 63
    dot.Parent = btn; cr(dot, UDim.new(1,0))
    btn.MouseButton1Click:Connect(function()
        setThemeHue(q[1])
        themeSel.Position = UDim2.new(.5, math.cos(q[1]*math.pi*2)*thM, .5, math.sin(q[1]*math.pi*2)*thM)
        themeCenter.BackgroundColor3 = C.BLUE; themeSel.BackgroundColor3 = C.BLUE
    end)
    btn.MouseEnter:Connect(function() tw(s,{Transparency=.1},.15) end)
    btn.MouseLeave:Connect(function() tw(s,{Transparency=.4},.15) end)
end

gearBtn.MouseButton1Click:Connect(function()
    settingsPanel.Visible = true; settingsPanel.Position = UDim2.new(1,0,0,0)
    tw(settingsPanel,{Position=UDim2.new(0,0,0,0)},.28,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
end)
spBack.MouseButton1Click:Connect(function()
    tw(settingsPanel,{Position=UDim2.new(1,0,0,0)},.25,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
end)

--== Color Wheel ===============================================
local WHEEL, RING, SEG, SV_SIZE = 260, 26, 90, 140
local oR = WHEEL/2; local iR = oR - RING; local mR = (oR+iR)/2
local wheelWrap = Instance.new("Frame")
wheelWrap.Size = UDim2.new(0,WHEEL,0,WHEEL)
wheelWrap.Position = UDim2.new(.5,-WHEEL/2,0,20)
wheelWrap.BackgroundTransparency = 1; wheelWrap.Parent = content
for i=0,SEG-1 do
    local a=(i/SEG)*math.pi*2; local h=i/SEG
    local c=Color3.fromHSV(h,1,1)
    local arcLen=(2*math.pi*mR)/SEG+3
    local sg=Instance.new("Frame")
    sg.AnchorPoint=Vector2.new(.5,.5); sg.Size=UDim2.new(0,RING+2,0,arcLen)
    sg.Position=UDim2.new(.5, math.cos(a)*mR, .5, math.sin(a)*mR)
    sg.Rotation=math.deg(a); sg.BackgroundColor3=c; sg.BorderSizePixel=0
    sg.Parent=wheelWrap
end
local svWrap = Instance.new("Frame")
svWrap.Size=UDim2.new(0,SV_SIZE,0,SV_SIZE)
svWrap.AnchorPoint=Vector2.new(.5,.5); svWrap.Position=UDim2.new(.5,0,.5,0)
svWrap.BackgroundColor3=Color3.fromRGB(255,0,0); svWrap.BorderSizePixel=0
svWrap.ZIndex=2; svWrap.Parent=wheelWrap
local svW = Instance.new("Frame")
svW.Size=UDim2.new(1,0,1,0); svW.BackgroundColor3=Color3.new(1,1,1)
svW.BorderSizePixel=0; svW.ZIndex=3; svW.Parent=svWrap
local svWG = Instance.new("UIGradient")
svWG.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
svWG.Parent=svW
local svB = Instance.new("Frame")
svB.Size=UDim2.new(1,0,1,0); svB.BackgroundColor3=Color3.new(0,0,0)
svB.BorderSizePixel=0; svB.ZIndex=4; svB.Parent=svWrap
local svBG = Instance.new("UIGradient"); svBG.Rotation=90
svBG.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
svBG.Parent=svB
sk(svWrap, C.BORDER, 1, .2)
local hueSel = Instance.new("Frame")
hueSel.Size=UDim2.new(0,16,0,16); hueSel.AnchorPoint=Vector2.new(.5,.5)
hueSel.BackgroundColor3=Color3.fromRGB(255,0,0); hueSel.BorderSizePixel=0
hueSel.ZIndex=10; hueSel.Parent=wheelWrap
cr(hueSel, UDim.new(1,0)); sk(hueSel, Color3.new(1,1,1), 2, 0)
local svSel = Instance.new("Frame")
svSel.Size=UDim2.new(0,14,0,14); svSel.AnchorPoint=Vector2.new(.5,.5)
svSel.BackgroundColor3=Color3.new(1,1,1); svSel.BorderSizePixel=0
svSel.ZIndex=10; svSel.Parent=svWrap
cr(svSel, UDim.new(1,0)); sk(svSel, Color3.new(1,1,1), 2, 0)
local hueArea = Instance.new("TextButton")
hueArea.Size=UDim2.new(1,0,1,0); hueArea.BackgroundTransparency=1
hueArea.Text=""; hueArea.ZIndex=20; hueArea.Parent=wheelWrap
local svArea = Instance.new("TextButton")
svArea.Size=UDim2.new(1,0,1,0); svArea.BackgroundTransparency=1
svArea.Text=""; svArea.ZIndex=21; svArea.Parent=svWrap

--== Hex row ==================================================
local hexRow = Instance.new("Frame")
hexRow.Size=UDim2.new(1,-40,0,44); hexRow.Position=UDim2.new(0,20,0,300)
hexRow.BackgroundColor3=C.BG2; hexRow.BorderSizePixel=0; hexRow.Parent=content
cr(hexRow, 0); sk(hexRow, C.BORDER, 1, .3)
local hexHash = Instance.new("TextLabel")
hexHash.Size=UDim2.new(0,24,1,0); hexHash.Position=UDim2.new(0,10,0,0)
hexHash.BackgroundTransparency=1; hexHash.Font=Enum.Font.GothamBold
hexHash.Text="#"; hexHash.TextColor3=C.BLUE_L; hexHash.TextSize=16
hexHash.Parent=hexRow
regS(hexHash, "TextColor3", "BLUE_L")
local hexBox = Instance.new("TextBox")
hexBox.Size=UDim2.new(1,-100,1,0); hexBox.Position=UDim2.new(0,32,0,0)
hexBox.BackgroundTransparency=1; hexBox.Font=Enum.Font.Code
hexBox.Text="4D6BFE"; hexBox.TextColor3=C.TEXT
hexBox.PlaceholderText="RRGGBB"; hexBox.PlaceholderColor3=C.DIM
hexBox.TextSize=15; hexBox.TextXAlignment=Enum.TextXAlignment.Left
hexBox.ClearTextOnFocus=false; hexBox.Parent=hexRow
local preview = Instance.new("Frame")
preview.Size=UDim2.new(0,30,0,30); preview.Position=UDim2.new(1,-40,.5,-15)
preview.BackgroundColor3=C.BLUE; preview.BorderSizePixel=0
preview.ZIndex=3; preview.Parent=hexRow
cr(preview, 0); sk(preview, Color3.new(1,1,1), 1.5, .55)

--== Sliders ==================================================
local sliders = {}
local function makeSlider(ch, color, y)
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,-40,0,34); wrap.Position=UDim2.new(0,20,0,y)
    wrap.BackgroundTransparency=1; wrap.Parent=content
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0,20,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.Text=ch
    lbl.TextColor3=color; lbl.TextSize=15
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=wrap
    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,-80,0,8); track.Position=UDim2.new(0,30,.5,-4)
    track.BackgroundColor3=C.BG2; track.BorderSizePixel=0; track.Parent=wrap
    cr(track, UDim.new(1,0))
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(1,0,1,0); fill.BackgroundColor3=color
    fill.BorderSizePixel=0; fill.Parent=track; cr(fill, UDim.new(1,0))
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(1,-8,.5,-8)
    knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0
    knob.ZIndex=3; knob.Parent=track; cr(knob, UDim.new(1,0)); sk(knob, color, 2, 0)
    local val=Instance.new("TextLabel")
    val.Size=UDim2.new(0,44,1,0); val.Position=UDim2.new(1,-44,0,0)
    val.BackgroundTransparency=1; val.Font=Enum.Font.Code
    val.Text="255"; val.TextColor3=C.TEXT; val.TextSize=13
    val.TextXAlignment=Enum.TextXAlignment.Right; val.Parent=wrap
    sliders[ch]={track=track,fill=fill,knob=knob,val=val,value=255,color=color}
end
makeSlider("R", Color3.fromRGB(255,90,110), 354)
makeSlider("G", Color3.fromRGB(90,230,130), 388)
makeSlider("B", Color3.fromRGB(100,140,255), 422)

local brightS
do
    local wrap=Instance.new("Frame")
    wrap.Size=UDim2.new(1,-40,0,34); wrap.Position=UDim2.new(0,20,0,456)
    wrap.BackgroundTransparency=1; wrap.Parent=content
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0,80,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.Text="BRIGHT"
    lbl.TextColor3=Color3.fromRGB(255,220,120); lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=wrap
    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,-130,0,8); track.Position=UDim2.new(0,80,.5,-4)
    track.BackgroundColor3=C.BG2; track.BorderSizePixel=0; track.Parent=wrap
    cr(track, UDim.new(1,0))
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new(.5,0,1,0); fill.BackgroundColor3=Color3.fromRGB(255,220,120)
    fill.BorderSizePixel=0; fill.Parent=track; cr(fill, UDim.new(1,0))
    local fg=Instance.new("UIGradient")
    fg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(60,60,80)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,240,180))})
    fg.Parent=fill
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,16,0,16); knob.Position=UDim2.new(.5,-8,.5,-8)
    knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0
    knob.ZIndex=3; knob.Parent=track; cr(knob, UDim.new(1,0))
    sk(knob, Color3.fromRGB(255,220,120), 2, 0)
    local val=Instance.new("TextLabel")
    val.Size=UDim2.new(0,50,1,0); val.Position=UDim2.new(1,-50,0,0)
    val.BackgroundTransparency=1; val.Font=Enum.Font.Code
    val.Text="100%"; val.TextColor3=C.TEXT; val.TextSize=13
    val.TextXAlignment=Enum.TextXAlignment.Right; val.Parent=wrap
    brightS={track=track,fill=fill,knob=knob,val=val}
end

--== Toggles ==================================================
local function toggleRow(label, y, defOn, themeKey)
    local r=Instance.new("Frame")
    r.Size=UDim2.new(1,-40,0,36); r.Position=UDim2.new(0,20,0,y)
    r.BackgroundColor3=C.BG2; r.BorderSizePixel=0; r.Parent=content
    cr(r, 0); sk(r, C.BORDER, 1, .4)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-70,1,0); l.Position=UDim2.new(0,14,0,0)
    l.BackgroundTransparency=1; l.Font=Enum.Font.GothamBold
    l.Text=label; l.TextColor3=C.TEXT; l.TextSize=12
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=r
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,44,0,22); b.Position=UDim2.new(1,-54,.5,-11)
    b.BackgroundColor3 = defOn and C[themeKey] or C.BG3
    b.BorderSizePixel=0; b.Text = defOn and "ON" or "OFF"
    b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold
    b.TextSize=11; b.AutoButtonColor=false; b.Parent=r
    cr(b, 0)
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,b.BackgroundColor3:Lerp(Color3.new(1,1,1),.12)),
        ColorSequenceKeypoint.new(1,b.BackgroundColor3:Lerp(Color3.new(0,0,0),.22))})
    g.Rotation=90; g.Parent=b
    regBG(g, themeKey)
    return b, g
end
local texBtn = toggleRow("Replace texture (solid color)", 498, true, "BLUE")
local chrBtn, chrG = toggleRow("Chroma (rainbow cycle)", 538, false, "BLUE")

local chromaAnimRunning = false
local function startChromaAnim()
    if chromaAnimRunning then return end
    chromaAnimRunning = true
    task.spawn(function()
        local t = 0
        while chromaAnimRunning and gui.Parent do
            t = (t + 0.01) % 1
            chrG.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(t, .85, .9)),
                ColorSequenceKeypoint.new(.5, Color3.fromHSV((t+.33)%1, .85, .9)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV((t+.66)%1, .85, .9)),
            })
            task.wait(.03)
        end
    end)
end
local function stopChromaAnim()
    chromaAnimRunning = false
    local base = C.BG3
    chrG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, base:Lerp(Color3.new(1,1,1),.12)),
        ColorSequenceKeypoint.new(1, base:Lerp(Color3.new(0,0,0),.22)),
    })
end
texBtn.MouseButton1Click:Connect(function()
    replaceTexture = not replaceTexture
    texBtn.Text = replaceTexture and "ON" or "OFF"
    tw(texBtn, {BackgroundColor3 = replaceTexture and C.BLUE or C.BG3}, .15)
    if not replaceTexture then
        for inst, tex in pairs(originalTextures) do
            if inst.Parent then pcall(function()
                if inst:IsA("MeshPart") then inst.TextureID = tex
                elseif inst:IsA("Texture") then inst.Texture = tex
                elseif inst:IsA("Decal") then inst.Texture = tex end end) end
        end
    end
    applyColor()
end)
chrBtn.MouseButton1Click:Connect(function()
    chromaOn = not chromaOn
    if chromaOn then
        chromaHue = select(1, currentColor:ToHSV())
        chrBtn.Text = "ON"; tw(chrBtn, {BackgroundColor3 = C.BLUE}, .15); startChromaAnim()
    else
        chrBtn.Text = "OFF"; tw(chrBtn, {BackgroundColor3 = C.BG3}, .15); stopChromaAnim(); applyColor()
    end
end)

--== Presets ==================================================
local presetLabel = Instance.new("TextLabel")
presetLabel.Size = UDim2.new(1,-40,0,18); presetLabel.Position = UDim2.new(0,20,0,582)
presetLabel.BackgroundTransparency = 1; presetLabel.Font = Enum.Font.GothamBold
presetLabel.Text = "MATERIAL EFFECTS"; presetLabel.TextColor3 = C.BLUE_L
presetLabel.TextSize = 11; presetLabel.TextXAlignment = Enum.TextXAlignment.Left
presetLabel.Parent = content
regS(presetLabel, "TextColor3", "BLUE_L")

local presetBtns = {}
local function makePresetButton(preset, x, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,88,0,34); btn.Position = UDim2.new(0,x,0,y)
    btn.BackgroundColor3 = C.BG2; btn.Text = preset.name
    btn.TextColor3 = C.TEXT; btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10; btn.BorderSizePixel = 0; btn.AutoButtonColor = false
    btn.Parent = content; cr(btn, 0)
    local s = sk(btn, C.BORDER, 1, .4)
    local st = Instance.new("Frame")
    st.Size = UDim2.new(0,3,1,-8); st.Position = UDim2.new(0,4,0,4)
    st.BackgroundColor3 = preset.base; st.BorderSizePixel = 0; st.Parent = btn
    cr(st, 0)
    btn.MouseEnter:Connect(function() tw(s, {Transparency = .1}, .15) end)
    btn.MouseLeave:Connect(function() if activePreset ~= preset then tw(s, {Transparency = .4}, .15) end end)
    btn.MouseButton1Click:Connect(function()
        for _, pb in ipairs(presetBtns) do
            tw(pb.btn, {BackgroundColor3 = C.BG2}, .15); pb.stroke.Transparency = .4
        end
        if activePreset == preset then
            activePreset = nil
            clearEffects(currentTool); clearEffects(currentDisplay)
            for inst, tex in pairs(originalTextures) do
                if inst.Parent then pcall(function()
                    if inst:IsA("MeshPart") then inst.TextureID = tex
                    elseif inst:IsA("Texture") then inst.Texture = tex
                    elseif inst:IsA("Decal") then inst.Texture = tex end end) end
            end
        else
            activePreset = preset
            tw(btn, {BackgroundColor3 = C.BLUE_D}, .15); s.Transparency = 0
        end
        applyColor()
    end)
    table.insert(presetBtns, {btn=btn, stroke=s, preset=preset})
end
for i, p in ipairs(PRESETS) do
    local idx = i - 1
    local row = math.floor(idx/4); local col = idx % 4
    makePresetButton(p, 20+col*(88+8), 604+row*(34+8))
end

--== setColor =================================================
local updating = false
local function setColor(color, silent)
    if updating then return end
    updating = true
    currentColor = color
    local h,s,v = color:ToHSV()
    svWrap.BackgroundColor3 = Color3.fromHSV(h,1,1)
    local ha = h*math.pi*2
    hueSel.Position = UDim2.new(.5, math.cos(ha)*mR, .5, math.sin(ha)*mR)
    hueSel.BackgroundColor3 = Color3.fromHSV(h,1,1)
    svSel.Position = UDim2.new(s,0,1-v,0)
    preview.BackgroundColor3 = color
    hexBox.Text = hx(color)
    local r=math.floor(color.R*255+.5); local g=math.floor(color.G*255+.5); local b=math.floor(color.B*255+.5)
    for ch, sld in pairs(sliders) do
        local vv = (ch=="R" and r) or (ch=="G" and g) or b
        sld.value = vv
        sld.knob.Position = UDim2.new(vv/255,-8,.5,-8)
        sld.fill.Size = UDim2.new(vv/255,0,1,0)
        sld.val.Text = tostring(vv)
    end
    updating = false
    if not silent then applyColor() end
end

--== Wheel drag ===============================================
do
    local dh, ds = false, false
    local function pHue(pos)
        local ap=wheelWrap.AbsolutePosition; local sz=wheelWrap.AbsoluteSize.X
        local cx=ap.X+sz/2; local cy=ap.Y+sz/2
        local a=math.atan2(pos.Y-cy, pos.X-cx); local h=(a/(math.pi*2))%1
        local _,s,v=currentColor:ToHSV()
        setColor(Color3.fromHSV(h,s,v))
        if chromaOn then chromaHue = h end
    end
    local function pSV(pos)
        local ap=svWrap.AbsolutePosition; local sz=svWrap.AbsoluteSize.X
        local x=math.clamp((pos.X-ap.X)/sz,0,1); local y=math.clamp((pos.Y-ap.Y)/sz,0,1)
        local h=select(1,currentColor:ToHSV())
        setColor(Color3.fromHSV(h,x,1-y))
    end
    local function beginH(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dh=true; pHue(i.Position)
        end
    end
    local function beginS(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            ds=true; pSV(i.Position)
        end
    end
    hueArea.InputBegan:Connect(beginH); hueSel.InputBegan:Connect(beginH)
    svArea.InputBegan:Connect(beginS); svSel.InputBegan:Connect(beginS)
    UIS.InputChanged:Connect(function(i)
        if dh and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then pHue(i.Position) end
        if ds and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then pSV(i.Position) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dh=false; ds=false end
    end)
end

--== Slider drags =============================================
do
    local draggingSlider
    for ch, sld in pairs(sliders) do
        local function upd(pos)
            if updating then return end
            local ap=sld.track.AbsolutePosition; local sz=sld.track.AbsoluteSize.X
            local rel=math.clamp((pos.X-ap.X)/sz,0,1); local vv=math.floor(rel*255+.5)
            local r=math.floor(currentColor.R*255+.5); local g=math.floor(currentColor.G*255+.5); local b=math.floor(currentColor.B*255+.5)
            if ch=="R" then r=vv end; if ch=="G" then g=vv end; if ch=="B" then b=vv end
            setColor(Color3.fromRGB(r,g,b))
        end
        sld.track.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                draggingSlider=ch; upd(i.Position)
            end
        end)
        sld.knob.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                draggingSlider=ch; upd(i.Position)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if draggingSlider==ch and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                upd(i.Position)
            end
        end)
        UIS.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                if draggingSlider==ch then draggingSlider=nil end
            end
        end)
    end
end

do
    local draggingB
    local function updB(pos)
        local ap=brightS.track.AbsolutePosition; local sz=brightS.track.AbsoluteSize.X
        local rel=math.clamp((pos.X-ap.X)/sz,0,1)
        brightness = .2 + rel*1.8
        brightS.knob.Position = UDim2.new(rel,-8,.5,-8)
        brightS.fill.Size = UDim2.new(rel,0,1,0)
        brightS.val.Text = string.format("%d%%", math.floor(brightness*100+.5))
        applyColor()
    end
    brightS.track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingB=true; updB(i.Position)
        end
    end)
    brightS.knob.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingB=true; updB(i.Position)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if draggingB and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            updB(i.Position)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then draggingB=false end
    end)
end

hexBox.FocusLost:Connect(function()
    local c = px(hexBox.Text)
    if c then setColor(Color3.new(c[1],c[2],c[3])) else hexBox.Text = hx(currentColor) end
end)

--== Bottom buttons ===========================================
local function makeButton(text, x, w, themeKey)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,w,0,42); btn.Position=UDim2.new(0,x,1,-58)
    btn.BackgroundColor3=C[themeKey]; btn.Text=text
    btn.TextColor3=Color3.new(1,1,1); btn.Font=Enum.Font.GothamBold
    btn.TextSize=13; btn.BorderSizePixel=0; btn.AutoButtonColor=false
    btn.Parent=content; cr(btn, 0)
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,C[themeKey]:Lerp(Color3.new(1,1,1),.12)),
        ColorSequenceKeypoint.new(1,C[themeKey]:Lerp(Color3.new(0,0,0),.22))})
    g.Rotation=90; g.Parent=btn
    if themeKey=="BLUE" then regBG(g, "BLUE") end
    regS(btn, "BackgroundColor3", themeKey)
    local s=sk(btn, C[themeKey]:Lerp(Color3.new(1,1,1),.4), 1, .5)
    if themeKey=="BLUE" then regS(s, "Color", "BLUE") end
    btn.MouseEnter:Connect(function()
        tw(btn,{Size=UDim2.new(0,w+4,0,44),Position=UDim2.new(0,x-2,1,-59)},.18,Enum.EasingStyle.Back)
        tw(s,{Transparency=.15},.18) end)
    btn.MouseLeave:Connect(function()
        tw(btn,{Size=UDim2.new(0,w,0,42),Position=UDim2.new(0,x,1,-58)},.18,Enum.EasingStyle.Back)
        tw(s,{Transparency=.5},.18) end)
    return btn
end

local rescanBtn  = makeButton("RESCAN",  30,  110, "BLUE")
local restoreBtn = makeButton("RESTORE", 155, 110, "BG3")
local resetBtn   = makeButton("WHITE",   280, 110, "BG3")

rescanBtn.MouseButton1Click:Connect(function()
    refreshTool(); applyColor()
    local found = currentTool or currentDisplay
    rescanBtn.Text = found and "✓ FOUND" or "✗ MISSING"
    task.wait(.7); rescanBtn.Text = "RESCAN"
end)

restoreBtn.MouseButton1Click:Connect(function()
    if chromaOn then
        chromaOn=false; chrBtn.Text="OFF"
        tw(chrBtn,{BackgroundColor3=C.BG3},.15); stopChromaAnim()
    end
    activePreset = nil
    for _, pb in ipairs(presetBtns) do
        pb.btn.BackgroundColor3 = C.BG2; pb.stroke.Transparency = .4
    end
    clearEffects(currentTool); clearEffects(currentDisplay)
    restoreOriginals()
    restoreBtn.Text = "✓ RESTORED"; task.wait(.7); restoreBtn.Text = "RESTORE"
end)

resetBtn.MouseButton1Click:Connect(function() setColor(Color3.fromRGB(255,255,255)) end)

--== Init =====================================================
setColor(Color3.fromRGB(77,107,254))
tw(shellScale,{Scale=1},.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

print(("[Raven's Voidscope Mod v8.5] %s (%d) — held: %s | waist: %s")
    :format(PLR.Name, PLR.UserId,
        currentTool and currentTool:GetFullName() or "none",
        currentDisplay and currentDisplay:GetFullName() or "none"))

end, function(msg)
    warn("[Raven's Voidscope Mod v8.5] Crashed: "..tostring(msg))
    print(debug.traceback())
end)