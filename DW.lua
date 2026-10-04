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
        pcall(notify, "Dandy's World", "Wrong game (universe " .. tostring(game.GameId) .. ") - aborted.", 4)
    end
    return
end

local PLACE_MODE = game.PlaceId == 16552821455 and "main" or game.PlaceId == 16116270224 and "lobby" or "other"

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players and Players.LocalPlayer

local HttpService = game:GetService("HttpService")
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
    CollectablePiece = {name = "Special", rarity = "Common", use = "Collectible", effect = "Event special collectible, collected by walking near it", floor = false, store = false, cost = 0},
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
for index, entry in ipairs(ALERT_ITEMS) do
    if entry.label == "Special" then
        table.insert(ALERT_ITEMS, index + 1, {key = "itemAlertDoors", items = {}, label = "Doors [Halloween]", use = "Collectible"})
        break
    end
end

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
    showSpecial = true,
    showDoors = true,
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
    floorLimit = 15,
    unlimitedFloors = false,
    farmWarningAccepted = false,
    masteryFarm = false,
    masterySelect = true,
    masteryEnd = true,
    farmAutoResume = true,
    farmHideOnTeleport = true,
    farmEventItems = true,
    farmSpecialItems = true,
    farmTrickOrTreat = true,
    farmHealItems = true,
    farmExtractionItems = true,
    farmCapsules = true,
    farmCapsulesResearch = false,
    farmResearchTwisteds = true,
    farmEventTwisteds = false,
    farmAvoidAura = 2.5,
    farmSkipResearched = true,
    farmIgnoreTwistedsTravel = false,
    farmSpeedMultiplier = 1.32,
    farmTreadmillRun = true,
    farmTreadmillStopAt = 30,
    farmMachinePriority = false,
    farmMachineOrder = "Box,Treadmill,Circle,Barnaby",
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
    alwaysGolden = false,
    betterBarnaby = false,
    autoRemap = false,
    autoBarnaby = true,
    barnabyCollectCoins = true,
    barnabyRiskyCoins = false,
    autoSquirmEscape = true,
    autoAbility = true,
    squirmTapRate = 14,
    alertTracers = true,
    disable3d = false,
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
    itemAlertCollectablePiece = true,
    itemAlertDoors = false,
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
    Special = Color3.fromRGB(255, 140, 0),
    Doors = Color3.fromRGB(255, 90, 20),
    Generators = Color3.fromRGB(255, 220, 70),
    CompletedGenerator = Color3.fromRGB(120, 200, 255),
    InUseGenerator = Color3.fromRGB(255, 244, 170),
}

local CONFIG_FOLDER = "DW"
local CONFIG_PATH = "DW/config.json"

local SAVED_KEYS = {}
for key in pairs(SETTINGS) do
    if key ~= "aggressiveAutoFarm" and key ~= "resolveBudget" then table.insert(SAVED_KEYS, key) end
end

local SAVED_COLORS = { "Monsters", "Items", "ItemAlert", "ResearchCapsules", "Tapes", "Special", "Doors", "Generators", "CompletedGenerator", "InUseGenerator" }

local SAVE_DEBOUNCE = 1
local configSnapshot = nil
local configDirtyAt = 0

local FOLDERS = {
    { key = "Monsters", enabledKeys = { "showMonsters" } },
    { key = "Items", enabledKeys = { "showItems", "showResearchCapsules", "showTapes" } },
    { key = "Generators", enabledKeys = { "showGenerators" } },
    { key = "HolidayPickups", enabledKeys = { "showSpecial" } },
    { key = "TrickOrTreatDoors", enabledKeys = { "showDoors" } },
}

FOLDERS.BLOT_ZONE_PREFIX = "BlotHandZone_"
FOLDERS.BLOT_ZONE_MAX = 10
FOLDERS.BLOT_HAND_PREFIX = "BlotHand"

local CATEGORY_ENABLED = {
    Monsters = "showMonsters",
    Items = "showItems",
    ResearchCapsules = "showResearchCapsules",
    Tapes = "showTapes",
    Special = "showSpecial",
    Doors = "showDoors",
    Generators = "showGenerators",
}

local ALERT_DURATION = 5

local DOOR_INFO = setmetatable({name = "Trick or Treat Door"}, {__index = function(Info) return Info end})

local alertSeen = {}

local ITEM_CATEGORIES = {
    ResearchCapsule = "ResearchCapsules",
    Tape = "Tapes",
    FakeCapsule = false,
}


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
    "Door",
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

local SKILL = {
    RANDOM_MIN = 0.35,
    RANDOM_MAX = 0.65,
    CHECK_GAP = 0.35,
    MOTION_GRACE = 0.25,
    BAR_MAX_SPEED = 3000,
    CIRCLE_MAX_RATE = 20000,
    CIRCLE_FALLBACK_BAND = 12,
    Bar = {Reverses = true, Rate = 0, Aim = 0, Pressed = false, Frame = 0.005},
    Circle = {Rate = 0, Aim = 0, Pressed = false, Frame = 0.005},
    VK_SPACE = 0x20,
    SPACE_HOLD = 0.05,
    SPACE_MIN_HOLD = 0.015,
    PRESS_COOLDOWN = 0.25,
    FIND_INTERVAL = 0.35,
    lastPress = 0,
    lastTap = 0,
    parts = nil,
    lastFind = 0,
    MARKER_NAMES = {
        Marker = true,
        Needle = true,
        Cursor = true,
        Pointer = true,
        Line = true,
        ShrinkingCircle = true,
    },
    GOLD_NAMES = {
        GoldArea = true,
        PerfectArea = true,
        YellowCircle = true,
    },
    GREY_NAMES = {
        GreyCircle = true,
        GrayCircle = true,
    },
    HOLE_NAMES = {
        CenterHole = true,
        BlackCircle = true,
        Center = true,
    },
    REQUIRED_NAMES = {
        RequiredArea = true,
        SuccessArea = true,
        SafeArea = true,
        HitArea = true,
        GoodArea = true,
        Goal = true,
        Zone = true,
    },
}

local GOLDEN = {PressDelay = 0.65, Ready = false, CircleReady = false, TreadReady = false, Busy = false, Slots = {}, NextScan = 0, NextCheck = 0, Sweep = 2, Attempts = 0, MaxAttempts = 3, RetryDelay = 30}
GOLDEN.Offsets = {Tag = 1, Nups = 4, ValueTag = 12, StringTag = 6, FunctionTag = 8, NumberTag = 3, ProtoTag = 15, StringLength = 20, StringText = 24, Upvalues = 0x20, Upvalue = 0x70, Proto = 0x18, Code = 0x50, CodeSize = 0xAC, Constants = 0x48, ConstantCount = 0xA4, Children = 0x28, ChildCount = 0xA0, TweenList = 0xE0, TweenTime = 0xB8, TweenElapsed = 0x124, TweenTarget = 0xE0}
GOLDEN.Offsets.Encoding = {Proto = 0, Code = 0, Constants = 0, Children = 0}
GOLDEN.Map = {File = CONFIG_FOLDER .. "/Offsets.json", Loaded = false, Luau = false, Tween = false, Tries = 0, Waits = 0, NextTry = nil, TweenNext = 0, TweenBusy = false, StatusAt = 0}

local KEYS = {Held = {}, Timed = {}}

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
    track = { y = nil, v = 0, t = 0 },
    lastDecision = 0,
    lastPress = 0,
    obstacleSignature = nil,
    lastMotion = 0,
    focusWarned = false,
}
BARNABY.LATENCY_NOMINAL = (BARNABY.LATENCY_MIN + BARNABY.LATENCY_MAX) * 0.5
BARNABY.sortByX = function(a, b)
    return a.x < b.x
end

local SWIMMER = {Ready = false, Busy = false, Patches = {}, NextScan = 0, Attempts = 0}

local SQUIRM = {
    VK_LEFT = 0x41,
    VK_RIGHT = 0x44,
    HOLD = 0.02,
    MIN_GAP = 0.06,
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
        GigiMonster = 131330279221224,
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

local NO_RARITY_CATEGORIES = { Tapes = true, Special = true, Doors = true }

local COMPLETION_TTL = 0.5

local STRINGS = {
    OFFSET = 0xA8,
}

local NAME_RETRY_INTERVAL = 5

local MACHINE_TYPE_LABELS = {
    Original = "Bar",
    Circle = "Circle",
    Treadmill = "Treadmill",
    TreadmillTap = "Treadmill",
    MovementTreadmill = "Treadmill",
}

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

local FARM = {
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
    SpeedMeter = {Every = 0.25, At = 0, Value = 0},
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
    Debug = {Enabled = _G.DW_DEBUG == true or (type(isfile) == "function" and select(2, pcall(isfile, "DW/Debug.txt")) == true), File = "DW/FarmDebug.txt", Slow = 0.04, Phase = nil, Status = nil, Gap = 0.5, Section = 0.05},
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
        FREEZE_EVERY = 0.1,
        ATTR_EVERY = 1 / 30,
        RAY_DOWN = 50,
        RAY_HOPS = 6,
        rayWorks = false,
        rayCheckAt = 0,
        CHASER_DEFAULTS = { InstantRadius = 30, VisionRadius = 70, LineOfSight = 0.4 },
        SprintDefault = 25,
        SprintMultiplier = 1.32,
        SprintMultiplierMax = 1.42,
        SprintSpeed = 25,
        SprintReadEvery = 0.25,
        SprintReadAt = 0,
        DangerTwisted = {GoobMonster = true, ScrapsMonster = true},
        SpeedTrim = 0.85,
        TrimMin = 0.4,
        TrimMax = 1.3,
        TrimPhases = {tween = true, toElevator = true, research = true},
        AvoidMargin = 2.5,
        AvoidRange = 6,
        SteerLook = 10,
        ItemGuard = 12,
        SteerPush = 1.5,
        SteerDrift = 0.35,
        CollectDodge = 5,
        FrameTime = 0.016,
        CoverSkip = {Generators = true, Monsters = true, Items = true, Waypoints = true, TriggerZones = true, SpawnPoints = true, MonsterSpawnPoints = true, GeneratorSpawnPoints = true, ItemSpawnPoints = true, GeneratorSpawnPointsCache = true, HolidayPickups = true, Puddles = true, Sounds = true, TrickOrTreatDoors = true},
        CoverBatch = 150,
        CoverMargin = 1.05,
        CoverReach = 60,
        CoverNear = 4,
        CoverSafePass = 10,
        CoverGround = 2,
        CoverChecks = 6,
        CoverRescan = 0.3,
        CoverArrive = 0.6,
        CoverExit = 1.8,
        CoverAt = 0,
        CoverCell = 16,
        CoverStep = 0.3,
        CoverProbe = 6,
        CoverDirections = 16,
        CoverLevelBudget = 0.006,
        CoverPreloadBudget = 0.03,
        CoverLevelTolerance = 1,
        CoverMinParts = 20,
        CoverUpright = 0.97,
        CoverSkipNames = {CylinderCollider = true, WallFiller = true},
        HideMin = 0.55,
        HideHeights = {-1, 0, 0.3},
        HideFamily = 60,
        HideClasses = {Part = true, MeshPart = true, UnionOperation = true},
        ZoneRects = 24,
        ZoneSlack = 0.3,
        EscapeToward = 1,
        EscapeGain = 2,
        EscapeProgress = 0.5,
        HideToward = 0.3,
        CoverRootOffset = 2.85,
        CoverFloorRange = 6,
        ShapeOffset = 0x1A8,
        TransparencyOffset = 0x120,
        InvisibleNames = {NoClip = true, NoClip_Collider = true, Collider = true, HumanoidRootPart = true, RootPart = true},
        ShapeBlock = 1,
        ShapeCylinder = 2,
        ExposedWait = 8,
        WatcherEvery = 0.25,
        PanicGrace = 5,
        PanicGraceUntil = 0,
        ExitProbe = 1.5,
        CoverRetryEvery = 2,
        CoverSettleChecks = 2,
        CoverSettleEvery = 1,
        CoverWatchEvery = 3,
        CoverWatchTime = 90,
        CoverGrowth = 40,
        KillRadius = {BassieMonster = 4, BlottMonster = 4, BobetteMonster = 4, GourdyMonster = 4, ShellyMonster = 4, SproutMonster = 4, VeeMonster = 4, GoobMonster = 3.5, ScrapsMonster = 3.5, GigiMonster = 5, PebbleMonster = 6.5, DandyMonster = 8.5, DyleMonster = 8.5, SquirmMonster = 5},
        KillDefault = 3.33,
        CoverDepth = 1.5,
        CampTime = 4,
        GourdyWait = 20,
        GourdyCheckEvery = 0.5,
        CampClose = 8,
        BlockBuffer = 2,
        SightLift = 2,
        EscapeEvery = 1,
        EscapeAt = 0,
        EscapeBuffer = 10,
        GuardBuffer = 6,
        GuardWait = 20,
        SneakEvery = 0.5,
        CovertStep = 3,
        CovertRange = 90,
        SneakAt = 0,
        SneakBuffer = 4,
        CoverBuildPhases = {working = true, aim = true, pick = true, collect = true},
        HopReach = 30,
        HopGain = 6,
        HopDirect = 15,
        HIDE_MAX = 30,
        GAIN = 5.5,
        MAX_STEP = 40,
        TOL = 6,
        AIM_MAX = 2.5,
        SACRIFICE_TOUCH = 5,
        WANT_ITEMS = { Bandage = "farmHealItems", HealthKit = "farmHealItems", JumperCable = "farmExtractionItems" },
        SpecialMaxed = {"HalloweenCollectionMaxed", "ChristmasCollectionMaxed", "EasterCollectionMaxed"},
        SpecialMaxedEvery = 2,
        SpecialHold = 0.6,
        ApproachGap = 3,
        SpecialName = "Special Collectible",
        QuestFolders = {"UniqueLights", "FreeArea", "Ignore", "LoreRoom"},
        QuestSkip = {"Typewriter", "TV"},
        QuestBatch = 10,
        QuestEvery = 1,
        QuestRecheck = 2,
        QuestName = "Gourdy quest prop",
        DoorName = "Trick or Treat Door",
        TravelPhases = {pick = true, tween = true, collect = true},
        MachineCover = 20,
        DoorHold = 1,
        HEAL_ORDER = { "HealthKit", "Bandage" },
        HEAL_AT = 1,
        KEEP_ITEMS = { bandage = true, healthkit = true, jumpercable = true, valve = true, tape = true, instructions = true, extractionspeedcandy = true, bonbon = true, stopwatch = true, skillcheckcandy = true },
        MACHINE_ORDER = { "Instructions", "ExtractionSpeedCandy", "BonBon", "Stopwatch", "SkillCheckCandy" },
        STAMINA_ITEMS = { pop = true, popbottle = true },
        STAMINA_RAZZLE_RANGE = 60,
        staminaSprint = false,
        SPRINT_OFF_EVERY = 0.8,
        SHIFT_HOLD = 0.1,
        sprintOffAt = 0,
        CABLE_MAX_FILL = 0.67,
        USE_COOLDOWN = 1.5,
        KEY_HOLD = 0.12,
        itemKey = nil,
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
        BLOT_HAND_MARGIN = 4,
        BLOT_HAND_RECHECK = 0.25,
        SPROUT_RANGE = 18,
        RODGER_ACTIVE_RANGE = 34,
        RODGER_RISE = 3,
        SPROUT_FLEE_MARGIN = 4,
        RollMargin = 8,
        SPROUT_RECHECK = 0.2,
        sproutAt = 0,
        sprouts = {},
        FLOOR_UP = 8,
        FLOOR_DOWN = 40,
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
        capsuleNames = {},
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
        hideUntil = 0,
        leaveAt = 0,
        rmbDown = false,
        W_KEY = 0x57,
        noCollide = false,
        deathClick = {stage = 0, at = 0},
        readyClick = {stage = 0, at = 0},
        voteClick = {stage = 0, at = 0},
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
        leaveClick = {stage = 0, at = 0},
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
FARM.CURSOR = {Map = nil, At = -math.huge, Viewport = nil, Busy = false, Failures = 0, RetryAt = 0, GuiScale = nil}

FARM.UNSAFE = { interval = 3, checkedAt = -math.huge, probing = false, enabled = false }

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
    running = false,
    done = false,
    stop = false,
}

FARM.MASTERY.AUTO = {}
FARM.MASTERY.LABELS = {}
for _, quest in ipairs(FARM.MASTERY.QUESTS) do
    FARM.MASTERY.AUTO[quest[1]] = quest[2]
    FARM.MASTERY.LABELS[quest[1]] = quest[4]
end

FARM.TREADMILL_RECOVER = 30
FARM.MachineOrder = {"Box", "Treadmill", "Circle", "Barnaby"}
FARM.MachineKinds = {Original = "Box", Circle = "Circle", Treadmill = "Treadmill", TreadmillTap = "Treadmill", MovementTreadmill = "Treadmill", Barnaby = "Barnaby"}

FARM.TWISTED = {}
FARM.TWISTED_PRUNE = 0
FARM.RESEARCH = {}

FARM.whitelist = {}

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

local REPORT = {FILE = "DW/session.json", STALE = 1800, BEAT = 15, POLL = 1, WAIT_MAX = 45, queue = {}, queuedAt = 0, COLOR = 3907299, DEATH_COLOR = 16724787, LIMIT_COLOR = 15844367, EMOJI ={Ichor = "<:Ichor:1537419766216794202>", Research = "<:Research:1537425747042639962>", Items = "<:Items:1537454153415008316>", Twisteds = "<:Twisteds:1537144148908314675>", Character = "<:Character:1537200090370805840>", Mastery = "<:Mastery:1537206041085747331>"}, nextAt = 0, beatAt = 0}

local RENDER = {Offset = 0x190, CheckOffset = 0x1D8, Applied = false, Wanted = false, NextAt = 0}
RENDER.Clear = {Global = 0x858D208, VisualEngine = 0x6D58DD0, Holder = 0xBC0, Color = 0x1A4, Saved = nil}

local UI_REFRESH_INTERVAL = 0.1
local lastUiRefresh = 0

local UI = {
    Frame = 0,
    Found = {},
    Roster = {At = 0, Names = {}, Models = {}},
    MapAt = 0,
    PlayerMapAt = 0,
    PlayerMissAt = 0,
    SkillIdleAt = 0,
    SkillBusy = false,
    InfoCache = {},
    Binds = {},
    GetValue = function(id)
        local Option = VantaUI.Options[id]
        return Option and Option.Value
    end,
    SetValue = function(id, value)
        local Option = VantaUI.Options[id]
        if Option then Option:Set(value) end
    end,
}

UI.ValueKinds = {BoolValue = "byte", IntValue = "int64", NumberValue = "double"}

function UI.read(holder)
    if not holder then return nil end
    local Kind = UI.ValueKinds[holder.ClassName]
    if Kind and VantaUI.MemoryAccess() then
        local ok, value = pcall(memory_read, Kind, tonumber(holder.Address) + 0xA8)
        if ok and type(value) == "number" then
            if Kind == "byte" then return value ~= 0 end
            return value
        end
    end
    return holder.Value
end

function UI.bool(holder)
    if not holder then return nil end
    if VantaUI.MemoryAccess() then
        local ok, value = pcall(memory_read, "byte", tonumber(holder.Address) + 0xA8)
        if ok and (value == 0 or value == 1) then return value == 1 end
    end
    local ok, value = pcall(function() return holder.Value end)
    if ok and type(value) == "boolean" then return value end
    return nil
end

UI.StatNames = {StopInteracting = true, RewardAmount = true, CurrentAmount = true, RequiredAmount = true, ForceStop = true, SkillCheck = true, ActivePlayer = true, ActivePlayer2 = true, Connie = true}

function UI.completed(stats)
    if not stats then return nil end
    local found = stats:FindFirstChild("Completed")
    if found then return found end
    local pick
    for _, child in ipairs(stats:GetChildren()) do
        if not UI.StatNames[child.Name] then
            if pick then return nil end
            pick = child
        end
    end
    return pick
end

function UI.fill(current, required)
    return type(current) == "number" and type(required) == "number" and required >= 1 and required < 1e6 and current >= 0 and current <= required * 2
end


function UI.find(key, resolve)
    local Found = UI.Found[key]
    if Found and Found.Parent then return Found end
    Found = resolve()
    UI.Found[key] = Found
    return Found
end

function UI.info()
    return UI.find("Info", function() return Workspace:FindFirstChild("Info") end)
end

function UI.infoValue(name, ttl)
    local now = tick()
    local Cache = UI.InfoCache[name]
    if Cache and now < Cache.At then return Cache.Value end
    local info = UI.info()
    local holder = info and UI.find("Info." .. name, function() return info:FindFirstChild(name) end)
    local ok, value = pcall(UI.read, holder)
    value = ok and value or nil
    UI.InfoCache[name] = {At = now + ttl, Value = value}
    return value
end

function UI.folder(path)
    pcall(function()
        local current = nil
        for part in path:gmatch("[^/]+") do
            current = current and (current .. "/" .. part) or part
            if not isfolder(current) then makefolder(current) end
        end
    end)
end

function UI.clock()
    local ok, value = pcall(os.time)
    return (ok and type(value) == "number") and value or math.floor(tick())
end

function UI.elevators()
    return UI.find("Elevators", function() return Workspace:FindFirstChild("Elevators") end)
end

function UI.playerGui()
    return UI.find("PlayerGui", function() return LocalPlayer:FindFirstChild("PlayerGui") end)
end

function UI.map()
    local now = tick()
    local Map = UI.MapNow
    if Map and now < UI.MapAt and Map.Parent then return Map end
    local room = Workspace:FindFirstChild("CurrentRoom")
    UI.MapNow = room and room:GetChildren()[1]
    UI.MapAt = now + 0.5
    return UI.MapNow
end

UI.Sprout = {At = 0, Key = nil, Area = nil, Count = 0, List = {}}

function UI.sproutTendrils(map)
    local S = UI.Sprout
    local now = tick()
    local key = map and tostring(map.Address)
    if key == S.Key and now < S.At then return S.List end
    S.At = now + 0.2
    if key ~= S.Key then
        S.Key, S.Area, S.Count, S.List = key, map and map:FindFirstChild("FreeArea"), 0, {}
    end
    local Alive = {}
    local Known = {}
    for _, Tendril in ipairs(S.List) do
        if Tendril.Parent then
            Alive[#Alive + 1] = Tendril
            Known[tostring(Tendril.Address)] = true
        end
    end
    local function take(Child)
        if Child and Child.Name == "SproutTendril" and not Known[tostring(Child.Address)] then
            Known[tostring(Child.Address)] = true
            Alive[#Alive + 1] = Child
        end
    end
    if S.Area then
        local Kids = S.Area:GetChildren()
        local count = #Kids
        local from = count > S.Count and S.Count + 1 or math.max(count - 1, 1)
        for index = from, count do take(Kids[index]) end
        S.Count = count
    end
    take(map and map:FindFirstChild("SproutTendril"))
    S.List = Alive
    return Alive
end

function UI.roster()
    local Roster = UI.Roster
    local now = tick()
    if now < Roster.At then return Roster end
    Roster.At = now + 0.5
    local map = UI.map()
    local folder = map and map:FindFirstChild("Monsters")
    Roster.Models = folder and folder:GetChildren() or {}
    Roster.Names = {}
    for _, Model in ipairs(Roster.Models) do Roster.Names[Model.Name] = true end
    return Roster
end

function UI.me()
    local char = LocalPlayer.Character
    if not char then
        UI.Me = nil
        return nil
    end
    local address = char.Address
    if not (UI.Me and UI.Me.Address == address) then UI.Me = {Address = address, Char = char, Parts = {}, Stats = {}} end
    return UI.Me
end

function UI.myPart(name)
    local Me = UI.me()
    if not Me then return nil end
    local Part = Me.Parts[name]
    if Part and Part.Parent then return Part end
    Part = Me.Char:FindFirstChild(name)
    Me.Parts[name] = Part
    return Part
end

function UI.myStat(name)
    local Me = UI.me()
    local Stats = Me and UI.myPart("Stats")
    if not Stats then return nil end
    local Stat = Me.Stats[name]
    if Stat and Stat.Parent then return Stat end
    Stat = Stats:FindFirstChild(name)
    Me.Stats[name] = Stat
    return Stat
end

function UI.playerAt(address)
    local now = tick()
    local Map = UI.PlayerMap
    if not Map or now >= UI.PlayerMapAt or (Map[address] == nil and now >= UI.PlayerMissAt) then
        Map = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            local char = plr.Character
            if char then Map[tonumber(char.Address)] = plr.Name end
        end
        UI.PlayerMap = Map
        UI.PlayerMapAt = now + 1
        UI.PlayerMissAt = now + 0.25
    end
    return Map[address]
end

function UI.valuePlayer(holder)
    if not holder then return nil end
    local ok, target = false, nil
    if VantaUI.MemoryAccess() then ok, target = pcall(memory_read, "uintptr_t", tonumber(holder.Address) + 0xA8) end
    if ok and type(target) == "number" then
        if target <= 4096 then return nil end
        return UI.playerAt(target)
    end
    local okValue, Value = pcall(function() return holder.Value end)
    if not (okValue and Value and Value.ClassName == "Model") then return nil end
    local address = tonumber(Value.Address)
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char and (tonumber(char.Address) == address or char.Name == Value.Name) then return plr.Name end
    end
    return nil
end

function UI.dialog(title, subtitle, heading, size, onClose)
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local position = Vector2.new(math.floor(viewport.X / 2 - size.X / 2), math.floor(viewport.Y / 2 - size.Y / 2))
    local Dialog = VantaUI:CreateWindow({Title = title, SubTitle = subtitle, Size = size, Position = position, MenuKey = false, Sidebar = false, StayOpen = true, Resizable = false, Layer = 40, OnClose = onClose})
    return Dialog, Dialog:AddTab(title):AddSection(heading, "Full")
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

function KEYS.allowed()
    return robloxFocused() and not VantaUI.Blocked and not gameTyping()
end

function KEYS.set(code, down)
    local Held = KEYS.Held
    if down then
        if Held[code] then return true end
        if not KEYS.allowed() then return false end
        Held[code] = true
        pcall(keypress, code)
        return true
    end
    KEYS.Timed[code] = nil
    if Held[code] then
        Held[code] = nil
        pcall(keyrelease, code)
    end
    return false
end

function KEYS.tap(code)
    if not KEYS.allowed() then return false end
    pcall(keypress, code)
    pcall(keyrelease, code)
    return true
end

function KEYS.hold(code, seconds)
    KEYS.set(code, false)
    if not KEYS.set(code, true) then return false end
    KEYS.Timed[code] = tick() + seconds
    return true
end

function KEYS.update(now)
    for code, at in pairs(KEYS.Timed) do
        if now >= at then KEYS.set(code, false) end
    end
end

function KEYS.releaseAll()
    for code in pairs(KEYS.Held) do KEYS.set(code, false) end
end

function KEYS.mouse(action, ...)
    if not (robloxFocused() and not VantaUI.Blocked) then return false end
    pcall(action, ...)
    return true
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

local function makeDrawing(kind, color)
    local object = Drawing.new(kind)
    safeSet(object, "Color", color)
    safeSet(object, "Visible", false)
    safeSet(object, "ZIndex", 50)
    return object
end

local function makeText(size, color, center)
    local text = makeDrawing("Text", color or Color3.fromRGB(255, 255, 255))
    if center ~= false then safeSet(text, "Center", true) end
    safeSet(text, "Outline", true)
    safeSet(text, "Font", Drawing.Fonts.SystemBold)
    safeSet(text, "Size", size)
    safeSet(text, "FontSize", size)
    return text
end

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

function STRINGS.memory(address)
    local ok, text = pcall(function()
        if memory_read("int", address + 24) > 15 then
            return memory_read("string", memory_read("uintptr_t", address))
        end
        return memory_read("string", address)
    end)
    return ok and type(text) == "string" and text or nil
end

function STRINGS.read(instance)
    if not instance then
        return ""
    end

    if VantaUI.MemoryAccess() then
        local ok, address = pcall(function()
            return tonumber(instance.Address)
        end)
        local text = ok and address and address > 4096 and STRINGS.clean(STRINGS.memory(address + STRINGS.OFFSET))
        if text then
            return text
        end
    end

    local ok, value = pcall(function()
        return instance.Value
    end)
    return (ok and type(value) == "string") and value or ""
end

local function saveConfig()
    if type(writefile) ~= "function" then
        return
    end

    UI.folder(CONFIG_FOLDER)
    pcall(function()
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

local function alertKeyFor(category, name)
    if category == "Monsters" then
        return ALERT_BY_MONSTER[name], "twisted"
    end

    if category == "Doors" then
        return "itemAlertDoors", "item"
    end

    if category == "Items" or category == "Tapes" or category == "Special" then
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

local function anyEnabled(keys)
    for _, key in ipairs(keys) do
        if SETTINGS[key] then
            return true
        end
    end

    return false
end

local function hasScreenRect(instance)
    if not instance then
        return false
    end

    local ok, hasRect = pcall(function()
        return instance.AbsolutePosition ~= nil
    end)
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

    local marker = findNamedScreenObject(frame, SKILL.MARKER_NAMES)
    local gold = findNamedScreenObject(frame, SKILL.GOLD_NAMES)
    local required = findNamedScreenObject(frame, SKILL.REQUIRED_NAMES)

    if not marker or not (gold or required) then
        return nil
    end

    return {
        frame = frame,
        marker = marker,
        gold = gold or required,
        required = required,
        grey = findNamedScreenObject(frame, SKILL.GREY_NAMES),
        hole = findNamedScreenObject(frame, SKILL.HOLE_NAMES),
        circle = marker.Name == "ShrinkingCircle" or (gold and gold.Name == "YellowCircle"),
    }
end

local function rollAimFraction()
    if SETTINGS.skillCheckRandom then
        return SKILL.RANDOM_MIN + math.random() * (SKILL.RANDOM_MAX - SKILL.RANDOM_MIN)
    end

    return math.clamp(SETTINGS.skillCheckAim or 15, 0, 100) / 100
end

function SKILL.track(S, value)
    local now = tick()

    if S.Last == nil then
        S.Last, S.LastTime, S.LastMove = value, now, 0
        return false
    end

    local delta = value - S.Last

    if math.abs(delta) > 0.5 then
        local frame = now - S.LastTime

        if now - S.LastMove > SKILL.CHECK_GAP then
            S.Pressed = false
            S.Rate = 0
            S.Aim = rollAimFraction()
            S.StartValue, S.StartTime = value, now
        else
            if S.Reverses and S.Rate ~= 0 and (delta > 0) ~= (S.Rate > 0) then
                S.StartValue, S.StartTime = S.Last, S.LastTime
            end

            local elapsed = now - S.StartTime
            if elapsed >= 0.03 then
                S.Rate = (value - S.StartValue) / elapsed
            elseif frame > 0 then
                S.Rate = delta / frame
            end

            if frame > 0 then
                S.Frame = frame
            end
        end

        S.LastMove = now
        S.Last, S.LastTime = value, now
    end

    return now - S.LastMove <= SKILL.MOTION_GRACE
end

local function sampleBar(marker)
    local pos = marker.AbsolutePosition
    if not pos then
        return false
    end

    return SKILL.track(SKILL.Bar, pos.X)
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

    return SKILL.track(SKILL.Circle, value), SKILL.Circle.Frame
end

local function shouldPressCircle(parts, lead)
    local marker, yellow = parts.marker, parts.gold
    local moving, dt = sampleCircle(marker)

    local Circle = SKILL.Circle
    if Circle.Pressed or not moving then
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
        yellowInner = math.max(0, yellowOuter - SKILL.CIRCLE_FALLBACK_BAND)
    end

    local rate = math.clamp(Circle.Rate, -SKILL.CIRCLE_MAX_RATE, SKILL.CIRCLE_MAX_RATE)
    local predicted = markerSize + rate * (lead / 1000)
    local aim = yellowOuter - Circle.Aim * (yellowOuter - yellowInner)
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
        Circle.Pressed = true
    end

    return press
end

function GOLDEN.heap(pointer)
    return pointer ~= nil and pointer > 0x10000 and pointer < 0x7FF000000000
end

function GOLDEN.pointer(address, mode)
    if not mode or mode == 0 then return memory_read("uintptr_t", address) end
    local low, high = memory_read("int", address) % 4294967296, memory_read("int", address + 4) % 4294967296
    local addressLow, addressHigh = address % 4294967296, math.floor(address / 4294967296)
    if mode == 1 then
        low, high = low + addressLow, high + addressHigh
    elseif mode == 2 then
        low, high = low - addressLow, high - addressHigh
    else
        low, high = addressLow - low, addressHigh - high
    end
    if low >= 4294967296 then
        low, high = low - 4294967296, high + 1
    elseif low < 0 then
        low, high = low + 4294967296, high - 1
    end
    return (high % 4294967296) * 4294967296 + low
end

function GOLDEN.read(object, field)
    return GOLDEN.pointer(object + GOLDEN.Offsets[field], GOLDEN.Offsets.Encoding[field])
end

function GOLDEN.text(pointer)
    local O = GOLDEN.Offsets
    if not pointer or pointer < 0x10000 then return nil end
    if memory_read("byte", pointer + O.Tag) ~= O.StringTag then return nil end
    local length = memory_read("int", pointer + O.StringLength)
    if not length or length < 1 or length > 64 then return nil end
    return memory_read("string", pointer + O.StringText)
end

function GOLDEN.constants(proto)
    local list = {}
    local base = GOLDEN.read(proto, "Constants")
    local count = memory_read("int", proto + GOLDEN.Offsets.ConstantCount)
    if not base or base < 0x10000 or not count or count < 0 or count > 512 then return list end
    for index = 0, count - 1 do
        local slot = base + index * 16
        if memory_read("int", slot + GOLDEN.Offsets.ValueTag) == GOLDEN.Offsets.StringTag then
            local pointer = memory_read("uintptr_t", slot)
            table.insert(list, {Slot = slot, Pointer = pointer, Text = GOLDEN.text(pointer)})
        end
    end
    return list
end

function GOLDEN.named(proto)
    local Names = {}
    for _, Constant in ipairs(GOLDEN.constants(proto)) do
        if Constant.Text and not Names[Constant.Text] then Names[Constant.Text] = Constant end
    end
    return Names
end

function GOLDEN.children(proto)
    local list = {}
    local base = GOLDEN.read(proto, "Children")
    local count = memory_read("int", proto + GOLDEN.Offsets.ChildCount)
    if not base or base < 0x10000 or not count or count < 0 or count > 64 then return list end
    for index = 0, count - 1 do
        local child = memory_read("uintptr_t", base + index * 8)
        if child and child > 0x10000 then table.insert(list, child) end
    end
    return list
end

function GOLDEN.closures(key, upvalues)
    local list = {}
    GOLDEN.Cache = GOLDEN.Cache or {}
    GOLDEN.Cache[key] = GOLDEN.Cache[key] or getgc(key) or {}
    for _, Entry in ipairs(GOLDEN.Cache[key]) do
        local closure = Entry.addr and memory_read("uintptr_t", Entry.addr)
        if closure and closure > 0x10000 and memory_read("byte", closure + GOLDEN.Offsets.Tag) == GOLDEN.Offsets.FunctionTag and memory_read("byte", closure + GOLDEN.Offsets.Nups) == upvalues then
            table.insert(list, closure)
        end
    end
    return list
end

function GOLDEN.patch(List, kind, address, original, value)
    if memory_read(kind, address) ~= value then memory_write(kind, address, value) end
    table.insert(List, {Address = address, Kind = kind, Original = original, Patched = value})
end

function GOLDEN.unpatch(List)
    for _, Patch in ipairs(List or {}) do
        pcall(function()
            if Patch.Original ~= nil and memory_read(Patch.Kind, Patch.Address) == Patch.Patched then memory_write(Patch.Kind, Patch.Address, Patch.Original) end
        end)
    end
end

function GOLDEN.setupBar()
    local O = GOLDEN.Offsets
    for _, closure in ipairs(GOLDEN.closures("handleInvoke", 6)) do
        if memory_read("int", closure + O.Upvalue + O.ValueTag) == O.FunctionTag then
            local check = memory_read("uintptr_t", closure + O.Upvalue)
            local proto = GOLDEN.heap(check) and GOLDEN.read(check, "Proto")
            local NoInput = proto and proto > 0x10000 and GOLDEN.named(proto)["noinput"]
            if NoInput then
                GOLDEN.NoInput = NoInput.Pointer
                local Found = {}
                local timeout
                local targets = {}
                for _, child in ipairs(GOLDEN.children(proto)) do
                    for _, Constant in ipairs(GOLDEN.constants(child)) do
                        if Constant.Pointer == NoInput.Pointer then
                            timeout = child
                            table.insert(targets, Constant.Slot)
                        elseif Constant.Text and not Found[Constant.Text] then
                            Found[Constant.Text] = Constant.Pointer
                        end
                    end
                    for _, grandchild in ipairs(GOLDEN.children(child)) do
                        for _, Constant in ipairs(GOLDEN.constants(grandchild)) do
                            if Constant.Text and not Found[Constant.Text] then Found[Constant.Text] = Constant.Pointer end
                        end
                    end
                end
                if not timeout and Found["supercomplete"] then
                    for _, child in ipairs(GOLDEN.children(proto)) do
                        local Names = GOLDEN.named(child)
                        local Swapped = Names["supercomplete"]
                        if Swapped and Names["Calibrate"] and not Names["Sounds.UI.SkillCheck.Correct"] then
                            GOLDEN.Slots.Bar = {{Address = Swapped.Slot, Kind = "uintptr_t", Original = NoInput.Pointer, Patched = Swapped.Pointer}}
                            GOLDEN.Ready = true
                            return true
                        end
                    end
                end
                if Found["supercomplete"] and timeout and #targets > 0 then
                    local Group = {}
                    for _, slot in ipairs(targets) do GOLDEN.patch(Group, "uintptr_t", slot, NoInput.Pointer, Found["supercomplete"]) end
                    GOLDEN.Slots.Bar = Group
                    GOLDEN.Ready = true
                    return true
                end
            end
        end
    end
    return false
end

function GOLDEN.setupCircle(closure)
    local proto = GOLDEN.read(closure, "Proto")
    if not proto or proto < 0x10000 then return false end
    local Timeout, Press
    for _, child in ipairs(GOLDEN.children(proto)) do
        local Names = GOLDEN.named(child)
        if Names["PlaybackState"] and (Names["noinput"] or Names["supercomplete"]) then Timeout = Names end
        if Names["supercomplete"] and Names["Sounds.UI.SkillCheck.GoldAreaHit"] then Press = Names end
    end
    if Timeout and Press and not Timeout["noinput"] then
        GOLDEN.Slots.Circle = {{Address = Timeout["supercomplete"].Slot, Kind = "uintptr_t", Original = not Timeout["Sounds.UI.SkillCheck.GoldAreaHit"] and GOLDEN.NoInput or nil, Patched = Timeout["supercomplete"].Pointer}}
        GOLDEN.CircleReady = true
        return true
    end
    if not (Timeout and Press) then return false end
    local Group = {}
    GOLDEN.patch(Group, "uintptr_t", Timeout["noinput"].Slot, Timeout["noinput"].Pointer, Press["supercomplete"].Pointer)
    GOLDEN.Slots.Circle = Group
    GOLDEN.CircleReady = true
    return true
end

function GOLDEN.setupTreadmill(closure)
    local O = GOLDEN.Offsets
    local proto = GOLDEN.read(closure, "Proto")
    if not proto or proto < 0x10000 then return false end
    for _, child in ipairs(GOLDEN.children(proto)) do
        local Names = GOLDEN.named(child)
        local code = GOLDEN.read(child, "Code")
        if Names["task"] and Names["wait"] and memory_read("int", child + O.ConstantCount) == 3 and memory_read("int", child + O.CodeSize) == 12 and code and code > 0x10000 then
            local function byte(offset) return memory_read("byte", code + offset) end
            local loads = byte(28) == byte(36) and byte(29) == 0 and byte(30) == 0 and byte(31) == 0 and byte(37) == 0 and (byte(38) == 0 or byte(38) == 1) and byte(39) == 0
            local stores = byte(32) == byte(40) and byte(28) ~= byte(32) and byte(33) == 0 and byte(34) == 0 and byte(35) == 0 and byte(41) == 0 and byte(42) == 1 and byte(43) == 0
            local wait = byte(9) == 1 and (byte(10) == 3 or byte(10) == 0) and byte(11) == 0
            if loads and stores and wait then
                local Patches = {}
                GOLDEN.patch(Patches, "byte", code + 38, 0, 1)
                GOLDEN.patch(Patches, "byte", code + 10, 3, 0)
                GOLDEN.Slots.Treadmill = Patches
                GOLDEN.TreadCheck = code + 38
                GOLDEN.TreadReady = true
                return true
            end
        end
    end
    return false
end

function GOLDEN.setupHandlers()
    for _, closure in ipairs(GOLDEN.closures("HandleSkillCheck", 14)) do
        if not GOLDEN.CircleReady then pcall(GOLDEN.setupCircle, closure) end
    end
    for _, closure in ipairs(GOLDEN.closures("HandleSkillCheck", 11)) do
        if not GOLDEN.TreadReady then pcall(GOLDEN.setupTreadmill, closure) end
    end
end

function GOLDEN.restore()
    GOLDEN.unpatch(GOLDEN.Slots.Bar)
    GOLDEN.unpatch(GOLDEN.Slots.Circle)
    GOLDEN.unpatch(GOLDEN.Slots.Treadmill)
    GOLDEN.Slots = {}
    GOLDEN.Ready = false
    GOLDEN.CircleReady = false
    GOLDEN.TreadReady = false
end

function GOLDEN.valid(List)
    local Patch = List and List[1]
    if not Patch then return false end
    return memory_read("uintptr_t", Patch.Address) == Patch.Patched and GOLDEN.text(Patch.Patched) == "supercomplete"
end

function GOLDEN.tweenFor(target, wanted)
    local O = GOLDEN.Offsets
    if not GOLDEN.Map.Tween then GOLDEN.queueTween() return nil end
    if not GOLDEN.service() then return nil end
    local first = memory_read("uintptr_t", GOLDEN.Service + O.TweenList)
    local last = memory_read("uintptr_t", GOLDEN.Service + O.TweenList + 8)
    if not first or not last or last < first or last - first > 16 * 512 then return nil end
    for entry = first, last - 16, 16 do
        local tween = memory_read("uintptr_t", entry)
        if tween and tween > 0x10000 and memory_read("uintptr_t", tween + O.TweenTarget) == target then
            local duration = memory_read("float", tween + O.TweenTime)
            local elapsed = memory_read("float", tween + O.TweenElapsed)
            if duration and elapsed and elapsed > 0 and elapsed < duration - 0.02 and (not wanted or math.abs(duration - wanted) < 0.01) then return tween, elapsed, duration end
        end
    end
    return nil
end

function GOLDEN.cut(parts)
    local Marker = parts and parts.marker
    if not Marker then return false end
    local tween, elapsed = GOLDEN.tweenFor(tonumber(Marker.Address), not parts.circle and GOLDEN.Sweep or nil)
    if not tween then return false end
    memory_write("float", tween + GOLDEN.Offsets.TweenTime, elapsed + 0.001)
    return true
end

function GOLDEN.stretch(parts)
    local Ring = parts and parts.marker
    if not (Ring and parts.gold and parts.hole) then return false end
    local tween, elapsed, duration = GOLDEN.tweenFor(tonumber(Ring.Address))
    if not tween or tween == GOLDEN.Stretched then return false end
    local size, yellow, hole = circleDiameter(Ring), circleDiameter(parts.gold), circleDiameter(parts.hole)
    if not (size and yellow and hole) or size <= 0 or elapsed >= duration * 0.5 then return false end
    local start = size / math.max(0.05, 1 - elapsed / duration)
    if start <= yellow or yellow <= hole then return false end
    local enter, leave = 1 - yellow / start, 1 - hole / start
    local press = duration * (enter + rollAimFraction() * (leave - enter))
    local finish = press + GOLDEN.PressDelay + math.random() * 0.05
    GOLDEN.Stretched = tween
    if finish <= elapsed + 0.05 then return false end
    memory_write("float", tween + GOLDEN.Offsets.TweenTime, finish)
    return true
end

function GOLDEN.active(parts)
    if not SETTINGS.alwaysGolden or not parts then return false end
    if parts.circle then return GOLDEN.CircleReady end
    return GOLDEN.Ready
end

function GOLDEN.snapshot()
    local Copy = {Encoding = {}}
    for key, value in pairs(GOLDEN.Offsets) do
        if type(value) == "number" then Copy[key] = value end
    end
    for key, value in pairs(GOLDEN.Offsets.Encoding) do Copy.Encoding[key] = value end
    return Copy
end

function GOLDEN.apply(Copy)
    for key, value in pairs(Copy) do
        if type(value) == "number" and type(GOLDEN.Offsets[key]) == "number" then GOLDEN.Offsets[key] = value end
    end
    for key, value in pairs(type(Copy.Encoding) == "table" and Copy.Encoding or {}) do
        if type(value) == "number" and GOLDEN.Offsets.Encoding[key] ~= nil then GOLDEN.Offsets.Encoding[key] = value end
    end
end

function GOLDEN.build()
    local Map = GOLDEN.Map
    if Map.Build or not VantaUI.MemoryAccess() then return Map.Build end
    local base = getbase()
    local header = memory_read("int", base + 0x3C)
    Map.Build = tostring(memory_read("int", base + header + 8)) .. ":" .. tostring(memory_read("int", base + header + 0x50))
    return Map.Build
end

function GOLDEN.changed(Before)
    for key, value in pairs(GOLDEN.snapshot()) do
        if key ~= "Encoding" and Before[key] ~= value then return true end
    end
    for key, value in pairs(GOLDEN.Offsets.Encoding) do
        if Before.Encoding[key] ~= value then return true end
    end
    return false
end

function GOLDEN.saveMap(ran)
    local Map = GOLDEN.Map
    if ran or not Map.LastRun then Map.LastRun = os.time() end
    Map.Works, Map.SavedBuild = Map.Luau, GOLDEN.build()
    if type(writefile) ~= "function" then return end
    local Data = GOLDEN.snapshot()
    Data.LastRun, Data.Works, Data.Build = Map.LastRun, Map.Works, Map.SavedBuild
    UI.folder(CONFIG_FOLDER)
    pcall(writefile, Map.File, HttpService:JSONEncode(Data))
end

function GOLDEN.ago(time)
    local seconds = os.time() - time
    local minutes, hours, days = math.floor(seconds / 60), math.floor(seconds / 3600), math.floor(seconds / 86400)
    if days > 0 then return days .. (days == 1 and " day ago" or " days ago") end
    if hours > 0 then return hours .. (hours == 1 and " hour ago" or " hours ago") end
    if minutes > 0 then return minutes .. (minutes == 1 and " minute ago" or " minutes ago") end
    return "just now"
end

function GOLDEN.showStatus()
    local Map = GOLDEN.Map
    local Status = Map.Label
    if not (Status and Status.SetContent) then return end
    local text, color
    if Map.State == "Success" then
        text, color = "Status: Success", Color3.fromRGB(80, 200, 110)
    elseif Map.State == "Lobby" then
        text, color = "Status: Be in the game!", Color3.fromRGB(230, 80, 80)
    elseif Map.State == "Failed" then
        text, color = "Status: Failed (" .. tostring(Map.Reason) .. ")", Color3.fromRGB(230, 80, 80)
    elseif not Map.LastRun then
        text = "Status: Unknown"
    else
        local current = GOLDEN.build()
        local works = Map.Works and (not current or not Map.SavedBuild or current == Map.SavedBuild)
        text = (works and "Status: Works" or "Status: Requires a remap") .. " (ran " .. GOLDEN.ago(Map.LastRun) .. ")"
    end
    Status:SetContent(text)
    if Status.SetColor then Status:SetColor(color) end
end

function GOLDEN.setStatus(state, reason)
    GOLDEN.Map.State, GOLDEN.Map.Reason = state, reason
    GOLDEN.showStatus()
end

function GOLDEN.loadMap()
    GOLDEN.Map.Loaded = true
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    local ok, Data = pcall(function()
        if not isfile(GOLDEN.Map.File) then return nil end
        return HttpService:JSONDecode(readfile(GOLDEN.Map.File))
    end)
    if not (ok and type(Data) == "table") then return end
    GOLDEN.apply(Data)
    GOLDEN.Map.LastRun, GOLDEN.Map.Works, GOLDEN.Map.SavedBuild = tonumber(Data.LastRun), Data.Works == true, type(Data.Build) == "string" and Data.Build or nil
    GOLDEN.Map.TweenSaved = Data.TweenElapsed ~= nil and Data.TweenList ~= nil and Data.TweenTime ~= nil
end

function GOLDEN.entries(key)
    GOLDEN.Cache = GOLDEN.Cache or {}
    GOLDEN.Cache[key] = GOLDEN.Cache[key] or getgc(key) or {}
    return GOLDEN.Cache[key]
end

function GOLDEN.fields(current, mode, full, last)
    local List = {{Offset = current, Mode = mode or 0}}
    if not full then return List end
    for offset = 0x08, last or 0xC8, 8 do
        for encoding = 0, 3 do table.insert(List, {Offset = offset, Mode = encoding}) end
    end
    return List
end

function GOLDEN.counts(current, full)
    local List = {current}
    if not full then return List end
    for offset = 0x08, 0xFC, 4 do table.insert(List, offset) end
    return List
end

function GOLDEN.ints(proto)
    local Values = {}
    for offset = 0x08, 0xFC, 4 do Values[offset] = memory_read("int", proto + offset) end
    return Values
end

function GOLDEN.scanConstants(base, limit)
    local O = GOLDEN.Offsets
    local found
    for index = 0, limit - 1 do
        local slot = base + index * 16
        local tag = memory_read("int", slot + O.ValueTag)
        if not tag or tag < 0 or tag > 31 then return index, found end
        if tag == O.StringTag or tag == O.FunctionTag then
            local value = memory_read("uintptr_t", slot)
            if not GOLDEN.heap(value) or memory_read("byte", value + O.Tag) ~= tag then return index, found end
            if not found and tag == O.StringTag and GOLDEN.text(value) == "noinput" then found = index end
        end
    end
    return limit, found
end

function GOLDEN.mapConstants(Protos, Ints, full)
    local O = GOLDEN.Offsets
    local Best
    for _, Field in ipairs(GOLDEN.fields(O.Constants, O.Encoding.Constants, full)) do
        local Lengths = {}
        for index, proto in ipairs(Protos) do
            local base = GOLDEN.pointer(proto + Field.Offset, Field.Mode)
            if not GOLDEN.heap(base) then Lengths = nil break end
            local length, found = GOLDEN.scanConstants(base, 1024)
            if index <= 2 and not found then Lengths = nil break end
            Lengths[index] = {Length = length, Minimum = index <= 2 and found + 1 or 1}
        end
        for _, offset in ipairs(Lengths and GOLDEN.counts(O.ConstantCount, full) or {}) do
            local total = 0
            for index = 1, #Protos do
                local count = Ints[index][offset]
                if not count or count < Lengths[index].Minimum or count > Lengths[index].Length then total = nil break end
                total = total + count
            end
            if total and (not Best or total > Best.Total) then Best = {Total = total, Offset = Field.Offset, Mode = Field.Mode, Count = offset} end
        end
        if full then task.wait() end
    end
    if not Best then return false end
    O.Constants, O.Encoding.Constants, O.ConstantCount = Best.Offset, Best.Mode, Best.Count
    return true
end

function GOLDEN.mapChildren(Protos, Ints, full)
    local O = GOLDEN.Offsets
    local Best
    for _, Field in ipairs(GOLDEN.fields(O.Children, O.Encoding.Children, full)) do
        local Lengths = {}
        for index, proto in ipairs(Protos) do
            local base = GOLDEN.pointer(proto + Field.Offset, Field.Mode)
            local length = 0
            if not GOLDEN.heap(base) and index == 2 then Lengths = nil break end
            while GOLDEN.heap(base) and length < 256 do
                local child = memory_read("uintptr_t", base + length * 8)
                if not GOLDEN.heap(child) or memory_read("byte", child + O.Tag) ~= O.ProtoTag then break end
                length = length + 1
            end
            Lengths[index] = length
        end
        for _, offset in ipairs(Lengths and Lengths[2] >= 2 and GOLDEN.counts(O.ChildCount, full) or {}) do
            local total = offset ~= O.ConstantCount and 0 or nil
            for index = 1, total and #Protos or 0 do
                local count = Ints[index][offset]
                if not count or count < 0 or count > Lengths[index] or (index == 2 and count < 2) then total = nil break end
                total = total + count
            end
            if total and (not Best or total > Best.Total) then Best = {Total = total, Offset = Field.Offset, Mode = Field.Mode, Count = offset} end
        end
        if full then task.wait() end
    end
    if not Best then return false end
    O.Children, O.Encoding.Children, O.ChildCount = Best.Offset, Best.Mode, Best.Count
    return true
end

function GOLDEN.mapCode(Protos, Ints, full)
    local O = GOLDEN.Offsets
    local Found = {}
    for _, Field in ipairs(GOLDEN.fields(O.Code, O.Encoding.Code, full)) do
        local Bases = {}
        for index, proto in ipairs(Protos) do
            local base = GOLDEN.pointer(proto + Field.Offset, Field.Mode)
            if not GOLDEN.heap(base) or (base >= proto and base < proto + 0x200) then Bases = nil break end
            Bases[index] = base
        end
        for _, offset in ipairs(Bases and GOLDEN.counts(O.CodeSize, full) or {}) do
            local last = offset ~= O.ConstantCount and offset ~= O.ChildCount and -1 or nil
            local Sizes, distinct = {}, 0
            for index = 1, last and #Protos or 0 do
                local size = Ints[index][offset]
                local word = size and size >= 1 and size <= 65536 and memory_read("int", Bases[index] + (size - 1) * 4)
                local operation = word and word ~= 0 and word % 256
                if not operation or (last ~= -1 and operation ~= last) then last = nil break end
                last = operation
                if not Sizes[size] then Sizes[size], distinct = true, distinct + 1 end
            end
            if last and distinct >= 3 then table.insert(Found, {Offset = Field.Offset, Mode = Field.Mode, Size = offset}) end
        end
        if full then task.wait() end
    end
    local Choice = Found[1]
    if not Choice then return false end
    for _, Candidate in ipairs(Found) do
        for index = 1, #Protos do
            if Ints[index][Candidate.Size] ~= Ints[index][Choice.Size] then return false end
        end
    end
    O.Code, O.Encoding.Code, O.CodeSize = Choice.Offset, Choice.Mode, Choice.Size
    return true
end

function GOLDEN.mapProto(Protos, full)
    local Ints = {}
    for index, proto in ipairs(Protos) do Ints[index] = GOLDEN.ints(proto) end
    if not GOLDEN.mapConstants(Protos, Ints, full) then return false end
    if not GOLDEN.mapChildren(Protos, Ints, full) then return false end
    local All, AllInts = {}, {}
    for index, proto in ipairs(Protos) do
        table.insert(All, proto)
        table.insert(AllInts, Ints[index])
    end
    for index = 2, #Protos do
        for _, child in ipairs(GOLDEN.children(Protos[index])) do
            if #All < 40 then
                table.insert(All, child)
                table.insert(AllInts, GOLDEN.ints(child))
            end
        end
    end
    return GOLDEN.mapCode(All, AllInts, full)
end

function GOLDEN.findLuau(force)
    local O = GOLDEN.Offsets
    local Invoke = GOLDEN.entries("handleInvoke")[1]
    if not (Invoke and Invoke.addr and Invoke.vtt) then return false, "skill check scripts not found" end
    local functionTag = Invoke.vtt
    local Entries = {Invoke}
    for _, Entry in ipairs(GOLDEN.entries("HandleSkillCheck")) do
        if Entry.vtt == functionTag and Entry.addr then table.insert(Entries, Entry) end
    end
    if #Entries < 3 then return false, "skill check scripts not found" end
    local Closures = {}
    for index, Entry in ipairs(Entries) do
        Closures[index] = memory_read("uintptr_t", Entry.addr)
        if not GOLDEN.heap(Closures[index]) then return false, "Luau object layout not recognised" end
    end
    local valueTag
    for _, offset in ipairs({12, 8}) do
        local match = true
        for _, Entry in ipairs(Entries) do
            if memory_read("int", Entry.addr + offset) ~= functionTag then match = false break end
        end
        if match then valueTag = offset break end
    end
    if not valueTag then return false, "Luau object layout not recognised" end
    local tag
    for index = 0, 3 do
        local match = true
        for _, closure in ipairs(Closures) do
            if memory_read("byte", closure + index) ~= functionTag then match = false break end
        end
        if match and tag then return false, "Luau object layout not recognised" end
        if match then tag = index end
    end
    if not tag then return false, "Luau object layout not recognised" end
    local key, other = memory_read("uintptr_t", Invoke.addr + 16), memory_read("uintptr_t", Entries[2].addr + 16)
    if not (GOLDEN.heap(key) and GOLDEN.heap(other)) then return false, "Luau object layout not recognised" end
    local stringTag = memory_read("byte", key + tag)
    local textOffset, lengthOffset
    for offset = 8, 64, 4 do
        if memory_read("string", key + offset) == "handleInvoke" then textOffset = offset break end
    end
    if not textOffset then return false, "Luau object layout not recognised" end
    for offset = textOffset - 4, 4, -4 do
        if memory_read("int", key + offset) == 12 then lengthOffset = offset break end
    end
    if not lengthOffset or memory_read("byte", other + tag) ~= stringTag or memory_read("int", other + lengthOffset) ~= 16 or memory_read("string", other + textOffset) ~= "HandleSkillCheck" then return false, "Luau object layout not recognised" end
    local nups
    for index = tag + 1, 7 do
        if memory_read("byte", Closures[1] + index) == 6 then
            local Seen = {}
            for position = 2, #Closures do Seen[memory_read("byte", Closures[position] + index)] = true end
            if Seen[11] and Seen[14] then nups = index break end
        end
    end
    if not nups then return false, "Luau object layout not recognised" end
    local upvalues
    for offset = 0x10, 0x48, 8 do
        local match = memory_read("int", Closures[1] + offset + 5 * 16 + valueTag) == functionTag
        for _, closure in ipairs(match and Closures or {}) do
            for index = 0, memory_read("byte", closure + nups) - 1 do
                local value = memory_read("int", closure + offset + index * 16 + valueTag)
                if not value or value < 0 or value > 31 then match = false break end
            end
            if not match then break end
        end
        if match then upvalues = offset break end
    end
    if not upvalues then return false, "Luau object layout not recognised" end
    O.Tag, O.ValueTag, O.FunctionTag, O.StringTag, O.StringText, O.StringLength, O.Nups, O.Upvalues, O.Upvalue = tag, valueTag, functionTag, stringTag, textOffset, lengthOffset, nups, upvalues, upvalues + 5 * 16
    local check = memory_read("uintptr_t", Closures[1] + O.Upvalue)
    if not GOLDEN.heap(check) or memory_read("byte", check + tag) ~= functionTag then return false, "Luau object layout not recognised" end
    local Owners = {Closures[1], check}
    for position = 2, #Closures do table.insert(Owners, Closures[position]) end
    for _, full in ipairs(force and {true} or {false, true}) do
        for _, Field in ipairs(GOLDEN.fields(O.Proto, O.Encoding.Proto, full, upvalues - 8)) do
            local Protos, protoTag = {}, nil
            for index, owner in ipairs(Owners) do
                local proto = GOLDEN.pointer(owner + Field.Offset, Field.Mode)
                local kind = GOLDEN.heap(proto) and memory_read("byte", proto + tag)
                if not kind or (protoTag and kind ~= protoTag) then Protos = nil break end
                protoTag = kind
                Protos[index] = proto
            end
            if Protos and protoTag ~= functionTag and protoTag ~= stringTag then
                O.ProtoTag = protoTag
                if GOLDEN.mapProto(Protos, full) then
                    O.Proto, O.Encoding.Proto = Field.Offset, Field.Mode
                    return true
                end
            end
        end
    end
    return false, "function layout not found"
end

function GOLDEN.mapLuau(force)
    local Previous, mapped = GOLDEN.snapshot(), GOLDEN.Map.Luau
    local ok, found, reason = pcall(GOLDEN.findLuau, force)
    reason = ok and reason or "error: " .. tostring(found):sub(1, 60)
    found = ok and found == true
    if not found then GOLDEN.apply(Previous) end
    GOLDEN.Map.Luau = found or mapped
    GOLDEN.Map.Verified = found or GOLDEN.Map.Verified
    return found, reason
end

function GOLDEN.service()
    if GOLDEN.Service then return GOLDEN.Service end
    for _, Service in ipairs(game:GetChildren()) do
        if Service.ClassName == "TweenService" then GOLDEN.Service = tonumber(Service.Address) break end
    end
    return GOLDEN.Service
end

function GOLDEN.className(address)
    local descriptor = memory_read("uintptr_t", address + 0x18)
    if not descriptor or descriptor < 0x10000 then return nil end
    local name = memory_read("uintptr_t", descriptor + 8)
    if not name or name < 0x10000 then return nil end
    local text = memory_read("string", name)
    if type(text) ~= "string" or #text < 2 or #text > 40 or not text:match("^%a+$") then return nil end
    return text
end

function GOLDEN.tweens(service, offset)
    local first, last = memory_read("uintptr_t", service + offset), memory_read("uintptr_t", service + offset + 8)
    if not (GOLDEN.heap(first) and GOLDEN.heap(last)) or last <= first or (last - first) % 16 ~= 0 or last - first > 16 * 512 then return nil end
    local List = {}
    for entry = first, last - 16, 16 do
        local tween = memory_read("uintptr_t", entry)
        if not GOLDEN.heap(tween) or GOLDEN.className(tween) ~= "Tween" then return nil end
        table.insert(List, tween)
    end
    return List
end

function GOLDEN.findTween(force)
    local O = GOLDEN.Offsets
    local service = GOLDEN.service()
    if not service then return false, "TweenService not found" end
    local listOffset, Tweens = O.TweenList, GOLDEN.tweens(service, O.TweenList)
    for offset = 0x40, Tweens and 0 or 0x400, 8 do
        Tweens = GOLDEN.tweens(service, offset)
        if Tweens then listOffset = offset break end
    end
    if not Tweens then return false, "no animations playing" end
    local Samples = {}
    for index = 1, math.min(#Tweens, 6) do
        local Floats = {}
        for offset = 0x40, 0x300, 4 do Floats[offset] = memory_read("float", Tweens[index] + offset) end
        Samples[index] = {Tween = Tweens[index], Before = Floats}
    end
    task.wait(0.2)
    local Present, Alive = {}, {}
    for _, tween in ipairs(GOLDEN.tweens(service, listOffset) or {}) do Present[tween] = true end
    for _, Sample in ipairs(Samples) do
        if Present[Sample.Tween] then
            Sample.After = {}
            for offset = 0x40, 0x300, 4 do Sample.After[offset] = memory_read("float", Sample.Tween + offset) end
            table.insert(Alive, Sample)
        end
    end
    if #Alive < 1 then return false, "animations ended while sampling" end
    local function passes(test, offset, share)
        if offset < 0x40 or offset > 0x300 then return false end
        local count = 0
        for _, Sample in ipairs(Alive) do
            if test(Sample, offset) then count = count + 1 end
        end
        return count >= math.max(1, math.ceil(#Alive * (share or 1)))
    end
    local function targets(Sample, offset)
        local pointer = memory_read("uintptr_t", Sample.Tween + offset)
        if not GOLDEN.heap(pointer) or pointer == Sample.Tween then return false end
        local name = GOLDEN.className(pointer)
        return name ~= nil and name ~= "Tween" and name ~= "TweenService"
    end
    local function elapses(Sample, offset)
        local before, after = Sample.Before[offset], Sample.After[offset]
        return before ~= nil and after ~= nil and before >= 0 and after - before >= 0.05 and after - before <= 2 and after < 3600
    end
    local function lasts(elapsed)
        return function(Sample, offset)
            local before, after = Sample.Before[offset], Sample.After[offset]
            return before ~= nil and before == after and before > 0 and before < 3600 and offset ~= elapsed
        end
    end
    local function unique(test, step, share)
        local found
        for offset = 0x40, #Alive >= 2 and 0x300 or 0, step do
            if passes(test, offset, share) then
                if found then return nil end
                found = offset
            end
        end
        return found
    end
    local target, elapsed, duration
    for shift = 0, 0x80, 4 do
        for _, delta in ipairs(shift == 0 and {0} or {shift, -shift}) do
            if not target and (O.TweenTarget + delta) % 8 == 0 and passes(targets, O.TweenTarget + delta) and passes(elapses, O.TweenElapsed + delta, 0.6) and passes(lasts(O.TweenElapsed + delta), O.TweenTime + delta) then
                target, elapsed, duration = O.TweenTarget + delta, O.TweenElapsed + delta, O.TweenTime + delta
            end
        end
    end
    if not target then
        target = passes(targets, O.TweenTarget) and O.TweenTarget or unique(targets, 8)
        elapsed = passes(elapses, O.TweenElapsed, 0.6) and O.TweenElapsed or unique(elapses, 4, 0.6)
        duration = elapsed and (passes(lasts(elapsed), O.TweenTime) and O.TweenTime or unique(lasts(elapsed), 4))
    end
    if not (target and elapsed and duration) then return false, "tween fields not found" end
    O.TweenList, O.TweenTarget, O.TweenElapsed, O.TweenTime = listOffset, target, elapsed, duration
    return true
end

function GOLDEN.mapTween(force)
    local ok, found, reason = pcall(GOLDEN.findTween, force)
    reason = ok and reason or "error: " .. tostring(found):sub(1, 60)
    found = ok and found == true
    GOLDEN.Map.Tween = found or GOLDEN.Map.Tween
    return found, reason
end

function GOLDEN.queueTween()
    local Map, now = GOLDEN.Map, tick()
    if Map.TweenBusy or GOLDEN.Busy or now < Map.TweenNext or (Map.TweenTries or 0) >= 3 or not VantaUI.MemoryAccess() then return end
    Map.TweenTries = (Map.TweenTries or 0) + 1
    Map.TweenNext = now + 20
    Map.TweenBusy = true
    task.spawn(function()
        local started = os.clock()
        FARM.debugNote("TASK golden tween remap start")
        local Before = GOLDEN.snapshot()
        local found = GOLDEN.mapTween(false)
        FARM.debugNote(string.format("TASK golden tween remap end %.0f ms, found=%s", (os.clock() - started) * 1000, tostring(found)))
        if found then
            local changed = GOLDEN.changed(Before)
            GOLDEN.saveMap(changed)
            if changed or Map.State == "Failed" then GOLDEN.setStatus(changed and "Success" or nil) end
        end
        Map.TweenBusy = false
    end)
end

function GOLDEN.prepare(now)
    local Map = GOLDEN.Map
    if now >= Map.StatusAt then
        Map.StatusAt = now + 30
        GOLDEN.showStatus()
    end
    if not (SETTINGS.alwaysGolden or SETTINGS.betterBarnaby) or PLACE_MODE ~= "main" then return end
    if GOLDEN.Busy or SWIMMER.Busy or not VantaUI.MemoryAccess() then return end
    if not Map.Loaded then GOLDEN.loadMap() end
    if not SETTINGS.autoRemap then
        Map.Luau, Map.Tween = true, true
        return
    end
    if not Map.Verified and Map.Works and Map.SavedBuild and Map.SavedBuild == GOLDEN.build() then
        Map.Verified, Map.Luau = true, true
        if Map.TweenSaved then Map.Tween = true end
        FARM.debugNote("golden offsets: saved map matches this client build, skipped the scan")
    end
    if Map.Verified then
        if SETTINGS.alwaysGolden and not Map.Tween then GOLDEN.queueTween() end
        return
    end
    Map.NextTry = Map.NextTry or now + 10
    if now < Map.NextTry or Map.Tries >= 3 or Map.Waits >= 15 then return end
    Map.NextTry = now + 20
    GOLDEN.Busy = true
    task.spawn(function()
        local started = os.clock()
        FARM.debugNote("TASK golden offset remap start")
        GOLDEN.Cache = {}
        local Before = GOLDEN.snapshot()
        local luau, reason = GOLDEN.mapLuau(false)
        FARM.debugNote(string.format("TASK golden offset remap luau %.0f ms, ok=%s %s", (os.clock() - started) * 1000, tostring(luau), tostring(reason)))
        local missing = reason == "skill check scripts not found"
        if missing then Map.Waits = Map.Waits + 1 else Map.Tries = Map.Tries + 1 end
        if luau then
            local tween, tweenReason = GOLDEN.mapTween(false)
            local changed = GOLDEN.changed(Before)
            GOLDEN.saveMap(changed)
            if tween or tweenReason ~= "tween fields not found" then
                GOLDEN.setStatus(changed and "Success" or nil)
            else
                GOLDEN.setStatus("Failed", "tween offsets: " .. tweenReason .. ", retrying during skill checks")
            end
        elseif not missing then
            GOLDEN.setStatus("Failed", "Golden and Barnaby offsets: " .. reason)
        end
        if not luau and not missing and Map.Tries >= 3 then
            VantaUI:Notify("Memory offsets", "Could not find the memory offsets, so Always hit Golden and Better Barnaby stay off. Press Remap the memory offsets to try again.", 8)
        end
        if not SETTINGS.alwaysGolden then GOLDEN.Cache = nil end
        GOLDEN.Busy = false
    end)
end

function GOLDEN.remap()
    if PLACE_MODE ~= "main" then GOLDEN.setStatus("Lobby") return end
    if not VantaUI.MemoryAccess() then VantaUI:Notify("Memory offsets", "Memory access is off.", 4) return end
    if GOLDEN.Busy or SWIMMER.Busy or GOLDEN.Map.TweenBusy then VantaUI:Notify("Memory offsets", "Busy, try again in a few seconds.", 4) return end
    if not GOLDEN.Map.Loaded then GOLDEN.loadMap() end
    GOLDEN.Busy = true
    VantaUI:Notify("Memory offsets", "Remapping, Roblox may freeze for a few seconds.", 4)
    task.spawn(function()
        GOLDEN.Cache = {}
        local luau, luauReason = GOLDEN.mapLuau(true)
        local tween, tweenReason = GOLDEN.mapTween(true)
        if luau or tween then GOLDEN.saveMap(true) end
        local Failures = {}
        if not luau then table.insert(Failures, "Golden and Barnaby offsets: " .. luauReason) end
        if not tween then table.insert(Failures, "tween offsets: " .. tweenReason) end
        GOLDEN.setStatus(#Failures == 0 and "Success" or "Failed", table.concat(Failures, "; "))
        GOLDEN.Cache = nil
        GOLDEN.Map.Tries, GOLDEN.Map.Waits, GOLDEN.Map.NextTry, GOLDEN.Map.TweenNext = 0, 0, 0, 0
        GOLDEN.Attempts, GOLDEN.NextScan = 0, 0
        SWIMMER.Attempts, SWIMMER.NextScan = 0, 0
        GOLDEN.Busy = false
        local skill = luau and "Skill check and Barnaby offsets found." or "Skill check and Barnaby offsets not found, those features stay off."
        local engine = tween and "Tween offsets found." or "Tween offsets not found yet, retrying during skill checks."
        VantaUI:Notify("Memory offsets", skill .. " " .. engine, 7)
    end)
end

function GOLDEN.update(now)
    if not SETTINGS.alwaysGolden then
        if GOLDEN.Busy then return end
        if GOLDEN.Ready or GOLDEN.CircleReady or GOLDEN.TreadReady then GOLDEN.restore() end
        GOLDEN.Attempts = 0
        GOLDEN.NextScan = 0
        return
    end
    if PLACE_MODE ~= "main" or GOLDEN.Busy then return end
    if not VantaUI.MemoryAccess() then return end
    if (not GOLDEN.Ready or not GOLDEN.CircleReady or not GOLDEN.TreadReady) and GOLDEN.Map.Luau and now >= GOLDEN.NextScan and GOLDEN.Attempts < GOLDEN.MaxAttempts then
        GOLDEN.NextScan = now + GOLDEN.RetryDelay
        GOLDEN.Attempts = GOLDEN.Attempts + 1
        GOLDEN.Busy = true
        task.spawn(function()
            local started = os.clock()
            FARM.debugNote(string.format("TASK golden setup start (attempt %d)", GOLDEN.Attempts))
            GOLDEN.Cache = GOLDEN.Cache or {}
            if not GOLDEN.Ready then pcall(GOLDEN.setupBar) end
            if not GOLDEN.CircleReady or not GOLDEN.TreadReady then pcall(GOLDEN.setupHandlers) end
            GOLDEN.Cache = nil
            if not SETTINGS.alwaysGolden or GOLDEN.Stopped then GOLDEN.restore() end
            GOLDEN.Busy = false
            FARM.debugNote(string.format("TASK golden setup end %.0f ms, bar=%s circle=%s tread=%s", (os.clock() - started) * 1000, tostring(GOLDEN.Ready), tostring(GOLDEN.CircleReady), tostring(GOLDEN.TreadReady)))
        end)
        return
    end
    if now >= GOLDEN.NextCheck then
        GOLDEN.NextCheck = now + 2
        if GOLDEN.Ready then
            local ok, valid = pcall(GOLDEN.valid, GOLDEN.Slots.Bar)
            if not (ok and valid) then GOLDEN.Ready = false GOLDEN.Slots.Bar = nil GOLDEN.Attempts = 0 end
        end
        if GOLDEN.CircleReady then
            local ok, valid = pcall(GOLDEN.valid, GOLDEN.Slots.Circle)
            if not (ok and valid) then GOLDEN.CircleReady = false GOLDEN.Slots.Circle = nil GOLDEN.Attempts = 0 end
        end
        if GOLDEN.TreadReady then
            local ok, value = pcall(memory_read, "byte", GOLDEN.TreadCheck)
            if not (ok and value == 1) then GOLDEN.TreadReady = false GOLDEN.Slots.Treadmill = nil GOLDEN.Attempts = 0 end
        end
    end
end

local function shouldPressBar(parts, lead)
    local marker, gold, required = parts.marker, parts.gold, parts.required
    local moving = sampleBar(marker)

    local Bar = SKILL.Bar
    if Bar.Pressed or not moving then
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

    local velocity = math.clamp(Bar.Rate, -SKILL.BAR_MAX_SPEED, SKILL.BAR_MAX_SPEED)
    local predicted = markerPos.X + velocity * (lead / 1000)
    local forward = velocity >= 0
    local aim

    if forward then
        aim = goldStart + Bar.Aim * (goldFinish - goldStart)
    else
        aim = goldFinish - Bar.Aim * (goldFinish - goldStart)
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
        Bar.Pressed = true
    end

    return press
end

local function shouldPressSkillCheck(parts, lead)
    if parts.circle then
        return shouldPressCircle(parts, lead)
    end

    return shouldPressBar(parts, lead)
end

local function clearSkillCheckCache()
    SKILL.parts = nil
end

local function cachedSkillCheckIsValid()
    return SKILL.parts ~= nil
        and SKILL.parts.frame.Parent
        and SKILL.parts.marker.Parent
        and SKILL.parts.gold.Parent
        and hasScreenRect(SKILL.parts.marker)
        and hasScreenRect(SKILL.parts.gold)
end

local function getSkillCheckFrame()
    local playerGui = UI.playerGui()
    if not playerGui then
        clearSkillCheckCache()
        return nil
    end

    local circleGui = playerGui:FindFirstChild("CircleSkillCheckGui")

    if SKILL.parts and (circleGui ~= nil) ~= (SKILL.parts.circle == true) then
        clearSkillCheckCache()
    end

    if cachedSkillCheckIsValid() then
        return SKILL.parts
    end

    clearSkillCheckCache()

    local parts = findSkillCheckParts(circleGui)
    if parts then
        SKILL.parts = parts
        return parts
    end

    local now = tick()
    if now - SKILL.lastFind < SKILL.FIND_INTERVAL then
        return nil
    end

    SKILL.lastFind = now

    local screenGui = playerGui:FindFirstChild("ScreenGui")
    local menu = screenGui and screenGui:FindFirstChild("Menu")
    parts = findSkillCheckParts(menu and menu:FindFirstChild("SkillCheckFrame"))
    if parts then
        SKILL.parts = parts
        return parts
    end

    return nil
end

local function pressSpace(hold)
    KEYS.hold(SKILL.VK_SPACE, hold or SKILL.SPACE_HOLD)
end

function SKILL.showing()
    local parts = getSkillCheckFrame()
    if not parts then return false end
    local State = parts.circle and SKILL.Circle or SKILL.Bar
    return State.LastMove ~= nil and tick() - State.LastMove <= SKILL.MOTION_GRACE
end

local function getTreadmillTapGui()
    local playerGui = UI.playerGui()
    return playerGui and playerGui:FindFirstChild("TreadmillTapSkillCheckGui")
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
    if now - SKILL.lastTap >= tapDelay then
        pressSpace(math.clamp(tapDelay * 0.4, SKILL.SPACE_MIN_HOLD, SKILL.SPACE_HOLD))
        SKILL.lastTap = now
    end

    return true
end

local function getBarnabyWorld()
    if PLACE_MODE == "other" then
        return nil
    end

    local playerGui = UI.playerGui()
    if not playerGui then
        return nil
    end

    if PLACE_MODE == "main" then
        local viewport = UI.find("BarnabyViewport", function()
            local clientUi = playerGui:FindFirstChild("ClientUI")
            local window = clientUi and clientUi:FindFirstChild("GameWindow")
            return window and window:FindFirstChild("ViewportFrame")
        end)
        return viewport and viewport:FindFirstChild("WorldModel")
    end

    local viewport = UI.find("BarnabyViewport", function()
        local surface = playerGui:FindFirstChild("SurfaceGui")
        return surface and surface:FindFirstChild("ViewportFrame")
    end)
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
    local info = UI.info()

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

            local chanceValue = UI.myStat("SkillCheckChance")
            local chance = chanceValue and UI.read(chanceValue) or 15
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
    local track = BARNABY.track

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
    BARNABY.track.y = nil
    BARNABY.obstacleSignature = nil
    BARNABY.focusWarned = false
end

function SWIMMER.keyText(slot)
    return GOLDEN.text(memory_read("uintptr_t", slot + 16))
end

function SWIMMER.sibling(slot, name)
    for step = -40, 40 do
        local candidate = slot + step * 32
        if SWIMMER.keyText(candidate) == name then return candidate end
    end
end

function SWIMMER.patch(address, kind, original, value)
    GOLDEN.patch(SWIMMER.Patches, kind, address, original, value)
end

function SWIMMER.setup()
    for _, Entry in ipairs(getgc("IsOverlapping") or {}) do
        local slot = Entry.addr
        local gravity = slot and SWIMMER.sibling(slot, "SetGravity")
        local bounds = slot and SWIMMER.sibling(slot, "IsOutOfBounds")
        local new = slot and SWIMMER.sibling(slot, "new")
        local O = GOLDEN.Offsets
        if gravity and bounds and new and memory_read("int", slot + O.ValueTag) == O.FunctionTag and memory_read("int", bounds + O.ValueTag) == O.FunctionTag and memory_read("int", gravity + O.ValueTag) == O.FunctionTag and memory_read("int", new + O.ValueTag) == O.FunctionTag then
            SWIMMER.Patches = {}
            local noop = memory_read("uintptr_t", gravity)
            local overlap, outside = memory_read("uintptr_t", slot), memory_read("uintptr_t", bounds)
            if overlap ~= noop then SWIMMER.patch(slot, "uintptr_t", overlap, noop) end
            if outside ~= noop then SWIMMER.patch(bounds, "uintptr_t", outside, noop) end
            local closure = memory_read("uintptr_t", new)
            local proto = GOLDEN.heap(closure) and GOLDEN.read(closure, "Proto")
            local base = GOLDEN.heap(proto) and GOLDEN.read(proto, "Constants")
            local count = GOLDEN.heap(proto) and memory_read("int", proto + O.ConstantCount)
            local accelerationKey
            if base and base > 0x10000 and count and count > 0 and count < 128 then
                for index = 0, count - 1 do
                    local constant = base + index * 16
                    local tag = memory_read("int", constant + O.ValueTag)
                    if tag == O.NumberTag then
                        local value = memory_read("double", constant)
                        if math.abs(value + 0.1) < 1e-9 then SWIMMER.patch(constant, "double", value, 0) end
                    elseif tag == O.StringTag and GOLDEN.text(memory_read("uintptr_t", constant)) == "Acceleration_Y" then
                        accelerationKey = index
                    end
                end
            end
            local code = GOLDEN.heap(proto) and GOLDEN.read(proto, "Code")
            local size = GOLDEN.heap(proto) and memory_read("int", proto + O.CodeSize)
            if accelerationKey and code and code > 0x10000 and size and size > 2 and size < 256 then
                for index = 0, size - 3 do
                    local word = code + index * 4
                    local low, high = memory_read("byte", word + 2), memory_read("byte", word + 3)
                    if ((low == 0xFB and high == 0xFF) or (low == 1 and high == 0)) and memory_read("byte", word + 5) == memory_read("byte", word + 1) and memory_read("int", word + 8) == accelerationKey then
                        SWIMMER.patch(word + 2, "byte", 0xFB, 0)
                        SWIMMER.patch(word + 3, "byte", 0xFF, 0)
                        break
                    end
                end
            end
            SWIMMER.patchCoinReach()
            SWIMMER.Ready = true
            return true
        end
    end
    return false
end

function SWIMMER.patchCoinReach()
    for _, Entry in ipairs(getgc("HasClearedFish") or {}) do
        local slot = Entry.addr
        local tickSlot = slot and SWIMMER.sibling(slot, "tick")
        local O = GOLDEN.Offsets
        if tickSlot and memory_read("int", slot + O.ValueTag) == O.FunctionTag and memory_read("int", tickSlot + O.ValueTag) == O.FunctionTag then
            local closure = memory_read("uintptr_t", tickSlot)
            local proto = GOLDEN.heap(closure) and GOLDEN.read(closure, "Proto")
            local base = GOLDEN.heap(proto) and GOLDEN.read(proto, "Constants")
            local count = GOLDEN.heap(proto) and memory_read("int", proto + O.ConstantCount)
            if base and base > 0x10000 and count and count > 0 and count < 128 then
                local Names = GOLDEN.named(proto)
                local Magnitude, X = Names["Magnitude"], Names["X"]
                if Magnitude and X then
                    SWIMMER.patch(Magnitude.Slot, "uintptr_t", Magnitude.Pointer, X.Pointer)
                    return true
                end
            end
        end
    end
    return false
end

function SWIMMER.restore()
    GOLDEN.unpatch(SWIMMER.Patches)
    SWIMMER.Patches = {}
    SWIMMER.Ready = false
end

function SWIMMER.update()
    if not SETTINGS.betterBarnaby then
        if SWIMMER.Ready and not SWIMMER.Busy then SWIMMER.restore() end
        SWIMMER.Attempts = 0
        return false
    end
    if PLACE_MODE ~= "main" then return false end
    local world = getBarnabyWorld()
    if not world then return false end
    if SWIMMER.Busy or not VantaUI.MemoryAccess() then return true end
    if not SWIMMER.Ready then
        local now = tick()
        if not GOLDEN.Map.Luau then return false end
        if now >= SWIMMER.NextScan and SWIMMER.Attempts < 3 then
            SWIMMER.NextScan = now + 10
            SWIMMER.Attempts = SWIMMER.Attempts + 1
            SWIMMER.Busy = true
            task.spawn(function()
                pcall(SWIMMER.setup)
                if not SETTINGS.betterBarnaby or GOLDEN.Stopped then SWIMMER.restore() end
                SWIMMER.Busy = false
            end)
        end
        return true
    end
    return true
end

local function doAutoBarnaby()
    if SETTINGS.betterBarnaby or SWIMMER.Ready then
        local handled = SWIMMER.update()
        if SETTINGS.betterBarnaby and PLACE_MODE == "main" then return handled end
    end

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

    if BARNABY.track.y == nil then
        barnabyRefreshGravity()
    end

    local now = tick()
    barnabyTrackUpdate(now, fishPosition.Y)
    local y, velocity = advanceBarnaby(BARNABY.track.y, BARNABY.track.v, now - BARNABY.track.t)

    local signature = 0
    for _, obstacle in ipairs(obstacles) do
        signature = signature + obstacle.x
    end

    if BARNABY.obstacleSignature ~= nil and math.abs(signature - BARNABY.obstacleSignature) > 0.001 then
        BARNABY.lastMotion = now
    end
    BARNABY.obstacleSignature = signature

    if not SETTINGS.autoBarnaby or #obstacles == 0 or now - BARNABY.lastMotion > BARNABY.STALL_TIMEOUT then
        return true
    end

    if not robloxFocused() then
        if not BARNABY.focusWarned and type(notify) == "function" then
            BARNABY.focusWarned = true
            pcall(notify, "Auto Barnaby", "Roblox is not focused - click its window so jumps go through.", 4)
        end
        return true
    end

    local risky = SETTINGS.barnabyCollectCoins and SETTINGS.barnabyRiskyCoins
    BARNABY.PRESS_GAP = risky and BARNABY.RISKY_PRESS_GAP or BARNABY.SAFE_PRESS_GAP
    BARNABY.COIN_REWARD = risky and BARNABY.RISKY_COIN_REWARD or BARNABY.SAFE_COIN_REWARD
    BARNABY.SAFE_MARGIN = risky and BARNABY.RISKY_SAFE_MARGIN or BARNABY.SAFE_SAFE_MARGIN

    if now - BARNABY.lastPress < BARNABY.PRESS_GAP then
        return true
    end

    if now - BARNABY.lastDecision < BARNABY.DECISION_INTERVAL then
        return true
    end
    BARNABY.lastDecision = now

    local fishSize = fish.Size
    local fishRadius = (fishSize and fishSize.X or 1) * 0.5

    if barnabyShouldJump(y, velocity, fishPosition.X, fishRadius, obstacles, BARNABY.DEFER_SPACING, SETTINGS.barnabyCollectCoins) then
        pressSpace(BARNABY.PRESS_HOLD)
        BARNABY.lastPress = now
    end

    return true
end

local function doAutoSquirmEscape()
    if not SETTINGS.autoSquirmEscape or PLACE_MODE ~= "main" then
        return false
    end

    if not (SQUIRM.lastSide or UI.roster().Names.SquirmMonster) then
        return false
    end

    local character = LocalPlayer and LocalPlayer.Character

    if not (character and character:GetAttribute("GrabbedBySquirm")) then
        SQUIRM.lastSide = nil
        return false
    end

    local now = tick()

    if KEYS.Held[SQUIRM.VK_LEFT] or KEYS.Held[SQUIRM.VK_RIGHT] or now < SQUIRM.nextPressAt then
        return true
    end

    local useLeft = SQUIRM.lastSide ~= "left"
    local key = useLeft and SQUIRM.VK_LEFT or SQUIRM.VK_RIGHT
    if not KEYS.hold(key, SQUIRM.HOLD) then
        return true
    end
    SQUIRM.lastSide = useLeft and "left" or "right"
    SQUIRM.nextPressAt = now + math.max(1 / (SETTINGS.squirmTapRate or 14), SQUIRM.MIN_GAP)

    return true
end

local function doAutoSkillCheck()
    local now = os.clock()
    if not UI.SkillBusy and now < UI.SkillIdleAt then
        return
    end
    UI.SkillIdleAt = now + 1 / 60
    UI.SkillBusy = false

    if doAutoBarnaby() then
        UI.SkillBusy = true
        return
    end

    if PLACE_MODE ~= "main" or not (SETTINGS.autoSkillCheck or SETTINGS.alwaysGolden) then
        return
    end

    if SETTINGS.autoSkillCheck and doTreadmillTapSkillCheck(now) then
        UI.SkillBusy = true
        return
    end

    if now - SKILL.lastPress < SKILL.PRESS_COOLDOWN then
        UI.SkillBusy = true
        return
    end

    local parts = getSkillCheckFrame()
    if not parts then
        return
    end
    UI.SkillBusy = true

    local golden = GOLDEN.active(parts)
    if not golden and not SETTINGS.autoSkillCheck then return end
    if golden and parts.circle then
        pcall(GOLDEN.stretch, parts)
        return
    end

    local press = shouldPressSkillCheck(parts, golden and 0 or SETTINGS.skillCheckLead)

    if press then
        if golden then
            pcall(GOLDEN.cut, parts)
        else
            pressSpace()
        end
        SKILL.lastPress = now
    end
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

    if ok and primaryPart and isVisualPart(primaryPart) then
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

    local okMachine, minigame = pcall(function() return instance:GetAttribute("MinigameType") end)
    if okMachine and minigame then
        local Prompt = instance:FindFirstChild("Prompt")
        if Prompt and readPosition(Prompt) then return Prompt end
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

local function sourceBelongs(source, item)
    local ok, inside = pcall(function()
        return tostring(source.Address) == tostring(item.Address) or source:IsDescendantOf(item)
    end)
    return ok and inside == true
end

local function getVisualPosition(visual)
    local source = visual.positionSource
    if source and tick() >= (visual.sourceCheckAt or 0) then
        visual.sourceCheckAt = tick() + 2.5 + math.random()
        if not sourceBelongs(source, visual.item) then
            source = nil
            visual.positionSource = nil
            visual.nextResolveAt = nil
        end
    end
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

local function createVisual(item, category, roomName)
    local color = COLORS[category]
    local alertKey, alertKind = alertKeyFor(category, item.Name)
    local lines = {}

    for index = 1, LABEL_LINES do
        lines[index] = { drawing = makeText(LABEL_LINE_HEIGHT, color), text = nil, visible = false }
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
        abilityDraw = makeText(ABILITY.TEXT_SIZE, color)
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

local function visualIsCompleted(visual)
    if visual.category ~= "Generators" then
        return false
    end

    local now = tick()
    if now - visual.completionCheckedAt < COMPLETION_TTL then
        return visual.completed
    end

    visual.completionCheckedAt = now
    if not (visual.doneHolder and visual.doneHolder.Parent) then
        local stats = visual.item:FindFirstChild("Stats")
        visual.doneHolder = UI.completed(stats)
    end
    local ok, value = pcall(UI.bool, visual.doneHolder)
    visual.completed = ok and value == true
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

            if not visual.useHolders then
                local stats = visual.item:FindFirstChild("Stats")
                visual.useHolders = stats and {stats:FindFirstChild("ActivePlayer"), stats:FindFirstChild("ActivePlayer2")} or nil
            end
            local holders = visual.useHolders
            local localName = LocalPlayer and LocalPlayer.Name

            if holders then
                local slots = holders[2] and 2 or 1
                local taken = 0
                local byOther = false

                for index = 1, slots do
                    local holder = holders[index]
                    local occupantName = UI.valuePlayer(holder)

                    if occupantName then
                        taken = taken + 1
                        if occupantName ~= localName then
                            byOther = true
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

local function researchCapsuleMonster(item)
    local prompt = item:FindFirstChild("Prompt")
    local holder = prompt and prompt:FindFirstChild("Monster")
    return holder and STRINGS.clean(STRINGS.read(holder)) or nil
end

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
        elseif visual.category == "Doors" then
            name = DOOR_INFO.name
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

        local now = tick()
        if now >= (visual.fillAt or 0) then
            visual.fillAt = now + 0.25
            visual.fillValue = UI.read(visual.fillCurrent)
            visual.fillMax = UI.read(visual.fillRequired)
        end
        local current = visual.fillValue
        local required = visual.fillMax
        if UI.fill(current, required) then
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

local function doorUsed(door)
    local ok, used = pcall(function()
        return door:GetAttribute("TrickOrTreatUsed")
    end)
    return ok and used == true
end

local function categoryForChild(folderKey, child)
    if folderKey == "HolidayPickups" then return "Special" end
    if folderKey == "TrickOrTreatDoors" then return not doorUsed(child) and "Doors" or nil end
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

local function scanFolder(children, folderKey, roomName)
    for _, child in ipairs(children) do
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

    local present = {}
    local monsterHits = newHitList()
    local itemHits = newHitList()
    local monsterAlertsOn = anyAlertEnabled(ALERT_MONSTERS)
    local itemAlertsOn = anyAlertEnabled(ALERT_ITEMS)
    local blotOn = SETTINGS.showMonsters or alertEnabledFor("Monsters", "BlottMonster")

    for _, room in ipairs(currentRoom:GetChildren()) do
        local blot = false
        for _, folderInfo in ipairs(FOLDERS) do
            local key = folderInfo.key
            local wanted = anyEnabled(folderInfo.enabledKeys)
                or (monsterAlertsOn and key == "Monsters")
                or (itemAlertsOn and (key == "Items" or key == "HolidayPickups" or key == "TrickOrTreatDoors"))
            if wanted or key == "Monsters" or key == "Items" or key == "HolidayPickups" or key == "TrickOrTreatDoors" then
                local folder = room:FindFirstChild(key)
                if folder then
                    local children = folder:GetChildren()
                    if key == "Monsters" then
                        for _, child in ipairs(children) do
                            checkAlert(present, monsterHits, child, ALERT_BY_MONSTER[child.Name], MONSTER_INFO)
                            if child.Name == "BlottMonster" then blot = true end
                        end
                    elseif key == "Items" or key == "HolidayPickups" then
                        for _, child in ipairs(children) do
                            checkAlert(present, itemHits, child, ALERT_BY_ITEM[child.Name], ITEM_INFO)
                        end
                    elseif key == "TrickOrTreatDoors" then
                        for _, child in ipairs(children) do
                            if not doorUsed(child) then checkAlert(present, itemHits, child, "itemAlertDoors", DOOR_INFO) end
                        end
                    end
                    if wanted then
                        scanFolder(children, key, room.Name)
                    end
                end
            end
        end

        if blot and blotOn then
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

    alertSeen = present
    announceAlerts(monsterHits, itemHits)

    for key, visual in pairs(tracked) do
        if not activeKeys[key] or not visual.item.Parent then
            removeVisual(visual)
            tracked[key] = nil
        end
    end
end

local function uiValue(id, fallback)
    local value = UI.GetValue(id)
    if value == nil then
        return fallback
    end

    return value
end

local function refreshSettingsFromUi()
    for id, Bind in pairs(UI.Binds) do
        local value = UI.GetValue(id)
        if value ~= nil then
            SETTINGS[Bind.Key] = Bind.Map and Bind.Map(value) or value
        end
    end

    local twisteds = uiValue("dw_alert_twisteds", nil)
    if twisteds then
        for _, entry in ipairs(ALERT_MONSTERS) do
            SETTINGS[entry.key] = twisteds[entry.label] == true
        end
    end

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

    local Seen = {}
    local fresh = false
    for _, Tendril in ipairs(UI.sproutTendrils(map)) do
        local address = tostring(Tendril.Address)
        Seen[address] = true
        if not (entry.tendrils and entry.tendrils[address]) then fresh = true end
    end
    entry.tendrils = Seen
    return fresh
end

function ABILITY.pollDebuff(spec, now)
    if now - spec.checkedAt < ABILITY.POLL_INTERVAL then
        return
    end

    spec.checkedAt = now
    local seen = spec.seen
    local current = {}
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

            current[key] = { marks = marks, hadPending = hadPending }
        end
    end

    spec.seen = current
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
            entry.readyAt = now + entry.cooldown - ABILITY.SPROUT_DELAY - 0.1
        end

        return
    end

    if not (entry.root and entry.root.Parent) then
        entry.root = model:FindFirstChild("HumanoidRootPart")
    end
    local root = entry.root
    local active = root ~= nil and root:FindFirstChild(ABILITY.WINDUP_SOUND) ~= nil

    if not active then
        active = model:GetAttribute("UsingAbility") == true
    end

    if not active then
        if not (entry.grabbing and entry.grabbing.Parent) then
            entry.grabbing = model:FindFirstChild("Grabbing")
        end
        active = entry.grabbing ~= nil and UI.bool(entry.grabbing) == true
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
                UI.folder(ABILITY.ICON_FOLDER)
                pcall(writefile, path, data)
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
        card.name = makeText(P.NAME_SIZE, white, false)
        local info = MONSTER_INFO[entry.name]
        safeSet(card.name, "Text", (info and info.name) or entry.name)

        card.timer = makeText(P.TIMER_SIZE, white, false)

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
            card.missing = makeText(ABILITY.MISSING_SIZE, white)
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

function PLAYERS.makeLine()
    return { drawing = makeText(PLAYERS.TEXT_SIZE, PLAYERS.WHITE), text = nil, low = nil, visible = false }
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
    if not character then
        PLAYERS.hide(entry)
        return
    end

    local address = character.Address
    if entry.charAddress ~= address or not (entry.maximum and entry.root and entry.root.Parent) then
        entry.charAddress = address
        entry.root = character:FindFirstChild("HumanoidRootPart")
        entry.humanoid = character:FindFirstChild("Humanoid")
        local stats = character:FindFirstChild("Stats")
        entry.current = stats and stats:FindFirstChild("CurrentStamina")
        entry.maximum = stats and stats:FindFirstChild("Stamina")
    end
    local root, humanoid, current, maximum = entry.root, entry.humanoid, entry.current, entry.maximum

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
        local stamina = UI.read(current) or 0
        local text = math.floor(stamina + 0.5) .. "/" .. math.floor((UI.read(maximum) or 0) + 0.5) .. " SP"
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

    if now < (PLAYERS.drawAt or 0) then
        return
    end
    PLAYERS.drawAt = now + SETTINGS.updateInterval

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
    if FARM.Debug.Enabled then table.insert(specs, { text = "", size = B.BODY_SIZE }) end

    local banner = { lines = {}, height = 0, x = 0.5, y = 0.5, moveAt = 0, keyText = nil, statusText = nil }

    for index, spec in ipairs(specs) do
        local drawing = makeText(spec.size)
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
    if down and not FARM.pauseDown and not gameTyping() then
        FARM.pauseWanted = not FARM.pauseWanted
    end
    FARM.pauseDown = down
end

function FARM.statusText(now)
    if FARM.paused then
        return "Paused"
    end
    if FARM.pauseWanted then
        return "Pausing after leaving cover"
    end
    if FARM.UNSAFE.missing then
        return "Unsafe LuaU is required."
    end
    if not robloxFocused() then
        return "Roblox is not focused"
    end

    if FARM.RUN.Mapping then
        return string.format("Mapping the room %d%%", math.floor(FARM.RUN.Mapping * 100))
    end

    local elapsed = now - FARM.armedAt
    if elapsed < FARM.BANNER.STARTUP then
        return "Starts in " .. math.ceil(FARM.BANNER.STARTUP - elapsed) .. "s"
    end

    return FARM.status or "Working"
end

function FARM.running(now)
    return FARM.active and not FARM.paused and now - FARM.armedAt >= FARM.BANNER.STARTUP
end

function FARM.setStatus(text)
    FARM.status = text
end

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

function FARM.health()
    local humanoid = UI.myPart("Humanoid")
    local ok, health, maxHealth = pcall(function()
        return humanoid.Health, humanoid.MaxHealth
    end)
    if ok and type(health) == "number" and type(maxHealth) == "number" then return health, maxHealth end
    return nil, nil
end

function FARM.stamina()
    local ok, current, maximum = pcall(function()
        return UI.read(UI.myStat("CurrentStamina")), UI.read(UI.myStat("Stamina"))
    end)
    if ok and type(current) == "number" and type(maximum) == "number" then return current, maximum end
    return nil, nil
end

function FARM.MASTERY.useItems(now, character)
    local M = FARM.MASTERY
    local R = FARM.RUN
    local health, maxHealth = FARM.health()
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
    local map = UI.map()
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
    local health, maxHealth = FARM.health()
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
    local map = UI.map()
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
    local ok, address = pcall(function()
        return tonumber(label.Address)
    end)
    return ok and address and STRINGS.memory(address + FARM.MASTERY.TEXT) or ""
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

function FARM.cursorCalibrate()
    local C = FARM.CURSOR
    local Mouse = LocalPlayer and LocalPlayer:GetMouse()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
    if not (Mouse and viewport) or not robloxFocused() then return false end
    local Samples = {}
    for _, point in ipairs({{0.3, 0.3}, {0.7, 0.7}, {0.5, 0.45}}) do
        local x, y = math.floor(viewport.X * point[1]), math.floor(viewport.Y * point[2])
        mousemoveabs(x, y)
        task.wait(0.2)
        local mouseX, mouseY = Mouse.X, Mouse.Y
        if not robloxFocused() or type(mouseX) ~= "number" or type(mouseY) ~= "number" then return false end
        table.insert(Samples, {X = x, Y = y, MouseX = mouseX, MouseY = mouseY})
    end
    local first, second, third = Samples[1], Samples[2], Samples[3]
    local scaleX = (second.MouseX - first.MouseX) / (second.X - first.X)
    local scaleY = (second.MouseY - first.MouseY) / (second.Y - first.Y)
    if scaleX < 0.3 or scaleX > 3 or scaleY < 0.3 or scaleY > 3 then return false end
    local offsetX, offsetY = first.MouseX - scaleX * first.X, first.MouseY - scaleY * first.Y
    if math.abs(scaleX * third.X + offsetX - third.MouseX) > 4 or math.abs(scaleY * third.Y + offsetY - third.MouseY) > 4 then return false end
    C.Map = {ScaleX = scaleX, ScaleY = scaleY, OffsetX = offsetX, OffsetY = offsetY}
    C.At, C.Viewport = tick(), viewport
    return true
end

function FARM.cursorReady()
    local C = FARM.CURSOR
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
    if C.Map and tick() - C.At < 300 and viewport and C.Viewport and viewport.X == C.Viewport.X and viewport.Y == C.Viewport.Y then return true end
    if tick() < C.RetryAt then return true end
    if C.Busy or not KEYS.allowed() then return false end
    C.Busy = true
    task.spawn(function()
        if FARM.cursorCalibrate() then
            C.Failures = 0
        else
            C.Failures = C.Failures + 1
            if C.Failures >= 3 then C.Failures, C.RetryAt = 0, tick() + 60 end
        end
        C.Busy = false
    end)
    return false
end

function FARM.guiScale(gui)
    local C = FARM.CURSOR
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
    local Root = gui
    for _ = 1, 40 do
        if not Root or Root.ClassName == "ScreenGui" then break end
        Root = Root.Parent
    end
    if viewport and Root and VantaUI.MemoryAccess() then
        local ok, width, height = pcall(function()
            local address = tonumber(Root.Address) + FARM.GUI.positionOffset + 8
            return memory_read("float", address), memory_read("float", address + 4)
        end)
        local scale = ok and type(width) == "number" and type(height) == "number" and width > 0 and height > 0 and viewport.X / width
        if scale and scale >= 0.5 and scale <= 4 then
            C.GuiScale = scale
            return scale, viewport.Y - height * scale
        end
    end
    return C.GuiScale or 1, 0
end

function FARM.cursorPoint(gui, x, y)
    local Map = FARM.CURSOR.Map
    if not Map then return math.floor(x) + 1, math.floor(y) + 24 end
    local scale, inset = FARM.guiScale(gui)
    local mouseX, mouseY = x * scale, y * scale + inset
    return math.floor((mouseX - Map.OffsetX) / Map.ScaleX + 0.5), math.floor((mouseY - Map.OffsetY) / Map.ScaleY + 0.5)
end

function FARM.MASTERY.centre(gui)
    local position, size = gui.AbsolutePosition, FARM.guiSize(gui)
    return math.floor(position.X + size.X / 2 + 0.5), math.floor(position.Y + size.Y / 2 + 0.5)
end

function FARM.MASTERY.moveTo(gui, x, y)
    mousemoveabs(FARM.cursorPoint(gui, x, y))
end

function FARM.MASTERY.calibrate()
    for _ = 1, 3 do
        if FARM.cursorCalibrate() then return true end
        task.wait(0.2)
    end
    return false
end

function FARM.MASTERY.box(gui)
    local ok, x, y, w, h = pcall(function()
        local position, size = gui.AbsolutePosition, FARM.guiSize(gui)
        return position.X, position.Y, size.X, size.Y
    end)
    if not ok or type(x) ~= "number" or type(w) ~= "number" then return nil end
    return string.format("%.1f,%.1f,%.1f,%.1f", x, y, w, h)
end

function FARM.MASTERY.settle(gui)
    local M = FARM.MASTERY
    local last, steady = M.box(gui), 0
    local deadline = tick() + 2
    while tick() < deadline do
        task.wait(0.08)
        local now = M.box(gui)
        steady = (now ~= nil and now == last) and steady + 1 or 0
        last = now
        if steady >= 2 then return true end
    end
    return false
end

function FARM.MASTERY.hover(gui)
    local M = FARM.MASTERY
    return M.waitFor(function()
        local state = M.byte(gui, M.STATE)
        return state == 1 or state == 2
    end, 0.3)
end

function FARM.MASTERY.click(gui, delay)
    local M = FARM.MASTERY
    if not M.waitFocus() then return false end
    if not M.shown(gui) then return false end
    M.settle(gui)
    local x, y = M.centre(gui)
    M.moveTo(gui, x, y)
    task.wait(0.03)
    mousemoverel(1, 0)
    local hovered = M.hover(gui)
    if not hovered then
        M.settle(gui)
        x, y = M.centre(gui)
        M.moveTo(gui, x, y)
        task.wait(0.03)
        mousemoverel(1, 0)
        hovered = M.hover(gui)
    end
    if not hovered then return false end
    if delay then task.wait(delay) end
    mouse1click()
    task.wait(0.15)
    return true
end

function FARM.MASTERY.clickUntil(gui, check, timeout, tries, delay)
    local M = FARM.MASTERY
    for _ = 1, tries or 3 do
        if M.stop then return false end
        if not M.click(gui, delay) then
            task.wait(0.3)
        elseif M.waitFor(check, timeout) then
            return true
        end
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
    local MainGui = UI.playerGui():FindFirstChild("MainGui")
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
        M.moveTo(ui.cards, x, y)
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
        return toonName ~= nil and TOON.RULES[toonName] ~= nil
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
        M.select(ui, chosen)
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
        local toonName = TOON.character(char)
        if not toonName then return nil end
        local Folder = game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Mastery:FindFirstChild(toonName)
        if not Folder then return nil end
        local left, total, types, reach = 0, 0, {}, nil
        for _, Quest in ipairs(Folder:GetChildren()) do
            local Current, Amount = Quest:FindFirstChild("Current"), Quest:FindFirstChild("Amount")
            if Current and Amount then
                total = total + 1
                local questType = M.questType(Quest.Name, "")
                if M.canDo(questType, toonName) and UI.read(Current) < UI.read(Amount) then
                    types[questType] = true
                    if questType == "ReachFloor" then reach = UI.read(Amount) end
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
    local wanted = SETTINGS.masteryFarm and PLACE_MODE == "lobby" and FARM.running(tick()) and not FARM.pauseWanted
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

function FARM.measureSpeed(now)
    local Meter = FARM.SpeedMeter
    if now < Meter.At then return Meter.Value end
    Meter.At = now + Meter.Every
    local root = UI.myPart("HumanoidRootPart")
    local ok, p = pcall(function()
        return root.Position
    end)
    if not ok or not p then return Meter.Value end
    local R = FARM.RUN
    if Meter.Position and now > Meter.Time then
        Meter.Value = FARM.flatDistance(Meter.Position, p) / (now - Meter.Time)
        local target = FARM.travelSpeed(now)
        if R.TrimPhases[R.phase] and Meter.Phase == R.phase and Meter.Value > target * 0.6 and Meter.Value < target * 2 then
            R.SpeedTrim = math.clamp(R.SpeedTrim * math.clamp(target / Meter.Value, 0.85, 1.15), R.TrimMin, R.TrimMax)
        end
    end
    Meter.Position, Meter.Time, Meter.Phase = p, now, R.phase
    return Meter.Value
end

function FARM.speedText(now)
    return string.format("Speed %.1f / target %.1f / limit %.1f", FARM.measureSpeed(now), FARM.travelSpeed(now), FARM.runSprintSpeed(now))
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

    FARM.measureSpeed(now)
    if banner.lines[5] then
        local speedText = FARM.speedText(now)
        if banner.speedText ~= speedText then
            banner.speedText = speedText
            banner.lines[5].drawing.Text = speedText
        end
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

function FARM.writeResume()
    if FARM.resumeWritten or not SETTINGS.farmAutoResume then
        return
    end

    SETTINGS.resumeAutoFarm = true
    SETTINGS.resumeAutoFarmAt = UI.clock()
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
    local age = UI.clock() - (SETTINGS.resumeAutoFarmAt or 0)

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
            pcall(UI.SetValue, FARM.TOGGLE_ID, true)
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
            pcall(UI.SetValue, FARM.TOGGLE_ID, false)
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

    if PLACE_MODE == "main" then pcall(FARM.coverPreload) end

    if FARM.active then
        FARM.pollPause()

        if FARM.pauseWanted and not FARM.paused then
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

        if FARM.running(now) then
            if PLACE_MODE == "lobby" and (FARM.MASTERY.running or (SETTINGS.masteryFarm and FARM.UNSAFE.enabled and not FARM.MASTERY.done)) then
                FARM.lobbyStop()
            elseif PLACE_MODE == "lobby" then
                FARM.lobbyUpdate(now)
            elseif PLACE_MODE == "main" then
                local started = os.clock()
                FARM.runUpdate(now)
                FARM.debugTrace(os.clock() - started)
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
    local folder = UI.elevators()
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
    local folder = UI.elevators()
    local gate = folder and folder:FindFirstChild(gateName)
    local elevator = gate and gate:FindFirstChild("Elevator")
    local opened = elevator and elevator:FindFirstChild("Opened")
    return (opened and UI.bool(opened)) or false
end

function FARM.gateInside(gateName)
    local root = UI.myPart("HumanoidRootPart")
    local folder = UI.elevators()
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

function FARM.releaseKeys()
    local VK = FARM.LOBBY.VK
    for _, code in ipairs({VK.W, VK.A, VK.S, VK.D}) do
        KEYS.set(code, false)
    end
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

    KEYS.set(L.VK.W, forward > L.THRESHOLD)
    KEYS.set(L.VK.S, forward < -L.THRESHOLD)
    KEYS.set(L.VK.D, side > L.THRESHOLD)
    KEYS.set(L.VK.A, side < -L.THRESHOLD)
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

function FARM.isSprinting()
    local flag = UI.myStat("HoldingSprint") or UI.myStat("Sprinting")
    if not flag then
        return false
    end

    local ok, value = pcall(function()
        return UI.bool(flag)
    end)

    return ok and value == true
end

function FARM.sprintSetting()
    local ok, value = pcall(function()
        return UI.bool(game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].SprintToggle)
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
            KEYS.set(FARM.LOBBY.SHIFT, false)
        end
        return
    end

    if L.sprintMode == nil then
        if L.sprintStage == 0 then
            if FARM.isSprinting() then
                return
            end

            KEYS.set(FARM.LOBBY.SHIFT, true)
            L.sprintStage = 1
            L.sprintAt = now + L.SPRINT_PROBE
        elseif L.sprintStage == 1 and now >= L.sprintAt then
            KEYS.set(FARM.LOBBY.SHIFT, false)
            L.sprintStage = 2
            L.sprintAt = now + L.SPRINT_PROBE
        elseif L.sprintStage == 2 and now >= L.sprintAt then
            L.sprintMode = FARM.isSprinting() and "toggle" or "hold"
            L.sprintStage = 3
        end

        return
    end

    if L.sprintMode == "hold" then
        KEYS.set(FARM.LOBBY.SHIFT, true)
        return
    end

    if not FARM.isSprinting() and now >= L.sprintNextAt then
        L.sprintNextAt = now + L.SPRINT_RETAP
        KEYS.tap(L.SHIFT)
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

function FARM.lobbyReset()
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
            FARM.lobbyReset()
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

    if not UI.elevators() then
        FARM.releaseKeys()
        FARM.setStatus("Not in the lobby")
        return
    end

    local character = LocalPlayer.Character
    local root = character and UI.myPart("HumanoidRootPart")
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
            if KEYS.tap(L.VK.ESC) then
                L.resetStage = 2
                L.at = now + 0.4
            end
        elseif L.resetStage == 2 and now >= L.at then
            if KEYS.tap(L.VK.R) then
                L.resetStage = 3
                L.at = now + 0.4
            end
        elseif L.resetStage == 3 and now >= L.at and KEYS.tap(L.VK.ENTER) then
            L.resetFrom = character and getIdentity(character)
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

        local folder = UI.elevators()
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
            L.phase = "leave"
            L.at = now
            L.leaveClick.stage = 0
            FARM.setStatus("Leaving, someone joined")
        elseif count == 0 and not FARM.gateInside(gateName) then
            FARM.lobbyNext()
        end
        return
    end

    if L.phase == "leave" and now >= L.at then
        local gui = UI.playerGui()
        local main = gui and gui:FindFirstChild("MainGui")
        local button = main and main:FindFirstChild("leaveButton")
        if not button then
            L.leaveClick.stage = 0
            FARM.lobbyGoHub()
            return
        end
        if FARM.clickStep(L.leaveClick, now, button, 1.2, 0.1, L.CLICK_HOLD) then
            local gateName = L.GATE_OF[L.target]
            if FARM.gateCount(gateName) == 0 or not FARM.gateInside(gateName) then
                L.atNode = L.target
                FARM.lobbyNext()
            else
                L.at = now + 0.3
            end
        end
    end
end

function FARM.lobbyStop()
    local L = FARM.LOBBY
    KEYS.set(FARM.LOBBY.SHIFT, false)
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

    if down then
        if KEYS.mouse(mouse2press) then R.rmbDown = true end
    else
        R.rmbDown = false
        pcall(mouse2release)
    end
end

function FARM.runHoldW(down)
    local R = FARM.RUN
    if down and KEYS.Held[R.W_KEY] and type(iskeypressed) == "function" then
        local ok, pressed = pcall(iskeypressed, R.W_KEY)
        local now = tick()
        if ok and pressed == false and now >= (R.wRepressAt or 0) and KEYS.allowed() then
            R.wRepressAt = now + 0.2
            pcall(keypress, R.W_KEY)
        end
        return
    end

    KEYS.set(R.W_KEY, down)
end

function FARM.runCollide(on)
    local R = FARM.RUN
    if not UI.me() then
        return
    end

    R.noCollide = not on
    if on then R.InCover = nil end
    for _, name in ipairs({ "HumanoidRootPart", "Torso" }) do
        local part = UI.myPart(name)
        if part then
            pcall(function()
                part.CanCollide = on
            end)
        end
    end
end

function FARM.runFreeze(root)
    local R = FARM.RUN
    local now = tick()
    if now < (R.freezeAt or 0) then
        return
    end
    pcall(function()
        local v = root.AssemblyLinearVelocity
        if math.abs(v.X) + math.abs(v.Y) + math.abs(v.Z) > 0.05 then
            R.freezeAt = now + R.FREEZE_EVERY
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
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
    KEYS.mouse(mousemoverel, math.floor(math.clamp(err * R.GAIN, -R.MAX_STEP, R.MAX_STEP)), 0)
    return false, err
end

function FARM.currentFloor()
    local info = UI.info()
    local value = info and info:FindFirstChild("Floor")
    local ok, floor = pcall(function()
        return UI.read(value)
    end)

    return (ok and floor) or 0
end

function FARM.travelSpeed(now)
    local R = FARM.RUN
    local multiplier = tonumber(SETTINGS.farmSpeedMultiplier) or R.SprintMultiplier
    local speed = FARM.runSprintSpeed(now) * math.clamp(multiplier, 1, R.SprintMultiplierMax)
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

function FARM.runMachines()
    local map = UI.map()
    local now = tick()
    local address = map and tostring(map.Address)
    local Cache = FARM.MACHINES
    if Cache and Cache.Address == address and now < Cache.At then return Cache.List end
    local out = FARM.runMachinesRead(map)
    FARM.MACHINES = {Address = address, At = now + 3, List = out}
    return out
end

function FARM.runMachinesRead(map)
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
            local done = UI.completed(stats)
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
        return UI.read(machine.cur)
    end)
    local okReq, req = pcall(function()
        return UI.read(machine.req)
    end)
    if not (okCur and okReq and UI.fill(cur, req)) then return 0, 1, false end
    return cur, req, true
end

function FARM.runConnie(machine)
    local ok, value = pcall(function()
        return UI.bool(machine.connie)
    end)
    return ok and value == true
end

function FARM.floorDone()
    local need = UI.infoValue("RequiredGenerators", 0.25)
    local done = UI.infoValue("GeneratorsCompleted", 0.25)
    return type(need) == "number" and type(done) == "number" and need >= 1 and need < 100 and done >= need
end

function FARM.runDone(machine)
    if FARM.floorDone() then return true end
    local ok, value = pcall(function()
        return UI.bool(machine.done)
    end)
    return ok and value == true
end

function FARM.runEngagedBy(machine)
    if not machine.active then
        return "none"
    end

    return UI.valuePlayer(machine.active) or "none"
end

function FARM.runTaken(machine)
    local who = FARM.runEngagedBy(machine)
    return who ~= "none" and who ~= LocalPlayer.Name
end

function FARM.runItemKey(value)
    return string.lower((string.gsub(tostring(value or ""), "[^%w]", "")))
end

function FARM.runInventory(character)
    local Last = UI.Me
    if Last and Last.InventoryFrame == UI.Frame and Last.InventoryFor == character then return Last.Inventory end
    local Me = UI.me()
    local mine = Me ~= nil and Me.Address == character.Address
    if mine and Me.InventoryFrame == UI.Frame then return Me.Inventory end
    local folder = mine and UI.myPart("Inventory") or character:FindFirstChild("Inventory")
    local slots = {}
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            local index = tonumber(string.match(child.Name, "^Slot(%d+)$"))
            if index then
                slots[#slots + 1] = { index = index, item = STRINGS.read(child) }
            end
        end
    end
    if mine then
        Me.InventoryFrame = UI.Frame
        Me.InventoryFor = character
        Me.Inventory = slots
    end
    return slots
end

function FARM.runPressItem(now, slot)
    local R = FARM.RUN
    if not slot or (R.itemKey and KEYS.Held[R.itemKey]) then
        return
    end

    R.itemKey = 0x30 + slot
    KEYS.hold(R.itemKey, R.KEY_HOLD)
end

function FARM.runReleaseItemKey(now, force)
    local R = FARM.RUN
    if R.itemKey and force then
        KEYS.set(R.itemKey, false)
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

function FARM.runTrinketReady(character, name)
    local Trinkets = character:FindFirstChild("Trinkets")
    if not Trinkets then return false end
    for _, Trinket in ipairs(Trinkets:GetChildren()) do
        if STRINGS.read(Trinket) == name then return UI.bool(Trinket:FindFirstChild("Active")) == true end
    end
    return false
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
    local info = UI.info()
    local stats = info and info:FindFirstChild("PlayerStats")
    local mine = stats and stats:FindFirstChild(LocalPlayer.Name)
    local points = mine and mine:FindFirstChild("SurvivalPoints")
    local ok, value = pcall(function()
        return UI.read(points)
    end)
    return (ok and type(value) == "number") and value or 0
end

function FARM.runStoreDiscount()
    local info = UI.info()
    local modifiers = info and info:FindFirstChild("CardModifiers")
    local card = modifiers and modifiers:FindFirstChild("DandyDiscount")
    local ok, value = pcall(function()
        return UI.read(card)
    end)
    if ok and type(value) == "number" and value > 0 and value < 1 then
        return value
    end
    return 1
end

function FARM.runPromptShows(name)
    local Gui = UI.playerGui():FindFirstChild("ProximityPrompts")
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
    local isOpen = UI.infoValue("DandyStoreOpen", 0.1)

    if isOpen ~= true then
        R.bought = {}
        return nil
    end

    if not FARM.runHasFreeSlot(character) then
        return nil
    end

    local masteryBuy = FARM.MASTERY.wants("BuyDandyStoreItem")
    local specific = FARM.MASTERY.specificItem()

    local folder = UI.elevators()
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
    local map = UI.map()
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

    local health, maxHealth = FARM.health()

    if not health or health <= 0 or health >= maxHealth then
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

function FARM.runSpecialMaxed()
    local R = FARM.RUN
    local now = tick()
    if R.SpecialMaxedAt and now < R.SpecialMaxedAt then return R.SpecialMaxedValue end
    R.SpecialMaxedAt = now + R.SpecialMaxedEvery
    local maxed = false
    for _, attribute in ipairs(R.SpecialMaxed) do
        local ok, value = pcall(function()
            return LocalPlayer:GetAttribute(attribute)
        end)
        if ok and value == true then
            maxed = true
            break
        end
    end
    R.SpecialMaxedValue = maxed
    return maxed
end

function FARM.runQuestCounts(Room)
    local R = FARM.RUN
    local Counts = {}
    for _, name in ipairs(R.QuestFolders) do
        local Folder = Room:FindFirstChild(name)
        Counts[name] = Folder and #Folder:GetChildren() or 0
    end
    return Counts
end

function FARM.runQuestScan(Room)
    local R = FARM.RUN
    local key = FARM.runKey(Room)
    if not key then return end
    if R.QuestMap == key and not R.QuestQueue and tick() >= (R.QuestCheckAt or 0) then
        R.QuestCheckAt = tick() + R.QuestRecheck
        local Counts = FARM.runQuestCounts(Room)
        for name, count in pairs(Counts) do
            if count ~= (R.QuestCounts and R.QuestCounts[name]) then
                R.QuestMap = nil
                break
            end
        end
    end
    if R.QuestMap ~= key then
        R.QuestMap = key
        R.QuestProps = {}
        R.QuestPrompts = {}
        R.QuestAt = 0
        R.QuestQueue = {}
        R.QuestIndex = 1
        R.QuestCounts = FARM.runQuestCounts(Room)
        R.QuestCheckAt = tick() + R.QuestRecheck
        for _, name in ipairs(R.QuestFolders) do
            local Folder = Room:FindFirstChild(name)
            for _, Child in ipairs(Folder and Folder:GetChildren() or {}) do
                table.insert(R.QuestQueue, Child)
            end
        end
    end
    local Queue = R.QuestQueue
    if Queue then
        local last = math.min(R.QuestIndex + R.QuestBatch - 1, #Queue)
        for i = R.QuestIndex, last do
            local Item = Queue[i]
            pcall(function()
                if Item.ClassName ~= "Model" or Item:GetAttribute("GourdyQuestStep") == nil then return end
                for _, word in ipairs(R.QuestSkip) do
                    if Item.Name:find(word) then return end
                end
                table.insert(R.QuestProps, Item)
            end)
        end
        R.QuestIndex = last + 1
        if R.QuestIndex > #Queue then
            R.QuestQueue = nil
            FARM.debugNote(string.format("quest props scanned: %d found in %d children", #R.QuestProps, #Queue))
        end
    end
    local now = tick()
    if now < R.QuestAt then return end
    R.QuestAt = now + R.QuestEvery
    local Prompts = {}
    for _, Prop in ipairs(R.QuestProps) do
        pcall(function()
            for _, Descendant in ipairs(Prop:GetDescendants()) do
                if Descendant.Name == "GourdyQuestPrompt" then
                    table.insert(Prompts, Descendant)
                    break
                end
            end
        end)
    end
    if #Prompts ~= #(R.QuestPrompts or {}) then FARM.debugNote(string.format("quest prompts live: %d of %d props", #Prompts, #R.QuestProps)) end
    R.QuestPrompts = Prompts
end

function FARM.runSpecialPart(Model)
    for _, Child in ipairs(Model:GetChildren()) do
        local name = Child.ClassName
        if name == "MeshPart" or name == "Part" or name == "UnionOperation" then return Child end
    end
    return nil
end

function FARM.runCollectTarget(root, character, itemsOnly)
    local R = FARM.RUN
    local map = UI.map()
    local folder = map and map:FindFirstChild("Items")
    if not folder then
        return nil
    end

    local mapKey = tostring(map.Address)
    if R.skipMap ~= mapKey then
        R.skipMap = mapKey
        R.skip = {}
        R.capsuleNames = {}
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
        elseif info and info.event and not itemsOnly and SETTINGS.farmEventItems then
            kind = "event"
        elseif model.Name == "ResearchCapsule" and not itemsOnly and (SETTINGS.farmCapsules or masteryCapsules or (SETTINGS.farmCapsulesResearch and FARM.capsuleForResearch(model))) then
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

    if not itemsOnly and SETTINGS.farmSpecialItems then
        for _, Prompt in ipairs(R.QuestPrompts or {}) do
            local ok, Part, position = pcall(function()
                return Prompt.Parent, Prompt.Parent.Position
            end)
            if ok and Part and position and not R.skip[FARM.runSpotKey(position)] then
                local d = (position - root.Position).Magnitude
                if not capsuleDistance or d < capsuleDistance then
                    bestCapsule, capsuleDistance = {model = Prompt, prompt = Part, kind = "quest", name = R.QuestName, spot = FARM.runSpotKey(position), standY = root.Position.Y}, d
                end
            end
        end
    end

    local Pickups = not itemsOnly and SETTINGS.farmSpecialItems and map:FindFirstChild("HolidayPickups")
    if Pickups and not FARM.runSpecialMaxed() then
        for _, Piece in ipairs(Pickups:GetChildren()) do
            local Part = FARM.runSpecialPart(Piece)
            local ok, position = pcall(function()
                return Part.Position
            end)
            if ok and position and not R.skip[FARM.runSpotKey(position)] then
                local d = (position - root.Position).Magnitude
                if not capsuleDistance or d < capsuleDistance then
                    bestCapsule, capsuleDistance = {model = Piece, prompt = Part, kind = "special", name = R.SpecialName, spot = FARM.runSpotKey(position), standY = root.Position.Y}, d
                end
            end
        end
    end

    local Doors = not itemsOnly and SETTINGS.farmTrickOrTreat and map:FindFirstChild("TrickOrTreatDoors")
    for _, Door in ipairs(Doors and Doors:GetChildren() or {}) do
        local Ground = Door:FindFirstChild("Ground")
        local ok, position = pcall(function()
            return Ground.Position
        end)
        if ok and position and not doorUsed(Door) and not R.skip[FARM.runSpotKey(position)] then
            local d = (position - root.Position).Magnitude
            if not capsuleDistance or d < capsuleDistance then
                bestCapsule, capsuleDistance = {model = Door, prompt = Ground, kind = "door", name = R.DoorName, spot = FARM.runSpotKey(position), standY = root.Position.Y}, d
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

    local health = FARM.health()

    if SETTINGS.farmHealItems and health and health > 0 and health <= R.HEAL_AT then
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

    if SETTINGS.farmExtractionItems and R.phase == "working" and R.current and FARM.runEngagedBy(R.current) == LocalPlayer.Name and not FARM.runTrinketReady(character, "VeeRemote") then
        local cur, req, valid = FARM.runFill(R.current)
        local valve = FARM.runSlotOf(character, "Valve")
        if valve and valid and cur < req then
            FARM.runPressItem(now, valve)
            R.useAt = now + R.USE_COOLDOWN
            FARM.setStatus("Using Valve")
            return
        end

        if valid and cur / req <= R.CABLE_MAX_FILL then
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
    local current, maximum = FARM.stamina()
    return current ~= nil and current >= maximum
end

function FARM.runNearRazzle(root)
    local R = FARM.RUN
    if not UI.roster().Names.RazzleDazzleMonster then
        return false
    end
    local map = UI.map()
    local monsters = map and map:FindFirstChild("Monsters")
    local razzle = monsters and monsters:FindFirstChild("RazzleDazzleMonster")
    local T = razzle and FARM.twisted(razzle)
    if not T then
        return false
    end
    local part = T.Part
    local ok, position = pcall(function()
        return part.Position
    end)
    return not ok or not position or Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z).Magnitude <= R.STAMINA_RAZZLE_RANGE
end

function FARM.runOnTreadmill(machine)
    if machine.minigame == nil then
        local ok, kind = pcall(function()
            return machine.model:GetAttribute("MinigameType")
        end)
        machine.minigame = ok and kind or false
    end
    return machine.minigame == "MovementTreadmill"
end

function FARM.runMachineKind(machine)
    if machine.kind == nil then
        local ok, value = pcall(function()
            local second = machine.slot == 2 and machine.model:GetAttribute("Prompt2MinigameType")
            return second or machine.model:GetAttribute("MinigameType")
        end)
        machine.kind = ok and FARM.MachineKinds[value] or false
    end
    return machine.kind
end

function FARM.runMachineRanks()
    if not SETTINGS.farmMachinePriority then return nil end
    local order = SETTINGS.farmMachineOrder
    if FARM.Ranks and FARM.Ranks.Order == order then return FARM.Ranks.List end
    local List, count = {}, 0
    for kind in string.gmatch(order, "[^,]+") do
        count += 1
        List[kind] = count
    end
    FARM.Ranks = {Order = order, List = List}
    return List
end

function FARM.runMachineRank(machine, Ranks)
    if not Ranks then return 0 end
    return Ranks[FARM.runMachineKind(machine)] or #FARM.MachineOrder + 1
end

function FARM.runStaminaSprint(now, root)
    local R = FARM.RUN
    local L = FARM.LOBBY

    local moving = R.phase == "tween" or R.phase == "toElevator" or (R.phase == "research" and R.research and R.research.kind ~= "razzle" and not R.researchArrived)
    if R.phase == "research" and R.research and R.research.kind == "razzle" then
        return
    end

    if R.phase == "working" and R.current and SETTINGS.farmTreadmillRun and FARM.runOnTreadmill(R.current) then
        local stamina, maximum = FARM.stamina()
        if stamina then
            if stamina <= SETTINGS.farmTreadmillStopAt then
                R.treadmillResting = true
            elseif stamina >= math.min(SETTINGS.farmTreadmillStopAt + FARM.TREADMILL_RECOVER, maximum) then
                R.treadmillResting = false
            end
        end
        if not R.treadmillResting then
            FARM.sprintUpdate(now, true)
            return
        end
    else
        R.treadmillResting = false
    end

    if R.staminaSprint and moving and not FARM.runNearRazzle(root) then
        FARM.sprintUpdate(now, true)
        return
    end

    if KEYS.Held[L.SHIFT] then
        KEYS.set(FARM.LOBBY.SHIFT, false)
        return
    end

    if L.sprintMode == nil then
        L.sprintMode = FARM.sprintSetting()
    end

    if L.sprintMode == "toggle" and not KEYS.Timed[L.SHIFT] and now >= R.sprintOffAt and FARM.isSprinting() then
        R.sprintOffAt = now + R.SPRINT_OFF_EVERY
        KEYS.hold(L.SHIFT, R.SHIFT_HOLD)
    end
end

function FARM.runElevatorBase()
    return UI.find("ElevatorBase", function()
        local folder = UI.elevators()
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
    end)
end

function FARM.runElevatorState(character, root)
    local folder = UI.elevators()
    local elevator = folder and folder:FindFirstChild("Elevator")
    local opened = elevator and elevator:FindFirstChild("Opened")
    local okOpen, isOpen = pcall(function()
        return UI.bool(opened)
    end)
    if not okOpen or type(isOpen) ~= "boolean" then
        isOpen = nil
    end

    local flag = UI.myStat("InElevator")
    local okFlag, flagged = pcall(function()
        return UI.bool(flag)
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
        return character and UI.bool(UI.myStat("InElevator"))
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
    if monster.Name == "GourdyMonster" then
        local T = FARM.twisted(monster)
        return T ~= nil and FARM.twistedAttr(T, "IsStationary") ~= false
    end
    if monster.Name ~= "GlistenMonster" then
        return false
    end
    local T = FARM.twisted(monster)
    return T ~= nil and FARM.twistedAttr(T, "GlistenActivated") ~= true
end

function FARM.runThreat(root, ignore)
    local R = FARM.RUN
    local map = UI.map()
    local monsters = map and map:FindFirstChild("Monsters")
    if not monsters then
        return 9999, false
    end
    FARM.runResearchMap(map)

    local nearest, chasing, panic, seen, danger = 9999, false, false, false, false
    local hidden = R.phase == "hide"
    local eye = root.Position
    local walls = FARM.runRayWorks(root, hidden)
    local generators = map:FindFirstChild("Generators")

    local myName = LocalPlayer.Name
    local research = SETTINGS.farmResearchTwisteds or SETTINGS.farmEventTwisteds or FARM.MASTERY.researchMode()
    for _, monster in ipairs(monsters:GetChildren()) do
        local wasPanic, wasSeen, wasChasing = panic, seen, chasing
        panic, seen, chasing = false, false, false
        local T = FARM.twisted(monster)
        local part = T and T.Part
        local ok, position = pcall(function()
            return part.Position
        end)

        if ok and position and R.IGNORE_BODY[monster.Name] then
            ok = false
        end

        if ok and position and research then
            local key = FARM.runKey(monster)
            local now = tick()
            if key and not R.researched[key] and (now >= (T.SawAt or 0) or (position - root.Position).Magnitude < R.DANGER) then
                T.SawAt = now + 0.25
                if FARM.runSawYou(monster) and not (R.phase == "research" and key == ignore) then
                    R.researched[key] = true
                end
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

            local razzle = monster.Name == "RazzleDazzleMonster"
            if razzle then
                if FARM.runRazzleSees(eye) then
                    panic = true
                    seen = true
                end
            elseif not chasing and FARM.twistedTarget(T) == myName then
                chasing = true
                R.ChaseWhy = string.format("%s targets you at %.0f studs", monster.Name, distance)
            end

            if chasing or razzle then
            elseif passive then
                if FARM.twistedAttr(T, "Attacking") == true then
                    chasing = true
                    R.ChaseWhy = string.format("passive %s attacking at %.0f studs", monster.Name, distance)
                end
            elseif (not T.Holder or not VantaUI.MemoryAccess()) and distance < math.min(R.DANGER, (T.Instant or R.CHASER_DEFAULTS.InstantRadius) + R.DIVE_BUFFER) and not FARM.twistedTarget(T) and FARM.twistedChasing(T) then
                chasing = true
                R.ChaseWhy = string.format("%s in chase state, target unreadable, at %.0f studs", monster.Name, distance)
            end

            if distance < nearest and not passive then
                nearest = distance
            end
        end
        if (panic or seen or chasing) and FARM.runDangerous(monster) then danger = true end
        panic, seen, chasing = panic or wasPanic, seen or wasSeen, chasing or wasChasing
    end

    return nearest, chasing, panic, seen, danger
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
        return instance:IsDescendantOf(folder) or instance.Address == folder.Address
    end)
    return ok and result == true
end

function FARM.rayFirst(from, to, Ignore, gap)
    local point = from
    for _ = 1, FARM.RUN.RAY_HOPS do
        local offset = to - point
        if offset.Magnitude < (gap or 1) then
            return nil
        end
        local hit = workspace:Raycast(point, offset)
        if not hit or not hit.Instance then
            return nil
        end
        local ignored = false
        for _, Folder in pairs(Ignore) do
            if FARM.runIsInside(hit.Instance, Folder) then
                ignored = true
                break
            end
        end
        if not ignored then
            return hit.Position
        end
        point = hit.Position + offset.Unit * 0.05
    end
    return nil
end

function FARM.runRayBlocked(from, to, generators)
    local ok, hit = pcall(FARM.rayFirst, from, to, {generators})
    return ok and hit ~= nil and (hit - from).Magnitude < (to - from).Magnitude - 1
end

function FARM.runWallBetween(monster, part, eye, generators)
    local T = FARM.twisted(monster)
    local origin = (T and T.Origin) or part
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
        return UI.read(UI.info().PlayerStats[LocalPlayer.Name].Monsters)
    end)
    return (ok and type(value) == "number") and value or nil
end

function FARM.runHandWall(zone, from, eye, generators)
    local start = from + Vector3.new(0, 2, 0)
    local ok, hit = pcall(FARM.rayFirst, start, eye, {zone, generators, LocalPlayer.Character})
    return ok and hit ~= nil and (hit - start).Magnitude < (eye - start).Magnitude - 1
end

function FARM.objectSpace(cf, point)
    local offset = point - cf.Position
    return Vector3.new(offset:Dot(cf.RightVector), offset:Dot(cf.UpVector), -offset:Dot(cf.LookVector))
end

function FARM.runInHandZone(zone, position, point)
    local R = FARM.RUN
    local ok, offset, size = pcall(function()
        return FARM.objectSpace(zone.CFrame, point), zone.Size
    end)
    if ok and offset and size then
        return math.abs(offset.X) <= size.X / 2 + R.BLOT_HAND_MARGIN and math.abs(offset.Z) <= size.Z / 2 + R.BLOT_HAND_MARGIN
    end
    return Vector3.new(point.X - position.X, 0, point.Z - position.Z).Magnitude <= R.BLOT_HAND_RANGE
end

function FARM.runBlotHandNear(point, root)
    local R = FARM.RUN
    local map = UI.map()
    if not map or not UI.roster().Names.BlottMonster then
        return false
    end
    local generators = map:FindFirstChild("Generators")
    local walls = FARM.runRayWorks(root, R.phase == "dive" or R.phase == "hide")
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
            if hand and ok and position and FARM.runInHandZone(zone, position, point) and not (walls and FARM.runHandWall(zone, position, point, generators)) then
                return true
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
    local map = UI.map()
    local Roster = UI.roster()
    if map and Roster.Names.SproutMonster then
        for _, child in ipairs(UI.sproutTendrils(map)) do
            local part = child:FindFirstChild("Puddle") or child:FindFirstChild("HumanoidRootPart")
            local ok, position = pcall(function()
                return part.Position
            end)
            if ok and position then
                list[#list + 1] = { position = position, range = R.SPROUT_RANGE }
            end
        end
    end
    if map and Roster.Names.RodgerMonster then
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
        for _, monster in ipairs(Roster.Models) do
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
    for _, Roller in ipairs(map and FARM.runRollingPumpkins(map) or {}) do
        list[#list + 1] = Roller
    end
    R.sprouts = list
    return list
end

function FARM.runRollingPumpkins(map)
    local R = FARM.RUN
    local key = FARM.runKey(map)
    if R.RollMap ~= key then
        R.RollMap, R.RollSeen, R.Rollers = key, {}, {}
    end
    local Parents = {Workspace, map}
    local Doors = map:FindFirstChild("TrickOrTreatDoors")
    for _, Door in ipairs(Doors and Doors:GetChildren() or {}) do table.insert(Parents, Door) end
    for _, Parent in ipairs(Parents) do
        for _, Child in ipairs(Parent:GetChildren()) do
            local address = FARM.runKey(Child)
            if address and not R.RollSeen[address] then
                R.RollSeen[address] = true
                local ok, width = pcall(function()
                    return Child.ClassName == "Model" and Child:GetAttribute("FullWidth")
                end)
                if ok and type(width) == "number" then
                    table.insert(R.Rollers, {Model = Child, Width = width})
                    FARM.debugNote(string.format("rolling pumpkin found: %s (full width %.1f)", Child:GetFullName(), width))
                end
            end
        end
    end
    local list = {}
    for i = #R.Rollers, 1, -1 do
        local Roller = R.Rollers[i]
        local ok, position = pcall(function()
            if not Roller.Model.Parent then return nil end
            for _, Child in ipairs(Roller.Model:GetChildren()) do
                if Child.ClassName == "ObjectValue" and Child.Value and Child.Value:IsA("BasePart") then return Child.Value.Position end
            end
            local Part = Roller.Model.PrimaryPart or Roller.Model:FindFirstChildWhichIsA("BasePart")
            return Part and Part.Position
        end)
        if ok and position then
            list[#list + 1] = {position = position, range = Roller.Width / 2 + R.RollMargin}
        elseif not (ok and Roller.Model.Parent) then
            table.remove(R.Rollers, i)
        end
    end
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
        return UI.bool(holder)
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
    local map = UI.map()
    local Roster = UI.roster()
    if not (map and Roster.Names.RazzleDazzleMonster) then
        return false
    end
    local generators = map:FindFirstChild("Generators")
    for _, monster in ipairs(Roster.Models) do
        if monster.Name == "RazzleDazzleMonster" then
            local T = FARM.twisted(monster)
            local part = T and T.Part
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
    local mapKey = tostring(map.Address)
    if R.researchMap ~= mapKey then
        R.researchMap = mapKey
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
        local T = FARM.twisted(target.model)
        local head = (T and T.Origin) or target.part
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

    local map = UI.map()
    local generators = map and map:FindFirstChild("Generators")
    local okRay, hit = pcall(FARM.rayFirst, origin, origin + facing * reach, {generators}, 0.5)
    if not okRay then
        return nil
    end
    local free = hit and (hit - origin).Magnitude or reach

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

function FARM.researchDone(name)
    local now = tick()
    local Cache = FARM.RESEARCH[name]
    if not Cache or now >= Cache.At then
        local ok, value = pcall(function()
            return UI.read(game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Research[name])
        end)
        Cache = {At = now + 2, Done = ok and type(value) == "number" and value >= 100}
        FARM.RESEARCH[name] = Cache
    end
    return Cache.Done
end

function FARM.runFullyResearched(name)
    if FARM.MASTERY.wants("EncounterMonster") or SETTINGS.farmEventTwisteds then
        return false
    end
    if not SETTINGS.farmSkipResearched then
        return false
    end
    return FARM.researchDone(name)
end

function FARM.capsuleForResearch(model)
    local R = FARM.RUN
    local key = FARM.runKey(model)
    local name = key and R.capsuleNames[key]
    if not name then
        name = researchCapsuleMonster(model)
        if key and name then R.capsuleNames[key] = name end
    end
    return name ~= nil and MONSTER_INFO[name] ~= nil and not FARM.researchDone(name)
end

function FARM.runResearchTarget(root)
    local R = FARM.RUN
    if not SETTINGS.farmResearchTwisteds and not SETTINGS.farmEventTwisteds and not FARM.MASTERY.researchMode() then
        return nil
    end

    local map = UI.map()
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
                local T = FARM.twisted(monster)
                local unavailable = T ~= nil and monster.Name == "GlistenMonster" and FARM.twistedAttr(T, "GlistenActivated") == true
                if T ~= nil and monster.Name == "GourdyMonster" and FARM.twistedAttr(T, "IsStationary") ~= false then unavailable = true end
                local part = T and T.Part
                local ok, position = pcall(function()
                    return part.Position
                end)
                if ok and position and not unavailable then
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
    local T = FARM.twisted(monster)
    if not T then
        return false
    end
    return FARM.twistedTarget(T) == LocalPlayer.Name or FARM.twistedChasing(T)
end

function FARM.runSprintOff()
    local L = FARM.LOBBY
    if KEYS.Held[L.SHIFT] then
        KEYS.set(FARM.LOBBY.SHIFT, false)
    end
end

function FARM.runLeaveMachine(now)
    local R = FARM.RUN
    if now < R.leaveAt then return end
    R.leaveAt = now + 0.2
    for _, machine in ipairs(FARM.runMachines()) do
        if FARM.runEngagedBy(machine) == LocalPlayer.Name then
            if SKILL.showing() then
                pressSpace()
                SKILL.lastPress = os.clock()
                R.leaveAt = now + 0.15
                return
            end
            if KEYS.hold(R.E_KEY, R.KEY_HOLD) then R.leaveAt = now + 0.5 end
            return
        end
    end
end

function FARM.runDive(root, now, status)
    local R = FARM.RUN
    local floor = FARM.runFloorY(root.Position.X, root.Position.Y, root.Position.Z)
    if floor then
        R.hipOffset = math.clamp(root.Position.Y - floor, 2, 5)
    end
    R.hideUntil = now + R.HIDE_MAX
    R.leaveAt = 0
    R.clearSince = nil
    R.elevatorDive = nil
    R.hideGoal = nil
    R.hideGoalY = nil
    R.hideGoalAt = 0
    R.Cover, R.CoverSpot, R.HopLabel = nil, nil, nil
    R.CoverAt = 0
    R.phase = "dive"
    R.at = now
    FARM.setStatus(status)
end

function FARM.debugNote(text)
    if not FARM.Debug.Enabled or type(appendfile) ~= "function" then return end
    local now = tick()
    pcall(appendfile, FARM.Debug.File, os.date("%H:%M:%S", math.floor(now)) .. string.format(".%03d ", math.floor((now % 1) * 1000)) .. text .. "\n")
end

function FARM.debugTrust(now)
    local Debug = FARM.Debug
    if now < (Debug.TrustAt or 0) then return end
    Debug.TrustAt = now + 0.2
    Debug.Trust = Debug.Trust or {}
    for _, name in ipairs({"KM_TELEPORT_TRUST_SCORE", "KM_SPEED_TRUST_SCORE", "KM_FLY_TRUST_SCORE", "KM_IGNORE_PLAYER_SPEED_CHEAT"}) do
        local ok, value = pcall(function()
            return LocalPlayer:GetAttribute(name)
        end)
        local text = ok and tostring(value) or "?"
        if Debug.Trust[name] ~= nil and Debug.Trust[name] ~= text then
            FARM.debugNote(string.format("ANTICHEAT %s %s -> %s (speed %.1f)", name, Debug.Trust[name], text, FARM.SpeedMeter.Value))
        end
        Debug.Trust[name] = text
    end
end

function FARM.debugTrace(spent)
    if not FARM.Debug.Enabled then return end
    local R = FARM.RUN
    local Debug = FARM.Debug
    FARM.debugTrust(tick())
    local status = FARM.status or ""
    if R.phase == Debug.Phase and status == Debug.Status and spent < Debug.Slow then return end
    local slow = spent >= Debug.Slow and "SLOW " or ""
    Debug.Phase, Debug.Status = R.phase, status
    local root = UI.myPart("HumanoidRootPart")
    local ok, p = pcall(function()
        return root.Position
    end)
    local threat = "?"
    if ok and p then
        local nearest = FARM.runNearestThreat(p, FARM.runCoverThreats(root))
        threat = nearest and string.format("%.1f", FARM.flatDistance(p, nearest)) or "none"
    end
    local cover = R.CoverSpot and string.format("exp %.1f hid %.1f", R.CoverSpot.Exposure, R.CoverSpot.Hidden or 0) or "-"
    FARM.debugNote(string.format("%s%-9s %6.1fms spd=%.1f/%.1f pos=%s twisted=%s cover=%s | %s", slow, tostring(R.phase), spent * 1000, FARM.SpeedMeter.Value, R.SprintSpeed, ok and p and string.format("(%.1f,%.1f,%.1f)", p.X, p.Y, p.Z) or "?", threat, cover, status))
end

function FARM.flatDistance(from, to)
    return Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
end

function FARM.runSprintSpeed(now)
    local R = FARM.RUN
    if now < R.SprintReadAt then return R.SprintSpeed end
    R.SprintReadAt = now + R.SprintReadEvery
    local ok, value = pcall(function()
        return LocalPlayer:GetAttribute("KM_MAX_PLAYER_SPEED")
    end)
    R.SprintSpeed = (ok and type(value) == "number" and value > 0) and value or R.SprintDefault
    return R.SprintSpeed
end

function FARM.stepLength(now)
    local R = FARM.RUN
    return FARM.travelSpeed(now) * R.FrameTime * R.SpeedTrim
end

function FARM.frameThreats(root, now)
    local R = FARM.RUN
    if R.ThreatFrame ~= now then
        R.ThreatFrame = now
        R.ThreatList = FARM.runCoverThreats(root)
    end
    return R.ThreatList
end

function FARM.runSteer(root, direction, now)
    local R = FARM.RUN
    local p = root.Position
    local aura = SETTINGS.farmAvoidAura or R.AvoidMargin
    local Best, bestDistance
    for _, Threat in ipairs(FARM.frameThreats(root, now)) do
        local dx, dz = p.X - Threat.Position.X, p.Z - Threat.Position.Z
        local distance = math.sqrt(dx * dx + dz * dz)
        local keep = Threat.Kill + aura
        if distance > 0.01 and distance < keep + R.AvoidRange + R.SteerLook then
            local ahead = -(dx * direction.X + dz * direction.Z)
            local lateral = math.abs(dx * direction.Z - dz * direction.X)
            local blocking = distance < keep or (ahead > 0 and (distance < keep + R.AvoidRange or lateral < keep + 1))
            if blocking and (not bestDistance or distance < bestDistance) then
                Best, bestDistance = {Name = Threat.Name, X = dx / distance, Z = dz / distance, Keep = keep}, distance
            end
        end
    end
    if not Best then
        R.SteerSide = nil
        return direction
    end
    local sideX, sideZ = -Best.Z, Best.X
    if not R.SteerSide or R.SteerFor ~= Best.Name then
        R.SteerSide = sideX * direction.X + sideZ * direction.Z >= 0 and 1 or -1
        R.SteerFor = Best.Name
    end
    sideX, sideZ = sideX * R.SteerSide, sideZ * R.SteerSide
    local outward = bestDistance < Best.Keep and R.SteerPush or R.SteerDrift
    return Vector3.new(sideX + Best.X * outward, 0, sideZ + Best.Z * outward).Unit
end

function FARM.runDangerous(monster)
    local info = MONSTER_INFO[monster.Name]
    return FARM.RUN.DangerTwisted[monster.Name] == true or (info ~= nil and info.rarity == "Lethal")
end

function FARM.partShape(Item)
    local R = FARM.RUN
    if Item.ClassName ~= "Part" then return nil end
    if R.ShapeBroken or not VantaUI.MemoryAccess() then return nil end
    local ok, value = pcall(memory_read, "byte", tonumber(Item.Address) + R.ShapeOffset)
    if not ok or type(value) ~= "number" then return nil end
    if value > 4 then
        R.ShapeBroken = true
        FARM.debugNote(string.format("part shape offset 0x%X read %d, shape checks off", R.ShapeOffset, value))
        return nil
    end
    return value
end

function FARM.coverEntry(Item)
    local R = FARM.RUN
    local shape = FARM.partShape(Item)
    if shape and shape ~= R.ShapeBlock then return nil end
    local size = Item.Size
    local smallest = R.CoverMargin * 2
    if size.X < smallest or size.Y < smallest or size.Z < smallest then return nil end
    local cf = Item.CFrame
    local origin = Item.Position
    local axisX = cf.RightVector
    local axisY = cf.UpVector
    local axisZ = -cf.LookVector
    if math.max(math.abs(axisX.Y), math.abs(axisY.Y), math.abs(axisZ.Y)) < R.CoverUpright then return nil end
    return {
        Part = Item,
        Ox = origin.X, Oy = origin.Y, Oz = origin.Z,
        Xx = axisX.X, Xy = axisX.Y, Xz = axisX.Z,
        Yx = axisY.X, Yy = axisY.Y, Yz = axisY.Z,
        Zx = axisZ.X, Zy = axisZ.Y, Zz = axisZ.Z,
        Hx = size.X / 2, Hy = size.Y / 2, Hz = size.Z / 2,
        Radius = size.Magnitude / 2,
    }
end

function FARM.coverIndex(Entry)
    local R = FARM.RUN
    local cell = R.CoverCell
    local reach = math.sqrt(Entry.Hx * Entry.Hx + Entry.Hz * Entry.Hz + Entry.Hy * Entry.Hy)
    for cx = math.floor((Entry.Ox - reach) / cell), math.floor((Entry.Ox + reach) / cell) do
        for cz = math.floor((Entry.Oz - reach) / cell), math.floor((Entry.Oz + reach) / cell) do
            local key = cx .. ":" .. cz
            local List = R.CoverCells[key]
            if not List then
                List = {}
                R.CoverCells[key] = List
            end
            table.insert(List, Entry)
        end
    end
end

function FARM.coverCount(Room)
    local R = FARM.RUN
    local count = 0
    for _, Child in ipairs(Room:GetChildren()) do
        if not R.CoverSkip[Child.Name] then count += #Child:GetDescendants() + 1 end
    end
    return count
end

function FARM.coverFill(Room)
    local R = FARM.RUN
    R.CoverParts = {}
    R.CoverCells = {}
    R.CoverLevels = {}
    R.CoverHeights = nil
    R.CoverPreloaded = nil
    R.CoverQueue = {}
    R.CoverIndex = 1
    for _, Child in ipairs(Room:GetChildren()) do
        if not R.CoverSkip[Child.Name] then
            if Child.ClassName == "Part" then table.insert(R.CoverQueue, Child) end
            for _, Descendant in ipairs(Child:GetDescendants()) do
                table.insert(R.CoverQueue, Descendant)
            end
        end
    end
    R.CoverFilled = true
    R.CoverBuiltCount = R.CoverCount
end

function FARM.runCoverCache(Room)
    local R = FARM.RUN
    local key = FARM.runKey(Room)
    if not key then return end
    local now = tick()
    if R.CoverMap == key and R.CoverFilled and not R.CoverQueue and #R.CoverParts < R.CoverMinParts and now >= (R.CoverRetryAt or 0) then
        R.CoverRetryAt = now + R.CoverRetryEvery
        R.CoverMap = nil
    end
    if R.CoverMap ~= key then
        R.CoverMap = key
        R.CoverParts = {}
        R.CoverCells = {}
        R.CoverLevels = {}
        R.CoverHeights = nil
        R.CoverPreloaded = nil
        R.CoverQueue = {}
        R.CoverIndex = 1
        R.CoverFilled = false
        R.CoverStart, R.CoverCheckAt, R.CoverCount, R.CoverStable = now, 0, -1, 0
    end
    if now >= R.CoverCheckAt and now - R.CoverStart < R.CoverWatchTime then
        R.CoverCheckAt = now + (R.CoverFilled and R.CoverWatchEvery or R.CoverSettleEvery)
        local ok, count = pcall(FARM.coverCount, Room)
        if ok then
            R.CoverStable = count == R.CoverCount and R.CoverStable + 1 or 0
            R.CoverCount = count
            if R.CoverFilled and count - R.CoverBuiltCount >= R.CoverGrowth then
                FARM.debugNote(string.format("room grew from %d to %d instances, remapping cover", R.CoverBuiltCount, count))
                FARM.coverFill(Room)
            end
        end
    end
    if not R.CoverFilled then
        if R.CoverStable < R.CoverSettleChecks and now - R.CoverStart < R.CoverWatchTime then return end
        FARM.debugNote(string.format("room settled at %d instances after %.1f s", R.CoverCount, now - R.CoverStart))
        FARM.coverFill(Room)
    end
    local Queue = R.CoverQueue
    if not Queue then return end
    local last = math.min(R.CoverIndex + R.CoverBatch - 1, #Queue)
    for i = R.CoverIndex, last do
        local Item = Queue[i]
        pcall(function()
            if Item.ClassName ~= "Part" or not Item.CanCollide or R.CoverSkipNames[Item.Name] then return end
            local Entry = FARM.coverEntry(Item)
            if not Entry then return end
            table.insert(R.CoverParts, Entry)
            FARM.coverIndex(Entry)
        end)
    end
    R.CoverIndex = last + 1
    if R.CoverIndex > #Queue then
        R.CoverQueue = nil
        FARM.debugNote(string.format("cover parts ready: %d", #R.CoverParts))
    end
end

function FARM.coverSolid(x, y, z)
    local R = FARM.RUN
    local List = R.CoverCells and R.CoverCells[math.floor(x / R.CoverCell) .. ":" .. math.floor(z / R.CoverCell)]
    if not List then return false end
    for _, E in ipairs(List) do
        local dx, dy, dz = x - E.Ox, y - E.Oy, z - E.Oz
        if math.abs(dx * E.Xx + dy * E.Xy + dz * E.Xz) <= E.Hx and math.abs(dx * E.Yx + dy * E.Yy + dz * E.Yz) <= E.Hy and math.abs(dx * E.Zx + dy * E.Zy + dz * E.Zz) <= E.Hz then
            return true
        end
    end
    return false
end

function FARM.coverExitDirection(x, y, z)
    local R = FARM.RUN
    local count = R.CoverDirections
    local best, bestT
    for i = 0, count - 1 do
        local angle = i * 2 * math.pi / count
        local cx, cz = math.cos(angle), math.sin(angle)
        local t = R.CoverStep
        while t < R.CoverProbe * 3 and FARM.coverSolid(x + cx * t, y, z + cz * t) do
            t += R.CoverStep
        end
        if not bestT or t < bestT then
            best, bestT = Vector3.new(cx, 0, cz), t
        end
    end
    return best
end

function FARM.coverClear(point)
    local R = FARM.RUN
    if FARM.coverSolid(point.X, point.Y, point.Z) then return false end
    local count = 8
    for i = 0, count - 1 do
        local angle = i * 2 * math.pi / count
        if FARM.coverSolid(point.X + math.cos(angle) * R.CoverExit, point.Y, point.Z + math.sin(angle) * R.CoverExit) then return false end
    end
    return true
end

function FARM.partTransparency(Item)
    local R = FARM.RUN
    local Root = R.TransparencyWorks == nil and VantaUI.MemoryAccess() and UI.myPart("HumanoidRootPart")
    if Root then
        local ok, value = pcall(function()
            return memory_read("float", tonumber(Root.Address) + R.TransparencyOffset)
        end)
        R.TransparencyWorks = ok and type(value) == "number" and math.abs(value - 1) < 0.001
        FARM.debugNote(string.format("part transparency offset 0x%X %s", R.TransparencyOffset, R.TransparencyWorks and "works" or "failed, using collider names"))
    end
    if R.TransparencyWorks and VantaUI.MemoryAccess() then
        local ok, value = pcall(memory_read, "float", tonumber(Item.Address) + R.TransparencyOffset)
        if ok and type(value) == "number" and value == value then return value end
    end
    local ok, value = pcall(function()
        return Item.Transparency
    end)
    if ok and type(value) == "number" and value > 0 then return value end
    return R.InvisibleNames[Item.Name] and 1 or 0
end

function FARM.coverVisual(Item, Visuals)
    local R = FARM.RUN
    if not R.HideClasses[Item.ClassName] or R.CoverSkipNames[Item.Name] or FARM.partTransparency(Item) >= 1 then return end
    local size = Item.Size
    local cf = Item.CFrame
    local origin = Item.Position
    local Axes = {
        cf.RightVector,
        cf.UpVector,
        -cf.LookVector,
    }
    local Half = {size.X / 2, size.Y / 2, size.Z / 2}
    local up = 1
    for i = 2, 3 do
        if math.abs(Axes[i].Y) > math.abs(Axes[up].Y) then up = i end
    end
    if math.abs(Axes[up].Y) < R.CoverUpright then return end
    local shape = FARM.partShape(Item)
    if shape and shape ~= R.ShapeBlock and not (shape == R.ShapeCylinder and up == 1) then return end
    local a, b = up == 1 and 2 or 1, up == 3 and 2 or 3
    table.insert(Visuals, {
        Round = shape == R.ShapeCylinder and math.min(Half[2], Half[3]) or nil,
        Ox = origin.X, Oy = origin.Y, Oz = origin.Z,
        Ax = Axes[a].X, Az = Axes[a].Z, Ha = Half[a],
        Bx = Axes[b].X, Bz = Axes[b].Z, Hb = Half[b],
        Low = origin.Y - Half[up], High = origin.Y + Half[up],
    })
end

function FARM.coverVisuals(Entry)
    if Entry.Visuals then return Entry.Visuals end
    local R = FARM.RUN
    local Visuals = {}
    local Item = Entry.Part
    pcall(FARM.coverVisual, Item, Visuals)
    local Parent = Item.Parent
    if Parent then
        pcall(FARM.coverVisual, Parent, Visuals)
        if #Parent:GetChildren() <= R.HideFamily then
            for _, Other in ipairs(Parent:GetDescendants()) do
                if Other ~= Item then pcall(FARM.coverVisual, Other, Visuals) end
            end
        end
    end
    Entry.Visuals = Visuals
    return Visuals
end

function FARM.coverRect(V, ox, oz, ax, az, bx, bz)
    local R = FARM.RUN
    local du, dv = V.Ox - ox, V.Oz - oz
    local cu, cv = du * ax + dv * az, du * bx + dv * bz
    local hu, hv
    if V.Round then
        hu = (V.Round - R.HideMin) * 0.7071
        hv = hu
    else
        local lengthA = math.sqrt(V.Ax * V.Ax + V.Az * V.Az)
        local cos = math.abs((V.Ax * ax + V.Az * az) / lengthA)
        local sin = math.sqrt(math.max(0, 1 - cos * cos))
        if cos >= 0.995 then
            hu, hv = V.Ha - R.HideMin, V.Hb - R.HideMin
        elseif sin >= 0.995 then
            hu, hv = V.Hb - R.HideMin, V.Ha - R.HideMin
        else
            hu = (math.min(V.Ha, V.Hb) - R.HideMin) / (cos + sin)
            hv = hu
        end
    end
    if hu <= 0 or hv <= 0 then return nil end
    return {cu - hu, cu + hu, cv - hv, cv + hv}
end

function FARM.coverZone(Level, Entry)
    local R = FARM.RUN
    local margin = R.CoverMargin
    local standY = Level.Y
    local Axes = {
        {X = Entry.Xx, Y = Entry.Xy, Z = Entry.Xz, H = Entry.Hx},
        {X = Entry.Yx, Y = Entry.Yy, Z = Entry.Yz, H = Entry.Hy},
        {X = Entry.Zx, Y = Entry.Zy, Z = Entry.Zz, H = Entry.Hz},
    }
    local up = 1
    for i = 2, 3 do
        if math.abs(Axes[i].Y) > math.abs(Axes[up].Y) then up = i end
    end
    local Vertical = Axes[up]
    if math.abs(Vertical.Y) < R.CoverUpright then return end
    local First, Second
    for i = 1, 3 do
        if i ~= up then
            if First then Second = Axes[i] else First = Axes[i] end
        end
    end
    local rangeA, rangeB = First.H - margin, Second.H - margin
    if rangeA < 0 or rangeB < 0 then return end
    local center = (standY - Entry.Oy) / Vertical.Y
    local wobble = (math.abs(First.Y) * First.H + math.abs(Second.Y) * Second.H) / math.abs(Vertical.Y)
    if math.abs(center) - wobble > Vertical.H - margin then return end
    local Visuals = FARM.coverVisuals(Entry)
    if #Visuals == 0 then return end
    local ox, oz = Entry.Ox + center * Vertical.X, Entry.Oz + center * Vertical.Z
    local lengthA = math.sqrt(First.X * First.X + First.Z * First.Z)
    local lengthB = math.sqrt(Second.X * Second.X + Second.Z * Second.Z)
    local ax, az = First.X / lengthA, First.Z / lengthA
    local bx, bz = Second.X / lengthB, Second.Z / lengthB
    local Rects = {{-rangeA, rangeA, -rangeB, rangeB}}
    for _, offset in ipairs(R.HideHeights) do
        local y = standY + offset
        local Next = {}
        for _, V in ipairs(Visuals) do
            if y >= V.Low and y <= V.High then
                local B = FARM.coverRect(V, ox, oz, ax, az, bx, bz)
                if B then
                    for _, A in ipairs(Rects) do
                        local Cut = {math.max(A[1], B[1]), math.min(A[2], B[2]), math.max(A[3], B[3]), math.min(A[4], B[4])}
                        if Cut[1] <= Cut[2] and Cut[3] <= Cut[4] and #Next < R.ZoneRects then table.insert(Next, Cut) end
                    end
                end
            end
        end
        if #Next == 0 then return end
        Rects = Next
    end
    local Zone = {Entry = Entry, X = ox, Z = oz, Ax = ax, Az = az, Bx = bx, Bz = bz, Ha = First.H, Hb = Second.H, Rects = Rects}
    table.insert(Level.Zones, Zone)
    local cell = R.CoverCell
    local reach = math.sqrt(First.H * First.H + Second.H * Second.H)
    for cx = math.floor((ox - reach) / cell), math.floor((ox + reach) / cell) do
        for cz = math.floor((oz - reach) / cell), math.floor((oz + reach) / cell) do
            local key = cx .. ":" .. cz
            local Cell = Level.Cells[key]
            if not Cell then
                Cell = {}
                Level.Cells[key] = Cell
            end
            table.insert(Cell, Zone)
        end
    end
end

function FARM.coverLevel(standY, near, budget)
    local R = FARM.RUN
    if not R.CoverLevels or R.CoverQueue then return nil end
    local Level
    for _, Existing in ipairs(R.CoverLevels) do
        if math.abs(Existing.Y - standY) <= R.CoverLevelTolerance then
            Level = Existing
            break
        end
    end
    if not Level then
        Level = {Y = standY, Zones = {}, Cells = {}, Index = 1, Done = {}}
        table.insert(R.CoverLevels, Level)
    end
    if Level.Index > #R.CoverParts then return Level end
    if near then
        local started = os.clock()
        local count = 0
        for i = Level.Index, #R.CoverParts do
            local Entry = R.CoverParts[i]
            if not Level.Done[Entry] then
                local dx, dz = Entry.Ox - near.X, Entry.Oz - near.Z
                local range = R.CoverReach + Entry.Radius
                if dx * dx + dz * dz <= range * range then
                    Level.Done[Entry] = true
                    count += 1
                    pcall(FARM.coverZone, Level, Entry)
                end
            end
        end
        if count > 0 then FARM.debugNote(string.format("cover urgent build at Y %.1f: %d parts near you in %.0f ms", Level.Y, count, (os.clock() - started) * 1000)) end
        return Level
    end
    local started = os.clock()
    local limit = budget or R.CoverLevelBudget
    while Level.Index <= #R.CoverParts and os.clock() - started < limit do
        local Entry = R.CoverParts[Level.Index]
        if not Level.Done[Entry] then pcall(FARM.coverZone, Level, Entry) end
        Level.Index += 1
    end
    if Level.Index > #R.CoverParts then
        FARM.debugNote(string.format("cover zones ready at Y %.1f: %d zones", Level.Y, #Level.Zones))
    end
    return Level
end

function FARM.coverHeights(Room)
    local R = FARM.RUN
    if R.CoverHeightsMap == R.CoverMap and R.CoverHeights then return R.CoverHeights end
    local Floors = {}
    local function add(part)
        local ok, y = pcall(function()
            return part.Position.Y
        end)
        if ok and type(y) == "number" then table.insert(Floors, y + R.CoverRootOffset) end
    end
    local Waypoints = Room:FindFirstChild("Waypoints")
    for _, Point in ipairs(Waypoints and Waypoints:GetChildren() or {}) do add(Point) end
    local Generators = Room:FindFirstChild("Generators")
    for _, Machine in ipairs(Generators and Generators:GetChildren() or {}) do
        local Stands = Machine:FindFirstChild("TeleportPositions")
        local Stand = Stands and Stands:FindFirstChild("TeleportPosition")
        if Stand then add(Stand) end
    end
    if #Floors == 0 then return {} end
    table.sort(Floors)
    local Groups = {}
    for _, y in ipairs(Floors) do
        local Last = Groups[#Groups]
        if Last and y - Last.Low <= R.CoverLevelTolerance then
            Last.Total += y
            Last.Count += 1
        else
            table.insert(Groups, {Low = y, Total = y, Count = 1})
        end
    end
    table.sort(Groups, function(a, b) return a.Count > b.Count end)
    local Heights = {}
    for _, Group in ipairs(Groups) do table.insert(Heights, Group.Total / Group.Count) end
    R.CoverHeightsMap = R.CoverMap
    R.CoverHeights = Heights
    FARM.debugNote(string.format("cover heights to preload: %d (%d floor points)", #Heights, #Floors))
    return Heights
end

function FARM.coverNearFloor(y)
    local R = FARM.RUN
    for _, height in ipairs(R.CoverHeights or {}) do
        if math.abs(height - y) <= R.CoverFloorRange then return true end
    end
    return false
end

function FARM.coverPreload()
    local R = FARM.RUN
    local Room = UI.map()
    if not Room then
        R.Mapping = nil
        return
    end
    FARM.runCoverCache(Room)
    if R.CoverPreloaded == R.CoverMap and not R.CoverQueue then
        R.Mapping = nil
        return
    end
    if R.CoverQueue or #R.CoverParts < R.CoverMinParts then
        R.Mapping = 0
        return
    end
    local Heights = FARM.coverHeights(Room)
    if #Heights == 0 then return end
    local budget = (not FARM.active or R.phase == "waitFloor" or R.phase == "idle") and R.CoverPreloadBudget or R.CoverLevelBudget
    local total, done = #Heights * math.max(#R.CoverParts, 1), 0
    for _, standY in ipairs(Heights) do
        local Level = FARM.coverLevel(standY, nil, budget)
        if not Level then return end
        done += math.min(Level.Index - 1, #R.CoverParts)
        if Level.Index <= #R.CoverParts then
            R.Mapping = done / total
            return
        end
    end
    R.Mapping = nil
    R.CoverPreloaded = R.CoverMap
end

function FARM.runCoverThreats(root, everywhere)
    local R = FARM.RUN
    local Room = UI.map()
    local Monsters = Room and Room:FindFirstChild("Monsters")
    local Threats = {}
    if not Monsters then return Threats end
    for _, Monster in ipairs(Monsters:GetChildren()) do
        local key = FARM.runKey(Monster)
        local ignored = (R.hideIgnore and key == R.hideIgnore and not R.researched[R.hideIgnore]) or (R.research and key == R.research.key)
        if not ignored and not R.IGNORE_BODY[Monster.Name] and not FARM.runPassive(Monster) then
            local T = FARM.twisted(Monster)
            local ok, position = pcall(function()
                return T.Part.Position
            end)
            if ok and position and (everywhere or (position - root.Position).Magnitude < R.DANGER * 2) then
                local instant = FARM.runChaser(Monster)
                table.insert(Threats, {Position = position, Kill = R.KillRadius[Monster.Name] or R.KillDefault, Instant = instant or R.CHASER_DEFAULTS.InstantRadius, Name = FARM.twistedLabel(Monster.Name), Danger = FARM.runDangerous(Monster)})
            end
        end
    end
    return Threats
end

function FARM.twistedLabel(name)
    local info = MONSTER_INFO[name]
    return info and info.name or "Twisted " .. name:gsub("Monster$", "")
end

function FARM.runNearestThreat(point, Threats)
    local nearest, best
    for _, Threat in ipairs(Threats) do
        local distance = FARM.flatDistance(point, Threat.Position)
        if not best or distance < best then
            nearest, best = Threat.Position, distance
        end
    end
    return nearest
end

function FARM.runCoverNeed()
    return FARM.RUN.CoverDepth
end

function FARM.runExitExposed(p, Threats)
    local R = FARM.RUN
    local direction = FARM.coverExitDirection(p.X, p.Y, p.Z)
    if not direction then return nil end
    local t = R.CoverStep
    while t < R.CoverProbe * 3 and FARM.coverSolid(p.X + direction.X * t, p.Y, p.Z + direction.Z * t) do
        t += R.CoverStep
    end
    local exit = Vector3.new(p.X + direction.X * (t + R.ExitProbe), p.Y, p.Z + direction.Z * (t + R.ExitProbe))
    local Room = UI.map()
    local Generators = Room and Room:FindFirstChild("Generators")
    for _, Threat in ipairs(Threats) do
        if FARM.flatDistance(exit, Threat.Position) < Threat.Instant + R.DIVE_BUFFER and not FARM.runRayBlocked(Threat.Position, exit, Generators) then
            return Threat
        end
    end
    return nil
end

function FARM.runCamper(point, Threats, goal)
    local R = FARM.RUN
    local Room = UI.map()
    local Generators = Room and Room:FindFirstChild("Generators")
    local lift = Vector3.new(0, R.SightLift, 0)
    for _, Threat in ipairs(Threats) do
        local distance = Threat.Name ~= "Hazard" and FARM.flatDistance(point, Threat.Position)
        if distance and distance < Threat.Instant + R.SURFACE_BUFFER then
            if distance < R.CampClose or not goal then return Threat end
            local eye = Threat.Position + lift
            local middle = Vector3.new((point.X + goal.X) / 2, point.Y, (point.Z + goal.Z) / 2)
            if not FARM.runRayBlocked(eye, middle + lift, Generators) or not FARM.runRayBlocked(eye, goal + lift, Generators) then return Threat end
        end
    end
    return nil
end

function FARM.runPathBlocker(from, to, Threats)
    local R = FARM.RUN
    if not to then return nil end
    local Room = UI.map()
    local Generators = Room and Room:FindFirstChild("Generators")
    local lift = Vector3.new(0, R.SightLift, 0)
    local lineX, lineZ = to.X - from.X, to.Z - from.Z
    local length = lineX * lineX + lineZ * lineZ
    for _, Threat in ipairs(Threats) do
        local position = Threat.Position
        local pass = Threat.Name ~= "Hazard" and FARM.runPassDistance(from, to, position)
        if pass and pass < Threat.Instant + R.BlockBuffer then
            if pass < Threat.Instant * 0.5 then return Threat end
            local t = length > 0.0001 and math.clamp(((position.X - from.X) * lineX + (position.Z - from.Z) * lineZ) / length, 0, 1) or 0
            local closest = Vector3.new(from.X + lineX * t, from.Y, from.Z + lineZ * t)
            if not FARM.runRayBlocked(position + lift, closest + lift, Generators) then return Threat end
        end
    end
    return nil
end

function FARM.runPathSeen(from, to, Threats)
    local R = FARM.RUN
    local Room = UI.map()
    local Generators = Room and Room:FindFirstChild("Generators")
    local lift = Vector3.new(0, R.SightLift, 0)
    local middle = Vector3.new((from.X + to.X) / 2, from.Y, (from.Z + to.Z) / 2)
    for _, Threat in ipairs(Threats) do
        if Threat.Name ~= "Hazard" then
            local eye = Threat.Position + lift
            if not FARM.runRayBlocked(eye, middle + lift, Generators) or not FARM.runRayBlocked(eye, to + lift, Generators) then return true end
        end
    end
    return false
end

function FARM.runPathVisible(from, to, Threats)
    local R = FARM.RUN
    local Room = UI.map()
    local Ignore = {Room and Room:FindFirstChild("Generators"), Room and Room:FindFirstChild("Monsters"), Workspace:FindFirstChild("InGamePlayers")}
    local lift = Vector3.new(0, R.SightLift, 0)
    local length = FARM.flatDistance(from, to)
    local steps = math.max(1, math.ceil(length / R.CovertStep))
    for _, Threat in ipairs(Threats) do
        if Threat.Name ~= "Hazard" and FARM.flatDistance(from, Threat.Position) < R.CovertRange then
            local eye = Threat.Position + lift
            for i = 1, steps do
                local t = i / steps
                local point = Vector3.new(from.X + (to.X - from.X) * t, from.Y, from.Z + (to.Z - from.Z) * t) + lift
                local ok, hit = pcall(FARM.rayFirst, eye, point, Ignore)
                if not (ok and hit and (hit - eye).Magnitude < (point - eye).Magnitude - 1) then return true end
            end
        end
    end
    return false
end

function FARM.runGuarded(machine, Threats)
    local R = FARM.RUN
    local ok, stand = pcall(function()
        return machine.stand.Position
    end)
    if not ok or not stand then return nil end
    local Room = UI.map()
    local Generators = Room and Room:FindFirstChild("Generators")
    local lift = Vector3.new(0, R.SightLift, 0)
    for _, Threat in ipairs(Threats) do
        if Threat.Danger and FARM.flatDistance(stand, Threat.Position) < Threat.Instant + R.GuardBuffer and not FARM.runRayBlocked(Threat.Position + lift, stand + lift, Generators) then return Threat end
    end
    return nil
end

function FARM.runCoverGround(spot)
    local R = FARM.RUN
    local ok, hit = pcall(function()
        return workspace:Raycast(spot, Vector3.new(0, -(R.hipOffset + 3), 0))
    end)
    if not ok or not hit then return false end
    local okY, y = pcall(function()
        return hit.Position.Y
    end)
    return okY and y ~= nil and math.abs(spot.Y - R.hipOffset - y) <= R.CoverGround
end

function FARM.runPassDistance(from, to, point)
    local lineX, lineZ = to.X - from.X, to.Z - from.Z
    local offsetX, offsetZ = point.X - from.X, point.Z - from.Z
    local length = lineX * lineX + lineZ * lineZ
    if length < 0.0001 then return math.sqrt(offsetX * offsetX + offsetZ * offsetZ) end
    local t = math.clamp((offsetX * lineX + offsetZ * lineZ) / length, 0, 1)
    local dx, dz = offsetX - lineX * t, offsetZ - lineZ * t
    return math.sqrt(dx * dx + dz * dz)
end

function FARM.runFloorDone()
    local Machines = FARM.runMachines()
    if #Machines == 0 then return false end
    for _, machine in ipairs(Machines) do
        if not FARM.runDone(machine) then return false end
    end
    return true
end

function FARM.runGourdyResearch()
    local R = FARM.RUN
    if not SETTINGS.farmResearchTwisteds and not SETTINGS.farmEventTwisteds and not FARM.MASTERY.researchMode() then return nil end
    if FARM.runFullyResearched("GourdyMonster") then return nil end
    local map = UI.map()
    local Monsters = map and map:FindFirstChild("Monsters")
    local Gourdy = Monsters and Monsters:FindFirstChild("GourdyMonster")
    if not Gourdy then return nil end
    local key = FARM.runKey(Gourdy)
    if not key or R.researched[key] then return nil end
    local T = FARM.twisted(Gourdy)
    return Gourdy, T ~= nil and FARM.twistedAttr(T, "IsStationary") == false
end

function FARM.runRushElevator(root, status)
    local R = FARM.RUN
    local base = FARM.runElevatorBase()
    local ok, position = pcall(function()
        return base.Position
    end)
    if not ok or not position then return false end
    R.current = nil
    R.research = nil
    R.hideIgnore = nil
    R.elevatorDive = nil
    R.Cover, R.CoverSpot, R.HopLabel = nil, nil, nil
    FARM.runTravelTo(root, position, position.Y + 3)
    R.phase = "toElevator"
    FARM.setStatus(status)
    return true
end

function FARM.runHopGoal(root, character)
    local R = FARM.RUN
    if R.elevatorDive or FARM.runFloorDone() then
        local base = FARM.runElevatorBase()
        local ok, position = pcall(function()
            return base.Position
        end)
        if ok and position then return position, R.ELEV_ARRIVE, "the elevator", nil end
        return nil
    end
    return FARM.runHideGoal(root, character)
end

function FARM.runFindCover(root, Threats, goal, reach, gain, escape, sneak, toward, covert)
    local R = FARM.RUN
    local p = root.Position
    local Level = FARM.coverLevel(p.Y, p)
    if not Level then return nil end
    local Candidates = {}
    local px, pz = p.X, p.Z
    local gx, gz = goal and goal.X, goal and goal.Z
    local startGoal = goal and math.sqrt((gx - px) ^ 2 + (gz - pz) ^ 2)
    local need = FARM.runCoverNeed()
    local Info = {}
    for _, Threat in ipairs(Threats) do
        local tx, tz = Threat.Position.X, Threat.Position.Z
        table.insert(Info, {X = tx, Z = tz, Mine = math.sqrt((tx - px) ^ 2 + (tz - pz) ^ 2), Instant = Threat.Instant, Danger = Threat.Danger})
    end
    local Hazards = {}
    for _, hazard in ipairs(FARM.runHazards(tick())) do
        local range = hazard.range + R.SPROUT_FLEE_MARGIN
        table.insert(Hazards, {X = hazard.position.X, Z = hazard.position.Z, Range = range * range})
    end
    local cell = R.CoverCell
    local Cells = Level.Cells
    local reachSquared = reach * reach
    local safePass, escapeBuffer, sneakBuffer = R.CoverSafePass, R.EscapeBuffer, R.SneakBuffer
    local Seen = {}
    local slack = R.ZoneSlack
    local towardWeight = escape and R.EscapeToward or R.HideToward
    local startToward = escape and toward and math.sqrt((toward.X - px) ^ 2 + (toward.Z - pz) ^ 2)
    local function consider(Zone, sx, sz, exposure)
        local dx, dz = sx - px, sz - pz
        local travelSquared = dx * dx + dz * dz
        if travelSquared > reachSquared then return end
        for _, H in ipairs(Hazards) do
            if (sx - H.X) ^ 2 + (sz - H.Z) ^ 2 <= H.Range then return end
        end
        local travel = math.sqrt(travelSquared)
        if startToward and startToward - math.sqrt((sx - toward.X) ^ 2 + (sz - toward.Z) ^ 2) < math.max(R.EscapeGain, travel * R.EscapeProgress) then return end
        local safe, away, unseen = true, true, true
        if travel > R.CoverNear or escape then
            for _, T in ipairs(Info) do
                local ox, oz = T.X - px, T.Z - pz
                local pass
                if travelSquared < 0.0001 then
                    pass = T.Mine
                else
                    local t = math.clamp((ox * dx + oz * dz) / travelSquared, 0, 1)
                    pass = math.sqrt((ox - dx * t) ^ 2 + (oz - dz * t) ^ 2)
                end
                local there = math.sqrt((sx - T.X) ^ 2 + (sz - T.Z) ^ 2)
                if there < T.Mine - 2 then away = false end
                if pass < safePass then safe = false end
                if escape and (there < T.Instant + escapeBuffer or pass < T.Mine - 1) then
                    safe, away = false, false
                end
                if sneak and T.Danger and (there < T.Instant + sneakBuffer or pass < T.Instant + sneakBuffer) then
                    safe, away = false, false
                end
                local zone = T.Instant + (T.Danger and sneakBuffer or 0)
                if there < zone or pass < zone then unseen = false end
            end
        end
        local score
        if goal then
            local left = math.sqrt((sx - gx) ^ 2 + (sz - gz) ^ 2)
            if left <= startGoal - gain then score = left end
        elseif toward then
            score = travel + towardWeight * math.sqrt((sx - toward.X) ^ 2 + (sz - toward.Z) ^ 2)
        else
            score = travel
        end
        if score then
            local rank = safe and away and 0 or (away and 2 or 4)
            if goal then rank = unseen and 0 or 4 end
            table.insert(Candidates, {Data = {X = sx, Z = sz, Exposure = exposure, Hidden = R.HideMin, Entry = Zone.Entry}, Score = score, Rank = rank})
        end
    end
    local function nearest(Zone, tx, tz, limitA, limitB)
        local du, dv = tx - Zone.X, tz - Zone.Z
        local u, v = du * Zone.Ax + dv * Zone.Az, du * Zone.Bx + dv * Zone.Bz
        local bestU, bestV, best
        for _, Rect in ipairs(Zone.Rects) do
            local lowU, highU = math.max(Rect[1] + slack, -limitA), math.min(Rect[2] - slack, limitA)
            local lowV, highV = math.max(Rect[3] + slack, -limitB), math.min(Rect[4] - slack, limitB)
            if lowU <= highU and lowV <= highV then
                local cu, cv = math.clamp(u, lowU, highU), math.clamp(v, lowV, highV)
                local d = (cu - u) ^ 2 + (cv - v) ^ 2
                if not best or d < best then bestU, bestV, best = cu, cv, d end
            end
        end
        if not best then return nil end
        return Zone.X + bestU * Zone.Ax + bestV * Zone.Bx, Zone.Z + bestU * Zone.Az + bestV * Zone.Bz, math.min(Zone.Ha - math.abs(bestU), Zone.Hb - math.abs(bestV))
    end
    for cx = math.floor((px - reach) / cell), math.floor((px + reach) / cell) do
        for cz = math.floor((pz - reach) / cell), math.floor((pz + reach) / cell) do
            for _, Zone in ipairs(Cells[cx .. ":" .. cz] or {}) do
                if not Seen[Zone] then
                    Seen[Zone] = true
                    local limitA, limitB = Zone.Ha - need - slack, Zone.Hb - need - slack
                    if limitA >= 0 and limitB >= 0 then
                        local sx, sz, exposure = nearest(Zone, px, pz, limitA, limitB)
                        if sx then consider(Zone, sx, sz, exposure) end
                        if goal then
                            local gxs, gzs, goalExposure = nearest(Zone, gx, gz, limitA, limitB)
                            if gxs then consider(Zone, gxs, gzs, goalExposure) end
                        end
                    end
                end
            end
        end
    end
    table.sort(Candidates, function(a, b)
        if a.Rank ~= b.Rank then return a.Rank < b.Rank end
        return a.Score < b.Score
    end)
    local checked = 0
    for _, Candidate in ipairs(Candidates) do
        if (goal or escape or sneak) and Candidate.Rank > 1 then break end
        if goal and Candidate.Rank > 0 then break end
        if checked >= R.CoverChecks then break end
        checked += 1
        Candidate.Spot = Vector3.new(Candidate.Data.X, p.Y, Candidate.Data.Z)
        if FARM.runCoverGround(Candidate.Spot) and not (escape and FARM.runPathSeen(p, Candidate.Spot, Threats)) and not (covert and FARM.runPathVisible(p, Candidate.Spot, Threats)) then
            FARM.debugNote(string.format("cover pick (%s): rank %d exposure %.1f hidden %.1f need %.1f travel %.1f, %d candidates, %d threats", escape and "escape" or (sneak and "sneak" or (goal and "hop" or "hide")), Candidate.Rank, Candidate.Data.Exposure, Candidate.Data.Hidden, need, FARM.flatDistance(p, Candidate.Spot), #Candidates, #Threats))
            return Candidate.Spot, Candidate.Data
        end
    end
    FARM.debugNote(string.format("cover pick (%s): NONE, need %.1f, %d candidates, %d checked, %d threats", escape and "escape" or (sneak and "sneak" or (goal and "hop" or "hide")), need, #Candidates, checked, #Threats))
    return nil
end

function FARM.twisted(monster)
    local key = FARM.runKey(monster)
    if not key then
        return nil
    end
    local now = tick()
    local name = monster.Name
    local T = FARM.TWISTED[key]
    if not T or T.Name ~= name then
        T = {Model = monster, Name = name, ChaserAt = 0}
        FARM.TWISTED[key] = T
    end
    T.Seen = now
    local okPart, parent = pcall(function()
        return T.Part.Parent
    end)
    if not (okPart and parent) then
        T.Part = monster:FindFirstChild("RootPart") or monster:FindFirstChild("HumanoidRootPart") or monster.PrimaryPart
        T.Origin = monster:FindFirstChild("HumanoidRootPart") or T.Part
        T.Holder = monster:FindFirstChild("ChasingValue")
        T.ChaserAt = 0
    end
    if now >= T.ChaserAt then
        T.ChaserAt = now + 1
        T.Instant, T.Vision, T.Sight = FARM.runChaserRead(monster)
        T.Holder = T.Holder or monster:FindFirstChild("ChasingValue")
    end
    if now >= FARM.TWISTED_PRUNE then
        FARM.TWISTED_PRUNE = now + 5
        for other, Entry in pairs(FARM.TWISTED) do
            if now - Entry.Seen > 10 then FARM.TWISTED[other] = nil end
        end
    end
    return T
end

function FARM.twistedFresh(T)
    local now = tick()
    if now >= (T.ReadUntil or 0) then
        T.ReadUntil = now + FARM.RUN.ATTR_EVERY
        T.Read = {}
        T.TargetRead = false
    end
end

function FARM.twistedAttr(T, name)
    FARM.twistedFresh(T)
    local value = T.Read[name]
    if value == nil then
        local ok, result = pcall(function()
            return T.Model:GetAttribute(name)
        end)
        value = ok and result
        if value == nil then value = false end
        T.Read[name] = value
    end
    return value
end

function FARM.twistedTarget(T)
    FARM.twistedFresh(T)
    if not T.TargetRead then
        T.TargetRead = true
        T.Target = UI.valuePlayer(T.Holder)
    end
    return T.Target
end

function FARM.twistedChasing(T)
    local state = FARM.twistedAttr(T, "ChaseState")
    return state == "run" or state == "attack" or FARM.twistedAttr(T, "Chasing") == true or FARM.twistedAttr(T, "Attacking") == true
end

function FARM.runChaser(monster)
    local T = FARM.twisted(monster)
    if T then
        return T.Instant, T.Vision, T.Sight
    end
    return FARM.runChaserRead(monster)
end

function FARM.runChaserRead(monster)
    local D = FARM.RUN.CHASER_DEFAULTS
    local chaser = monster:FindFirstChild("Chaser")
    local function read(name)
        local value = chaser and chaser:FindFirstChild(name)
        local ok, number = pcall(function()
            return UI.read(value)
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
    local map = UI.map()
    local monsters = map and map:FindFirstChild("Monsters")
    if not monsters then
        return nil, nil
    end

    local bestMonster, bestPart, bestDistance
    for _, monster in ipairs(monsters:GetChildren()) do
        local info = MONSTER_INFO[monster.Name]
        local lethal = skipLethal and info ~= nil and info.rarity == "Lethal"
        if not FARM.runPassive(monster) and not lethal then
            local T = FARM.twisted(monster)
            local part = T and T.Part
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

function FARM.runOtherPlayers()
    local now = tick()
    if now < (FARM.othersAt or 0) then
        return FARM.others
    end
    FARM.othersAt = now + 0.25
    local count = 0
    local myId = LocalPlayer.UserId
    for _, player in ipairs(Players:GetPlayers()) do
        if player.UserId ~= myId and not FARM.whitelist[string.lower(player.Name)] then
            count = count + 1
        end
    end
    FARM.others = count
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

    local best, bestDistance, bestRank
    local Ranks = FARM.runMachineRanks()
    for _, machine in ipairs(FARM.runMachines()) do
        if not FARM.runDone(machine) and not FARM.runConnie(machine) and not FARM.runTaken(machine) and not FARM.runBlotMachine(machine, root, tick()) then
            local ok, stand = pcall(function()
                return machine.stand.Position
            end)
            if ok and stand then
                local d = Vector3.new(stand.X - p.X, 0, stand.Z - p.Z).Magnitude
                local rank = FARM.runMachineRank(machine, Ranks)
                if not bestDistance or rank < bestRank or (rank == bestRank and d < bestDistance) then
                    best, bestDistance, bestRank = stand, d, rank
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

function FARM.clickStep(State, now, button, settle, aim, hold)
    if State.stage == 0 then
        if not FARM.runClick(button) then return false end
        State.stage, State.at = 1, now + (aim or 0.3)
    elseif State.stage == 1 and now >= State.at then
        if not KEYS.mouse(mouse1press) then
            State.stage = 0
            return false
        end
        State.stage, State.at = 2, now + (hold or 0.32)
    elseif State.stage == 2 and now >= State.at then
        pcall(mouse1release)
        State.stage, State.at = 3, now + settle
    elseif State.stage == 3 and now >= State.at then
        State.stage = 0
        return true
    end
    return false
end

function FARM.runHalt()
    FARM.runRmb(false)
    FARM.runHoldW(false)
    if FARM.RUN.noCollide then
        FARM.runCollide(true)
    end
end

function FARM.runClick(button)
    if not FARM.cursorReady() then return false end
    local p, s = button.AbsolutePosition, FARM.guiSize(button)
    local x, y = FARM.cursorPoint(button, p.X + s.X / 2, p.Y + s.Y / 2)
    if not KEYS.mouse(mousemoveabs, x, y) then return false end
    pcall(mousemoverel, 3, 3)
    pcall(mousemoverel, -3, -3)
    return true
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
    local screen = UI.find("DeathScreen", function()
        local gui = UI.playerGui()
        local death = gui and gui:FindFirstChild("DeathGui")
        return death and death:FindFirstChild("DeathScreen")
    end)
    local okScreen, position = pcall(function()
        return screen.AbsolutePosition
    end)

    if okScreen and position and position.Y > -100 then
        return true
    end

    if not character or not root then
        return false
    end

    local hearts = UI.myStat("Health")
    local okHearts, count = pcall(function()
        return UI.read(hearts)
    end)

    if okHearts and type(count) == "number" and count <= 0 then
        return true
    end

    local humanoid = UI.myPart("Humanoid")
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
    local Click = R.deathClick

    if Click.stage == 0 then
        if not FARM.runButtonReady(button, now, wait) then
            FARM.setStatus("Dead, waiting for the button")
            return false
        end
        FARM.setStatus(status)
    end

    local done = FARM.clickStep(Click, now, button, settle)
    if Click.stage ~= 0 or done then
        R.buttonSeen = nil
    end
    return done
end

function FARM.runDeath(now)
    local R = FARM.RUN
    local gui = UI.playerGui()
    local spectator = gui and gui:FindFirstChild("SpectatorGui")
    local bottom = spectator and spectator:FindFirstChild("BottomFrame")
    local leave = bottom and bottom:FindFirstChild("LeaveLobby")

    if FARM.runSized(leave) then
        if R.deathClick.stage == 0 then
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
    local gui = UI.playerGui()
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
        local gui = UI.playerGui()
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
    local gui = UI.playerGui()
    local screen = gui and gui:FindFirstChild("ScreenGui")
    local frame = screen and screen:FindFirstChild("VoteFrame")
    local cards = {}
    if not frame then
        return cards
    end

    for _, child in ipairs(frame:GetChildren()) do
        if child.ClassName == "TextButton" and child.Name ~= "Template" and child.Name ~= "FancyTemplate" then
            local object = child:FindFirstChild("Object")
            local module = object and STRINGS.read(object) or ""
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
    local cards = UI.infoValue("CardVoting", 0.1) == true and FARM.runCards() or {}

    if #cards == 0 then
        if R.voteClick.stage == 2 then
            pcall(mouse1release)
        end
        R.voteClick.stage = 0
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

    if R.voteClick.stage == 0 then
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
    end

    if FARM.clickStep(R.voteClick, now, best.button, 0.5) then
        R.voteClicked = true
        FARM.setStatus("Voted " .. label)
    end

    return true
end

function FARM.runReady(now)
    local R = FARM.RUN
    local seconds = UI.infoValue("GameStarted", 0.1) ~= true and FARM.roundCountdown() or nil

    if not seconds or seconds <= 0 then
        R.readyClicked = false
        R.readyClick.stage = 0
        R.readyWidth = 0
        R.readySteady = 0
        return false
    end

    local button, width = FARM.readyButton()

    if not button or width <= 0 then
        R.readyClicked = false
        R.readyClick.stage = 0
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

    if R.readyClick.stage == 0 then
        FARM.setStatus("Pressing Ready Up")
    end

    if FARM.clickStep(R.readyClick, now, button, 1.5) then
        R.readyClicked = true
    end

    return true
end

function FARM.runUpdate(now)
    local R = FARM.RUN
    FARM.runReleaseItemKey(now)
    local character = LocalPlayer.Character
    local root = character and UI.myPart("HumanoidRootPart")
    local camera = Workspace.CurrentCamera

    if R.dead or FARM.runIsDead(character, root) then
        R.dead = true
        FARM.runHalt()
        R.phase = "idle"
        R.current = nil
        FARM.runDeath(now)
        return
    end

    if not (root and camera) then
        FARM.runHalt()
        R.phase = "idle"
        return
    end

    R.deathClick.stage = 0
    R.FrameTime = math.clamp(now - (R.FrameAt or now), 0.001, 0.1)
    R.FrameAt = now
    local Room = UI.map()
    if Room and SETTINGS.farmSpecialItems then FARM.runQuestScan(Room) end
    if Room and not R.CoverQueue and R.CoverPreloaded == R.CoverMap and R.CoverBuildPhases[R.phase] and FARM.coverNearFloor(root.Position.Y) then FARM.coverLevel(root.Position.Y) end

    local underground = R.phase == "dive" or R.phase == "hide"
    if not SETTINGS.allowFarmWithPlayers and not underground then
        local others = FARM.runOtherPlayers()
        if others > 0 then
            FARM.runHalt()
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
            FARM.runHalt()
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
    local hidingFor = (R.phase == "dive" or R.phase == "hide") and R.hideIgnore
    local nearest, chasing, panic, seen, danger = FARM.runThreat(root, (researching and R.research.key) or hidingFor or nil)
    local hiding = R.phase == "dive" or R.phase == "hide"

    local travelIgnore = SETTINGS.farmIgnoreTwistedsTravel and (R.phase == "tween" or R.phase == "collect")
    local grabbing = R.phase == "collect" and R.collect and R.collectDeadline and now < R.collectDeadline
    local nearMachine = R.current and select(2, pcall(function()
        return FARM.flatDistance(root.Position, R.current.prompt.Position) < R.MachineCover
    end)) == true
    local crowded, touched = false, false
    if R.TravelPhases[R.phase] then
        local p = root.Position
        local okGoal, goal = pcall(function()
            return R.collect and R.collect.prompt.Position
        end)
        goal = okGoal and goal or nil
        for _, Threat in ipairs(FARM.frameThreats(root, now)) do
            if Threat.Name ~= "Hazard" then
                if FARM.flatDistance(p, Threat.Position) < Threat.Kill + (SETTINGS.farmAvoidAura or R.AvoidMargin) then
                    crowded = Threat.Name .. " touched the avoid aura"
                    touched = true
                end
                if goal and FARM.flatDistance(goal, Threat.Position) < R.ItemGuard then crowded = Threat.Name .. " is near the " .. (R.collect.kind == "capsule" and "Research Capsule" or tostring(R.collect.name)) end
            end
        end
    end
    if crowded and not R.CrowdedNoted then FARM.debugNote(string.format("travel blocked: %s, allowing cover", crowded)) end
    R.CrowdedNoted = crowded or nil
    local farChase = not danger and R.TravelPhases[R.phase] and not nearMachine and not crowded
    if (chasing or touched or (panic and now >= R.PanicGraceUntil)) and not hiding and not travelIgnore and not grabbing and not farChase and R.phase ~= "sacrifice" and not FARM.runSafeInElevator(character) then
        FARM.runRmb(false)
        if R.current and FARM.runEngagedBy(R.current) == LocalPlayer.Name then
            KEYS.tap(R.E_KEY)
        end

        local toElevator = R.phase == "toElevator"
        if (chasing or not danger) and (toElevator or FARM.runFloorDone()) then
            local status = chasing and "Twisted chasing, running to the elevator" or "Twisted near, running to the elevator"
            FARM.setStatus(status)
            if not toElevator and FARM.runRushElevator(root, status) then return end
        else
            R.research = nil
            R.hideIgnore = nil
            FARM.runSprintOff()
            FARM.debugNote(string.format("dive trigger: chasing=%s panic=%s seen=%s nearest=%.1f grace=%.1f%s", tostring(chasing), tostring(panic), tostring(seen), nearest or -1, R.PanicGraceUntil - now, chasing and " (" .. tostring(R.ChaseWhy) .. ")" or ""))
            FARM.runDive(root, now, toElevator and "Twisted near, diving to the elevator" or "Twisted near, diving")
            R.elevatorDive = toElevator or nil
            return
        end
    end

    if R.phase == "toElevator" and not chasing and now >= (R.GourdyCheckAt or 0) then
        R.GourdyCheckAt = now + R.GourdyCheckEvery
        local Gourdy, emerged = FARM.runGourdyResearch()
        if Gourdy and emerged then
            FARM.runHoldW(false)
            R.phase = "pick"
            FARM.setStatus("Twisted Gourdy emerged, going for research")
            return
        end
    end

    if not hiding and R.phase ~= "flee" and R.phase ~= "sacrifice" then
        local tendril = FARM.runHazardNear(root.Position, now)
        if tendril then
            FARM.runRmb(false)
            if R.current and FARM.runEngagedBy(R.current) == LocalPlayer.Name then
                KEYS.tap(R.E_KEY)
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

    if hiding or R.phase == "flee" then
        FARM.runLeaveMachine(now)
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
        local step = FARM.stepLength(now)
        local x, z = p.X + direction.X * step, p.Z + direction.Z * step
        local floor = FARM.runFloorY(x, R.fleeY, z)
        local y = floor and (floor + R.hipOffset) or R.fleeY
        R.fleeY = y
        root.Position = Vector3.new(x, y, z)
        return
    end

    if (R.phase == "dive" or R.phase == "hide") and (chasing or not danger) and FARM.runFloorDone() and FARM.runRushElevator(root, chasing and "Twisted chasing, running to the elevator" or "Running to the elevator") then
        return
    end

    if R.phase == "dive" then
        FARM.runCollide(false)
        FARM.runFreeze(root)
        local p = root.Position
        if not R.Cover and now >= R.CoverAt then
            R.CoverAt = now + R.CoverRescan
            R.Cover, R.CoverSpot = FARM.runFindCover(root, FARM.runCoverThreats(root), nil, R.CoverReach, 0)
        end

        local target = R.Cover
        if not target then
            local nearest = FARM.runNearestThreat(p, FARM.runCoverThreats(root))
            if not nearest then
                FARM.runHoldW(false)
                R.phase = "hide"
                return
            end
            local away = Vector3.new(p.X - nearest.X, 0, p.Z - nearest.Z)
            local direction = away.Magnitude > 0.1 and away.Unit or Vector3.new(1, 0, 0)
            FARM.runHoldW(true)
            FARM.runFace(camera, root, p + direction * 10)
            local step = FARM.stepLength(now)
            root.Position = Vector3.new(p.X + direction.X * step, p.Y, p.Z + direction.Z * step)
            FARM.setStatus("No cover in reach, moving away")
            return
        end

        local flat = Vector3.new(target.X - p.X, 0, target.Z - p.Z)
        if flat.Magnitude <= R.CoverArrive then
            FARM.runHoldW(false)
            root.Position = target
            R.phase = "hide"
            R.HideStart = now
            R.WatcherAt = 0
            R.WatcherCache = nil
            R.CamperAt = 0
            R.CamperCache = nil
            R.BlockerCache = nil
            FARM.setStatus("Hiding in cover")
            return
        end
        FARM.runHoldW(true)
        FARM.runFace(camera, root, target)
        local step = math.min(FARM.stepLength(now), flat.Magnitude)
        local direction = FARM.runSteer(root, flat.Unit, now)
        local y = p.Y + math.clamp(target.Y - p.Y, -step, step)
        root.Position = Vector3.new(p.X + direction.X * step, y, p.Z + direction.Z * step)
        FARM.setStatus(R.HopLabel and ("Sneaking through cover to " .. R.HopLabel) or "Twisted near, going into cover")
        return
    end

    if R.phase == "hide" then
        FARM.runCollide(false)
        FARM.runFreeze(root)
        local p = root.Position
        local hold = R.Cover or p
        root.Position = hold

        local tendril = FARM.runHazardNear(p, now, R.SPROUT_FLEE_MARGIN)
        if tendril then
            local Threats = FARM.runCoverThreats(root)
            table.insert(Threats, {Position = tendril, Kill = R.KillDefault, Instant = 0, Name = "Hazard"})
            R.Cover, R.CoverSpot = FARM.runFindCover(root, Threats, nil, R.CoverReach, 0, false, false, (FARM.runHopGoal(root, character)))
            R.CoverAt = now + R.CoverRescan
            R.clearSince = nil
            R.HopLabel = nil
            R.phase = "dive"
            FARM.setStatus("Sprout tendril or active Rodger near, changing cover")
            return
        end

        local Threats = FARM.runCoverThreats(root)
        if now >= (R.CamperAt or 0) then
            R.CamperAt = now + R.WatcherEvery
            local goal = FARM.runHopGoal(root, character)
            R.CamperCache = FARM.runCamper(p, Threats, goal) or false
            R.BlockerCache = FARM.runPathBlocker(p, goal, Threats) or false
        end
        local Camper = R.CamperCache or nil
        local Blocker = R.BlockerCache or nil
        if now - (R.HideStart or now) >= R.ExposedWait then
            R.WatcherCache = nil
        elseif now >= (R.WatcherAt or 0) then
            R.WatcherAt = now + R.WatcherEvery
            R.WatcherCache = FARM.runExitExposed(p, Threats) or false
        end
        local Watcher = R.WatcherCache or nil
        if chasing or seen or Camper or Watcher or Blocker or FARM.runHazardNear(p, now) or FARM.runBlotHandNear(p, root) then
            R.clearSince = nil
        elseif not R.clearSince then
            R.clearSince = now
        end

        local clear = R.clearSince and now - R.clearSince >= R.CLEAR_TIME
        local campDistance = Camper and FARM.flatDistance(p, Camper.Position)
        local camping = Camper and campDistance < Camper.Instant and Camper
        if not camping or camping.Name ~= R.CampName then R.CampName, R.CampSince = camping and camping.Name, now end
        local leaving = camping and R.CampLast and campDistance > R.CampLast + 0.5
        if now >= (R.CampLastAt or 0) then R.CampLast, R.CampLastAt = campDistance, now + 0.5 end
        if not clear and camping and not leaving and not chasing and now - R.CampSince >= R.CampTime and now >= R.EscapeAt then
            R.EscapeAt = now + R.EscapeEvery
            FARM.debugNote(string.format("camper %s at %.0f studs (instant %.0f) for %.1f s", camping.Name, FARM.flatDistance(p, camping.Position), camping.Instant, now - R.CampSince))
            local spot, Spot = FARM.runFindCover(root, Threats, nil, R.CoverReach, 0, true, false, (FARM.runHopGoal(root, character)))
            if spot then
                R.Cover, R.CoverSpot = spot, Spot
                R.HopLabel = nil
                R.clearSince = nil
                R.phase = "dive"
                FARM.setStatus(string.format("%s is camping nearby, moving to safer cover", Camper.Name))
                return
            end
        end
        if not clear and #Threats > 0 and now >= R.SneakAt then
            R.SneakAt = now + R.SneakEvery
            local goal, radius, label, ignore = FARM.runHopGoal(root, character)
            if goal and FARM.flatDistance(p, goal) > (radius or 0) + R.HopDirect then
                local spot, Spot = FARM.runFindCover(root, Threats, goal, R.HopReach, R.HopGain, false, true, nil, chasing or seen)
                if spot then
                    R.Cover, R.CoverSpot = spot, Spot
                    R.HopLabel = label
                    R.hideIgnore = ignore
                    R.clearSince = nil
                    R.hideUntil = now + R.HIDE_MAX
                    R.phase = "dive"
                    return
                end
            end
        end
        if not clear and now < R.hideUntil then
            FARM.runHoldW(false)
            FARM.runRmb(false)
            local Nearby = Camper or Watcher
            FARM.setStatus(Nearby and string.format("Hiding in cover, %s is nearby", Nearby.Name) or (Blocker and string.format("Waiting, %s is in the way", Blocker.Name)) or "Hiding in cover")
            return
        end

        local goal, radius, label, ignore = FARM.runHopGoal(root, character)

        if goal and FARM.flatDistance(p, goal) > (radius or 0) + R.HopDirect then
            local spot, Spot = FARM.runFindCover(root, FARM.runCoverThreats(root), goal, R.HopReach, R.HopGain)
            if spot then
                R.Cover, R.CoverSpot = spot, Spot
                R.HopLabel = label
                R.hideIgnore = ignore
                R.clearSince = nil
                R.hideUntil = now + R.HIDE_MAX
                R.phase = "dive"
                return
            end
        end

        FARM.runHoldW(false)
        FARM.runRmb(false)
        R.hideIgnore = nil
        R.HopLabel = nil
        R.elevatorDive = nil
        R.PanicGraceUntil = now + R.PanicGrace
        R.Cover, R.CoverSpot = nil, nil
        R.InCover = true
        R.phase = "pick"
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
        FARM.runHalt()
        R.current = nil
        R.phase = "pick"
        FARM.setStatus("Connie got into the machine, leaving")
        return
    end

    if R.current and R.targetKind == "machine" and (R.phase == "tween" or R.phase == "aim" or R.phase == "working") and FARM.runTaken(R.current) then
        FARM.runHalt()
        R.current = nil
        R.phase = "pick"
        FARM.setStatus("Another player took the machine, leaving")
        return
    end

    if R.current and R.targetKind == "machine" and (R.phase == "tween" or R.phase == "aim" or R.phase == "working") and FARM.runBlotMachine(R.current, root, now) then
        FARM.runRmb(false)
        FARM.runHoldW(false)
        if R.phase == "working" then
            KEYS.tap(R.E_KEY)
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
        if not R.InCover then FARM.runCollide(true) end
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
            R.hurtFrom = FARM.health()
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
            R.SpecialUntil = nil
            R.targetKind = grab.kind
            if grab.standY then
                local target = grab.prompt.Position
                local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
                local stop = flat.Magnitude > R.ApproachGap and (target - flat.Unit * R.ApproachGap) or target
                local floor = FARM.runFloorY(stop.X, math.max(root.Position.Y, target.Y), stop.Z)
                FARM.runTravelTo(root, Vector3.new(stop.X, target.Y, stop.Z), floor and (floor + R.hipOffset) or grab.standY)
            else
                FARM.runTravelTo(root, grab.prompt.Position, grab.prompt.Position.Y + R.COLLECT_Y)
            end
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

        local best, bestDistance, bestRank
        local blocked = false
        local blotBlocked = false
        local takenBlocked = false
        local guardedBest, guardedDistance, guardedRank, Guard
        local Threats = FARM.runCoverThreats(root, true)
        local Ranks = FARM.runMachineRanks()
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
                    local rank = FARM.runMachineRank(machine, Ranks)
                    local Guarding = FARM.runGuarded(machine, Threats)
                    if Guarding then
                        if not guardedDistance or rank < guardedRank or (rank == guardedRank and d < guardedDistance) then
                            guardedBest, guardedDistance, guardedRank, Guard = machine, d, rank, Guarding
                        end
                    elseif not bestDistance or rank < bestRank or (rank == bestRank and d < bestDistance) then
                        best, bestDistance, bestRank = machine, d, rank
                    end
                end
            end
        end

        if best then
            R.GuardSince = nil
        elseif guardedBest then
            R.GuardSince = R.GuardSince or now
            if now - R.GuardSince < R.GuardWait then
                R.current = nil
                FARM.setStatus(string.format("%s is near the machine, waiting (%ds)", Guard.Name, math.ceil(R.GuardWait - (now - R.GuardSince))))
                return
            end
            best = guardedBest
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
            local Gourdy = FARM.runGourdyResearch()
            if Gourdy then
                local key = FARM.runKey(Gourdy)
                if R.GourdyWaitKey ~= key then
                    R.GourdyWaitKey = key
                    R.GourdyWaitUntil = now + R.GourdyWait
                end
                if now < R.GourdyWaitUntil then
                    R.current = nil
                    FARM.setStatus(string.format("Waiting for Twisted Gourdy to emerge for research (%ds)", math.ceil(R.GourdyWaitUntil - now)))
                    return
                end
            end
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

        local step = math.min(FARM.stepLength(now), distance)
        local direction = FARM.runSteer(root, flat.Unit, now)
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
            FARM.runHalt()
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
        local speed = FARM.stepLength(now)
        local step = math.min(speed, distance)
        local direction = distance > 0.01 and FARM.runSteer(root, flat.Unit, now) or Vector3.new(0, 0, 0)
        local y = p.Y + math.clamp(standY - p.Y, -speed, speed)
        root.Position = Vector3.new(p.X + direction.X * step, y, p.Z + direction.Z * step)
        return
    end

    if R.phase == "sacrifice" and R.hurtFrom then
        local health = FARM.health()
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
            FARM.runHalt()
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
        local step = math.min(FARM.stepLength(now), distance)
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

        if target and target.kind == "special" then
            R.SpecialUntil = R.SpecialUntil or now + R.SpecialHold
            if target.model.Parent == nil or now >= R.SpecialUntil then
                R.skip[target.spot] = true
                R.SpecialUntil = nil
                R.collect = nil
                R.phase = "pick"
                return
            end
            FARM.setStatus("Collecting " .. R.SpecialName)
            return
        end

        if target and target.kind == "door" and doorUsed(target.model) then
            FARM.debugNote(string.format("trick or treat door used after %d tries", R.collectTries))
            R.skip[target.spot] = true
            R.collect = nil
            R.phase = "pick"
            return
        end

        if not target or target.model.Parent == nil or (target.kind ~= "quest" and target.kind ~= "door" and not target.model:FindFirstChild("Prompt")) then
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

        if target.kind ~= "buy" then
            local p = root.Position
            for _, Threat in ipairs(FARM.frameThreats(root, now)) do
                local dx, dz = p.X - Threat.Position.X, p.Z - Threat.Position.Z
                local distance = math.sqrt(dx * dx + dz * dz)
                if Threat.Name ~= "Hazard" and distance < Threat.Kill + (SETTINGS.farmAvoidAura or R.AvoidMargin) + R.CollectDodge then
                    local away = distance > 0.01 and Vector3.new(dx / distance, 0, dz / distance) or Vector3.new(1, 0, 0)
                    root.Position = p + away * FARM.stepLength(now)
                    FARM.setStatus(string.format("Dodging %s near %s", Threat.Name, target.kind == "capsule" and "Research Capsule" or target.name))
                    return
                end
            end
        end

        if target.kind == "buy" and okPos and position then
            if FARM.runPromptShows(target.name) == false then
                target.wrongSince = target.wrongSince or now
                if now - target.wrongSince < 3 then
                    FARM.runFace(camera, root, position)
                    if flat > 1.5 then
                        local direction = Vector3.new(position.X - root.Position.X, 0, position.Z - root.Position.Z).Unit
                        local step = math.min(flat - 1.5, FARM.stepLength(now))
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

        if (target.kind == "quest" or target.kind == "door") and okPos and position then
            FARM.runFace(camera, root, position)
        end

        if now >= R.at then
            if R.collectTries >= R.COLLECT_TRIES then
                R.skip[target.spot] = true
                R.collect = nil
                R.phase = "pick"
                return
            end

            if target.kind == "door" then
                if not KEYS.hold(R.E_KEY, R.DoorHold) then return end
            elseif not KEYS.tap(R.E_KEY) then
                return
            end
            if target.kind == "rodger" then
                R.skip[target.spot] = true
                if target.key then
                    R.researched[target.key] = true
                end
            end
            R.collectTries = R.collectTries + 1
            R.at = now + R.COLLECT_RETRY
            FARM.setStatus((target.kind == "buy" and "Buying " or (target.kind == "door" and "Opening " or "Collecting ")) .. (target.kind == "capsule" and "Research Capsule" or target.name))
        end
        return
    end

    if R.phase == "aim" then
        local aligned = FARM.runFace(camera, root, R.current.prompt.Position)
        if aligned or now >= R.at then
            FARM.runRmb(false)
            KEYS.tap(R.E_KEY)
            R.phase = "working"
            R.at = now + R.REPRESS
        end
        return
    end

    if R.phase == "working" then
        FARM.runRmb(false)
        local cur, req, valid = FARM.runFill(R.current)
        FARM.setStatus(valid and string.format("Working %d/%d", math.floor(cur), math.floor(req)) or "Working")

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
    KEYS.set(FARM.LOBBY.SHIFT, false)
    if R.noCollide then
        FARM.runCollide(true)
    end
    FARM.runReleaseItemKey(0, true)
    R.phase = "idle"
    R.current = nil
    R.elevatorDive = nil
    R.Cover, R.CoverSpot, R.HopLabel = nil, nil, nil
    R.deathClick.stage = 0
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
    for _, Model in ipairs(UI.roster().Models) do
        if Model.Name == "SquirmMonster" then
            return Model
        end
    end

    return nil
end

function SQUIRM.isTargetingMe(model)
    if not SQUIRM.WARN_STATES[model:GetAttribute("SquirmState") or ""] then
        return false
    end

    local root = model:FindFirstChild("RootPart") or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    local character = LocalPlayer.Character
    local myRoot = character and UI.myPart("HumanoidRootPart")
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
            drawing = makeText(SQUIRM.WARN_SIZE)
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
        if UI.bool(UI.myStat("InElevator")) == true then return true end
        local active = UI.infoValue("FloorActive", 0.25)
        if active ~= nil and active ~= true then return true end
        return Workspace.CurrentRoom:FindFirstChildOfClass("Model") == nil
    end)
    return not ok or blocked
end

function TOON.blackout()
    local Info = UI.info()
    local Flag = Info and Info:FindFirstChild("BlackOut")
    local ok, value = pcall(function()
        return UI.bool(Flag)
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
    if Cost and UI.read(Cost) > 0 and not Rule.tapes then return false end
    if Rule.hurt then
        local health, maxHealth = FARM.health()
        if not (health and health < maxHealth) then return false end
    end
    if Rule.freeSlot and not TOON.freeSlot(char) then return false end
    return UI.read(Ability.CurrentCooldown) <= 0
end

function TOON.confirm(char, now)
    local Pending = TOON.pending
    if not Pending then return end
    local ok, cooldown = pcall(function()
        return UI.read(char.Abilities.Ability1.CurrentCooldown)
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
        KEYS.tap(TOON.KEY)
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
    if not ((SETTINGS.autoAbility or mastery) and Rule and FARM.running(now)) then return end
    if PLACE_MODE ~= "main" or not KEYS.allowed() then return end
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
    KEYS.tap(TOON.KEY)
    if Rule.presses == 2 then TOON.secondAt = now + TOON.SECOND_PRESS end
    if perFloor then TOON.pending = {Name = name, Floor = floor, At = now, Instant = Rule.instant} end
    TOON.nextAt = now + TOON.RETRY
end

function REPORT.fresh(now)
    return {startedAt = now, lastBeat = 0, runs = 0, deaths = 0, ichor = 0, machines = 0, capsules = 0, bestFloor = 0, summaryAt = {}}
end

function REPORT.load()
    local now = UI.clock()
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
    S.lastBeat = UI.clock()
    UI.folder("DW")
    pcall(function()
        writefile(REPORT.FILE, HttpService:JSONEncode(S))
    end)
end

function REPORT.stats()
    local ok, Stats = pcall(function()
        local Mine = UI.info().PlayerStats[LocalPlayer.Name]
        return {ichor = UI.read(Mine.Ichor), tapes = UI.read(Mine.SurvivalPoints), machines = UI.read(Mine.Generators), capsules = UI.read(Mine.Capsules), research = UI.read(Mine.Monsters)}
    end)
    return ok and Stats or nil
end

function REPORT.research()
    local ok, Values = pcall(function()
        local Folder = game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Research
        local out = {}
        for _, Value in ipairs(Folder:GetChildren()) do
            out[Value.Name] = UI.read(Value)
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
            return UI.read(Quest.Current), UI.read(Quest.Amount)
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
        return UI.read(game:GetService("ReplicatedStorage").PlayerData[tostring(LocalPlayer.UserId)].Coin)
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
    local names, seen = {}, {}
    for _, Monster in ipairs(PLACE_MODE == "main" and UI.roster().Models or {}) do
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
    if not (PLACE_MODE == "main" and UI.map()) then return nil end
    local names = REPORT.twistedNames()
    return #names > 0 and table.concat(names, ", ") or "None"
end

function REPORT.summary(Options, heading)
    local S = REPORT.session
    local now = UI.clock()
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
        local hearts, maxHearts = FARM.health()
        local health = (hearts and maxHearts > 0) and (" (" .. math.floor(hearts + 0.5) .. "/" .. math.floor(maxHearts + 0.5) .. " HP)") or ""
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
        REPORT.field("Run Time:", REPORT.duration(UI.clock() - (S.runStartedAt or UI.clock()))),
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
    S.lastRunTime = UI.clock() - (S.runStartedAt or UI.clock())
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
            S.runStartedAt = UI.clock()
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
        REPORT.queuedAt = UI.clock()
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
    if PLACE_MODE ~= "main" or not FARM.running(tick()) then
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
        if not S.runResearch or now >= (REPORT.researchAt or 0) then
            REPORT.researchAt = now + 10
            local Research = REPORT.research()
            if Research then
                if not S.research then S.research = Research end
                if not S.runResearch then S.runResearch = Research end
                S.lastResearch = Research
            end
        end
        local health = FARM.health()
        if health and health <= 0 then
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
        local clock = UI.clock()
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
    local clock = UI.clock()
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

function RENDER.address()
    if not RENDER.Service then
        for _, Child in ipairs(game:GetChildren()) do
            if Child.ClassName == "RunService" then RENDER.Service = tonumber(Child.Address) break end
        end
    end
    local address = RENDER.Service
    if not address then return nil end
    if memory_read("double", address + RENDER.CheckOffset) ~= 0.05 then return nil end
    local value = memory_read("byte", address + RENDER.Offset)
    if value ~= 0 and value ~= 1 then return nil end
    return address
end

function RENDER.set(enabled)
    local address = RENDER.address()
    if not address then return false end
    local value = enabled and 1 or 0
    if memory_read("byte", address + RENDER.Offset) ~= value then
        memory_write("byte", address + RENDER.Offset, value)
    end
    return true
end

function RENDER.clearAddress()
    local base = getbase()
    local engine = memory_read("uintptr_t", base + RENDER.Clear.Global)
    if not engine or engine < 0x10000 then return nil end
    if memory_read("uintptr_t", engine) - base ~= RENDER.Clear.VisualEngine then return nil end
    local holder = memory_read("uintptr_t", engine + RENDER.Clear.Holder)
    if not holder or holder < 0x10000 then return nil end
    local address = holder + RENDER.Clear.Color
    for index = 0, 3 do
        local value = memory_read("float", address + index * 4)
        if not value or value < 0 or value > 1 then return nil end
    end
    return address
end

function RENDER.setClear(black)
    local address = RENDER.clearAddress()
    if not address then return end
    if black then
        if not RENDER.Clear.Saved then
            RENDER.Clear.Saved = {}
            for index = 0, 3 do RENDER.Clear.Saved[index] = memory_read("float", address + index * 4) end
        end
        for index = 0, 2 do
            if memory_read("float", address + index * 4) ~= 0 then memory_write("float", address + index * 4, 0) end
        end
    elseif RENDER.Clear.Saved then
        for index = 0, 3 do memory_write("float", address + index * 4, RENDER.Clear.Saved[index]) end
        RENDER.Clear.Saved = nil
    end
end

function RENDER.update(now)
    if SETTINGS.disable3d ~= RENDER.Wanted then
        RENDER.Wanted = SETTINGS.disable3d
        RENDER.NextAt = 0
    end
    if now < RENDER.NextAt then return end
    RENDER.NextAt = now + 1
    if not SETTINGS.disable3d and not RENDER.Applied then return end
    if not VantaUI.MemoryAccess() then return end
    local ok, done = pcall(RENDER.set, not SETTINGS.disable3d)
    if ok and done then RENDER.Applied = SETTINGS.disable3d end
    pcall(RENDER.setClear, SETTINGS.disable3d)
end

function RENDER.cleanup()
    pcall(RENDER.setClear, false)
    if not RENDER.Applied then return end
    pcall(RENDER.set, true)
    RENDER.Applied = false
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

    local function toggle(Section, id, title, key, color)
        UI.Binds[id] = {Key = key}
        return Section:AddToggle({Id = id, Title = title, Default = SETTINGS[key], TextColor = color})
    end

    local function slider(Section, id, title, key, minimum, maximum, decimals, suffix, map)
        UI.Binds[id] = {Key = key, Map = map}
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
    toggle(Filters, "dw_visuals_special", "Special Collectibles", "showSpecial")
    picker(Filters, "dw_visuals_special_color", "Special Collectibles Color", "Special")
    toggle(Filters, "dw_visuals_doors", "Doors [Halloween]", "showDoors")
    picker(Filters, "dw_visuals_doors_color", "Doors [Halloween] Color", "Doors")
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
    slider(Performance, "dw_visuals_update_rate", "Update Delay", "updateInterval", 0.005, 0.2, 3, "s", function(value) return math.max(0.005, value) end)
    slider(Performance, "dw_visuals_scan_rate", "Scan Delay", "scanInterval", 0.5, 5, 1, "s", function(value) return math.max(0.5, value) end)
    toggle(Performance, "dw_disable_3d", "Disable 3D Rendering", "disable3d")

    local SkillCheck = AutomationTab:AddSection("Skill Check", "Left")
    toggle(SkillCheck, "dw_skillcheck_enabled", "Auto Skill Check", "autoSkillCheck")
    toggle(SkillCheck, "dw_skillcheck_random", "Randomize Press", "skillCheckRandom")
    slider(SkillCheck, "dw_skillcheck_aim", "Aim Point", "skillCheckAim", 0, 100, 0, "%")
    slider(SkillCheck, "dw_skillcheck_lead", "Press Lead", "skillCheckLead", 0, 120, 0, " ms")
    slider(SkillCheck, "dw_skillcheck_treadmill_rate", "Treadmill Tap Rate", "treadmillTapRate", 1, 30, 0, " cps")

    local Experimental = AutomationTab:AddSection("Experimental", "Left")
    toggle(Experimental, "dw_always_golden", "Always hit Golden", "alwaysGolden", Color3.fromRGB(45, 200, 235))
    Experimental:AddParagraph({Title = "", Content = "This will always hit Golden no matter what. Does not use inputs. Allows you to minimize Roblox."})
    toggle(Experimental, "dw_better_barnaby", "Better Auto Barnaby", "betterBarnaby", Color3.fromRGB(45, 200, 235))
    Experimental:AddParagraph({Title = "", Content = "Does not use inputs. Allows you to minimize Roblox."})
    Experimental:AddButton({Title = "Remap the memory offsets", Callback = GOLDEN.remap})
    GOLDEN.Map.Label = Experimental:AddParagraph({Title = "", Content = "Status: Unknown"})
    toggle(Experimental, "dw_auto_remap", "Remap automatically on join", "autoRemap")
    if not GOLDEN.Map.Loaded then GOLDEN.loadMap() end
    GOLDEN.showStatus()
    Experimental:AddParagraph({Title = "", Content = "Finds the memory offsets again after a Roblox update. Press it when the status says Requires a remap."})

    local Barnaby = AutomationTab:AddSection("Barnaby", "Right")
    toggle(Barnaby, "dw_barnaby_enabled", "Auto Barnaby", "autoBarnaby")
    toggle(Barnaby, "dw_barnaby_coins", "Collect Barnaby Coins", "barnabyCollectCoins")
    toggle(Barnaby, "dw_barnaby_risky_coins", "Risk for more coins (Not recommended)", "barnabyRiskyCoins", Color3.fromRGB(204, 170, 62))
    Barnaby:AddLabel("Also plays the Swimmy Barnaby arcade in the lobby.")

    local Squirm = AutomationTab:AddSection("Squirm", "Right")
    toggle(Squirm, "dw_squirm_escape", "Auto Squirm Escape", "autoSquirmEscape")
    slider(Squirm, "dw_squirm_tap_rate", "Squirm Tap Rate", "squirmTapRate", 1, 16, 0, " cps")

    local Farm = FarmTab:AddSection("Autofarm", "Left")
    toggle(Farm, FARM.TOGGLE_ID, "Aggressive Auto-farm", "aggressiveAutoFarm", Color3.fromRGB(204, 170, 62))
    slider(Farm, "dw_farm_speed", "Travel Speed", "farmSpeedMultiplier", 1, FARM.RUN.SprintMultiplierMax, 2, "x", function(value) return math.clamp(value, 1, FARM.RUN.SprintMultiplierMax) end)
    Farm:AddParagraph({Title = "", Content = "If it pushes you back, try lowering your speed. 1.42x is the maximum speed the game accepts."})
    slider(Farm, "dw_farm_avoid_aura", "Avoid Aura", "farmAvoidAura", 2.5, 12.5, 1, " studs")
    slider(Farm, "dw_farm_floor_limit", "Floor Limit", "floorLimit", 5, 50, 0, " floors")
    toggle(Farm, "dw_farm_unlimited", "Unlimited Floors", "unlimitedFloors")
    toggle(Farm, "dw_farm_auto_resume", "Resume after teleport", "farmAutoResume")
    toggle(Farm, "dw_farm_hide_teleport", "Hide the interface post-teleporting", "farmHideOnTeleport")

    local FarmPlayers = FarmTab:AddSection("Players", "Left")
    toggle(FarmPlayers, "dw_farm_with_players", "Allow everyone (Ignore Whitelist)", "allowFarmWithPlayers", Color3.fromRGB(214, 84, 72))

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
    local Priority = toggle(Machines, "dw_farm_machine_priority", "Machines Priority", "farmMachinePriority")
    local Order = {}
    for kind in string.gmatch(SETTINGS.farmMachineOrder, "[^,]+") do table.insert(Order, kind) end
    UI.Binds.dw_farm_machine_order = {Key = "farmMachineOrder", Map = function(value) return table.concat(value, ",") end}
    local PriorityOrder = Machines:AddDropdown({Id = "dw_farm_machine_order", Title = "Priority Order", Groups = {{Name = "Priority", Values = FARM.MachineOrder}}, Default = Order, Reorder = true})
    Priority:OnChanged(function(value)
        PriorityOrder:SetHidden(not value)
    end)
    toggle(Machines, "dw_farm_treadmill_run", "Run on Treadmill Machines", "farmTreadmillRun")
    slider(Machines, "dw_farm_treadmill_stop", "Stop Running at", "farmTreadmillStopAt", 0, 270, 0, " stamina")

    local Collecting = FarmTab:AddSection("Collecting", "Right")
    toggle(Collecting, "dw_farm_event_items", "Collect Event Collectibles", "farmEventItems")
    toggle(Collecting, "dw_farm_special_items", "Collect Special Collectibles (On events)", "farmSpecialItems")
    toggle(Collecting, "dw_farm_trick_or_treat", "Use Trick or Treat Doors", "farmTrickOrTreat")
    toggle(Collecting, "dw_farm_heal_items", "Collect & Use healing items", "farmHealItems")
    toggle(Collecting, "dw_farm_extraction_items", "Collect & Use extraction items", "farmExtractionItems")
    local CapsulesIchor = toggle(Collecting, "dw_farm_capsules", "Collect Research Capsules [For Ichor]", "farmCapsules")
    local CapsulesResearch = toggle(Collecting, "dw_farm_capsules_research", "Collect Research Capsules [For Research]", "farmCapsulesResearch")
    Collecting:AddParagraph({Title = "", Content = "For Ichor: Collects every capsules\nFor Research: Collects only for Research"})
    CapsulesIchor:OnChanged(function(value)
        if value and CapsulesResearch.Value then CapsulesResearch:Set(false) end
    end)
    CapsulesResearch:OnChanged(function(value)
        if value and CapsulesIchor.Value then CapsulesIchor:Set(false) end
    end)

    local FarmTwisteds = FarmTab:AddSection("Twisteds", "Left")
    local SeenResearch = toggle(FarmTwisteds, "dw_farm_research_twisteds", "Let Twisteds see you first [For Research]", "farmResearchTwisteds")
    local SeenEvent = toggle(FarmTwisteds, "dw_farm_event_twisteds", "Let Twisteds see you first [For Event]", "farmEventTwisteds")
    FarmTwisteds:AddParagraph({Title = "", Content = "For Research: Only Twisteds you still need Research from\nFor Event: Every Twisted on every floor (+1 Pumpkin)"})
    SeenResearch:OnChanged(function(value)
        if value and SeenEvent.Value then SeenEvent:Set(false) end
    end)
    SeenEvent:OnChanged(function(value)
        if value and SeenResearch.Value then SeenResearch:Set(false) end
    end)
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
        UI.folder(webhookFolder)
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
        UI.folder(configFolder)
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
                elseif Option.Reorder then
                    Data[id] = Option:Copy()
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

ABILITY.startIconCache()

local renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
    local Profile = FARM.Debug
    local frameStart = os.clock()
    if Profile.FrameEnd and frameStart - Profile.FrameEnd > Profile.Gap then
        FARM.debugNote(string.format("FREEZE %.0f ms between frames", (frameStart - Profile.FrameEnd) * 1000))
    end
    local Sections = Profile.Enabled and {} or nil
    local mark = frameStart
    local function section(name)
        if not Sections then return end
        local now = os.clock()
        if now - mark > Profile.Section then table.insert(Sections, string.format("%s %.0f ms", name, (now - mark) * 1000)) end
        mark = now
    end

    UI.Frame = UI.Frame + 1
    KEYS.update(tick())
    lastUiRefresh = lastUiRefresh + deltaTime
    if lastUiRefresh >= UI_REFRESH_INTERVAL then
        lastUiRefresh = 0
        refreshSettingsFromUi()
        FARM.updateUnsafeWarning()
        FARM.MASTERY.update()
        FARM.MASTERY.runUpdate()
    end
    section("ui/mastery")

    lastScan = lastScan + deltaTime
    if lastScan >= SETTINGS.scanInterval then
        lastScan = 0
        scanVisuals()
    end
    section("scanVisuals")

    if not doAutoSquirmEscape() then
        doAutoSkillCheck()
    end
    section("skillcheck/squirm")

    drawAll(deltaTime)
    section("drawAll")
    ABILITY.update()
    section("ability")
    SQUIRM.updateWarning()
    PLAYERS.update(tick())
    section("players")
    FARM.update(tick())
    section("farm")
    TOON.update(tick())
    REPORT.update(tick())
    section("toon/report")
    RENDER.update(tick())
    GOLDEN.prepare(tick())
    GOLDEN.update(tick())
    section("render/golden")

    Profile.FrameEnd = os.clock()
    if Sections and #Sections > 0 then FARM.debugNote("SLOW SECTIONS " .. table.concat(Sections, ", ")) end
end)

_G.DW_CLEANUP = function()
    if renderConnection then
        pcall(function()
            renderConnection:Disconnect()
        end)
        renderConnection = nil
    end

    KEYS.releaseAll()
    pcall(mouse2release)

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
    RENDER.cleanup()
    GOLDEN.Stopped = true
    GOLDEN.restore()
    SWIMMER.restore()

    for key, visual in pairs(tracked) do
        pcall(removeVisual, visual)
        tracked[key] = nil
    end

    clearSkillCheckCache()

    pcall(function()
        VantaUI:Unload()
    end)
end
