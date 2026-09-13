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
}

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
    "squirmTapRate",
    "alertTracers",
    "alertDandy",
    "alertDyle",
    "alertGoob",
    "alertScraps",
    "alertGigi",
    "alertSquirm",
    "alertWaxwell",
    "alertPebble",
    "alertVee",
    "alertAstro",
    "alertSprout",
    "alertShelly",
    "alertGourdy",
    "alertBobette",
    "alertBassie",
    "itemAlertTracers",
    "itemAlertTape",
    "itemAlertBandage",
    "itemAlertHealthKit",
    "itemAlertChocolateBox",
    "itemAlertJumperCable",
    "itemAlertPopBottle",
    "itemAlertSmokeBomb",
    "itemAlertJawbreaker",
    "itemAlertEjectButton",
    "itemAlertAirHorn",
}

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

local ITEM_INFO = {
    AirHorn = { name = "Air Horn", rarity = "Rare" },
    Bandage = { name = "Bandage", rarity = "Rare" },
    BonBon = { name = "BonBon", rarity = "Rare" },
    Chocolate = { name = "Chocolate", rarity = "Common" },
    ChocolateBox = { name = "Box o' Chocolates", rarity = "Very Rare" },
    ChristmasCookie = { name = "ChristmasCookie", rarity = "Rare" },
    DandyEasterEggs = { name = "DandyEasterEggs", rarity = "Rare" },
    EjectButton = { name = "Eject Button", rarity = "Ultra Rare" },
    ExtractionSpeedCandy = { name = "Extraction Speed Candy", rarity = "Uncommon" },
    Gumball = { name = "Gumballs", rarity = "Common" },
    HealthKit = { name = "Health Kit", rarity = "Very Rare" },
    Instructions = { name = "Instructions", rarity = "Uncommon" },
    Jawbreaker = { name = "Jawbreaker", rarity = "Rare" },
    JumperCable = { name = "Jumper Cable", rarity = "Rare" },
    Ornament = { name = "Ornament", rarity = "Common" },
    Pop = { name = "Pop", rarity = "Common" },
    PopBottle = { name = "Bottle o' Pop", rarity = "Very Rare" },
    ProteinBar = { name = "Protein Bar", rarity = "Uncommon" },
    SkillCheckCandy = { name = "Skill Check Candy", rarity = "Uncommon" },
    SmokeBomb = { name = "Smoke Bomb", rarity = "Ultra Rare" },
    SpeedCandy = { name = "Speed Candy", rarity = "Uncommon" },
    StaminaCandy = { name = "Stamina Candy", rarity = "Common" },
    StealthCandy = { name = "Stealth Candy", rarity = "Common" },
    Stopwatch = { name = "Stopwatch", rarity = "Common" },
    Tape = { name = "Tape", rarity = "Common" },
    Valve = { name = "Valve", rarity = "Ultra Rare" },
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

local ALERT_MONSTERS = {
    { key = "alertDandy", monster = "DandyMonster", id = "dw_alertdandy" },
    { key = "alertDyle", monster = "DyleMonster", id = "dw_alertdyle" },
    { key = "alertGoob", monster = "GoobMonster", id = "dw_alertgoob" },
    { key = "alertScraps", monster = "ScrapsMonster", id = "dw_alertscraps" },
    { key = "alertGigi", monster = "GigiMonster", id = "dw_alertgigi" },
    { key = "alertSquirm", monster = "SquirmMonster", id = "dw_alertsquirm" },
    { key = "alertWaxwell", monster = "WaxwellMonster", id = "dw_alertwaxwell" },
    { key = "alertPebble", monster = "PebbleMonster", id = "dw_alertpebble" },
    { key = "alertVee", monster = "VeeMonster", id = "dw_alertvee" },
    { key = "alertAstro", monster = "AstroMonster", id = "dw_alertastro" },
    { key = "alertSprout", monster = "SproutMonster", id = "dw_alertsprout" },
    { key = "alertShelly", monster = "ShellyMonster", id = "dw_alertshelly" },
    { key = "alertGourdy", monster = "GourdyMonster", id = "dw_alertgourdy" },
    { key = "alertBobette", monster = "BobetteMonster", id = "dw_alertbobette" },
    { key = "alertBassie", monster = "BassieMonster", id = "dw_alertbassie" },
}

local ALERT_ITEMS = {
    { key = "itemAlertTape", item = "Tape", id = "dw_itemalerttape" },
    { key = "itemAlertBandage", item = "Bandage", id = "dw_itemalertbandage" },
    { key = "itemAlertHealthKit", item = "HealthKit", id = "dw_itemalerthealthkit" },
    { key = "itemAlertChocolateBox", item = "ChocolateBox", id = "dw_itemalertchocolatebox" },
    { key = "itemAlertJumperCable", item = "JumperCable", id = "dw_itemalertjumpercable" },
    { key = "itemAlertPopBottle", item = "PopBottle", id = "dw_itemalertpopbottle" },
    { key = "itemAlertSmokeBomb", item = "SmokeBomb", id = "dw_itemalertsmokebomb" },
    { key = "itemAlertJawbreaker", item = "Jawbreaker", id = "dw_itemalertjawbreaker" },
    { key = "itemAlertEjectButton", item = "EjectButton", id = "dw_itemalertejectbutton" },
    { key = "itemAlertAirHorn", item = "AirHorn", id = "dw_itemalertairhorn" },
}

local ALERT_BY_MONSTER = {}
for _, entry in ipairs(ALERT_MONSTERS) do
    ALERT_BY_MONSTER[entry.monster] = entry.key
end

local ALERT_BY_ITEM = {}
for _, entry in ipairs(ALERT_ITEMS) do
    ALERT_BY_ITEM[entry.item] = entry.key
end

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

local SKILL_FRAME_NAMES = {
    SkillCheckFrame = true,
    SkillcheckFrame = true,
    SkillCheck = true,
    CircleSkillCheckGui = true,
    Skillcheck = true,
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
    local position = instance.AbsolutePosition
    local size = instance.AbsoluteSize
    return position ~= nil and size ~= nil and size.X > 0 and size.Y > 0
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

local function sampleCircle(marker)
    local size = marker.AbsoluteSize
    if not size then
        return false, 0
    end

    local now = tick()
    local value = size.X

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

    local markerSize = marker.AbsoluteSize
    local yellowSize = yellow and yellow.AbsoluteSize
    if not (markerSize and yellowSize) then
        return false
    end

    local yellowOuter = yellowSize.X
    local yellowInner = 0

    if parts.hole then
        local holeSize = parts.hole.AbsoluteSize
        if holeSize then
            yellowInner = holeSize.X
        end
    end

    if yellowInner <= 0 or yellowInner >= yellowOuter then
        yellowInner = math.max(0, yellowOuter - CIRCLE_FALLBACK_BAND)
    end

    local rate = math.clamp(circleRate, -CIRCLE_MAX_RATE, CIRCLE_MAX_RATE)
    local predicted = markerSize.X + rate * (SETTINGS.skillCheckLead / 1000)
    local aim = yellowOuter - circleAimFrac * (yellowOuter - yellowInner)
    local press = predicted <= aim and predicted >= yellowInner

    if not press and parts.grey and dt > 0 and rate < 0 then
        local greySize = parts.grey.AbsoluteSize

        if greySize then
            local inGrey = predicted <= greySize.X and predicted > yellowOuter
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

    local goldStart = goldPos.X
    local goldFinish = goldStart + goldSize.X
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
        local reqPos, reqSize = required.AbsolutePosition, required.AbsoluteSize

        if reqPos and reqSize then
            local pastGold

            if forward then
                pastGold = predicted > goldFinish
            else
                pastGold = predicted < goldStart
            end

            if pastGold and predicted >= reqPos.X and predicted <= reqPos.X + reqSize.X then
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

    for _, descendant in ipairs(playerGui:GetDescendants()) do
        if SKILL_FRAME_NAMES[descendant.Name] then
            parts = trySkillCheckFrame(descendant)
            if parts then
                return cacheSkillCheckParts(parts)
            end
        end
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

    if not robloxFocused() then
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
        WIDTH = 400,
        HEIGHT = 160,
        BUTTON_WIDTH = 150,
        BUTTON_HEIGHT = 38,
        BUTTON_GAP = 20,
        BUTTON_BOTTOM = 22,
        TITLE = "Would you like to cache Twisted icons?",
        SUBTITLE = "May take some time.",
        TITLE_SIZE = 20,
        SUBTITLE_SIZE = 16,
        BUTTON_SIZE = 18,
        TITLE_Y = 26,
        SUBTITLE_Y = 56,
        BUTTON_TEXT_Y = 17,
        CORNER = 6,
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

local function researchCapsuleMonster(item)
    local prompt = item:FindFirstChild("Prompt")
    local holder = prompt and prompt:FindFirstChild("Monster")
    local value = holder and holder.Value

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
    SETTINGS.squirmTapRate = uiValue("dw_squirm_tap_rate", SETTINGS.squirmTapRate)    SETTINGS.barnabyCollectCoins = uiValue("dw_barnaby_coins", SETTINGS.barnabyCollectCoins)
    SETTINGS.barnabyRiskyCoins = uiValue("dw_barnaby_risky_coins", SETTINGS.barnabyRiskyCoins)
    SETTINGS.alertTracers = uiValue("dw_alert_tracers", SETTINGS.alertTracers)

    for _, entry in ipairs(ALERT_MONSTERS) do
        SETTINGS[entry.key] = uiValue(entry.id, SETTINGS[entry.key])
    end

    SETTINGS.itemAlertTracers = uiValue("dw_item_alert_tracers", SETTINGS.itemAlertTracers)

    for _, entry in ipairs(ALERT_ITEMS) do
        SETTINGS[entry.key] = uiValue(entry.id, SETTINGS[entry.key])
    end

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

function ABILITY.promptDrawing(kind, z)
    local object = Drawing.new(kind)
    safeSet(object, "ZIndex", z)
    safeSet(object, "Transparency", 1)
    table.insert(ABILITY.prompt.drawings, object)
    return object
end

function ABILITY.promptSquare(x, y, w, h, color, filled, z)
    local square = ABILITY.promptDrawing("Square", z)
    safeSet(square, "Filled", filled)
    safeSet(square, "Thickness", 1)
    safeSet(square, "Color", color)
    safeSet(square, "Corner", ABILITY.PROMPT.CORNER)
    square.Position = Vector2.new(x, y)
    square.Size = Vector2.new(w, h)
    square.Visible = true
    return square
end

function ABILITY.promptText(text, size, color, x, y)
    local label = ABILITY.promptDrawing("Text", 63)
    safeSet(label, "Font", Drawing.Fonts.SystemBold)
    safeSet(label, "Size", size)
    safeSet(label, "FontSize", size)
    safeSet(label, "Center", true)
    safeSet(label, "Color", color)
    label.Text = text
    label.Position = Vector2.new(x, y)
    label.Visible = true
    return label
end

function ABILITY.showPrompt()
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local P = ABILITY.PROMPT
    local viewport = camera.ViewportSize
    local x = math.floor(viewport.X / 2 - P.WIDTH / 2)
    local y = math.floor(viewport.Y / 2 - P.HEIGHT / 2)
    local white = Color3.fromRGB(255, 255, 255)

    ABILITY.prompt = { drawings = {}, buttons = {}, wasDown = true }
    ABILITY.promptSquare(x, y, P.WIDTH, P.HEIGHT, Color3.fromRGB(22, 22, 26), true, 60)
    ABILITY.promptSquare(x, y, P.WIDTH, P.HEIGHT, Color3.fromRGB(62, 62, 72), false, 61)
    ABILITY.promptText(P.TITLE, P.TITLE_SIZE, white, x + P.WIDTH / 2, y + P.TITLE_Y)
    ABILITY.promptText(P.SUBTITLE, P.SUBTITLE_SIZE, Color3.fromRGB(170, 170, 180), x + P.WIDTH / 2, y + P.SUBTITLE_Y)

    local buttonY = y + P.HEIGHT - P.BUTTON_HEIGHT - P.BUTTON_BOTTOM
    local specs = {
        { label = "Yes", choice = true, x = x + P.WIDTH / 2 - P.BUTTON_WIDTH - P.BUTTON_GAP / 2, base = Color3.fromRGB(214, 92, 14), hover = Color3.fromRGB(240, 116, 36) },
        { label = "No", choice = false, x = x + P.WIDTH / 2 + P.BUTTON_GAP / 2, base = Color3.fromRGB(48, 48, 56), hover = Color3.fromRGB(70, 70, 80) },
    }

    for _, spec in ipairs(specs) do
        spec.y = buttonY
        spec.square = ABILITY.promptSquare(spec.x, buttonY, P.BUTTON_WIDTH, P.BUTTON_HEIGHT, spec.base, true, 62)
        spec.hovered = false
        ABILITY.promptText(spec.label, P.BUTTON_SIZE, white, spec.x + P.BUTTON_WIDTH / 2, buttonY + P.BUTTON_TEXT_Y)
        table.insert(ABILITY.prompt.buttons, spec)
    end
end

function ABILITY.removePrompt()
    local prompt = ABILITY.prompt
    if not prompt then
        return
    end

    for _, object in ipairs(prompt.drawings) do
        pcall(function()
            object:Remove()
        end)
    end

    ABILITY.prompt = nil
end

function ABILITY.choosePrompt(cache)
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

function ABILITY.updatePrompt()
    local prompt = ABILITY.prompt
    if not prompt.mouse and LocalPlayer then
        prompt.mouse = LocalPlayer:GetMouse()
    end

    local mouse = prompt.mouse
    if not mouse or type(ismouse1pressed) ~= "function" then
        return
    end

    local P = ABILITY.PROMPT
    local mx, my = mouse.X, mouse.Y
    local down = ismouse1pressed() and robloxFocused()
    local clicked = down and not prompt.wasDown
    prompt.wasDown = down

    for _, button in ipairs(prompt.buttons) do
        local over = mx and my and mx >= button.x and mx <= button.x + P.BUTTON_WIDTH and my >= button.y and my <= button.y + P.BUTTON_HEIGHT
        if over ~= button.hovered then
            button.hovered = over
            button.square.Color = over and button.hover or button.base
        end

        if over and clicked then
            ABILITY.choosePrompt(button.choice)
            return
        end
    end
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

    if ABILITY.prompt then
        ABILITY.updatePrompt()
    end

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

if UI then
    if UI.RemoveTab then
        pcall(function()
            UI.RemoveTab("Dandy World")
        end)
    end

    UI.AddTab("Dandy World", function(tab)
        local visuals = tab:Section("Visuals", "Left")
        visuals:Toggle("dw_visuals_enabled", "Enabled", SETTINGS.enabled)
        visuals:Keybind("dw_visuals_key", 0x50, "toggle")
        visuals:SliderInt("dw_visuals_distance", "Max Distance", 100, 3000, SETTINGS.maxDistance)
        visuals:Toggle("dw_visuals_name", "Names", SETTINGS.showName)
        visuals:Toggle("dw_visuals_range", "Distance", SETTINGS.showDistance)
        visuals:Toggle("dw_visuals_room", "Room", SETTINGS.showRoom)
        visuals:Toggle("dw_visuals_machine_type", "Machine Type", SETTINGS.showMachineType)
        visuals:Toggle("dw_visuals_twisted_rarity", "Twisted Rarity", SETTINGS.showTwistedRarity)
        visuals:Toggle("dw_visuals_ability_timer", "Twisted Ability Timer", SETTINGS.showAbilityTimer)
        visuals:Toggle("dw_visuals_squirm_warning", "Squirm Attack Warning", SETTINGS.showSquirmWarning)
        visuals:Toggle("dw_visuals_item_rarity", "Item Rarity", SETTINGS.showItemRarity)
        visuals:Toggle("dw_visuals_dot", "Dot", SETTINGS.showDot)
        visuals:Toggle("dw_visuals_tracer", "Tracer", SETTINGS.showTracer)
        visuals:SliderInt("dw_visuals_max_visible", "Max Visible", 0, 1000, SETTINGS.maxVisible)
        visuals:SliderFloat("dw_visuals_update_rate", "Update Delay", 0.005, 0.2, SETTINGS.updateInterval, "%.3f")
        visuals:SliderFloat("dw_visuals_scan_rate", "Scan Delay", 0.5, 5.0, SETTINGS.scanInterval, "%.1f")

        local alerts = tab:Section("Alert System", "Left")
        alerts:Toggle("dw_alert_tracers", "Use additional tracers", SETTINGS.alertTracers)

        for _, entry in ipairs(ALERT_MONSTERS) do
            local info = MONSTER_INFO[entry.monster]
            local label = (info and info.name) or entry.monster
            alerts:Toggle(entry.id, label, SETTINGS[entry.key])
        end

        local filters = tab:Section("Filters", "Right")
        filters:Toggle("dw_visuals_monsters", "Monsters", SETTINGS.showMonsters)
        filters:ColorPicker("dw_visuals_monsters_color", COLORS.Monsters.R, COLORS.Monsters.G, COLORS.Monsters.B, 1, function(color)
            COLORS.Monsters = color
        end)
        filters:Toggle("dw_visuals_items", "Items", SETTINGS.showItems)
        filters:ColorPicker("dw_visuals_items_color", COLORS.Items.R, COLORS.Items.G, COLORS.Items.B, 1, function(color)
            COLORS.Items = color
        end)
        filters:Toggle("dw_visuals_research", "Research Capsules", SETTINGS.showResearchCapsules)
        filters:ColorPicker("dw_visuals_research_color", COLORS.ResearchCapsules.R, COLORS.ResearchCapsules.G, COLORS.ResearchCapsules.B, 1, function(color)
            COLORS.ResearchCapsules = color
        end)
        filters:Toggle("dw_visuals_tapes", "Tapes", SETTINGS.showTapes)
        filters:ColorPicker("dw_visuals_tapes_color", COLORS.Tapes.R, COLORS.Tapes.G, COLORS.Tapes.B, 1, function(color)
            COLORS.Tapes = color
        end)
        filters:Toggle("dw_visuals_generators", "Ichor Extractors", SETTINGS.showGenerators)
        filters:Toggle("dw_visuals_show_done_generators", "Show Done Extractors", SETTINGS.showCompletedGenerators)
        filters:Toggle("dw_visuals_inuse_generators", "Highlight In-Use Extractors", SETTINGS.showInUseGenerators)
        filters:ColorPicker("dw_visuals_generators_color", COLORS.Generators.R, COLORS.Generators.G, COLORS.Generators.B, 1, function(color)
            COLORS.Generators = color
        end)
        filters:ColorPicker("dw_visuals_completed_generator_color", COLORS.CompletedGenerator.R, COLORS.CompletedGenerator.G, COLORS.CompletedGenerator.B, 1, function(color)
            COLORS.CompletedGenerator = color
        end)
        filters:ColorPicker("dw_visuals_inuse_generator_color", COLORS.InUseGenerator.R, COLORS.InUseGenerator.G, COLORS.InUseGenerator.B, 1, function(color)
            COLORS.InUseGenerator = color
        end)

        local automation = tab:Section("Automation", "Right")
        automation:Toggle("dw_skillcheck_enabled", "Auto Skill Check", SETTINGS.autoSkillCheck)
        automation:Toggle("dw_skillcheck_random", "Randomize Press", SETTINGS.skillCheckRandom)
        automation:SliderInt("dw_skillcheck_aim", "Aim Point (%)", 0, 100, SETTINGS.skillCheckAim)
        automation:SliderInt("dw_skillcheck_lead", "Press Lead (ms)", 0, 120, SETTINGS.skillCheckLead)
        automation:SliderInt("dw_skillcheck_treadmill_rate", "Treadmill Tap Rate", 1, 30, SETTINGS.treadmillTapRate)
        automation:Toggle("dw_barnaby_enabled", "Auto Barnaby", SETTINGS.autoBarnaby)
        automation:Toggle("dw_barnaby_coins", "Collect Barnaby Coins", SETTINGS.barnabyCollectCoins)
        automation:Toggle("dw_barnaby_risky_coins", "Risk for more coins (Not recommended)", SETTINGS.barnabyRiskyCoins)
        automation:Toggle("dw_squirm_escape", "Auto Squirm Escape", SETTINGS.autoSquirmEscape)
        automation:SliderInt("dw_squirm_tap_rate", "Squirm Tap Rate", 1, 16, SETTINGS.squirmTapRate)        local itemAlerts = tab:Section("Item Alerts", "Right")
        itemAlerts:Toggle("dw_item_alert_tracers", "Use additional tracers", SETTINGS.itemAlertTracers)
        itemAlerts:ColorPicker("dw_item_alert_color", COLORS.ItemAlert.R, COLORS.ItemAlert.G, COLORS.ItemAlert.B, 1, function(color)
            COLORS.ItemAlert = color
        end)

        for _, entry in ipairs(ALERT_ITEMS) do
            local info = ITEM_INFO[entry.item]
            local label = (info and info.name) or entry.item
            itemAlerts:Toggle(entry.id, label, SETTINGS[entry.key])
        end
    end)
end

local UI_REFRESH_INTERVAL = 0.1
local lastUiRefresh = 0

ABILITY.startIconCache()

local renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
    lastUiRefresh = lastUiRefresh + deltaTime
    if lastUiRefresh >= UI_REFRESH_INTERVAL then
        lastUiRefresh = 0
        refreshSettingsFromUi()
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

    if UI and UI.RemoveTab then
        pcall(function()
            UI.RemoveTab("Dandy World")
        end)
    end
end