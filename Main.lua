-- ====================================================================
--   🐻 BEAR HUB v1.0 [OFFICIAL INTEGRATED EDITION + AUTO LETTER v5.4]
--   Author / Ownership: Bear Hub
--   Tampering or removing watermarks will terminate script execution.
-- ====================================================================

local __BRAND__ = "BEAR HUB"
local __SIG__ = 0xBEA8

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local plr = Players.LocalPlayer

-- Shared fishing state
local castSerial = 0
local currentBiteToken = nil
local lastAction = nil
local rng = Random.new()

local function getAliveCharacter()
    local c = plr.Character
    if not c or not c.Parent then return nil, nil, nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    local root = c:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return nil, nil, nil end
    return c, hum, root
end

-- Network Remotes Reference
local Events = ReplicatedStorage:WaitForChild("Events")
local fishingRemote = Events:WaitForChild("Activities"):WaitForChild("Fishing")
local foodRemote = Events:WaitForChild("Player"):WaitForChild("Food")
local sicknessRemote = Events:WaitForChild("Player"):WaitForChild("Sickness")
local remedyRemote = Events:WaitForChild("Activities"):WaitForChild("Remedy")
local teaRemote = Events:WaitForChild("Activities"):WaitForChild("Tea")
local shopRemote = Events:WaitForChild("Economy"):WaitForChild("Shop")
local paycheckRemote = Events:WaitForChild("Economy"):WaitForChild("Paycheck")
local allowanceRemote = Events:WaitForChild("Economy"):WaitForChild("Allowance")

-- Combat Remote Reference
local combatFolder = Events:FindFirstChild("Combat") or Events:FindFirstChild("Sword") or Events:FindFirstChild("Activities")
local parryRemote = combatFolder and (combatFolder:FindFirstChild("Parry") or combatFolder:FindFirstChild("Block") or combatFolder:FindFirstChild("Defend"))

-- Configuration
local CONFIG = {
    ToggleKey = Enum.KeyCode.RightShift,

    FishingSpotCF = CFrame.new(2084.19, 167.49, -176.79),
    SpotMaxDist = 16,
    CastRetryDelay = 0.5,
    CastTimeout = 18,
    MinReactionDelay = 0.20,
    MaxReactionDelay = 0.38,
    FishSellThreshold = 8,
    DefaultWalkSpeed = 16,
    CustomWalkSpeed = 34,
    TPOffsetY = 0.5,

    -- [ Merchant Settings ]
    YakukoNPC = "Yakuko",
    SickMedicine = "Senjigusuri",
    HealMedicine = "Kaifukuto",
    FoodMerchant = "Genzo",
    FoodItem = "Bread",

    EmergencyHealthThreshold = 40,
    EmergencyHungerThreshold = 25,
    FoodCooldown = 60,
    ConsumeAttempts = 5,
    ConsumeHoldTime = 0.35,

    -- [ Auto Parry Settings ]
    ParryRange = 18,
    ParryReactionDelay = 0,
    ParryHoldDuration = 0.5,
    ParryRepressGap = 0.3,
    ParryAnyAction = true,

    -- [ Auto Farm Bandits ]
    FarmDistance = 4,
    FarmYOffset = 0,
    FarmMode = 2,
    FarmAboveHeight = 6,
    FarmSide = 1,
    FarmLeash = 12,
    FarmEmergencyHealth = 65,
    FarmClickInterval = 0.12,
    FarmTargetTimeout = 30,
    WeaponKeywords = { "katana", "sword", "blade", "tachi", "wakizashi", "nodachi", "saber" },

    -- [ Auto Letter Settings v5.4 ]
    LetterInitialOpenDelay = 1.0,
    LetterBetweenClaimsDelay = 0.55,
    LetterRulingUnlockDelay = 0.75,
    LetterPollInterval = 0.30,
    LetterReferKeywords = {
        "tax", "taxes", "tax rate", "shogun", "samurai", 
        "prisoner", "prison", "jail", "release", "punish"
    }
}

-- Settings Config
local SETTINGS = {
    { key = "FarmDistance",             label = "Farm Distance",      min = 1.5,  max = 15,  step = 0.5,  dec = 1 },
    { key = "FarmMode",                 label = "Mode (1=หลัง,2=บนหัว)", min = 1, max = 2,  step = 1,    dec = 0 },
    { key = "FarmAboveHeight",          label = "Above Height",       min = 2,    max = 20,  step = 0.5,  dec = 1 },
    { key = "FarmSide",                 label = "Side (1=หลัง,-1=หน้า)", min = -1, max = 1, step = 2,    dec = 0 },
    { key = "FarmLeash",                label = "Farm Leash (TP if >)", min = 5,  max = 60,  step = 1,    dec = 0 },
    { key = "FarmYOffset",              label = "Farm Y Offset",      min = -5,   max = 10,  step = 0.5,  dec = 1 },
    { key = "FarmClickInterval",        label = "Click Interval (s)", min = 0.03, max = 1,   step = 0.02, dec = 2 },
    { key = "FarmEmergencyHealth",      label = "Heal HP (Farm)",     min = 10,   max = 99,  step = 5,    dec = 0 },
    { key = "EmergencyHealthThreshold", label = "Heal HP (Normal)",   min = 5,    max = 99,  step = 5,    dec = 0 },
    { key = "EmergencyHungerThreshold", label = "Eat at Hunger",      min = 5,    max = 80,  step = 5,    dec = 0 },
    { key = "ConsumeHoldTime",          label = "Eat Hold Time (s)",  min = 0.1,  max = 3,   step = 0.1,  dec = 1 },
    { key = "CustomWalkSpeed",          label = "Walk Speed",         min = 16,   max = 120, step = 2,    dec = 0 },
    { key = "ParryRange",               label = "Parry Range",        min = 5,    max = 40,  step = 1,    dec = 0 },
    { key = "ParryReactionDelay",       label = "Parry Delay (s)",    min = 0,    max = 0.5, step = 0.01, dec = 2 },
    { key = "ParryHoldDuration",        label = "Parry Hold (s)",     min = 0.1,  max = 2,   step = 0.1,  dec = 1 },
    { key = "ParryRepressGap",          label = "Parry Re-press (s)", min = 0.1,  max = 1,   step = 0.05, dec = 2 },
    { key = "FishSellThreshold",        label = "Sell Fish At",       min = 1,    max = 30,  step = 1,    dec = 0 },
}

local SETTINGS_FILE = "BearHubSettings.json"
local SETTINGS_VERSION = 2
local DEFAULTS = {}
for _, def in ipairs(SETTINGS) do DEFAULTS[def.key] = CONFIG[def.key] end

local function saveSettings()
    local data = {}
    for _, def in ipairs(SETTINGS) do data[def.key] = CONFIG[def.key] end
    data.__v = SETTINGS_VERSION
    data.__brand = __BRAND__
    getgenv().BearHubSaved = data
    if type(writefile) == "function" then
        pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(data)) end)
    end
end

local function loadSettings()
    local data = getgenv().BearHubSaved
    if not data and type(readfile) == "function" and type(isfile) == "function" then
        pcall(function()
            if isfile(SETTINGS_FILE) then
                data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            end
        end)
    end
    if type(data) == "table" and data.__v == SETTINGS_VERSION then
        for _, def in ipairs(SETTINGS) do
            local v = data[def.key]
            if type(v) == "number" then CONFIG[def.key] = math.clamp(v, def.min, def.max) end
        end
    end
end
loadSettings()

-- States
getgenv().AdminState = {
    AutoFish = false,
    AutoSurvival = true,
    AutoParry = false,
    BanditESP = false,
    FreeMouse = true,
    AutoFarm = false,
    Fullbright = false,
    SpeedBoost = false,
    Noclip = false,
    InfJump = false,
    AutoTPOnSelect = false,
    AutoLetter = false
}

getgenv().BearHubRunId = (getgenv().BearHubRunId or 0) + 1
local RUN_ID = getgenv().BearHubRunId
local function isCurrent() return getgenv().BearHubRunId == RUN_ID end

if type(getgenv().BearHubConns) == "table" then
    for _, c in ipairs(getgenv().BearHubConns) do pcall(function() c:Disconnect() end) end
end
getgenv().BearHubConns = {}

-- ================= 1. ANTI-AFK & ADMIN UTILITY =================
table.insert(getgenv().BearHubConns, plr.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end))

-- Noclip Handler
local NoclipOriginal = setmetatable({}, { __mode = "k" })
local function restoreNoclip()
    for part, original in pairs(NoclipOriginal) do
        if part and part.Parent then
            part.CanCollide = original
        end
    end
    NoclipOriginal = setmetatable({}, { __mode = "k" })
end

table.insert(getgenv().BearHubConns, RunService.Stepped:Connect(function()
    local c = plr.Character
    if getgenv().AdminState.Noclip and c then
        for _, part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") then
                if NoclipOriginal[part] == nil then
                    NoclipOriginal[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    elseif next(NoclipOriginal) ~= nil then
        restoreNoclip()
    end
end))

-- Infinite Jump Handler
table.insert(getgenv().BearHubConns, UserInputService.JumpRequest:Connect(function()
    if getgenv().AdminState.InfJump and plr.Character then
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

-- Fullbright Module
local FullbrightModule = { _original = {}, _conn = nil }
local function saveOriginalLighting()
    FullbrightModule._original = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient
    }
end

function FullbrightModule:Apply(enable)
    if enable then
        if next(self._original) == nil then saveOriginalLighting() end
        local function setLight()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 786543
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(180, 180, 180)
            Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        end
        setLight()
        if not self._conn then
            self._conn = Lighting.Changed:Connect(function()
                if getgenv().AdminState.Fullbright and isCurrent() then setLight() end
            end)
            table.insert(getgenv().BearHubConns, self._conn)
        end
    else
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        if next(self._original) ~= nil then
            Lighting.Brightness = self._original.Brightness
            Lighting.ClockTime = self._original.ClockTime
            Lighting.FogEnd = self._original.FogEnd
            Lighting.GlobalShadows = self._original.GlobalShadows
            Lighting.Ambient = self._original.Ambient
            Lighting.OutdoorAmbient = self._original.OutdoorAmbient
        end
    end
end

-- Speed Boost Applier
local function applyWalkSpeed(c)
    if not c then return end
    local hum = c:WaitForChild("Humanoid", 3)
    if hum then
        hum.WalkSpeed = getgenv().AdminState.SpeedBoost and CONFIG.CustomWalkSpeed or CONFIG.DefaultWalkSpeed
    end
end

table.insert(getgenv().BearHubConns, plr.CharacterAdded:Connect(function(c)
    restoreNoclip()
    task.wait(0.5)
    if isCurrent() then
        applyWalkSpeed(c)
    end
end))

-- ================= 2. AUTO-PARRY / BLOCK =================
local ParrySystem = {
    Parrying = false,
    Repressing = false,
    HoldUntil = 0,
    PressTick = 0,
    Bound = setmetatable({}, { __mode = "k" }),
    Seen = setmetatable({}, { __mode = "k" }),
    AttackKeywords = {
        "attack", "slash", "swing", "strike", "m1", "m2", "heavy",
        "light", "katana", "blade", "cut", "slice", "combo", "thrust",
        "stab", "hit", "sword", "spear", "kick", "punch", "smash"
    },
    IgnoreKeywords = {
        "idle", "walk", "run", "jump", "fall", "climb", "swim", "death",
        "die", "dead", "stun", "react", "spawn", "sit", "emote", "dance", "sprint"
    }
}

local function rightClick(down)
    local ok = pcall(function()
        local c = workspace.CurrentCamera.ViewportSize / 2
        VirtualInputManager:SendMouseButtonEvent(c.X, c.Y, 1, down, game, 0)
    end)
    if not ok then
        pcall(function()
            VirtualUser:CaptureController()
            local cf = workspace.CurrentCamera.CFrame
            if down then
                VirtualUser:Button2Down(Vector2.new(0, 0), cf)
            else
                VirtualUser:Button2Up(Vector2.new(0, 0), cf)
            end
        end)
    end
end

function ParrySystem:TriggerParry()
    local now = os.clock()
    self.HoldUntil = math.max(self.HoldUntil, now + CONFIG.ParryHoldDuration)

    if self.Parrying then
        if not self.Repressing and now - self.PressTick >= CONFIG.ParryRepressGap then
            self.Repressing = true
            task.spawn(function()
                rightClick(false)
                task.wait(0.03)
                if self.Parrying then
                    rightClick(true)
                    self.PressTick = os.clock()
                end
                self.Repressing = false
            end)
        end
        return
    end

    self.Parrying = true
    task.spawn(function()
        if CONFIG.ParryReactionDelay > 0 then
            task.wait(CONFIG.ParryReactionDelay)
        end
        if parryRemote and parryRemote:IsA("RemoteEvent") then
            pcall(function() parryRemote:FireServer("Parry", true) end)
            pcall(function() parryRemote:FireServer("Block", true) end)
        end
        rightClick(true)
        self.PressTick = os.clock()

        while (os.clock() < self.HoldUntil or self.Repressing) and isCurrent() do
            task.wait(0.02)
        end
        rightClick(false)
        self.Parrying = false
    end)
end

function ParrySystem:IsAttackTrack(track)
    if not track then return false end
    local name = (track.Name or ""):lower()
    local animName = (track.Animation and track.Animation.Name or ""):lower()

    for _, kw in ipairs(self.AttackKeywords) do
        if name:find(kw, 1, true) or animName:find(kw, 1, true) then return true end
    end

    if CONFIG.ParryAnyAction then
        for _, kw in ipairs(self.IgnoreKeywords) do
            if name:find(kw, 1, true) or animName:find(kw, 1, true) then return false end
        end
        if track.Looped then return false end
        local pr = track.Priority
        if pr == Enum.AnimationPriority.Action or pr == Enum.AnimationPriority.Action2
            or pr == Enum.AnimationPriority.Action3 or pr == Enum.AnimationPriority.Action4 then
            return true
        end
    end
    return false
end

function ParrySystem:CheckTrack(mob, track, fresh)
    if self.Seen[track] then return end
    if not getgenv().AdminState.AutoParry or not isCurrent() then return end
    if not fresh and track.TimePosition > 0.5 then return end

    local mHum = mob:FindFirstChildOfClass("Humanoid")
    if mHum and mHum.Health <= 0 then return end

    local _, _, myRoot = getAliveCharacter()
    local enemyRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart", true)
    if not myRoot or not enemyRoot then return end

    local dist = (enemyRoot.Position - myRoot.Position).Magnitude
    if dist <= CONFIG.ParryRange and self:IsAttackTrack(track) then
        self.Seen[track] = true
        self:TriggerParry()
    end
end

function ParrySystem:BindMob(mob, animator)
    if self.Bound[animator] then return end
    self.Bound[animator] = true
    local conn = animator.AnimationPlayed:Connect(function(track)
        self:CheckTrack(mob, track, true)
    end)
    table.insert(getgenv().BearHubConns, conn)
end

task.spawn(function()
    while isCurrent() do
        if getgenv().AdminState.AutoParry then
            local world = workspace:FindFirstChild("World")
            local bandits = world and world:FindFirstChild("Bandits")
            if bandits then
                for _, mob in ipairs(bandits:GetChildren()) do
                    local animator = mob:FindFirstChildWhichIsA("Animator", true)
                    if animator then
                        ParrySystem:BindMob(mob, animator)
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            ParrySystem:CheckTrack(mob, track, false)
                        end
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- ================= 3. SMART EMERGENCY & MERCHANT ENGINE =================
local SurvivalEngine = {
    Hunger = 100,
    Health = 100,
    MaxHealth = 100,
    Sickness = "None",
    Stage = 0,
    IsBusy = false,
    LastAction = 0,
    LastFood = 0,
    ActionCooldown = 3.5
}

function SurvivalEngine:CheckVitals()
    pcall(function()
        local vitals = plr.PlayerGui.MainUI.HUD.Stats.Vitals
        local hungerFrame = vitals:FindFirstChild("Hunger")
        if hungerFrame then
            local fill = hungerFrame:FindFirstChild("Bar", true) or hungerFrame:FindFirstChild("Fill", true)
            if fill and fill:IsA("GuiObject") then
                local v = math.floor(fill.Size.X.Scale * 100)
                if v > 0 and v <= 100 then self.Hunger = v end
            end
        end
    end)

    local currentCharacter = plr.Character
    if currentCharacter then
        self.Sickness = currentCharacter:GetAttribute("Sickness") or "None"
        self.Stage = currentCharacter:GetAttribute("SicknessStage") or 0
        local hum = currentCharacter:FindFirstChildOfClass("Humanoid")
        if hum then
            self.Health = hum.Health
            self.MaxHealth = hum.MaxHealth
        end
    end
end

local function getNPCCFrame(npcName)
    local searchArea = workspace:FindFirstChild("World") or workspace
    for _, desc in ipairs(searchArea:GetDescendants()) do
        if desc.Name:lower():find(npcName:lower(), 1, true) then
            local part = desc:IsA("BasePart") and desc or desc:FindFirstChildWhichIsA("BasePart", true)
            if part then return part.CFrame end
        end
    end
    return nil
end

local function findItemTool(exactName, keywords)
    local backpack = plr:FindFirstChild("Backpack")
    local currentCharacter = plr.Character

    local function scan(container, equipped)
        if not container then return nil end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local iname = item.Name:lower()
                if iname == exactName:lower() then return item, equipped end
                if keywords then
                    for _, kw in ipairs(keywords) do
                        if iname:find(kw:lower(), 1, true) then return item, equipped end
                    end
                end
            end
        end
        return nil
    end

    local tool, eq = scan(currentCharacter, true)
    if tool then return tool, eq end
    tool, eq = scan(backpack, false)
    if tool then return tool, eq end
    return nil, false
end

local function pressUse(tool)
    pcall(function() tool:Activate() end)
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)
    pcall(function()
        local cam = workspace.CurrentCamera
        local c = cam.ViewportSize / 2
        VirtualInputManager:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0)
        task.wait(CONFIG.ConsumeHoldTime)
        VirtualInputManager:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0)
    end)
end

function SurvivalEngine:ConsumeItem(tool, itemName)
    local isFood = itemName == CONFIG.FoodItem
    self:CheckVitals()
    local beforeHunger, beforeHealth, beforeStage = self.Hunger, self.Health, self.Stage

    for attempt = 1, CONFIG.ConsumeAttempts do
        if not isCurrent() then break end
        local char, hum = getAliveCharacter()
        if not char or not hum then break end

        if tool.Parent ~= char then
            pcall(function() hum:EquipTool(tool) end)
            task.wait(0.35)
        end

        pressUse(tool)

        if attempt >= 3 then
            if isFood then
                pcall(function() foodRemote:FireServer("Eat") end)
            else
                pcall(function() remedyRemote:FireServer("Consume") end)
            end
        end

        task.wait(0.7)

        local stillHave = tool.Parent and (tool:IsDescendantOf(plr) or (plr.Character and tool:IsDescendantOf(plr.Character)))
        if not stillHave then return true end

        self:CheckVitals()
        if isFood and self.Hunger > beforeHunger then return true end
        if not isFood and (self.Health > beforeHealth or self.Stage < beforeStage) then return true end
    end

    warn("[Bear Hub Survival] ใช้ไอเทมไม่สำเร็จ: " .. tostring(itemName))
    return false
end

function SurvivalEngine:TeleportAndPurchase(npcName, itemName, forceConsume, keywords)
    if self.IsBusy then return false end
    if os.clock() - self.LastAction < self.ActionCooldown then return false end

    local _, hum, root = getAliveCharacter()
    if not root or not hum then return false end

    local npcCF = getNPCCFrame(npcName)
    if not npcCF then
        warn("[Bear Hub Survival] NPC not found: " .. tostring(npcName))
        return false
    end

    self.IsBusy = true
    self.LastAction = os.clock()
    castSerial = castSerial + 1
    currentBiteToken = nil
    local success = false

    local ok, err = xpcall(function()
        local originalCF = root.CFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = npcCF + Vector3.new(0, CONFIG.TPOffsetY, 0)
        task.wait(0.4)

        shopRemote:FireServer("Buy", npcName, { [itemName] = 1 })

        if forceConsume then
            local tool = nil
            local t0 = os.clock()
            while os.clock() - t0 < 3.5 and isCurrent() do
                tool = findItemTool(itemName, keywords)
                if tool then break end
                task.wait(0.2)
            end

            if tool and tool.Parent then
                success = self:ConsumeItem(tool, itemName)
            else
                warn("[Bear Hub Survival] ซื้อแล้วแต่หาไอเทมไม่เจอ: " .. tostring(itemName))
            end
        else
            task.wait(0.5)
            success = true
        end

        local _, _, newRoot = getAliveCharacter()
        if newRoot then
            newRoot.AssemblyLinearVelocity = Vector3.zero
            newRoot.AssemblyAngularVelocity = Vector3.zero
            if getgenv().AdminState.AutoFish then
                newRoot.CFrame = CONFIG.FishingSpotCF + Vector3.new(0, CONFIG.TPOffsetY, 0)
            else
                newRoot.CFrame = originalCF
            end
        end
    end, debug.traceback)

    self.IsBusy = false
    if not ok then
        warn("[Bear Hub Survival] " .. tostring(err))
    end
    return success
end

task.spawn(function()
    while isCurrent() do
        if getgenv().AdminState.AutoSurvival and not SurvivalEngine.IsBusy then
            SurvivalEngine:CheckVitals()
            if os.clock() - SurvivalEngine.LastAction >= SurvivalEngine.ActionCooldown then
                if SurvivalEngine.Sickness ~= "None" and SurvivalEngine.Stage >= 1 then
                    SurvivalEngine:TeleportAndPurchase(CONFIG.YakukoNPC, CONFIG.SickMedicine, true, { "senjigusuri", "remedy" })
                    task.wait(1)
                elseif SurvivalEngine.Health <= ((getgenv().AdminState.AutoFarm and CONFIG.FarmEmergencyHealth) or CONFIG.EmergencyHealthThreshold) then
                    SurvivalEngine:TeleportAndPurchase(CONFIG.YakukoNPC, CONFIG.HealMedicine, true, { "kaifukuto", "heal", "remedy" })
                    task.wait(1)
                elseif SurvivalEngine.Hunger <= CONFIG.EmergencyHungerThreshold
                    and os.clock() - SurvivalEngine.LastFood > CONFIG.FoodCooldown then
                    SurvivalEngine.LastFood = os.clock()
                    SurvivalEngine:TeleportAndPurchase(CONFIG.FoodMerchant, CONFIG.FoodItem, true, { "bread", "food" })
                    task.wait(1)
                end
            end
        end
        task.wait(0.8)
    end
end)

-- ================= 4. AUTO-FISHING =================
table.insert(getgenv().BearHubConns, fishingRemote.OnClientEvent:Connect(function(action, data)
    if not isCurrent() then return end
    lastAction = action
    if action == "Bite" then
        local token = (type(data) == "table" and data.token) or data
        if token then
            currentBiteToken = token
            local serial = castSerial
            task.spawn(function()
                task.wait(rng:NextNumber(CONFIG.MinReactionDelay, CONFIG.MaxReactionDelay))
                if currentBiteToken == token and serial == castSerial
                    and isCurrent() and getgenv().AdminState.AutoFish then
                    pcall(function() fishingRemote:FireServer("Result", true, token) end)
                end
            end)
        end
    elseif action == "CastEnded" then
        currentBiteToken = nil
    end
end))

local function teleportToSpot(cf)
    local _, _, root = getAliveCharacter()
    if not root then return false end
    local ok = pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = cf
    end)
    if ok then task.wait(0.3) end
    return ok
end

local function getFishingPrompt()
    local world = workspace:FindFirstChild("World")
    local interactables = world and world:FindFirstChild("Interactables")
    local fishFolder = interactables and interactables:FindFirstChild("Fish")
    if not fishFolder then return nil, nil, math.huge end

    local _, _, root = getAliveCharacter()
    if not root then return nil, nil, math.huge end

    local bestSpot, bestPrompt, bestDist = nil, nil, math.huge
    for _, spot in ipairs(fishFolder:GetChildren()) do
        local cf
        if spot:IsA("BasePart") or spot:IsA("Model") then
            cf = spot:GetPivot()
        else
            local part = spot:FindFirstChildWhichIsA("BasePart", true)
            cf = part and part.CFrame
        end

        local pos = cf and cf.Position
        if pos then
            local dist = (pos - root.Position).Magnitude
            if dist < bestDist then
                local prompt = spot:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    pcall(function()
                        prompt.RequiresLineOfSight = false
                        prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, CONFIG.SpotMaxDist)
                    end)
                    bestSpot, bestPrompt, bestDist = spot, prompt, dist
                end
            end
        end
    end

    return bestPrompt, bestSpot, bestDist
end

local function activatePrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return false end
    if type(fireproximityprompt) == "function" then
        local ok = pcall(fireproximityprompt, prompt)
        if ok then return true end
    end
    return pcall(function()
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration)
        prompt:InputHoldEnd()
    end)
end

local function ensureRodEquipped()
    local currentCharacter, hum = getAliveCharacter()
    if not currentCharacter or not hum then return false end
    local backpack = plr:FindFirstChild("Backpack")
    if not backpack then return false end

    local fishCount = 0
    for _, container in ipairs({ currentCharacter, backpack }) do
        for _, item in ipairs(container:GetChildren()) do
            local n = item.Name:lower()
            if item:IsA("Tool") and n:find("fish", 1, true) and not n:find("rod", 1, true) then
                fishCount = fishCount + 1
            end
        end
    end

    if fishCount >= CONFIG.FishSellThreshold then
        pcall(function()
            shopRemote:FireServer("Sell", "Takeshi", { Fish = fishCount })
        end)
        task.wait(0.4)
    end

    local equippedTool = currentCharacter:FindFirstChildOfClass("Tool")
    if equippedTool and equippedTool.Name:lower():find("rod", 1, true) then return true end

    local function findRod()
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("rod", 1, true) then return item end
        end
        return nil
    end

    local rod = findRod()
    if not rod then
        pcall(function()
            shopRemote:FireServer("Buy", "Takeshi", { ["Best Fishing Rod"] = 1 })
        end)
        local t0 = os.clock()
        while os.clock() - t0 < 3 and isCurrent() do
            rod = findRod()
            if rod then break end
            task.wait(0.2)
        end
    end

    if not rod then return false end

    local ok = pcall(function() hum:EquipTool(rod) end)
    if not ok then return false end
    task.wait(0.3)

    local latest = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
    return latest ~= nil and latest.Name:lower():find("rod", 1, true) ~= nil
end

local FishStats = { casts = 0, caught = 0, misses = 0 }
getgenv().FishStats = FishStats

task.spawn(function()
    while isCurrent() do
        repeat
            if not getgenv().AdminState.AutoFish or getgenv().AdminState.AutoFarm or SurvivalEngine.IsBusy then
                task.wait(0.2)
                break
            end
            if not ensureRodEquipped() then
                task.wait(0.8)
                break
            end

            local prompt, spot, dist = getFishingPrompt()
            if not prompt or dist > CONFIG.SpotMaxDist then
                teleportToSpot(CONFIG.FishingSpotCF)
                task.wait(0.4)
                prompt, spot, dist = getFishingPrompt()
            end

            if not (prompt and dist <= CONFIG.SpotMaxDist) then
                task.wait(CONFIG.CastRetryDelay)
                break
            end

            currentBiteToken, lastAction = nil, nil
            castSerial = castSerial + 1
            local serial = castSerial

            local _, _, root = getAliveCharacter()
            if root and spot then
                local oldRot = root.CFrame - root.CFrame.Position
                local spotCF = spot:IsA("BasePart") and spot.CFrame or (spot:IsA("Model") and spot:GetPivot())
                if spotCF then
                    root.CFrame = CFrame.new(root.Position, Vector3.new(spotCF.X, root.Position.Y, spotCF.Z))
                end
                activatePrompt(prompt)
                task.wait(0.1)
                if root.Parent then root.CFrame = CFrame.new(root.Position) * oldRot end
            else
                activatePrompt(prompt)
            end
            FishStats.casts = FishStats.casts + 1

            local t0, gotBite = os.clock(), false
            while os.clock() - t0 < CONFIG.CastTimeout and isCurrent()
                and getgenv().AdminState.AutoFish and serial == castSerial do
                if lastAction == "Bite" then gotBite = true end
                if lastAction == "CastEnded" then
                    if gotBite then
                        FishStats.caught = FishStats.caught + 1
                    else
                        FishStats.misses = FishStats.misses + 1
                    end
                    break
                end
                task.wait(0.05)
            end
            task.wait(CONFIG.CastRetryDelay)
        until true
    end
end)

-- ================= 4.5 AUTO FARM BANDITS =================
local function findWeapon()
    local backpack = plr:FindFirstChild("Backpack")
    local char = plr.Character
    local skip = { "rod", "fish", "bread", "senjigusuri", "kaifukuto", "remedy", "tea" }

    local function isSkipped(n)
        for _, w in ipairs(skip) do
            if n:find(w, 1, true) then return true end
        end
        return false
    end

    local function scan(container, useKeywords)
        if not container then return nil end
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if useKeywords then
                    for _, kw in ipairs(CONFIG.WeaponKeywords) do
                        if n:find(kw, 1, true) then return item end
                    end
                elseif not isSkipped(n) then
                    return item
                end
            end
        end
        return nil
    end

    return scan(char, true) or scan(backpack, true) or scan(char, false) or scan(backpack, false)
end

local function equipWeapon()
    local char, hum = getAliveCharacter()
    if not char or not hum then return false end
    local weapon = findWeapon()
    if not weapon then return false end
    if weapon.Parent ~= char then
        pcall(function() hum:EquipTool(weapon) end)
        task.wait(0.25)
    end
    return weapon.Parent == char
end

local function swingWeapon()
    local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
    if tool then pcall(function() tool:Activate() end) end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(0, 0))
    end)
end

local FarmFace = { Root = nil, Down = false }
pcall(function() RunService:UnbindFromRenderStep("BearHubFarmFace") end)
RunService:BindToRenderStep("BearHubFarmFace", 3001, function()
    if not isCurrent() then
        pcall(function() RunService:UnbindFromRenderStep("BearHubFarmFace") end)
        return
    end
    local tr = FarmFace.Root
    if tr and tr.Parent and getgenv().AdminState.AutoFarm then
        local _, _, r = getAliveCharacter()
        if r then
            if FarmFace.Down then
                r.CFrame = CFrame.lookAt(r.Position, r.Position + Vector3.new(0, -1, 0), Vector3.new(0, 0, 1))
            else
                r.CFrame = CFrame.lookAt(r.Position, Vector3.new(tr.Position.X, r.Position.Y, tr.Position.Z))
            end
        end
    end
end)

local function getNearestBandit(fromPos)
    local world = workspace:FindFirstChild("World")
    local bandits = world and world:FindFirstChild("Bandits")
    if not bandits then return nil end

    local best, bestDist = nil, math.huge
    for _, mob in ipairs(bandits:GetChildren()) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local mRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart", true)
        if hum and mRoot and hum.Health > 0 then
            local d = (mRoot.Position - fromPos).Magnitude
            if d < bestDist then best, bestDist = mob, d end
        end
    end
    return best
end

task.spawn(function()
    while isCurrent() do
        repeat
            if not getgenv().AdminState.AutoFarm or SurvivalEngine.IsBusy then
                task.wait(0.2)
                break
            end

            local _, _, root = getAliveCharacter()
            if not root then
                task.wait(0.5)
                break
            end

            if not equipWeapon() then
                task.wait(1)
                break
            end

            local target = getNearestBandit(root.Position)
            if not target then
                task.wait(1)
                break
            end

            local t0, lastSwing, arrived = os.clock(), 0, false
            local fixedDir = nil
            while isCurrent() and getgenv().AdminState.AutoFarm and not SurvivalEngine.IsBusy
                and os.clock() - t0 < CONFIG.FarmTargetTimeout do

                local tHum = target:FindFirstChildOfClass("Humanoid")
                local tRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart", true)
                if not target.Parent or not tHum or not tRoot or tHum.Health <= 0 then break end

                local _, myHum, myRoot = getAliveCharacter()
                if not myRoot or not myHum then break end
                myHum.AutoRotate = false

                local tPos = tRoot.Position
                FarmFace.Root = tRoot

                if CONFIG.FarmMode == 2 then
                    FarmFace.Down = true
                    local hoverPos = tPos + Vector3.new(0, CONFIG.FarmAboveHeight, 0)
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                    myRoot.AssemblyAngularVelocity = Vector3.zero
                    myRoot.CFrame = CFrame.lookAt(hoverPos, hoverPos + Vector3.new(0, -1, 0), Vector3.new(0, 0, 1))
                    arrived = true
                else
                    FarmFace.Down = false
                    if not fixedDir then
                        local back = tRoot.CFrame.LookVector * CONFIG.FarmSide
                        local flat = Vector3.new(back.X, 0, back.Z)
                        if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, 1) end
                        fixedDir = flat.Unit
                    end
                    local desired = tPos + fixedDir * CONFIG.FarmDistance + Vector3.new(0, CONFIG.FarmYOffset, 0)

                    local gap = Vector3.new(desired.X - myRoot.Position.X, 0, desired.Z - myRoot.Position.Z).Magnitude
                    if not arrived or gap > CONFIG.FarmLeash then
                        arrived = true
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        myRoot.CFrame = CFrame.lookAt(desired, Vector3.new(tPos.X, desired.Y, tPos.Z))
                    elseif gap > 1.5 then
                        myHum:MoveTo(desired)
                    end
                    myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(tPos.X, myRoot.Position.Y, tPos.Z))
                end

                if not ParrySystem.Parrying and os.clock() - lastSwing >= CONFIG.FarmClickInterval then
                    lastSwing = os.clock()
                    swingWeapon()
                end
                RunService.Heartbeat:Wait()
            end
            FarmFace.Root = nil
            FarmFace.Down = false
            do
                local _, rh = getAliveCharacter()
                if rh then rh.AutoRotate = true end
            end
            task.wait(0.1)
        until true
    end
end)

-- ================= 4.8 AUTO LETTER ENGINE (v5.4 FOCUS-HOLD) =================
local LetterState = {
    busy = false,
    lastSig = "",
    status = "พร้อมทำงาน",
    solved = 0
}

local EMOJI_LIST = { "🔴", "🟠", "🟡", "🟢", "🔵", "🟣", "🟤", "⚫", "⚪" }
local function extractEmoji(str)
    if not str then return nil end
    for _, emo in ipairs(EMOJI_LIST) do
        if str:find(emo, 1, true) then return emo end
    end
    return nil
end

local function cleanHtml(str)
    if not str then return "" end
    local cleaned = str:gsub("<[^>]+>", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
    return cleaned or ""
end

local function executeLetterClick(btn, btnName)
    if not btn or not btn.Parent then 
        warn("[LetterClick] ไม่พบปุ่ม:", btnName)
        return false 
    end
    
    local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
    local x = math.floor(pos.X)
    local y = math.floor(pos.Y)

    -- [หัวใจสำคัญ]: โฟกัสปุ่ม แล้วกด ButtonA ตามมาตรฐาน Roblox Engine
    pcall(function()
        GuiService.SelectedObject = btn
        task.wait(0.08)

        -- 1. ยิง ButtonA
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.ButtonA, false, game)
        task.wait(0.08)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.ButtonA, false, game)
        task.wait(0.05)

        -- 2. ยิง Return (Enter)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.04)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)

    -- [เสริม 1]: ยิง Event สัญญาณตรง
    local eventNames = {"MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up"}
    for _, sigName in ipairs(eventNames) do
        pcall(function()
            if btn[sigName] and type(firesignal) == "function" then
                firesignal(btn[sigName])
            end
        end)
        pcall(function()
            if btn[sigName] and type(getconnections) == "function" then
                for _, conn in ipairs(getconnections(btn[sigName])) do
                    if type(conn.Fire) == "function" then
                        conn:Fire()
                    elseif type(conn.Function) == "function" then
                        conn.Function()
                    end
                end
            end
        end)
    end

    -- [เสริม 2]: จำลองเมาส์คลิกพิกัดจริง
    pcall(function()
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)

    task.wait(0.08)
    pcall(function()
        GuiService.SelectedObject = nil
    end)

    return true
end

local function getLetterContainer()
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local mainUI = pg:FindFirstChild("MainUI") or pg
    local claims = mainUI:FindFirstChild("Claims", true)
    if claims and claims.Parent then
        local p = claims.Parent
        if p:FindFirstChild("Records") and p:FindFirstChild("Rulings") then
            return p
        end
    end
    return nil
end

local function parseTownRecords(recordsFrame)
    local ctx = { signed = nil, wrote = 0, today = nil, streets = {}, heads = {}, houses = {} }
    local currentStreet = nil

    for _, rec in ipairs(recordsFrame:GetChildren()) do
        if rec:IsA("GuiObject") and rec.Visible then
            local entryLabel = rec:FindFirstChild("Entry")
            local valueLabel = rec:FindFirstChild("Value")
            if entryLabel and valueLabel then
                local entry = cleanHtml(entryLabel.Text)
                local val = cleanHtml(valueLabel.Text)
                local el = entry:lower()
                local vl = val:lower()

                if el:find("signed on") then
                    ctx.signed = tonumber(val:match("%d+"))
                elseif el:find("wrote before") then
                    if vl:find("none") or vl:find("never") then
                        ctx.wrote = 0
                    else
                        ctx.wrote = tonumber(val:match("%d+")) or 0
                    end
                elseif el:find("today is") then
                    ctx.today = tonumber(val:match("%d+"))
                elseif el:find("^head:") then
                    if currentStreet then
                        ctx.heads[currentStreet] = entry:match("^[Hh]ead:%s*(.+)$")
                        ctx.houses[currentStreet] = tonumber(val:match("(%d+)%s*[Hh]ouses?"))
                    end
                elseif vl:find("ryo") then
                    currentStreet = el
                    local dotEmoji = extractEmoji(val)
                    local paidAmt = tonumber(val:match("(%d+)%s*Ryo"))
                    ctx.streets[currentStreet] = { paid = paidAmt, dot = dotEmoji }
                end
            end
        end
    end
    return ctx
end

local function verifyLetterClaim(claimText, ctx, bodyText, askText, sealEmoji, senderKey)
    local c = cleanHtml(claimText):lower():gsub("%s+", " "):gsub("[%.!]+$", "")

    -- 1. วันที่
    local sd = c:match("signed on day (%d+)") or c:match("written on day (%d+)") or c:match("dated day (%d+)")
    if sd then return (ctx.signed and ctx.signed == tonumber(sd)), "signed" end

    -- 2. จำนวนวันที่ผ่านมา
    local dn = c:match("(%d+) days? ago")
    if dn then
        if ctx.today and ctx.signed then
            return ((ctx.today - ctx.signed) == tonumber(dn)), "days"
        end
    end

    -- 3. การส่งจดหมาย
    local isLetterCountClaim = c:find("written", 1, true) or c:find("wrote before", 1, true) or c:find("wrote in", 1, true)
    if isLetterCountClaim then
        if c:find("not written") or c:find("never") then return (ctx.wrote == 0), "wrote-none" end
        local times = c:match("(%d+) times") or c:match("(%d+) letters")
        if times then return (ctx.wrote ~= nil and ctx.wrote == tonumber(times)), "wrote-times" end
    end

    -- 4. หัวหน้าหมู่บ้าน
    local headName, headStreet = c:match("^(.-) is the head of (.+)$")
    if not headName then headStreet, headName = c:match("^the head of (.-) is (.+)$") end
    if headName and headStreet then
        local h = ctx.heads[headStreet:lower()]
        return (h and h:lower() == headName:lower()), "head"
    end

    -- 5. จำนวนบ้าน
    local hn = c:match("(%d+) houses")
    if hn then
        local target = senderKey
        for s in pairs(ctx.streets) do if c:find(s, 1, true) then target = s break end end
        return (target and ctx.houses[target] == tonumber(hn)), "houses"
    end

    -- 6. ตราประทับ
    if c:find("seal", 1, true) then
        local target = senderKey
        for s in pairs(ctx.streets) do if c:find(s, 1, true) then target = s break end end
        if target and ctx.streets[target] and ctx.streets[target].dot and sealEmoji then
            return (ctx.streets[target].dot == sealEmoji), "seal"
        end
    end

    -- 7. ภาษี
    if not c:find("more than") and not c:find("less than") then
        local pAmt = c:match("(%d+)%s*ryo in tax") or c:match("paid (%d+)%s*ryo") or c:match("paid (%d+)")
        if pAmt then
            local target = senderKey
            for s in pairs(ctx.streets) do if c:find(s, 1, true) then target = s break end end
            if target and ctx.streets[target] then
                return (ctx.streets[target].paid == tonumber(pAmt)), "paid"
            end
        end
    end

    -- 8. ตัวเลขในเนื้อความ
    local fullRef = (askText .. " " .. bodyText):lower():gsub("%s+", " ")
    local foundAnyNumPattern = false
    for num, item in c:gmatch("(%d+)%s+([%a]+)") do
        foundAnyNumPattern = true
        local singular = item:gsub("s$", "")
        local p1 = "%f[%d]" .. num .. "%f[%D]%s+" .. singular
        local p2 = "%f[%d]" .. num .. "%f[%D]%s+" .. item
        if not fullRef:find(p1) and not fullRef:find(p2) then
            return false, "body-num-mismatch"
        end
    end
    if foundAnyNumPattern then return true, "body-num-match" end

    for num in c:gmatch("%d+") do
        if not fullRef:find("%f[%d]" .. num .. "%f[%D]") then
            return false, "standalone-num-mismatch"
        end
    end

    return true, "default-true"
end

local function processLetter(force)
    local container = getLetterContainer()
    if not container then 
        LetterState.lastSig = ""
        return 
    end

    local claimsFrame = container:FindFirstChild("Claims")
    local recordsFrame = container:FindFirstChild("Records")
    local rulingsFrame = container:FindFirstChild("Rulings")
    if not (claimsFrame and recordsFrame and rulingsFrame) then return end

    local fromText = cleanHtml(container:FindFirstChild("From") and container.From.Text or "")
    local sender = fromText:match("^[Ff]rom%s+(.+)$") or fromText
    local senderKey = sender:lower()

    local askText = cleanHtml(container:FindFirstChild("Ask") and container.Ask.Text or "")
    local bodyText = cleanHtml(container:FindFirstChild("Body") and container.Body.Text or "")

    local sealFrame = container:FindFirstChild("Seal")
    local sealGlyph = sealFrame and sealFrame:FindFirstChild("Glyph")
    local sealEmoji = sealGlyph and extractEmoji(sealGlyph.Text) or ""

    local currentSig = sender .. "|" .. askText .. "|" .. bodyText
    if not force and currentSig == LetterState.lastSig then return end

    LetterState.busy = true
    LetterState.lastSig = currentSig

    if not force then
        LetterState.status = "รอกระดาษนิ่ง..."
        task.wait(CONFIG.LetterInitialOpenDelay)
    end

    container = getLetterContainer()
    if not container then LetterState.busy = false return end
    claimsFrame = container:FindFirstChild("Claims")
    recordsFrame = container:FindFirstChild("Records")
    rulingsFrame = container:FindFirstChild("Rulings")
    if not (claimsFrame and recordsFrame and rulingsFrame) then LetterState.busy = false return end

    local ctx = parseTownRecords(recordsFrame)
    local rows = {}
    local anyFalse = false

    for i = 1, 3 do
        local claimBox = claimsFrame:FindFirstChild("Claim" .. i)
        if claimBox then
            local textLabel = claimBox:FindFirstChild("Text")
            local trueBtn = claimBox:FindFirstChild("True")
            local falseBtn = claimBox:FindFirstChild("False")

            if textLabel and trueBtn and falseBtn then
                local claimText = cleanHtml(textLabel.Text)
                local verdict, kind = verifyLetterClaim(claimText, ctx, bodyText, askText, sealEmoji, senderKey)
                if not verdict then anyFalse = true end

                table.insert(rows, {
                    index = i,
                    verdict = verdict,
                    targetName = verdict and "True" or "False"
                })
            end
        end
    end

    local finalAnswer = "Grant"
    if anyFalse then
        finalAnswer = "Deny"
    else
        local fullText = (askText .. " " .. bodyText):lower()
        for _, kw in ipairs(CONFIG.LetterReferKeywords) do
            if fullText:find(kw, 1, true) then
                finalAnswer = "Refer"
                break
            end
        end
    end

    -- สั่งกด Claim 1 -> 2 -> 3
    for i, r in ipairs(rows) do
        local freshBox = claimsFrame:FindFirstChild("Claim" .. i)
        local targetBtn = freshBox and freshBox:FindFirstChild(r.targetName)
        if targetBtn then
            LetterState.status = string.format("กดข้อ [%d]: %s", i, r.targetName:upper())
            executeLetterClick(targetBtn, string.format("Claim%d_%s", i, r.targetName))
            task.wait(CONFIG.LetterBetweenClaimsDelay)
        end
    end

    -- ปลดล็อกปุ่มตัดสินด้านล่าง
    LetterState.status = "ตัดสิน: " .. finalAnswer:upper()
    task.wait(CONFIG.LetterRulingUnlockDelay)

    local rulingBtn = rulingsFrame:FindFirstChild(finalAnswer)
    if rulingBtn then
        executeLetterClick(rulingBtn, "Ruling_" .. finalAnswer)
        task.wait(0.2)
        executeLetterClick(rulingBtn, "RulingConfirm_" .. finalAnswer)
    end

    LetterState.solved = LetterState.solved + 1
    LetterState.status = "เสร็จสิ้น -> " .. finalAnswer:upper()
    LetterState.busy = false
end

task.spawn(function()
    while isCurrent() do
        if getgenv().AdminState.AutoLetter and not LetterState.busy then
            local ok, err = pcall(function() processLetter(false) end)
            if not ok then LetterState.busy = false end
        end
        task.wait(CONFIG.LetterPollInterval)
    end
end)

-- ================= 5. WORLD NAVIGATION SYSTEM =================
local TeleportEngine = {
    Categories = {
        ["Players"] = {},
        ["Interactables"] = {},
        ["Nodes & Mining"] = {},
        ["Bandits & Mobs"] = {},
        ["Fast Travel"] = {},
        ["Custom"] = {}
    },
    SelectedTarget = nil
}

function TeleportEngine:TeleportTo(target)
    local currentCharacter = plr.Character
    local root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
    if not root or not target then return end

    local cf = nil
    if typeof(target) == "Instance" then
        if target:IsA("Player") and target.Character then
            local pRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then cf = pRoot.CFrame end
        elseif target:IsA("BasePart") then
            cf = target.CFrame
        elseif target:IsA("Model") then
            cf = target:GetPivot()
        end
    elseif typeof(target) == "CFrame" then
        cf = target
    end

    if cf then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
        root.CFrame = cf + Vector3.new(0, CONFIG.TPOffsetY, 0)
    end
end

function TeleportEngine:ScanWorld()
    for cat, _ in pairs(self.Categories) do
        if cat ~= "Custom" then self.Categories[cat] = {} end
    end

    local function addDest(cat, name, data)
        if not data then return end
        table.insert(self.Categories[cat], { Name = name, Target = data })
    end

    for _, otherPlr in ipairs(Players:GetPlayers()) do
        if otherPlr ~= plr then
            addDest("Players", otherPlr.DisplayName .. " (@" .. otherPlr.Name .. ")", otherPlr)
        end
    end

    local fastTravelFolder = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Teleports")
    if fastTravelFolder then
        for _, pt in ipairs(fastTravelFolder:GetChildren()) do
            local cf = pt:IsA("BasePart") and pt.CFrame or pt:GetPivot()
            addDest("Fast Travel", pt.Name, cf)
        end
    end

    local world = workspace:FindFirstChild("World")
    if world then
        local interactables = world:FindFirstChild("Interactables")
        if interactables then
            for _, folder in ipairs(interactables:GetChildren()) do
                local fname = folder.Name
                if fname == "Beds" or fname == "Shrines" or fname == "Baker" or fname == "Tailor" or fname == "Houses" then
                    for _, item in ipairs(folder:GetChildren()) do
                        local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
                        if part then addDest("Interactables", fname .. " - " .. item.Name, part.CFrame) end
                    end
                elseif fname == "OreNodes" or fname == "HerbNodes" then
                    for _, node in ipairs(folder:GetChildren()) do
                        local part = node:IsA("BasePart") and node or node:FindFirstChildWhichIsA("BasePart", true)
                        if part then addDest("Nodes & Mining", fname .. " - " .. node.Name, part.CFrame) end
                    end
                end
            end
        end

        local banditsFolder = world:FindFirstChild("Bandits")
        if banditsFolder then
            for _, mob in ipairs(banditsFolder:GetChildren()) do
                local rootPart = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart", true)
                if rootPart then addDest("Bandits & Mobs", mob.Name, rootPart.CFrame) end
            end
        end
    end
end

-- ================= 5.5 BANDIT ESP =================
local BanditESP = { Objects = {}, Container = nil }

function BanditESP:GetContainer()
    if self.Container and self.Container.Parent then return self.Container end
    local pg = plr:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local f = Instance.new("Folder")
    f.Name = "BearHubESP"
    f.Parent = pg
    self.Container = f
    return f
end

function BanditESP:Remove(mob)
    local data = self.Objects[mob]
    if data then
        for _, o in ipairs(data.Items) do pcall(function() o:Destroy() end) end
        self.Objects[mob] = nil
    end
end

function BanditESP:Clear()
    for mob in pairs(self.Objects) do self:Remove(mob) end
    if self.Container then
        pcall(function() self.Container:Destroy() end)
        self.Container = nil
    end
end

function BanditESP:Add(mob)
    if self.Objects[mob] then return end
    local container = self:GetContainer()
    if not container then return end
    local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart", true)
    if not root then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = mob
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillColor = Color3.fromRGB(255, 60, 60)
    hl.FillTransparency = 0.65
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0
    hl.Parent = container

    local bb = Instance.new("BillboardGui")
    bb.Adornee = root
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(140, 30)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(255, 90, 90)
    label.TextStrokeTransparency = 0.3
    label.Text = mob.Name
    label.Parent = bb

    self.Objects[mob] = { Items = { hl, bb }, Label = label, Root = root }
end

task.spawn(function()
    while isCurrent() do
        if getgenv().AdminState.BanditESP then
            local world = workspace:FindFirstChild("World")
            local bandits = world and world:FindFirstChild("Bandits")
            if bandits then
                for _, mob in ipairs(bandits:GetChildren()) do
                    if mob:IsA("Model") then BanditESP:Add(mob) end
                end
            end

            local _, _, myRoot = getAliveCharacter()
            for mob, data in pairs(BanditESP.Objects) do
                if not mob.Parent or not data.Root.Parent then
                    BanditESP:Remove(mob)
                else
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    local hp = hum and math.floor(hum.Health) or 0
                    local dist = myRoot and math.floor((data.Root.Position - myRoot.Position).Magnitude) or 0
                    data.Label.Text = string.format("%s [%d HP] %dm", mob.Name, hp, dist)
                end
            end
        elseif next(BanditESP.Objects) ~= nil or BanditESP.Container then
            BanditESP:Clear()
        end
        task.wait(0.3)
    end
    BanditESP:Clear()
end)

-- ================= 5.6 FREE MOUSE =================
local MouseModule = { gui = nil, btn = nil }

function MouseModule:Apply(enabled)
    if enabled then
        if not (self.gui and self.gui.Parent) then
            local g = Instance.new("ScreenGui")
            g.Name = "BearHubModalGui"
            g.ResetOnSpawn = false
            g.DisplayOrder = -1
            g.Parent = plr:WaitForChild("PlayerGui")
            local b = Instance.new("TextButton")
            b.Size = UDim2.fromOffset(0, 0)
            b.BackgroundTransparency = 1
            b.Text = ""
            b.Modal = true
            b.Parent = g
            self.gui, self.btn = g, b
        end
        self.btn.Modal = true
    else
        if self.gui then
            pcall(function() self.gui:Destroy() end)
            self.gui, self.btn = nil, nil
        end
    end
end

pcall(function() RunService:UnbindFromRenderStep("BearHubFreeMouse") end)
RunService:BindToRenderStep("BearHubFreeMouse", 3000, function()
    if not isCurrent() then
        pcall(function() RunService:UnbindFromRenderStep("BearHubFreeMouse") end)
        return
    end
    if getgenv().AdminState.FreeMouse then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end
end)

-- ================= 6. BEAR HUB DASHBOARD UI =================
local function buildMasterUI()
    local guiName = "BearHub_v1"
    local pg = plr:WaitForChild("PlayerGui")

    for _, n in ipairs({ guiName, "ShogunMasterAdmin_v7_1", "ShogunMasterAdmin_v6_6", "BearHubModalGui", "ShogunModalGui", "AutoLetterController_v5_4" }) do
        local old = pg:FindFirstChild(n)
        if old then old:Destroy() end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = guiName
    gui.ResetOnSpawn = false
    gui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(510, 435)
    frame.Position = UDim2.new(0.5, -255, 0.5, -217)
    frame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 70, 95)
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    title.Font = Enum.Font.GothamBold
    title.Text = "  🐻 BEAR HUB v1.0  |  [" .. CONFIG.ToggleKey.Name .. "] Hide/Show"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = title

    -- ปรับ LeftPanel เป็น ScrollingFrame ป้องกันปุ่มล้นหน้าต่าง
    local leftPanel = Instance.new("ScrollingFrame")
    leftPanel.Size = UDim2.new(0, 190, 1, -42)
    leftPanel.Position = UDim2.new(0, 8, 0, 36)
    leftPanel.BackgroundTransparency = 1
    leftPanel.ScrollBarThickness = 3
    leftPanel.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 95)
    leftPanel.CanvasSize = UDim2.new(0, 0, 0, 445)
    leftPanel.Parent = frame

    local function makeToggle(name, labelText, yPos, stateKey, onToggle)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 21)
        btn.Position = UDim2.new(0, 0, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = "  " .. labelText
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextSize = 9
        btn.TextColor3 = Color3.fromRGB(230, 230, 240)
        btn.Parent = leftPanel
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = btn

        local sLabel = Instance.new("TextLabel")
        sLabel.Size = UDim2.new(0, 35, 1, 0)
        sLabel.Position = UDim2.new(1, -38, 0, 0)
        sLabel.BackgroundTransparency = 1
        sLabel.Font = Enum.Font.GothamBold
        sLabel.TextSize = 9
        sLabel.Parent = btn

        local function refresh()
            local active = getgenv().AdminState[stateKey] == true
            sLabel.Text = active and "ON" or "OFF"
            sLabel.TextColor3 = active and Color3.fromRGB(80, 240, 140) or Color3.fromRGB(240, 80, 80)
        end

        btn.Activated:Connect(function()
            getgenv().AdminState[stateKey] = not getgenv().AdminState[stateKey]
            if onToggle then onToggle(getgenv().AdminState[stateKey]) end
            refresh()
        end)
        refresh()
        return refresh
    end

    local rFish = makeToggle("TFlu", "Auto Fish (360°)", 0, "AutoFish", function(v)
        if v then
            getgenv().AdminState.AutoFarm = false
            task.spawn(teleportToSpot, CONFIG.FishingSpotCF)
        end
    end)
    local rParry = makeToggle("TPar", "⚔ Auto Parry (Bandits)", 23, "AutoParry")
    local rSurv = makeToggle("TSur", "Auto Emergency Heal", 46, "AutoSurvival")
    local rBri = makeToggle("TBri", "Fullbright", 69, "Fullbright", function(v) FullbrightModule:Apply(v) end)
    local rSpd = makeToggle("TSpd", "Speed Boost", 92, "SpeedBoost", function() applyWalkSpeed(plr.Character) end)
    local rNoc = makeToggle("TNoc", "Noclip Mode", 115, "Noclip")
    local rJmp = makeToggle("TJmp", "Infinite Jump", 138, "InfJump")
    local rEsp = makeToggle("TEsp", "Bandit ESP (Wallhack)", 161, "BanditESP")
    local rFarm = makeToggle("TFrm", "⚔ Auto Farm Bandits", 184, "AutoFarm", function(v)
        if v then getgenv().AdminState.AutoFish = false end
    end)
    local rMouse = makeToggle("TMou", "Free Mouse (ปลดล็อกเม้า)", 207, "FreeMouse", function(v)
        MouseModule:Apply(v)
    end)

    -- Toggle สำหรับ Auto Letter
    local rLetter = makeToggle("TLet", "✉ Auto Letter (ตรวจจดหมาย)", 230, "AutoLetter", function(v)
        if v then
            LetterState.busy = false
            LetterState.lastSig = ""
        end
    end)

    -- ปุ่มกดทันที Solve Letter Now
    local solveNowBtn = Instance.new("TextButton")
    solveNowBtn.Size = UDim2.new(1, -6, 0, 20)
    solveNowBtn.Position = UDim2.new(0, 0, 0, 253)
    solveNowBtn.BackgroundColor3 = Color3.fromRGB(60, 45, 95)
    solveNowBtn.Font = Enum.Font.GothamBold
    solveNowBtn.Text = "⚡ Solve Letter Now (กดทันที)"
    solveNowBtn.TextSize = 8
    solveNowBtn.TextColor3 = Color3.fromRGB(255, 225, 100)
    solveNowBtn.Parent = leftPanel
    local snc = Instance.new("UICorner")
    snc.CornerRadius = UDim.new(0, 4)
    snc.Parent = solveNowBtn

    solveNowBtn.Activated:Connect(function()
        LetterState.busy = false
        task.spawn(function() processLetter(true) end)
    end)

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -6, 0, 46)
    infoLabel.Position = UDim2.new(0, 0, 0, 276)
    infoLabel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 8
    infoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
    infoLabel.Text = "HP: 100% | Hunger: 100%\nSick: None | Status: Ready\nLetter: พร้อมทำงาน"
    infoLabel.Parent = leftPanel
    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(0, 4)
    ic.Parent = infoLabel

    local claimBtn = Instance.new("TextButton")
    claimBtn.Size = UDim2.new(1, -6, 0, 20)
    claimBtn.Position = UDim2.new(0, 0, 0, 325)
    claimBtn.BackgroundColor3 = Color3.fromRGB(45, 95, 140)
    claimBtn.Font = Enum.Font.GothamBold
    claimBtn.Text = "Claim Paycheck & Allowance"
    claimBtn.TextSize = 8
    claimBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
    claimBtn.Parent = leftPanel
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 4)
    cc.Parent = claimBtn

    claimBtn.Activated:Connect(function()
        pcall(function() paycheckRemote:FireServer() end)
        pcall(function() allowanceRemote:FireServer() end)
    end)

    local sickBtn = Instance.new("TextButton")
    sickBtn.Size = UDim2.new(0.48, -4, 0, 22)
    sickBtn.Position = UDim2.new(0, 0, 0, 348)
    sickBtn.BackgroundColor3 = Color3.fromRGB(130, 40, 140)
    sickBtn.Font = Enum.Font.GothamBold
    sickBtn.Text = "Buy Senjigusuri"
    sickBtn.TextSize = 8
    sickBtn.TextColor3 = Color3.fromRGB(255, 230, 255)
    sickBtn.Parent = leftPanel
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 4)
    sc.Parent = sickBtn

    sickBtn.Activated:Connect(function()
        task.spawn(function()
            SurvivalEngine:TeleportAndPurchase(CONFIG.YakukoNPC, CONFIG.SickMedicine, false)
        end)
    end)

    local healBtn = Instance.new("TextButton")
    healBtn.Size = UDim2.new(0.48, -4, 0, 22)
    healBtn.Position = UDim2.new(0.52, 0, 0, 348)
    healBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 80)
    healBtn.Font = Enum.Font.GothamBold
    healBtn.Text = "Buy Kaifukuto"
    healBtn.TextSize = 8
    healBtn.TextColor3 = Color3.fromRGB(230, 255, 240)
    healBtn.Parent = leftPanel
    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 4)
    hc.Parent = healBtn

    healBtn.Activated:Connect(function()
        task.spawn(function()
            SurvivalEngine:TeleportAndPurchase(CONFIG.YakukoNPC, CONFIG.HealMedicine, false)
        end)
    end)

    local foodBtn = Instance.new("TextButton")
    foodBtn.Size = UDim2.new(1, -6, 0, 20)
    foodBtn.Position = UDim2.new(0, 0, 0, 373)
    foodBtn.BackgroundColor3 = Color3.fromRGB(160, 90, 40)
    foodBtn.Font = Enum.Font.GothamBold
    foodBtn.Text = "Buy Bread (Genzo)"
    foodBtn.TextSize = 8
    foodBtn.TextColor3 = Color3.fromRGB(255, 245, 230)
    foodBtn.Parent = leftPanel
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 4)
    fc.Parent = foodBtn

    foodBtn.Activated:Connect(function()
        task.spawn(function()
            SurvivalEngine:TeleportAndPurchase(CONFIG.FoodMerchant, CONFIG.FoodItem, false)
        end)
    end)

    local settingsBtn = Instance.new("TextButton")
    settingsBtn.Size = UDim2.new(1, -6, 0, 20)
    settingsBtn.Position = UDim2.new(0, 0, 0, 396)
    settingsBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
    settingsBtn.Font = Enum.Font.GothamBold
    settingsBtn.Text = "⚙ Settings (ปรับค่า)"
    settingsBtn.TextSize = 8
    settingsBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
    settingsBtn.Parent = leftPanel
    local stc = Instance.new("UICorner")
    stc.CornerRadius = UDim.new(0, 4)
    stc.Parent = settingsBtn

    local sFrame = Instance.new("Frame")
    sFrame.Size = UDim2.fromOffset(240, 435)
    sFrame.Position = UDim2.new(1, 6, 0, 0)
    sFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    sFrame.Visible = false
    sFrame.Parent = frame
    local sfc = Instance.new("UICorner")
    sfc.CornerRadius = UDim.new(0, 8)
    sfc.Parent = sFrame
    local sfs = Instance.new("UIStroke")
    sfs.Color = Color3.fromRGB(70, 70, 95)
    sfs.Parent = sFrame

    local sTitle = Instance.new("TextLabel")
    sTitle.Size = UDim2.new(1, 0, 0, 32)
    sTitle.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
    sTitle.Font = Enum.Font.GothamBold
    sTitle.Text = "  ⚙ BEAR HUB SETTINGS"
    sTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    sTitle.TextSize = 11
    sTitle.TextXAlignment = Enum.TextXAlignment.Left
    sTitle.Parent = sFrame
    local stc2 = Instance.new("UICorner")
    stc2.CornerRadius = UDim.new(0, 8)
    stc2.Parent = sTitle

    local sScroll = Instance.new("ScrollingFrame")
    sScroll.Size = UDim2.new(1, -12, 1, -78)
    sScroll.Position = UDim2.new(0, 6, 0, 38)
    sScroll.BackgroundTransparency = 1
    sScroll.ScrollBarThickness = 3
    sScroll.CanvasSize = UDim2.new(0, 0, 0, #SETTINGS * 32)
    sScroll.Parent = sFrame
    local sLayout = Instance.new("UIListLayout")
    sLayout.Padding = UDim.new(0, 4)
    sLayout.Parent = sScroll

    local refreshers = {}

    for _, def in ipairs(SETTINGS) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 28)
        row.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
        row.Parent = sScroll
        local rowc = Instance.new("UICorner")
        rowc.CornerRadius = UDim.new(0, 4)
        rowc.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 96, 1, 0)
        lbl.Position = UDim2.new(0, 6, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.Text = def.label
        lbl.TextSize = 9
        lbl.TextColor3 = Color3.fromRGB(220, 220, 235)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local function makeBtn(text, x)
            local b = Instance.new("TextButton")
            b.Size = UDim2.fromOffset(22, 20)
            b.Position = UDim2.new(0, x, 0, 4)
            b.BackgroundColor3 = Color3.fromRGB(45, 55, 85)
            b.Font = Enum.Font.GothamBold
            b.Text = text
            b.TextSize = 12
            b.TextColor3 = Color3.fromRGB(240, 240, 255)
            b.Parent = row
            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 4)
            bc.Parent = b
            return b
        end

        local minus = makeBtn("-", 104)
        local box = Instance.new("TextBox")
        box.Size = UDim2.fromOffset(48, 20)
        box.Position = UDim2.new(0, 128, 0, 4)
        box.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
        box.Font = Enum.Font.GothamBold
        box.TextSize = 10
        box.TextColor3 = Color3.fromRGB(255, 215, 0)
        box.ClearTextOnFocus = false
        box.Parent = row
        local boxc = Instance.new("UICorner")
        boxc.CornerRadius = UDim.new(0, 4)
        boxc.Parent = box
        local plus = makeBtn("+", 180)

        local function show()
            box.Text = string.format("%." .. def.dec .. "f", CONFIG[def.key])
        end
        refreshers[def.key] = show

        local function setVal(v)
            v = math.clamp(v, def.min, def.max)
            local m = 10 ^ def.dec
            v = math.floor(v * m + 0.5) / m
            CONFIG[def.key] = v
            show()
            saveSettings()
            if def.key == "CustomWalkSpeed" and getgenv().AdminState.SpeedBoost then
                task.spawn(applyWalkSpeed, plr.Character)
            end
        end

        minus.Activated:Connect(function() setVal(CONFIG[def.key] - def.step) end)
        plus.Activated:Connect(function() setVal(CONFIG[def.key] + def.step) end)
        box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then setVal(n) else show() end
        end)
        show()
    end

    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(1, -12, 0, 26)
    resetBtn.Position = UDim2.new(0, 6, 1, -34)
    resetBtn.BackgroundColor3 = Color3.fromRGB(140, 50, 50)
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.Text = "Reset ค่าเริ่มต้น"
    resetBtn.TextSize = 9
    resetBtn.TextColor3 = Color3.fromRGB(255, 235, 235)
    resetBtn.Parent = sFrame
    local rbc = Instance.new("UICorner")
    rbc.CornerRadius = UDim.new(0, 4)
    rbc.Parent = resetBtn

    resetBtn.Activated:Connect(function()
        for _, def in ipairs(SETTINGS) do
            CONFIG[def.key] = DEFAULTS[def.key]
            refreshers[def.key]()
        end
        saveSettings()
        if getgenv().AdminState.SpeedBoost then task.spawn(applyWalkSpeed, plr.Character) end
    end)

    settingsBtn.Activated:Connect(function()
        sFrame.Visible = not sFrame.Visible
    end)

    local rightPanel = Instance.new("Frame")
    rightPanel.Size = UDim2.new(1, -212, 1, -42)
    rightPanel.Position = UDim2.new(0, 204, 0, 36)
    rightPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    rightPanel.Parent = frame
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 6)
    rc.Parent = rightPanel

    local catBar = Instance.new("ScrollingFrame")
    catBar.Size = UDim2.new(1, -12, 0, 24)
    catBar.Position = UDim2.new(0, 6, 0, 6)
    catBar.BackgroundTransparency = 1
    catBar.ScrollBarThickness = 2
    catBar.CanvasSize = UDim2.new(2.5, 0, 0, 0)
    catBar.Parent = rightPanel

    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection = Enum.FillDirection.Horizontal
    catLayout.Padding = UDim.new(0, 4)
    catLayout.Parent = catBar

    local listScroll = Instance.new("ScrollingFrame")
    listScroll.Size = UDim2.new(1, -12, 0, 238)
    listScroll.Position = UDim2.new(0, 6, 0, 34)
    listScroll.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    listScroll.ScrollBarThickness = 4
    listScroll.Parent = rightPanel
    local lc = Instance.new("UICorner")
    lc.CornerRadius = UDim.new(0, 4)
    lc.Parent = listScroll

    local destLayout = Instance.new("UIListLayout")
    destLayout.Padding = UDim.new(0, 2)
    destLayout.Parent = listScroll

    local currentCat = "Players"

    local function renderDestinations()
        for _, ch in ipairs(listScroll:GetChildren()) do
            if ch:IsA("TextButton") then ch:Destroy() end
        end
        local items = TeleportEngine.Categories[currentCat] or {}
        listScroll.CanvasSize = UDim2.new(0, 0, 0, #items * 24)

        for _, item in ipairs(items) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -4, 0, 22)
            b.BackgroundColor3 = (TeleportEngine.SelectedTarget == item) and Color3.fromRGB(65, 65, 90) or Color3.fromRGB(26, 26, 36)
            b.Font = Enum.Font.Gotham
            b.Text = "  " .. item.Name
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.TextSize = 9
            b.TextColor3 = Color3.fromRGB(220, 220, 235)
            b.Parent = listScroll

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 4)
            c.Parent = b

            b.Activated:Connect(function()
                TeleportEngine.SelectedTarget = item
                if getgenv().AdminState.AutoTPOnSelect then
                    TeleportEngine:TeleportTo(item.Target)
                end
                renderDestinations()
            end)
        end
    end

    local cats = {"Players", "Bandits & Mobs", "Interactables", "Nodes & Mining", "Fast Travel", "Custom"}
    for _, cname in ipairs(cats) do
        local cb = Instance.new("TextButton")
        cb.Size = UDim2.new(0, 80, 1, 0)
        cb.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
        cb.Font = Enum.Font.GothamBold
        cb.Text = cname
        cb.TextSize = 8
        cb.TextColor3 = Color3.fromRGB(210, 210, 230)
        cb.Parent = catBar
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = cb

        cb.Activated:Connect(function()
            currentCat = cname
            TeleportEngine:ScanWorld()
            renderDestinations()
        end)
    end

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.48, -4, 0, 26)
    tpBtn.Position = UDim2.new(0, 6, 0, 280)
    tpBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 75)
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.Text = "Teleport Now"
    tpBtn.TextSize = 9
    tpBtn.TextColor3 = Color3.fromRGB(240, 255, 240)
    tpBtn.Parent = rightPanel
    local tc2 = Instance.new("UICorner")
    tc2.CornerRadius = UDim.new(0, 4)
    tc2.Parent = tpBtn

    tpBtn.Activated:Connect(function()
        if TeleportEngine.SelectedTarget then
            TeleportEngine:TeleportTo(TeleportEngine.SelectedTarget.Target)
        end
    end)

    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0.48, -4, 0, 26)
    scanBtn.Position = UDim2.new(0.52, 2, 0, 280)
    scanBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.Text = "Scan World"
    scanBtn.TextSize = 9
    scanBtn.TextColor3 = Color3.fromRGB(230, 240, 255)
    scanBtn.Parent = rightPanel
    local sc2 = Instance.new("UICorner")
    sc2.CornerRadius = UDim.new(0, 4)
    sc2.Parent = scanBtn

    scanBtn.Activated:Connect(function()
        TeleportEngine:ScanWorld()
        renderDestinations()
    end)

    TeleportEngine:ScanWorld()
    renderDestinations()

    -- Watermark Integrity Guard Loop
    task.spawn(function()
        while gui.Parent and isCurrent() do
            if not title or not title.Parent or not title.Text:find("BEAR HUB") then
                if getgenv().BearHubShutdown then getgenv().BearHubShutdown() end
                break
            end

            rFish(); rParry(); rSurv(); rEsp(); rFarm(); rMouse(); rBri(); rSpd(); rNoc(); rJmp(); rLetter()

            infoLabel.Text = string.format(
                "HP: %d/%d | Hunger: %d%%\nSick: %s (Lv.%d) | Fish: %d/%d\nLetter: %s (%d solved)",
                math.floor(SurvivalEngine.Health),
                math.floor(SurvivalEngine.MaxHealth),
                SurvivalEngine.Hunger,
                tostring(SurvivalEngine.Sickness),
                SurvivalEngine.Stage,
                FishStats.caught, FishStats.casts,
                LetterState.status, LetterState.solved
            )
            task.wait(0.6)
        end
    end)

    return gui
end

local masterGui = buildMasterUI()
getgenv().BearHubGui = masterGui
MouseModule:Apply(getgenv().AdminState.FreeMouse)

table.insert(getgenv().BearHubConns, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not isCurrent() then return end
    if input.KeyCode == CONFIG.ToggleKey then
        if masterGui and masterGui.Parent then
            masterGui.Enabled = not masterGui.Enabled
        end
    end
end))

getgenv().BearHubShutdown = function()
    pcall(function() getgenv().AdminState.Noclip = false end)
    pcall(function() getgenv().AdminState.AutoFish = false end)
    pcall(function() getgenv().AdminState.AutoFarm = false end)
    pcall(function() getgenv().AdminState.AutoParry = false end)
    pcall(function() getgenv().AdminState.AutoLetter = false end)
    pcall(function() GuiService.SelectedObject = nil end)
    pcall(restoreNoclip)
    pcall(function() BanditESP:Clear() end)
    pcall(function() FarmFace.Root = nil; RunService:UnbindFromRenderStep("BearHubFarmFace") end)
    pcall(function() ParrySystem.HoldUntil = 0; rightClick(false) end)
    pcall(function()
        local _, h = getAliveCharacter()
        if h then h.AutoRotate = true end
    end)
    pcall(function() MouseModule:Apply(false) end)
    pcall(function() RunService:UnbindFromRenderStep("BearHubFreeMouse") end)
    pcall(function() FullbrightModule:Apply(false) end)
    if type(getgenv().BearHubConns) == "table" then
        for _, c in ipairs(getgenv().BearHubConns) do
            pcall(function() c:Disconnect() end)
        end
    end
    getgenv().BearHubConns = {}
    pcall(function()
        if masterGui then masterGui:Destroy() end
    end)
    getgenv().BearHubRunId = (getgenv().BearHubRunId or 0) + 1
end
