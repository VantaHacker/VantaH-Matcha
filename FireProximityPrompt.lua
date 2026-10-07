local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer

local Fire = _G.FireProximityPrompt or {}
_G.FireProximityPrompt = Fire

Fire.Offsets = {Tag = 0, ValueTag = 12, StringTag = 6, FunctionTag = 8, StringLength = 20, StringText = 24, Proto = 0x18, Code = 0x28, CodeSize = 0xA8, Constants = 0x20, ConstantCount = 0xAC, PromptDistance = 0x118, PromptHold = 0x110, CameraRotation = 0xC8}
Fire.Code = {Index = 22, Move = 23, Shape = {[21] = {A = 5}, [22] = {A = 6, B = 1, C = 0}, [23] = {A = 8, B = 5}, [24] = {A = 9, D = 4}, [25] = {A = 6, B = 6}}, Aux = {[26] = 5}}
Fire.Window = {Hide = 0.04, Show = 0.6}
Fire.State = Fire.State or {}
Fire.Version = 5

local function heap(pointer)
    return pointer ~= nil and pointer > 0x10000 and pointer < 0x7FF000000000
end

local function text(pointer, length)
    local O = Fire.Offsets
    if not heap(pointer) then return nil end
    if memory_read("byte", pointer + O.Tag) ~= O.StringTag then return nil end
    local size = memory_read("int", pointer + O.StringLength)
    if not size or size < 1 or size > 64 or (length and size ~= length) then return nil end
    return memory_read("string", pointer + O.StringText)
end

local function constants(proto)
    local O = Fire.Offsets
    local base = memory_read("uintptr_t", proto + O.Constants)
    local count = memory_read("int", proto + O.ConstantCount)
    if not heap(base) or not count or count < 1 or count > 255 then return nil, 0 end
    local List = {}
    for i = 0, count - 1 do
        local slot = base + i * 16
        local pointer = memory_read("int", slot + O.ValueTag) == O.StringTag and memory_read("uintptr_t", slot) or nil
        List[i] = {Slot = slot, Pointer = pointer}
    end
    return List, count
end

local function protos(key)
    local O = Fire.Offsets
    local Found = {}
    for _, Entry in ipairs(getgc(key) or {}) do
        local closure = Entry.addr and memory_read("uintptr_t", Entry.addr)
        if heap(closure) and memory_read("byte", closure + O.Tag) == O.FunctionTag then
            local proto = memory_read("uintptr_t", closure + O.Proto)
            if heap(proto) then table.insert(Found, proto) end
        end
    end
    return Found
end

local function near(center, range, test)
    local O = Fire.Offsets
    local steps = 0
    for proto = center - range, center + range, 8 do
        steps = steps + 1
        if Fire.Yield and steps % 2048 == 0 then task.wait(1 / 60) end
        local base = memory_read("uintptr_t", proto + O.Constants)
        if heap(base) then
            local count = memory_read("int", proto + O.ConstantCount)
            if count and count > 0 and count < 256 and test(proto, count) then return proto end
        end
    end
end

local function codeWord(proto, index)
    return memory_read("int", memory_read("uintptr_t", proto + Fire.Offsets.Code) + index * 4)
end

local function part(word, index)
    return math.floor(word % 4294967296 / 256 ^ index) % 256
end

local function matches(word, Shape)
    if Shape.A and part(word, 1) ~= Shape.A then return false end
    if Shape.B and part(word, 2) ~= Shape.B then return false end
    if Shape.C and part(word, 3) ~= Shape.C then return false end
    if Shape.D and math.floor(word % 4294967296 / 65536) ~= Shape.D then return false end
    return true
end

local function findHandler()
    for _, gourdy in ipairs(protos("GourdyMonster")) do
        local handler = near(gourdy, 0x4000, function(proto, count)
            if count ~= 9 then return false end
            local List = constants(proto)
            return List and text(List[1].Pointer) == "HolidayFreeItemPrompt" and text(List[3].Pointer) == "HumanoidRootPart" and text(List[5].Pointer) == "HasTag"
        end)
        if handler then return handler end
    end
end

local function shares(proto, Game)
    local List, count = constants(proto)
    if not List then return false end
    for i = 0, count - 1 do
        if List[i].Pointer and Game[List[i].Pointer] then return true end
    end
    return false
end

local function findString(word, centers, Game)
    local found
    for _, center in ipairs(centers) do
        near(center, 0x40000, function(proto, count)
            local List = constants(proto)
            if not List then return false end
            for i = 0, count - 1 do
                local pointer = List[i].Pointer
                if pointer and text(pointer, #word) == word and shares(proto, Game) then
                    found = pointer
                    return true
                end
            end
            return false
        end)
        if found then return found end
    end
end

local function expand(center, Game)
    near(center, 0x4000, function(proto, count)
        if not shares(proto, Game) then return false end
        local List = constants(proto)
        for i = 0, count - 1 do
            if List[i].Pointer then Game[List[i].Pointer] = true end
        end
        return false
    end)
end

local function keyString(word, Game)
    local Scores = {}
    for _, Entry in ipairs(getgc(word) or {}) do
        local node = Entry.addr
        local pointer = heap(node) and memory_read("uintptr_t", node + 16)
        if pointer and text(pointer, #word) == word then
            if Game[pointer] then return pointer end
            local Score = Scores[pointer] or {Game = 0, All = 0}
            Scores[pointer] = Score
            for i = -40, 40 do
                local sibling = i ~= 0 and memory_read("uintptr_t", node + i * 32 + 16)
                if sibling and text(sibling) then
                    Score.All = Score.All + 1
                    if Game[sibling] then Score.Game = Score.Game + 1 end
                end
            end
        end
    end
    local best, bestRatio
    for pointer, Score in pairs(Scores) do
        local ratio = Score.All > 0 and Score.Game / Score.All or 0
        if Score.Game >= 2 and ratio >= 0.1 and (not bestRatio or ratio > bestRatio) then best, bestRatio = pointer, ratio end
    end
    return best
end

function Fire.setup()
    local S = Fire.State
    if S.Ready and S.JobId == game.JobId and S.Version == Fire.Version then return true end
    S.Ready = false
    local handler = findHandler()
    if not handler then return false, "PromptShown handler not found" end
    for index, value in pairs(Fire.Code.Aux) do
        if codeWord(handler, index) % 4294967296 % 65536 ~= value then return false, "handler bytecode changed" end
    end
    local moveOp = part(codeWord(handler, Fire.Code.Move), 0)
    local patched = 0x600 + moveOp
    local word = codeWord(handler, Fire.Code.Index)
    local original = word
    if word == patched then
        original = S.Handler == handler and S.Original or nil
        if not original then return false, "handler was left patched, rejoin" end
    end
    for index, Shape in pairs(Fire.Code.Shape) do
        local value = index == Fire.Code.Index and original or codeWord(handler, index)
        if not matches(value, Shape) then return false, "handler bytecode changed" end
    end
    if part(original, 0) == moveOp then return false, "handler bytecode changed" end
    local List = constants(handler)
    if not (List and List[1].Pointer) then return false, "handler constants unreadable" end
    local Game = {}
    for i = 0, 8 do
        if List[i].Pointer then Game[List[i].Pointer] = true end
    end
    expand(handler, Game)
    local ginger = protos("isChanneling")
    local hold = findString("InputHoldBegin", ginger, Game)
    if not hold then
        for _, proto in ipairs(ginger) do
            near(proto, 0x100000, function(candidate, count)
                local Candidates = constants(candidate)
                for i = 0, count - 1 do
                    if Candidates[i].Pointer and text(Candidates[i].Pointer, 14) == "InputHoldBegin" then hold = Candidates[i].Pointer return true end
                end
                return false
            end)
            if hold then break end
        end
    end
    if not hold then return false, "InputHoldBegin string not found" end
    S.Handler = handler
    S.Original = original
    S.Patched = patched
    S.CodeAddress = memory_read("uintptr_t", handler + Fire.Offsets.Code) + Fire.Code.Index * 4
    S.NameSlot = List[0].Slot
    S.NameOriginal = List[0].Pointer
    S.RootSlot = List[3].Slot
    S.RootOriginal = List[3].Pointer
    S.TagSlot = List[5].Slot
    S.TagOriginal = List[5].Pointer
    S.Hold = hold
    S.Game = Game
    S.Centers = {handler, ginger[1]}
    S.Names = {}
    S.JobId = game.JobId
    S.Version = Fire.Version
    S.Ready = true
    return true
end

function Fire.name(word)
    local S = Fire.State
    if S.Names[word] == nil then
        S.Names[word] = findString(word, S.Centers, S.Game) or keyString(word, S.Game) or false
    end
    return S.Names[word] or nil
end

function Fire.find(Model)
    for _, Child in ipairs(Model:GetDescendants()) do
        if Child.Name == "ProximityPrompt" or Child.ClassName == "ProximityPrompt" then return Child end
    end
end

local function promptPosition(Prompt)
    local Holder = Prompt.Parent
    if Holder and Holder.ClassName ~= "Attachment" and Holder.Position then return Holder.Position end
    local Part = Holder and Holder.Parent
    return Part and Part.Position
end

local function cameraRotation(Camera)
    local address = Camera.Address
    if not address then return nil end
    local base = address + Fire.Offsets.CameraRotation
    local components = {Camera.CFrame:GetComponents()}
    for i = 4, 12 do
        if math.abs(memory_read("float", base + (i - 4) * 4) - components[i]) > 0.01 then return nil end
    end
    return base
end

local function aim(Camera, rotation, target)
    local position = Camera.CFrame.Position
    if (target - position).Magnitude < 0.1 then return end
    local components = {CFrame.lookAt(position, target):GetComponents()}
    for i = 4, 12 do memory_write("float", rotation + (i - 4) * 4, components[i]) end
end

local function restore(S, Saved)
    if memory_read("int", S.CodeAddress) == S.Patched then memory_write("int", S.CodeAddress, S.Original) end
    if memory_read("uintptr_t", S.NameSlot) ~= S.NameOriginal then memory_write("uintptr_t", S.NameSlot, S.NameOriginal) end
    if memory_read("uintptr_t", S.RootSlot) ~= S.RootOriginal then memory_write("uintptr_t", S.RootSlot, S.RootOriginal) end
    if memory_read("uintptr_t", S.TagSlot) ~= S.TagOriginal then memory_write("uintptr_t", S.TagSlot, S.TagOriginal) end
    if Saved.Prompt.Parent == nil then return end
    if Saved.Distance then memory_write("float", Saved.Address + Fire.Offsets.PromptDistance, Saved.Distance) end
    if Saved.Hold and Saved.Hold > 0 then memory_write("float", Saved.Address + Fire.Offsets.PromptHold, Saved.Hold) end
end

function Fire.fire(Prompt, Options)
    Options = Options or {}
    local S = Fire.State
    if Fire.Busy and tick() - (Fire.BusyAt or 0) > Fire.Window.Hide + Fire.Window.Show + 3 then
        if Fire.Pending then pcall(restore, S, Fire.Pending) end
        Fire.Busy, Fire.Pending = false, nil
        Fire.Last = {At = tick(), Success = false, Camera = false, Problem = "fire thread never finished, reset by watchdog"}
    end
    if Fire.Busy then return false, "busy" end
    local ok, reason = Fire.setup()
    if not ok then return false, reason end
    local address = Prompt and Prompt.Address
    if not heap(address) then return false, "no prompt address" end
    local distance = memory_read("float", address + Fire.Offsets.PromptDistance)
    if not distance or distance <= 0 or distance > 1000 then return false, "prompt distance unreadable or muted" end
    local Holder = Prompt.Parent
    local holderName = Holder and Holder.Name
    local holderPointer = holderName and Fire.name(holderName)
    local namePointer
    if not holderPointer then
        local className = Holder and Holder.ClassName
        namePointer = className and Fire.name("ClassName")
        holderPointer = namePointer and Fire.name(className)
        if not holderPointer then return false, "no game string for parent " .. tostring(holderName) .. " / " .. tostring(className) end
    end
    local target = promptPosition(Prompt)
    local char = plr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (target and root) then return false, "no character or prompt position" end
    local away = (target - root.Position).Magnitude
    local reach = math.min(distance * 2 - 1, math.max(distance, away + 1))
    if away > reach then return false, string.format("too far (%.1f > %.1f)", away, reach) end
    if memory_read("uintptr_t", S.NameSlot) ~= S.NameOriginal or memory_read("uintptr_t", S.RootSlot) ~= S.RootOriginal or memory_read("uintptr_t", S.TagSlot) ~= S.TagOriginal or memory_read("int", S.CodeAddress) ~= S.Original then
        S.Ready = false
        return false, "handler state changed, run again"
    end
    Fire.Busy, Fire.BusyAt = true, tick()
    task.spawn(function()
        local Saved = {Prompt = Prompt, Address = address, Distance = distance}
        Fire.Pending = Saved
        local Camera, rotation
        local success, problem = pcall(function()
            local hold = memory_read("float", address + Fire.Offsets.PromptHold)
            Saved.Hold = hold and hold > 0 and hold < 60 and hold or nil
            Camera = workspace.CurrentCamera
            local okRotation, found = pcall(cameraRotation, Camera)
            rotation = Options.Camera ~= false and Camera and okRotation and found or nil
            if rotation then aim(Camera, rotation, target) end
            if Saved.Hold then memory_write("float", address + Fire.Offsets.PromptHold, 0) end
            if namePointer then memory_write("uintptr_t", S.NameSlot, namePointer) end
            memory_write("uintptr_t", S.RootSlot, holderPointer)
            memory_write("uintptr_t", S.TagSlot, S.Hold)
            memory_write("int", S.CodeAddress, S.Patched)
            memory_write("float", address + Fire.Offsets.PromptDistance, 0)
            local stop, frames = tick() + Fire.Window.Hide, 0
            while tick() < stop or frames < 2 do
                if rotation then aim(Camera, rotation, target) end
                frames = frames + 1
                task.wait(1 / 60)
            end
            memory_write("float", address + Fire.Offsets.PromptDistance, reach)
            stop = tick() + Fire.Window.Show
            while tick() < stop and Prompt.Parent ~= nil do
                if rotation then aim(Camera, rotation, target) end
                task.wait(1 / 60)
            end
        end)
        pcall(restore, S, Saved)
        Fire.Busy, Fire.Pending = false, nil
        Fire.Last = {At = tick(), Success = success, Camera = rotation ~= nil, Problem = not success and tostring(problem) or nil}
        if Options.Callback then pcall(Options.Callback, success) end
    end)
    return true
end

_G.fireproximityprompt = function(Prompt, Options)
    return Fire.fire(Prompt, Options)
end
