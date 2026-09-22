--// VantaH | Dandy's World
--// Made by VantaH
--// ESP, twisted and item alerts, auto skill checks and Auto Barnaby for Matcha.
--// Scans workspace.CurrentRoom.*.Monsters, .Items and .Generators.

--// Set to true, or set _G.RESET_TO_DEFAULT_SETTINGS = true before running, to wipe all saved config.
local RESET_TO_DEFAULT_SETTINGS = false
if _G.RESET_TO_DEFAULT_SETTINGS == true then
    RESET_TO_DEFAULT_SETTINGS = true
    _G.RESET_TO_DEFAULT_SETTINGS = nil
end

local ALLOWED_UNIVERSE = 5569032992
if game.GameId ~= ALLOWED_UNIVERSE then
    if type(notify) == "function" then
        pcall(notify, "Dandy World", "Wrong game (universe " .. tostring(game.GameId) .. ") - aborted.", 4)
    end
    return
end

local PLACE_MODE = game.PlaceId == 16552821455 and "main" or game.PlaceId == 16116270224 and "lobby" or "other"

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players and Players.LocalPlayer

if not (Players and Workspace and RunService and LocalPlayer) then
    if type(notify) == "function" then
        pcall(notify, "Dandy's World", "Not in a game yet - rejoin, then run the script again.", 4)
    end
    return
end

if _G.DW_CLEANUP then
    pcall(_G.DW_CLEANUP)
    _G.DW_CLEANUP = nil
end

local VantaUI = (function()
    local ok, source = pcall(readfile, "VantaUI/VantaUI.lua")
    if not (ok and type(source) == "string" and #source > 0) then ok, source = pcall(httpget, "https://raw.githubusercontent.com/VantaHacker/VantaH-Matcha/refs/heads/main/VantaUI.lua") end
    local chunk = ok and type(source) == "string" and loadstring(source)
    if not chunk then return nil end
    return pcall(chunk) and _G.VantaUI or nil
end)()

if not VantaUI then
    if type(notify) == "function" then
        pcall(notify, "Dandy's World", "Could not load VantaUI - aborted.", 4)
    end
    return
end

local UI = {
    GetValue = function(id)
        local Option = VantaUI.Options[id]
        return Option and Option.Value
    end,
    SetValue = function(id, value)
        local Option = VantaUI.Options[id]
        if Option then Option:Set(value) end
    end,
}

function UI.dialog(title, subtitle, heading, size, onClose)
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local position = Vector2.new(math.floor(viewport.X / 2 - size.X / 2), math.floor(viewport.Y / 2 - size.Y / 2))
    local Dialog = VantaUI:CreateWindow({Title = title, SubTitle = subtitle, Size = size, Position = position, MenuKey = false, Sidebar = false, StayOpen = true, Resizable = false, Layer = 40, OnClose = onClose})
    return Dialog, Dialog:AddTab(title):AddSection(heading, "Full")
end

local ITEM_USES = {"Collectible", "Healing", "Machines", "Skill Check", "Speed", "Stamina", "Stealth", "Random Effect", "Distraction"}

local ITEM_INFO = {
    Bandage = {name = "Bandage", rarity = "Rare", use = "Healing", effect = "Heals 1 heart", floor = true, store = true, cost = 60},
    HealthKit = {name = "Health Kit", rarity = "Very Rare", use = "Healing", effect = "Restores all hearts", floor = true, store = true, cost = 100},
    Pop = {name = "Pop", rarity = "Common", use = "Stamina", effect = "+45 stamina", floor = true, store = true, cost = 25},
    PopBottle = {name = "Bottle o' Pop", rarity = "Very Rare", use = "Stamina", effect = "Refills stamina", floor = true, store = true, cost = 85},
    ProteinBar = {name = "Protein Bar", rarity = "Uncommon", use = "Stamina", effect = "+150% stamina regen", floor = true, store = true, cost = 45, duration = 15},
    StaminaCandy = {name = "Stamina Candy", rarity = "Common", use = "Stamina", effect = "+50% stamina regen", floor = true, store = true, cost = 35, duration = 20},
    Chocolate = {name = "Chocolate", rarity = "Common", use = "Stamina", effect = "+25 max stamina, +10% walk speed", floor = true, store = true, cost = 22, duration = 10},
    ChocolateBox = {name = "Box o' Chocolates", rarity = "Very Rare", use = "Stamina", effect = "+25 max stamina, +10% run speed", floor = true, store = true, cost = 88, duration = 10, charges = 5},
    JumperCable = {name = "Jumper Cable", rarity = "Rare", use = "Machines", effect = "Adds a large amount of completion", needsMachine = true, floor = true, store = true, cost = 65},
    Valve = {name = "Valve", rarity = "Ultra Rare", use = "Machines", effect = "Instantly completes the machine", needsMachine = true, floor = false, store = true, cost = 150},
    Instructions = {name = "Instructions", rarity = "Uncommon", use = "Machines", effect = "+100% extraction speed", needsMachine = true, floor = false, store = true, cost = 40, duration = 10},
    ExtractionSpeedCandy = {name = "Extraction Speed Candy", rarity = "Uncommon", use = "Machines", effect = "+50% extraction speed", floor = true, store = true, cost = 35, duration = 5},
    BonBon = {name = "BonBon", rarity = "Rare", use = "Machines", effect = "+50% extraction speed, +25% movement speed", abilityOnly = true, floor = false, store = false, cost = 0, duration = 10},
    SkillCheckCandy = {name = "Skill Check Candy", rarity = "Uncommon", use = "Skill Check", effect = "+25% skill check chance", floor = true, store = true, cost = 42, duration = 15},
    Stopwatch = {name = "Stopwatch", rarity = "Common", use = "Skill Check", effect = "+50 skill check window", needsMachine = true, floor = false, store = true, cost = 18, duration = 15},
    SpeedCandy = {name = "Speed Candy", rarity = "Uncommon", use = "Speed", effect = "+25% walk and run speed", floor = true, store = true, cost = 45, duration = 5},
    ChristmasCookie = {name = "Christmas Cookie", rarity = "Rare", use = "Speed", effect = "+15% speed to nearby Toons", abilityOnly = true, floor = false, store = false, cost = 0, duration = 10},
    DandyEasterEggs = {name = "Dandy's Easter Eggs", rarity = "Rare", use = "Speed", effect = "+15% speed to nearby Toons", abilityOnly = true, floor = false, store = false, cost = 0, duration = 10},
    StealthCandy = {name = "Stealth Candy", rarity = "Common", use = "Stealth", effect = "+25% stealth", floor = true, store = true, cost = 35, duration = 8},
    SmokeBomb = {name = "Smoke Bomb", rarity = "Ultra Rare", use = "Stealth", effect = "Chasing Twisted loses interest", floor = true, store = true, cost = 150, duration = 3},
    EjectButton = {name = "Eject Button", rarity = "Ultra Rare", use = "Speed", effect = "+25 stealth, walk and run speed, removes Slow", floor = true, store = true, cost = 150, duration = 3},
    Gumball = {name = "Gumballs", rarity = "Common", use = "Random Effect", effect = "Random 10% effect", floor = true, store = true, cost = 20, duration = 5, charges = 3},
    Jawbreaker = {name = "Jawbreaker", rarity = "Rare", use = "Random Effect", effect = "Random 50% effect", floor = true, store = true, cost = 58, duration = 20},
    AirHorn = {name = "Air Horn", rarity = "Rare", use = "Distraction", effect = "Lowers stealth, alerts nearby Twisteds", floor = true, store = true, cost = 55, duration = 10},
    Tape = {name = "Tape", rarity = "Common", use = "Collectible", effect = "Gives 10 Tapes", floor = true, store = false, cost = 5},
    Ornament = {name = "Ornament", rarity = "Common", use = "Collectible", effect = "Gives 5 baubles", floor = false, store = false, cost = 5, event = true},
    Pumpkin = {name = "Pumpkin", rarity = "Common", use = "Collectible", effect = "Halloween event pickup", floor = false, store = false, cost = 0, event = true},
    Basket = {name = "Basket", rarity = "Common", use = "Collectible", effect = "Easter event pickup", floor = false, store = false, cost = 0, event = true},
}

local MONSTER_INFO = {

    AstroMonster = { name = "Twisted Astro", rarity = "Main Character" },
    BassieMonster = { name = "Twisted Bassie", rarity = "Main Character" },
    BlottMonster = { name = "Twisted Blot", rarity = "Rare" },
    BlotHand_R = { name = "Twisted Blot Hand", rarity = "Rare" },
    BlotHand_L = { name = "Twisted Blot Hand", rarity = "Rare" },
    BobetteMonster = { name = "Twisted Bobette", rarity = "Main Character" },
    BoxtenMonster = { name = "Twisted Boxten", rarity = "Common" },
    BrightneyMonster = { name = "Twisted Brightney", rarity = "Uncommon" },
    BrushaMonster = { name = "Twisted Brusha", rarity = "Common" },
    CoalMonster = { name = "Twisted Coal", rarity = "Rare" },
    CocoaMonster = { name = "Twisted Cocoa", rarity = "Rare" },
    ConnieMonster = { name = "Twisted Connie", rarity = "Uncommon" },
    CosmoMonster = { name = "Twisted Cosmo", rarity = "Common" },
    DandyMonster = { name = "Twisted Dandy", rarity = "Lethal" },
    DyleMonster = { name = "Twisted Dyle", rarity = "Lethal" },
    EclipseMonster = { name = "Twisted Eclipse", rarity = "Rare" },
    EggsonMonster = { name = "Twisted Eggson", rarity = "Common" },
    FinnMonster = { name = "Twisted Finn", rarity = "Uncommon" },
    FlutterMonster = { name = "Twisted Flutter", rarity = "Rare" },
    FlyteMonster = { name = "Twisted Flyte", rarity = "Uncommon" },
    GigiMonster = { name = "Twisted Gigi", rarity = "Rare" },
    GingerMonster = { name = "Twisted Ginger", rarity = "Uncommon" },
    GlistenMonster = { name = "Twisted Glisten", rarity = "Rare" },
    GoobMonster = { name = "Twisted Goob", rarity = "Rare" },
    GourdyMonster = { name = "Twisted Gourdy", rarity = "Main Character" },
    LooeyMonster = { name = "Twisted Looey", rarity = "Common" },
    PebbleMonster = { name = "Twisted Pebble", rarity = "Main Character" },
    PoppyMonster = { name = "Twisted Poppy", rarity = "Common" },
    RazzleDazzleMonster = { name = "Twisted Razzle & Dazzle", rarity = "Uncommon" },
    RibeccaMonster = { name = "Twisted Ribecca", rarity = "Common" },
    RodgerMonster = { name = "Twisted Rodger", rarity = "Uncommon" },
    RudieMonster = { name = "Twisted Rudie", rarity = "Common" },
    ScrapsMonster = { name = "Twisted Scraps", rarity = "Rare" },
    ShellyMonster = { name = "Twisted Shelly", rarity = "Main Character" },
    ShrimpoMonster = { name = "Twisted Shrimpo", rarity = "Common" },
    SoulvesterMonster = { name = "Twisted Soulvester", rarity = "Uncommon" },
    SproutMonster = { name = "Twisted Sprout", rarity = "Main Character" },
    SquirmMonster = { name = "Twisted Squirm", rarity = "Rare" },
    TeaganMonster = { name = "Twisted Teagan", rarity = "Uncommon" },
    TishaMonster = { name = "Twisted Tisha", rarity = "Common" },
    ToodlesMonster = { name = "Twisted Toodles", rarity = "Uncommon" },
    VeeMonster = { name = "Twisted Vee", rarity = "Main Character" },
    WaxwellMonster = { name = "Twisted Waxwell", rarity = "Rare" },
    YattaMonster = { name = "Twisted Yatta", rarity = "Common" },
}

local ALERT_MONSTERS = {}
for monster, info in pairs(MONSTER_INFO) do
    if not monster:find("^BlotHand") then
        table.insert(ALERT_MONSTERS, {key = "alert" .. (monster:gsub("Monster$", "")), monster = monster, label = (info.name:gsub("^Twisted ", "")), rarity = info.rarity})
    end
end
table.sort(ALERT_MONSTERS, function(a, b) return a.label < b.label end)

local ALERT_ITEMS = {}
local eventItems = {}
for item, info in pairs(ITEM_INFO) do
    if info.event then
        table.insert(eventItems, item)
    else
        table.insert(ALERT_ITEMS, {key = "itemAlert" .. item, items = {item}, label = info.name, use = info.use})
    end
end
table.insert(ALERT_ITEMS, {key = "itemAlertEvent", items = eventItems, label = "Event", use = "Collectible"})
table.sort(ALERT_ITEMS, function(a, b) return a.label < b.label end)

local ALERT_BY_MONSTER = {}
for _, entry in ipairs(ALERT_MONSTERS) do
    ALERT_BY_MONSTER[entry.monster] = entry.key
end

local ALERT_BY_ITEM = {}
for _, entry in ipairs(ALERT_ITEMS) do
    for _, item in ipairs(entry.items) do
        ALERT_BY_ITEM[item] = entry.key
    end
end

local SETTINGS = {
    enabled = true,
    maxDistance = 1500,
    showMonsters = true,
    showItems = true,
    showResearchCapsules = true,
    showTapes = true,
    showGenerators = true,
    showCompletedGenerators = false,
    showInUseGenerators = true,
    showName = true,
    showDistance = true,
    showRoom = false,
    showMachineType = true,
    showTwistedRarity = true,
    showAbilityTimer = true,
    showSquirmWarning = true,
    showItemRarity = true,
    showPlayerHealth = true,
    aggressiveAutoFarm = false,
    allowFarmWithPlayers = false,
    tweenWalkSpeed = 50,
    floorLimit = 15,
    unlimitedFloors = false,
    farmWarningAccepted = false,
    masteryFarm = false,
    masterySelect = true,
    masteryEnd = true,
    farmAutoResume = true,
    farmHideOnTeleport = true,
    farmHealItems = true,
    farmExtractionItems = true,
    farmCapsules = true,
    farmResearchTwisteds = true,
    farmSkipResearched = true,
    farmIgnoreTwistedsTravel = false,
    farmTreadmillRun = true,
    farmTreadmillStopAt = 30,
    resumeAutoFarm = false,
    resumeAutoFarmAt = 0,
    showPlayerStamina = true,
    lowStaminaThreshold = 50,
    showDot = true,
    showTracer = false,
    scanInterval = 0.5,
    updateInterval = 0.01,
    maxVisible = 0,
    resolveBudget = 2,
    autoSkillCheck = true,
    skillCheckRandom = true,
    skillCheckAim = 15,
    skillCheckLead = 35,
    treadmillTapRate = 24,
    autoBarnaby = true,
    barnabyCollectCoins = true,
    barnabyRiskyCoins = false,
    autoSquirmEscape = true,
    autoAbility = true,
    squirmTapRate = 14,
    alertTracers = true,
    alertDandy = true,
    alertDyle = true,
    alertGoob = true,
    alertScraps = true,
    alertGigi = true,
    alertSquirm = false,
    alertWaxwell = true,
    alertPebble = true,
    alertVee = true,
    alertAstro = false,
    alertSprout = false,
    alertShelly = false,
    alertGourdy = false,
    alertBobette = false,
    alertBassie = false,
    itemAlertTracers = true,
    itemAlertTape = false,
    itemAlertBandage = true,
    itemAlertHealthKit = true,
    itemAlertChocolateBox = true,
    itemAlertJumperCable = true,
    itemAlertPopBottle = true,
    itemAlertSmokeBomb = false,
    itemAlertJawbreaker = false,
    itemAlertEjectButton = false,
    itemAlertAirHorn = false,
    itemAlertEvent = true,
    webhooksEnabled = false,
    espKey = 0x4C,
    menuKey = 0xA1,
}

for _, entry in ipairs(ALERT_MONSTERS) do
    if SETTINGS[entry.key] == nil then SETTINGS[entry.key] = false end
end
for _, entry in ipairs(ALERT_ITEMS) do
    if SETTINGS[entry.key] == nil then SETTINGS[entry.key] = false end
end

local COLORS = {
    Monsters = Color3.fromRGB(255, 70, 70),
    Items = Color3.fromRGB(70, 255, 120),
    ItemAlert = Color3.fromRGB(255, 20, 147),
    ResearchCapsules = Color3.fromRGB(30, 70, 200),
    Tapes = Color3.fromRGB(255, 255, 255),
    Generators = Color3.fromRGB(255, 220, 70),
    CompletedGenerator = Color3.fromRGB(120, 200, 255),
    InUseGenerator = Color3.fromRGB(255, 244, 170),
}

local HttpService = game:GetService("HttpService")
local CONFIG_FOLDER = "DW"
local CONFIG_PATH = "DW/config.json"

local SAVED_KEYS = {
    "enabled",
    "maxDistance",
    "showMonsters",
    "showItems",
    "showResearchCapsules",
    "showTapes",
    "showGenerators",
    "showCompletedGenerators",
    "showInUseGenerators",
    "showName",
    "showDistance",
    "showRoom",
    "showMachineType",
    "showTwistedRarity",
    "showAbilityTimer",
    "showSquirmWarning",
    "showItemRarity",
    "showPlayerHealth",
    "allowFarmWithPlayers",
    "tweenWalkSpeed",
    "floorLimit",
    "unlimitedFloors",
    "farmWarningAccepted",
    "masteryFarm",
    "masterySelect",
    "masteryEnd",
    "farmAutoResume",
    "farmHideOnTeleport",
    "farmHealItems",
    "farmExtractionItems",
    "farmCapsules",
    "farmResearchTwisteds",
    "farmSkipResearched",
    "farmIgnoreTwistedsTravel",
    "farmTreadmillRun",
    "farmTreadmillStopAt",
    "resumeAutoFarm",
    "resumeAutoFarmAt",
    "showPlayerStamina",
    "lowStaminaThreshold",
    "showDot",
    "showTracer",
    "scanInterval",
    "updateInterval",
    "maxVisible",
    "autoSkillCheck",
    "skillCheckRandom",
    "skillCheckAim",
    "skillCheckLead",
    "treadmillTapRate",
    "autoBarnaby",
    "barnabyCollectCoins",
    "barnabyRiskyCoins",
    "autoSquirmEscape",
    "autoAbility",
    "squirmTapRate",
    "alertTracers",
    "itemAlertTracers",
    "espKey",
    "menuKey",
    "webhooksEnabled",
}

for _, entry in ipairs(ALERT_MONSTERS) do
    table.insert(SAVED_KEYS, entry.key)
end
for _, entry in ipairs(ALERT_ITEMS) do
    table.insert(SAVED_KEYS, entry.key)
end

local SAVED_COLORS = { "Monsters", "Items", "ItemAlert", "ResearchCapsules", "Tapes", "Generators", "CompletedGenerator", "InUseGenerator" }

local function saveConfig()
    if type(writefile) ~= "function" then
        return
    end

    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end

        local data = { colors = {} }

        for _, key in ipairs(SAVED_KEYS) do
            data[key] = SETTINGS[key]
        end

        for _, key in ipairs(SAVED_COLORS) do
            local color = COLORS[key]
            data.colors[key] = { r = color.R, g = color.G, b = color.B }
        end

        writefile(CONFIG_PATH, HttpService:JSONEncode(data))
    end)
end

local function loadConfig()
    if RESET_TO_DEFAULT_SETTINGS then
        if type(delfile) == "function" and type(isfile) == "function" then
            pcall(function()
                if isfile(CONFIG_PATH) then
                    delfile(CONFIG_PATH)
                end
            end)
        end
        return
    end

    if type(readfile) ~= "function" or type(isfile) ~= "function" then
        return
    end

    pcall(function()
        if not isfile(CONFIG_PATH) then
            return
        end

        local data = HttpService:JSONDecode(readfile(CONFIG_PATH))
        if type(data) ~= "table" then
            return
        end

        for _, key in ipairs(SAVED_KEYS) do
            local value = data[key]
            if type(value) == type(SETTINGS[key]) then
                SETTINGS[key] = value
            end
        end

        if type(data.colors) == "table" then
            for _, key in ipairs(SAVED_COLORS) do
                local color = data.colors[key]
                if type(color) == "table"
                    and type(color.r) == "number"
                    and type(color.g) == "number"
                    and type(color.b) == "number" then
                    COLORS[key] = Color3.new(color.r, color.g, color.b)
                end
            end
        end
    end)
end

loadConfig()

local SAVE_DEBOUNCE = 1
local configSnapshot = nil
local configDirtyAt = 0

local function syncConfigSnapshot()
    local changed = false

    for _, key in ipairs(SAVED_KEYS) do
        local value = SETTINGS[key]
        if configSnapshot[key] ~= value then
            configSnapshot[key] = value
            changed = true
        end
    end

    for _, key in ipairs(SAVED_COLORS) do
        local color = COLORS[key]
        local stored = configSnapshot.colors[key]
        if not stored
            or math.abs(stored.R - color.R) > 0.0005
            or math.abs(stored.G - color.G) > 0.0005
            or math.abs(stored.B - color.B) > 0.0005 then
            configSnapshot.colors[key] = { R = color.R, G = color.G, B = color.B }
            changed = true
        end
    end

    return changed
end

local function autoSaveConfig()
    if configSnapshot == nil then
        configSnapshot = { colors = {} }
        syncConfigSnapshot()
        return
    end

    if syncConfigSnapshot() then
        configDirtyAt = tick()
    elseif configDirtyAt > 0 and tick() - configDirtyAt >= SAVE_DEBOUNCE then
        configDirtyAt = 0
        saveConfig()
    end
end

local FOLDERS = {
    { key = "Monsters", enabledKeys = { "showMonsters" } },
    { key = "Items", enabledKeys = { "showItems", "showResearchCapsules", "showTapes" } },
    { key = "Generators", enabledKeys = { "showGenerators" } },
}

FOLDERS.BLOT_ZONE_PREFIX = "BlotHandZone_"
FOLDERS.BLOT_ZONE_MAX = 10
FOLDERS.BLOT_HAND_PREFIX = "BlotHand"

local CATEGORY_ENABLED = {
    Monsters = "showMonsters",
    Items = "showItems",
    ResearchCapsules = "showResearchCapsules",
    Tapes = "showTapes",
    Generators = "showGenerators",
}

local ALERT_DURATION = 5

local function alertKeyFor(category, name)
    if category == "Monsters" then
        return ALERT_BY_MONSTER[name], "twisted"
    end

    if category == "Items" or category == "Tapes" then
        return ALERT_BY_ITEM[name], "item"
    end

    return nil, nil
end

local function alertEnabledFor(category, name)
    local key = alertKeyFor(category, name)
    return key ~= nil and SETTINGS[key] == true
end

local function anyAlertEnabled(list)
    for _, entry in ipairs(list) do
        if SETTINGS[entry.key] then
            return true
        end
    end

    return false
end

local alertSeen = {}

local ITEM_CATEGORIES = {
    ResearchCapsule = "ResearchCapsules",
    Tape = "Tapes",
    FakeCapsule = false,
}

local function anyEnabled(keys)
    for _, key in ipairs(keys) do
        if SETTINGS[key] then
            return true
        end
    end

    return false
end

local TARGET_ICHOR_SIZE = Vector3.new(6.22, 3.07, 3.07)
local SIZE_TOLERANCE = 0.05
local VK_SPACE = 0x20
local SPACE_HOLD = 0.05
local SPACE_MIN_HOLD = 0.015
local SKILL_PRESS_COOLDOWN = 0.25
local SKILL_FIND_INTERVAL = 0.35
local lastSkillCheckPress = 0
local lastTreadmillTap = 0
local cachedParts = nil
local lastSkillCheckFind = 0

local tracked = {}
local activeKeys = {}
local lastScan = 0
local lastUpdate = 0
local currentResolveBudget = 0

local PART_CLASSES = {
    BasePart = true,
    Part = true,
    MeshPart = true,
    UnionOperation = true,
    WedgePart = true,
    CornerWedgePart = true,
    TrussPart = true,
}

local POSITION_CHILD_NAMES = {
    "HumanoidRootPart",
    "RootPart",
    "Head",
    "Handle",
    "Main",
    "Hitbox",
    "Pickup",
    "MeshPart",
    "Part",
    "Base",
    "Root",
    "Ichor",
    "Position",
    "CFrame",
    "WorldPosition",
    "WorldCFrame",
}

local SKILL_MARKER_NAMES = {
    Marker = true,
    Needle = true,
    Cursor = true,
    Pointer = true,
    Line = true,
    ShrinkingCircle = true,
}

local SKILL_GOLD_NAMES = {
    GoldArea = true,
    PerfectArea = true,
    YellowCircle = true,
}

local SKILL_GREY_NAMES = {
    GreyCircle = true,
    GrayCircle = true,
}

local SKILL_HOLE_NAMES = {
    CenterHole = true,
    BlackCircle = true,
    Center = true,
}

local SKILL_REQUIRED_NAMES = {
    RequiredArea = true,
    SuccessArea = true,
    SafeArea = true,
    HitArea = true,
    GoodArea = true,
    Goal = true,
    Zone = true,
}

local function isGuiVisible(instance)
    return instance ~= nil
end

local function readScreenRect(instance)
    return instance.AbsolutePosition ~= nil
end

local function hasScreenRect(instance)
    if not instance then
        return false
    end

    local ok, hasRect = pcall(readScreenRect, instance)
    return ok and hasRect == true
end

local function findNamedScreenObject(root, names)
    if not root then
        return nil
    end

    for name in pairs(names) do
        local direct = root:FindFirstChild(name)
        if direct and hasScreenRect(direct) then
            return direct
        end
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if names[descendant.Name] and hasScreenRect(descendant) then
            return descendant
        end
    end

    return nil
end

local function findSkillCheckParts(frame)
    if not frame then
        return nil
    end

    local marker = findNamedScreenObject(frame, SKILL_MARKER_NAMES)
    local gold = findNamedScreenObject(frame, SKILL_GOLD_NAMES)
    local required = findNamedScreenObject(frame, SKILL_REQUIRED_NAMES)

    if not marker or not (gold or required) then
        return nil
    end

    return {
        frame = frame,
        marker = marker,
        gold = gold or required,
        required = required,
        grey = findNamedScreenObject(frame, SKILL_GREY_NAMES),
        hole = findNamedScreenObject(frame, SKILL_HOLE_NAMES),
        circle = marker.Name == "ShrinkingCircle" or (gold and gold.Name == "YellowCircle"),
    }
end

local BAR_RANDOM_MIN = 0.35
local BAR_RANDOM_MAX = 0.65
local BAR_CHECK_GAP = 0.35
local BAR_MOTION_GRACE = 0.25
local BAR_MAX_SPEED = 3000
local CIRCLE_MAX_RATE = 20000
local CIRCLE_FALLBACK_BAND = 12

local barLastX = nil
local barLastTime = 0
local barLastMove = 0
local barVelocity = 0
local barPressed = false
local barAimFrac = 0

local circleLastSize = nil
local circleLastTime = 0
local circleLastMove = 0
local circleRate = 0
local circlePressed = false
local circleAimFrac = 0
local sweepStart = { barX = 0, barT = 0, circleSize = 0, circleT = 0, circleFrame = 0.005 }

local function rollAimFraction()
    if SETTINGS.skillCheckRandom then
        return BAR_RANDOM_MIN + math.random() * (BAR_RANDOM_MAX - BAR_RANDOM_MIN)
    end

    return math.clamp(SETTINGS.skillCheckAim or 15, 0, 100) / 100
end

local function rollBarAim()
    barPressed = false
    barVelocity = 0
    barAimFrac = rollAimFraction()
end

local function rollCircleAim()
    circlePressed = false
    circleRate = 0
    circleAimFrac = rollAimFraction()
end

local function sampleBar(marker)
    local pos = marker.AbsolutePosition
    if not pos then
        return false
    end

    local now = tick()
    local x = pos.X

    if barLastX == nil then
        barLastX, barLastTime, barLastMove = x, now, 0
        return false
    end

    local dx = x - barLastX

    if math.abs(dx) > 0.5 then
        local frame = now - barLastTime

        if now - barLastMove > BAR_CHECK_GAP then
            rollBarAim()
            sweepStart.barX, sweepStart.barT = x, now
        else
            if barVelocity ~= 0 and (dx > 0) ~= (barVelocity > 0) then
                sweepStart.barX, sweepStart.barT = barLastX, barLastTime
            end

            local elapsed = now - sweepStart.barT
            if elapsed >= 0.03 then
                barVelocity = (x - sweepStart.barX) / elapsed
            elseif frame > 0 then
                barVelocity = dx / frame
            end
        end

        barLastMove = now
        barLastX, barLastTime = x, now
    end

    return now - barLastMove <= BAR_MOTION_GRACE
end

local function circleDiameter(part)
    local size = part.AbsoluteSize
    if size and size.X > 0 then return size.X end
    local container = part.Parent
    local position = part.AbsolutePosition
    if not (container and position) then return nil end
    local corner = container.AbsolutePosition
    if not corner then return nil end
    local shadow = container.Parent and container.Parent:FindFirstChild("Shadow")
    local shadowPosition = shadow and shadow.AbsolutePosition
    local width = shadowPosition and (corner.X - shadowPosition.X) / 0.1 or 280
    if width <= 0 then width = 280 end
    return 2 * (corner.X + width / 2 - position.X)
end

local function sampleCircle(marker)
    local value = circleDiameter(marker)
    if not value then
        return false, 0
    end

    local now = tick()

    if circleLastSize == nil then
        circleLastSize, circleLastTime, circleLastMove = value, now, 0
        return false, 0
    end

    local delta = value - circleLastSize

    if math.abs(delta) > 0.5 then
        local frame = now - circleLastTime

        if now - circleLastMove > BAR_CHECK_GAP then
            rollCircleAim()
            sweepStart.circleSize, sweepStart.circleT = value, now
        else
            local elapsed = now - sweepStart.circleT
            if elapsed >= 0.03 then
                circleRate = (value - sweepStart.circleSize) / elapsed
            elseif frame > 0 then
                circleRate = delta / frame
            end

            if frame > 0 then
                sweepStart.circleFrame = frame
            end
        end

        circleLastMove = now
        circleLastSize, circleLastTime = value, now
    end

    return now - circleLastMove <= BAR_MOTION_GRACE, sweepStart.circleFrame
end

local function shouldPressCircle(parts)
    local marker, yellow = parts.marker, parts.gold
    local moving, dt = sampleCircle(marker)

    if circlePressed or not moving then
        return false
    end

    local markerSize = circleDiameter(marker)
    local yellowOuter = yellow and circleDiameter(yellow)
    if not (markerSize and yellowOuter) then
        return false
    end

    local yellowInner = 0

    if parts.hole then
        yellowInner = circleDiameter(parts.hole) or 0
    end

    if yellowInner <= 0 or yellowInner >= yellowOuter then
        yellowInner = math.max(0, yellowOuter - CIRCLE_FALLBACK_BAND)
    end

    local rate = math.clamp(circleRate, -CIRCLE_MAX_RATE, CIRCLE_MAX_RATE)
    local predicted = markerSize + rate * (SETTINGS.skillCheckLead / 1000)
    local aim = yellowOuter - circleAimFrac * (yellowOuter - yellowInner)
    local press = predicted <= aim and predicted >= yellowInner

    if not press and parts.grey and dt > 0 and rate < 0 then
        local greySize = circleDiameter(parts.grey)

        if greySize then
            local inGrey = predicted <= greySize and predicted > yellowOuter
            if inGrey and predicted + rate * dt < yellowInner then
                press = true
            end
        end
    end

    if press then
        circlePressed = true
    end

    return press
end

local function shouldPressBar(parts)
    local marker, gold, required = parts.marker, parts.gold, parts.required
    local moving = sampleBar(marker)

    if barPressed or not moving then
        return false
    end

    local markerPos = marker.AbsolutePosition
    local goldPos, goldSize = gold.AbsolutePosition, gold.AbsoluteSize
    if not (markerPos and goldPos and goldSize) then
        return false
    end

    local reqPos = required and required.AbsolutePosition
    local goldStart = goldPos.X
    local goldWidth = goldSize.X
    if goldWidth <= 0 and reqPos and required ~= gold then
        goldWidth = goldStart - reqPos.X
    end
    local goldFinish = goldStart + goldWidth
    if goldFinish <= goldStart then
        return false
    end

    local velocity = math.clamp(barVelocity, -BAR_MAX_SPEED, BAR_MAX_SPEED)
    local predicted = markerPos.X + velocity * (SETTINGS.skillCheckLead / 1000)
    local forward = velocity >= 0
    local aim

    if forward then
        aim = goldStart + barAimFrac * (goldFinish - goldStart)
    else
        aim = goldFinish - barAimFrac * (goldFinish - goldStart)
    end

    local press = false

    if forward then
        press = predicted >= aim and predicted <= goldFinish
    else
        press = predicted <= aim and predicted >= goldStart
    end

    if not press and required then
        local reqSize = required.AbsoluteSize
        local reqWidth = reqSize and reqSize.X or 0
        if reqWidth <= 0 then
            reqWidth = goldWidth * 3
        end

        if reqPos then
            local pastGold

            if forward then
                pastGold = predicted > goldFinish
            else
                pastGold = predicted < goldStart
            end

            if pastGold and predicted >= reqPos.X and predicted <= reqPos.X + reqWidth then
                press = true
            end
        end
    end

    if press then
        barPressed = true
    end

    return press
end

local function shouldPressSkillCheck(parts)
    if parts.circle then
        return shouldPressCircle(parts)
    end

    return shouldPressBar(parts)
end

local function cacheSkillCheckParts(parts)
    cachedParts = parts
    return parts
end

local function clearSkillCheckCache()
    cachedParts = nil
end

local function cachedSkillCheckIsValid()
    return cachedParts ~= nil
        and cachedParts.frame.Parent
        and cachedParts.marker.Parent
        and cachedParts.gold.Parent
        and hasScreenRect(cachedParts.marker)
        and hasScreenRect(cachedParts.gold)
end

local function trySkillCheckFrame(frame)
    if not frame or not isGuiVisible(frame) then
        return nil
    end

    return findSkillCheckParts(frame)
end

local function getSkillCheckFrame()
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        clearSkillCheckCache()
        return nil
    end

    local circleGui = playerGui:FindFirstChild("CircleSkillCheckGui")

    if cachedParts and (circleGui ~= nil) ~= (cachedParts.circle == true) then
        clearSkillCheckCache()
    end

    if cachedSkillCheckIsValid() then
        return cachedParts
    end

    clearSkillCheckCache()

    local parts = trySkillCheckFrame(circleGui)
    if parts then
        return cacheSkillCheckParts(parts)
    end

    local now = tick()
    if now - lastSkillCheckFind < SKILL_FIND_INTERVAL then
        return nil
    end

    lastSkillCheckFind = now

    local screenGui = playerGui:FindFirstChild("ScreenGui")
    local menu = screenGui and screenGui:FindFirstChild("Menu")
    parts = trySkillCheckFrame(menu and menu:FindFirstChild("SkillCheckFrame"))
    if parts then
        return cacheSkillCheckParts(parts)
    end

    return nil
end
local spaceHeldUntil = 0

local function releaseSpaceIfDue()
    if spaceHeldUntil > 0 and tick() >= spaceHeldUntil then
        spaceHeldUntil = 0
        pcall(keyrelease, VK_SPACE)
    end
end

local function gameTyping()
    local ok, typing = pcall(function()
        return VantaUI.GameTyping and VantaUI.GameTyping()
    end)
    return ok and typing == true
end

local function robloxFocused()
    if type(isrbxactive) ~= "function" then
        return true
    end

    local ok, active = pcall(isrbxactive)
    return not ok or active ~= false
end

local function pressSpace(hold)
    if type(keypress) ~= "function" or type(keyrelease) ~= "function" then
        return
    end

    if spaceHeldUntil > 0 then
        pcall(keyrelease, VK_SPACE)
        spaceHeldUntil = 0
    end

    if not robloxFocused() or gameTyping() then
        return
    end

    pcall(keypress, VK_SPACE)
    spaceHeldUntil = tick() + (hold or SPACE_HOLD)
end
local function isTreadmillTapGui(gui)
    return gui and isGuiVisible(gui)
end

local function getTreadmillTapGui()
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local gui = playerGui and playerGui:FindFirstChild("TreadmillTapSkillCheckGui")

    if isTreadmillTapGui(gui) then
        return gui
    end

    return nil
end

local function treadmillIsComplete(gui)
    local frame = gui:FindFirstChild("TapSkillCheckFrame")
    local container = frame and frame:FindFirstChild("Container")
    local counter = container and container:FindFirstChild("TapCounter")
    local text = counter and counter.Text

    if type(text) ~= "string" then
        return false
    end

    local done, needed = text:match("^%s*(%d+)%s*/%s*(%d+)%s*$")
    if not done then
        return false
    end

    return tonumber(done) >= tonumber(needed)
end

local function doTreadmillTapSkillCheck(now)
    local gui = getTreadmillTapGui()
    if not gui then
        return false
    end

    if treadmillIsComplete(gui) then
        return true
    end

    local tapDelay = 1 / (SETTINGS.treadmillTapRate or 6)
    if now - lastTreadmillTap >= tapDelay then
        pressSpace(math.clamp(tapDelay * 0.4, SPACE_MIN_HOLD, SPACE_HOLD))
        lastTreadmillTap = now
    end

    return true
end
local BARNABY = {
    GRAVITY = 225,
    MAX_FALL = -120,
    JUMP_ADD = 48,
    JUMP_MIN = 60,
    JUMP_RISE = 8,
    SCROLL_SPEED = 30,
    ARENA_HALF = 15,
    FISH_HALF = 0.57,
    COLLISION_PAD = 0.25,
    COIN_REACH_PAD = 0.6,
    STEP = 1 / 60,
    HORIZON_STEPS = 48,
    LATENCY_MIN = 0.003,
    LATENCY_MAX = 0.025,
    PRESS_GAP = 0.1,
    PRESS_HOLD = 0.03,
    HOVER_PAD = 0.8,
    SAFE_MARGIN = 2,
    MARGIN_WEIGHT = 200,
    COIN_REWARD = 300,
    DEATH_COST = 1000000,
    DEFER_OPTIONS = 6,
    DECISION_TOLERANCE = 50,
    STALL_TIMEOUT = 0.25,
    SAFE_PRESS_GAP = 0.1,
    SAFE_COIN_REWARD = 300,
    SAFE_SAFE_MARGIN = 2,
    RISKY_PRESS_GAP = 0.07,
    RISKY_COIN_REWARD = 900,
    RISKY_SAFE_MARGIN = 1.5,
    DECISION_INTERVAL = 0.008,
    DEFER_SPACING = 0.012,
    TRACK_GAIN = 0.15,
    TRACK_THRESHOLD = 0.25,
    TRACK_THRESHOLD_SPEED = 0.004,
    TRACK_JUMP_DV = 30,
    BOX_SLOP = 0.03,
    NARROW_FISH_HALF = 0.45,
    NARROW_PAD_SCALE = 0.08,
    NARROW_PAD_MIN = 0.05,
    NARROW_MARGIN_SCALE = 0.35,
    NARROW_MARGIN_MIN = 0.4,
}
BARNABY.LATENCY_NOMINAL = (BARNABY.LATENCY_MIN + BARNABY.LATENCY_MAX) * 0.5
BARNABY.sortByX = function(a, b)
    return a.x < b.x
end
local barnabyTrack = { y = nil, v = 0, t = 0 }
local barnabyLastDecision = 0
local barnabyLastPress = 0
local barnabyObstacleSignature = nil
local barnabyLastMotion = 0
local barnabyFocusWarned = false

local function getBarnabyWorld()
    if PLACE_MODE == "other" then
        return nil
    end

    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return nil
    end

    if PLACE_MODE == "main" then
        local clientUi = playerGui:FindFirstChild("ClientUI")
        local window = clientUi and clientUi:FindFirstChild("GameWindow")
        local viewport = window and window:FindFirstChild("ViewportFrame")
        return viewport and viewport:FindFirstChild("WorldModel")
    end

    local surface = playerGui:FindFirstChild("SurfaceGui")
    local viewport = surface and surface:FindFirstChild("ViewportFrame")
    return viewport and viewport:FindFirstChild("WorldModel")
end

local function isUnitPart(size)
    return size ~= nil
        and math.abs(size.X - 1) < 0.01
        and math.abs(size.Y - 1) < 0.01
        and math.abs(size.Z - 1) < 0.01
end

local function readBarnabyObstacle(model)
    local obstacle = {}

    for _, part in ipairs(model:GetChildren()) do
        local position = part.Position
        local size = part.Size

        if position and size then
            if part.Name == "BarnabyCoin" then
                obstacle.coinX = position.X
                obstacle.coinY = position.Y
                obstacle.coinRadius = size.Y * 0.5
            elseif size.X > 1.5 then
                local bottomEdge = position.Y - size.Y * 0.5
                local topEdge = position.Y + size.Y * 0.5
                local halfWidth = size.X * 0.5
                local bendy = part:FindFirstChild("BendySeaweed")
                local bendyPosition = bendy and bendy.Position
                local bendySize = bendy and bendy.Size
                local hasBendy = bendyPosition ~= nil and bendySize ~= nil

                if hasBendy then
                    halfWidth = math.max(halfWidth, bendySize.X * 0.5)
                end

                if bottomEdge < -BARNABY.ARENA_HALF + 1 then
                    obstacle.x = position.X
                    obstacle.halfWidth = math.max(obstacle.halfWidth or 0, halfWidth)
                    obstacle.gapBottom = hasBendy and math.max(topEdge, bendyPosition.Y + bendySize.Y * 0.5) or topEdge
                elseif topEdge > BARNABY.ARENA_HALF - 1 then
                    obstacle.x = position.X
                    obstacle.halfWidth = math.max(obstacle.halfWidth or 0, halfWidth)
                    obstacle.gapTop = hasBendy and math.min(bottomEdge, bendyPosition.Y - bendySize.Y * 0.5) or bottomEdge
                end
            end
        end
    end

    if obstacle.x and obstacle.gapBottom and obstacle.gapTop then
        return obstacle
    end

    return nil
end

local function readBarnabyWorld(world)
    local fish = nil
    local obstacles = {}

    for _, child in ipairs(world:GetChildren()) do
        local className = child.ClassName

        if className == "Part" then
            if not fish and isUnitPart(child.Size) then
                fish = child
            end
        elseif className == "Model" and child.Name == "ObstacleSet" then
            local obstacle = readBarnabyObstacle(child)
            if obstacle then
                obstacles[#obstacles + 1] = obstacle
            end
        end
    end

    table.sort(obstacles, BARNABY.sortByX)

    return fish, obstacles
end

local function barnabyHoverFloor(sim, t, coinTaken)
    local fishX = sim.fishX

    for index, obstacle in ipairs(sim.obstacles) do
        local x = obstacle.x - BARNABY.SCROLL_SPEED * t

        if x + obstacle.halfWidth + BARNABY.FISH_HALF > fishX - BARNABY.FISH_HALF then
            local low = obstacle.gapBottom + BARNABY.FISH_HALF + BARNABY.HOVER_PAD
            local high = obstacle.gapTop - BARNABY.FISH_HALF - BARNABY.HOVER_PAD - BARNABY.JUMP_RISE
            local want = (obstacle.gapBottom + obstacle.gapTop) * 0.5 - BARNABY.JUMP_RISE * 0.5

            if sim.collectCoins and obstacle.coinY and not coinTaken[index]
                and obstacle.coinX - BARNABY.SCROLL_SPEED * t > fishX - obstacle.coinReach then
                want = obstacle.coinY - BARNABY.JUMP_RISE + 1
            end

            if high < low then
                return low
            end

            return math.clamp(want, low, high)
        end
    end

    return -BARNABY.JUMP_RISE * 0.5
end

local function barnabyPolicyWantsJump(sim, t, y, velocity, coinTaken)
    if velocity > 0 then
        return false
    end

    local lead = BARNABY.LATENCY_NOMINAL + BARNABY.STEP
    local predicted = y + velocity * lead - 0.5 * BARNABY.GRAVITY * lead * lead
    return predicted <= barnabyHoverFloor(sim, t, coinTaken)
end

local function advanceBarnaby(y, velocity, dt)
    if dt <= 0 then
        return y, velocity
    end

    local nextVelocity = velocity - BARNABY.GRAVITY * dt
    if nextVelocity >= BARNABY.MAX_FALL then
        return y + velocity * dt - 0.5 * BARNABY.GRAVITY * dt * dt, nextVelocity
    end

    local toCap = (velocity - BARNABY.MAX_FALL) / BARNABY.GRAVITY
    if toCap < 0 then
        toCap = 0
    end

    y = y + velocity * toCap - 0.5 * BARNABY.GRAVITY * toCap * toCap
    return y + BARNABY.MAX_FALL * (dt - toCap), BARNABY.MAX_FALL
end

local function barnabyFishHalf(velocity)
    local angle = 1.5707963267948966 * ((velocity / 60 + 2) / 4 - 0.5)
    return 0.4 * (math.abs(math.cos(angle)) + math.abs(math.sin(angle))) + BARNABY.BOX_SLOP
end

local function barnabyRefreshGravity()
    local multiplier = 0.75
    local info = Workspace:FindFirstChild("Info")

    if info then
        local configured = info:GetAttribute("BarnabyGravity")
        if type(configured) == "number" then
            multiplier = configured
        end

        if info:GetAttribute("BarnabyGravityFromSkillCheck") == true then
            local strength = info:GetAttribute("BarnabyGravityStrength")
            if type(strength) ~= "number" then
                strength = 0.5
            end

            local character = LocalPlayer and LocalPlayer.Character
            local stats = character and character:FindFirstChild("Stats")
            local chanceValue = stats and stats:FindFirstChild("SkillCheckChance")
            local chance = chanceValue and chanceValue.Value or 15
            if type(chance) ~= "number" then
                chance = 15
            end

            multiplier = multiplier * (1 - math.clamp(chance, 0, 100) / 100 * math.clamp(strength, 0, 1))
        end
    end

    multiplier = math.max(multiplier, 0.05)
    BARNABY.GRAVITY = 300 * multiplier
    BARNABY.JUMP_RISE = BARNABY.JUMP_MIN * BARNABY.JUMP_MIN / (2 * BARNABY.GRAVITY)
end

local function barnabyTrackUpdate(now, y)
    local track = barnabyTrack

    if track.y == nil then
        track.y = y
        track.v = 0
        track.t = now
        return
    end

    if math.abs(y - track.y) < 0.000001 then
        return
    end

    local dt = now - track.t
    if dt <= 0 then
        return
    end

    local predictedY, predictedV = advanceBarnaby(track.y, track.v, dt)
    local residual = y - predictedY
    local intervalVelocity = (y - track.y) / dt
    local threshold = BARNABY.TRACK_THRESHOLD + math.abs(predictedV) * BARNABY.TRACK_THRESHOLD_SPEED

    if residual > threshold and intervalVelocity > predictedV + BARNABY.TRACK_JUMP_DV then
        local _, midVelocity = advanceBarnaby(track.y, track.v, dt * 0.5)
        local launch = math.max(math.max(0, midVelocity) + BARNABY.JUMP_ADD, BARNABY.JUMP_MIN)
        track.v = math.max(BARNABY.MAX_FALL, launch - BARNABY.GRAVITY * dt * 0.5)
    else
        track.v = math.clamp(predictedV + BARNABY.TRACK_GAIN * residual / math.max(dt, 0.004), BARNABY.MAX_FALL, BARNABY.JUMP_ADD + BARNABY.JUMP_MIN)
    end

    track.y = y
    track.t = now
end

local function simulateBarnaby(sim, jumpDelay, firstFreeJump, latency)
    local y = sim.y
    local velocity = sim.velocity
    local pendingJump = jumpDelay
    local nextFreeJump = jumpDelay and math.huge or firstFreeJump
    local coinTaken = {}
    local cost = 0
    local t = 0

    for step = 1, BARNABY.HORIZON_STEPS do
        if not pendingJump and t >= nextFreeJump and barnabyPolicyWantsJump(sim, t, y, velocity, coinTaken) then
            pendingJump = t + latency
        end

        local stepEnd = t + BARNABY.STEP

        if pendingJump and pendingJump < stepEnd then
            local before = math.max(0, pendingJump - t)
            y, velocity = advanceBarnaby(y, velocity, before)
            velocity = math.max(math.max(0, velocity) + BARNABY.JUMP_ADD, BARNABY.JUMP_MIN)
            y, velocity = advanceBarnaby(y, velocity, BARNABY.STEP - before)
            nextFreeJump = math.max(pendingJump, t) + BARNABY.PRESS_GAP
            pendingJump = nil
        else
            y, velocity = advanceBarnaby(y, velocity, BARNABY.STEP)
        end

        t = stepEnd

        if y > BARNABY.ARENA_HALF or y < -BARNABY.ARENA_HALF then
            return BARNABY.DEATH_COST * (BARNABY.HORIZON_STEPS - step + 1)
        end

        local arenaMargin = BARNABY.ARENA_HALF - math.abs(y)
        if arenaMargin < BARNABY.SAFE_MARGIN then
            local shortfall = BARNABY.SAFE_MARGIN - arenaMargin
            cost = cost + shortfall * shortfall * BARNABY.MARGIN_WEIGHT
        end

        local fishHalf = barnabyFishHalf(velocity)
        local fishLow = y - fishHalf
        local fishHigh = y + fishHalf

        for index, obstacle in ipairs(sim.obstacles) do
            local x = obstacle.x - BARNABY.SCROLL_SPEED * t

            if math.abs(x - sim.fishX) < obstacle.halfWidth + fishHalf then
                local below = fishLow - obstacle.gapBottom
                local above = obstacle.gapTop - fishHigh

                if below <= obstacle.pad or above <= obstacle.pad then
                    return BARNABY.DEATH_COST * (BARNABY.HORIZON_STEPS - step + 1)
                end

                local closest = math.min(below, above)
                if closest < obstacle.wantMargin then
                    local shortfall = obstacle.wantMargin - closest
                    cost = cost + shortfall * shortfall * BARNABY.MARGIN_WEIGHT
                end
            end

            if sim.collectCoins and obstacle.coinY and not coinTaken[index] then
                local dx = obstacle.coinX - BARNABY.SCROLL_SPEED * t - sim.fishX
                local dy = obstacle.coinY - y

                if dx * dx + dy * dy <= obstacle.coinReach * obstacle.coinReach then
                    coinTaken[index] = true
                    cost = cost - BARNABY.COIN_REWARD
                end
            end
        end

    end

    return cost
end

local function worstCaseBarnaby(sim, delayBeforeLatency, firstFreeJump)
    local fast, slow

    if delayBeforeLatency then
        fast = simulateBarnaby(sim, delayBeforeLatency + BARNABY.LATENCY_MIN, nil, BARNABY.LATENCY_MIN)
        slow = simulateBarnaby(sim, delayBeforeLatency + BARNABY.LATENCY_MAX, nil, BARNABY.LATENCY_MAX)
    else
        fast = simulateBarnaby(sim, nil, firstFreeJump, BARNABY.LATENCY_MIN)
        slow = simulateBarnaby(sim, nil, firstFreeJump, BARNABY.LATENCY_MAX)
    end

    return math.max(fast, slow)
end

local function barnabyShouldJump(y, velocity, fishX, fishRadius, obstacles, frameDt, collectCoins)
    for _, obstacle in ipairs(obstacles) do
        if obstacle.coinRadius then
            obstacle.coinReach = fishRadius + obstacle.coinRadius + BARNABY.COIN_REACH_PAD
        end

        local slack = obstacle.gapTop - obstacle.gapBottom - BARNABY.JUMP_RISE - 2 * BARNABY.NARROW_FISH_HALF
        obstacle.pad = math.clamp(slack * BARNABY.NARROW_PAD_SCALE, BARNABY.NARROW_PAD_MIN, BARNABY.COLLISION_PAD)
        obstacle.wantMargin = math.clamp(slack * BARNABY.NARROW_MARGIN_SCALE, BARNABY.NARROW_MARGIN_MIN, BARNABY.SAFE_MARGIN)
    end

    local sim = {
        y = y,
        velocity = velocity,
        fishX = fishX,
        obstacles = obstacles,
        collectCoins = collectCoins,
    }

    local jumpCost = worstCaseBarnaby(sim, 0, nil)
    local bestOther = worstCaseBarnaby(sim, nil, frameDt)

    for option = 1, BARNABY.DEFER_OPTIONS do
        local cost = worstCaseBarnaby(sim, option * frameDt, nil)
        if cost < bestOther then
            bestOther = cost
        end
    end

    if jumpCost >= BARNABY.DEATH_COST and bestOther >= BARNABY.DEATH_COST then
        return jumpCost < bestOther
    end

    if barnabyPolicyWantsJump(sim, 0, y, velocity, {}) then
        return jumpCost <= bestOther + BARNABY.DECISION_TOLERANCE
    end

    return jumpCost + BARNABY.DECISION_TOLERANCE < bestOther
end

local function resetBarnabyTracking()
    barnabyTrack.y = nil
    barnabyObstacleSignature = nil
    barnabyFocusWarned = false
end

local function doAutoBarnaby()
    if not SETTINGS.autoBarnaby then
        resetBarnabyTracking()
        return false
    end

    local world = getBarnabyWorld()
    if not world then
        resetBarnabyTracking()
        return false
    end

    local fish, obstacles = readBarnabyWorld(world)
    local fishPosition = fish and fish.Position
    if not fishPosition then
        resetBarnabyTracking()
        return false
    end

    if barnabyTrack.y == nil then
        barnabyRefreshGravity()
    end

    local now = tick()
    barnabyTrackUpdate(now, fishPosition.Y)
    local y, velocity = advanceBarnaby(barnabyTrack.y, barnabyTrack.v, now - barnabyTrack.t)

    local signature = 0
    for _, obstacle in ipairs(obstacles) do
        signature = signature + obstacle.x
    end

    if barnabyObstacleSignature ~= nil and math.abs(signature - barnabyObstacleSignature) > 0.001 then
        barnabyLastMotion = now
    end
    barnabyObstacleSignature = signature

    if not SETTINGS.autoBarnaby or #obstacles == 0 or now - barnabyLastMotion > BARNABY.STALL_TIMEOUT then
        return true
    end

    if not robloxFocused() then
        if not barnabyFocusWarned and type(notify) == "function" then
            barnabyFocusWarned = true
            pcall(notify, "Auto Barnaby", "Roblox is not focused - click its window so jumps go through.", 4)
        end
        return true
    end

    local risky = SETTINGS.barnabyCollectCoins and SETTINGS.barnabyRiskyCoins
    BARNABY.PRESS_GAP = risky and BARNABY.RISKY_PRESS_GAP or BARNABY.SAFE_PRESS_GAP
    BARNABY.COIN_REWARD = risky and BARNABY.RISKY_COIN_REWARD or BARNABY.SAFE_COIN_REWARD
    BARNABY.SAFE_MARGIN = risky and BARNABY.RISKY_SAFE_MARGIN or BARNABY.SAFE_SAFE_MARGIN

    if now - barnabyLastPress < BARNABY.PRESS_GAP then
        return true
    end

    if now - barnabyLastDecision < BARNABY.DECISION_INTERVAL then
        return true
    end
    barnabyLastDecision = now

    local fishSize = fish.Size
    local fishRadius = (fishSize and fishSize.X or 1) * 0.5

    if barnabyShouldJump(y, velocity, fishPosition.X, fishRadius, obstacles, BARNABY.DEFER_SPACING, SETTINGS.barnabyCollectCoins) then
        pressSpace(BARNABY.PRESS_HOLD)
        barnabyLastPress = now
    end

    return true
end

local SQUIRM = {
    VK_LEFT = 0x41,
    VK_RIGHT = 0x44,
    HOLD = 0.02,
    MIN_GAP = 0.06,
    heldKey = nil,
    heldUntil = 0,
    nextPressAt = 0,
    lastSide = nil,
    WARN_TEXT = "Squirm is preparing to attack you.",
    WARN_STATES = { ALERT = true, DESCENDING = true, STRIKE = true },
    WARN_RANGE = 35,
    WARN_POLL = 0.05,
    WARN_FIND = 1,
    WARN_SIZE = 28,
    warnModel = nil,
    warnFindAt = 0,
    warnPollAt = 0,
    warnOn = false,
    warnDrawing = nil,
    ALERT_DELAY = 1.5,
    alertAt = 0,
    warnState = nil,
    warnTenths = nil,
    warnTimerText = nil,
    warnShown = nil,
}

local function doAutoSquirmEscape()
    if SQUIRM.heldKey and tick() >= SQUIRM.heldUntil then
        pcall(keyrelease, SQUIRM.heldKey)
        SQUIRM.heldKey = nil
    end

    if not SETTINGS.autoSquirmEscape or PLACE_MODE ~= "main" then
        return false
    end

    local character = LocalPlayer and LocalPlayer.Character

    if not (character and character:GetAttribute("GrabbedBySquirm")) then
        SQUIRM.lastSide = nil
        return false
    end

    if type(keypress) ~= "function" or type(keyrelease) ~= "function" then
        return true
    end

    if not robloxFocused() then
        return true
    end

    local now = tick()

    if SQUIRM.heldKey or now < SQUIRM.nextPressAt then
        return true
    end

    local useLeft = SQUIRM.lastSide ~= "left"
    SQUIRM.lastSide = useLeft and "left" or "right"
    local key = useLeft and SQUIRM.VK_LEFT or SQUIRM.VK_RIGHT
    pcall(keypress, key)
    SQUIRM.heldKey = key
    SQUIRM.heldUntil = now + SQUIRM.HOLD
    SQUIRM.nextPressAt = now + math.max(1 / (SETTINGS.squirmTapRate or 14), SQUIRM.MIN_GAP)

    return true
end

local function doAutoSkillCheck()
    releaseSpaceIfDue()

    if doAutoBarnaby() then
        return
    end

    if PLACE_MODE ~= "main" or not SETTINGS.autoSkillCheck then
        return
    end

    local now = os.clock()
    if doTreadmillTapSkillCheck(now) then
        return
    end

    if now - lastSkillCheckPress < SKILL_PRESS_COOLDOWN then
        return
    end

    local parts = getSkillCheckFrame()
    if not parts then
        return
    end

    if shouldPressSkillCheck(parts) then
        pressSpace()
        lastSkillCheckPress = now
    end
end
local function getIdentity(instance)
    if instance.Address then
        return tostring(instance.Address)
    end

    return instance:GetFullName()
end

local function isVector3(value)
    return typeof and typeof(value) == "Vector3"
end

local function isCFrame(value)
    return typeof and typeof(value) == "CFrame"
end

local function safeSet(object, property, value)
    pcall(function()
        object[property] = value
    end)
end

local function isVisualPart(instance)
    if not instance then
        return false
    end

    if PART_CLASSES[instance.ClassName] then
        return true
    end

    local okPosition, position = pcall(function()
        return instance.Position
    end)

    if okPosition and isVector3(position) then
        return true
    end

    local okCFrame, cframe = pcall(function()
        return instance.CFrame
    end)

    return okCFrame and isCFrame(cframe)
end

local function readPosition(instance)
    if not instance then
        return nil
    end

    local ok, position = pcall(function()
        return instance.Position
    end)

    if ok and isVector3(position) then
        return position
    end

    local okCFrame, cframe = pcall(function()
        return instance.CFrame
    end)

    if okCFrame and isCFrame(cframe) then
        return cframe.Position
    end

    local okValue, value = pcall(function()
        return instance.Value
    end)

    if okValue then
        if isVector3(value) then
            return value
        end

        if isCFrame(value) then
            return value.Position
        end

        if typeof and typeof(value) == "Instance" then
            return readPosition(value)
        end
    end

    return nil
end

local function readSize(instance)
    if not instance then
        return nil
    end

    local ok, size = pcall(function()
        return instance.Size
    end)

    if ok and isVector3(size) then
        return size
    end

    return nil
end

local function findVisualPart(instance)
    if isVisualPart(instance) then
        return instance
    end

    local ok, primaryPart = pcall(function()
        return instance.PrimaryPart
    end)

    if ok and primaryPart then
        return primaryPart
    end

    for _, name in ipairs(POSITION_CHILD_NAMES) do
        local child = instance:FindFirstChild(name)
        if child and isVisualPart(child) then
            return child
        end
    end

    local best = nil
    local bestScore = -1
    for _, descendant in ipairs(instance:GetDescendants()) do
        if isVisualPart(descendant) then
            local score = 1
            for index, name in ipairs(POSITION_CHILD_NAMES) do
                if descendant.Name == name then
                    score = 100 - index
                    break
                end
            end

            if score > bestScore then
                best = descendant
                bestScore = score
            end
        end
    end

    return best
end

local function resolvePositionSource(instance)
    if readPosition(instance) then
        return instance
    end

    local part = findVisualPart(instance)
    if part and readPosition(part) then
        return part
    end

    for _, name in ipairs(POSITION_CHILD_NAMES) do
        local child = instance:FindFirstChild(name)
        if child and readPosition(child) then
            return child
        end
    end

    for _, descendant in ipairs(instance:GetDescendants()) do
        if readPosition(descendant) then
            return descendant
        end
    end

    return nil
end

local function getVisualPosition(visual)
    local source = visual.positionSource
    if source then
        local position

        if visual.positionIsPart then
            position = source.Position
        else
            position = readPosition(source)
        end

        if position then
            return position
        end
    end

    local now = tick()
    if visual.nextResolveAt and now < visual.nextResolveAt then
        return nil
    end

    if currentResolveBudget <= 0 then
        return nil
    end

    currentResolveBudget = currentResolveBudget - 1
    visual.nextResolveAt = now + 2.5
    visual.positionSource = resolvePositionSource(visual.item)
    visual.positionIsPart = visual.positionSource ~= nil and PART_CLASSES[visual.positionSource.ClassName] == true
    if visual.positionSource then
        return readPosition(visual.positionSource)
    end

    return nil
end

local ABILITY = {
    COOLDOWNS = {
        GoobMonster = 12,
        ScrapsMonster = 15,
        GigiMonster = 12,
        SproutMonster = 10,
        SquirmMonster = 8,
        VeeMonster = 10,
        AstroMonster = 15,
    },
    SQUIRM_MONSTER = "SquirmMonster",
    DEBUFF_ABILITIES = {
        VeeMonster = { debuff = "Slow", source = "Slow_2", seen = {}, checkedAt = 0, firedAt = 0 },
        AstroMonster = { debuff = "Tired", source = "Tired_3", seen = {}, checkedAt = 0, firedAt = 0 },
    },
    SPROUT_MONSTER = "SproutMonster",
    SPROUT_TENDRIL = "SproutTendril",
    SPROUT_DELAY = 0.5,
    TEXT_SIZE = 20,
    POLL_INTERVAL = 0.05,
    READY_TEXT = "ABILITY",
    WINDUP_SOUND = "_RangedWindupSound",
    REARM_AFTER = 3,
    ICONS = {
        GoobMonster = 17268662964,
        ScrapsMonster = 17572307852,
        GigiMonster = 106223056157959,
        SproutMonster = 18688072034,
        SquirmMonster = 108443751963686,
        VeeMonster = 17320166218,
        AstroMonster = 17615948235,
    },
    THUMB_URL = "https://thumbnails.roblox.com/v1/assets?returnPolicy=PlaceHolder&size=150x150&format=Png&isCircular=false&assetIds=",
    ICON_RETRY = 10,
    ICON_FOLDER = "DW/cacheIcons",
    LOADED_TIMEOUT = 20,
    MISSING_TEXT = "?",
    MISSING_SIZE = 44,
    downloadEnabled = false,
    loadedNotified = false,
    cacheStartedAt = 0,
    prompt = nil,
    PROMPT = {
        SIZE = Vector2.new(420, 204),
        TITLE = "Would you like to cache Twisted icons?",
        SUBTITLE = "May take some time.",
    },
    PNG_SIGNATURE = string.char(137, 80, 78, 71),
    SCAN_INTERVAL = 0.5,
    PANEL = {
        WIDTH = 260,
        HEIGHT = 72,
        GAP = 10,
        ICON = 58,
        PAD = 8,
        RIGHT = 24,
        TOP = 0.32,
        NAME_SIZE = 18,
        TIMER_SIZE = 26,
        NAME_Y = 10,
        TIMER_Y = 34,
    },
    entries = {},
    list = {},
    seen = {},
    seq = 0,
    scanAt = 0,
    dirty = false,
    panelShown = false,
    iconData = {},
    iconState = {},
    iconsReady = false,
    precacheAt = 0,
    PRECACHE_DELAY = 0.5,
}

local LABEL_LINES = 5
local LABEL_LINE_HEIGHT = 13
local LABEL_GAP = 18

local lineScratch = {}

local NO_RARITY_CATEGORIES = { Tapes = true }

local function makeDrawing(kind, color)
    local object = Drawing.new(kind)
    safeSet(object, "Color", color)
    safeSet(object, "Visible", false)
    safeSet(object, "ZIndex", 50)
    return object
end

local function createVisual(item, category, roomName)
    local color = COLORS[category]
    local alertKey, alertKind = alertKeyFor(category, item.Name)
    local lines = {}

    for index = 1, LABEL_LINES do
        local text = makeDrawing("Text", color)
        safeSet(text, "Center", true)
        safeSet(text, "Outline", true)
        safeSet(text, "Font", Drawing.Fonts.SystemBold)
        safeSet(text, "Size", LABEL_LINE_HEIGHT)
        safeSet(text, "FontSize", LABEL_LINE_HEIGHT)
        lines[index] = { drawing = text, text = nil, visible = false }
    end

    local dot = makeDrawing("Circle", color)
    safeSet(dot, "NumSides", 18)
    safeSet(dot, "Radius", 4)
    safeSet(dot, "Thickness", 2)

    local tracer = makeDrawing("Line", color)
    safeSet(tracer, "Thickness", 1)
    safeSet(tracer, "Transparency", 0.7)

    local abilityCooldown = category == "Monsters" and ABILITY.COOLDOWNS[item.Name] or nil
    local abilityDraw = nil

    if abilityCooldown then
        abilityDraw = makeDrawing("Text", color)
        safeSet(abilityDraw, "Center", true)
        safeSet(abilityDraw, "Outline", true)
        safeSet(abilityDraw, "Font", Drawing.Fonts.SystemBold)
        safeSet(abilityDraw, "Size", ABILITY.TEXT_SIZE)
        safeSet(abilityDraw, "FontSize", ABILITY.TEXT_SIZE)
    end


    return {
        item = item,
        category = category,
        roomName = roomName,
        alertKey = alertKey,
        alertKind = alertKind,
        positionSource = nil,
        nextResolveAt = 0,
        completionCheckedAt = 0,
        completed = false,
        baseName = nil,
        baseNameRetryAt = nil,
        baseRarity = nil,
        baseRarityKind = nil,
        hidden = false,
        dotOn = nil,
        tracerOn = nil,
        lastColor = nil,
        lines = lines,
        dot = dot,
        tracer = tracer,
        abilityCooldown = abilityCooldown,
        abilityDrawing = abilityDraw,
        abilityShown = nil,
        abilityVisible = false,
    }
end

local function removeVisual(visual)
    if visual.lines then
        for _, line in ipairs(visual.lines) do
            line.drawing:Remove()
        end
    end

    if visual.dot then
        visual.dot:Remove()
    end

    if visual.tracer then
        visual.tracer:Remove()
    end

    if visual.abilityDrawing then
        visual.abilityDrawing:Remove()
    end

end

local function hideVisual(visual)
    if visual.hidden then
        return
    end

    visual.hidden = true
    visual.dotOn = false
    visual.tracerOn = false

    for _, line in ipairs(visual.lines) do
        line.visible = false
        line.drawing.Visible = false
    end

    visual.dot.Visible = false
    visual.tracer.Visible = false

    if visual.abilityDrawing and visual.abilityVisible then
        visual.abilityVisible = false
        visual.abilityDrawing.Visible = false
    end
end

local function cameraWorldToScreen(worldPosition)
    if not WorldToScreen then
        return nil, false
    end

    return WorldToScreen(worldPosition)
end

local function almostEqual(a, b, tolerance)
    return math.abs(a - b) <= tolerance
end

local function sizeMatches(v1, v2, tolerance)
    return almostEqual(v1.X, v2.X, tolerance)
        and almostEqual(v1.Y, v2.Y, tolerance)
        and almostEqual(v1.Z, v2.Z, tolerance)
end

local function findIchorPart(instance)
    local direct = instance:FindFirstChild("Ichor")
    if direct and readSize(direct) then
        return direct
    end

    for _, descendant in ipairs(instance:GetDescendants()) do
        if descendant.Name == "Ichor" and readSize(descendant) then
            return descendant
        end
    end

    return nil
end

local function isCompletedGenerator(instance)
    local ichor = findIchorPart(instance)
    if not ichor then
        return false
    end

    local size = readSize(ichor)
    if not size then
        return false
    end

    return sizeMatches(size, TARGET_ICHOR_SIZE, SIZE_TOLERANCE)
end

local COMPLETION_TTL = 0.5

local function visualIsCompleted(visual)
    if visual.category ~= "Generators" then
        return false
    end

    local now = tick()
    if now - visual.completionCheckedAt < COMPLETION_TTL then
        return visual.completed
    end

    visual.completionCheckedAt = now
    visual.completed = isCompletedGenerator(visual.item)
    return visual.completed
end

local function isItemAlert(visual)
    return visual.alertKind == "item"
        and visual.alertKey ~= nil
        and SETTINGS[visual.alertKey] == true
end

local function getVisualColor(visual)
    if visualIsCompleted(visual) then
        return COLORS.CompletedGenerator
    end

    if SETTINGS.showInUseGenerators and visual.category == "Generators" then
        local now = tick()
        if now - (visual.inUseCheckedAt or 0) >= 0.25 then
            visual.inUseCheckedAt = now
            visual.inUse = false

            local stats = visual.item:FindFirstChild("Stats")
            local localName = LocalPlayer and LocalPlayer.Name

            if stats then
                local slots = stats:FindFirstChild("ActivePlayer2") and 2 or 1
                local taken = 0
                local byOther = false

                for index = 1, slots do
                    local holder = stats:FindFirstChild(index == 1 and "ActivePlayer" or "ActivePlayer2")
                    local okValue, occupant = pcall(function()
                        return holder and holder.Value
                    end)

                    if okValue and occupant then
                        local okClass, className = pcall(function()
                            return occupant.ClassName
                        end)
                        local okName, occupantName = pcall(function()
                            return occupant.Name
                        end)

                        if okClass and className == "Model" then
                            taken = taken + 1
                            if okName and occupantName ~= localName then
                                byOther = true
                            end
                        end
                    end
                end

                visual.inUse = byOther and taken >= slots
            end
        end

        if visual.inUse then
            return COLORS.InUseGenerator
        end
    end

    if isItemAlert(visual) then
        return COLORS.ItemAlert
    end

    return COLORS[visual.category]
end

local STRINGS = {
    OFFSET = 0xA8,
    memoryReads = nil,
}

function STRINGS.clean(text)
    if type(text) ~= "string" then
        return nil
    end
    text = text:match("^%s*(.-)%s*$")
    if #text > 0 and #text < 64 and text:match("^[%w%s'%-%.]+$") then
        return text
    end
    return nil
end

function STRINGS.read(instance)
    if not instance then
        return ""
    end

    if STRINGS.memoryReads ~= false and not VantaUI.MemoryAccess() then
        STRINGS.memoryReads = false
    end

    if STRINGS.memoryReads ~= false then
        local okAddress, address = pcall(function()
            return tonumber(instance.Address)
        end)

        if not okAddress or not address or address <= 4096 then
            STRINGS.memoryReads = false
        else
            local okDirect, direct = pcall(memory_read, "string", address + STRINGS.OFFSET)
            if not okDirect or type(direct) ~= "string" then
                STRINGS.memoryReads = false
            else
                STRINGS.memoryReads = true
                local text = STRINGS.clean(direct)
                if text then
                    return text
                end

                local okPointer, pointer = pcall(memory_read, "uintptr_t", address + STRINGS.OFFSET)
                if okPointer and type(pointer) == "number" and pointer > 4096 then
                    local okDeref, deref = pcall(memory_read, "string", pointer)
                    text = okDeref and STRINGS.clean(deref)
                    if text then
                        return text
                    end
                end
            end
        end
    end

    local ok, value = pcall(function()
        return instance.Value
    end)
    return (ok and type(value) == "string") and value or ""
end

local function researchCapsuleMonster(item)
    local prompt = item:FindFirstChild("Prompt")
    local holder = prompt and prompt:FindFirstChild("Monster")
    local value = holder and STRINGS.read(holder)

    if type(value) ~= "string" then
        return nil
    end

    value = value:match("^%s*(.-)%s*$")

    if value == "" or not value:match("^[%w%s%-'%.]+$") then
        return nil
    end

    return value
end

local NAME_RETRY_INTERVAL = 5

local MACHINE_TYPE_LABELS = {
    Original = "Bar",
    Circle = "Circle",
    Treadmill = "Treadmill",
    TreadmillTap = "Treadmill",
    MovementTreadmill = "Treadmill",
}

local function machineTypeLabel(item)
    local value = item:GetAttribute("MinigameType")

    if type(value) ~= "string" or value == "" then
        return nil
    end

    local label = MACHINE_TYPE_LABELS[value] or value

    if item:GetAttribute("IsDualGen") == true or item:GetAttribute("MachineFamily") == "DUAL" then
        local second = item:GetAttribute("Prompt2MinigameType")
        if type(second) == "string" and second ~= "" then
            label = label .. " & " .. (MACHINE_TYPE_LABELS[second] or second)
        end
    end

    return label
end

local function getVisualName(visual)
    local name = visual.baseName

    if name and visual.baseNameRetryAt and tick() >= visual.baseNameRetryAt then
        name = nil
    end

    if not name then
        name = visual.item.Name
        visual.baseNameRetryAt = nil
        visual.baseRarity = nil
        visual.baseRarityKind = nil

        if visual.category == "Generators" then
            name = "Ichor Extractor"
        elseif visual.category == "ResearchCapsules" then
            local monster = researchCapsuleMonster(visual.item)
            if monster then
                local info = MONSTER_INFO[monster]
                name = ((info and info.name) or (monster:gsub("Monster$", ""))) .. " Research"
                visual.baseRarity = info and info.rarity or nil
                visual.baseRarityKind = "twisted"
            else
                name = "Research Capsule"
                visual.baseNameRetryAt = tick() + NAME_RETRY_INTERVAL
            end
        elseif visual.category == "Monsters" then
            local info = MONSTER_INFO[name]
            if info then
                name = info.name
                visual.baseRarity = info.rarity
                visual.baseRarityKind = "twisted"
            else
                name = name:gsub("Monster$", "")
            end
        else
            local info = ITEM_INFO[name]
            if info then
                name = info.name
                if not NO_RARITY_CATEGORIES[visual.category] then
                    visual.baseRarity = info.rarity
                    visual.baseRarityKind = "item"
                end
            end
        end

        visual.baseName = name
    end

    local percent = nil

    if visual.category == "Generators" then
        if not visual.fillRequired then
            local stats = visual.item:FindFirstChild("Stats")
            visual.fillCurrent = stats and stats:FindFirstChild("CurrentAmount")
            visual.fillRequired = stats and stats:FindFirstChild("RequiredAmount")
        end

        local current = visual.fillCurrent and visual.fillCurrent.Value
        local required = visual.fillRequired and visual.fillRequired.Value
        if type(current) == "number" and type(required) == "number" and required > 0 then
            percent = math.clamp(math.floor(current / required * 100 + 0.5), 0, 100)
        end
    end

    local completed = visualIsCompleted(visual)

    if not percent and not completed then
        return name, visual.baseRarity
    end

    if visual.nameTextBase ~= name or visual.nameTextPercent ~= percent or visual.nameTextCompleted ~= completed then
        visual.nameTextBase = name
        visual.nameTextPercent = percent
        visual.nameTextCompleted = completed

        local text = name
        if percent then
            text = text .. " " .. percent .. "%"
        end
        if completed then
            text = text .. " - COMPLETED"
        end
        visual.nameText = text
    end

    return visual.nameText, visual.baseRarity
end
local function addCandidate(item, category, roomName)
    local key = category .. ":" .. getIdentity(item)
    activeKeys[key] = true

    if not tracked[key] then
        tracked[key] = createVisual(item, category, roomName)
    else
        local visual = tracked[key]
        if visual.category ~= category then
            visual.category = category
            visual.alertKey, visual.alertKind = alertKeyFor(category, item.Name)
            visual.baseName = nil
            visual.baseNameRetryAt = nil
            visual.baseRarity = nil
            visual.baseRarityKind = nil
            visual.completionCheckedAt = 0
        end

        visual.roomName = roomName
    end
end

local function newHitList()
    return { order = {}, byName = {} }
end

local function addHit(hits, display)
    local entry = hits.byName[display]

    if entry then
        entry.count = entry.count + 1
        return
    end

    entry = { name = display, count = 1 }
    hits.byName[display] = entry
    hits.order[#hits.order + 1] = entry
end

local function formatHits(hits)
    local parts = {}

    for _, entry in ipairs(hits.order) do
        parts[#parts + 1] = entry.count > 1 and (entry.name .. " x" .. entry.count) or entry.name
    end

    return table.concat(parts, ", ")
end

local function checkAlert(present, hits, instance, key, infoTable)
    if not key then
        return
    end

    local id = getIdentity(instance)
    present[id] = true

    if not SETTINGS[key] or alertSeen[id] then
        return
    end

    local info = infoTable[instance.Name]
    addHit(hits, (info and info.name) or (instance.Name:gsub("Monster$", "")))
end

local function announceAlerts(monsterHits, itemHits)
    local monsterText = formatHits(monsterHits)
    local itemText = formatHits(itemHits)

    if monsterText == "" and itemText == "" then
        return
    end

    local title, body

    if itemText == "" then
        title, body = "Twisted Spawned", monsterText
    elseif monsterText == "" then
        title, body = "Item Found", itemText
    else
        title = "Twisteds & Items"
        body = "Twisted: " .. monsterText .. "  |  Items: " .. itemText
    end

    if type(notify) == "function" then
        pcall(notify, title, body, ALERT_DURATION)
    end
end

local function updateAlerts(currentRoom)
    local present = {}
    local monsterHits = newHitList()
    local itemHits = newHitList()

    for _, room in ipairs(currentRoom:GetChildren()) do
        local monsters = room:FindFirstChild("Monsters")
        if monsters then
            for _, child in ipairs(monsters:GetChildren()) do
                checkAlert(present, monsterHits, child, ALERT_BY_MONSTER[child.Name], MONSTER_INFO)
            end
        end

        local items = room:FindFirstChild("Items")
        if items then
            for _, child in ipairs(items:GetChildren()) do
                checkAlert(present, itemHits, child, ALERT_BY_ITEM[child.Name], ITEM_INFO)
            end
        end
    end

    alertSeen = present
    announceAlerts(monsterHits, itemHits)
end

local function categoryForChild(folderKey, child)
    if folderKey == "Items" then
        local special = ITEM_CATEGORIES[child.Name]
        if special == false then
            return nil
        end
        if special then
            return special
        end
    end

    return folderKey
end

local function scanFolder(folder, folderKey, roomName)
    for _, child in ipairs(folder:GetChildren()) do
        local category = categoryForChild(folderKey, child)
        local enabled = category and SETTINGS[CATEGORY_ENABLED[category]]

        if category and not enabled then
            enabled = alertEnabledFor(category, child.Name)
        end

        if enabled then
            addCandidate(child, category, roomName)
        end
    end
end

local function scanVisuals()
    activeKeys = {}
    local currentRoom = Workspace:FindFirstChild("CurrentRoom")

    if not currentRoom then
        return
    end

    updateAlerts(currentRoom)

    local monsterAlertsOn = anyAlertEnabled(ALERT_MONSTERS)
    local itemAlertsOn = anyAlertEnabled(ALERT_ITEMS)

    for _, room in ipairs(currentRoom:GetChildren()) do
        for _, folderInfo in ipairs(FOLDERS) do
            if anyEnabled(folderInfo.enabledKeys)
                or (monsterAlertsOn and folderInfo.key == "Monsters")
                or (itemAlertsOn and folderInfo.key == "Items") then
                local folder = room:FindFirstChild(folderInfo.key)
                if folder then
                    scanFolder(folder, folderInfo.key, room.Name)
                end
            end
        end

        if SETTINGS.showMonsters or alertEnabledFor("Monsters", "BlottMonster") then
            for index = 1, FOLDERS.BLOT_ZONE_MAX do
                local zone = room:FindFirstChild(FOLDERS.BLOT_ZONE_PREFIX .. index)
                if zone then
                    for _, hand in ipairs(zone:GetChildren()) do
                        if hand.ClassName == "Model" and hand.Name:sub(1, #FOLDERS.BLOT_HAND_PREFIX) == FOLDERS.BLOT_HAND_PREFIX then
                            addCandidate(hand, "Monsters", room.Name)
                        end
                    end
                end
            end
        end
    end

    for key, visual in pairs(tracked) do
        if not activeKeys[key] or not visual.item.Parent then
            removeVisual(visual)
            tracked[key] = nil
        end
    end
end

local function uiValue(id, fallback)
    if not UI then
        return fallback
    end

    local value = UI.GetValue(id)
    if value == nil then
        return fallback
    end

    return value
end

local function refreshSettingsFromUi()
    if not UI then
        return
    end

    SETTINGS.enabled = uiValue("dw_visuals_enabled", SETTINGS.enabled)
    SETTINGS.maxDistance = uiValue("dw_visuals_distance", SETTINGS.maxDistance)
    SETTINGS.showMonsters = uiValue("dw_visuals_monsters", SETTINGS.showMonsters)
    SETTINGS.showItems = uiValue("dw_visuals_items", SETTINGS.showItems)
    SETTINGS.showResearchCapsules = uiValue("dw_visuals_research", SETTINGS.showResearchCapsules)
    SETTINGS.showTapes = uiValue("dw_visuals_tapes", SETTINGS.showTapes)
    SETTINGS.showGenerators = uiValue("dw_visuals_generators", SETTINGS.showGenerators)
    SETTINGS.showCompletedGenerators = uiValue("dw_visuals_show_done_generators", SETTINGS.showCompletedGenerators)
    SETTINGS.showInUseGenerators = uiValue("dw_visuals_inuse_generators", SETTINGS.showInUseGenerators)
    SETTINGS.showName = uiValue("dw_visuals_name", SETTINGS.showName)
    SETTINGS.showDistance = uiValue("dw_visuals_range", SETTINGS.showDistance)
    SETTINGS.showRoom = uiValue("dw_visuals_room", SETTINGS.showRoom)
    SETTINGS.showMachineType = uiValue("dw_visuals_machine_type", SETTINGS.showMachineType)
    SETTINGS.showTwistedRarity = uiValue("dw_visuals_twisted_rarity", SETTINGS.showTwistedRarity)
    SETTINGS.showAbilityTimer = uiValue("dw_visuals_ability_timer", SETTINGS.showAbilityTimer)
    SETTINGS.showSquirmWarning = uiValue("dw_visuals_squirm_warning", SETTINGS.showSquirmWarning)
    SETTINGS.showItemRarity = uiValue("dw_visuals_item_rarity", SETTINGS.showItemRarity)
    SETTINGS.showPlayerHealth = uiValue("dw_players_health", SETTINGS.showPlayerHealth)
    SETTINGS.aggressiveAutoFarm = uiValue("dw_farm_aggressive", SETTINGS.aggressiveAutoFarm)
    SETTINGS.allowFarmWithPlayers = uiValue("dw_farm_with_players", SETTINGS.allowFarmWithPlayers)
    SETTINGS.tweenWalkSpeed = uiValue("dw_farm_speed", SETTINGS.tweenWalkSpeed)
    SETTINGS.floorLimit = uiValue("dw_farm_floor_limit", SETTINGS.floorLimit)
    SETTINGS.unlimitedFloors = uiValue("dw_farm_unlimited", SETTINGS.unlimitedFloors)
    SETTINGS.masteryFarm = uiValue("dw_mastery_farm", SETTINGS.masteryFarm)
    SETTINGS.masterySelect = uiValue("dw_mastery_select", SETTINGS.masterySelect)
    SETTINGS.masteryEnd = uiValue("dw_mastery_end", SETTINGS.masteryEnd)
    SETTINGS.farmAutoResume = uiValue("dw_farm_auto_resume", SETTINGS.farmAutoResume)
    SETTINGS.farmHideOnTeleport = uiValue("dw_farm_hide_teleport", SETTINGS.farmHideOnTeleport)
    SETTINGS.farmHealItems = uiValue("dw_farm_heal_items", SETTINGS.farmHealItems)
    SETTINGS.farmExtractionItems = uiValue("dw_farm_extraction_items", SETTINGS.farmExtractionItems)
    SETTINGS.farmCapsules = uiValue("dw_farm_capsules", SETTINGS.farmCapsules)
    SETTINGS.farmResearchTwisteds = uiValue("dw_farm_research_twisteds", SETTINGS.farmResearchTwisteds)
    SETTINGS.farmSkipResearched = uiValue("dw_farm_skip_researched", SETTINGS.farmSkipResearched)
    SETTINGS.farmIgnoreTwistedsTravel = uiValue("dw_farm_ignore_twisteds_travel", SETTINGS.farmIgnoreTwistedsTravel)
    SETTINGS.farmTreadmillRun = uiValue("dw_farm_treadmill_run", SETTINGS.farmTreadmillRun)
    SETTINGS.farmTreadmillStopAt = uiValue("dw_farm_treadmill_stop", SETTINGS.farmTreadmillStopAt)
    SETTINGS.showPlayerStamina = uiValue("dw_players_stamina", SETTINGS.showPlayerStamina)
    SETTINGS.lowStaminaThreshold = uiValue("dw_players_low_stamina", SETTINGS.lowStaminaThreshold)
    SETTINGS.showDot = uiValue("dw_visuals_dot", SETTINGS.showDot)
    SETTINGS.showTracer = uiValue("dw_visuals_tracer", SETTINGS.showTracer)
    SETTINGS.maxVisible = uiValue("dw_visuals_max_visible", SETTINGS.maxVisible)
    SETTINGS.updateInterval = math.max(0.005, uiValue("dw_visuals_update_rate", SETTINGS.updateInterval))
    SETTINGS.scanInterval = math.max(0.5, uiValue("dw_visuals_scan_rate", SETTINGS.scanInterval))
    SETTINGS.autoSkillCheck = uiValue("dw_skillcheck_enabled", SETTINGS.autoSkillCheck)
    SETTINGS.skillCheckRandom = uiValue("dw_skillcheck_random", SETTINGS.skillCheckRandom)
    SETTINGS.skillCheckAim = uiValue("dw_skillcheck_aim", SETTINGS.skillCheckAim)
    SETTINGS.skillCheckLead = uiValue("dw_skillcheck_lead", SETTINGS.skillCheckLead)
    SETTINGS.treadmillTapRate = uiValue("dw_skillcheck_treadmill_rate", SETTINGS.treadmillTapRate)
    SETTINGS.autoBarnaby = uiValue("dw_barnaby_enabled", SETTINGS.autoBarnaby)
    SETTINGS.autoSquirmEscape = uiValue("dw_squirm_escape", SETTINGS.autoSquirmEscape)
    SETTINGS.autoAbility = uiValue("dw_auto_ability", SETTINGS.autoAbility)
    SETTINGS.squirmTapRate = uiValue("dw_squirm_tap_rate", SETTINGS.squirmTapRate)    SETTINGS.barnabyCollectCoins = uiValue("dw_barnaby_coins", SETTINGS.barnabyCollectCoins)
    SETTINGS.barnabyRiskyCoins = uiValue("dw_barnaby_risky_coins", SETTINGS.barnabyRiskyCoins)
    SETTINGS.alertTracers = uiValue("dw_alert_tracers", SETTINGS.alertTracers)

    local twisteds = uiValue("dw_alert_twisteds", nil)
    if twisteds then
        for _, entry in ipairs(ALERT_MONSTERS) do
            SETTINGS[entry.key] = twisteds[entry.label] == true
        end
    end

    SETTINGS.itemAlertTracers = uiValue("dw_item_alert_tracers", SETTINGS.itemAlertTracers)
    SETTINGS.webhooksEnabled = uiValue("dw_webhooks_enabled", SETTINGS.webhooksEnabled)

    local items = uiValue("dw_alert_items", nil)
    if items then
        for _, entry in ipairs(ALERT_ITEMS) do
            SETTINGS[entry.key] = items[entry.label] == true
        end
    end

    local Keybind = VantaUI.Options.dw_esp_key
    if Keybind and Keybind.Key then SETTINGS.espKey = Keybind.Key end
    if UI.Window then SETTINGS.menuKey = UI.Window.MenuKey end

    autoSaveConfig()
end


function ABILITY.newSproutTendril(entry)
    local folder = entry.model.Parent
    local map = folder and folder.Parent
    if not map then
        return false
    end

    local area = map:FindFirstChild("FreeArea")
    local tendril = (area and area:FindFirstChild(ABILITY.SPROUT_TENDRIL)) or map:FindFirstChild(ABILITY.SPROUT_TENDRIL)
    if not tendril then
        entry.tendrilAddress = nil
        return false
    end

    local address = tostring(tendril.Address)
    if entry.tendrilAddress == address then
        return false
    end

    entry.tendrilAddress = address
    return true
end

function ABILITY.pollDebuff(spec, now)
    if now - spec.checkedAt < ABILITY.POLL_INTERVAL then
        return
    end

    spec.checkedAt = now
    local seen = spec.seen
    local prefix = "Debuff_" .. spec.debuff .. "_"
    local pattern = "%d+:([%d%.]+):" .. spec.source

    for _, player in ipairs(Players:GetPlayers()) do
        local key = player.UserId
        local character = player.Character

        if character then
            local marks = {}
            local active = nil
            if character:GetAttribute(prefix .. "Source") == spec.source then
                active = "active:" .. tostring(character:GetAttribute(prefix .. "EndTime"))
                marks[active] = true
            end

            local hadPending = false
            local pending = character:GetAttribute(prefix .. "Pending")
            if type(pending) == "string" then
                for endTime in pending:gmatch(pattern) do
                    marks["pending:" .. endTime] = true
                    hadPending = true
                end
            end

            local previous = seen[key]
            if previous then
                for mark in pairs(marks) do
                    if not previous.marks[mark] and (mark ~= active or not previous.hadPending) then
                        spec.firedAt = now
                    end
                end
            end

            seen[key] = { marks = marks, hadPending = hadPending }
        else
            seen[key] = nil
        end
    end
end

function ABILITY.poll(entry, now)
    if now - entry.checkedAt < ABILITY.POLL_INTERVAL then
        return
    end

    entry.checkedAt = now
    local model = entry.model

    local spec = ABILITY.DEBUFF_ABILITIES[entry.name]
    if spec then
        ABILITY.pollDebuff(spec, now)
        if entry.debuffFired ~= spec.firedAt then
            entry.debuffFired = spec.firedAt
            if entry.readyAt - now < entry.cooldown - ABILITY.REARM_AFTER then
                entry.readyAt = now + entry.cooldown
            end
        end

        return
    end

    if entry.name == ABILITY.SQUIRM_MONSTER then
        local holding = model:GetAttribute("SquirmState") == "HOLDING" or model:GetAttribute("GrabbedPlayer") ~= nil
        if entry.active and not holding then
            entry.readyAt = now + entry.cooldown
        end

        entry.active = holding
        return
    end

    if entry.name == ABILITY.SPROUT_MONSTER then
        if ABILITY.newSproutTendril(entry) then
            entry.readyAt = now + entry.cooldown - ABILITY.SPROUT_DELAY
        end

        return
    end

    local root = model:FindFirstChild("HumanoidRootPart")
    local active = root ~= nil and root:FindFirstChild(ABILITY.WINDUP_SOUND) ~= nil

    if not active then
        active = model:GetAttribute("UsingAbility") == true
    end

    if not active then
        local grabbing = model:FindFirstChild("Grabbing")
        active = grabbing ~= nil and grabbing.Value == true
    end

    if active and not entry.active and entry.readyAt - now < entry.cooldown - ABILITY.REARM_AFTER then
        entry.readyAt = now + entry.cooldown
    end

    entry.active = active
end

function ABILITY.label(entry, now)
    local remaining = entry.readyAt - now

    if remaining <= 0 then
        return ABILITY.READY_TEXT
    end

    local tenths = math.ceil(remaining * 10)

    if entry.tenths ~= tenths then
        entry.tenths = tenths
        entry.text = string.format("%.1fs", tenths / 10)
    end

    return entry.text
end

local function abilityLabel(visual, now)
    local entry = ABILITY.entries[getIdentity(visual.item)]
    if not entry then
        return ABILITY.READY_TEXT
    end

    return ABILITY.label(entry, now)
end

function ABILITY.iconPath(name)
    return ABILITY.ICON_FOLDER .. "/" .. tostring(ABILITY.ICONS[name]) .. ".dat"
end

function ABILITY.loadCachedIcon(name)
    if ABILITY.iconData[name] then
        return true
    end

    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return false
    end

    local path = ABILITY.iconPath(name)
    local okRead, cached = pcall(function()
        return isfile(path) and readfile(path) or nil
    end)

    if okRead and type(cached) == "string" and cached:sub(1, 4) == ABILITY.PNG_SIGNATURE then
        ABILITY.iconData[name] = cached
        ABILITY.iconState[name] = "done"
        return true
    end

    return false
end

function ABILITY.requestIcon(name)
    local state = ABILITY.iconState[name]
    if state == "loading" or state == "done" or (type(state) == "number" and tick() < state) then
        return
    end

    local id = ABILITY.ICONS[name]
    if not id or type(httpget) ~= "function" then
        ABILITY.iconState[name] = "done"
        return
    end

    if ABILITY.loadCachedIcon(name) then
        return
    end

    local path = ABILITY.iconPath(name)
    ABILITY.iconState[name] = "loading"
    task.spawn(function()
        local ok, body = pcall(httpget, ABILITY.THUMB_URL .. tostring(id))
        local url = ok and type(body) == "string" and body:match('"state":"Completed","imageUrl":"([^"]+)"')

        if url then
            local okImage, data = pcall(httpget, url)
            if okImage and type(data) == "string" and data:sub(1, 4) == ABILITY.PNG_SIGNATURE then
                ABILITY.iconData[name] = data
                ABILITY.iconState[name] = "done"
                pcall(function()
                    if not isfolder("DW") then
                        makefolder("DW")
                    end
                    if not isfolder(ABILITY.ICON_FOLDER) then
                        makefolder(ABILITY.ICON_FOLDER)
                    end
                    writefile(path, data)
                end)
                return
            end
        end

        ABILITY.iconState[name] = tick() + ABILITY.ICON_RETRY
    end)
end

function ABILITY.precacheIcons()
    local ready = true
    for name in pairs(ABILITY.ICONS) do
        ABILITY.requestIcon(name)
        if not ABILITY.iconData[name] then
            ready = false
        end
    end

    ABILITY.iconsReady = ready
    ABILITY.precacheAt = tick() + 1
end

function ABILITY.notifyLoaded()
    ABILITY.loadedNotified = true
    if type(notify) ~= "function" then
        return
    end

    pcall(notify, "Dandy's World", "Loaded. Made by VantaH.", 4)
    if PLACE_MODE == "other" then
        pcall(notify, "Dandy's World", "Unknown place " .. tostring(game.PlaceId) .. " - auto skill check and Auto Barnaby are off here.", 5)
    end
end

function ABILITY.showPrompt()
    local P = ABILITY.PROMPT
    local Dialog, Body = UI.dialog("Twisted Icons", "Dandy's World", "CACHE", P.SIZE, function()
        ABILITY.choosePrompt(false)
    end)
    ABILITY.prompt = {Window = Dialog}
    Body:AddParagraph({Content = P.TITLE .. "\n" .. P.SUBTITLE})
    Body:AddButton({Title = "Yes", Primary = true, Callback = function()
        ABILITY.choosePrompt(true)
    end})
    Body:AddButton({Title = "No", Callback = function()
        ABILITY.choosePrompt(false)
    end})
end

function ABILITY.removePrompt()
    local prompt = ABILITY.prompt
    if not prompt then return end
    ABILITY.prompt = nil
    pcall(function()
        prompt.Window:Destroy()
    end)
end

function ABILITY.choosePrompt(cache)
    if not ABILITY.prompt then return end
    ABILITY.removePrompt()

    if not cache then
        ABILITY.notifyLoaded()
        return
    end

    if type(notify) == "function" then
        pcall(notify, "Dandy's World", "Caching images", 3)
    end

    ABILITY.downloadEnabled = true
    ABILITY.cacheStartedAt = tick()
    ABILITY.precacheAt = ABILITY.cacheStartedAt + ABILITY.PRECACHE_DELAY
end

function ABILITY.startIconCache()
    local ready = true
    for name in pairs(ABILITY.ICONS) do
        if not ABILITY.loadCachedIcon(name) then
            ready = false
        end
    end

    ABILITY.iconsReady = ready
    if ready then
        ABILITY.notifyLoaded()
    else
        ABILITY.showPrompt()
        if not ABILITY.prompt then
            ABILITY.notifyLoaded()
        end
    end
end

function ABILITY.removeCard(entry)
    local card = entry.card
    if not card then
        return
    end

    for _, key in ipairs({ "name", "timer", "icon", "missing" }) do
        if card[key] then
            pcall(function()
                card[key]:Remove()
            end)
        end
    end

    entry.card = nil
end

function ABILITY.scan(now)
    if now < ABILITY.scanAt then
        return
    end

    ABILITY.scanAt = now + ABILITY.SCAN_INTERVAL
    local seen = ABILITY.seen
    for key in pairs(seen) do
        seen[key] = nil
    end

    local room = Workspace:FindFirstChild("CurrentRoom")
    if room then
        for _, child in ipairs(room:GetChildren()) do
            local folder = child:FindFirstChild("Monsters")
            if folder then
                for _, model in ipairs(folder:GetChildren()) do
                    local cooldown = ABILITY.COOLDOWNS[model.Name]
                    if cooldown then
                        local key = getIdentity(model)
                        seen[key] = true

                        if not ABILITY.entries[key] then
                            ABILITY.seq = ABILITY.seq + 1
                            ABILITY.entries[key] = {
                                model = model,
                                name = model.Name,
                                cooldown = cooldown,
                                readyAt = 0,
                                active = false,
                                checkedAt = 0,
                                order = ABILITY.seq,
                                debuffFired = ABILITY.DEBUFF_ABILITIES[model.Name] and ABILITY.DEBUFF_ABILITIES[model.Name].firedAt,
                            }
                            ABILITY.dirty = true
                        end
                    end
                end
            end
        end
    end

    for key, entry in pairs(ABILITY.entries) do
        if not seen[key] or not entry.model.Parent then
            ABILITY.removeCard(entry)
            ABILITY.entries[key] = nil
            ABILITY.dirty = true
        end
    end

    if ABILITY.dirty then
        ABILITY.dirty = false
        local list = ABILITY.list
        for index = #list, 1, -1 do
            list[index] = nil
        end

        for _, entry in pairs(ABILITY.entries) do
            list[#list + 1] = entry
        end

        table.sort(list, function(a, b)
            return a.order < b.order
        end)
    end
end

function ABILITY.drawCard(entry, index, viewport, now)
    local P = ABILITY.PANEL
    local card = entry.card
    local white = Color3.fromRGB(255, 255, 255)

    if not card then
        card = {}
        card.name = makeDrawing("Text", white)
        safeSet(card.name, "Font", Drawing.Fonts.SystemBold)
        safeSet(card.name, "Size", P.NAME_SIZE)
        safeSet(card.name, "FontSize", P.NAME_SIZE)
        safeSet(card.name, "Outline", true)
        local info = MONSTER_INFO[entry.name]
        safeSet(card.name, "Text", (info and info.name) or entry.name)

        card.timer = makeDrawing("Text", white)
        safeSet(card.timer, "Font", Drawing.Fonts.SystemBold)
        safeSet(card.timer, "Size", P.TIMER_SIZE)
        safeSet(card.timer, "FontSize", P.TIMER_SIZE)
        safeSet(card.timer, "Outline", true)

        entry.card = card
    end

    if not card.icon then
        local data = ABILITY.iconData[entry.name]
        if data then
            card.icon = makeDrawing("Image", white)
            safeSet(card.icon, "Data", data)
            safeSet(card.icon, "Size", Vector2.new(P.ICON, P.ICON))
            safeSet(card.icon, "ZIndex", 51)
            if card.missing then
                pcall(function()
                    card.missing:Remove()
                end)
                card.missing = nil
            end
            card.x = nil
            card.visible = false
        elseif not card.missing then
            card.missing = makeDrawing("Text", white)
            safeSet(card.missing, "Font", Drawing.Fonts.SystemBold)
            safeSet(card.missing, "Size", ABILITY.MISSING_SIZE)
            safeSet(card.missing, "FontSize", ABILITY.MISSING_SIZE)
            safeSet(card.missing, "Center", true)
            safeSet(card.missing, "Outline", true)
            safeSet(card.missing, "Text", ABILITY.MISSING_TEXT)
            card.x = nil
            card.visible = false
        end
    end

    local text = ABILITY.label(entry, now)
    if card.shown ~= text then
        card.shown = text
        card.timer.Text = text
    end

    local x = viewport.X - P.WIDTH - P.RIGHT
    local y = viewport.Y * P.TOP + (index - 1) * (P.HEIGHT + P.GAP)
    if card.x ~= x or card.y ~= y then
        card.x = x
        card.y = y
        local textX = x + P.PAD + P.ICON + 12
        card.name.Position = Vector2.new(textX, y + P.NAME_Y)
        card.timer.Position = Vector2.new(textX, y + P.TIMER_Y)
        if card.icon then
            card.icon.Position = Vector2.new(x + P.PAD, y + (P.HEIGHT - P.ICON) / 2)
        end
        if card.missing then
            card.missing.Position = Vector2.new(x + P.PAD + P.ICON / 2, y + (P.HEIGHT - ABILITY.MISSING_SIZE) / 2)
        end
    end

    if not card.visible then
        card.visible = true
        card.name.Visible = true
        card.timer.Visible = true
        if card.icon then
            card.icon.Visible = true
        end
        if card.missing then
            card.missing.Visible = true
        end
    end
end

function ABILITY.hidePanel()
    if not ABILITY.panelShown then
        return
    end

    ABILITY.panelShown = false
    for _, entry in pairs(ABILITY.entries) do
        local card = entry.card
        if card and card.visible then
            card.visible = false
            card.name.Visible = false
            card.timer.Visible = false
            if card.icon then
                card.icon.Visible = false
            end
            if card.missing then
                card.missing.Visible = false
            end
        end
    end
end

function ABILITY.update()
    local now = tick()

    if ABILITY.downloadEnabled then
        if not ABILITY.iconsReady and now >= ABILITY.precacheAt then
            ABILITY.precacheIcons()
        end

        if not ABILITY.loadedNotified and (ABILITY.iconsReady or now - ABILITY.cacheStartedAt >= ABILITY.LOADED_TIMEOUT) then
            ABILITY.notifyLoaded()
        end
    end

    if not SETTINGS.showAbilityTimer then
        ABILITY.hidePanel()
        return
    end

    ABILITY.scan(now)

    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize

    for index, entry in ipairs(ABILITY.list) do
        ABILITY.poll(entry, now)
        if viewport then
            ABILITY.drawCard(entry, index, viewport, now)
            ABILITY.panelShown = true
        end
    end
end

local PLAYERS = {
    entries = {},
    seen = {},
    TEXT_SIZE = 13,
    FOOT_DROP = 3.2,
    LABEL_GAP = 6,
    LOW_HEALTH = 1,
    PRUNE_INTERVAL = 2,
    WHITE = Color3.fromRGB(255, 255, 255),
    LOW = Color3.fromRGB(255, 120, 120),
    pruneAt = 0,
}

function PLAYERS.makeLine()
    local drawing = makeDrawing("Text", PLAYERS.WHITE)
    safeSet(drawing, "Center", true)
    safeSet(drawing, "Outline", true)
    safeSet(drawing, "Font", Drawing.Fonts.SystemBold)
    safeSet(drawing, "Size", PLAYERS.TEXT_SIZE)
    safeSet(drawing, "FontSize", PLAYERS.TEXT_SIZE)
    return { drawing = drawing, text = nil, low = nil, visible = false }
end

function PLAYERS.entryFor(userId)
    local entry = PLAYERS.entries[userId]

    if not entry then
        entry = { health = PLAYERS.makeLine(), stamina = PLAYERS.makeLine() }
        PLAYERS.entries[userId] = entry
    end

    return entry
end

function PLAYERS.showLine(line, text, low, x, y)
    if line.text ~= text then
        line.text = text
        line.drawing.Text = text
    end

    if line.low ~= low then
        line.low = low
        line.drawing.Color = low and PLAYERS.LOW or PLAYERS.WHITE
    end

    line.drawing.Position = Vector2.new(x, y)

    if not line.visible then
        line.visible = true
        line.drawing.Visible = true
    end
end

function PLAYERS.hideLine(line)
    if line.visible then
        line.visible = false
        line.drawing.Visible = false
    end
end

function PLAYERS.hide(entry)
    PLAYERS.hideLine(entry.health)
    PLAYERS.hideLine(entry.stamina)
end

function PLAYERS.removeEntry(entry)
    pcall(function()
        entry.health.drawing:Remove()
    end)

    pcall(function()
        entry.stamina.drawing:Remove()
    end)
end

function PLAYERS.drawOne(player, cameraPosition)
    local entry = PLAYERS.entryFor(player.UserId)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")
    local stats = character and character:FindFirstChild("Stats")
    local current = stats and stats:FindFirstChild("CurrentStamina")
    local maximum = stats and stats:FindFirstChild("Stamina")

    if not (root and humanoid and current and maximum) then
        PLAYERS.hide(entry)
        return
    end

    local health = humanoid.Health or 0
    if health <= 0 then
        PLAYERS.hide(entry)
        return
    end

    local position = root.Position
    if (position - cameraPosition).Magnitude > SETTINGS.maxDistance then
        PLAYERS.hide(entry)
        return
    end

    local screenPosition, onScreen = cameraWorldToScreen(position - Vector3.new(0, PLAYERS.FOOT_DROP, 0))
    if not (screenPosition and onScreen) then
        PLAYERS.hide(entry)
        return
    end

    local top = screenPosition.Y + PLAYERS.LABEL_GAP

    if SETTINGS.showPlayerHealth then
        local hearts = math.max(0, math.floor(health + 0.5))
        local maxHearts = math.max(1, math.floor((humanoid.MaxHealth or 3) + 0.5))
        PLAYERS.showLine(entry.health, hearts .. "/" .. maxHearts .. " HP", hearts <= PLAYERS.LOW_HEALTH, screenPosition.X, top)
        top = top + PLAYERS.TEXT_SIZE
    else
        PLAYERS.hideLine(entry.health)
    end

    if SETTINGS.showPlayerStamina then
        local stamina = current.Value or 0
        local text = math.floor(stamina + 0.5) .. "/" .. math.floor((maximum.Value or 0) + 0.5) .. " SP"
        PLAYERS.showLine(entry.stamina, text, stamina < SETTINGS.lowStaminaThreshold, screenPosition.X, top)
    else
        PLAYERS.hideLine(entry.stamina)
    end
end

function PLAYERS.update(now)
    if not (SETTINGS.enabled and (SETTINGS.showPlayerHealth or SETTINGS.showPlayerStamina)) then
        for _, entry in pairs(PLAYERS.entries) do
            PLAYERS.hide(entry)
        end

        return
    end

    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local cameraPosition = camera.CFrame.Position
    local localId = LocalPlayer.UserId
    local prune = now >= PLAYERS.pruneAt

    if prune then
        PLAYERS.pruneAt = now + PLAYERS.PRUNE_INTERVAL

        for userId in pairs(PLAYERS.seen) do
            PLAYERS.seen[userId] = nil
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local userId = player.UserId

        if userId ~= localId then
            if prune then
                PLAYERS.seen[userId] = true
            end

            pcall(PLAYERS.drawOne, player, cameraPosition)
        end
    end

    if prune then
        for userId, entry in pairs(PLAYERS.entries) do
            if not PLAYERS.seen[userId] then
                PLAYERS.removeEntry(entry)
                PLAYERS.entries[userId] = nil
            end
        end
    end
end

function PLAYERS.cleanup()
    for userId, entry in pairs(PLAYERS.entries) do
        PLAYERS.removeEntry(entry)
        PLAYERS.entries[userId] = nil
    end
end

local FARM = {
    entries = {},
    prompt = nil,
    banner = nil,
    acknowledged = false,
    active = false,
    PAUSE_KEY = 0x50,
    paused = false,
    pauseWanted = false,
    pauseDown = false,
    pausedAt = 0,
    TOGGLE_ID = "dw_farm_aggressive",
    BANNER = {
        TITLE_SIZE = 40,
        BODY_SIZE = 30,
        STATUS_SIZE = 40,
        LINE_GAP = 8,
        STATUS_GAP = 18,
        LIMIT = 0.10,
        HOLD = 30,
        STARTUP = 15,
    },
    status = nil,
    armedAt = 0,
    forceOffUntil = 0,
    RESUME_MAX_AGE = 300,
    resumeWritten = false,
    resumePending = false,
    FORCE_OFF_WINDOW = 3,
    RUN = {
        PASSIVE = { RazzleDazzleMonster = true, WaxwellMonster = true, ConnieMonster = true, RodgerMonster = true },
        ARRIVE = 3,
        ELEV_ARRIVE = 6,
        LOST = 14,
        STAND_Y = 3,
        E_KEY = 0x45,
        REPRESS = 3,
        DANGER = 55,
        DIVE_BUFFER = 8,
        CLOSE_RADIUS = 12,
        CLEAR_TIME = 0.4,
        clearSince = nil,
        SURFACE_BUFFER = 10,
        RAY_RECHECK = 5,
        RAY_DOWN = 50,
        RAY_HOPS = 6,
        rayWorks = false,
        rayCheckAt = 0,
        CHASER_DEFAULTS = { InstantRadius = 30, VisionRadius = 70, LineOfSight = 0.4 },
        DEPTH = 12,
        DIVE_SPEED = 50,
        HIDE_MAX = 30,
        GAIN = 5.5,
        MAX_STEP = 40,
        TOL = 6,
        AIM_MAX = 2.5,
        SACRIFICE_TOUCH = 5,
        WANT_ITEMS = { Bandage = "farmHealItems", HealthKit = "farmHealItems", JumperCable = "farmExtractionItems" },
        HEAL_ORDER = { "HealthKit", "Bandage" },
        HEAL_AT = 1,
        KEEP_ITEMS = { bandage = true, healthkit = true, jumpercable = true, valve = true, tape = true, instructions = true, extractionspeedcandy = true, bonbon = true, stopwatch = true, skillcheckcandy = true },
        MACHINE_ORDER = { "Instructions", "ExtractionSpeedCandy", "BonBon", "Stopwatch", "SkillCheckCandy" },
        STAMINA_ITEMS = { pop = true, popbottle = true },
        STAMINA_RAZZLE_RANGE = 60,
        staminaSprint = false,
        sprinting = false,
        SPRINT_OFF_EVERY = 0.8,
        SHIFT_HOLD = 0.1,
        sprintOffAt = 0,
        shiftReleaseAt = nil,
        CABLE_MAX_FILL = 0.67,
        USE_COOLDOWN = 1.5,
        KEY_HOLD = 0.12,
        itemKey = nil,
        itemKeyUp = 0,
        COLLECT_ARRIVE = 2,
        COLLECT_Y = 2.3,
        COLLECT_RETRY = 1.5,
        COLLECT_TRIES = 3,
        COLLECT_GRACE = 3,
        RESEARCH_NEAR = { WaxwellMonster = 5, ConnieMonster = 8, GlistenMonster = 8 },
        RESEARCH_GRAB_ARRIVE = 6,
        RESEARCH_GRAB_WAIT = 10,
        RESEARCH_BLOT_ARRIVE = 3,
        RESEARCH_SEEN_SCALE = 0.5,
        RESEARCH_TRAVEL_MAX = 30,
        RESEARCH_BLOT_ZONES = 10,
        RODGER_LINK = 10,
        RESEARCH_FACE_MAX = 50,
        RESEARCH_FACE_MIN = 10,
        RESEARCH_FACE_GAP = 3,
        RESEARCH_FACE_ARRIVE = 4,
        RESEARCH_FACE_REFRESH = 0.25,
        RESEARCH_RAZZLE_ARRIVE = 15,
        RESEARCH_RAZZLE_WAIT = 8,
        BLOT_HAND_RANGE = 12,
        BLOT_HAND_RECHECK = 0.25,
        SPROUT_RANGE = 18,
        RODGER_ACTIVE_RANGE = 34,
        RODGER_RISE = 3,
        SPROUT_FLEE_MARGIN = 4,
        SPROUT_RECHECK = 0.2,
        sproutAt = 0,
        sprouts = {},
        FLOOR_UP = 8,
        FLOOR_DOWN = 40,
        HIP_DEFAULT = 3,
        SURFACE_TOLERANCE = 6,
        FACE_FLOOR_TOLERANCE = 4,
        AT_MACHINE = 6,
        hipOffset = 3,
        PASSIVE_RANGE = { RodgerMonster = 40 },
        IGNORE_BODY = { BlottMonster = true },
        researched = {},
        researchMap = nil,
        research = nil,
        BUY_ORDER = { "Valve", "HealthKit", "Bandage", "JumperCable" },
        BUY_SETTING = { Valve = "farmExtractionItems", HealthKit = "farmHealItems", Bandage = "farmHealItems", JumperCable = "farmExtractionItems" },
        PRICES = { Valve = 150, HealthKit = 100, Bandage = 60, JumperCable = 65 },
        BUY_ARRIVE = 4,
        bought = {},
        buyTapes = 0,
        BUY_RANGE = 45,
        roomUntil = 0,
        targetKind = "machine",
        collect = nil,
        collectTries = 0,
        useAt = 0,
        skip = {},
        skipMap = nil,
        dead = false,
        skipped = false,
        BUTTON_WAIT = 1.5,
        sacrificeY = 0,
        phase = "idle",
        at = 0,
        current = nil,
        goalPos = nil,
        goalY = 0,
        startY = 0,
        travelStart = nil,
        hideY = 0,
        surfaceY = 0,
        hideUntil = 0,
        rmbDown = false,
        wDown = false,
        W_KEY = 0x57,
        noCollide = false,
        deathStage = 0,
        readyStage = 0,
        readyClicked = false,
        readyWidth = 0,
        readySteady = 0,
        READY_STEADY = 0.8,
        CARD_STEADY = 0.8,
        HIDE_RETARGET = 1,
        hideGoal = nil,
        hideGoalAt = 0,
        hideGoalRadius = 0,
        hideGoalLabel = "",
        elevatorHold = "armed",
        voteStage = 0,
        voteAt = 0,
        voteClicked = false,
        voteSignature = 0,
        voteSteady = 0,
        startLabel = nil,
    },
    LOBBY = {
        THRESHOLD = 0.38,
        ARRIVE = 5,
        STALL_SAMPLE = 1.2,
        STALL_DIST = 2,
        TIMEOUT = 5,
        RESET_WAIT = 7,
        ENTER_TIMEOUT = 10,
        CLICK_HOLD = 0.32,
        POLL = 1,
        VK = { W = 0x57, A = 0x41, S = 0x53, D = 0x44, ESC = 0x1B, R = 0x52, ENTER = 0x0D },
        SHIFT = 0xA0,
        SPRINT_PROBE = 0.6,
        SPRINT_RETAP = 2,
        sprintMode = nil,
        sprintStage = 0,
        sprintAt = 0,
        sprintNextAt = 0,
        shiftDown = false,
        RING = { "Hub", "NE", "Right", "SE", "Center", "SW", "Left", "NW" },
        GATES = { "Right", "Left", "Center" },
        GATE_OF = { Right = "RightGate", Left = "LeftGate", Center = "CenterGate" },
        NODES = {
            Hub = Vector3.new(14.6, 23.5, -44.2),
            NE = Vector3.new(53.9, 23.5, -57.7),
            Right = Vector3.new(71.3, 23.5, -91.2),
            SE = Vector3.new(56.1, 23.5, -131.5),
            Center = Vector3.new(16.5, 23.5, -149.3),
            SW = Vector3.new(-27.3, 23.5, -131.9),
            Left = Vector3.new(-43.1, 23.5, -88.9),
            NW = Vector3.new(-24.6, 23.5, -57.0),
        },
        edges = nil,
        held = {},
        phase = "idle",
        atNode = "Hub",
        target = nil,
        path = nil,
        legIndex = 1,
        at = 0,
        resetStage = 1,
        lastPos = nil,
        lastCheck = 0,
        stallUntil = 0,
        stallFrom = nil,
        stallTick = -1,
        pollAt = 0,
    },
    PROMPT = {
        SIZE = Vector2.new(640, 296),
        TITLE = "WARNING",
        BODY = {
            "Auto-farm is still in early access, so it may not be 100% ideal.",
            "This was stress-tested on my alt for 7 days and didn't cause any harm.",
            "DEVS CAN BE UNPREDICTABLE WITH THEIR UPDATES, SO STAY CAREFUL!",
            "Tested on version ALPHA 0.28.3.",
            "",
            "Unsafe LuaU and Raycast (at least 1500 ms) are recommended for the best results.",
        },
        CHECK_LABEL = "I understand everything written above. Remember my choice.",
    },
}

FARM.GUI = {positionOffset = 0xFC}

function FARM.guiMatches(address, offset, position)
    local x, y = memory_read("float", address + offset), memory_read("float", address + offset + 4)
    return type(x) == "number" and type(y) == "number" and math.abs(x - position.X) < 0.01 and math.abs(y - position.Y) < 0.01
end

function FARM.guiSize(gui)
    local size = gui.AbsoluteSize
    if size and size.X > 1 and size.Y > 1 then return size end
    if not VantaUI.MemoryAccess() then return size end
    local position = gui.AbsolutePosition
    local address = tonumber(gui.Address)
    if not (position and address) then return size end
    local G = FARM.GUI
    if not FARM.guiMatches(address, G.positionOffset, position) then
        if position.X == 0 and position.Y == 0 then return size end
        local found = nil
        for offset = 0x40, 0x400, 4 do
            if FARM.guiMatches(address, offset, position) then
                found = offset
                break
            end
        end
        if not found then return size end
        G.positionOffset = found
    end
    local width = memory_read("float", address + G.positionOffset + 8)
    local height = memory_read("float", address + G.positionOffset + 12)
    if type(width) ~= "number" or type(height) ~= "number" or width ~= width or height ~= height then return size end
    if width < 0 or height < 0 or width > 20000 or height > 20000 then return size end
    return Vector2.new(width, height)
end

function FARM.showPrompt()
    local P = FARM.PROMPT
    local Dialog, Body = UI.dialog(P.TITLE, "Auto-farm", "READ BEFORE CONTINUING", P.SIZE, function()
        FARM.choosePrompt(false)
    end)
    FARM.prompt = {Window = Dialog}
    Body:AddParagraph({Content = table.concat(P.BODY, "\n")})
    local Continue
    Body:AddToggle({Title = P.CHECK_LABEL, Default = false, Callback = function(value)
        Continue:SetDisabled(not value)
    end})
    Continue = Body:AddButton({Title = "Continue", Primary = true, Disabled = true, Callback = function()
        FARM.choosePrompt(true)
    end})
    Body:AddButton({Title = "No", Callback = function()
        FARM.choosePrompt(false)
    end})
end

function FARM.removePrompt()
    local prompt = FARM.prompt
    if not prompt then return end
    FARM.prompt = nil
    pcall(function()
        prompt.Window:Destroy()
    end)
end

function FARM.hideMenu()
    local Window = UI.Window
    if not (Window and Window.SetVisible) then return end
    pcall(function()
        Window:SetVisible(false)
        if Window.HideChildren then
            Window:HideChildren()
        end
    end)
end

function FARM.choosePrompt(accept)
    if not FARM.prompt then return end
    FARM.removePrompt()

    if accept then
        FARM.acknowledged = true
        FARM.active = true
        SETTINGS.farmWarningAccepted = true
        FARM.resetBanner(tick())

        if type(notify) == "function" then
            pcall(notify, "Dandy's World", "Auto-farm armed", 3)
        end

        return
    end

    FARM.acknowledged = false
    FARM.active = false
    SETTINGS.aggressiveAutoFarm = false
    pcall(UI.SetValue, FARM.TOGGLE_ID, false)
end

function FARM.makeBanner()
    local B = FARM.BANNER
    local specs = {
        { text = "Auto-farm is active", size = B.TITLE_SIZE },
        { text = "Press [P] to pause it.", size = B.BODY_SIZE },
        { text = "Made by VantaH", size = B.BODY_SIZE },
        { text = "", size = B.STATUS_SIZE, gap = B.STATUS_GAP },
    }

    local banner = { lines = {}, height = 0, x = 0.5, y = 0.5, moveAt = 0, keyText = nil, statusText = nil }

    for index, spec in ipairs(specs) do
        local drawing = makeDrawing("Text", Color3.fromRGB(255, 255, 255))
        safeSet(drawing, "Center", true)
        safeSet(drawing, "Outline", true)
        safeSet(drawing, "Font", Drawing.Fonts.SystemBold)
        safeSet(drawing, "Size", spec.size)
        safeSet(drawing, "FontSize", spec.size)
        safeSet(drawing, "ZIndex", 68)
        drawing.Text = spec.text
        banner.lines[index] = { drawing = drawing, size = spec.size, gap = spec.gap or B.LINE_GAP }
        banner.height = banner.height + spec.size + (index < #specs and banner.lines[index].gap or 0)
    end

    banner.titleText = specs[1].text
    banner.keyText = specs[2].text
    FARM.banner = banner
    return banner
end

function FARM.bannerText()
    if FARM.paused then
        return "Auto-farm is paused", "Press [P] to unpause it."
    end
    return "Auto-farm is active", "Press [P] to pause it."
end

function FARM.pollPause()
    if type(iskeypressed) ~= "function" then
        return
    end
    local ok, pressed = pcall(iskeypressed, FARM.PAUSE_KEY)
    local down = ok and pressed == true and robloxFocused()
    if down and not FARM.pauseDown then
        FARM.pauseWanted = not FARM.pauseWanted
    end
    FARM.pauseDown = down
end

function FARM.underground()
    local phase = FARM.RUN.phase
    return PLACE_MODE == "main" and (phase == "dive" or phase == "hide" or phase == "surface")
end

function FARM.statusText(now)
    if FARM.paused then
        return "Paused"
    end
    if FARM.pauseWanted then
        return "Pausing after surfacing"
    end
    if FARM.UNSAFE.missing then
        return "Unsafe LuaU is required."
    end

    local elapsed = now - FARM.armedAt
    if elapsed < FARM.BANNER.STARTUP then
        return "Starts in " .. math.ceil(FARM.BANNER.STARTUP - elapsed) .. "s"
    end

    return FARM.status or "Working"
end

function FARM.setStatus(text)
    FARM.status = text
end

FARM.UNSAFE = { interval = 3, checkedAt = -math.huge, probing = false, enabled = false }

function FARM.unsafeEnabled()
    return VantaUI.MemoryAccess(true)
end

function FARM.updateUnsafeWarning()
    local U = FARM.UNSAFE
    local warning = U.label
    if not warning then
        return
    end
    local active = SETTINGS.masteryFarm and PLACE_MODE == "lobby"
    local now = tick()
    if active and not U.enabled and not U.probing and now - U.checkedAt >= U.interval then
        U.checkedAt = now
        U.probing = true
        task.spawn(function()
            U.enabled = FARM.unsafeEnabled()
            U.probing = false
        end)
    end
    U.missing = active and not U.enabled
    warning:SetHidden(not U.missing)
end

FARM.MASTERY = {
    VISIBLE = 0x59D,
    TEXT = 0xB88,
    STATE = 0x568,
    QUESTS = {
        { "ActiveAbilityActivate", "ability", "Active Ability", "Use Active Ability %s times" },
        { "PassiveAbilityActivate", "passive", "Passive Ability", "Activate Passive Ability %s times" },
        { "TravelDistance", true, "^Travel %d+ Meters", "Travel %s Meters" },
        { "PickUpCapsule", true, "Research Capsules", "Pick up %s Research Capsules" },
        { "PickUpItem", true, "^Pick up %d+ Items", "Pick up %s Items" },
        { "UseItem", true, "^Use %d+ Items", "Use %s Items" },
        { "UseItemSpecific", true, "^Use %d+ ", "Use %s specific items" },
        { "SurviveFloorWithParty", false, "other Players", "Survive %s Floors with a party" },
        { "SurviveFloorWithToon", false, "Floors with .+ in your round", "Survive %s Floors with a toon" },
        { "SurviveFloor", true, "^Survive %d+ Floors", "Survive %s Floors" },
        { "CompleteDuoGenerator", false, "Duo Machines", "Complete %s Duo Machines" },
        { "CompleteFloorWithTrinket", false, "equipped", "Complete Floor %s with a trinket" },
        { "CompleteGenerator", true, "Machines", "Finish %s Machines" },
        { "ReachFloor", true, "^Reach Floor", "Reach Floor %s" },
        { "BuyDandyStoreItem", true, "Elevator Shop", "Buy %s items from Dandy's Shop" },
        { "CollectResearch", true, "Twisted Research", "Collect %s%% Twisted Research" },
        { "EncounterMonster", true, "^Encounter", "Encounter %s Twisteds" },
        { "BlackOut", true, "Blackouts", "Experience %s Blackouts" },
        { "IchorSpill", true, "Ichor Spills", "Experience %s Ichor Spills" },
        { "EatBookshelfOnCooldown", false, "Bookshelves", "Eat from %s Bookshelves" },
        { "IcedOver", false, "Iced", "Get Iced Over %s times" },
    },
    SPECIFIC = { Cocoa = "BonBon", Waxwell = "Instructions" },
    PASSIVE = { Eggson = "machines", Poppy = "damage", Looey = "damage" },
    PASSIVE_DOABLE = { machines = true, damage = true },
    RUN_POLL = 2,
    TRAVEL_SPEED = 50,
    runAt = 0,
    runState = nil,
    target = nil,
    running = false,
    done = false,
    stop = false,
    results = nil,
}

FARM.MASTERY.AUTO = {}
FARM.MASTERY.LABELS = {}
for _, quest in ipairs(FARM.MASTERY.QUESTS) do
    FARM.MASTERY.AUTO[quest[1]] = quest[2]
    FARM.MASTERY.LABELS[quest[1]] = quest[4]
end

function FARM.MASTERY.questType(name, text)
    if FARM.MASTERY.AUTO[name] ~= nil then return name end
    for _, quest in ipairs(FARM.MASTERY.QUESTS) do
        if text:find(quest[3]) then return quest[1] end
    end
    return name
end

function FARM.MASTERY.wants(questType)
    local M = FARM.MASTERY
    return SETTINGS.masteryFarm and PLACE_MODE == "main" and M.runLeft ~= nil and M.runLeft[questType] == true
end

function FARM.MASTERY.itemMode()
    local M = FARM.MASTERY
    return M.wants("PickUpItem") or M.wants("UseItem") or M.wants("BuyDandyStoreItem") or M.wants("UseItemSpecific")
end

function FARM.MASTERY.capsuleMode()
    return FARM.MASTERY.wants("PickUpCapsule") or FARM.MASTERY.wants("CollectResearch")
end

function FARM.MASTERY.researchMode()
    return FARM.MASTERY.wants("CollectResearch") or FARM.MASTERY.wants("EncounterMonster")
end

function FARM.MASTERY.specificItem()
    local M = FARM.MASTERY
    if not M.wants("UseItemSpecific") then return nil end
    return M.runToon and M.SPECIFIC[M.runToon] or nil
end

function FARM.MASTERY.abilityMode(name)
    local M = FARM.MASTERY
    local item = M.specificItem()
    local info = item and ITEM_INFO[item]
    return M.wants("ActiveAbilityActivate") or (info ~= nil and info.abilityOnly == true and M.SPECIFIC[name] == item)
end

function FARM.MASTERY.passiveDeath()
    local M = FARM.MASTERY
    if not (SETTINGS.masteryFarm and PLACE_MODE == "main" and M.runLeft and M.runLeft.PassiveAbilityActivate) then return false end
    if not (M.runToon and M.PASSIVE[M.runToon] == "damage") then return false end
    for questType in pairs(M.runLeft) do
        if questType ~= "PassiveAbilityActivate" and questType ~= "TravelDistance" then return false end
    end
    return true
end

function FARM.MASTERY.travelOnly()
    local M = FARM.MASTERY
    if not (SETTINGS.masteryFarm and PLACE_MODE == "main" and M.runLeft) then return false end
    local any = false
    for questType in pairs(M.runLeft) do
        if questType ~= "TravelDistance" then return false end
        any = true
    end
    return any
end

function FARM.MASTERY.itemInfo(key)
    local M = FARM.MASTERY
    if not M.itemKeys then
        M.itemKeys = {}
        for name, info in pairs(ITEM_INFO) do
            M.itemKeys[FARM.runItemKey(name)] = info
        end
    end
    return M.itemKeys[key]
end

function FARM.MASTERY.health(character)
    local humanoid = character and character:FindFirstChild("Humanoid")
    local ok, health, maxHealth = pcall(function()
        return humanoid.Health, humanoid.MaxHealth
    end)
    if ok and type(health) == "number" and type(maxHealth) == "number" then return health, maxHealth end
    return nil, nil
end

function FARM.MASTERY.useItems(now, character)
    local M = FARM.MASTERY
    local R = FARM.RUN
    local health, maxHealth = M.health(character)
    local hurt = health ~= nil and health > 0 and health < maxHealth
    local working = R.phase == "working" and R.current ~= nil and FARM.runEngagedBy(R.current) == LocalPlayer.Name
    local inventory = FARM.runInventory(character)
    M.blocked = M.blocked or {}
    local last = M.lastUse
    if last then
        M.lastUse = nil
        for _, slot in ipairs(inventory) do
            if slot.index == last.index and FARM.runItemKey(slot.item) == last.key and not last.charges then
                M.blocked[last.key] = now + 8
            end
        end
    end
    for _, slot in ipairs(inventory) do
        local key = FARM.runItemKey(slot.item)
        if key ~= "" and key ~= "none" and now >= (M.blocked[key] or 0) then
            local info = M.itemInfo(key)
            local heal = info ~= nil and info.use == "Healing"
            local machine = info ~= nil and info.needsMachine == true
            local stamina = R.STAMINA_ITEMS[key] and FARM.runStaminaFull(character)
            if stamina then
                R.staminaSprint = true
            elseif (heal and hurt) or (machine and working) or (not heal and not machine) then
                FARM.runPressItem(now, slot.index)
                R.useAt = now + R.USE_COOLDOWN
                M.lastUse = {index = slot.index, key = key, charges = info ~= nil and info.charges ~= nil}
                FARM.setStatus("Mastery: using " .. slot.item)
                return true
            end
        end
    end
    return false
end

function FARM.MASTERY.itemOnMap()
    local R = FARM.RUN
    local map = FARM.runMap()
    local folder = map and map:FindFirstChild("Items")
    for _, model in ipairs(folder and folder:GetChildren() or {}) do
        local info = ITEM_INFO[model.Name]
        if info and info.use ~= "Collectible" then
            local prompt = model:FindFirstChild("Prompt")
            local ok, position = pcall(function() return prompt.Position end)
            if ok and position and not R.skip[FARM.runSpotKey(position)] then return true end
        end
    end
    return false
end

function FARM.MASTERY.needHit(now, character)
    local M = FARM.MASTERY
    if not M.itemMode() or now < (M.hitBlockUntil or 0) or FARM.runHasFreeSlot(character) then return false end
    local health, maxHealth = M.health(character)
    if not health or health <= 0 or health < maxHealth then return false end
    local heals = false
    for _, slot in ipairs(FARM.runInventory(character)) do
        local info = M.itemInfo(FARM.runItemKey(slot.item))
        if info and info.use == "Healing" then heals = true end
    end
    return heals and M.itemOnMap()
end

function FARM.MASTERY.wanderPoint(root)
    local M = FARM.MASTERY
    local map = FARM.runMap()
    local here = root.Position
    local goal = M.wanderGoal
    if goal and M.wanderMap == map and Vector3.new(goal.X - here.X, 0, goal.Z - here.Z).Magnitude > 8 then
        return goal
    end
    local points = {}
    local folder = map and map:FindFirstChild("Waypoints")
    for _, Waypoint in ipairs(folder and folder:GetChildren() or {}) do
        local ok, position = pcall(function() return Waypoint.Position end)
        if ok and position then table.insert(points, position) end
    end
    if #points == 0 then
        for _, machine in ipairs(FARM.runMachines()) do
            local ok, position = pcall(function() return machine.stand.Position end)
            if ok and position then table.insert(points, position) end
        end
    end
    if #points == 0 then return nil end
    table.sort(points, function(a, b)
        return Vector3.new(a.X - here.X, 0, a.Z - here.Z).Magnitude > Vector3.new(b.X - here.X, 0, b.Z - here.Z).Magnitude
    end)
    M.wanderGoal = points[math.random(1, math.max(1, math.floor(#points / 3)))]
    M.wanderMap = map
    return M.wanderGoal
end

function FARM.MASTERY.byte(gui, offset)
    local ok, value = pcall(memory_read, "byte", gui.Address + offset)
    return ok and value or 0
end

function FARM.MASTERY.shown(gui)
    local M = FARM.MASTERY
    while gui and gui.ClassName ~= "ScreenGui" and gui.ClassName ~= "PlayerGui" and gui.ClassName ~= "CoreGui" do
        if M.byte(gui, M.VISIBLE) == 0 then return false end
        gui = gui.Parent
    end
    return true
end

function FARM.MASTERY.text(label)
    if not label then return "" end
    local ok, text = pcall(function()
        local address = label.Address + FARM.MASTERY.TEXT
        if memory_read("int", address + 24) > 15 then
            return memory_read("string", memory_read("uintptr_t", address))
        end
        return memory_read("string", address)
    end)
    return ok and type(text) == "string" and text or ""
end

function FARM.MASTERY.waitFor(check, timeout)
    local deadline = tick() + timeout
    while tick() < deadline do
        if FARM.MASTERY.stop then return false end
        if check() then return true end
        task.wait(0.05)
    end
    return check()
end

function FARM.MASTERY.waitFocus()
    if robloxFocused() then return true end
    FARM.setStatus("Mastery: waiting for Roblox focus")
    local focused = FARM.MASTERY.waitFor(robloxFocused, 600)
    FARM.setStatus("Checking mastery")
    return focused
end

function FARM.MASTERY.centre(gui)
    local position, size = gui.AbsolutePosition, FARM.guiSize(gui)
    return math.floor(position.X + size.X / 2 + 0.5), math.floor(position.Y + size.Y / 2 + 0.5)
end

function FARM.MASTERY.moveTo(x, y)
    local offset = FARM.MASTERY.offset or { x = 0, y = 0 }
    mousemoveabs(x + offset.x, y + offset.y)
end

function FARM.MASTERY.calibrate()
    local M = FARM.MASTERY
    local Mouse = LocalPlayer:GetMouse()
    local samples = {}
    for _, point in ipairs({ { 640, 480 }, { 1200, 700 } }) do
        mousemoveabs(point[1], point[2])
        task.wait(0.2)
        local ok, mx, my = pcall(function() return Mouse.X, Mouse.Y end)
        if ok and type(mx) == "number" and type(my) == "number" then
            table.insert(samples, { x = point[1] - mx, y = point[2] - my })
        end
    end
    local first, second = samples[1], samples[2]
    if first and second and math.abs(first.x - second.x) <= 3 and math.abs(first.y - second.y) <= 3 then
        M.offset = { x = math.floor((first.x + second.x) / 2 + 0.5), y = math.floor((first.y + second.y) / 2 + 0.5) }
    else
        M.offset = { x = 0, y = 0 }
    end
end

function FARM.MASTERY.click(gui, delay)
    local M = FARM.MASTERY
    if not M.waitFocus() then return false end
    local x, y = M.centre(gui)
    M.moveTo(x, y)
    task.wait(0.03)
    mousemoverel(1, 0)
    M.waitFor(function()
        local state = M.byte(gui, M.STATE)
        return state == 1 or state == 2
    end, 0.3)
    if delay then task.wait(delay) end
    mouse1click()
    task.wait(0.15)
    return true
end

function FARM.MASTERY.clickUntil(gui, check, timeout, tries, delay)
    local M = FARM.MASTERY
    for _ = 1, tries or 3 do
        if M.stop then return false end
        M.click(gui, delay)
        if M.waitFor(check, timeout) then return true end
    end
    return false
end

function FARM.MASTERY.chat()
    local CoreGui = game:GetService("CoreGui")
    local Chat = CoreGui:FindFirstChild("ExperienceChat")
    local Layout = Chat and Chat:FindFirstChild("appLayout")
    local TopBar = CoreGui:FindFirstChild("TopBarApp")
    local Icon
    for _, Item in ipairs(TopBar and TopBar:GetDescendants() or {}) do
        if Item.Name == "IconHitArea_chat" then
            Icon = Item
            break
        end
    end
    return Layout, Icon
end

function FARM.MASTERY.chatOpen()
    local M = FARM.MASTERY
    local Layout = M.chat()
    if not Layout then return false end
    if Layout:FindFirstChild("chatWindow") then return true end
    local InputRow = Layout:FindFirstChild("chatInputRow")
    return InputRow ~= nil and M.byte(InputRow, M.VISIBLE) == 1
end

function FARM.MASTERY.closeChat()
    local M = FARM.MASTERY
    if not M.chatOpen() then return true end
    local _, Icon = M.chat()
    if not Icon then return false end
    return M.clickUntil(Icon, function() return not M.chatOpen() end, 1.5)
end

function FARM.MASTERY.ui()
    local MainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
    if not MainGui then return nil end
    local ok, ui = pcall(function()
        return {
            toonsButton = MainGui.Menu.LeftSide.CharacterButton,
            toons = MainGui.CharacterFrame,
            cards = MainGui.CharacterFrame.ScrollingFrame,
            selectedName = MainGui.CharacterFrame.DescribeFrame.CharacterName,
            masteryButton = MainGui.CharacterFrame.MasteryFrame.SelectCharacter,
            selectButton = MainGui.CharacterFrame.DescribeFrame.SelectCharacter,
            toonsExit = MainGui.CharacterFrame.ExitButton,
            mastery = MainGui.MasteryFrame,
            holder = MainGui.MasteryFrame.HolderFrame,
            masteryExit = MainGui.MasteryFrame.ExitButton,
        }
    end)
    return ok and ui or nil
end

function FARM.MASTERY.openToons(ui)
    local M = FARM.MASTERY
    if M.shown(ui.toons) then return true end
    return M.clickUntil(ui.toonsButton, function() return M.shown(ui.toons) end, 2)
end

function FARM.MASTERY.owned(ui)
    local M = FARM.MASTERY
    local toons = {}
    for _, Card in ipairs(ui.cards:GetChildren()) do
        if Card.ClassName == "TextButton" and Card.Name ~= "Template" and M.byte(Card, M.VISIBLE) == 1 then
            local Star = Card:FindFirstChild("MasteryStar")
            table.insert(toons, {
                name = Card.Name,
                label = M.text(Card:FindFirstChild("CharacterName")),
                card = Card,
                mastered = Star ~= nil and M.byte(Star, M.VISIBLE) == 1,
            })
        end
    end
    table.sort(toons, function(a, b)
        local pa, pb = a.card.AbsolutePosition, b.card.AbsolutePosition
        if math.abs(pa.Y - pb.Y) > 5 then return pa.Y < pb.Y end
        return pa.X < pb.X
    end)
    return toons
end

function FARM.MASTERY.offView(ui, card)
    local ok, cardTop, cardBottom, top, bottom = pcall(function()
        local cardTop = card.AbsolutePosition.Y
        local top = ui.cards.AbsolutePosition.Y
        return cardTop, cardTop + FARM.guiSize(card).Y, top, top + FARM.guiSize(ui.cards).Y
    end)
    if not ok then return nil end
    if cardTop < top - 1 then return -1 end
    if cardBottom > bottom + 1 then return 1 end
    return 0
end

function FARM.MASTERY.scrollTo(ui, card)
    local M = FARM.MASTERY
    local direction = M.offView(ui, card)
    if direction == nil then
        task.wait(0.1)
        direction = M.offView(ui, card) or 0
    end
    if direction == 0 then return true end
    local stuck = 0
    for _ = 1, 30 do
        if M.stop or not M.waitFocus() then return false end
        local x, y = M.centre(ui.cards)
        M.moveTo(x, y)
        task.wait(0.03)
        local okBefore, before, notches = pcall(function()
            local before = card.AbsolutePosition.Y
            local top = ui.cards.AbsolutePosition.Y
            local edge = direction > 0 and (top + FARM.guiSize(ui.cards).Y) or top
            local cardEdge = direction > 0 and (before + FARM.guiSize(card).Y) or before
            return before, math.clamp(math.ceil(math.abs(cardEdge - edge) / 100), 1, 5)
        end)
        if not okBefore then before, notches = nil, 1 end
        mousescroll(-direction * notches)
        task.wait(0.35)
        local okAfter, after = pcall(function() return card.AbsolutePosition.Y end)
        local moved = (okAfter and before) and (after - before) or 100
        stuck = math.abs(moved) < 1 and stuck + 1 or 0
        direction = M.offView(ui, card) or direction
        if direction == 0 then return true end
        if stuck >= 3 then
            local okCentre, inside = pcall(function()
                local _, y = M.centre(card)
                return y > ui.cards.AbsolutePosition.Y and y < ui.cards.AbsolutePosition.Y + FARM.guiSize(ui.cards).Y
            end)
            return okCentre and inside
        end
    end
    return false
end

function FARM.MASTERY.entries(ui)
    local entries = {}
    for _, Entry in ipairs(ui.holder:GetChildren()) do
        if Entry.Name ~= "Template" and Entry:FindFirstChild("CharacterAmount") then table.insert(entries, Entry) end
    end
    return entries
end

function FARM.MASTERY.signature(ui)
    local M = FARM.MASTERY
    local parts = {}
    for _, Entry in ipairs(M.entries(ui)) do
        table.insert(parts, tostring(Entry.Address) .. M.text(Entry.CharacterName) .. M.text(Entry.CharacterAmount))
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

function FARM.MASTERY.quests(ui)
    local M = FARM.MASTERY
    local quests = {}
    for _, Entry in ipairs(M.entries(ui)) do
        local progress = M.text(Entry.CharacterAmount)
        local text = M.text(Entry.CharacterName)
        local current, amount = progress:gsub(",", ""):match("(%d+)%s*/%s*(%d+)")
        local quest = {
            type = M.questType(Entry.Name, text),
            text = text,
            progress = progress,
            current = tonumber(current),
            amount = tonumber(amount),
            row = Entry.AbsolutePosition.Y,
            column = Entry.AbsolutePosition.X,
        }
        quest.done = progress:upper():find("COMPLETE") ~= nil or (quest.current ~= nil and quest.amount ~= nil and quest.current >= quest.amount)
        table.insert(quests, quest)
    end
    table.sort(quests, function(a, b)
        if math.abs(a.row - b.row) > 5 then return a.row < b.row end
        return a.column < b.column
    end)
    for _, quest in ipairs(quests) do
        quest.row = nil
        quest.column = nil
    end
    return quests
end

function FARM.MASTERY.canDo(questType, toonName)
    local auto = FARM.MASTERY.AUTO[questType]
    if auto == "passive" then
        local trigger = toonName and FARM.MASTERY.PASSIVE[toonName]
        return trigger ~= nil and FARM.MASTERY.PASSIVE_DOABLE[trigger] == true
    end
    if auto == "ability" then
        local rules = FARM.MASTERY.toonRules
        return rules ~= nil and toonName ~= nil and rules[toonName] ~= nil
    end
    return auto == true
end

function FARM.MASTERY.equipped()
    local char = LocalPlayer.Character
    local ok, name = pcall(function() return char and char:GetAttribute("ToonName") end)
    return ok and name or nil
end

function FARM.MASTERY.select(ui, toon)
    local M = FARM.MASTERY
    if M.equipped() == toon.name then return true end
    if not M.openToons(ui) then return false end
    if not M.scrollTo(ui, toon.card) then return false end
    if not M.clickUntil(toon.card, function() return M.text(ui.selectedName) == toon.label end, 1.5) then return false end
    return M.clickUntil(ui.selectButton, function() return M.equipped() == toon.name end, 3, 3, 0.2)
end

function FARM.MASTERY.readToon(ui, toon)
    local M = FARM.MASTERY
    if not M.openToons(ui) then return nil, "toons menu did not open" end
    if not M.scrollTo(ui, toon.card) then return nil, "could not scroll to the card" end
    if not M.clickUntil(toon.card, function() return M.text(ui.selectedName) == toon.label end, 1.5) then return nil, "card did not select" end
    local before = M.signature(ui)
    if not M.clickUntil(ui.masteryButton, function() return M.shown(ui.mastery) end, 2, 3, 0.2) then return nil, "mastery window did not open" end
    M.waitFor(function()
        local now = M.signature(ui)
        return now ~= "" and now ~= before
    end, 2)
    task.wait(0.3)
    local quests = M.quests(ui)
    M.clickUntil(ui.masteryExit, function() return not M.shown(ui.mastery) end, 1.5)
    if #quests == 0 then return nil, "no quests read" end
    return quests
end

function FARM.MASTERY.scan()
    local M = FARM.MASTERY
    local ui = M.ui()
    if not ui then return end
    FARM.setStatus("Checking mastery")
    if not M.waitFocus() then return end
    M.calibrate()
    M.closeChat()
    if not M.openToons(ui) then return end
    task.wait(0.3)
    local chosen
    local current = M.equipped()
    local ordered = {}
    for _, toon in ipairs(M.owned(ui)) do
        if toon.name == current then
            table.insert(ordered, 1, toon)
        elseif SETTINGS.masterySelect then
            table.insert(ordered, toon)
        end
    end
    for _, toon in ipairs(ordered) do
        if M.stop then return end
        if not toon.mastered then
            FARM.setStatus("Checking mastery: " .. toon.label)
            local quests
            for _ = 1, 2 do
                quests = M.readToon(ui, toon)
                if quests or M.stop then break end
            end
            if quests then
                local left = {}
                for _, quest in ipairs(quests) do
                    if not quest.done and M.canDo(quest.type, toon.name) then
                        table.insert(left, quest.text .. " " .. quest.progress)
                    end
                end
                if #left > 0 then
                    chosen = toon
                    break
                end
            end
        end
    end
    if M.stop then return end
    if chosen then
        FARM.setStatus("Selecting " .. chosen.label)
        if M.select(ui, chosen) then
            M.target = chosen.name
        end
    else
        SETTINGS.masteryFarm = false
        pcall(UI.SetValue, "dw_mastery_farm", false)
        pcall(notify, "Dandy's World", SETTINGS.masterySelect and "Mastery farm finished every toon." or "Mastery farm finished this toon.", 4)
    end
    if M.shown(ui.mastery) then M.clickUntil(ui.masteryExit, function() return not M.shown(ui.mastery) end, 1.5) end
    if M.shown(ui.toons) then M.clickUntil(ui.toonsExit, function() return not M.shown(ui.toons) end, 1.5) end
end

function FARM.MASTERY.runUpdate()
    local M = FARM.MASTERY
    if PLACE_MODE ~= "main" or not SETTINGS.masteryFarm then
        M.runState = nil
        M.runLeft = nil
        return
    end
    local now = tick()
    if now < M.runAt then return end
    M.runAt = now + M.RUN_POLL
    local ok, state = pcall(function()
        local char = LocalPlayer.Character
        local toonName = M.toonName and M.toonName(char)
        if not toonName then return nil end
        local Folder = game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Mastery:FindFirstChild(toonName)
        if not Folder then return nil end
        local left, total, types, reach = 0, 0, {}, nil
        for _, Quest in ipairs(Folder:GetChildren()) do
            local Current, Amount = Quest:FindFirstChild("Current"), Quest:FindFirstChild("Amount")
            if Current and Amount then
                total = total + 1
                local questType = M.questType(Quest.Name, "")
                if M.canDo(questType, toonName) and Current.Value < Amount.Value then
                    types[questType] = true
                    if questType == "ReachFloor" then reach = Amount.Value end
                    left = left + 1
                end
            end
        end
        if total == 0 then return nil end
        M.runLeft = types
        M.reachFloor = reach
        M.runToon = toonName
        return left == 0 and "done" or "working"
    end)
    local newState = ok and state or nil
    if not newState then M.runLeft = nil end
    M.runState = newState
end

function FARM.MASTERY.update()
    local M = FARM.MASTERY
    local wanted = SETTINGS.masteryFarm and PLACE_MODE == "lobby" and FARM.active and not FARM.paused and not FARM.pauseWanted
        and tick() - FARM.armedAt >= FARM.BANNER.STARTUP
    if not wanted then
        M.done = false
        if M.running then M.stop = true end
        return
    end
    if M.running or M.done or not FARM.UNSAFE.enabled then return end
    M.running = true
    M.done = true
    M.stop = false
    task.spawn(function()
        pcall(M.scan)
        M.running = false
        FARM.setStatus(nil)
    end)
end

function FARM.resetBanner(now)
    FARM.status = nil
    FARM.armedAt = now
    FARM.paused = false
    FARM.pauseWanted = false

    local banner = FARM.banner
    if banner then
        banner.x = 0.5
        banner.y = 0.5
        banner.moveAt = now + FARM.BANNER.HOLD
    end
end

function FARM.hideBanner()
    local banner = FARM.banner
    if not banner then
        return
    end

    for _, line in ipairs(banner.lines) do
        line.drawing.Visible = false
    end
end

function FARM.updateBanner(now)
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local banner = FARM.banner
    if not banner then
        banner = FARM.makeBanner()
        banner.moveAt = now + FARM.BANNER.HOLD
    end

    local B = FARM.BANNER
    local titleText, keyText = FARM.bannerText()

    if banner.titleText ~= titleText then
        banner.titleText = titleText
        banner.lines[1].drawing.Text = titleText
    end

    if banner.keyText ~= keyText then
        banner.keyText = keyText
        banner.lines[2].drawing.Text = keyText
    end

    local statusText = FARM.statusText(now)
    if banner.statusText ~= statusText then
        banner.statusText = statusText
        banner.lines[4].drawing.Text = statusText
    end

    if now >= banner.moveAt then
        banner.moveAt = now + B.HOLD
        banner.x = 0.5 + (math.random() * 2 - 1) * B.LIMIT
        banner.y = 0.5 + (math.random() * 2 - 1) * B.LIMIT
    end

    local viewport = camera.ViewportSize
    local px = viewport.X * banner.x
    local py = viewport.Y * banner.y - banner.height / 2

    for _, line in ipairs(banner.lines) do
        line.drawing.Position = Vector2.new(px, py)
        line.drawing.Visible = true
        py = py + line.size + line.gap
    end
end

function FARM.resumeClock()
    local ok, value = pcall(os.time)
    if ok and type(value) == "number" then
        return value
    end
    return tick()
end

function FARM.writeResume()
    if FARM.resumeWritten or not SETTINGS.farmAutoResume then
        return
    end

    SETTINGS.resumeAutoFarm = true
    SETTINGS.resumeAutoFarmAt = FARM.resumeClock()
    saveConfig()
    FARM.resumeWritten = true
end

function FARM.clearResume()
    if not FARM.resumeWritten and not SETTINGS.resumeAutoFarm then
        return
    end

    FARM.resumeWritten = false
    SETTINGS.resumeAutoFarm = false
    SETTINGS.resumeAutoFarmAt = 0
    saveConfig()
end

function FARM.consumeResume()
    local armed = SETTINGS.resumeAutoFarm == true
    local age = FARM.resumeClock() - (SETTINGS.resumeAutoFarmAt or 0)

    if armed then
        SETTINGS.resumeAutoFarm = false
        SETTINGS.resumeAutoFarmAt = 0
        saveConfig()
    end

    return armed and age >= 0 and age <= FARM.RESUME_MAX_AGE
end

function FARM.update(now)
    if now >= FARM.forceOffUntil and FARM.resumePending then
        FARM.resumePending = false

        if SETTINGS.farmAutoResume and SETTINGS.farmWarningAccepted and PLACE_MODE ~= "other" then
            SETTINGS.aggressiveAutoFarm = true
            if UI then
                pcall(UI.SetValue, FARM.TOGGLE_ID, true)
            end
            if type(notify) == "function" then
                pcall(notify, "Dandy's World", "Auto-farm resumed after teleport", 3)
            end
            if SETTINGS.farmHideOnTeleport then
                FARM.hideMenu()
            end
        end
    end

    if now < FARM.forceOffUntil then
        if SETTINGS.aggressiveAutoFarm then
            SETTINGS.aggressiveAutoFarm = false

            if UI then
                pcall(UI.SetValue, FARM.TOGGLE_ID, false)
            end
        end

        FARM.acknowledged = false
        FARM.active = false
        return
    end

    if SETTINGS.aggressiveAutoFarm then
        if not (FARM.active or FARM.prompt or FARM.acknowledged) then
            if SETTINGS.farmWarningAccepted then
                FARM.acknowledged = true
                FARM.active = true
                FARM.resetBanner(now)
            else
                FARM.showPrompt()
            end
        end
    else
        if FARM.prompt then
            FARM.removePrompt()
        end

        FARM.clearResume()
        FARM.acknowledged = false
        FARM.active = false
        FARM.paused = false
        FARM.pauseWanted = false
    end

    if FARM.active then
        FARM.pollPause()

        if FARM.pauseWanted and not FARM.paused and not FARM.underground() then
            FARM.paused = true
            FARM.pausedAt = now
            FARM.status = nil
            FARM.lobbyStop()
            FARM.runStop()
        elseif not FARM.pauseWanted and FARM.paused then
            FARM.paused = false
            if FARM.pausedAt - FARM.armedAt < FARM.BANNER.STARTUP then
                FARM.armedAt = FARM.armedAt + (now - FARM.pausedAt)
            end
        end

        FARM.updateBanner(now)

        if not FARM.paused and now - FARM.armedAt >= FARM.BANNER.STARTUP then
            if PLACE_MODE == "lobby" and (FARM.MASTERY.running or (SETTINGS.masteryFarm and FARM.UNSAFE.enabled and not FARM.MASTERY.done)) then
                FARM.lobbyStop()
            elseif PLACE_MODE == "lobby" then
                FARM.lobbyUpdate(now)
            elseif PLACE_MODE == "main" then
                FARM.runUpdate(now)
            end
        end
    else
        FARM.hideBanner()
        FARM.lobbyStop()
        FARM.runStop()
    end
end

function FARM.cleanup()
    FARM.removePrompt()
    FARM.lobbyStop()
    FARM.runStop()

    local banner = FARM.banner
    if banner then
        for _, line in ipairs(banner.lines) do
            pcall(function()
                line.drawing:Remove()
            end)
        end

        FARM.banner = nil
    end

    FARM.active = false
    FARM.acknowledged = false
end

function FARM.lobbyEdges()
    local L = FARM.LOBBY
    if L.edges then
        return L.edges
    end

    local edges = {}
    for index = 1, #L.RING do
        local a = L.RING[index]
        local b = L.RING[(index % #L.RING) + 1]
        local d = (L.NODES[a] - L.NODES[b]).Magnitude
        edges[a] = edges[a] or {}
        edges[b] = edges[b] or {}
        edges[a][b] = d
        edges[b][a] = d
    end

    L.edges = edges
    return edges
end

function FARM.shortest(from, to)
    local edges = FARM.lobbyEdges()
    local dist, prev, done = {}, {}, {}

    for node in pairs(edges) do
        dist[node] = math.huge
    end
    dist[from] = 0

    while true do
        local cur, best = nil, math.huge
        for node, d in pairs(dist) do
            if not done[node] and d < best then
                cur, best = node, d
            end
        end

        if not cur or cur == to then
            break
        end

        done[cur] = true
        for nb, w in pairs(edges[cur]) do
            if dist[cur] + w < dist[nb] then
                dist[nb] = dist[cur] + w
                prev[nb] = cur
            end
        end
    end

    local path, node = {}, to
    while node do
        table.insert(path, 1, node)
        node = prev[node]
    end

    if path[1] ~= from then
        return { from, to }, 9999
    end

    return path, dist[to]
end

function FARM.gateLabel(gateName, which)
    local folder = Workspace:FindFirstChild("Elevators")
    local gate = folder and folder:FindFirstChild(gateName)
    local billboard = gate and gate:FindFirstChild("billboardPart")
    local gui = billboard and billboard:FindFirstChild("billboardGui")
    local frame = gui and gui:FindFirstChild("Frame")
    local label = frame and frame:FindFirstChild(which)
    if not label then
        return nil
    end

    local ok, text = pcall(function()
        return label.Text
    end)

    return ok and text or nil
end

function FARM.gateCount(gateName)
    local text = FARM.gateLabel(gateName, "players")
    if not text then
        return -1
    end

    return tonumber(string.match(text, "^(%d+)")) or -1
end

function FARM.gateOpen(gateName)
    local folder = Workspace:FindFirstChild("Elevators")
    local gate = folder and folder:FindFirstChild(gateName)
    local elevator = gate and gate:FindFirstChild("Elevator")
    local opened = elevator and elevator:FindFirstChild("Opened")
    return (opened and opened.Value) or false
end

function FARM.gateInside(gateName)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local folder = Workspace:FindFirstChild("Elevators")
    local gate = folder and folder:FindFirstChild(gateName)
    local elevator = gate and gate:FindFirstChild("Elevator")
    local base = elevator and elevator:FindFirstChild("Base")
    if not (root and base) then
        return false
    end

    local d = root.Position - base.Position
    return math.abs(d.X) <= 20 and math.abs(d.Z) <= 20
end

function FARM.pickGate(from)
    local L = FARM.LOBBY
    local best, bestCost

    for _, node in ipairs(L.GATES) do
        local gateName = L.GATE_OF[node]
        if FARM.gateOpen(gateName) and FARM.gateCount(gateName) == 0 then
            local _, cost = FARM.shortest(from, node)
            if not bestCost or cost < bestCost then
                best, bestCost = node, cost
            end
        end
    end

    return best
end

function FARM.setKey(code, want)
    local held = FARM.LOBBY.held
    if want and not held[code] then
        held[code] = true
        pcall(keypress, code)
    elseif not want and held[code] then
        held[code] = nil
        pcall(keyrelease, code)
    end
end

function FARM.releaseKeys()
    local held = FARM.LOBBY.held
    for code in pairs(held) do
        held[code] = nil
        pcall(keyrelease, code)
    end
end

function FARM.tapKey(code)
    if gameTyping() then return end
    pcall(keypress, code)
    pcall(keyrelease, code)
end

function FARM.steer(root, camera, targetPosition)
    local L = FARM.LOBBY
    local position = root.Position
    local flat = Vector3.new(targetPosition.X - position.X, 0, targetPosition.Z - position.Z)
    local distance = flat.Magnitude
    if distance < 0.01 then
        return 0
    end

    local direction = flat.Unit
    local look = camera.CFrame.LookVector
    local lookFlat = Vector3.new(look.X, 0, look.Z)
    if lookFlat.Magnitude < 0.001 then
        return distance
    end

    lookFlat = lookFlat.Unit
    local right = Vector3.new(-lookFlat.Z, 0, lookFlat.X)
    local forward = direction.X * lookFlat.X + direction.Z * lookFlat.Z
    local side = direction.X * right.X + direction.Z * right.Z

    FARM.setKey(L.VK.W, forward > L.THRESHOLD)
    FARM.setKey(L.VK.S, forward < -L.THRESHOLD)
    FARM.setKey(L.VK.D, side > L.THRESHOLD)
    FARM.setKey(L.VK.A, side < -L.THRESHOLD)
    return distance
end

function FARM.lobbyPlan(dest, from)
    local L = FARM.LOBBY
    L.target = dest
    L.path = FARM.shortest(from, dest)
    L.legIndex = 1
    L.lastPos = nil
end

function FARM.lobbyGoHub()
    local L = FARM.LOBBY
    if L.atNode == "Hub" then
        L.phase = "waitHub"
        L.at = 0
        return
    end

    FARM.lobbyPlan("Hub", L.atNode)
    L.phase = "walk"
end

function FARM.setShift(down)
    local L = FARM.LOBBY
    if down == L.shiftDown then
        return
    end

    L.shiftDown = down
    if down then
        if gameTyping() then
            L.shiftDown = false
            return
        end
        pcall(keypress, L.SHIFT)
    else
        pcall(keyrelease, L.SHIFT)
    end
end

function FARM.isSprinting()
    local character = LocalPlayer.Character
    local stats = character and character:FindFirstChild("Stats")
    if not stats then
        return false
    end

    local flag = stats:FindFirstChild("HoldingSprint") or stats:FindFirstChild("Sprinting")
    if not flag then
        return false
    end

    local ok, value = pcall(function()
        return flag.Value
    end)

    return ok and value == true
end

function FARM.sprintSetting()
    local ok, value = pcall(function()
        return game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].SprintToggle.Value
    end)
    if ok and type(value) == "boolean" then
        return value and "toggle" or "hold"
    end
    return nil
end

function FARM.sprintUpdate(now, want)
    local L = FARM.LOBBY
    if L.sprintMode == nil then
        L.sprintMode = FARM.sprintSetting()
    end

    if not want then
        if L.sprintMode == "hold" then
            FARM.setShift(false)
        end
        return
    end

    if L.sprintMode == nil then
        if L.sprintStage == 0 then
            if FARM.isSprinting() then
                return
            end

            FARM.setShift(true)
            L.sprintStage = 1
            L.sprintAt = now + L.SPRINT_PROBE
        elseif L.sprintStage == 1 and now >= L.sprintAt then
            FARM.setShift(false)
            L.sprintStage = 2
            L.sprintAt = now + L.SPRINT_PROBE
        elseif L.sprintStage == 2 and now >= L.sprintAt then
            L.sprintMode = FARM.isSprinting() and "toggle" or "hold"
            L.sprintStage = 3
        end

        return
    end

    if L.sprintMode == "hold" then
        FARM.setShift(true)
        return
    end

    if not FARM.isSprinting() and now >= L.sprintNextAt then
        L.sprintNextAt = now + L.SPRINT_RETAP
        FARM.tapKey(L.SHIFT)
    end
end

function FARM.lobbyNext()
    local L = FARM.LOBBY
    local best = FARM.pickGate(L.atNode)

    if not best then
        FARM.setStatus("All elevators busy")
        FARM.lobbyGoHub()
        return
    end

    if best == L.atNode then
        L.target = best
        L.phase = "enter"
        L.at = tick() + L.ENTER_TIMEOUT
        FARM.setStatus("Entering " .. best)
        return
    end

    FARM.lobbyPlan(best, L.atNode)
    L.phase = "walk"
end

function FARM.lobbyReset(reason)
    local L = FARM.LOBBY
    FARM.releaseKeys()
    L.phase = "reset"
    L.resetStage = 1
    L.lastPos = nil
    L.stallFrom = nil
    FARM.setStatus("Resetting")
end

function FARM.moveGuard(root, now, restore)
    local L = FARM.LOBBY

    if not L.lastPos then
        L.lastPos = root.Position
        L.lastCheck = now
        return false
    end

    local moved = (root.Position - L.lastPos).Magnitude

    if L.stallFrom then
        if moved >= L.STALL_DIST then
            L.stallFrom = nil
            L.stallTick = -1
            L.lastPos = root.Position
            L.lastCheck = now
            FARM.setStatus(restore)
            return false
        end

        local left = math.ceil(L.stallUntil - now)
        if left ~= L.stallTick then
            L.stallTick = left
            FARM.setStatus("Timeout " .. math.max(left, 0) .. "s")
        end

        if now >= L.stallUntil then
            L.stallFrom = nil
            L.stallTick = -1
            FARM.lobbyReset("stall")
            return true
        end

        return false
    end

    if now - L.lastCheck >= L.STALL_SAMPLE then
        if moved < L.STALL_DIST then
            L.stallFrom = restore
            L.stallUntil = now + L.TIMEOUT
            L.stallTick = -1
        else
            L.lastPos = root.Position
            L.lastCheck = now
        end
    end

    return false
end

function FARM.lobbyClickLeave()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local main = gui and gui:FindFirstChild("MainGui")
    local button = main and main:FindFirstChild("leaveButton")
    if not button then
        return false
    end

    local p, s = button.AbsolutePosition, FARM.guiSize(button)
    pcall(mousemoveabs, math.floor(p.X + s.X / 2) + 1, math.floor(p.Y + s.Y / 2) + 24)
    pcall(mousemoverel, 3, 3)
    pcall(mousemoverel, -3, -3)
    return true
end

function FARM.lobbyRespawned(character, root)
    local L = FARM.LOBBY
    if not (character and root and L.resetFrom) then return false end
    if getIdentity(character) == L.resetFrom then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local ok, health = pcall(function() return humanoid.Health end)
    return ok and type(health) == "number" and health > 0
end

function FARM.lobbyUpdate(now)
    local L = FARM.LOBBY

    if not Workspace:FindFirstChild("Elevators") then
        FARM.releaseKeys()
        FARM.setStatus("Not in the lobby")
        return
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local camera = Workspace.CurrentCamera

    if L.phase == "idle" then
        L.phase = "reset"
        L.resetStage = 1
        L.atNode = "Hub"
        L.lastPos = nil
        L.stallFrom = nil
    end

    if L.phase == "reset" then
        FARM.releaseKeys()
        if L.resetStage == 1 then
            FARM.setStatus("Resetting")
            FARM.tapKey(L.VK.ESC)
            L.resetStage = 2
            L.at = now + 0.4
        elseif L.resetStage == 2 and now >= L.at then
            FARM.tapKey(L.VK.R)
            L.resetStage = 3
            L.at = now + 0.4
        elseif L.resetStage == 3 and now >= L.at then
            L.resetFrom = character and getIdentity(character)
            FARM.tapKey(L.VK.ENTER)
            L.phase = "spawnLeg"
            L.at = now + L.RESET_WAIT
            L.atNode = "Hub"
            L.lastPos = nil
            FARM.setStatus("Respawning")
        end
        return
    end

    if not (root and camera) then
        FARM.releaseKeys()
        return
    end

    local moving = L.phase == "walk" or L.phase == "enter" or (L.phase == "spawnLeg" and now >= L.at)
    FARM.sprintUpdate(now, moving)

    if L.phase == "spawnLeg" then
        if now < L.at and FARM.lobbyRespawned(character, root) then
            L.at = now
        end
        if now < L.at then
            FARM.releaseKeys()
            L.lastPos = root.Position
            L.lastCheck = now
            return
        end

        FARM.setStatus(L.stallFrom and FARM.status or "Moving to Hub")
        local d = FARM.steer(root, camera, L.NODES.Hub)
        if d <= L.ARRIVE then
            FARM.releaseKeys()
            L.atNode = "Hub"
            L.phase = "waitHub"
            L.at = 0
            L.lastPos = nil
            L.stallFrom = nil
        else
            FARM.moveGuard(root, now, "Moving to Hub")
        end
        return
    end

    if L.phase == "waitHub" then
        FARM.releaseKeys()
        if now < L.at then
            return
        end

        L.at = now + L.POLL
        local best = FARM.pickGate(L.atNode)
        if best then
            FARM.lobbyPlan(best, L.atNode)
            L.phase = "walk"
        else
            FARM.setStatus("All elevators busy")
        end
        return
    end

    if L.phase == "walk" then
        local nextNode = L.path[L.legIndex + 1]
        if not nextNode then
            FARM.lobbyGoHub()
            return
        end

        local label = "Moving to " .. (nextNode == L.target and nextNode or (L.target .. " via " .. nextNode))
        if not L.stallFrom then
            FARM.setStatus(label)
        end

        local d = FARM.steer(root, camera, L.NODES[nextNode])

        if d <= L.ARRIVE then
            FARM.releaseKeys()
            L.atNode = nextNode
            L.legIndex = L.legIndex + 1
            L.lastPos = nil
            L.stallFrom = nil

            if L.atNode == L.target then
                if L.target == "Hub" then
                    L.phase = "waitHub"
                    L.at = 0
                else
                    local gateName = L.GATE_OF[L.target]
                    if FARM.gateCount(gateName) ~= 0 or not FARM.gateOpen(gateName) then
                        FARM.lobbyNext()
                    else
                        L.phase = "enter"
                        L.at = now + L.ENTER_TIMEOUT
                        FARM.setStatus("Entering " .. L.target)
                    end
                end
            elseif L.target ~= "Hub" then
                local best = FARM.pickGate(L.atNode)
                if best and best ~= L.target then
                    FARM.lobbyPlan(best, L.atNode)
                end
            end
            return
        end

        FARM.moveGuard(root, now, label)
        return
    end

    if L.phase == "enter" then
        local gateName = L.GATE_OF[L.target]
        if FARM.gateInside(gateName) or FARM.gateCount(gateName) >= 1 then
            FARM.releaseKeys()
            L.phase = "inside"
            FARM.setStatus("Waiting")
            return
        end

        local folder = Workspace:FindFirstChild("Elevators")
        local gate = folder and folder:FindFirstChild(gateName)
        local spawnPart = gate and gate:FindFirstChild("spawn")
        if spawnPart then
            FARM.steer(root, camera, spawnPart.Position)
        end

        if now >= L.at then
            FARM.releaseKeys()
            FARM.lobbyNext()
        end
        return
    end

    FARM.releaseKeys()

    if L.phase == "inside" then
        local gateName = L.GATE_OF[L.target]
        local count = FARM.gateCount(gateName)

        if count == 1 and not FARM.resumeWritten then
            local seconds = tonumber(FARM.gateLabel(gateName, "time") or "")
            if not FARM.gateOpen(gateName) or (seconds and seconds <= 5) then
                FARM.writeResume()
            end
        end

        if count > 1 then
            FARM.clearResume()
            L.phase = "leaveAim"
            L.at = now
            FARM.setStatus("Leaving, someone joined")
        elseif count == 0 and not FARM.gateInside(gateName) then
            FARM.lobbyNext()
        end
        return
    end

    if L.phase == "leaveAim" and now >= L.at then
        if FARM.lobbyClickLeave() then
            L.phase = "leaveDown"
            L.at = now + 0.1
        else
            FARM.lobbyGoHub()
        end
    elseif L.phase == "leaveDown" and now >= L.at then
        pcall(mouse1press)
        L.phase = "leaveUp"
        L.at = now + L.CLICK_HOLD
    elseif L.phase == "leaveUp" and now >= L.at then
        pcall(mouse1release)
        L.phase = "leaveCheck"
        L.at = now + 1.2
    elseif L.phase == "leaveCheck" and now >= L.at then
        local gateName = L.GATE_OF[L.target]
        if FARM.gateCount(gateName) == 0 or not FARM.gateInside(gateName) then
            L.atNode = L.target
            FARM.lobbyNext()
        else
            L.phase = "leaveAim"
            L.at = now + 0.3
        end
    end
end

function FARM.lobbyStop()
    local L = FARM.LOBBY
    FARM.setShift(false)
    FARM.releaseKeys()
    L.phase = "idle"
    L.stallFrom = nil
    L.lastPos = nil
    L.sprintStage = 0
end

function FARM.runRmb(down)
    local R = FARM.RUN
    if down == R.rmbDown then
        return
    end

    R.rmbDown = down
    if down then
        pcall(mouse2press)
    else
        pcall(mouse2release)
    end
end

function FARM.runHoldW(down)
    local R = FARM.RUN
    if down and R.wDown and type(iskeypressed) == "function" then
        local ok, pressed = pcall(iskeypressed, R.W_KEY)
        local now = tick()
        if ok and pressed == false and now >= (R.wRepressAt or 0) and not gameTyping() then
            R.wRepressAt = now + 0.2
            pcall(keypress, R.W_KEY)
        end
        return
    end

    if down == R.wDown then
        return
    end

    R.wDown = down
    if down then
        if gameTyping() then
            R.wDown = false
            return
        end
        pcall(keypress, R.W_KEY)
    else
        pcall(keyrelease, R.W_KEY)
    end
end

function FARM.runCollide(on)
    local R = FARM.RUN
    local character = LocalPlayer.Character
    if not character then
        return
    end

    R.noCollide = not on
    for _, name in ipairs({ "HumanoidRootPart", "Torso" }) do
        local part = character:FindFirstChild(name)
        if part then
            pcall(function()
                part.CanCollide = on
            end)
        end
    end
end

function FARM.runFreeze(root)
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end)
end

function FARM.runYawError(camera, root, goal)
    local look = camera.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.001 then
        return 0
    end

    flat = flat.Unit
    local to = Vector3.new(goal.X - root.Position.X, 0, goal.Z - root.Position.Z)
    if to.Magnitude < 0.001 then
        return 0
    end

    to = to.Unit
    local angle = math.deg(math.acos(math.clamp(flat.X * to.X + flat.Z * to.Z, -1, 1)))
    if flat.X * to.Z - flat.Z * to.X < 0 then
        angle = -angle
    end

    return angle
end

function FARM.runFace(camera, root, goal)
    local R = FARM.RUN
    local err = FARM.runYawError(camera, root, goal)

    if math.abs(err) <= R.TOL then
        FARM.runRmb(false)
        return true, err
    end

    FARM.runRmb(true)
    pcall(mousemoverel, math.floor(math.clamp(err * R.GAIN, -R.MAX_STEP, R.MAX_STEP)), 0)
    return false, err
end

function FARM.currentFloor()
    local info = Workspace:FindFirstChild("Info")
    local value = info and info:FindFirstChild("Floor")
    local ok, floor = pcall(function()
        return value.Value
    end)

    return (ok and floor) or 0
end

function FARM.tweenSpeed()
    local speed = math.max(SETTINGS.tweenWalkSpeed, 1)
    if FARM.MASTERY.travelOnly() then
        speed = math.min(speed, FARM.MASTERY.TRAVEL_SPEED)
    end
    return speed
end

function FARM.floorLimitHit()
    local floor = FARM.currentFloor()
    local M = FARM.MASTERY
    if SETTINGS.masteryFarm and M.runState ~= nil then
        if (M.runState == "done" and SETTINGS.masteryEnd) or M.passiveDeath() then
            return true
        end
        if M.reachFloor and floor < M.reachFloor then
            return false
        end
    end
    if SETTINGS.unlimitedFloors then
        return false
    end

    return floor > 0 and floor >= SETTINGS.floorLimit
end

function FARM.runMap()
    local room = Workspace:FindFirstChild("CurrentRoom")
    return room and room:GetChildren()[1]
end

function FARM.runMachines()
    local map = FARM.runMap()
    local gens = map and map:FindFirstChild("Generators")
    local out = {}
    if not gens then
        return out
    end

    for _, model in ipairs(gens:GetChildren()) do
        local prompt = model:FindFirstChild("Prompt")
        local stats = model:FindFirstChild("Stats")
        local folder = model:FindFirstChild("TeleportPositions")
        local stand = folder and folder:FindFirstChild("TeleportPosition")

        if prompt and stats then
            local cur = stats:FindFirstChild("CurrentAmount")
            local req = stats:FindFirstChild("RequiredAmount")
            local done = stats:FindFirstChild("Completed")
            local connie = stats:FindFirstChild("Connie")

            out[#out + 1] = {
                model = model,
                slot = 1,
                prompt = prompt,
                stand = stand or prompt,
                cur = cur,
                req = req,
                done = done,
                active = stats:FindFirstChild("ActivePlayer"),
                connie = connie,
            }

            local mirrorPrompt = model:FindFirstChild("Prompt2")
            local mirrorFolder = model:FindFirstChild("TeleportPositions_Mirror")
            local mirrorStand = mirrorFolder and mirrorFolder:FindFirstChild("TeleportPosition")
            local mirrorActive = stats:FindFirstChild("ActivePlayer2")

            if mirrorPrompt and mirrorStand and mirrorActive then
                out[#out + 1] = {
                    model = model,
                    slot = 2,
                    prompt = mirrorPrompt,
                    stand = mirrorStand,
                    cur = cur,
                    req = req,
                    done = done,
                    active = mirrorActive,
                    connie = connie,
                }
            end
        end
    end

    return out
end

function FARM.runFill(machine)
    local okCur, cur = pcall(function()
        return machine.cur.Value
    end)
    local okReq, req = pcall(function()
        return machine.req.Value
    end)
    return (okCur and cur) or 0, (okReq and req) or 1
end

function FARM.runConnie(machine)
    local ok, value = pcall(function()
        return machine.connie.Value
    end)
    return ok and value == true
end

function FARM.runDone(machine)
    local ok, value = pcall(function()
        return machine.done.Value
    end)
    if ok and type(value) == "boolean" then
        return value
    end

    local cur, req = FARM.runFill(machine)
    return cur >= req
end

function FARM.runEngagedBy(machine)
    if not machine.active then
        return "none"
    end

    local ok, value = pcall(function()
        return machine.active.Value
    end)

    if not ok or not value or tostring(value.ClassName) ~= "Model" then
        return "none"
    end

    return tostring(value.Name)
end

function FARM.runTaken(machine)
    local who = FARM.runEngagedBy(machine)
    return who ~= "none" and who ~= LocalPlayer.Name
end

function FARM.runItemKey(value)
    return string.lower((string.gsub(tostring(value or ""), "[^%w]", "")))
end

function FARM.runStringValue(instance)
    return STRINGS.read(instance)
end

function FARM.runInventory(character)
    local folder = character:FindFirstChild("Inventory")
    local slots = {}
    if not folder then
        return slots
    end

    for _, child in ipairs(folder:GetChildren()) do
        local index = tonumber(string.match(child.Name, "^Slot(%d+)$"))
        if index then
            slots[#slots + 1] = { index = index, item = FARM.runStringValue(child) }
        end
    end

    return slots
end

function FARM.runPressItem(now, slot)
    local R = FARM.RUN
    if R.itemKey or not slot then
        return
    end

    R.itemKey = 0x30 + slot
    R.itemKeyUp = now + R.KEY_HOLD
    pcall(keypress, R.itemKey)
end

function FARM.runReleaseItemKey(now, force)
    local R = FARM.RUN
    if R.itemKey and (force or now >= R.itemKeyUp) then
        pcall(keyrelease, R.itemKey)
        R.itemKey = nil
    end
end

function FARM.runSlotOf(character, name)
    local want = FARM.runItemKey(name)
    for _, slot in ipairs(FARM.runInventory(character)) do
        if FARM.runItemKey(slot.item) == want then
            return slot.index
        end
    end
    return nil
end

function FARM.runHasFreeSlot(character)
    for _, slot in ipairs(FARM.runInventory(character)) do
        local key = FARM.runItemKey(slot.item)
        if key == "" or key == "none" then
            return true
        end
    end
    return false
end

function FARM.runSpotKey(position)
    return string.format("%d,%d,%d", math.floor(position.X), math.floor(position.Y), math.floor(position.Z))
end

function FARM.runTapes()
    local info = Workspace:FindFirstChild("Info")
    local stats = info and info:FindFirstChild("PlayerStats")
    local mine = stats and stats:FindFirstChild(LocalPlayer.Name)
    local points = mine and mine:FindFirstChild("SurvivalPoints")
    local ok, value = pcall(function()
        return points.Value
    end)
    return (ok and type(value) == "number") and value or 0
end

function FARM.runStoreDiscount()
    local info = Workspace:FindFirstChild("Info")
    local modifiers = info and info:FindFirstChild("CardModifiers")
    local card = modifiers and modifiers:FindFirstChild("DandyDiscount")
    local ok, value = pcall(function()
        return card.Value
    end)
    if ok and type(value) == "number" and value > 0 and value < 1 then
        return value
    end
    return 1
end

function FARM.runPromptShows(name)
    local Gui = LocalPlayer.PlayerGui:FindFirstChild("ProximityPrompts")
    if not Gui then return nil end
    local info = ITEM_INFO[name]
    local wanted = { FARM.runItemKey(name), info and FARM.runItemKey(info.name) or nil }
    local readable = false
    for _, Prompt in ipairs(Gui:GetChildren()) do
        local Frame = Prompt:FindFirstChild("Frame")
        local TextFrame = Frame and Frame:FindFirstChild("TextFrame")
        for _, Label in ipairs(TextFrame and TextFrame:GetChildren() or {}) do
            if Label.ClassName == "TextLabel" then
                local key = FARM.runItemKey(FARM.MASTERY.text(Label))
                if key ~= "" then readable = true end
                for _, want in ipairs(wanted) do
                    if want and key == want then return true end
                end
            end
        end
    end
    if not readable then return nil end
    return false
end

function FARM.runStoreTarget(root, character)
    local R = FARM.RUN
    local info = Workspace:FindFirstChild("Info")
    local open = info and info:FindFirstChild("DandyStoreOpen")
    local okOpen, isOpen = pcall(function()
        return open.Value
    end)

    if not okOpen or isOpen ~= true then
        R.bought = {}
        return nil
    end

    if not FARM.runHasFreeSlot(character) then
        return nil
    end

    local masteryBuy = FARM.MASTERY.wants("BuyDandyStoreItem")
    local specific = FARM.MASTERY.specificItem()

    local folder = Workspace:FindFirstChild("Elevators")
    local elevator = folder and folder:FindFirstChild("Elevator")
    local store = elevator and elevator:FindFirstChild("DandyStore")
    if not store then
        return nil
    end

    local offers = {}
    for _, slot in ipairs(store:GetChildren()) do
        if string.match(slot.Name, "^Slot%d+$") then
            for _, model in ipairs(slot:GetChildren()) do
                local prompt = model:FindFirstChild("Prompt")
                local ok, position = pcall(function()
                    return prompt.Position
                end)
                if ok and position and not R.skip[FARM.runSpotKey(position)] and (position - root.Position).Magnitude <= R.BUY_RANGE then
                    offers[model.Name] = { model = model, prompt = prompt, kind = "buy", name = model.Name, spot = FARM.runSpotKey(position) }
                end
            end
        end
    end

    local tapes = FARM.runTapes()
    local discount = FARM.runStoreDiscount()

    if specific and offers[specific] and not R.bought[specific] then
        local info = ITEM_INFO[specific]
        local cost = (info and info.cost and info.cost > 0 and info.cost) or R.PRICES[specific]
        local price = cost and math.ceil(cost * discount - 0.001)
        if price and tapes >= price then
            offers[specific].price = price
            return offers[specific]
        end
    end

    if masteryBuy then
        for name, offer in pairs(offers) do
            local info = ITEM_INFO[name]
            local cost = (info and info.cost and info.cost > 0 and info.cost) or R.PRICES[name]
            if cost and not R.bought[name] then
                local price = math.ceil(cost * discount - 0.001)
                if tapes >= price then
                    offer.price = price
                    return offer
                end
            end
        end
        return nil
    end

    for _, name in ipairs(R.BUY_ORDER) do
        local offer = offers[name]
        if offer and not R.bought[name] and SETTINGS[R.BUY_SETTING[name]] then
            local price = math.ceil(R.PRICES[name] * discount - 0.001)
            if tapes >= price then
                offer.price = price
                return offer
            end
        end
    end

    return nil
end

function FARM.runMapItems()
    local R = FARM.RUN
    local map = FARM.runMap()
    local folder = map and map:FindFirstChild("Items")
    local found = {}
    if not folder then
        return found
    end

    for _, model in ipairs(folder:GetChildren()) do
        if R.WANT_ITEMS[model.Name] then
            local prompt = model:FindFirstChild("Prompt")
            local ok, position = pcall(function()
                return prompt.Position
            end)
            if ok and position and not R.skip[FARM.runSpotKey(position)] then
                found[model.Name] = true
            end
        end
    end

    return found
end

function FARM.runMakeRoom(now, character)
    local R = FARM.RUN
    if not SETTINGS.farmHealItems or now < R.useAt or FARM.runHasFreeSlot(character) then
        return false
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local ok, health, maxHealth = pcall(function()
        return humanoid.Health, humanoid.MaxHealth
    end)

    if not ok or type(health) ~= "number" or type(maxHealth) ~= "number" or health <= 0 or health >= maxHealth then
        return false
    end

    local onMap = FARM.runMapItems()
    local burn = nil
    if (onMap.Bandage or onMap.HealthKit) and FARM.runSlotOf(character, "Bandage") then
        burn = "Bandage"
    elseif onMap.HealthKit and FARM.runSlotOf(character, "HealthKit") then
        burn = "HealthKit"
    end

    if not burn then
        return false
    end

    FARM.runPressItem(now, FARM.runSlotOf(character, burn))
    R.useAt = now + R.USE_COOLDOWN
    R.roomUntil = now + R.USE_COOLDOWN
    FARM.setStatus("Using " .. burn .. " to make room")
    return true
end

function FARM.runCollectTarget(root, character, itemsOnly)
    local R = FARM.RUN
    local map = FARM.runMap()
    local folder = map and map:FindFirstChild("Items")
    if not folder then
        return nil
    end

    if R.skipMap ~= map.Name then
        R.skipMap = map.Name
        R.skip = {}
    end

    local canCarry = FARM.runHasFreeSlot(character)
    local bestItem, itemDistance, bestCapsule, capsuleDistance
    local M = FARM.MASTERY
    local masteryItems = M.itemMode()
    local specificInfo = ITEM_INFO[M.specificItem() or ""]
    local masteryTapes = M.wants("BuyDandyStoreItem") or (specificInfo ~= nil and specificInfo.store == true)
    local masteryCapsules = M.capsuleMode()

    for _, model in ipairs(folder:GetChildren()) do
        local kind = nil
        local setting = R.WANT_ITEMS[model.Name]
        local info = ITEM_INFO[model.Name]
        if canCarry and setting and SETTINGS[setting] then
            kind = "item"
        elseif canCarry and masteryItems and info and info.use ~= "Collectible" then
            kind = "item"
        elseif masteryTapes and model.Name == "Tape" then
            kind = "item"
        elseif model.Name == "ResearchCapsule" and (SETTINGS.farmCapsules or masteryCapsules) and not itemsOnly then
            kind = "capsule"
        end

        if kind then
            local prompt = model:FindFirstChild("Prompt")
            local ok, position = pcall(function()
                return prompt.Position
            end)

            if ok and position and not R.skip[FARM.runSpotKey(position)] then
                local d = (position - root.Position).Magnitude
                local entry = { model = model, prompt = prompt, kind = kind, name = model.Name, spot = FARM.runSpotKey(position) }
                if kind == "item" then
                    if not itemDistance or d < itemDistance then
                        bestItem, itemDistance = entry, d
                    end
                elseif not capsuleDistance or d < capsuleDistance then
                    bestCapsule, capsuleDistance = entry, d
                end
            end
        end
    end

    if (masteryItems or masteryCapsules) and bestItem and bestCapsule then
        return capsuleDistance < itemDistance and bestCapsule or bestItem
    end
    return bestItem or bestCapsule
end

function FARM.runUseItems(now, character)
    local R = FARM.RUN
    if now < R.useAt then
        return
    end

    if FARM.MASTERY.itemMode() then
        R.staminaSprint = false
        FARM.MASTERY.useItems(now, character)
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local okHealth, health = pcall(function()
        return humanoid.Health
    end)

    if SETTINGS.farmHealItems and okHealth and type(health) == "number" and health > 0 and health <= R.HEAL_AT then
        for _, name in ipairs(R.HEAL_ORDER) do
            local slot = FARM.runSlotOf(character, name)
            if slot then
                FARM.runPressItem(now, slot)
                R.useAt = now + R.USE_COOLDOWN
                FARM.setStatus("Using " .. name)
                return
            end
        end
    end

    if SETTINGS.farmExtractionItems and R.phase == "working" and R.current and FARM.runEngagedBy(R.current) == LocalPlayer.Name then
        local cur, req = FARM.runFill(R.current)
        local valve = FARM.runSlotOf(character, "Valve")
        if valve and req > 0 and cur < req then
            FARM.runPressItem(now, valve)
            R.useAt = now + R.USE_COOLDOWN
            FARM.setStatus("Using Valve")
            return
        end

        if req > 0 and cur / req <= R.CABLE_MAX_FILL then
            local slot = FARM.runSlotOf(character, "JumperCable")
            if slot then
                FARM.runPressItem(now, slot)
                R.useAt = now + R.USE_COOLDOWN
                FARM.setStatus("Using JumperCable")
                return
            end

            for _, name in ipairs(R.MACHINE_ORDER) do
                local held = FARM.runSlotOf(character, name)
                if held then
                    FARM.runPressItem(now, held)
                    R.useAt = now + R.USE_COOLDOWN
                    FARM.setStatus("Using " .. ((ITEM_INFO[name] and ITEM_INFO[name].name) or name))
                    return
                end
            end
        end
    end

    R.staminaSprint = false
    for _, slot in ipairs(FARM.runInventory(character)) do
        local key = FARM.runItemKey(slot.item)
        if key ~= "" and key ~= "none" and not R.KEEP_ITEMS[key] then
            if R.STAMINA_ITEMS[key] and FARM.runStaminaFull(character) then
                R.staminaSprint = true
            else
                FARM.runPressItem(now, slot.index)
                R.useAt = now + R.USE_COOLDOWN
                FARM.setStatus("Using " .. slot.item)
                return
            end
        end
    end
end

function FARM.runStaminaFull(character)
    local ok, current, maximum = pcall(function()
        local stats = character.Stats
        return stats.CurrentStamina.Value, stats.Stamina.Value
    end)
    return ok and type(current) == "number" and type(maximum) == "number" and current >= maximum
end

function FARM.runNearRazzle(root)
    local R = FARM.RUN
    local map = FARM.runMap()
    local monsters = map and map:FindFirstChild("Monsters")
    local razzle = monsters and monsters:FindFirstChild("RazzleDazzleMonster")
    if not razzle then
        return false
    end
    local part = razzle:FindFirstChild("RootPart") or razzle.PrimaryPart
    local ok, position = pcall(function()
        return part.Position
    end)
    return not ok or not position or Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z).Magnitude <= R.STAMINA_RAZZLE_RANGE
end

FARM.TREADMILL_RECOVER = 30

function FARM.runOnTreadmill(machine)
    local ok, kind = pcall(function()
        return machine.model:GetAttribute("MinigameType")
    end)
    return ok and kind == "MovementTreadmill"
end

function FARM.runStaminaSprint(now, root)
    local R = FARM.RUN
    local L = FARM.LOBBY
    if R.shiftReleaseAt and now >= R.shiftReleaseAt then
        R.shiftReleaseAt = nil
        pcall(keyrelease, L.SHIFT)
    end

    local moving = R.phase == "tween" or R.phase == "toElevator" or (R.phase == "research" and R.research and R.research.kind ~= "razzle" and not R.researchArrived)
    if R.phase == "research" and R.research and R.research.kind == "razzle" then
        R.sprinting = false
        return
    end

    if R.phase == "working" and R.current and SETTINGS.farmTreadmillRun and FARM.runOnTreadmill(R.current) then
        local ok, stamina, maximum = pcall(function()
            local stats = LocalPlayer.Character.Stats
            return stats.CurrentStamina.Value, stats.Stamina.Value
        end)
        if ok and type(stamina) == "number" and type(maximum) == "number" then
            if stamina <= SETTINGS.farmTreadmillStopAt then
                R.treadmillResting = true
            elseif stamina >= math.min(SETTINGS.farmTreadmillStopAt + FARM.TREADMILL_RECOVER, maximum) then
                R.treadmillResting = false
            end
        end
        if not R.treadmillResting then
            R.sprinting = true
            FARM.sprintUpdate(now, true)
            return
        end
    else
        R.treadmillResting = false
    end

    if R.staminaSprint and moving and not FARM.runNearRazzle(root) then
        R.sprinting = true
        FARM.sprintUpdate(now, true)
        return
    end

    R.sprinting = false
    if L.shiftDown then
        FARM.setShift(false)
        return
    end

    if L.sprintMode == nil then
        L.sprintMode = FARM.sprintSetting()
    end

    if L.sprintMode == "toggle" and not R.shiftReleaseAt and now >= R.sprintOffAt and FARM.isSprinting() then
        R.sprintOffAt = now + R.SPRINT_OFF_EVERY
        pcall(keypress, L.SHIFT)
        R.shiftReleaseAt = now + R.SHIFT_HOLD
    end
end

function FARM.runElevatorBase()
    local folder = Workspace:FindFirstChild("Elevators")
    local elevator = folder and folder:FindFirstChild("Elevator")
    if not elevator then
        return nil
    end

    for _, child in ipairs(elevator:GetChildren()) do
        if child.Name == "Base" and (child.ClassName == "Part" or child.ClassName == "MeshPart") then
            return child
        end
    end

    return elevator:FindFirstChild("SpawnZones")
end

function FARM.runElevatorState(character, root)
    local folder = Workspace:FindFirstChild("Elevators")
    local elevator = folder and folder:FindFirstChild("Elevator")
    local opened = elevator and elevator:FindFirstChild("Opened")
    local okOpen, isOpen = pcall(function()
        return opened.Value
    end)
    if not okOpen or type(isOpen) ~= "boolean" then
        isOpen = nil
    end

    local stats = character:FindFirstChild("Stats")
    local flag = stats and stats:FindFirstChild("InElevator")
    local okFlag, flagged = pcall(function()
        return flag.Value
    end)

    if okFlag and flagged == true then
        return true, isOpen
    end

    local base = FARM.runElevatorBase()
    local okBase, position = pcall(function()
        return base.Position
    end)

    if not okBase or not position then
        return false, isOpen
    end

    local d = root.Position - position
    return math.abs(d.X) <= 20 and math.abs(d.Z) <= 20, isOpen
end

function FARM.runSafeInElevator(character)
    local R = FARM.RUN
    local ok, flagged = pcall(function()
        return character.Stats.InElevator.Value
    end)
    if ok and flagged == true then
        return true
    end
    return R.phase == "waitFloor" and R.elevatorHold ~= "none"
end

function FARM.runPassive(monster)
    if FARM.RUN.PASSIVE[monster.Name] then
        return true
    end
    return monster.Name == "GlistenMonster" and monster:GetAttribute("GlistenActivated") ~= true
end

function FARM.runThreat(root, ignore)
    local R = FARM.RUN
    local map = FARM.runMap()
    local monsters = map and map:FindFirstChild("Monsters")
    if not monsters then
        return 9999, false
    end
    FARM.runResearchMap(map)

    local nearest, chasing, panic, seen = 9999, false, false, false
    local underground = R.phase == "dive" or R.phase == "hide" or R.phase == "surface"
    local eye = underground and R.surfaceY and Vector3.new(root.Position.X, R.surfaceY, root.Position.Z) or root.Position
    local walls = FARM.runRayWorks(root, underground)
    local generators = map:FindFirstChild("Generators")

    for _, monster in ipairs(monsters:GetChildren()) do
        local part = monster:FindFirstChild("RootPart") or monster.PrimaryPart
        local ok, position = pcall(function()
            return part.Position
        end)

        if ok and position and R.IGNORE_BODY[monster.Name] then
            ok = false
        end

        if ok and position and FARM.runSawYou(monster) then
            local key = FARM.runKey(monster)
            if key and not (R.phase == "research" and key == ignore) then
                R.researched[key] = true
            end
        end

        if ok and position and ignore and FARM.runKey(monster) == ignore and not R.researched[ignore] then
            ok = false
        end

        if ok and position and R.PASSIVE_RANGE[monster.Name] and (position - root.Position).Magnitude > R.PASSIVE_RANGE[monster.Name] then
            ok = false
        end

        if ok and position then
            local distance = (position - root.Position).Magnitude
            local passive = FARM.runPassive(monster)

            if not passive then
                local instant, vision, sight = FARM.runChaser(monster)
                local flat = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
                local reach = flat.Magnitude

                local blocked = walls and reach >= R.CLOSE_RADIUS and reach < vision + R.SURFACE_BUFFER and FARM.runWallBetween(monster, part, eye, generators)

                if not blocked and reach < instant + R.DIVE_BUFFER then
                    panic = true
                end

                if blocked then
                elseif reach < instant + R.SURFACE_BUFFER then
                    seen = true
                elseif reach < vision + R.SURFACE_BUFFER then
                    local okLook, look = pcall(function()
                        return part.CFrame.LookVector
                    end)
                    if not okLook or not look then
                        seen = true
                    else
                        local facing = Vector3.new(look.X, 0, look.Z)
                        if facing.Magnitude < 0.01 or reach < 0.01 or facing.Unit:Dot(flat.Unit) >= sight then
                            seen = true
                        end
                    end
                end
            end

            local holder = monster:FindFirstChild("ChasingValue")
            local okTarget, target = pcall(function()
                return holder.Value
            end)

            if okTarget and target and tostring(target.ClassName) == "Model" and tostring(target.Name) == LocalPlayer.Name then
                chasing = true
            end

            if passive then
                local okAwake, awake = pcall(function()
                    return monster:GetAttribute("Attacking")
                end)
                if okAwake and awake == true then
                    chasing = true
                end
            elseif distance < R.DANGER then
                local okState, state = pcall(function()
                    return monster:GetAttribute("ChaseState")
                end)
                if okState and (state == "run" or state == "attack") then
                    chasing = true
                end

                local okAttack, attacking = pcall(function()
                    return monster:GetAttribute("Attacking")
                end)
                if okAttack and attacking == true then
                    chasing = true
                end

                local okChase, hunting = pcall(function()
                    return monster:GetAttribute("Chasing")
                end)
                if okChase and hunting == true then
                    chasing = true
                end
            end

            if distance < nearest and not passive then
                nearest = distance
            end
        end
    end

    return nearest, chasing, panic, seen
end

function FARM.runRayWorks(root, underground)
    local R = FARM.RUN
    local now = tick()
    if underground or now < R.rayCheckAt then
        return R.rayWorks
    end
    R.rayCheckAt = now + R.RAY_RECHECK

    local ok, hit = pcall(function()
        return workspace:Raycast(root.Position, Vector3.new(0, -R.RAY_DOWN, 0))
    end)
    R.rayWorks = ok and hit ~= nil
    return R.rayWorks
end

function FARM.runIsInside(instance, folder)
    if not folder then
        return false
    end
    local ok, result = pcall(function()
        local target = folder.Address
        local current = instance
        for _ = 1, 10 do
            if not current then
                return false
            end
            if current.Address == target then
                return true
            end
            current = current.Parent
        end
        return false
    end)
    return ok and result == true
end

function FARM.runRayBlocked(from, to, generators)
    local R = FARM.RUN
    local ok, blocked = pcall(function()
        local point = from
        for _ = 1, R.RAY_HOPS do
            local offset = to - point
            if offset.Magnitude < 1 then
                return false
            end
            local hit = workspace:Raycast(point, offset)
            if not hit or not hit.Instance then
                return false
            end
            if not FARM.runIsInside(hit.Instance, generators) then
                return (hit.Position - point).Magnitude < offset.Magnitude - 1
            end
            point = hit.Position + offset.Unit * 0.05
        end
        return false
    end)
    return ok and blocked == true
end

function FARM.runWallBetween(monster, part, eye, generators)
    local origin = monster:FindFirstChild("HumanoidRootPart") or part
    local ok, from = pcall(function()
        return origin.Position
    end)
    if not ok or not from then
        return false
    end
    return FARM.runRayBlocked(from, eye, generators) and FARM.runRayBlocked(eye, from, generators)
end

function FARM.runKey(instance)
    local ok, address = pcall(function()
        return tostring(instance.Address)
    end)
    return ok and address or nil
end

function FARM.runResearchCount()
    local ok, value = pcall(function()
        return Workspace.Info.PlayerStats[LocalPlayer.Name].Monsters.Value
    end)
    return (ok and type(value) == "number") and value or nil
end

function FARM.runHandWall(zone, from, eye, generators)
    local R = FARM.RUN
    local ok, blocked = pcall(function()
        local start = from + Vector3.new(0, 2, 0)
        for _ = 1, R.RAY_HOPS do
            local offset = eye - start
            if offset.Magnitude < 1 then
                return false
            end
            local hit = workspace:Raycast(start, offset)
            if not hit or not hit.Instance then
                return false
            end
            if not (FARM.runIsInside(hit.Instance, zone) or FARM.runIsInside(hit.Instance, generators) or FARM.runIsInside(hit.Instance, LocalPlayer.Character)) then
                return (hit.Position - start).Magnitude < offset.Magnitude - 1
            end
            start = hit.Position + offset.Unit * 0.05
        end
        return false
    end)
    return ok and blocked == true
end

function FARM.runBlotHandNear(point, root)
    local R = FARM.RUN
    local map = FARM.runMap()
    if not map then
        return false
    end
    local generators = map:FindFirstChild("Generators")
    local walls = FARM.runRayWorks(root, R.phase == "dive" or R.phase == "hide" or R.phase == "surface")
    for index = 1, R.RESEARCH_BLOT_ZONES do
        local zone = map:FindFirstChild("BlotHandZone_" .. index)
        if zone then
            local hand = false
            for _, child in ipairs(zone:GetChildren()) do
                if child.ClassName == "Model" and child.Name:sub(1, 8) == "BlotHand" then
                    hand = true
                end
            end
            local ok, position = pcall(function()
                return zone.Position
            end)
            if hand and ok and position then
                local reach = Vector3.new(point.X - position.X, 0, point.Z - position.Z).Magnitude
                if reach <= R.BLOT_HAND_RANGE and not (walls and FARM.runHandWall(zone, position, point, generators)) then
                    return true
                end
            end
        end
    end
    return false
end

function FARM.runHazards(now)
    local R = FARM.RUN
    if now < R.sproutAt then
        return R.sprouts
    end
    R.sproutAt = now + R.SPROUT_RECHECK
    local list = {}
    local map = FARM.runMap()
    if map then
        local area = map:FindFirstChild("FreeArea")
        for _, folder in ipairs(area and { area, map } or { map }) do
            for _, child in ipairs(folder:GetChildren()) do
                if child.Name == "SproutTendril" then
                    local part = child:FindFirstChild("Puddle") or child:FindFirstChild("HumanoidRootPart")
                    local ok, position = pcall(function()
                        return part.Position
                    end)
                    if ok and position then
                        list[#list + 1] = { position = position, range = R.SPROUT_RANGE }
                    end
                end
            end
        end
        local capsules = {}
        local items = map:FindFirstChild("Items")
        for _, model in ipairs(items and items:GetChildren() or {}) do
            if model.Name == "FakeCapsule" then
                local prompt = model:FindFirstChild("Prompt")
                local ok, position = pcall(function()
                    return prompt.Position
                end)
                if ok and position then
                    capsules[#capsules + 1] = position
                end
            end
        end
        local monsters = map:FindFirstChild("Monsters")
        for _, monster in ipairs(monsters and monsters:GetChildren() or {}) do
            if monster.Name == "RodgerMonster" then
                local part = monster:FindFirstChild("HumanoidRootPart") or monster:FindFirstChild("RootPart")
                local ok, position = pcall(function()
                    return part.Position
                end)
                if ok and position then
                    local active = monster:GetAttribute("Attacking") == true
                    for _, capsule in ipairs(capsules) do
                        if Vector3.new(capsule.X - position.X, 0, capsule.Z - position.Z).Magnitude <= R.RODGER_LINK and position.Y >= capsule.Y - R.RODGER_RISE then
                            active = true
                        end
                    end
                    if active then
                        list[#list + 1] = { position = position, range = R.RODGER_ACTIVE_RANGE }
                    end
                end
            end
        end
    end
    R.sprouts = list
    return list
end

function FARM.runHazardNear(point, now, extra)
    local best, bestDistance
    for _, hazard in ipairs(FARM.runHazards(now)) do
        local position = hazard.position
        local d = Vector3.new(point.X - position.X, 0, point.Z - position.Z).Magnitude
        if d <= hazard.range + (extra or 0) and (not bestDistance or d < bestDistance) then
            best, bestDistance = position, d
        end
    end
    return best
end

function FARM.runFlag(model, name)
    local holder = model:FindFirstChild(name)
    local ok, value = pcall(function()
        return holder.Value
    end)
    return ok and value == true
end

function FARM.runAttr(model, name)
    local ok, value = pcall(function()
        return model:GetAttribute(name)
    end)
    return ok and value == true
end

function FARM.runRazzleSees(point)
    local map = FARM.runMap()
    local monsters = map and map:FindFirstChild("Monsters")
    if not monsters then
        return false
    end
    local generators = map:FindFirstChild("Generators")
    for _, monster in ipairs(monsters:GetChildren()) do
        if monster.Name == "RazzleDazzleMonster" then
            local part = monster:FindFirstChild("RootPart") or monster.PrimaryPart
            local ok, position = pcall(function()
                return part.Position
            end)
            local awake = FARM.runAttr(monster, "Awake") or FARM.runAttr(monster, "Attacking")
                or FARM.runFlag(monster, "Awake") or FARM.runFlag(monster, "Attacking") or FARM.runFlag(monster, "BeamActive")
            if ok and position and awake then
                local instant = FARM.runChaser(monster)
                local reach = Vector3.new(point.X - position.X, 0, point.Z - position.Z).Magnitude
                if reach <= instant + FARM.RUN.DIVE_BUFFER and not FARM.runWallBetween(monster, part, point, generators) then
                    return true
                end
            end
        end
    end
    return false
end

function FARM.runBlotMachine(machine, root, now)
    local R = FARM.RUN
    if machine.blotAt and now < machine.blotAt then
        return machine.blotNear
    end
    machine.blotAt = now + R.BLOT_HAND_RECHECK
    local ok, stand = pcall(function()
        return machine.stand.Position
    end)
    local eye = ok and stand and (stand + Vector3.new(0, R.STAND_Y, 0)) or nil
    machine.blotNear = (eye and (FARM.runHazardNear(stand, now) ~= nil or FARM.runBlotHandNear(eye, root) or FARM.runRazzleSees(eye))) or false
    return machine.blotNear
end

function FARM.runResearchName(name)
    local info = MONSTER_INFO[name]
    return (info and info.name) or name
end

function FARM.runResearchMap(map)
    local R = FARM.RUN
    if R.researchMap ~= map.Name then
        R.researchMap = map.Name
        R.researched = {}
    end
end

function FARM.runFloorY(x, y, z)
    local R = FARM.RUN
    local ok, hit = pcall(function()
        return workspace:Raycast(Vector3.new(x, y + R.FLOOR_UP, z), Vector3.new(0, -R.FLOOR_DOWN, 0))
    end)
    if not ok or not hit then
        return nil
    end
    local okY, hitY = pcall(function()
        return hit.Position.Y
    end)
    return okY and hitY or nil
end

function FARM.runLowestFloorY(x, y, z)
    local R = FARM.RUN
    local lowest
    pcall(function()
        local from = Vector3.new(x, y + R.FLOOR_UP, z)
        local bottom = y + R.FLOOR_UP - R.FLOOR_DOWN
        for _ = 1, 6 do
            local length = from.Y - bottom
            if length <= 0.5 then
                return
            end
            local hit = workspace:Raycast(from, Vector3.new(0, -length, 0))
            if not hit then
                return
            end
            lowest = hit.Position.Y
            from = Vector3.new(x, hit.Position.Y - 0.05, z)
        end
    end)
    return lowest
end

function FARM.runFacePoint(target)
    local R = FARM.RUN
    local ok, origin, look = pcall(function()
        local head = target.model:FindFirstChild("HumanoidRootPart") or target.part
        return head.Position, head.CFrame.LookVector
    end)
    if not ok or not origin or not look then
        return nil
    end

    local facing = Vector3.new(look.X, 0, look.Z)
    if facing.Magnitude < 0.01 then
        return nil
    end
    facing = facing.Unit

    local _, vision = FARM.runChaser(target.model)
    local reach = math.min(R.RESEARCH_FACE_MAX, math.max(vision - 5, 0))
    if reach < R.RESEARCH_FACE_MIN then
        return nil
    end

    local map = FARM.runMap()
    local generators = map and map:FindFirstChild("Generators")
    local free = reach
    local okRay = pcall(function()
        local from = origin
        local finish = origin + facing * reach
        for _ = 1, R.RAY_HOPS do
            local offset = finish - from
            if offset.Magnitude < 0.5 then
                return
            end
            local hit = workspace:Raycast(from, offset)
            if not hit or not hit.Instance then
                return
            end
            if not FARM.runIsInside(hit.Instance, generators) then
                free = (hit.Position - origin).Magnitude
                return
            end
            from = hit.Position + offset.Unit * 0.05
        end
    end)
    if not okRay then
        return nil
    end

    local stand = math.min(free - R.RESEARCH_FACE_GAP, reach)
    if stand < R.RESEARCH_FACE_MIN then
        return nil
    end

    local point = origin + facing * stand
    local floor = FARM.runFloorY(point.X, origin.Y, point.Z)
    local under = FARM.runFloorY(origin.X, origin.Y, origin.Z)
    if not floor or not under or math.abs(floor - under) > R.FACE_FLOOR_TOLERANCE then
        return nil
    end
    return Vector3.new(point.X, floor + R.hipOffset, point.Z)
end

function FARM.runRodgerAt(monsters, position)
    local R = FARM.RUN
    for _, monster in ipairs(monsters:GetChildren()) do
        if monster.Name == "RodgerMonster" then
            local part = monster:FindFirstChild("HumanoidRootPart") or monster:FindFirstChild("RootPart")
            local ok, spot = pcall(function()
                return part.Position
            end)
            if ok and spot and Vector3.new(spot.X - position.X, 0, spot.Z - position.Z).Magnitude <= R.RODGER_LINK then
                return monster
            end
        end
    end
    return nil
end

function FARM.runFullyResearched(name)
    if FARM.MASTERY.wants("EncounterMonster") then
        return false
    end
    if not SETTINGS.farmSkipResearched then
        return false
    end
    local ok, value = pcall(function()
        return game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Research[name].Value
    end)
    return ok and type(value) == "number" and value >= 100
end

function FARM.runResearchTarget(root)
    local R = FARM.RUN
    if not SETTINGS.farmResearchTwisteds and not FARM.MASTERY.researchMode() then
        return nil
    end

    local map = FARM.runMap()
    local monsters = map and map:FindFirstChild("Monsters")
    if not monsters then
        return nil
    end

    FARM.runResearchMap(map)

    local best, bestDistance
    local function consider(entry, position)
        local d = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z).Magnitude
        if not bestDistance or d < bestDistance then
            best, bestDistance = entry, d
        end
    end

    for _, monster in ipairs(monsters:GetChildren()) do
        local key = FARM.runKey(monster)
        if key and monster.Name == "RodgerMonster" and FARM.runSawYou(monster) then
            R.researched[key] = true
        end
        if key and not R.researched[key] and monster.Name ~= "RodgerMonster" and not FARM.runFullyResearched(monster.Name) then
            if monster.Name == "BlottMonster" then
                for index = 1, R.RESEARCH_BLOT_ZONES do
                    local zone = map:FindFirstChild("BlotHandZone_" .. index)
                    local ok, position = pcall(function()
                        return zone.Position
                    end)
                    if ok and position then
                        consider({ kind = "blot", key = key, model = monster, part = zone, name = monster.Name }, position)
                    end
                end
            else
                local enraged = monster.Name == "GlistenMonster" and monster:GetAttribute("GlistenActivated") == true
                local part = monster:FindFirstChild("RootPart") or monster.PrimaryPart
                local ok, position = pcall(function()
                    return part.Position
                end)
                if ok and position and not enraged then
                    local kind = R.RESEARCH_NEAR[monster.Name] and "near" or (monster.Name == "SquirmMonster" and "grab") or (monster.Name == "RazzleDazzleMonster" and "razzle") or "seen"
                    consider({ kind = kind, key = key, model = monster, part = part, name = monster.Name }, position)
                end
            end
        end
    end

    local items = map:FindFirstChild("Items")
    if items then
        for _, model in ipairs(items:GetChildren()) do
            if model.Name == "FakeCapsule" and not FARM.runFullyResearched("RodgerMonster") then
                local prompt = model:FindFirstChild("Prompt")
                local ok, position = pcall(function()
                    return prompt.Position
                end)
                local rodger = ok and position and FARM.runRodgerAt(monsters, position)
                local rodgerKey = rodger and FARM.runKey(rodger)
                local done = (rodgerKey and R.researched[rodgerKey]) or (rodger and FARM.runSawYou(rodger))
                if ok and position and not done and not R.skip[FARM.runSpotKey(position)] then
                    consider({ kind = "rodger", model = model, prompt = prompt, name = "Twisted Rodger", spot = FARM.runSpotKey(position), key = rodgerKey }, position)
                end
            end
        end
    end

    return best
end

function FARM.runSawYou(monster)
    local holder = monster:FindFirstChild("ChasingValue")
    local okTarget, target = pcall(function()
        return holder.Value
    end)
    if okTarget and target and tostring(target.ClassName) == "Model" and tostring(target.Name) == LocalPlayer.Name then
        return true
    end

    local ok, state, chasing, attacking = pcall(function()
        return monster:GetAttribute("ChaseState"), monster:GetAttribute("Chasing"), monster:GetAttribute("Attacking")
    end)
    return ok and (state == "run" or state == "attack" or chasing == true or attacking == true)
end

function FARM.runSprintOff()
    local L = FARM.LOBBY
    if L.shiftDown then
        FARM.setShift(false)
    end
end

function FARM.runDive(root, now, status)
    local R = FARM.RUN
    local floor = FARM.runFloorY(root.Position.X, root.Position.Y, root.Position.Z)
    if floor then
        R.hipOffset = math.clamp(root.Position.Y - floor, 2, 5)
    end
    R.surfaceY = root.Position.Y
    R.hideY = root.Position.Y - R.DEPTH
    local ground = FARM.runLowestFloorY(root.Position.X, root.Position.Y, root.Position.Z)
    if ground then
        R.hideY = math.min(R.hideY, ground + R.hipOffset - R.DEPTH)
    end
    R.hideUntil = now + R.HIDE_MAX
    R.clearSince = nil
    R.elevatorDive = nil
    R.elevatorSurface = nil
    R.hideGoal = nil
    R.hideGoalY = nil
    R.hideGoalAt = 0
    R.phase = "dive"
    R.at = now
    FARM.setStatus(status)
end

function FARM.runChaser(monster)
    local D = FARM.RUN.CHASER_DEFAULTS
    local chaser = monster:FindFirstChild("Chaser")
    local function read(name)
        local value = chaser and chaser:FindFirstChild(name)
        local ok, number = pcall(function()
            return value.Value
        end)
        if ok and type(number) == "number" then
            return number
        end
        return D[name]
    end
    return read("InstantRadius"), read("VisionRadius"), read("LineOfSight")
end

function FARM.runNearestTwisted(root, skipLethal)
    local R = FARM.RUN
    local map = FARM.runMap()
    local monsters = map and map:FindFirstChild("Monsters")
    if not monsters then
        return nil, nil
    end

    local bestMonster, bestPart, bestDistance
    for _, monster in ipairs(monsters:GetChildren()) do
        local info = MONSTER_INFO[monster.Name]
        local lethal = skipLethal and info ~= nil and info.rarity == "Lethal"
        if not FARM.runPassive(monster) and not lethal then
            local part = monster:FindFirstChild("RootPart") or monster.PrimaryPart
            local ok, position = pcall(function()
                return part.Position
            end)

            if ok and position then
                local distance = (position - root.Position).Magnitude
                if not bestDistance or distance < bestDistance then
                    bestMonster, bestPart, bestDistance = monster, part, distance
                end
            end
        end
    end

    return bestMonster, bestPart
end

FARM.whitelist = {}

function FARM.runOtherPlayers()
    local count = 0
    local myId = LocalPlayer.UserId
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId ~= myId and not FARM.whitelist[string.lower(player.Name)] then
            count = count + 1
        end
    end
    return count
end

function FARM.runHideGoal(root, character)
    local R = FARM.RUN
    local p = root.Position

    if FARM.MASTERY.travelOnly() then
        local spot = FARM.MASTERY.wanderPoint(root)
        if spot then
            return spot, R.ARRIVE, "travel checkpoint", nil, spot.Y + R.hipOffset
        end
    end

    if R.current and R.current.stand and not FARM.runDone(R.current) then
        local ok, stand = pcall(function()
            return R.current.stand.Position
        end)
        if ok and stand and Vector3.new(stand.X - p.X, 0, stand.Z - p.Z).Magnitude <= R.LOST then
            return nil, 0, ""
        end
    end

    local grab = FARM.runCollectTarget(root, character)
    if grab then
        local ok, position = pcall(function()
            return grab.prompt.Position
        end)
        if ok and position then
            return position, R.COLLECT_ARRIVE, (grab.kind == "capsule" and "Research Capsule" or grab.name), nil, position.Y + R.COLLECT_Y
        end
    end

    local study = FARM.runResearchTarget(root)
    if study then
        local point = study.kind == "seen" and FARM.runFacePoint(study)
        local ok, position = pcall(function()
            return (study.prompt or study.part).Position
        end)
        position = point or (ok and position)
        if position then
            local y = point and point.Y
            if not y then
                local floor = FARM.runFloorY(position.X, position.Y, position.Z)
                y = floor and (floor + R.hipOffset) or nil
            end
            return position, R.RESEARCH_FACE_ARRIVE, FARM.runResearchName(study.name), study.key, y
        end
    end

    if FARM.floorLimitHit() then
        return nil, 0, ""
    end

    local best, bestDistance
    for _, machine in ipairs(FARM.runMachines()) do
        if not FARM.runDone(machine) and not FARM.runConnie(machine) and not FARM.runTaken(machine) and not FARM.runBlotMachine(machine, root, tick()) then
            local ok, stand = pcall(function()
                return machine.stand.Position
            end)
            if ok and stand then
                local d = Vector3.new(stand.X - p.X, 0, stand.Z - p.Z).Magnitude
                if not bestDistance or d < bestDistance then
                    best, bestDistance = stand, d
                end
            end
        end
    end

    if best then
        return best, R.ARRIVE, "machine", nil, best.Y + R.STAND_Y
    end

    return nil, 0, ""
end

function FARM.runTravelTo(root, position, y)
    local R = FARM.RUN
    R.goalPos = position
    R.goalY = y
    R.startY = root.Position.Y
    R.travelStart = root.Position
end

function FARM.runClick(button)
    local p, s = button.AbsolutePosition, FARM.guiSize(button)
    pcall(mousemoveabs, math.floor(p.X + s.X / 2) + 1, math.floor(p.Y + s.Y / 2) + 24)
    pcall(mousemoverel, 3, 3)
    pcall(mousemoverel, -3, -3)
end

function FARM.runSized(button)
    if not button then
        return false
    end

    local ok, size = pcall(function()
        return FARM.guiSize(button)
    end)

    return ok and size ~= nil and size.X > 0
end

function FARM.runIsDead(character, root)
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local death = gui and gui:FindFirstChild("DeathGui")
    local screen = death and death:FindFirstChild("DeathScreen")
    local okScreen, position = pcall(function()
        return screen.AbsolutePosition
    end)

    if okScreen and position and position.Y > -100 then
        return true
    end

    if not character or not root then
        return false
    end

    local stats = character:FindFirstChild("Stats")
    local hearts = stats and stats:FindFirstChild("Health")
    local okHearts, count = pcall(function()
        return hearts.Value
    end)

    if okHearts and type(count) == "number" and count <= 0 then
        return true
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local ok, health = pcall(function()
        return humanoid.Health
    end)

    return ok and type(health) == "number" and health <= 0
end

function FARM.runButtonReady(button, now, wait)
    local R = FARM.RUN
    if not FARM.runSized(button) then
        R.buttonSeen = nil
        return false
    end
    local ok, position = pcall(function()
        return button.AbsolutePosition
    end)
    if not ok or not position then
        return false
    end
    local seen = R.buttonSeen
    if not seen or seen.button ~= button or math.abs(seen.position.X - position.X) > 1 or math.abs(seen.position.Y - position.Y) > 1 then
        R.buttonSeen = { button = button, position = position, at = now }
        return false
    end
    return now - seen.at >= (wait or R.BUTTON_WAIT)
end


function FARM.runDeathClick(now, button, status, settle, wait)
    local R = FARM.RUN

    if R.deathStage == 0 then
        if not FARM.runButtonReady(button, now, wait) then
            FARM.setStatus("Dead, waiting for the button")
            return false
        end
        R.buttonSeen = nil
        FARM.setStatus(status)
        FARM.runClick(button)
        R.deathStage = 1
        R.at = now + 0.3
    elseif R.deathStage == 1 and now >= R.at then
        pcall(mouse1press)
        R.deathStage = 2
        R.at = now + 0.32
    elseif R.deathStage == 2 and now >= R.at then
        pcall(mouse1release)
        R.deathStage = 3
        R.at = now + settle
    elseif R.deathStage == 3 and now >= R.at then
        R.deathStage = 0
        return true
    end

    return false
end

function FARM.runDeath(now)
    local R = FARM.RUN
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local spectator = gui and gui:FindFirstChild("SpectatorGui")
    local bottom = spectator and spectator:FindFirstChild("BottomFrame")
    local leave = bottom and bottom:FindFirstChild("LeaveLobby")

    if FARM.runSized(leave) then
        if R.deathStage == 0 then
            FARM.writeResume()
        end
        FARM.runDeathClick(now, leave, "Leaving to lobby", 3, 0.5)
        return
    end

    local death = gui and gui:FindFirstChild("DeathGui")
    local skip = death and death:FindFirstChild("SkipButton")
    local spectate = death and death:FindFirstChild("SpectateButton")

    if not R.skipped and FARM.runSized(skip) then
        if FARM.runDeathClick(now, skip, "Dead, skipping results", 0.5) then
            R.skipped = true
        end
        return
    end

    if spectate then
        FARM.runDeathClick(now, spectate, "Dead, opening spectate", 2.5, 0.5)
        return
    end

    FARM.setStatus("Dead, waiting for results")
end

function FARM.readyButton()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local screen = gui and gui:FindFirstChild("ScreenGui")
    local selection = screen and screen:FindFirstChild("SelectionFrame")
    local margin = selection and selection:FindFirstChild("Margin")
    local bottom = margin and margin:FindFirstChild("BottomFrame")
    local status = bottom and bottom:FindFirstChild("ReadyStatus")
    local button = status and status:FindFirstChild("ReadyUp")
    if not button then
        return nil, 0
    end

    local ok, size = pcall(function()
        return FARM.guiSize(button)
    end)

    if not ok or not size then
        return nil, 0
    end

    return button, size.X
end

function FARM.roundCountdown()
    local R = FARM.RUN
    local label = R.startLabel

    if not (label and label.Parent) then
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        local screen = gui and gui:FindFirstChild("ScreenGui")
        local selection = screen and screen:FindFirstChild("SelectionFrame")
        if not selection then
            return nil
        end

        for _, descendant in ipairs(selection:GetDescendants()) do
            if descendant.Name == "GameStarting" then
                label = descendant
                R.startLabel = descendant
                break
            end
        end
    end

    if not label then
        return nil
    end

    local ok, text = pcall(function()
        return label.Text
    end)

    if not ok or type(text) ~= "string" then
        return nil
    end

    return tonumber(string.match(text, "(%d+)"))
end

function FARM.runCards()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local screen = gui and gui:FindFirstChild("ScreenGui")
    local frame = screen and screen:FindFirstChild("VoteFrame")
    local cards = {}
    if not frame then
        return cards
    end

    for _, child in ipairs(frame:GetChildren()) do
        if child.ClassName == "TextButton" and child.Name ~= "Template" and child.Name ~= "FancyTemplate" then
            local object = child:FindFirstChild("Object")
            local module = object and FARM.runStringValue(object) or ""
            local lowered = string.lower(tostring(module))
            if lowered == "" or lowered == "none" then
                module = child.Name
            end
            local okModule = type(module) == "string" and module ~= ""
            local holder = child:FindFirstChild("Holder")
            local label = holder and holder:FindFirstChild("ItemName")
            local okTitle, title = pcall(function()
                return label.Text
            end)
            local okRect, size, position = pcall(function()
                return FARM.guiSize(child), child.AbsolutePosition
            end)

            if okModule and type(module) == "string" and module ~= "" and okRect and size and position and size.X > 0 then
                cards[#cards + 1] = {
                    button = child,
                    module = module,
                    title = (okTitle and type(title) == "string") and title or "",
                    signature = size.X + size.Y + position.X + position.Y,
                }
            end
        end
    end

    return cards
end

function FARM.runCardScore(card)
    local module = string.lower(card.module)
    local title = string.lower(card.title)

    if module == "machine" or title == "tech savvy" then
        return 4
    end
    if string.find(module, "^itemrarity") or title == "avaricious" or title == "covetous" then
        return 3
    end
    if module == "pipingtape" or title == "piping tape" then
        return 2
    end
    return 1
end

function FARM.runVote(now)
    local R = FARM.RUN
    local info = Workspace:FindFirstChild("Info")
    local voting = info and info:FindFirstChild("CardVoting")
    local okVoting, active = pcall(function()
        return voting.Value
    end)

    local cards = (okVoting and active == true) and FARM.runCards() or {}

    if #cards == 0 then
        if R.voteStage == 2 then
            pcall(mouse1release)
        end
        R.voteStage = 0
        R.voteClicked = false
        R.voteSignature = 0
        R.voteSteady = 0
        return false
    end

    if R.voteClicked then
        return false
    end

    local best
    local signature = 0
    for _, card in ipairs(cards) do
        signature = signature + card.signature
        if not best or FARM.runCardScore(card) > FARM.runCardScore(best) then
            best = card
        end
    end

    local label = best.title ~= "" and best.title or best.module

    if R.voteStage == 0 then
        if math.abs(signature - R.voteSignature) > 1 then
            R.voteSignature = signature
            R.voteSteady = now
            FARM.setStatus("Waiting for cards")
            return true
        end

        if now - R.voteSteady < R.CARD_STEADY then
            FARM.setStatus("Waiting for cards")
            return true
        end

        FARM.runRmb(false)
        FARM.runHoldW(false)
        FARM.setStatus("Voting " .. label)
        FARM.runClick(best.button)
        R.voteStage = 1
        R.voteAt = now + 0.3
    elseif R.voteStage == 1 and now >= R.voteAt then
        pcall(mouse1press)
        R.voteStage = 2
        R.voteAt = now + 0.32
    elseif R.voteStage == 2 and now >= R.voteAt then
        pcall(mouse1release)
        R.voteStage = 3
        R.voteAt = now + 0.5
    elseif R.voteStage == 3 and now >= R.voteAt then
        R.voteStage = 0
        R.voteClicked = true
        FARM.setStatus("Voted " .. label)
    end

    return true
end

function FARM.runReady(now)
    local R = FARM.RUN
    local info = Workspace:FindFirstChild("Info")
    local started = info and info:FindFirstChild("GameStarted")
    local okStarted, hasStarted = pcall(function()
        return started.Value
    end)

    local seconds = (not (okStarted and hasStarted == true)) and FARM.roundCountdown() or nil

    if not seconds or seconds <= 0 then
        R.readyClicked = false
        R.readyStage = 0
        R.readyWidth = 0
        R.readySteady = 0
        return false
    end

    local button, width = FARM.readyButton()

    if not button or width <= 0 then
        R.readyClicked = false
        R.readyStage = 0
        R.readyWidth = 0
        R.readySteady = 0
        return false
    end

    if R.readyClicked then
        FARM.setStatus("Waiting for the round")
        return true
    end

    if math.abs(width - R.readyWidth) > 1 then
        R.readyWidth = width
        R.readySteady = now
        FARM.setStatus("Waiting for Ready Up")
        return true
    end

    if now - R.readySteady < R.READY_STEADY then
        FARM.setStatus("Waiting for Ready Up")
        return true
    end

    if R.readyStage == 0 then
        FARM.setStatus("Pressing Ready Up")
        FARM.runClick(button)
        R.readyStage = 1
        R.at = now + 0.3
    elseif R.readyStage == 1 and now >= R.at then
        pcall(mouse1press)
        R.readyStage = 2
        R.at = now + 0.32
    elseif R.readyStage == 2 and now >= R.at then
        pcall(mouse1release)
        R.readyStage = 3
        R.at = now + 1.5
    elseif R.readyStage == 3 and now >= R.at then
        R.readyClicked = true
        R.readyStage = 0
    end

    return true
end

function FARM.runUpdate(now)
    local R = FARM.RUN
    FARM.runReleaseItemKey(now)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local camera = Workspace.CurrentCamera

    if R.dead or FARM.runIsDead(character, root) then
        R.dead = true
        if R.noCollide then
            FARM.runCollide(true)
        end
        FARM.runRmb(false)
        FARM.runHoldW(false)
        R.phase = "idle"
        R.current = nil
        FARM.runDeath(now)
        return
    end

    if not (root and camera) then
        if R.noCollide then
            FARM.runCollide(true)
        end
        FARM.runRmb(false)
        FARM.runHoldW(false)
        R.phase = "idle"
        return
    end

    R.deathStage = 0

    local underground = R.phase == "dive" or R.phase == "hide" or R.phase == "surface"
    if not SETTINGS.allowFarmWithPlayers and not underground then
        local others = FARM.runOtherPlayers()
        if others > 0 then
            FARM.runRmb(false)
            FARM.runHoldW(false)
            if R.noCollide then
                FARM.runCollide(true)
            end
            R.phase = "idle"
            R.current = nil
            FARM.setStatus(string.format("%d non-whitelisted player%s here, waiting", others, others == 1 and "" or "s"))
            return
        end
    end

    if not underground and FARM.runVote(now) then
        FARM.runHoldW(false)
        if R.noCollide then
            FARM.runCollide(true)
        end
        return
    end

    if FARM.runReady(now) then
        FARM.runRmb(false)
        if R.noCollide then
            FARM.runCollide(true)
        end
        R.phase = "idle"
        R.current = nil
        return
    end

    FARM.runUseItems(now, character)
    FARM.runStaminaSprint(now, root)

    local buying = R.targetKind == "buy" and (R.phase == "tween" or R.phase == "collect")
    if not underground and not buying and R.phase ~= "sacrifice" and R.phase ~= "working" then
        local deal = FARM.runStoreTarget(root, character)
        if deal then
            FARM.runRmb(false)
            R.current = nil
            R.collect = deal
            R.targetKind = "buy"
            FARM.runTravelTo(root, deal.prompt.Position, root.Position.Y)
            R.phase = "tween"
            buying = true
            FARM.setStatus(string.format("Buying %s for %d tapes", deal.name, deal.price))
        end
    end

    if not underground and not buying and R.elevatorHold ~= "none" then
        local inside, isOpen = FARM.runElevatorState(character, root)

        if not inside then
            R.elevatorHold = "none"
        elseif isOpen == false then
            R.elevatorHold = "closed"
            FARM.runRmb(false)
            FARM.runHoldW(false)
            if R.noCollide then
                FARM.runCollide(true)
            end
            R.phase = "waitFloor"
            R.current = nil
            FARM.setStatus("Waiting for elevator doors")
            return
        elseif isOpen == true and R.elevatorHold == "closed" then
            R.elevatorHold = "none"
        end
    end

    if R.phase == "idle" then
        R.phase = "pick"
    end

    local researching = R.phase == "research" and R.research
    local hidingFor = (R.phase == "dive" or R.phase == "hide" or R.phase == "surface") and R.hideIgnore
    local nearest, chasing, panic, seen = FARM.runThreat(root, (researching and R.research.key) or hidingFor or nil)
    local hiding = R.phase == "dive" or R.phase == "hide" or R.phase == "surface"

    local travelIgnore = SETTINGS.farmIgnoreTwistedsTravel and (R.phase == "tween" or R.phase == "collect")
    local grabbing = R.phase == "collect" and R.collect and R.collectDeadline and now < R.collectDeadline
    if (chasing or panic) and not hiding and not travelIgnore and not grabbing and R.phase ~= "sacrifice" and not FARM.runSafeInElevator(character) then
        FARM.runRmb(false)
        if R.current and FARM.runEngagedBy(R.current) == LocalPlayer.Name then
            FARM.tapKey(R.E_KEY)
        end

        local toElevator = R.phase == "toElevator"
        R.research = nil
        R.hideIgnore = nil
        FARM.runSprintOff()
        FARM.runDive(root, now, toElevator and "Twisted near, diving to the elevator" or "Twisted near, diving")
        R.elevatorDive = toElevator or nil
        return
    end

    if not hiding and R.phase ~= "flee" and R.phase ~= "toElevator" and R.phase ~= "sacrifice" then
        local tendril = FARM.runHazardNear(root.Position, now)
        if tendril then
            FARM.runRmb(false)
            if R.current and FARM.runEngagedBy(R.current) == LocalPlayer.Name then
                FARM.tapKey(R.E_KEY)
            end
            R.current = nil
            R.collect = nil
            R.research = nil
            R.fleeY = root.Position.Y
            R.phase = "flee"
            FARM.setStatus("Sprout tendril or active Rodger near, moving away")
            return
        end
    end

    if R.phase == "flee" then
        local p = root.Position
        local tendril = FARM.runHazardNear(p, now, R.SPROUT_FLEE_MARGIN)
        if not tendril then
            FARM.runHoldW(false)
            FARM.runCollide(true)
            R.phase = "pick"
            return
        end
        FARM.runCollide(false)
        FARM.runFreeze(root)
        FARM.runHoldW(true)
        local away = Vector3.new(p.X - tendril.X, 0, p.Z - tendril.Z)
        local direction = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
        FARM.runFace(camera, root, p + direction * 10)
        local step = FARM.tweenSpeed() * 0.016
        local x, z = p.X + direction.X * step, p.Z + direction.Z * step
        local floor = FARM.runFloorY(x, R.fleeY, z)
        local y = floor and (floor + R.hipOffset) or R.fleeY
        R.fleeY = y
        root.Position = Vector3.new(x, y, z)
        return
    end

    if R.phase == "dive" then
        FARM.runCollide(false)
        FARM.runFreeze(root)
        FARM.runHoldW(false)
        local p = root.Position
        root.Position = Vector3.new(p.X, R.hideY, p.Z)
        R.phase = "hide"
        FARM.setStatus("Hiding")
        return
    end

    if R.phase == "hide" then
        FARM.runCollide(false)
        FARM.runFreeze(root)
        local p = root.Position

        local tendril = FARM.runHazardNear(p, now, R.SPROUT_FLEE_MARGIN)
        if tendril then
            R.clearSince = nil
            FARM.runHoldW(true)
            local away = Vector3.new(p.X - tendril.X, 0, p.Z - tendril.Z)
            local direction = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
            FARM.runFace(camera, root, p + direction * 10)
            local step = FARM.tweenSpeed() * 0.016
            root.Position = Vector3.new(p.X + direction.X * step, R.hideY, p.Z + direction.Z * step)
            FARM.setStatus("Sprout tendril or active Rodger near, moving away")
            return
        end

        if R.elevatorDive then
            local base = FARM.runElevatorBase()
            local okBase, target = pcall(function()
                return base.Position
            end)
            if okBase and target then
                local flat = Vector3.new(target.X - p.X, 0, target.Z - p.Z)
                if flat.Magnitude <= R.ELEV_ARRIVE then
                    FARM.runHoldW(false)
                    FARM.runRmb(false)
                    root.Position = Vector3.new(p.X, R.hideY, p.Z)
                    R.surfaceY = target.Y + 3
                    R.elevatorDive = nil
                    R.elevatorSurface = true
                    R.clearSince = nil
                    R.hideIgnore = nil
                    R.phase = "surface"
                    FARM.setStatus("Surfacing inside the elevator")
                    return
                end
                FARM.runHoldW(true)
                FARM.runFace(camera, root, target)
                local step = math.min(FARM.tweenSpeed() * 0.016, flat.Magnitude)
                local direction = flat.Unit
                root.Position = Vector3.new(p.X + direction.X * step, R.hideY, p.Z + direction.Z * step)
                FARM.setStatus("Hiding, moving to the elevator underground")
                return
            end
            R.elevatorDive = nil
        end

        if chasing or seen or FARM.runHazardNear(p, now) or FARM.runBlotHandNear(Vector3.new(p.X, R.surfaceY, p.Z), root) then
            R.clearSince = nil
        elseif not R.clearSince then
            R.clearSince = now
        end

        if (R.clearSince and now - R.clearSince >= R.CLEAR_TIME) or now >= R.hideUntil then
            R.clearSince = nil
            FARM.runHoldW(false)
            FARM.runRmb(false)
            root.Position = Vector3.new(p.X, R.hideY, p.Z)
            local goal = R.hideGoal
            local atGoal = goal and R.hideGoalY and Vector3.new(goal.X - p.X, 0, goal.Z - p.Z).Magnitude <= (R.hideGoalRadius or 0) + 1
            if atGoal then
                R.surfaceY = R.hideGoalY
            else
                local floor = FARM.runFloorY(p.X, R.surfaceY, p.Z)
                if floor and math.abs(floor + R.hipOffset - R.surfaceY) <= R.SURFACE_TOLERANCE then
                    R.surfaceY = floor + R.hipOffset
                end
            end
            R.hideIgnore = nil
            R.phase = "surface"
            FARM.setStatus("Surfacing")
            return
        end

        if now >= R.hideGoalAt then
            R.hideGoalAt = now + R.HIDE_RETARGET
            R.hideGoal, R.hideGoalRadius, R.hideGoalLabel, R.hideIgnore, R.hideGoalY = FARM.runHideGoal(root, character)
        end

        local goal = R.hideGoal
        local flat = goal and Vector3.new(goal.X - p.X, 0, goal.Z - p.Z)

        if flat and flat.Magnitude > R.hideGoalRadius then
            FARM.runHoldW(true)
            FARM.runFace(camera, root, goal)
            local step = math.min(FARM.tweenSpeed() * 0.016, flat.Magnitude)
            local direction = flat.Unit
            root.Position = Vector3.new(p.X + direction.X * step, R.hideY, p.Z + direction.Z * step)
            FARM.setStatus("Hiding, moving to " .. R.hideGoalLabel)
        else
            FARM.runHoldW(false)
            FARM.runRmb(false)
            root.Position = Vector3.new(p.X, R.hideY, p.Z)
            FARM.setStatus("Hiding")
            if FARM.MASTERY.travelOnly() then
                R.hideGoalAt = 0
            end
        end
        return
    end

    if R.phase == "surface" then
        FARM.runCollide(false)
        FARM.runFreeze(root)
        FARM.runHoldW(false)
        local p = root.Position
        local y = math.min(p.Y + math.max(SETTINGS.tweenWalkSpeed, R.DIVE_SPEED) * 0.016, R.surfaceY)
        root.Position = Vector3.new(p.X, y, p.Z)

        if y >= R.surfaceY - 0.5 then
            FARM.runCollide(true)
            if R.elevatorSurface then
                R.elevatorSurface = nil
                R.elevatorHold = "armed"
                R.phase = "waitFloor"
                FARM.setStatus("In elevator")
                return
            end
            R.phase = "pick"
        end
        return
    end

    if R.current and (R.phase == "aim" or R.phase == "working") then
        local ok, stand = pcall(function()
            return R.current.stand.Position
        end)
        if ok and stand and (root.Position - (stand + Vector3.new(0, R.STAND_Y, 0))).Magnitude > R.AT_MACHINE then
            FARM.runRmb(false)
            FARM.runHoldW(false)
            R.current = nil
            R.phase = "pick"
            FARM.setStatus("Not at the machine, going back")
            return
        end
    end

    if R.current and R.targetKind == "machine" and (R.phase == "tween" or R.phase == "aim" or R.phase == "working") and FARM.runConnie(R.current) then
        FARM.runRmb(false)
        FARM.runHoldW(false)
        if R.noCollide then
            FARM.runCollide(true)
        end
        R.current = nil
        R.phase = "pick"
        FARM.setStatus("Connie got into the machine, leaving")
        return
    end

    if R.current and R.targetKind == "machine" and (R.phase == "tween" or R.phase == "aim" or R.phase == "working") and FARM.runTaken(R.current) then
        FARM.runRmb(false)
        FARM.runHoldW(false)
        if R.noCollide then
            FARM.runCollide(true)
        end
        R.current = nil
        R.phase = "pick"
        FARM.setStatus("Another player took the machine, leaving")
        return
    end

    if R.current and R.targetKind == "machine" and (R.phase == "tween" or R.phase == "aim" or R.phase == "working") and FARM.runBlotMachine(R.current, root, now) then
        FARM.runRmb(false)
        FARM.runHoldW(false)
        if R.phase == "working" then
            FARM.tapKey(R.E_KEY)
        end
        if R.noCollide then
            FARM.runCollide(true)
        end
        R.current = nil
        R.phase = "pick"
        FARM.setStatus("Unsafe machine, leaving")
        return
    end

    if R.phase == "pick" then
        FARM.runCollide(true)
        FARM.runRmb(false)
        FARM.runHoldW(false)

        if FARM.floorLimitHit() then
            R.current = nil
            R.sacrificeY = root.Position.Y
            R.phase = "sacrifice"
            FARM.setStatus(FARM.MASTERY.passiveDeath() and "Mastery: getting hit for the passive ability" or (FARM.MASTERY.runState == "done" and SETTINGS.masteryEnd and "Mastery done, ending the run" or ("Floor limit reached (" .. FARM.currentFloor() .. ")")))
            return
        end

        if now < R.roomUntil then
            FARM.setStatus("Making room for an item")
            return
        end

        if FARM.runMakeRoom(now, character) then
            return
        end

        if FARM.MASTERY.needHit(now, character) then
            R.current = nil
            R.sacrificeY = root.Position.Y
            R.hurtFrom = FARM.MASTERY.health(character)
            R.phase = "sacrifice"
            FARM.setStatus("Mastery: inventory full of heals, taking a hit")
            return
        end

        local grab = FARM.runCollectTarget(root, character)
        if grab and FARM.runHazardNear(grab.prompt.Position, now) then
            grab = nil
        end
        if grab then
            R.current = nil
            R.collect = grab
            R.targetKind = grab.kind
            FARM.runTravelTo(root, grab.prompt.Position, grab.prompt.Position.Y + R.COLLECT_Y)
            R.phase = "tween"
            FARM.setStatus("Moving to " .. (grab.kind == "capsule" and "Research Capsule" or grab.name))
            return
        end

        local study = FARM.runResearchTarget(root)
        if study and study.kind == "rodger" then
            R.current = nil
            R.collect = study
            R.targetKind = "rodger"
            FARM.runTravelTo(root, study.prompt.Position, study.prompt.Position.Y + R.COLLECT_Y)
            R.phase = "tween"
            FARM.setStatus("Moving to Twisted Rodger")
            return
        elseif study then
            R.current = nil
            R.collect = nil
            R.research = study
            R.researchY = root.Position.Y
            R.researchStart = now
            R.researchArrived = nil
            R.facePoint = nil
            R.faceAt = 0
            R.researchGrabbed = nil
            R.researchCount = FARM.runResearchCount()
            R.phase = "research"
            FARM.setStatus("Moving to " .. FARM.runResearchName(study.name) .. " for research")
            return
        end

        if FARM.MASTERY.travelOnly() then
            local spot = FARM.MASTERY.wanderPoint(root)
            if spot then
                R.current = nil
                R.collect = nil
                R.targetKind = "wander"
                FARM.runTravelTo(root, spot, spot.Y + R.hipOffset)
                R.phase = "tween"
                FARM.setStatus("Mastery: walking for Travel")
                return
            end
        end

        R.targetKind = "machine"
        R.collect = nil

        local best, bestDistance
        local blocked = false
        local blotBlocked = false
        local takenBlocked = false
        for _, machine in ipairs(FARM.runMachines()) do
            if not FARM.runDone(machine) then
                if FARM.runConnie(machine) then
                    blocked = true
                elseif FARM.runTaken(machine) then
                    takenBlocked = true
                elseif FARM.runBlotMachine(machine, root, now) then
                    blotBlocked = true
                else
                    local d = (machine.stand.Position - root.Position).Magnitude
                    if not bestDistance or d < bestDistance then
                        best, bestDistance = machine, d
                    end
                end
            end
        end

        if not best and blocked then
            R.current = nil
            FARM.setStatus("Connie is inside the last machine, waiting")
            return
        end

        if not best and takenBlocked then
            R.current = nil
            FARM.setStatus("Another player is on the last machine, waiting")
            return
        end

        if not best and blotBlocked then
            R.current = nil
            if FARM.runBlotHandNear(root.Position, root) then
                FARM.runDive(root, now, "Blot hand next to the machine, diving")
            else
                FARM.setStatus("Unsafe machine, waiting")
            end
            return
        end

        if not best then
            local base = FARM.runElevatorBase()
            if not base then
                FARM.setStatus("No elevator found")
                return
            end

            R.current = nil
            FARM.runTravelTo(root, base.Position, base.Position.Y + 3)
            R.phase = "toElevator"
            FARM.setStatus("Moving to elevator")
            return
        end

        R.current = best
        FARM.runTravelTo(root, best.stand.Position, best.stand.Position.Y + R.STAND_Y)
        R.phase = "tween"
        FARM.setStatus("Moving to machine")
        return
    end

    if R.phase == "tween" or R.phase == "toElevator" then
        FARM.runCollide(false)
        FARM.runFreeze(root)
        FARM.runHoldW(true)
        FARM.runFace(camera, root, R.goalPos)

        local p = root.Position
        local flat = Vector3.new(R.goalPos.X - p.X, 0, R.goalPos.Z - p.Z)
        local distance = flat.Magnitude
        local total = Vector3.new(R.goalPos.X - R.travelStart.X, 0, R.goalPos.Z - R.travelStart.Z).Magnitude
        local collecting = R.phase == "tween" and R.targetKind ~= "machine" and R.collect ~= nil
        local radius = (R.phase == "toElevator") and R.ELEV_ARRIVE or (collecting and (R.targetKind == "buy" and R.BUY_ARRIVE or R.COLLECT_ARRIVE)) or R.ARRIVE

        if distance <= radius then
            FARM.runCollide(true)
            FARM.runHoldW(false)
            if R.phase == "toElevator" then
                FARM.runRmb(false)
                R.elevatorHold = "armed"
                R.phase = "waitFloor"
                FARM.setStatus("In elevator")
                return
            end

            if collecting then
                FARM.runRmb(false)
                FARM.runFreeze(root)
                R.buyTapes = FARM.runTapes()
                R.phase = "collect"
                R.collectTries = 0
                R.at = now
                R.collectDeadline = now + R.COLLECT_GRACE
                return
            end

            if R.targetKind == "wander" then
                R.targetKind = "machine"
                R.phase = "pick"
                return
            end

            if FARM.onArrive then FARM.onArrive() end
            R.phase = "aim"
            R.at = now + R.AIM_MAX
            return
        end

        local step = math.min(FARM.tweenSpeed() * 0.016, distance)
        local direction = flat.Unit
        local t = total > 0 and math.clamp(1 - distance / total, 0, 1) or 1
        root.Position = Vector3.new(p.X + direction.X * step, R.startY + (R.goalY - R.startY) * t, p.Z + direction.Z * step)
        return
    end

    if R.phase == "research" then
        local target = R.research
        local label = target and FARM.runResearchName(target.name) or ""
        local okPosition, goal = pcall(function()
            return target.part.Position
        end)

        local function finish(status, retry)
            if target and not retry then
                R.researched[target.key] = true
            end
            FARM.runSprintOff()
            R.facePoint = nil
            R.faceAt = 0
            R.research = nil
            FARM.runHoldW(false)
            FARM.runRmb(false)
            if R.noCollide then
                FARM.runCollide(true)
            end
            if status then
                FARM.setStatus(status)
            end
            R.phase = "pick"
        end

        if not target or target.model.Parent == nil or not okPosition or not goal then
            finish()
            return
        end

        if target.kind == "blot" and R.researchArrived then
            finish()
            FARM.runDive(root, now, "Got research from " .. label .. ", diving")
            return
        end

        if target.kind == "grab" then
            local okHold, holding = pcall(function()
                return target.model:GetAttribute("SquirmState") == "HOLDING" or target.model:GetAttribute("GrabbedPlayer") ~= nil
            end)
            if okHold and holding then
                R.researchGrabbed = true
                FARM.setStatus("Grabbed by " .. label)
                return
            elseif R.researchGrabbed then
                R.researchGrabbed = nil
                finish()
                FARM.runDive(root, now, "Got research from " .. label .. ", diving")
                return
            end
        end

        local count = FARM.runResearchCount()
        local counted = target.kind == "near" and count and R.researchCount and count > R.researchCount
        local sawYou = (target.kind == "seen" or target.kind == "razzle") and FARM.runSawYou(target.model)
        if sawYou then
            FARM.sprintUpdate(now, false)
        end
        if counted or sawYou then
            if target.kind == "near" then
                finish("Got research from " .. label)
            else
                finish()
                FARM.runDive(root, now, "Got research from " .. label .. ", diving")
            end
            return
        end

        local radius
        local standY
        if target.kind == "blot" then
            radius = R.RESEARCH_BLOT_ARRIVE
        elseif target.kind == "grab" then
            radius = R.RESEARCH_GRAB_ARRIVE
        elseif target.kind == "near" then
            radius = R.RESEARCH_NEAR[target.name]
        elseif target.kind == "razzle" then
            radius = R.RESEARCH_RAZZLE_ARRIVE
        else
            local instant = FARM.runChaser(target.model)
            radius = math.max(instant * R.RESEARCH_SEEN_SCALE, 4)
            if not R.researchArrived then
                if now >= (R.faceAt or 0) then
                    R.faceAt = now + R.RESEARCH_FACE_REFRESH
                    R.facePoint = FARM.runFacePoint(target)
                end
                if R.facePoint then
                    goal = R.facePoint
                    standY = R.facePoint.Y
                    radius = R.RESEARCH_FACE_ARRIVE
                end
            end
        end

        if not standY then
            local floor = FARM.runFloorY(goal.X, root.Position.Y, goal.Z)
            standY = floor and (floor + R.hipOffset) or R.researchY
        end

        local p = root.Position
        local flat = Vector3.new(goal.X - p.X, 0, goal.Z - p.Z)
        local distance = flat.Magnitude
        local wait = (target.kind == "grab" and R.RESEARCH_GRAB_WAIT) or (target.kind == "razzle" and R.RESEARCH_RAZZLE_WAIT) or R.COLLECT_TRIES * R.COLLECT_RETRY

        if R.researchArrived and now - R.researchArrived >= wait then
            finish("No research from " .. label .. ", skipping")
            return
        end

        if not R.researchArrived and now - R.researchStart >= R.RESEARCH_TRAVEL_MAX then
            finish("Could not reach " .. label .. ", skipping")
            return
        end

        if (distance <= radius and math.abs(p.Y - standY) <= 1.5) or R.researchArrived then
            R.researchArrived = R.researchArrived or now
            if R.noCollide then
                FARM.runCollide(true)
            end
            if target.kind == "razzle" then
                FARM.runFace(camera, root, goal)
                FARM.runHoldW(true)
                FARM.sprintUpdate(now, true)
                FARM.setStatus(string.format("Sprinting to wake %s (%.1fs)", label, math.max(wait - (now - R.researchArrived), 0)))
                return
            end
            FARM.runHoldW(false)
            if target.kind == "seen" then
                FARM.runFace(camera, root, goal)
            else
                FARM.runRmb(false)
            end
            FARM.setStatus(string.format("Letting %s see you (%.1fs)", label, math.max(wait - (now - R.researchArrived), 0)))
            return
        end

        FARM.setStatus(string.format("Moving to %s for research (%d)", label, math.floor(distance)))
        FARM.runFace(camera, root, goal)
        FARM.runHoldW(true)
        FARM.runCollide(false)
        FARM.runFreeze(root)
        local speed = FARM.tweenSpeed() * 0.016
        local step = math.min(speed, distance)
        local direction = distance > 0.01 and flat.Unit or Vector3.new(0, 0, 0)
        local y = p.Y + math.clamp(standY - p.Y, -speed, speed)
        root.Position = Vector3.new(p.X + direction.X * step, y, p.Z + direction.Z * step)
        return
    end

    if R.phase == "sacrifice" and R.hurtFrom then
        local health = FARM.MASTERY.health(character)
        local hit = health ~= nil and health < R.hurtFrom
        local monster = FARM.runNearestTwisted(root, true)
        if hit or not monster or not FARM.MASTERY.itemMode() then
            if not hit then FARM.MASTERY.hitBlockUntil = now + 10 end
            R.hurtFrom = nil
            FARM.runHoldW(false)
            if R.noCollide then
                FARM.runCollide(true)
            end
            R.phase = "pick"
            return
        end
    end

    if R.phase == "sacrifice" then
        local monster, part = FARM.runNearestTwisted(root, R.hurtFrom ~= nil or FARM.MASTERY.passiveDeath())
        if not part then
            FARM.runRmb(false)
            FARM.runHoldW(false)
            if R.noCollide then
                FARM.runCollide(true)
            end
            FARM.setStatus((FARM.MASTERY.runState == "done" and SETTINGS.masteryEnd and "Mastery done" or "Floor limit reached") .. ", no twisted found")
            return
        end

        local p = root.Position
        local target = part.Position
        local flat = Vector3.new(target.X - p.X, 0, target.Z - p.Z)
        local distance = flat.Magnitude

        FARM.setStatus(string.format("%s, walking into %s (%d)", R.hurtFrom and "Mastery: taking a hit" or (FARM.MASTERY.passiveDeath() and "Mastery: passive ability" or (FARM.MASTERY.runState == "done" and SETTINGS.masteryEnd and "Mastery done" or "Floor limit reached")), monster.Name, math.floor(distance)))
        FARM.runFace(camera, root, target)
        FARM.runHoldW(true)

        if distance <= R.SACRIFICE_TOUCH then
            if R.noCollide then
                FARM.runCollide(true)
            end
            return
        end

        FARM.runCollide(false)
        FARM.runFreeze(root)
        local step = math.min(FARM.tweenSpeed() * 0.016, distance)
        local direction = flat.Unit
        root.Position = Vector3.new(p.X + direction.X * step, R.sacrificeY, p.Z + direction.Z * step)
        return
    end

    FARM.runCollide(true)

    if R.phase == "waitFloor" then
        FARM.runRmb(false)
        for _, machine in ipairs(FARM.runMachines()) do
            if not FARM.runDone(machine) then
                R.phase = "pick"
                return
            end
        end
        return
    end

    if R.phase == "collect" then
        local target = R.collect
        if not (target and target.wrongSince) then
            FARM.runRmb(false)
        end

        if target and target.kind == "buy" and FARM.runTapes() < R.buyTapes then
            R.bought[target.name] = true
            R.skip[target.spot] = true
            R.collect = nil
            R.phase = "pick"
            return
        end

        if not target or target.model.Parent == nil or not target.model:FindFirstChild("Prompt") then
            if target and target.kind == "buy" then
                R.bought[target.name] = true
            end
            R.collect = nil
            R.phase = "pick"
            return
        end

        local okPos, position = pcall(function()
            return target.prompt.Position
        end)
        local flat = okPos and position and Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z).Magnitude or 0
        if flat > R.LOST then
            R.phase = "pick"
            return
        end

        if target.kind == "buy" and okPos and position then
            if FARM.runPromptShows(target.name) == false then
                target.wrongSince = target.wrongSince or now
                if now - target.wrongSince < 3 then
                    FARM.runFace(camera, root, position)
                    if flat > 1.5 then
                        local direction = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z).Unit
                        local step = math.min(flat - 1.5, 0.5)
                        root.Position = root.Position + direction * step
                    end
                    FARM.setStatus("Aiming at " .. target.name)
                    return
                end
                R.skip[target.spot] = true
                R.collect = nil
                R.phase = "pick"
                FARM.runRmb(false)
                return
            end
            target.wrongSince = nil
        end

        if now >= R.at then
            if R.collectTries >= R.COLLECT_TRIES then
                R.skip[target.spot] = true
                R.collect = nil
                R.phase = "pick"
                return
            end

            FARM.tapKey(R.E_KEY)
            if target.kind == "rodger" then
                R.skip[target.spot] = true
                if target.key then
                    R.researched[target.key] = true
                end
            end
            R.collectTries = R.collectTries + 1
            R.at = now + R.COLLECT_RETRY
            FARM.setStatus((target.kind == "buy" and "Buying " or "Collecting ") .. (target.kind == "capsule" and "Research Capsule" or target.name))
        end
        return
    end

    if R.phase == "aim" then
        local aligned = FARM.runFace(camera, root, R.current.prompt.Position)
        if aligned or now >= R.at then
            FARM.runRmb(false)
            FARM.tapKey(R.E_KEY)
            R.phase = "working"
            R.at = now + R.REPRESS
        end
        return
    end

    if R.phase == "working" then
        FARM.runRmb(false)
        local cur, req = FARM.runFill(R.current)
        FARM.setStatus(string.format("Working %d/%d", math.floor(cur), math.floor(req)))

        if FARM.runDone(R.current) then
            R.phase = "pick"
            return
        end

        local distance = (R.current.stand.Position - root.Position).Magnitude
        if distance > R.LOST then
            R.current = nil
            R.phase = "pick"
            FARM.setStatus("Knocked away")
            return
        end

        if FARM.runEngagedBy(R.current) ~= LocalPlayer.Name and now >= R.at then
            R.at = now + R.REPRESS
            R.phase = "aim"
        end
        return
    end
end

function FARM.runStop()
    local R = FARM.RUN
    FARM.runRmb(false)
    FARM.runHoldW(false)
    FARM.setShift(false)
    if FARM.RUN.shiftReleaseAt then
        FARM.RUN.shiftReleaseAt = nil
        pcall(keyrelease, FARM.LOBBY.SHIFT)
    end
    if R.noCollide then
        FARM.runCollide(true)
    end
    FARM.runReleaseItemKey(0, true)
    R.phase = "idle"
    R.current = nil
    R.elevatorDive = nil
    R.elevatorSurface = nil
    R.deathStage = 0
end

local function drawVisual(visual, cameraPosition, tracerFrom)
    if not SETTINGS.enabled then
        hideVisual(visual)
        return false
    end

    if not SETTINGS.showCompletedGenerators and visualIsCompleted(visual) then
        hideVisual(visual)
        return false
    end

    local position = getVisualPosition(visual)
    if not position then
        hideVisual(visual)
        return false
    end

    local distance = (position - cameraPosition).Magnitude
    if distance > SETTINGS.maxDistance then
        hideVisual(visual)
        return false
    end

    local color = getVisualColor(visual)
    local screenPosition, onScreen = cameraWorldToScreen(position + Vector3.new(0, 2.5, 0))
    if not screenPosition then
        hideVisual(visual)
        return false
    end

    if not onScreen then
        hideVisual(visual)
        return false
    end

    local nameText, rarityText = getVisualName(visual)
    local count = 0

    if SETTINGS.showRoom and visual.roomName and visual.roomName ~= "" then
        if visual.roomTextFor ~= visual.roomName then
            visual.roomTextFor = visual.roomName
            visual.roomText = "[" .. visual.roomName .. "]"
        end

        count = count + 1
        lineScratch[count] = visual.roomText
    end

    if SETTINGS.showDistance then
        local meters = math.floor(distance + 0.5)
        if visual.distanceMeters ~= meters then
            visual.distanceMeters = meters
            visual.distanceText = tostring(meters) .. "m"
        end

        count = count + 1
        lineScratch[count] = visual.distanceText
    end

    if SETTINGS.showName then
        count = count + 1
        lineScratch[count] = nameText
    end

    if SETTINGS.showMachineType and visual.category == "Generators" then
        local now = tick()
        if now - (visual.machineCheckedAt or 0) >= 1 then
            visual.machineCheckedAt = now
            local machine = machineTypeLabel(visual.item)
            visual.machineText = machine and ("[" .. machine .. "]") or nil
        end

        if visual.machineText then
            count = count + 1
            lineScratch[count] = visual.machineText
        end
    end

    if rarityText then
        local rarityOn
        if visual.baseRarityKind == "twisted" then
            rarityOn = SETTINGS.showTwistedRarity
        else
            rarityOn = SETTINGS.showItemRarity
        end

        if rarityOn then
            if visual.rarityTextFor ~= rarityText then
                visual.rarityTextFor = rarityText
                visual.rarityText = "[" .. rarityText .. "]"
            end

            count = count + 1
            lineScratch[count] = visual.rarityText
        end
    end

    local abilityText = nil
    if visual.abilityDrawing and SETTINGS.showAbilityTimer then
        abilityText = abilityLabel(visual, tick())
    end

    local recolor = visual.lastColor ~= color
    if recolor then
        visual.lastColor = color
    end

    local bottomY = screenPosition.Y - LABEL_GAP
    for index = 1, LABEL_LINES do
        local line = visual.lines[index]
        local text = index <= count and lineScratch[index] or nil

        if text then
            if recolor then
                line.drawing.Color = color
            end

            if line.text ~= text then
                line.text = text
                line.drawing.Text = text
            end

            line.drawing.Position = Vector2.new(screenPosition.X, bottomY - (count - index) * LABEL_LINE_HEIGHT)

            if not line.visible then
                line.visible = true
                line.drawing.Visible = true
            end
        elseif line.visible then
            line.visible = false
            line.drawing.Visible = false
        end
    end

    if visual.abilityDrawing then
        if abilityText then
            if recolor then
                visual.abilityDrawing.Color = color
            end

            if visual.abilityShown ~= abilityText then
                visual.abilityShown = abilityText
                visual.abilityDrawing.Text = abilityText
            end

            local stackTop = bottomY - (math.max(count, 1) - 1) * LABEL_LINE_HEIGHT
            visual.abilityDrawing.Position = Vector2.new(screenPosition.X, stackTop - ABILITY.TEXT_SIZE)

            if not visual.abilityVisible then
                visual.abilityVisible = true
                visual.abilityDrawing.Visible = true
            end
        elseif visual.abilityVisible then
            visual.abilityVisible = false
            visual.abilityDrawing.Visible = false
        end
    end

    if SETTINGS.showDot then
        if recolor then
            visual.dot.Color = color
        end

        visual.dot.Position = screenPosition
    end

    if visual.dotOn ~= SETTINGS.showDot then
        visual.dotOn = SETTINGS.showDot
        visual.dot.Visible = SETTINGS.showDot
    end

    local tracerOn = SETTINGS.showTracer
    if not tracerOn and visual.alertKey and SETTINGS[visual.alertKey] then
        if visual.alertKind == "item" then
            tracerOn = SETTINGS.itemAlertTracers
        else
            tracerOn = SETTINGS.alertTracers
        end
    end

    if tracerOn then
        if recolor then
            visual.tracer.Color = color
        end

        visual.tracer.From = tracerFrom
        visual.tracer.To = screenPosition
    end

    if visual.tracerOn ~= tracerOn then
        visual.tracerOn = tracerOn
        visual.tracer.Visible = tracerOn
    end

    visual.hidden = false
    return true
end

local function drawAll(deltaTime)
    lastUpdate = lastUpdate + deltaTime
    if lastUpdate < SETTINGS.updateInterval then
        return
    end

    lastUpdate = 0
    currentResolveBudget = SETTINGS.resolveBudget

    local camera = Workspace.CurrentCamera
    if not camera then
        for _, visual in pairs(tracked) do
            hideVisual(visual)
        end

        return
    end

    local viewport = camera.ViewportSize
    local tracerFrom = Vector2.new(viewport.X * 0.5, viewport.Y - 24)
    local cameraPosition = camera.Position

    local visibleCount = 0
    for _, visual in pairs(tracked) do
        if SETTINGS.maxVisible > 0 and visibleCount >= SETTINGS.maxVisible then
            hideVisual(visual)
        elseif drawVisual(visual, cameraPosition, tracerFrom) then
            visibleCount = visibleCount + 1
        end
    end
end

function SQUIRM.findModel()
    local room = Workspace:FindFirstChild("CurrentRoom")
    if not room then
        return nil
    end

    for _, child in ipairs(room:GetChildren()) do
        local folder = child:FindFirstChild("Monsters")
        local model = folder and folder:FindFirstChild("SquirmMonster")
        if model then
            return model
        end
    end

    return nil
end

function SQUIRM.isTargetingMe(model)
    if not SQUIRM.WARN_STATES[model:GetAttribute("SquirmState") or ""] then
        return false
    end

    local root = model:FindFirstChild("RootPart") or model.PrimaryPart
    local character = LocalPlayer.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    if not (root and myRoot) or character:GetAttribute("GrabbedBySquirm") then
        return false
    end

    local origin = root.Position
    local mine = myRoot.Position
    local myDistance = Vector3.new(mine.X - origin.X, 0, mine.Z - origin.Z).Magnitude
    if myDistance > SQUIRM.WARN_RANGE then
        return false
    end

    local myId = LocalPlayer.UserId
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId ~= myId then
            local other = player.Character
            local otherRoot = other and other:FindFirstChild("HumanoidRootPart")
            if otherRoot then
                local p = otherRoot.Position
                if Vector3.new(p.X - origin.X, 0, p.Z - origin.Z).Magnitude < myDistance then
                    return false
                end
            end
        end
    end

    return true
end

function SQUIRM.updateWarning()
    local now = tick()
    if now >= SQUIRM.warnPollAt then
        SQUIRM.warnPollAt = now + SQUIRM.WARN_POLL
        local on = false

        if SETTINGS.showSquirmWarning then
            if now >= SQUIRM.warnFindAt then
                SQUIRM.warnFindAt = now + SQUIRM.WARN_FIND
                SQUIRM.warnModel = SQUIRM.findModel()
            end

            local model = SQUIRM.warnModel
            if model then
                local okState, state = pcall(function()
                    return model:GetAttribute("SquirmState")
                end)
                state = okState and state or nil

                if state == "ALERT" and SQUIRM.warnState ~= "ALERT" then
                    SQUIRM.alertAt = now
                end
                SQUIRM.warnState = state

                local ok, result = pcall(SQUIRM.isTargetingMe, model)
                on = ok and result == true
            else
                SQUIRM.warnState = nil
            end
        end

        SQUIRM.warnOn = on
    end

    local drawing = SQUIRM.warnDrawing
    if SQUIRM.warnOn then
        local camera = Workspace.CurrentCamera
        if not camera then
            return
        end

        if not drawing then
            drawing = makeDrawing("Text", Color3.fromRGB(255, 255, 255))
            safeSet(drawing, "Center", true)
            safeSet(drawing, "Outline", true)
            safeSet(drawing, "Font", Drawing.Fonts.SystemBold)
            safeSet(drawing, "Size", SQUIRM.WARN_SIZE)
            safeSet(drawing, "FontSize", SQUIRM.WARN_SIZE)
            safeSet(drawing, "Text", SQUIRM.WARN_TEXT)
            SQUIRM.warnShown = SQUIRM.WARN_TEXT
            SQUIRM.warnDrawing = drawing
        end

        local text = SQUIRM.WARN_TEXT
        local remaining = SQUIRM.alertAt + SQUIRM.ALERT_DELAY - now
        if SQUIRM.warnState == "ALERT" and remaining > 0 then
            local tenths = math.ceil(remaining * 10)
            if SQUIRM.warnTenths ~= tenths then
                SQUIRM.warnTenths = tenths
                SQUIRM.warnTimerText = SQUIRM.WARN_TEXT .. " " .. string.format("%.1fs", tenths / 10)
            end
            text = SQUIRM.warnTimerText
        end

        if SQUIRM.warnShown ~= text then
            SQUIRM.warnShown = text
            drawing.Text = text
        end

        local viewport = camera.ViewportSize
        drawing.Position = Vector2.new(viewport.X * 0.5, viewport.Y * 0.3)
        drawing.Visible = true
    elseif drawing then
        drawing.Visible = false
    end
end

local TOON = {KEY = 0x46, POLL = 0.25, RETRY = 10, SECOND_PRESS = 0.4, CONFIRM = 3, nextAt = 0, usedFloor = {}}

TOON.RULES = {
    Vee = {},
    Gourdy = {},
    Tisha = {},
    Connie = {},
    Astro = {},
    Flyte = {},
    Coal = {},
    Toodles = {machine = true},
    Gigi = {offMachine = true, freeSlot = true},
    Flutter = {offMachine = true},
    Cocoa = {offMachine = true},
    Rudie = {offMachine = true},
    Waxwell = {offMachine = true},
    Brightney = {blackout = true},
    Pebble = {offMachine = true, perFloor = true},
    Bobette = {offMachine = true, perFloor = true},
    Blott = {offMachine = true, perFloor = true, tapes = true},
    Teagan = {perFloor = true, tapes = true, hurt = true},
    Bassie = {perFloor = true, presses = 2, instant = true},
}
TOON.RULES.Blot = TOON.RULES.Blott

TOON.UNSUPPORTED = {Shelly = true, Sprout = true, Goob = true, Glisten = true, Cosmo = true, Scraps = true, Brusha = true, Squirm = true, Ginger = true}

FARM.MASTERY.toonRules = TOON.RULES
FARM.MASTERY.toonName = function(char) return TOON.character(char) end

function TOON.character(char)
    local Config = char and char:FindFirstChild("Config")
    local Module = Config and Config:FindFirstChild("ModuleName")
    local name = Module and STRINGS.read(Module)
    return name ~= "" and name or nil
end

function TOON.hasAbility(char, name)
    local ok, Abilities = pcall(function()
        return char:FindFirstChild("Abilities")
    end)
    if ok and Abilities then return Abilities:FindFirstChild("Ability1") ~= nil end
    return name ~= nil and (TOON.RULES[name] ~= nil or TOON.UNSUPPORTED[name] == true)
end

function TOON.describe(name, hasAbility)
    local text = "Character: " .. (name or "none")
    if not name then return text end
    if not hasAbility then return text .. " (no ability)" end
    return text .. (TOON.RULES[name] and " (supported)" or " (not supported)")
end

function TOON.inElevator(char)
    local ok, blocked = pcall(function()
        local Flag = char:FindFirstChild("Stats") and char.Stats:FindFirstChild("InElevator")
        if Flag and Flag.Value == true then return true end
        local Active = Workspace.Info:FindFirstChild("FloorActive")
        if Active and Active.Value ~= true then return true end
        return Workspace.CurrentRoom:FindFirstChildOfClass("Model") == nil
    end)
    return not ok or blocked
end

function TOON.blackout()
    local Info = Workspace:FindFirstChild("Info")
    local Flag = Info and Info:FindFirstChild("BlackOut")
    local ok, value = pcall(function()
        return Flag.Value
    end)
    return ok and value == true
end

function TOON.freeSlot(char)
    for _, slot in ipairs(FARM.runInventory(char)) do
        if slot.item == nil or slot.item == "" or slot.item == "None" then return true end
    end
    return false
end

function TOON.ready(char, Rule)
    if not (char.Parent and char.Parent.Name == "InGamePlayers") then return false end
    if TOON.inElevator(char) then return false end
    local Ability = char.Abilities.Ability1
    local Cost = Ability:FindFirstChild("AbilityCost")
    if Cost and Cost.Value > 0 and not Rule.tapes then return false end
    if Rule.hurt then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not (humanoid and humanoid.Health < humanoid.MaxHealth) then return false end
    end
    if Rule.freeSlot and not TOON.freeSlot(char) then return false end
    return Ability.CurrentCooldown.Value <= 0
end

function TOON.confirm(char, now)
    local Pending = TOON.pending
    if not Pending then return end
    local ok, cooldown = pcall(function()
        return char.Abilities.Ability1.CurrentCooldown.Value
    end)
    if Pending.Instant or (ok and cooldown > 0) then
        TOON.usedFloor[Pending.Name] = Pending.Floor
        TOON.pending = nil
    elseif now - Pending.At > TOON.CONFIRM then
        TOON.pending = nil
    end
end

function TOON.update(now)
    if TOON.secondAt and now >= TOON.secondAt then
        TOON.secondAt = nil
        if not VantaUI.Blocked and robloxFocused() then FARM.tapKey(TOON.KEY) end
    end
    if now < TOON.nextAt then return end
    TOON.nextAt = now + TOON.POLL
    local char = LocalPlayer.Character
    local ok, name = pcall(TOON.character, char)
    name = ok and name or nil
    if name then TOON.lastName = name end
    local hasAbility = TOON.hasAbility(char, name)
    local shown = tostring(name) .. tostring(hasAbility)
    if shown ~= TOON.shown and TOON.Label then
        TOON.shown = shown
        TOON.Label:SetText(TOON.describe(name, hasAbility))
    end
    local Rule = name and TOON.RULES[name]
    local mastery = FARM.MASTERY.abilityMode(name)
    if not ((SETTINGS.autoAbility or mastery) and Rule and FARM.active and not FARM.paused) then return end
    if PLACE_MODE ~= "main" or VantaUI.Blocked or not robloxFocused() then return end
    TOON.confirm(char, now)
    local working = FARM.RUN.phase == "working" and FARM.RUN.current ~= nil
    if Rule.machine and not working then return end
    if Rule.offMachine and working then return end
    local floor = FARM.currentFloor()
    local perFloor = Rule.perFloor and not mastery
    if perFloor and (TOON.usedFloor[name] == floor or TOON.pending) then return end
    if Rule.blackout and not TOON.blackout() then return end
    local okReady, ready = pcall(TOON.ready, char, Rule)
    if not (okReady and ready) then return end
    FARM.tapKey(TOON.KEY)
    if Rule.presses == 2 then TOON.secondAt = now + TOON.SECOND_PRESS end
    if perFloor then TOON.pending = {Name = name, Floor = floor, At = now, Instant = Rule.instant} end
    TOON.nextAt = now + TOON.RETRY
end

local REPORT = {FILE = "DW/session.json", STALE = 1800, BEAT = 15, POLL = 1, WAIT_MAX = 45, queue = {}, queuedAt = 0, COLOR = 3907299, DEATH_COLOR = 16724787, LIMIT_COLOR = 15844367, EMOJI ={Ichor = "<:Ichor:1537419766216794202>", Research = "<:Research:1537425747042639962>", Items = "<:Items:1537454153415008316>", Twisteds = "<:Twisteds:1537144148908314675>", Character = "<:Character:1537200090370805840>", Mastery = "<:Mastery:1537206041085747331>"}, nextAt = 0, beatAt = 0}

function REPORT.clock()
    local ok, value = pcall(os.time)
    return (ok and type(value) == "number") and value or math.floor(tick())
end

function REPORT.fresh(now)
    return {startedAt = now, lastBeat = 0, runs = 0, deaths = 0, ichor = 0, machines = 0, capsules = 0, bestFloor = 0, summaryAt = {}}
end

function REPORT.load()
    local now = REPORT.clock()
    local ok, Data = pcall(function()
        return HttpService:JSONDecode(readfile(REPORT.FILE))
    end)
    local gap = (ok and type(Data) == "table" and type(Data.lastBeat) == "number") and now - Data.lastBeat or nil
    if not gap or gap > REPORT.STALE or gap < 0 then
        REPORT.session = REPORT.fresh(now)
        return nil
    end
    Data.summaryAt = type(Data.summaryAt) == "table" and Data.summaryAt or {}
    REPORT.session = Data
    return gap
end

function REPORT.save()
    local S = REPORT.session
    if not S then return end
    S.lastBeat = REPORT.clock()
    pcall(function()
        if not isfolder("DW") then makefolder("DW") end
        writefile(REPORT.FILE, HttpService:JSONEncode(S))
    end)
end

function REPORT.stats()
    local ok, Stats = pcall(function()
        local Mine = Workspace.Info.PlayerStats[LocalPlayer.Name]
        return {ichor = Mine.Ichor.Value, tapes = Mine.SurvivalPoints.Value, machines = Mine.Generators.Value, capsules = Mine.Capsules.Value, research = Mine.Monsters.Value}
    end)
    return ok and Stats or nil
end

function REPORT.research()
    local ok, Values = pcall(function()
        local Folder = game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Research
        local out = {}
        for _, Value in ipairs(Folder:GetChildren()) do
            out[Value.Name] = Value.Value
        end
        return out
    end)
    return ok and next(Values) and Values or nil
end

function REPORT.number(value)
    local text = tostring(math.floor((value or 0) + 0.5))
    local sign, digits = text:match("^(-?)(%d+)$")
    if not digits then return text end
    return sign .. digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

function REPORT.duration(seconds)
    seconds = math.max(math.floor(seconds or 0), 0)
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end

function REPORT.stamp()
    local ok, text = pcall(os.date, "!%Y-%m-%dT%H:%M:%SZ")
    return ok and type(text) == "string" and text or nil
end

function REPORT.field(name, value, inline)
    return {name = name, value = tostring(value), inline = inline ~= false}
end

function REPORT.totals()
    local S = REPORT.session
    local live = S.runOpen and S.live or {}
    return (S.ichor or 0) + (live.ichor or 0), (S.machines or 0) + (live.machines or 0), (S.capsules or 0) + (live.capsules or 0)
end

function REPORT.researchLines(base)
    local S = REPORT.session
    local now = REPORT.research() or S.lastResearch or {}
    base = base or now
    local lines = {}
    for name, value in pairs(now) do
        local gained = value - (base[name] or 0)
        if gained > 0 then
            local info = MONSTER_INFO[name]
            lines[#lines + 1] = {gained = gained, text = string.format("%s: %d%% (+%d%%)", (info and info.name) or name, value, gained)}
        end
    end
    table.sort(lines, function(a, b) return a.gained > b.gained end)
    local out = {}
    for _, line in ipairs(lines) do
        out[#out + 1] = line.text
    end
    return out
end

function REPORT.masteryLines()
    local okName, current = pcall(TOON.character, LocalPlayer.Character)
    local name = (okName and current) or TOON.lastName
    if not name then return nil, {} end
    local ok, Folder = pcall(function()
        return game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Mastery[name]
    end)
    local lines = {}
    for _, Quest in ipairs(ok and Folder and Folder:GetChildren() or {}) do
        local okValues, current, amount = pcall(function()
            return Quest.Current.Value, Quest.Amount.Value
        end)
        if okValues and type(current) == "number" and type(amount) == "number" then
            local questType = FARM.MASTERY.questType(Quest.Name, "")
            local label = FARM.MASTERY.LABELS[questType]
            local specific = questType == "UseItemSpecific" and FARM.MASTERY.SPECIFIC[name]
            local info = specific and ITEM_INFO[specific]
            if info then label = "Use %s " .. info.name end
            label = label and string.format(label, REPORT.number(amount)) or Quest.Name
            local state = current >= amount and "COMPLETED" or (REPORT.number(math.floor(current)) .. "/" .. REPORT.number(amount))
            lines[#lines + 1] = label .. ": " .. state
        end
    end
    table.sort(lines)
    return name, lines
end

function REPORT.coin()
    local ok, value = pcall(function()
        return game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Coin.Value
    end)
    return (ok and type(value) == "number") and value or nil
end

function REPORT.itemList()
    local char = LocalPlayer.Character
    if not char then return nil end
    local Slots = FARM.runInventory(char)
    if #Slots == 0 then return nil end
    table.sort(Slots, function(a, b) return a.index < b.index end)
    local out = {}
    for _, Slot in ipairs(Slots) do
        local item = Slot.item
        if item == nil or item == "" then item = "None" end
        local info = ITEM_INFO[item]
        out[#out + 1] = "(" .. Slot.index .. ") " .. ((info and info.name) or item)
    end
    return table.concat(out, ", ")
end

function REPORT.twistedNames()
    local map = PLACE_MODE == "main" and FARM.runMap()
    local Monsters = map and map:FindFirstChild("Monsters")
    local names, seen = {}, {}
    for _, Monster in ipairs(Monsters and Monsters:GetChildren() or {}) do
        local info = MONSTER_INFO[Monster.Name]
        local name = info and (info.name:gsub("^Twisted ", "")) or nil
        if name and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end
    return names
end

function REPORT.twistedList()
    local map = PLACE_MODE == "main" and FARM.runMap()
    local Monsters = map and map:FindFirstChild("Monsters")
    if not Monsters then return nil end
    local names, seen = {}, {}
    for _, Monster in ipairs(Monsters:GetChildren()) do
        local info = MONSTER_INFO[Monster.Name]
        local name = info and info.name:gsub("^Twisted ", "") or nil
        if name and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end
    return #names > 0 and table.concat(names, ", ") or "None"
end

function REPORT.summary(Options, heading)
    local S = REPORT.session
    local now = REPORT.clock()
    local Run = (S.runOpen and S.live) or S.lastRun or {}
    local uptime = S.runOpen and (now - (S.runStartedAt or now)) or (S.lastRunTime or 0)
    local floor = PLACE_MODE == "main" and FARM.currentFloor() or 0
    local E = REPORT.EMOJI
    local Fields = {
        REPORT.field("Floor:", floor > 0 and tostring(floor) or "Lobby"),
        REPORT.field("Machines:", REPORT.number(Run.machines) .. " done"),
        REPORT.field("Uptime:", REPORT.duration(uptime)),
    }
    local lines = {}
    if Options.summary.includeIchor then
        local coin = REPORT.coin() or S.lastCoin
        local gained = S.runOpen and coin and (coin - (S.runCoin or coin)) or Run.coinGain
        if coin then
            lines[#lines + 1] = E.Ichor .. " Ichor: " .. REPORT.number(coin) .. " (+" .. REPORT.number(gained or 0) .. ")"
        end
    end
    local character = TOON.character(LocalPlayer.Character)
    if character then
        local okHearts, hearts, maxHearts = pcall(function()
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            return humanoid.Health, humanoid.MaxHealth
        end)
        local health = (okHearts and type(hearts) == "number" and type(maxHearts) == "number" and maxHearts > 0) and (" (" .. math.floor(hearts + 0.5) .. "/" .. math.floor(maxHearts + 0.5) .. " HP)") or ""
        lines[#lines + 1] = E.Character .. " Character: " .. character .. health
    end
    if Options.summary.includeItems then
        local items = REPORT.itemList()
        if items then lines[#lines + 1] = E.Items .. " Items: " .. items end
    end
    if Options.summary.includeTwisteds then
        local twisteds = REPORT.twistedList()
        if twisteds then lines[#lines + 1] = E.Twisteds .. " Twisteds: " .. twisteds end
    end
    if Options.summary.includeResearch then
        local found = REPORT.researchLines(S.runResearch)
        local block = E.Research .. " Research:\n```\n" .. (#found > 0 and table.concat(found, "\n"):sub(1, 900) or "None") .. "\n```"
        table.insert(Fields, REPORT.field("\u{200B}", block, false))
    end
    if Options.summary.includeMastery then
        table.insert(Fields, REPORT.masteryField(E))
    end
    return {embeds = {{title = "Summary (" .. (heading or "Since the beginning") .. ")", color = REPORT.COLOR, description = #lines > 0 and table.concat(lines, "\n") or nil, fields = Fields, footer = {text = "VantaH | Dandy's World"}, timestamp = REPORT.stamp()}}}
end

function REPORT.masteryField(E)
    local name, found = REPORT.masteryLines()
    local block = E.Mastery .. " Mastery" .. (name and (" (" .. name .. ")") or "") .. ":\n```\n" .. (#found > 0 and table.concat(found, "\n"):sub(1, 900) or "None") .. "\n```"
    return REPORT.field("\u{200B}", block, false)
end

function REPORT.runEnded(died, Run, Options)
    local S = REPORT.session
    local limit = S.limitEnd == true
    local Fields = {
        REPORT.field("Final Floor:", Run.floor or "-"),
        REPORT.field("Result:", limit and "Floor limit reached" or (died and "Died" or "Left the run")),
        REPORT.field("Run Time:", REPORT.duration(REPORT.clock() - (S.runStartedAt or REPORT.clock()))),
        REPORT.field("Ichor:", REPORT.number(Run.coinTotal or 0) .. " (+" .. REPORT.number(Run.coinGain or 0) .. ")"),
        REPORT.field("Machines:", REPORT.number(Run.machines) .. " done"),
    }
    local Twisteds = Run.twisteds or {}
    table.insert(Fields, REPORT.field("Twisteds on the floor:", #Twisteds > 0 and table.concat(Twisteds, "\n"):sub(1, 900) or "None"))
    local found = REPORT.researchLines(S.runResearch)
    table.insert(Fields, REPORT.field("Research:", "```\n" .. (#found > 0 and table.concat(found, "\n"):sub(1, 900) or "None") .. "\n```", false))
    if Options and Options.summary.includeMastery then
        table.insert(Fields, REPORT.masteryField(REPORT.EMOJI))
    end
    return {embeds = {{title = "Run Ended", color = (limit and REPORT.LIMIT_COLOR) or (died and REPORT.DEATH_COLOR) or REPORT.COLOR, fields = Fields, footer = {text = "VantaH | Dandy's World"}, timestamp = REPORT.stamp()}}}
end

function REPORT.send(kind, build, died)
    if not (SETTINGS.webhooksEnabled and REPORT.webhooks) then return end
    for _, Hook in pairs(REPORT.webhooks()) do
        local Given = Hook.Options
        local allowed = (kind == "summary" and Given.summary.enabled)
            or (kind == "runEnded" and Given.runEnded.enabled)
            or (kind == "reconnect" and Given.connection.onReconnect)
            or (kind == "lost" and Given.connection.onLost)
        if allowed then
            local body = build(Given)
            if kind == "runEnded" and died and Given.runEnded.mentionOnDeath and Hook.Mention ~= "" then
                body.content = "<@" .. Hook.Mention .. ">"
            end
            task.spawn(function()
                REPORT.post(Hook, body)
            end)
        end
    end
end

function REPORT.finishRun(died)
    local S = REPORT.session
    if not S.runOpen then return end
    local Run = S.live or {}
    Run.coinTotal = S.lastCoin
    Run.coinGain = S.lastCoin and (S.lastCoin - (S.runCoin or S.lastCoin)) or 0
    S.ichor = (S.ichor or 0) + (Run.ichor or 0)
    S.machines = (S.machines or 0) + (Run.machines or 0)
    S.capsules = (S.capsules or 0) + (Run.capsules or 0)
    if died then S.deaths = (S.deaths or 0) + 1 end
    S.runOpen = false
    REPORT.send("runEnded", function(Given)
        return REPORT.runEnded(died, Run, Given)
    end, died)
    S.lastRun = Run
    S.lastRunTime = REPORT.clock() - (S.runStartedAt or REPORT.clock())
    S.live = nil
    S.limitEnd = nil
    REPORT.save()
end

function REPORT.start()
    FARM.onArrive = REPORT.flushQueue
    local gap = REPORT.load()
    local S = REPORT.session
    if PLACE_MODE == "main" then
        if S.job ~= game.JobId then
            if S.runOpen then REPORT.finishRun(false) end
            S.job = game.JobId
            S.runs = (S.runs or 0) + 1
            S.runOpen = true
            S.runStartedAt = REPORT.clock()
            S.lastRun = nil
            S.lastRunTime = nil
            S.runCoin = nil
            S.runResearch = nil
            S.live = {}
        end
    elseif S.runOpen then
        REPORT.finishRun(false)
    end
    if gap and S.lastJob ~= game.JobId then
        local where = PLACE_MODE == "main" and "in Run" or "in Lobby"
        REPORT.pendingReconnect = "Script reconnected (" .. where .. ")"
    end
    S.lastJob = game.JobId
    REPORT.pendingSummary = true
    REPORT.save()
end

function REPORT.enqueue(Hook, body)
    local Queue = REPORT.queue
    Queue[#Queue + 1] = {Hook = Hook, Body = body}
    if REPORT.queuedAt == 0 then
        REPORT.queuedAt = REPORT.clock()
    end
end

function REPORT.flushQueue()
    local Queue = REPORT.queue
    if #Queue == 0 then return end
    REPORT.queue = {}
    REPORT.queuedAt = 0
    for _, Item in ipairs(Queue) do
        REPORT.post(Item.Hook, Item.Body)
    end
end

function REPORT.calm(now)
    if PLACE_MODE ~= "main" or not FARM.active or FARM.paused then
        return true
    end
    if FARM.runSafeInElevator(LocalPlayer.Character) or FARM.RUN.phase == "waitFloor" then
        return true
    end
    return now - REPORT.queuedAt >= REPORT.WAIT_MAX
end

function REPORT.lostPrompt()
    local ok, found = pcall(function()
        local Overlay = game:GetService("CoreGui").RobloxPromptGui.promptOverlay
        return Overlay:FindFirstChild("ErrorPrompt") ~= nil
    end)
    return ok and found == true
end

function REPORT.update(now)
    if now < REPORT.nextAt or not REPORT.session then return end
    REPORT.nextAt = now + REPORT.POLL
    local S = REPORT.session
    if PLACE_MODE == "main" and S.runOpen then
        local Stats = REPORT.stats()
        if Stats then
            S.live = {ichor = Stats.ichor, machines = Stats.machines, capsules = Stats.capsules, research = Stats.research, floor = FARM.currentFloor(), twisteds = REPORT.twistedNames()}
        end
        local floor = FARM.currentFloor()
        if floor > (S.bestFloor or 0) then S.bestFloor = floor end
        if FARM.RUN.phase == "sacrifice" then S.limitEnd = true end
        local coin = REPORT.coin()
        if coin then
            S.lastCoin = coin
            if not S.coin then S.coin = coin end
            if not S.runCoin then S.runCoin = coin end
        end
        local Research = REPORT.research()
        if Research then
            if not S.research then S.research = Research end
            if not S.runResearch then S.runResearch = Research end
            S.lastResearch = Research
        end
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local okHealth, health = pcall(function()
            return humanoid.Health
        end)
        if okHealth and type(health) == "number" and health <= 0 then
            REPORT.finishRun(true)
        end
    end
    if REPORT.pendingReconnect and REPORT.webhooks then
        local text = REPORT.pendingReconnect
        REPORT.pendingReconnect = nil
        REPORT.send("reconnect", function()
            return {content = text}
        end)
    end
    if REPORT.pendingSummary and PLACE_MODE ~= "main" then
        REPORT.pendingSummary = nil
    end
    if REPORT.pendingSummary and PLACE_MODE == "main" and S.runOpen and REPORT.webhooks and SETTINGS.webhooksEnabled then
        REPORT.pendingSummary = nil
        local clock = REPORT.clock()
        for name, Hook in pairs(REPORT.webhooks()) do
            if Hook.Options.summary.enabled then
                S.summaryAt[name] = clock
                REPORT.enqueue(Hook, REPORT.summary(Hook.Options, "Started"))
            end
        end
    end
    if not REPORT.lostSent and REPORT.lostPrompt() then
        REPORT.lostSent = true
        local floor = PLACE_MODE == "main" and FARM.currentFloor() or 0
        REPORT.send("lost", function()
            return {embeds = {{title = "Connection Lost", color = REPORT.DEATH_COLOR, description = floor > 0 and ("Disconnected on Floor " .. floor) or "Disconnected in the lobby", timestamp = REPORT.stamp()}}}
        end)
    end
    local clock = REPORT.clock()
    if REPORT.webhooks and SETTINGS.webhooksEnabled and PLACE_MODE == "main" then
        for name, Hook in pairs(REPORT.webhooks()) do
            local Summary = Hook.Options.summary
            local last = S.summaryAt[name] or S.startedAt
            if Summary.enabled and clock - last >= Summary.intervalMinutes * 60 then
                S.summaryAt[name] = clock
                REPORT.enqueue(Hook, REPORT.summary(Hook.Options))
                REPORT.save()
            end
        end
    end

    if #REPORT.queue > 0 and REPORT.calm(clock) then
        REPORT.flushQueue()
    end
    if now >= REPORT.beatAt then
        REPORT.beatAt = now + REPORT.BEAT
        REPORT.save()
    end
end

local function buildMenu()
    local Options = VantaUI.Options
    local Window = VantaUI:CreateWindow({Title = "VantaH", SubTitle = "Dandy's World", Size = Vector2.new(700, 500), MenuKey = SETTINGS.menuKey})
    UI.Window = Window

    local VisualsTab = Window:AddTab("Visuals")
    local AutomationTab = Window:AddTab("Automation")
    local FarmTab = Window:AddTab("Autofarm")
    local AlertsTab = Window:AddTab("Alerts")
    local WebhookTab = Window:AddTab("Webhook")
    local SettingsTab = Window:AddTab("Settings")

    local function toggle(Section, id, title, key)
        return Section:AddToggle({Id = id, Title = title, Default = SETTINGS[key]})
    end

    local function slider(Section, id, title, key, minimum, maximum, decimals, suffix)
        return Section:AddSlider({Id = id, Title = title, Min = minimum, Max = maximum, Default = SETTINGS[key], Decimals = decimals, Suffix = suffix})
    end

    local function picker(Section, id, title, key)
        return Section:AddColorpicker({Id = id, Title = title, Default = COLORS[key], Callback = function(value)
            COLORS[key] = value
        end})
    end

    local Esp = VisualsTab:AddSection("ESP", "Left")
    toggle(Esp, "dw_visuals_enabled", "Enabled", "enabled")
    Esp:AddKeybind({Id = "dw_esp_key", Title = "Toggle ESP", Default = SETTINGS.espKey, Mode = "Press", Callback = function()
        Options.dw_visuals_enabled:Set(not Options.dw_visuals_enabled.Value)
    end})
    slider(Esp, "dw_visuals_distance", "Max Distance", "maxDistance", 100, 3000, 0, " studs")
    toggle(Esp, "dw_visuals_name", "Names", "showName")
    toggle(Esp, "dw_visuals_range", "Distance", "showDistance")
    toggle(Esp, "dw_visuals_room", "Room", "showRoom")
    toggle(Esp, "dw_visuals_machine_type", "Machine Type", "showMachineType")
    toggle(Esp, "dw_visuals_twisted_rarity", "Twisted Rarity", "showTwistedRarity")
    toggle(Esp, "dw_visuals_item_rarity", "Item Rarity", "showItemRarity")
    toggle(Esp, "dw_visuals_ability_timer", "Twisted Ability Timer", "showAbilityTimer")
    toggle(Esp, "dw_visuals_squirm_warning", "Squirm Attack Warning", "showSquirmWarning")
    toggle(Esp, "dw_visuals_dot", "Dot", "showDot")
    toggle(Esp, "dw_visuals_tracer", "Tracer", "showTracer")

    local Filters = VisualsTab:AddSection("Filters", "Right")
    toggle(Filters, "dw_visuals_monsters", "Monsters", "showMonsters")
    picker(Filters, "dw_visuals_monsters_color", "Monsters Color", "Monsters")
    toggle(Filters, "dw_visuals_items", "Items", "showItems")
    picker(Filters, "dw_visuals_items_color", "Items Color", "Items")
    toggle(Filters, "dw_visuals_research", "Research Capsules", "showResearchCapsules")
    picker(Filters, "dw_visuals_research_color", "Research Capsules Color", "ResearchCapsules")
    toggle(Filters, "dw_visuals_tapes", "Tapes", "showTapes")
    picker(Filters, "dw_visuals_tapes_color", "Tapes Color", "Tapes")
    toggle(Filters, "dw_visuals_generators", "Ichor Extractors", "showGenerators")
    picker(Filters, "dw_visuals_generators_color", "Ichor Extractors Color", "Generators")
    toggle(Filters, "dw_visuals_show_done_generators", "Show Done Extractors", "showCompletedGenerators")
    picker(Filters, "dw_visuals_completed_generator_color", "Done Extractors Color", "CompletedGenerator")
    toggle(Filters, "dw_visuals_inuse_generators", "Highlight In-Use Extractors", "showInUseGenerators")
    picker(Filters, "dw_visuals_inuse_generator_color", "In-Use Extractors Color", "InUseGenerator")

    local PlayersSection = VisualsTab:AddSection("Players", "Left")
    toggle(PlayersSection, "dw_players_health", "Player Health", "showPlayerHealth")
    toggle(PlayersSection, "dw_players_stamina", "Player Stamina", "showPlayerStamina")
    slider(PlayersSection, "dw_players_low_stamina", "Low Stamina Warning", "lowStaminaThreshold", 0, 100, 0)

    local Performance = VisualsTab:AddSection("Performance", "Right")
    slider(Performance, "dw_visuals_max_visible", "Max Visible", "maxVisible", 0, 1000, 0)
    slider(Performance, "dw_visuals_update_rate", "Update Delay", "updateInterval", 0.005, 0.2, 3, "s")
    slider(Performance, "dw_visuals_scan_rate", "Scan Delay", "scanInterval", 0.5, 5, 1, "s")

    local SkillCheck = AutomationTab:AddSection("Skill Check", "Left")
    toggle(SkillCheck, "dw_skillcheck_enabled", "Auto Skill Check", "autoSkillCheck")
    toggle(SkillCheck, "dw_skillcheck_random", "Randomize Press", "skillCheckRandom")
    slider(SkillCheck, "dw_skillcheck_aim", "Aim Point", "skillCheckAim", 0, 100, 0, "%")
    slider(SkillCheck, "dw_skillcheck_lead", "Press Lead", "skillCheckLead", 0, 120, 0, " ms")
    slider(SkillCheck, "dw_skillcheck_treadmill_rate", "Treadmill Tap Rate", "treadmillTapRate", 1, 30, 0, " cps")

    local Barnaby = AutomationTab:AddSection("Barnaby", "Right")
    toggle(Barnaby, "dw_barnaby_enabled", "Auto Barnaby", "autoBarnaby")
    toggle(Barnaby, "dw_barnaby_coins", "Collect Barnaby Coins", "barnabyCollectCoins")
    Barnaby:AddToggle({Id = "dw_barnaby_risky_coins", Title = "Risk for more coins (Not recommended)", Default = SETTINGS.barnabyRiskyCoins, TextColor = Color3.fromRGB(204, 170, 62)})
    Barnaby:AddLabel("Also plays the Swimmy Barnaby arcade in the lobby.")

    local Squirm = AutomationTab:AddSection("Squirm", "Right")
    toggle(Squirm, "dw_squirm_escape", "Auto Squirm Escape", "autoSquirmEscape")
    slider(Squirm, "dw_squirm_tap_rate", "Squirm Tap Rate", "squirmTapRate", 1, 16, 0, " cps")

    local Farm = FarmTab:AddSection("Autofarm", "Left")
    Farm:AddToggle({Id = FARM.TOGGLE_ID, Title = "Aggressive Auto-farm", Default = false, TextColor = Color3.fromRGB(204, 170, 62)})
    slider(Farm, "dw_farm_speed", "Tween Walk Speed", "tweenWalkSpeed", 20, 200, 0, " studs")
    slider(Farm, "dw_farm_floor_limit", "Floor Limit", "floorLimit", 5, 50, 0, " floors")
    toggle(Farm, "dw_farm_unlimited", "Unlimited Floors", "unlimitedFloors")
    toggle(Farm, "dw_farm_auto_resume", "Resume after teleport", "farmAutoResume")
    toggle(Farm, "dw_farm_hide_teleport", "Hide the interface post-teleporting", "farmHideOnTeleport")

    local FarmPlayers = FarmTab:AddSection("Players", "Left")
    FarmPlayers:AddToggle({Id = "dw_farm_with_players", Title = "Allow everyone (Ignore Whitelist)", Default = SETTINGS.allowFarmWithPlayers, TextColor = Color3.fromRGB(214, 84, 72)})

    local whitelistPath = "DW/autofarmWhitelist.json"
    local Whitelist = VantaUI:CreateWindow({Title = "Players Whitelist", SubTitle = "Auto-farm", Size = Vector2.new(560, 380), MinSize = Vector2.new(420, 240), Position = Window.Position + Vector2.new(80, 60), MenuKey = false, Sidebar = false, Visible = false, Layer = 30})
    local WhitelistTab = Whitelist:AddTab("Whitelist")
    local AddPlayer = WhitelistTab:AddSection("Add Player", "Left")
    local Listed = WhitelistTab:AddSection("Whitelisted Players", "Right")
    local Username = AddPlayer:AddTextbox({Title = "Username", Placeholder = "Roblox Username", MaxLength = 20, Filter = "[%w_]"})
    local Names = {}
    local Rows = {}
    local WhitelistStatus

    local function syncWhitelist(save)
        FARM.whitelist = {}
        for _, name in ipairs(Names) do
            FARM.whitelist[string.lower(name)] = true
        end
        if save then pcall(writefile, whitelistPath, #Names == 0 and "[]" or HttpService:JSONEncode(Names)) end
    end

    local function whitelistCount()
        return #Names .. " player" .. (#Names == 1 and "" or "s") .. " whitelisted"
    end

    local function addRow(name)
        Rows[name] = Listed:AddItem({Title = name, Callback = function()
            local index = table.find(Names, name)
            if index then table.remove(Names, index) end
            if Rows[name] then Listed:RemoveElement(Rows[name]) end
            Rows[name] = nil
            syncWhitelist(true)
            WhitelistStatus:SetText(whitelistCount())
        end})
    end

    AddPlayer:AddButton({Title = "Add", Callback = function()
        local name = tostring(Username.Value or ""):match("^%s*(.-)%s*$")
        if #name < 3 or not name:match("^[%w_]+$") then WhitelistStatus:SetText("Type a valid username") return end
        if FARM.whitelist[string.lower(name)] then WhitelistStatus:SetText(name .. " is already whitelisted") return end
        table.insert(Names, name)
        addRow(name)
        syncWhitelist(true)
        Username:Set("")
        WhitelistStatus:SetText(whitelistCount())
    end})
    WhitelistStatus = AddPlayer:AddLabel("")

    pcall(function()
        if not isfile(whitelistPath) then return end
        local Saved = HttpService:JSONDecode(readfile(whitelistPath))
        if type(Saved) ~= "table" then return end
        for _, name in ipairs(Saved) do
            if type(name) == "string" and name:match("^[%w_]+$") and not table.find(Names, name) then
                table.insert(Names, name)
                addRow(name)
            end
        end
    end)
    syncWhitelist(false)
    WhitelistStatus:SetText(whitelistCount())

    FarmPlayers:AddButton({Title = "Players Whitelist", Callback = function()
        Whitelist:SetVisible(true)
    end})

    local FarmAbility = FarmTab:AddSection("Ability", "Left")
    toggle(FarmAbility, "dw_auto_ability", "Auto Use Ability", "autoAbility")
    TOON.Label = FarmAbility:AddLabel("Character: none")

    local MasterySection = FarmTab:AddSection("Mastery", "Right")
    toggle(MasterySection, "dw_mastery_farm", "Mastery farm", "masteryFarm")
    MasterySection:AddParagraph({Title = "", Content = "Farms only mastery, going through every Toon. Farming is slower, but it gets every mastery done."})
    FARM.UNSAFE.label = MasterySection:AddLabel("Unsafe LuaU is required.", Color3.fromRGB(214, 84, 72))
    FARM.UNSAFE.label:SetHidden(true)
    toggle(MasterySection, "dw_mastery_select", "Select Toon without Mastery (Lobby)", "masterySelect")
    toggle(MasterySection, "dw_mastery_end", "End the game after getting Mastery", "masteryEnd")

    local Machines = FarmTab:AddSection("Machines", "Right")
    toggle(Machines, "dw_farm_treadmill_run", "Run on Treadmill Machines", "farmTreadmillRun")
    slider(Machines, "dw_farm_treadmill_stop", "Stop Running at", "farmTreadmillStopAt", 0, 270, 0, " stamina")

    local Collecting = FarmTab:AddSection("Collecting", "Right")
    toggle(Collecting, "dw_farm_heal_items", "Collect & Use healing items", "farmHealItems")
    toggle(Collecting, "dw_farm_extraction_items", "Collect & Use extraction items", "farmExtractionItems")
    toggle(Collecting, "dw_farm_capsules", "Collect Research Capsules", "farmCapsules")

    local FarmTwisteds = FarmTab:AddSection("Twisteds", "Right")
    toggle(FarmTwisteds, "dw_farm_research_twisteds", "Let Twisteds see you first [For Research]", "farmResearchTwisteds")
    toggle(FarmTwisteds, "dw_farm_skip_researched", "Skip Twisteds with 100% Research", "farmSkipResearched")
    toggle(FarmTwisteds, "dw_farm_ignore_twisteds_travel", "Ignore Twisteds while traveling", "farmIgnoreTwistedsTravel")

    local TwistedAlerts = AlertsTab:AddSection("Twisted Alerts", "Left")
    toggle(TwistedAlerts, "dw_alert_tracers", "Use additional tracers", "alertTracers")

    local function alertDropdown(Section, id, title, List, order, groupOf, names)
        local Groups, Chosen, index = {}, {}, {}
        for _, group in ipairs(order) do
            index[group] = {Name = names and names[group] or group, Values = {}}
            table.insert(Groups, index[group])
        end
        for _, Entry in ipairs(List) do
            local Group = index[groupOf(Entry)]
            if Group then table.insert(Group.Values, Entry.label) end
            if SETTINGS[Entry.key] then table.insert(Chosen, Entry.label) end
        end
        return Section:AddDropdown({Id = id, Title = title, Groups = Groups, Default = Chosen, Multi = true})
    end

    alertDropdown(TwistedAlerts, "dw_alert_twisteds", "Alert Twisteds", ALERT_MONSTERS, {"Common", "Uncommon", "Rare", "Main Character", "Lethal"}, function(Entry)
        return Entry.rarity
    end, {["Main Character"] = "Main Characters"})

    local ItemAlerts = AlertsTab:AddSection("Item Alerts", "Right")
    toggle(ItemAlerts, "dw_item_alert_tracers", "Use additional tracers", "itemAlertTracers")
    picker(ItemAlerts, "dw_item_alert_color", "Alert Color", "ItemAlert")
    alertDropdown(ItemAlerts, "dw_alert_items", "Alert Items", ALERT_ITEMS, ITEM_USES, function(Entry)
        return Entry.use
    end)

    local webhookFolder = "DW/Webhooks"
    local webhookDefaults = {
        summary = {enabled = true, intervalMinutes = 20, includeIchor = true, includeResearch = false, includeItems = false, includeTwisteds = false, includeMastery = false},
        runEnded = {enabled = true, mentionOnDeath = false},
        connection = {onReconnect = true, onLost = true},
    }
    local Webhooks = {}

    local function stripComments(text)
        local out = {}
        local index, length = 1, #text
        local quoted = false
        while index <= length do
            local character = text:sub(index, index)
            if quoted then
                out[#out + 1] = character
                if character == "\\" then
                    out[#out + 1] = text:sub(index + 1, index + 1)
                    index += 1
                elseif character == '"' then
                    quoted = false
                end
            elseif character == '"' then
                quoted = true
                out[#out + 1] = character
            elseif text:sub(index, index + 1) == "//" then
                while index <= length and text:sub(index, index) ~= "\n" do index += 1 end
                index -= 1
            else
                out[#out + 1] = character
            end
            index += 1
        end
        return table.concat(out)
    end

    local function normalize(options)
        options = type(options) == "table" and options or {}
        local Result = {}
        for group, Defaults in pairs(webhookDefaults) do
            local Given = type(options[group]) == "table" and options[group] or {}
            Result[group] = {}
            for key, default in pairs(Defaults) do
                local value = Given[key]
                if type(value) ~= type(default) then value = default end
                Result[group][key] = value
            end
        end
        Result.summary.intervalMinutes = math.clamp(math.floor(Result.summary.intervalMinutes + 0.5), 5, 60)
        return Result
    end

    local function quote(text)
        return '"' .. tostring(text):gsub('[\\"]', "\\%0") .. '"'
    end

    local function encodeWebhook(link, mention, Hook)
        local function flag(value) return value and "true" or "false" end
        local Summary, RunEnded, Connection = Hook.summary, Hook.runEnded, Hook.connection
        return table.concat({
            "{",
            '\t"webhookLink": ' .. quote(link) .. ",",
            '\t"mentionUserId": ' .. quote(mention) .. ",",
            '\t"options": {',
            '\t\t"summary": {',
            '\t\t\t"enabled": ' .. flag(Summary.enabled) .. ",",
            '\t\t\t"intervalMinutes": ' .. Summary.intervalMinutes .. ",",
            '\t\t\t"includeIchor": ' .. flag(Summary.includeIchor) .. ",",
            '\t\t\t"includeResearch": ' .. flag(Summary.includeResearch) .. ",",
            '\t\t\t"includeItems": ' .. flag(Summary.includeItems) .. ",",
            '\t\t\t"includeTwisteds": ' .. flag(Summary.includeTwisteds) .. ",",
            '\t\t\t"includeMastery": ' .. flag(Summary.includeMastery),
            "\t\t},",
            '\t\t"runEnded": {',
            '\t\t\t"enabled": ' .. flag(RunEnded.enabled) .. ",",
            '\t\t\t"mentionOnDeath": ' .. flag(RunEnded.mentionOnDeath),
            "\t\t},",
            '\t\t"connection": {',
            '\t\t\t"onReconnect": ' .. flag(Connection.onReconnect) .. ",",
            '\t\t\t"onLost": ' .. flag(Connection.onLost),
            "\t\t}",
            "\t}",
            "}",
            "",
        }, "\n")
    end

    local function readWebhook(name)
        local ok, content = pcall(readfile, webhookFolder .. "/" .. name .. ".json")
        if not ok or type(content) ~= "string" then return nil, "can't read file" end
        local decoded, Data = pcall(function()
            return HttpService:JSONDecode(stripComments(content))
        end)
        if not decoded or type(Data) ~= "table" then return nil, "invalid JSON" end
        local link = type(Data.webhookLink) == "string" and Data.webhookLink:match("^%s*(https://[%w%.]*discord[%w]*%.com/api/webhooks/%d+/[%w_%-]+)%s*$")
        if not link then return nil, "link not filled in" end
        local Given = type(Data.options) == "table" and Data.options or {}
        local mention = tostring(Data.mentionUserId or Given.mentionUserId or ""):match("%d+") or ""
        return {Name = name, Link = link, Mention = mention, Options = normalize(Given)}
    end

    local function saveWebhook(Hook)
        return pcall(writefile, webhookFolder .. "/" .. Hook.Name .. ".json", encodeWebhook(Hook.Link, Hook.Mention, Hook.Options))
    end

    local function scanWebhooks()
        Webhooks = {}
        pcall(function()
            if not isfolder("DW") then makefolder("DW") end
            if not isfolder(webhookFolder) then makefolder(webhookFolder) end
        end)
        local ok, Files = pcall(listfiles, webhookFolder)
        local found = {}
        for _, path in ipairs(ok and Files or {}) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name then found[#found + 1] = name end
        end
        if #found == 0 then
            pcall(writefile, webhookFolder .. "/Example.json", encodeWebhook("", "", normalize({})))
            found = {"Example"}
        end
        table.sort(found)
        local names, problems = {}, {}
        for _, name in ipairs(found) do
            local Hook, problem = readWebhook(name)
            if Hook then
                Webhooks[name] = Hook
                names[#names + 1] = name
            elseif not (name == "Example" and problem == "link not filled in") then
                problems[#problems + 1] = name .. " (" .. problem .. ")"
            end
        end
        return names, problems
    end

    local function postWebhook(Hook, message)
        local body = type(message) == "table" and message or {content = message}
        body.username = "VantaH"
        local json = HttpService:JSONEncode(body):gsub('"color":(%d+)%.0', '"color":%1')
        return pcall(httppost, Hook.Link, json, "application/json")
    end

    REPORT.webhooks = function()
        return Webhooks
    end
    REPORT.post = postWebhook

    local Guide = WebhookTab:AddSection("READ ME", "Full")
    Guide:AddParagraph({Content = table.concat({
        "Your webhooks are located at \"C:\\matcha\\workspace\\DW\\Webhooks\".",
        "",
        "Duplicate the \"Example.json\" file and rename it to something convenient. Open it and paste your webhook URL into \"webhookLink\".",
        "Don't forget to save the file and press \"Refresh\" when you're done. (You can add more than one file.)",
    }, "\n")})

    local Summary = WebhookTab:AddSection("Summary", "Left")
    local Hooks = WebhookTab:AddSection("Webhooks", "Right")
    toggle(Hooks, "dw_webhooks_enabled", "Enable Webhook", "webhooksEnabled")
    local HookPick = Hooks:AddDropdown({Id = "webhook_pick", Title = "Webhook", Values = {}})
    local HookStatus = Hooks:AddLabel("Scanning DW\\Webhooks...")
    local Notifications = WebhookTab:AddSection("Notifications", "Left")

    local Current
    local loading = false
    local saveAt
    local Controls = {}

    local function bind(Element, group, key)
        Controls[#Controls + 1] = {Element = Element, Group = group, Key = key}
        Element:OnChanged(function(value)
            if loading then return end
            if not Current then HookStatus:SetText("Pick a webhook first") return end
            if key then
                Current.Options[group][key] = value
            elseif group == "mentionUserId" then
                Current.Mention = tostring(value):match("%d+") or ""
            end
            saveAt = tick() + 0.5
        end)
        return Element
    end

    bind(Summary:AddToggle({Title = "Enable Summary", Default = true}), "summary", "enabled")
    bind(Summary:AddSlider({Title = "Send a Summary", Min = 5, Max = 60, Default = 20, Suffix = " min"}), "summary", "intervalMinutes")
    bind(Summary:AddToggle({Title = "Include Ichor", Default = true}), "summary", "includeIchor")
    bind(Summary:AddToggle({Title = "Include New Research", Default = false}), "summary", "includeResearch")
    bind(Summary:AddToggle({Title = "Include Mastery", Default = false}), "summary", "includeMastery")
    bind(Summary:AddToggle({Title = "Include Inventory Items", Default = false}), "summary", "includeItems")
    bind(Summary:AddToggle({Title = "Include Twisteds (Current Floor)", Default = false}), "summary", "includeTwisteds")
    Summary:AddLabel("Run info (floor, machines, time) is always included.")

    bind(Notifications:AddToggle({Title = "Enable Run Ended Notifier", Default = true}), "runEnded", "enabled")
    bind(Notifications:AddToggle({Title = "Mention User If Died", Default = false}), "runEnded", "mentionOnDeath")
    bind(Notifications:AddTextbox({Title = "User ID (for mentions)", Placeholder = "Your Discord user ID", Numeric = true, MaxLength = 20}), "mentionUserId")
    bind(Notifications:AddToggle({Title = "Send Upon Reconnection", Default = true}), "connection", "onReconnect")
    bind(Notifications:AddToggle({Title = "Send If Connection Lost", Default = true}), "connection", "onLost")

    local function loadControls()
        Current = Webhooks[HookPick.Value or ""]
        local Given = Current and Current.Options or normalize({})
        loading = true
        for _, Control in ipairs(Controls) do
            local value = Current and Current.Mention or ""
            if Control.Key then value = Given[Control.Group][Control.Key] end
            Control.Element:Set(value)
        end
        loading = false
    end
    HookPick:OnChanged(loadControls)

    local function refreshWebhooks()
        local names, problems = scanWebhooks()
        HookPick:SetValues(names)
        if not Webhooks[HookPick.Value or ""] then HookPick:Set(names[1]) end
        local text = #names == 0 and "No usable webhooks in DW\\Webhooks" or (#names .. " webhook" .. (#names == 1 and "" or "s") .. " ready")
        if #problems > 0 then text ..= " | " .. table.concat(problems, ", ") end
        HookStatus:SetText(text)
        loadControls()
    end

    Hooks:AddButton({Title = "Refresh", Callback = refreshWebhooks})
    Hooks:AddButton({Title = "Send Test", Callback = function()
        if not Current then HookStatus:SetText("Pick a webhook first") return end
        local ok, err = postWebhook(Current, "DW - Test message")
        HookStatus:SetText(ok and ("Test sent to " .. Current.Name) or ("Send failed: " .. tostring(err)))
    end})
    Hooks:AddButton({Title = "Send Summary Now", Callback = function()
        if not Current then HookStatus:SetText("Pick a webhook first") return end
        local built, body = pcall(REPORT.summary, Current.Options)
        if not built then HookStatus:SetText("Summary failed: " .. tostring(body)) return end
        local ok, err = postWebhook(Current, body)
        HookStatus:SetText(ok and ("Summary sent to " .. Current.Name) or ("Send failed: " .. tostring(err)))
    end})
    refreshWebhooks()

    task.spawn(function()
        while not VantaUI.Unloaded do
            if saveAt and tick() >= saveAt and Current then
                saveAt = nil
                local ok = saveWebhook(Current)
                HookStatus:SetText(ok and ("Saved " .. Current.Name .. ".json") or ("Could not save " .. Current.Name .. ".json"))
            end
            task.wait(0.2)
        end
    end)

    local configFolder = "DW/Configs"
    local skipped = {[FARM.TOGGLE_ID] = true, webhook_pick = true, dw_config_name = true, dw_config_pick = true}

    local Config = SettingsTab:AddSection("Config", "Left")
    local ConfigName = Config:AddTextbox({Id = "dw_config_name", Title = "Config Name", Placeholder = "my config", MaxLength = 32})
    local ConfigPick = Config:AddDropdown({Id = "dw_config_pick", Title = "Saved Configs", Values = {}})
    local ConfigStatus = Config:AddLabel("Settings also save automatically.")

    local function listConfigs()
        pcall(function()
            if not isfolder("DW") then makefolder("DW") end
            if not isfolder(configFolder) then makefolder(configFolder) end
        end)
        local ok, Files = pcall(listfiles, configFolder)
        local names = {}
        for _, path in ipairs(ok and Files or {}) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name then names[#names + 1] = name end
        end
        table.sort(names)
        ConfigPick:SetValues(names)
        return names
    end

    local function saveNamed()
        local name = tostring(ConfigName.Value or ""):gsub("[^%w%s%-_]", ""):match("^%s*(.-)%s*$")
        if name == "" then ConfigStatus:SetText("Type a config name first") return end
        local Data = {menuKey = Window.MenuKey}
        for id, Option in pairs(Options) do
            if not skipped[id] and id:sub(1, 3) == "dw_" then
                local value = Option.Value
                if Option.Kind == "Keybind" then
                    Data[id] = {Key = Option.Key}
                elseif Option.Kind == "Colorpicker" then
                    Data[id] = {R = value.R, G = value.G, B = value.B}
                elseif Option.Multi then
                    local Chosen = {}
                    for _, item in ipairs(Option.Values) do
                        if value[item] then table.insert(Chosen, item) end
                    end
                    Data[id] = Chosen
                elseif type(value) == "boolean" or type(value) == "number" or type(value) == "string" then
                    Data[id] = value
                end
            end
        end
        listConfigs()
        local ok = pcall(writefile, configFolder .. "/" .. name .. ".json", HttpService:JSONEncode(Data))
        listConfigs()
        if ok then ConfigPick:Set(name) end
        ConfigStatus:SetText(ok and ("Saved " .. name) or ("Could not save " .. name))
    end

    local function loadNamed()
        local name = ConfigPick.Value
        if not name or name == "" then ConfigStatus:SetText("Pick a saved config first") return end
        local ok, Data = pcall(function()
            return HttpService:JSONDecode(readfile(configFolder .. "/" .. name .. ".json"))
        end)
        if not (ok and type(Data) == "table") then ConfigStatus:SetText("Could not read " .. name) return end
        for id, value in pairs(Data) do
            local Option = Options[id]
            if Option and not skipped[id] then
                if Option.Kind == "Keybind" then
                    if type(value) == "table" and type(value.Key) == "number" then Option:Bind(value.Key) end
                elseif Option.Kind == "Colorpicker" then
                    if type(value) == "table" and type(value.R) == "number" and type(value.G) == "number" and type(value.B) == "number" then
                        Option:Set(Color3.new(value.R, value.G, value.B))
                    end
                elseif type(value) == type(Option.Value) then
                    Option:Set(value)
                end
            end
        end
        if type(Data.menuKey) == "number" then
            Window.MenuKey = Data.menuKey
            Window:Refresh()
        end
        ConfigStatus:SetText("Loaded " .. name)
    end

    Config:AddButton({Title = "Save Config", Callback = saveNamed})
    Config:AddButton({Title = "Load Config", Callback = loadNamed})
    Config:AddButton({Title = "Refresh List", Callback = function()
        local names = listConfigs()
        ConfigStatus:SetText(#names .. " saved config" .. (#names == 1 and "" or "s"))
    end})
    listConfigs()

    local Menu = SettingsTab:AddSection("Menu", "Right")
    Menu:AddButton({Title = "Unload Script", Callback = function()
        if _G.DW_CLEANUP then
            local cleanup = _G.DW_CLEANUP
            _G.DW_CLEANUP = nil
            pcall(cleanup)
        end
    end})
end

buildMenu()
REPORT.start()

SETTINGS.aggressiveAutoFarm = false
FARM.forceOffUntil = tick() + FARM.FORCE_OFF_WINDOW
FARM.resumePending = FARM.consumeResume()
pcall(UI.SetValue, FARM.TOGGLE_ID, false)

local UI_REFRESH_INTERVAL = 0.1
local lastUiRefresh = 0

ABILITY.startIconCache()

local renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
    lastUiRefresh = lastUiRefresh + deltaTime
    if lastUiRefresh >= UI_REFRESH_INTERVAL then
        lastUiRefresh = 0
        refreshSettingsFromUi()
        FARM.updateUnsafeWarning()
        FARM.MASTERY.update()
        FARM.MASTERY.runUpdate()
    end

    lastScan = lastScan + deltaTime
    if lastScan >= SETTINGS.scanInterval then
        lastScan = 0
        scanVisuals()
    end

    if not doAutoSquirmEscape() then
        doAutoSkillCheck()
    end

    drawAll(deltaTime)
    ABILITY.update()
    SQUIRM.updateWarning()
    PLAYERS.update(tick())
    FARM.update(tick())
    TOON.update(tick())
    REPORT.update(tick())
end)

_G.DW_CLEANUP = function()
    if spaceHeldUntil > 0 then
        spaceHeldUntil = 0
        pcall(keyrelease, VK_SPACE)
    end

    if SQUIRM.heldKey then
        pcall(keyrelease, SQUIRM.heldKey)
        SQUIRM.heldKey = nil
    end

    if SQUIRM.warnDrawing then
        pcall(function()
            SQUIRM.warnDrawing:Remove()
        end)
        SQUIRM.warnDrawing = nil
    end

    for key, entry in pairs(ABILITY.entries) do
        ABILITY.removeCard(entry)
        ABILITY.entries[key] = nil
    end

    ABILITY.removePrompt()
    PLAYERS.cleanup()
    FARM.cleanup()

    if renderConnection then
        pcall(function()
            renderConnection:Disconnect()
        end)
        renderConnection = nil
    end

    for key, visual in pairs(tracked) do
        pcall(removeVisual, visual)
        tracked[key] = nil
    end

    clearSkillCheckCache()

    pcall(function()
        VantaUI:Unload()
    end)
end