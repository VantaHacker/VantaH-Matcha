local ps = game:GetService("Players")
local runs = game:GetService("RunService")

if _G.VantaUI and _G.VantaUI.Unload then pcall(function() _G.VantaUI:Unload() end) end

local plr = ps.LocalPlayer
local Mouse = plr:GetMouse()

local Library = {
	Version = "0.2",
	Build = "Sep 19 2026",
	Options = {},
	Drawings = {},
	Connections = {},
	Windows = {},
	Keybinds = {},
	Unloaded = false,
	WasDown = false,
	Popup = nil,
	Typing = nil,
	Binding = nil,
	Dragging = nil,
	Font = 2,
	TextSize = 13,
	PulseSpeed = 2.2,
	PulseStart = 0,
	Blocked = nil,
	BlockMode = "Typing",
	Theme = {
		Background = Color3.fromRGB(12, 12, 15),
		Topbar = Color3.fromRGB(10, 10, 13),
		Sidebar = Color3.fromRGB(12, 12, 15),
		Section = Color3.fromRGB(18, 18, 22),
		Element = Color3.fromRGB(29, 29, 35),
		ElementHover = Color3.fromRGB(38, 38, 46),
		Border = Color3.fromRGB(29, 29, 35),
		Line = Color3.fromRGB(28, 28, 34),
		Accent = Color3.fromRGB(222, 96, 18),
		AccentHover = Color3.fromRGB(245, 125, 45),
		AccentDark = Color3.fromRGB(96, 42, 10),
		Text = Color3.fromRGB(214, 214, 220),
		SubText = Color3.fromRGB(128, 128, 140),
		Header = Color3.fromRGB(170, 170, 178),
		CheckOff = Color3.fromRGB(29, 29, 35),
		PulseBright = Color3.fromRGB(46, 46, 56),
		PulseDark = Color3.fromRGB(30, 30, 37),
		PulseText = Color3.fromRGB(150, 150, 162),
		CloseBright = Color3.fromRGB(190, 55, 40),
		CloseDark = Color3.fromRGB(110, 30, 22),
	},
}

local Theme = Library.Theme

local keyNames = {
	[0x08] = "Backspace", [0x09] = "Tab", [0x0D] = "Enter", [0x13] = "Pause", [0x14] = "Caps Lock", [0x1B] = "Escape", [0x20] = "Space",
	[0x21] = "Page Up", [0x22] = "Page Down", [0x23] = "End", [0x24] = "Home", [0x25] = "Left Arrow", [0x26] = "Up Arrow", [0x27] = "Right Arrow", [0x28] = "Down Arrow",
	[0x2D] = "Insert", [0x2E] = "Delete", [0xA0] = "Left Shift", [0xA1] = "Right Shift", [0xA2] = "Left Ctrl", [0xA3] = "Right Ctrl", [0xA4] = "Left Alt", [0xA5] = "Right Alt",
	[0xBA] = ";", [0xBB] = "=", [0xBC] = ",", [0xBD] = "-", [0xBE] = ".", [0xBF] = "/", [0xC0] = "`", [0xDB] = "[", [0xDC] = "\\", [0xDD] = "]", [0xDE] = "'",
	[0x6A] = "Numpad *", [0x6B] = "Numpad +", [0x6D] = "Numpad -", [0x6E] = "Numpad .", [0x6F] = "Numpad /",
}
for code = 0x30, 0x39 do keyNames[code] = string.char(code) end
for code = 0x41, 0x5A do keyNames[code] = string.char(code) end
for code = 0x60, 0x69 do keyNames[code] = "Numpad " .. (code - 0x60) end
for code = 0x70, 0x7B do keyNames[code] = "F" .. (code - 0x6F) end

local shiftDigits = {[0x30] = ")", [0x31] = "!", [0x32] = "@", [0x33] = "#", [0x34] = "$", [0x35] = "%", [0x36] = "^", [0x37] = "&", [0x38] = "*", [0x39] = "("}
local punctuation = {
	[0xBA] = {";", ":"}, [0xBB] = {"=", "+"}, [0xBC] = {",", "<"}, [0xBD] = {"-", "_"}, [0xBE] = {".", ">"}, [0xBF] = {"/", "?"},
	[0xC0] = {"`", "~"}, [0xDB] = {"[", "{"}, [0xDC] = {"\\", "|"}, [0xDD] = {"]", "}"}, [0xDE] = {"'", "\""},
}

local scanCodes = {}
for code, _ in pairs(keyNames) do scanCodes[#scanCodes + 1] = code end
table.sort(scanCodes)

function Library.KeyName(code)
	if not code then return "None" end
	return keyNames[code] or ("0x%02X"):format(code)
end

local function focused()
	local active = true
	pcall(function() active = isrbxactive() end)
	return active ~= false
end

local function keyDown(code)
	local down = false
	pcall(function() down = iskeypressed(code) end)
	return down == true
end

local function draw(kind, props)
	if props.ZIndex and Library.Layer then props.ZIndex += Library.Layer end
	local Object = Drawing.new(kind)
	for key, value in pairs(props) do
		pcall(function() Object[key] = value end)
	end
	Library.Drawings[#Library.Drawings + 1] = Object
	return Object
end

local function box(z, color, corner)
	return draw("Square", {Filled = true, Color = color, Corner = corner or 0, ZIndex = z, Visible = false, Transparency = 1, Thickness = 1})
end

local function outline(z, color, corner)
	return draw("Square", {Filled = false, Color = color, Corner = corner or 0, ZIndex = z, Visible = false, Transparency = 1, Thickness = 1})
end

local function label(z, text, color, size)
	return draw("Text", {Text = text or "", Color = color or Theme.Text, Size = size or Library.TextSize, Font = Library.Font, Outline = false, Center = false, ZIndex = z, Visible = false, Transparency = 1})
end

local glyphUnits = {
	[32] = 3, [33] = 4, [34] = 6, [35] = 8, [36] = 8, [37] = 10, [38] = 9, [39] = 3, [40] = 4, [41] = 4, [42] = 6, [43] = 8, [44] = 4, [45] = 6, [46] = 4, [47] = 4,
	[48] = 8, [49] = 8, [50] = 8, [51] = 8, [52] = 8, [53] = 8, [54] = 8, [55] = 8, [56] = 8, [57] = 8, [58] = 4, [59] = 4, [60] = 8, [61] = 8, [62] = 8, [63] = 7,
	[64] = 11, [65] = 9, [66] = 8, [67] = 9, [68] = 9, [69] = 7, [70] = 7, [71] = 9, [72] = 9, [73] = 3, [74] = 7, [75] = 8, [76] = 7, [77] = 11, [78] = 9, [79] = 10,
	[80] = 8, [81] = 10, [82] = 8, [83] = 8, [84] = 8, [85] = 9, [86] = 9, [87] = 12, [88] = 9, [89] = 8, [90] = 8, [91] = 5, [92] = 4, [93] = 5, [94] = 6, [95] = 5,
	[96] = 6, [97] = 7, [98] = 8, [99] = 7, [100] = 8, [101] = 7, [102] = 5, [103] = 8, [104] = 8, [105] = 3, [106] = 3, [107] = 7, [108] = 3, [109] = 11, [110] = 8, [111] = 7,
	[112] = 8, [113] = 8, [114] = 5, [115] = 7, [116] = 5, [117] = 8, [118] = 7, [119] = 10, [120] = 7, [121] = 7, [122] = 7, [123] = 5, [124] = 4, [125] = 5, [126] = 7,
}

function Library.TextWidth(text, size)
	size = size or Library.TextSize
	text = tostring(text)
	local total = 0
	for index = 1, #text do
		total += glyphUnits[text:byte(index)] or 7
	end
	return math.floor(total * size / 15 + 0.5)
end

local function fit(text, size, maxWidth)
	text = tostring(text)
	if Library.TextWidth(text, size) <= maxWidth then return text end
	while #text > 0 and Library.TextWidth(text .. "..", size) > maxWidth do text = text:sub(1, -2) end
	return text .. ".."
end

local function wrap(text, size, maxWidth)
	local Lines = {}
	for paragraph in (tostring(text) .. "\n"):gmatch("(.-)\n") do
		local current = ""
		for word in paragraph:gmatch("%S+") do
			local candidate = current == "" and word or (current .. " " .. word)
			if Library.TextWidth(candidate, size) > maxWidth and current ~= "" then
				Lines[#Lines + 1] = current
				current = word
			else
				current = candidate
			end
		end
		Lines[#Lines + 1] = current
	end
	while #Lines > 0 and Lines[#Lines] == "" do table.remove(Lines) end
	return Lines
end

local function toHSV(color)
	local r, g, b = color.R, color.G, color.B
	local maximum, minimum = math.max(r, g, b), math.min(r, g, b)
	local delta = maximum - minimum
	local hue = 0
	if delta > 0 then
		if maximum == r then
			hue = ((g - b) / delta) % 6
		elseif maximum == g then
			hue = (b - r) / delta + 2
		else
			hue = (r - g) / delta + 4
		end
		hue /= 6
	end
	local saturation = maximum == 0 and 0 or delta / maximum
	return hue, saturation, maximum
end

local function mix(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function wave()
	return (1 - math.cos((tick() - Library.PulseStart) * Library.PulseSpeed)) / 2
end

local function pulse(bright, dark)
	return mix(bright, dark, wave())
end

local glowTime = 1.4

local function glowColor(start, normal)
	if not start then return nil end
	local t = (tick() - start) / glowTime
	if t >= 1 or t < 0 then return nil end
	if t < 0.12 then return Theme.Element end
	local u = (t - 0.12) / 0.88
	local strength = math.sin(math.pi * u)
	if u < 0.5 then return mix(Theme.Element, Theme.Accent, strength) end
	return mix(normal, Theme.Accent, strength)
end

local function isElement(value)
	return type(value) == "table" and value.Kind ~= nil
end

local function inside(x, y, px, py, width, height)
	return x >= px and x <= px + width and y >= py and y <= py + height
end

local function setVisible(List, visible)
	for _, Object in ipairs(List) do Object.Visible = visible end
end

local function fire(Element, value)
	for _, callback in ipairs(Element.Changed) do
		local ok, err = pcall(callback, value)
		if not ok then warn("[VantaUI] " .. tostring(Element.Id or Element.Title) .. ": " .. tostring(err)) end
	end
end

local function newElement(Section, config, kind, height)
	local Element = {
		Kind = kind,
		Section = Section,
		Id = config.Id,
		Title = config.Title or kind,
		Height = height,
		Draws = {},
		Changed = {},
		X = 0, Y = 0, Width = 0,
		Shown = false,
		Hovered = false,
		Layer = Library.Layer or 0,
		TextColor = config.TextColor,
	}
	if config.Callback then Element.Changed[#Element.Changed + 1] = config.Callback end
	function Element:OnChanged(callback)
		self.Changed[#self.Changed + 1] = callback
		pcall(callback, self.Value)
	end
	function Element:Get()
		return self.Value
	end
	function Element:SetHidden(value)
		if self.Hidden == (value == true) then return end
		self.Hidden = value == true
		Library.Dirty = true
	end
	if config.Id then Library.Options[config.Id] = Element end
	Section.Elements[#Section.Elements + 1] = Element
	Library.Dirty = true
	return Element
end

local function track(Element, Object)
	Element.Draws[#Element.Draws + 1] = Object
	return Object
end

local Section = {}
Section.__index = Section

function Section:AddToggle(config)
	local Element = newElement(self, config, "Toggle", 28)
	Element.Value = config.Default == true
	local Box = track(Element, box(4, Theme.CheckOff, 4))
	local Border = track(Element, outline(5, Theme.Border, 4))
	local Title = track(Element, label(4, Element.Title, Element.TextColor or Theme.Text))

	function Element:Paint()
		Box.Color = self.Value and (self.Hovered and Theme.AccentHover or Theme.Accent) or Theme.CheckOff
		Border.Color = (self.Value or self.Hovered) and Theme.Accent or Theme.Border
		Title.Color = self.TextColor or (self.Value and Theme.Text or Theme.SubText)
	end
	function Element:Pulse()
		Title.Color = self.TextColor and pulse(mix(self.TextColor, Color3.new(1, 1, 1), 0.4), self.TextColor) or pulse(Theme.Text, Theme.PulseText)
	end
	function Element:Place(x, y, width)
		Box.Position = Vector2.new(x + 12, y + 5)
		Box.Size = Vector2.new(18, 18)
		Border.Position = Box.Position
		Border.Size = Box.Size
		Title.Position = Vector2.new(x + 40, y + 7)
		Title.Text = fit(self.Title, Library.TextSize, width - 50)
		self:Paint()
	end
	function Element:Click()
		self:Set(not self.Value)
	end
	function Element:Set(value)
		value = value == true
		if value == self.Value then return end
		self.Value = value
		self:Paint()
		fire(self, value)
	end
	return Element
end

function Section:AddSlider(config)
	local Element = newElement(self, config, "Slider", 40)
	Element.Min = config.Min or 0
	Element.Max = config.Max or 100
	Element.Decimals = config.Decimals or 0
	Element.Suffix = config.Suffix or ""
	Element.Value = math.clamp(config.Default or Element.Min, Element.Min, Element.Max)
	Element.Numeric = true
	Element.EditWidth = config.EditWidth or 84
	local Title = track(Element, label(4, Element.Title, Element.TextColor or Theme.Text))
	local ValueBack = track(Element, box(4, Theme.CheckOff, 4))
	local ValueBorder = track(Element, outline(5, Theme.Accent, 4))
	local Value = track(Element, label(6, "", Theme.SubText))
	local Track = track(Element, box(4, Theme.Element, 2))
	local Fill = track(Element, box(5, Theme.Accent, 2))

	local function format(value)
		local text = Element.Decimals > 0 and (("%." .. Element.Decimals .. "f"):format(value)) or tostring(math.floor(value + 0.5))
		return text .. Element.Suffix
	end
	function Element:Paint()
		local ratio = (self.Value - self.Min) / math.max(self.Max - self.Min, 1e-9)
		local trackWidth = self.Width - 24
		Fill.Size = Vector2.new(math.max(trackWidth * ratio, 3), 4)
		Fill.Color = self.Hovered and Theme.AccentHover or Theme.Accent
		local typing = Library.Typing == self
		local boxX = self.X + self.Width - 12 - self.EditWidth
		ValueBack.Position = Vector2.new(boxX, self.Y + 3)
		ValueBack.Size = Vector2.new(self.EditWidth, 20)
		ValueBorder.Position = ValueBack.Position
		ValueBorder.Size = ValueBack.Size
		ValueBack.Visible = self.Shown and typing
		ValueBorder.Visible = self.Shown and typing
		if typing then
			Value.Color = Theme.Text
			Library:RenderEdit(Value, boxX + 7, self.Y + 6, self.EditWidth - 14, 5 + self.Layer)
		else
			local text = format(self.Value)
			Value.Text = text
			Value.Color = self.ValueHovered and Theme.Accent or Theme.SubText
			Value.Position = Vector2.new(self.X + self.Width - 12 - Library.TextWidth(text), self.Y + 6)
		end
		Track.Color = Theme.Element
	end
	function Element:EditText(value)
		value = value or self.Value
		return self.Decimals > 0 and (("%." .. self.Decimals .. "f"):format(value)) or tostring(math.floor(value + 0.5))
	end
	Element.MaxLength = math.max(#Element:EditText(Element.Max), #Element:EditText(Element.Min)) + 1
	function Element:Commit(text)
		if text then
			local number = tonumber(text)
			if number then
				local step = 10 ^ self.Decimals
				self:Set(math.floor(math.clamp(number, self.Min, self.Max) * step + 0.5) / step)
			end
		end
		self:Paint()
	end
	function Element:OverValue(mx, my)
		local width = math.max(Library.TextWidth(format(self.Value)) + 14, 44)
		return inside(mx, my, self.X + self.Width - 12 - width, self.Y + 2, width, 22)
	end
	function Element:Tick()
		if Library.Typing == self then self:Paint() end
		local mouseOver = self.Hovered and self:OverValue(Mouse.X, Mouse.Y)
		if mouseOver ~= self.ValueHovered then
			self.ValueHovered = mouseOver
			self:Paint()
		end
	end
	function Element:Pulse()
		Track.Color = pulse(Theme.PulseBright, Theme.PulseDark)
	end
	function Element:Place(x, y, width)
		Title.Position = Vector2.new(x + 12, y + 6)
		Title.Text = fit(self.Title, Library.TextSize, width - 80)
		Track.Position = Vector2.new(x + 12, y + 27)
		Track.Size = Vector2.new(width - 24, 4)
		Fill.Position = Vector2.new(x + 12, y + 27)
		self:Paint()
	end
	function Element:Drag(mx)
		local ratio = math.clamp((mx - self.X - 12) / math.max(self.Width - 24, 1), 0, 1)
		local raw = self.Min + (self.Max - self.Min) * ratio
		local step = 10 ^ self.Decimals
		self:Set(math.floor(raw * step + 0.5) / step)
	end
	function Element:Click(mx, my)
		if Library.Typing == self then
			if my and inside(mx, my, self.X + self.Width - 12 - self.EditWidth, self.Y + 2, self.EditWidth, 22) then
				Library:EditClick(mx)
				return
			end
			Library:StopTyping(false)
		end
		if my and self:OverValue(mx, my) then
			Library:StartTyping(self)
			Library:EditClick(mx)
			return
		end
		Library.Dragging = self
		self:Drag(mx)
	end
	function Element:Set(value)
		value = math.clamp(value, self.Min, self.Max)
		if value == self.Value then return end
		self.Value = value
		self:Paint()
		fire(self, value)
	end
	return Element
end

function Section:AddButton(config)
	local Element = newElement(self, config, "Button", 34)
	local Back = track(Element, box(4, Theme.Element, 5))
	local Border = track(Element, outline(5, Theme.Border, 5))
	local Title = track(Element, label(6, Element.Title, Element.TextColor or Theme.Text))
	Title.Center = true
	Element.FlashUntil = 0
	Element.Primary = config.Primary == true
	Element.Disabled = config.Disabled == true

	function Element:Paint()
		local flashing = tick() < self.FlashUntil
		if self.Disabled then
			Back.Color = Theme.Element
			Border.Color = Theme.Border
			Title.Color = Theme.PulseText
		elseif self.Primary then
			Back.Color = (self.Hovered or flashing) and Theme.AccentHover or Theme.Accent
			Border.Color = Theme.Accent
			Title.Color = self.TextColor or Theme.Text
		else
			Back.Color = flashing and Theme.Accent or (self.Hovered and Theme.ElementHover or Theme.Element)
			Border.Color = (self.Hovered or flashing) and Theme.Accent or Theme.Border
			Title.Color = self.TextColor or Theme.Text
		end
	end
	function Element:Pulse()
		if self.Disabled or tick() < self.FlashUntil then return end
		Back.Color = self.Primary and pulse(Theme.AccentHover, Theme.Accent) or pulse(Theme.PulseBright, Theme.PulseDark)
	end
	function Element:SetDisabled(value)
		self.Disabled = value == true
		self:Paint()
	end
	function Element:Place(x, y, width)
		Back.Position = Vector2.new(x + 12, y + 4)
		Back.Size = Vector2.new(width - 24, 26)
		Border.Position = Back.Position
		Border.Size = Back.Size
		Title.Text = fit(self.Title, Library.TextSize, width - 40)
		Title.Position = Vector2.new(x + width / 2, y + 17)
		self:Paint()
	end
	function Element:Click()
		if self.Disabled then return end
		self.FlashUntil = tick() + 0.15
		self:Paint()
		fire(self, true)
	end
	function Element:Tick()
		if self.FlashUntil > 0 and tick() >= self.FlashUntil then
			self.FlashUntil = 0
			self:Paint()
		end
	end
	return Element
end

function Section:AddLabel(text, color)
	local Element = newElement(self, {Title = text, TextColor = color}, "Label", 22)
	local Title = track(Element, label(4, text, color or Theme.SubText))
	function Element:Place(x, y, width)
		Title.Text = fit(self.Title, Library.TextSize, width - 24)
		Title.Position = Vector2.new(x + 12, y + 4)
	end
	function Element:SetText(value)
		self.Title = value
		if self.Width > 0 then self:Place(self.X, self.Y, self.Width) end
	end
	return Element
end

function Section:AddParagraph(config)
	local Element = newElement(self, config, "Paragraph", 24)
	Element.Title = config.Title or ""
	Element.Content = config.Content or ""
	local Title = track(Element, label(4, Element.Title, Element.TextColor or Theme.Text))
	Element.Lines = {}
	for i = 1, 14 do Element.Lines[i] = track(Element, label(4, "", Theme.SubText, Library.TextSize - 1)) end
	function Element:Measure(width)
		self.Wrapped = wrap(self.Content, Library.TextSize - 1, width - 24)
		local titled = self.Title ~= ""
		self.Height = (titled and 26 or 8) + math.min(#self.Wrapped, 14) * 16
	end
	function Element:Place(x, y, width)
		local titled = self.Title ~= ""
		Title.Text = fit(self.Title, Library.TextSize, width - 24)
		Title.Position = Vector2.new(x + 12, y + 4)
		Title.Visible = self.Shown and titled
		local firstY = titled and y + 24 or y + 4
		for i, Line in ipairs(self.Lines) do
			Line.Text = self.Wrapped[i] or ""
			Line.Position = Vector2.new(x + 12, firstY + (i - 1) * 16)
		end
	end
	function Element:ShowLines(visible)
		for i, Line in ipairs(self.Lines) do Line.Visible = visible and self.Wrapped[i] ~= nil end
	end
	return Element
end

function Section:AddDropdown(config)
	local Element = newElement(self, config, "Dropdown", 52)
	Element.Multi = config.Multi == true
	function Element:BuildItems(values, groups)
		self.Items = {}
		self.Values = {}
		self.Grouped = groups ~= nil
		if groups then
			for _, Group in ipairs(groups) do
				self.Items[#self.Items + 1] = {Header = Group.Name or Group.Title or ""}
				for _, value in ipairs(Group.Values or {}) do
					self.Items[#self.Items + 1] = {Value = value}
					self.Values[#self.Values + 1] = value
				end
			end
		else
			for _, value in ipairs(values or {}) do
				self.Items[#self.Items + 1] = {Value = value}
				self.Values[#self.Values + 1] = value
			end
		end
	end
	Element:BuildItems(config.Values, config.Groups)
	if Element.Multi then
		Element.Value = {}
		for _, value in ipairs(type(config.Default) == "table" and config.Default or {}) do Element.Value[value] = true end
	else
		Element.Value = config.Default or Element.Values[1]
	end
	local Title = track(Element, label(4, Element.Title, Element.TextColor or Theme.Text))
	local Back = track(Element, box(4, Theme.Element, 4))
	local Border = track(Element, outline(5, Theme.Border, 4))
	local Value = track(Element, label(5, "", Theme.SubText))
	local Arrow = track(Element, draw("Triangle", {Filled = true, Color = Theme.SubText, ZIndex = 5, Visible = false, Transparency = 1}))

	function Element:Display()
		if not self.Multi then return tostring(self.Value or "None") end
		local Chosen = {}
		for _, value in ipairs(self.Values) do
			if self.Value[value] then Chosen[#Chosen + 1] = tostring(value) end
		end
		return #Chosen > 0 and table.concat(Chosen, ", ") or "None"
	end
	function Element:Paint()
		local open = Library.Popup and Library.Popup.Owner == self
		Back.Color = self.Hovered and Theme.ElementHover or Theme.Element
		Border.Color = (open or self.Hovered) and Theme.Accent or Theme.Border
		Arrow.Color = open and Theme.Accent or Theme.SubText
		Value.Text = fit(self:Display(), Library.TextSize, self.Width - 56)
	end
	function Element:Pulse()
		Back.Color = pulse(Theme.PulseBright, Theme.PulseDark)
	end
	function Element:Place(x, y, width)
		Title.Text = fit(self.Title, Library.TextSize, width - 24)
		Title.Position = Vector2.new(x + 12, y + 5)
		Back.Position = Vector2.new(x + 12, y + 24)
		Back.Size = Vector2.new(width - 24, 24)
		Border.Position = Back.Position
		Border.Size = Back.Size
		Value.Position = Vector2.new(x + 20, y + 29)
		local ax, ay = x + width - 28, y + 33
		Arrow.PointA = Vector2.new(ax, ay)
		Arrow.PointB = Vector2.new(ax + 8, ay)
		Arrow.PointC = Vector2.new(ax + 4, ay + 5)
		self:Paint()
	end
	function Element:Click()
		if Library.Popup and Library.Popup.Owner == self then
			Library:ClosePopup()
		else
			Library:OpenList(self)
		end
	end
	function Element:Choose(value)
		if self.Multi then
			self.Value[value] = not self.Value[value] or nil
		else
			self.Value = value
			Library:ClosePopup()
		end
		self:Paint()
		fire(self, self.Value)
	end
	function Element:Set(value)
		if self.Multi then
			self.Value = {}
			for _, item in ipairs(type(value) == "table" and value or {}) do self.Value[item] = true end
		else
			self.Value = value
		end
		self:Paint()
		fire(self, self.Value)
	end
	function Element:SetValues(values, groups)
		if Library.Popup and Library.Popup.Owner == self then Library:ClosePopup() end
		self:BuildItems(values, groups)
		self:Paint()
	end
	return Element
end

function Section:AddKeybind(config)
	local Element = newElement(self, config, "Keybind", 28)
	Element.Key = config.Default
	Element.Mode = config.Mode or "Toggle"
	Element.Value = false
	local Title = track(Element, label(4, Element.Title, Element.TextColor or Theme.Text))
	local Chip = track(Element, box(4, Theme.Element, 4))
	local Border = track(Element, outline(5, Theme.Border, 4))
	local Key = track(Element, label(6, "", Theme.SubText))
	Key.Center = true

	function Element:Paint()
		local binding = Library.Binding == self
		local text = binding and "..." or Library.KeyName(self.Key)
		local chipWidth = math.max(Library.TextWidth(text) + 16, 36)
		Chip.Size = Vector2.new(chipWidth, 20)
		Chip.Position = Vector2.new(self.X + self.Width - 12 - chipWidth, self.Y + 4)
		Border.Position = Chip.Position
		Border.Size = Chip.Size
		Border.Color = (binding or self.Hovered) and Theme.Accent or Theme.Border
		Chip.Color = self.Hovered and Theme.ElementHover or Theme.Element
		Key.Text = text
		Key.Color = binding and Theme.Accent or ((self.Mode == "Toggle" and self.Value) and Theme.Accent or Theme.SubText)
		Key.Position = Vector2.new(Chip.Position.X + chipWidth / 2, self.Y + 14)
	end
	function Element:Pulse()
		Chip.Color = pulse(Theme.PulseBright, Theme.PulseDark)
	end
	function Element:Place(x, y, width)
		Title.Text = fit(self.Title, Library.TextSize, width - 90)
		Title.Position = Vector2.new(x + 12, y + 7)
		self:Paint()
	end
	function Element:Click()
		Library:StartBinding(self)
	end
	function Element:Bind(code)
		self.Key = code
		self:Paint()
	end
	function Element:Pressed(down)
		if self.Mode == "Hold" then
			if self.Value ~= down then
				self.Value = down
				fire(self, down)
			end
		elseif down then
			if self.Mode == "Toggle" then self.Value = not self.Value end
			self:Paint()
			fire(self, self.Mode == "Toggle" and self.Value or true)
		end
	end
	Library.Keybinds[#Library.Keybinds + 1] = Element
	return Element
end

function Section:AddColorpicker(config)
	local Element = newElement(self, config, "Colorpicker", 28)
	Element.Value = config.Default or Theme.Accent
	local h, s, v = toHSV(Element.Value)
	Element.Hue, Element.Saturation, Element.Brightness = h, s, v
	local Title = track(Element, label(4, Element.Title, Element.TextColor or Theme.Text))
	local Swatch = track(Element, box(5, Element.Value, 4))
	local Border = track(Element, outline(6, Theme.Border, 4))

	function Element:Paint()
		local open = Library.Popup and Library.Popup.Owner == self
		Swatch.Color = self.Value
		Border.Color = (open or self.Hovered) and Theme.Accent or Theme.Border
	end
	function Element:Pulse()
		Border.Color = pulse(Theme.AccentHover, Theme.AccentDark)
	end
	function Element:Place(x, y, width)
		Title.Text = fit(self.Title, Library.TextSize, width - 70)
		Title.Position = Vector2.new(x + 12, y + 7)
		Swatch.Position = Vector2.new(x + width - 30, y + 5)
		Swatch.Size = Vector2.new(18, 18)
		Border.Position = Swatch.Position
		Border.Size = Swatch.Size
		self:Paint()
	end
	function Element:Click()
		if Library.Popup and Library.Popup.Owner == self then
			Library:ClosePopup()
		else
			Library:OpenPicker(self)
		end
	end
	function Element:SetHSV(hue, saturation, brightness)
		self.Hue, self.Saturation, self.Brightness = hue, saturation, brightness
		self.Value = Color3.fromHSV(hue, saturation, brightness)
		self:Paint()
		fire(self, self.Value)
	end
	function Element:Set(color)
		local hue, saturation, brightness = toHSV(color)
		self:SetHSV(hue, saturation, brightness)
	end
	return Element
end

function Section:AddTextbox(config)
	local Element = newElement(self, config, "Textbox", 52)
	Element.Value = config.Default or ""
	Element.Placeholder = config.Placeholder or "Type here..."
	Element.MaxLength = config.MaxLength or 64
	Element.Numeric = config.Numeric == true
	Element.Filter = config.Filter
	local Title = track(Element, label(4, Element.Title, Element.TextColor or Theme.Text))
	local Back = track(Element, box(4, Theme.Element, 4))
	local Border = track(Element, outline(5, Theme.Border, 4))
	local Text = track(Element, label(5, "", Theme.Text))

	function Element:Paint()
		local typing = Library.Typing == self
		local shown = typing and Library.TypingText or self.Value
		Back.Color = self.Hovered and Theme.ElementHover or Theme.Element
		Border.Color = (typing or self.Hovered) and Theme.Accent or Theme.Border
		if typing then
			Text.Color = Theme.Text
			Library:RenderEdit(Text, self.X + 20, self.Y + 29, self.Width - 40, 5 + self.Layer)
		elseif shown == "" then
			Text.Text = fit(self.Placeholder, Library.TextSize, self.Width - 40)
			Text.Color = Theme.SubText
		else
			Text.Text = fit(shown, Library.TextSize, self.Width - 40)
			Text.Color = Theme.Text
		end
	end
	function Element:Pulse()
		Back.Color = pulse(Theme.PulseBright, Theme.PulseDark)
	end
	function Element:Place(x, y, width)
		Title.Text = fit(self.Title, Library.TextSize, width - 24)
		Title.Position = Vector2.new(x + 12, y + 5)
		Back.Position = Vector2.new(x + 12, y + 24)
		Back.Size = Vector2.new(width - 24, 24)
		Border.Position = Back.Position
		Border.Size = Back.Size
		Text.Position = Vector2.new(x + 20, y + 29)
		self:Paint()
	end
	function Element:Click(mx)
		if Library.Typing ~= self then Library:StartTyping(self) end
		Library:EditClick(mx)
	end
	function Element:Tick()
		if Library.Typing == self then self:Paint() end
	end
	function Element:Set(value)
		value = tostring(value or "")
		self.Value = value
		self:Paint()
		fire(self, value)
	end
	return Element
end

function Section:AddItem(config)
	local Element = newElement(self, config, "Item", 28)
	Element.Value = config.Title or ""
	local Back = track(Element, box(4, Theme.Element, 4))
	local Title = track(Element, label(5, Element.Value, Element.TextColor or Theme.Text))
	local Cross = track(Element, box(5, Theme.Element, 4))
	local LineA = track(Element, draw("Line", {Color = Theme.SubText, Thickness = 2, ZIndex = 6, Visible = false, Transparency = 1}))
	local LineB = track(Element, draw("Line", {Color = Theme.SubText, Thickness = 2, ZIndex = 6, Visible = false, Transparency = 1}))

	function Element:OverCross(mx, my)
		return inside(mx, my, self.X + self.Width - 38, self.Y + 3, 22, 22)
	end
	function Element:Paint()
		local Mouse = Library.Mouse
		local over = self.Hovered and Mouse and self:OverCross(Mouse.X, Mouse.Y)
		local back = self.Hovered and Theme.ElementHover or Theme.Element
		local line = over and Theme.Text or Theme.SubText
		Back.Color = back
		Cross.Color = over and Theme.CloseDark or back
		LineA.Color = line
		LineB.Color = line
	end
	function Element:Pulse()
		local Mouse = Library.Mouse
		if Mouse and self:OverCross(Mouse.X, Mouse.Y) then
			Back.Color = Theme.ElementHover
			Cross.Color = pulse(Theme.CloseBright, Theme.CloseDark)
			LineA.Color = Theme.Text
			LineB.Color = Theme.Text
		else
			local back = pulse(Theme.PulseBright, Theme.PulseDark)
			Back.Color = back
			Cross.Color = back
			LineA.Color = Theme.SubText
			LineB.Color = Theme.SubText
		end
	end
	function Element:Place(x, y, width)
		Back.Position = Vector2.new(x + 12, y + 2)
		Back.Size = Vector2.new(width - 24, 24)
		Title.Text = fit(self.Value, Library.TextSize, width - 64)
		Title.Position = Vector2.new(x + 20, y + 7)
		local cx = x + width - 38
		Cross.Position = Vector2.new(cx, y + 3)
		Cross.Size = Vector2.new(22, 22)
		LineA.From = Vector2.new(cx + 7, y + 9)
		LineA.To = Vector2.new(cx + 15, y + 18)
		LineB.From = Vector2.new(cx + 15, y + 9)
		LineB.To = Vector2.new(cx + 7, y + 18)
		self:Paint()
	end
	function Element:Click(mx, my)
		if self:OverCross(mx, my) then fire(self, self.Value) end
	end
	return Element
end

function Section:RemoveElement(Element)
	local index = table.find(self.Elements, Element)
	if not index then return end
	table.remove(self.Elements, index)
	if Element.Id and Library.Options[Element.Id] == Element then Library.Options[Element.Id] = nil end
	if Library.Typing == Element then Library:StopTyping(true) end
	if Library.Popup and Library.Popup.Owner == Element then Library:ClosePopup() end
	local Owner = self.Tab.Window
	if Owner.Hovered == Element then Owner.Hovered = nil end
	for _, Object in ipairs(Element.Draws) do
		local position = table.find(Library.Drawings, Object)
		if position then table.remove(Library.Drawings, position) end
		pcall(function() Object:Remove() end)
	end
	Element.Draws = {}
	Element.Shown = false
	Library.Dirty = true
end

local Tab = {}
Tab.__index = Tab

function Tab:AddSection(title, side)
	local NewSection = setmetatable({
		Title = title,
		Side = (side == "Right" or side == "Full") and side or "Left",
		Tab = self,
		Elements = {},
		Back = box(2, Theme.Section, 8),
		Border = outline(3, Theme.Section, 8),
		Header = label(3, title, Theme.Header),
		Line = box(3, Theme.Line, 0),
	}, Section)
	NewSection.Header.Font = Library.Font
	self.Sections[#self.Sections + 1] = NewSection
	Library.Dirty = true
	return NewSection
end

for name, method in pairs(Section) do
	if name:sub(1, 3) == "Add" then
		Section[name] = function(self, ...)
			local previous = Library.Layer
			Library.Layer = self.Tab.Window.Layer
			local Result = table.pack(pcall(method, self, ...))
			Library.Layer = previous
			if not Result[1] then error(Result[2], 2) end
			return table.unpack(Result, 2, Result.n)
		end
	end
end

local addSection = Tab.AddSection
function Tab:AddSection(...)
	local previous = Library.Layer
	Library.Layer = self.Window.Layer
	local ok, Result = pcall(addSection, self, ...)
	Library.Layer = previous
	if not ok then error(Result, 2) end
	return Result
end

local Window = {}
Window.__index = Window

local topbarHeight = 36
local sidebarWidth = 150
local gap = 10

function Library:CreateWindow(config)
	config = config or {}
	local NewWindow = setmetatable({
		Title = config.Title or "VantaUI",
		SubTitle = config.SubTitle or "",
		Position = config.Position or Vector2.new(260, 160),
		Size = config.Size or Vector2.new(680, 480),
		MenuKey = (config.MenuKey == nil and 0xA1) or config.MenuKey or nil,
		SidebarWidth = config.Sidebar == false and 0 or 150,
		Layer = config.Layer or 0,
		StayOpen = config.StayOpen == true,
		OnClose = config.OnClose,
		MinSize = config.MinSize or Vector2.new(520, 360),
		Resizable = config.Resizable ~= false,
		BlockInput = config.BlockInput ~= false,
		Tabs = {},
		ActiveTab = nil,
		Visible = config.Visible ~= false,
		Minimized = false,
		Hovered = nil,
	}, Window)
	local previousLayer = Library.Layer
	Library.Layer = NewWindow.Layer
	NewWindow.Chrome = {
		Shadow = box(0, Color3.fromRGB(0, 0, 0), 10),
		Back = box(1, Theme.Background, 8),
		Border = outline(2, Theme.Line, 8),
		Topbar = box(2, Theme.Topbar, 8),
		TopbarFill = box(2, Theme.Topbar, 0),
		AccentLine = box(3, Theme.Accent, 0),
		Title = label(4, NewWindow.Title, Theme.Text, 16),
		SubTitle = label(4, NewWindow.SubTitle, Theme.SubText, 13),
		Sidebar = box(2, Theme.Sidebar, 0),
		SidebarFoot = box(2, Theme.Sidebar, 8),
		SidebarFootFill = box(2, Theme.Sidebar, 0),
		SidebarLine = box(3, Theme.Line, 0),
		MenuChip = box(4, Theme.Element, 4),
		MenuBorder = outline(5, Theme.Border, 4),
		MenuText = label(6, "", Theme.SubText, 13),
		Minimize = box(4, Theme.Topbar, 4),
		MinimizeLine = box(5, Theme.SubText, 0),
		Close = box(4, Theme.Topbar, 4),
		CloseA = draw("Line", {Color = Theme.SubText, Thickness = 2, ZIndex = 5, Visible = false, Transparency = 1}),
		CloseB = draw("Line", {Color = Theme.SubText, Thickness = 2, ZIndex = 5, Visible = false, Transparency = 1}),
		Grip = draw("Triangle", {Filled = true, Color = Theme.Line, ZIndex = 6, Visible = false, Transparency = 1}),
	}
	NewWindow.Chrome.Shadow.Transparency = 0.35
	NewWindow.Chrome.Title.Font = Library.Font
	Library.Layer = previousLayer
	Library.Windows[#Library.Windows + 1] = NewWindow
	NewWindow:ClampToScreen()
	NewWindow:Refresh()
	return NewWindow
end

function Window:AddTab(name)
	local NewTab = setmetatable({
		Name = name,
		Window = self,
		Sections = {},
		Back = box(3, Theme.Sidebar, 5),
		Indicator = box(4, Theme.Accent, 2),
		Text = label(4, name, Theme.SubText),
		Scroll = {Left = 0, Right = 0},
		ScrollMax = {Left = 0, Right = 0},
		Bars = {},
	}, Tab)
	for _, side in ipairs({"Left", "Right"}) do
		local Bar = {IsBar = true, Tab = NewTab, Side = side, Window = self, Track = box(3, Theme.Element, 2), Thumb = box(4, Theme.ElementHover, 2)}
		function Bar:Drag(mx, my)
			local range = math.max(self.Height - self.ThumbHeight, 1)
			local ratio = math.clamp((my - self.GrabOffset - self.Y) / range, 0, 1)
			self.Tab.Scroll[self.Side] = ratio * self.Tab.ScrollMax[self.Side]
			self.Window:Refresh()
		end
		function Bar:Paint()
			self.Window:Refresh()
		end
		function Bar:Scroll(pixels)
			local maximum = self.Tab.ScrollMax[self.Side]
			if maximum <= 0 then return false end
			self.Tab.Scroll[self.Side] = math.clamp(self.Tab.Scroll[self.Side] + pixels, 0, maximum)
			self.Window:Refresh()
			return true
		end
		local Pan = {IsPan = true, Bar = Bar}
		function Pan:Drag(mx, my)
			local maximum = Bar.Tab.ScrollMax[Bar.Side]
			Bar.Tab.Scroll[Bar.Side] = math.clamp(self.StartScroll - (my - self.StartY), 0, maximum)
			Bar.Window:Refresh()
		end
		function Pan:Paint()
			Bar.Window:Refresh()
		end
		Bar.Pan = Pan
		NewTab.Bars[side] = Bar
	end
	self.Tabs[#self.Tabs + 1] = NewTab
	if not self.ActiveTab then self.ActiveTab = NewTab end
	Library.Dirty = true
	return NewTab
end

local addTab = Window.AddTab
function Window:AddTab(...)
	local previous = Library.Layer
	Library.Layer = self.Layer
	local ok, Result = pcall(addTab, self, ...)
	Library.Layer = previous
	if not ok then error(Result, 2) end
	return Result
end

function Window:SelectTab(NewTab)
	if self.ActiveTab == NewTab then return end
	Library:ClosePopup()
	Library:StopTyping(true)
	self.ActiveTab = NewTab
	self:Refresh()
end

function Window:MenuKeyText()
	if Library.Binding == self then return "Press a key..." end
	return "Close/Open: " .. Library.KeyName(self.MenuKey)
end

function Window:Refresh()
	local C = self.Chrome
	local x, y = self.Position.X, self.Position.Y
	local width = self.Size.X
	local height = self.Minimized and topbarHeight or self.Size.Y
	local shown = self.Visible and not Library.Unloaded

	C.Shadow.Position = Vector2.new(x - 4, y - 4)
	C.Shadow.Size = Vector2.new(width + 8, height + 8)
	C.Back.Position = Vector2.new(x, y)
	C.Back.Size = Vector2.new(width, height)
	C.Border.Position = C.Back.Position
	C.Border.Size = C.Back.Size
	C.Topbar.Position = Vector2.new(x, y)
	C.Topbar.Size = Vector2.new(width, topbarHeight)
	C.TopbarFill.Position = Vector2.new(x, y + topbarHeight - 10)
	C.TopbarFill.Size = Vector2.new(width, 10)
	C.TopbarFill.Visible = shown and not self.Minimized
	C.AccentLine.Position = Vector2.new(x, y + topbarHeight - 2)
	C.AccentLine.Size = Vector2.new(width, 2)
	C.Title.Text = self.Title
	C.Title.Position = Vector2.new(x + 14, y + 10)
	C.SubTitle.Text = self.SubTitle
	C.SubTitle.Position = Vector2.new(x + 22 + Library.TextWidth(self.Title, 16), y + 12)

	local closeX = x + width - 32
	C.Close.Position = Vector2.new(closeX, y + 7)
	C.Close.Size = Vector2.new(24, 22)
	C.CloseA.From = Vector2.new(closeX + 7, y + 12)
	C.CloseA.To = Vector2.new(closeX + 17, y + 23)
	C.CloseB.From = Vector2.new(closeX + 17, y + 12)
	C.CloseB.To = Vector2.new(closeX + 7, y + 23)
	local minimizeX = closeX - 28
	C.Minimize.Position = Vector2.new(minimizeX, y + 7)
	C.Minimize.Size = Vector2.new(24, 22)
	C.MinimizeLine.Position = Vector2.new(minimizeX + 7, y + 18)
	C.MinimizeLine.Size = Vector2.new(10, 2)
	local menuText = self:MenuKeyText()
	local chipWidth = Library.TextWidth(menuText, 13) + 18
	C.MenuChip.Position = Vector2.new(minimizeX - 8 - chipWidth, y + 8)
	C.MenuChip.Size = Vector2.new(chipWidth, 20)
	C.MenuBorder.Position = C.MenuChip.Position
	C.MenuBorder.Size = C.MenuChip.Size
	C.MenuText.Text = menuText
	C.MenuText.Center = true
	C.MenuText.Position = Vector2.new(C.MenuChip.Position.X + chipWidth / 2, y + 18)
	C.MenuText.Color = Library.Binding == self and Theme.Accent or Theme.SubText
	C.MenuBorder.Color = (Library.Binding == self or self.Hovered == "Menu") and Theme.Accent or Theme.Border
	C.Close.Color = self.Hovered == "Close" and Color3.fromRGB(170, 45, 45) or Theme.Topbar
	C.Minimize.Color = self.Hovered == "Minimize" and Theme.ElementHover or Theme.Topbar
	C.MenuChip.Color = Theme.Element

	C.Sidebar.Position = Vector2.new(x + 1, y + topbarHeight)
	local sidebarWidth = self.SidebarWidth
	C.Sidebar.Size = Vector2.new(math.max(sidebarWidth - 1, 0), math.max(height - topbarHeight - 9, 0))
	C.SidebarFoot.Position = Vector2.new(x + 1, y + height - 17)
	C.SidebarFoot.Size = Vector2.new(math.max(sidebarWidth - 1, 0), 16)
	C.SidebarFootFill.Position = Vector2.new(x + 12, y + height - 17)
	C.SidebarFootFill.Size = Vector2.new(math.max(sidebarWidth - 12, 0), 16)
	C.SidebarLine.Position = Vector2.new(x + sidebarWidth, y + topbarHeight)
	C.SidebarLine.Size = Vector2.new(1, height - topbarHeight)
	C.Grip.PointA = Vector2.new(x + width - 8, y + height - 18)
	C.Grip.PointB = Vector2.new(x + width - 8, y + height - 8)
	C.Grip.PointC = Vector2.new(x + width - 18, y + height - 8)
	C.Grip.Color = (self.Hovered == "Resize" or (Library.Dragging == self and self.DragMode == "Resize")) and Theme.Accent or Theme.Line

	for name, Object in pairs(C) do
		if name ~= "TopbarFill" then Object.Visible = shown end
	end
	local body = shown and not self.Minimized
	for _, name in ipairs({"Sidebar", "SidebarFoot", "SidebarFootFill", "SidebarLine"}) do C[name].Visible = body and sidebarWidth > 0 end
	for _, name in ipairs({"MenuChip", "MenuBorder", "MenuText"}) do C[name].Visible = shown and self.MenuKey ~= nil end
	C.Grip.Visible = body and self.Resizable

	for i, TabItem in ipairs(self.Tabs) do
		local ty = y + topbarHeight + 10 + (i - 1) * 34
		local active = self.ActiveTab == TabItem
		local hovered = self.Hovered == TabItem
		TabItem.Back.Position = Vector2.new(x + 8, ty)
		TabItem.Back.Size = Vector2.new(sidebarWidth - 16, 28)
		TabItem.Back.Color = active and Theme.Element or (hovered and Theme.Section or Theme.Sidebar)
		TabItem.Indicator.Position = Vector2.new(x + 8, ty + 6)
		TabItem.Indicator.Size = Vector2.new(3, 16)
		TabItem.Text.Position = Vector2.new(x + 22, ty + 7)
		TabItem.Text.Color = active and Theme.Accent or (hovered and Theme.Text or Theme.SubText)
		local listed = body and sidebarWidth > 0
		TabItem.Back.Visible = listed
		TabItem.Indicator.Visible = listed and active
		TabItem.Text.Visible = listed
		TabItem.Top = ty
	end

	local contentX = x + sidebarWidth + gap
	local contentY = y + topbarHeight + gap
	local contentBottom = y + height - gap
	local viewHeight = math.max(contentBottom - contentY, 1)
	local columnWidth = math.floor((width - sidebarWidth - gap * 3) / 2)
	local fullWidth = columnWidth * 2 + gap
	self.ContentX, self.ContentY, self.ContentBottom, self.ColumnWidth = contentX, contentY, contentBottom, columnWidth
	for _, TabItem in ipairs(self.Tabs) do
		local active = body and self.ActiveTab == TabItem
		local unified = false
		for _, S in ipairs(TabItem.Sections) do
			if S.Side == "Full" then unified = true end
		end
		TabItem.Unified = unified
		local cursor = {Left = 0, Right = 0}
		for _, S in ipairs(TabItem.Sections) do
			local sectionWidth = S.Side == "Full" and fullWidth or columnWidth
			local sectionHeight = 32
			for _, Element in ipairs(S.Elements) do
				if not Element.Hidden then
					if Element.Measure then Element:Measure(sectionWidth) end
					sectionHeight += Element.Height
				end
			end
			S.Height = sectionHeight + 6
			S.Width = sectionWidth
			if S.Side == "Full" then
				S.Offset = math.max(cursor.Left, cursor.Right)
				cursor.Left = S.Offset + S.Height + gap
				cursor.Right = cursor.Left
			else
				S.Offset = cursor[S.Side]
				cursor[S.Side] += S.Height + gap
			end
		end
		local totals = unified and {Left = math.max(cursor.Left, cursor.Right), Right = 0} or cursor
		for _, side in ipairs({"Left", "Right"}) do
			local total = math.max(totals[side] - gap, 0)
			local maximum = math.max(total - viewHeight, 0)
			TabItem.ScrollMax[side] = maximum
			TabItem.Scroll[side] = math.clamp(TabItem.Scroll[side], 0, maximum)
			local Bar = TabItem.Bars[side]
			local trackX = (side == "Left" and not unified) and contentX + columnWidth + 3 or contentX + fullWidth + 3
			local thumbHeight = math.max(viewHeight * viewHeight / math.max(total, 1), 24)
			local ratio = maximum > 0 and TabItem.Scroll[side] / maximum or 0
			Bar.X, Bar.Y, Bar.Height, Bar.ThumbHeight = trackX, contentY, viewHeight, thumbHeight
			Bar.ThumbY = contentY + (viewHeight - thumbHeight) * ratio
			Bar.Track.Position = Vector2.new(trackX, contentY)
			Bar.Track.Size = Vector2.new(4, viewHeight)
			Bar.Thumb.Position = Vector2.new(trackX, Bar.ThumbY)
			Bar.Thumb.Size = Vector2.new(4, thumbHeight)
			Bar.Thumb.Color = (Library.Dragging == Bar or self.Hovered == Bar) and Theme.Accent or Theme.ElementHover
			local scrollable = active and maximum > 0
			if scrollable and not Bar.WasShown then Bar.GlowStart = tick() end
			Bar.WasShown = scrollable
			Bar.Shown = scrollable
			Bar.Track.Visible = scrollable
			Bar.Thumb.Visible = scrollable
		end
		for _, S in ipairs(TabItem.Sections) do
			local scroll = unified and TabItem.Scroll.Left or TabItem.Scroll[S.Side == "Full" and "Left" or S.Side]
			local sx = S.Side == "Right" and contentX + columnWidth + gap or contentX
			local sectionWidth = S.Width
			local sy = contentY + S.Offset - scroll
			local top = math.max(sy, contentY)
			local bottom = math.min(sy + S.Height, contentBottom)
			S.Back.Position = Vector2.new(sx, top)
			S.Back.Size = Vector2.new(sectionWidth, math.max(bottom - top, 0))
			S.Border.Position = S.Back.Position
			S.Border.Size = S.Back.Size
			S.Header.Position = Vector2.new(sx + 14, sy + 9)
			S.Line.Position = Vector2.new(sx + 12, sy + 28)
			S.Line.Size = Vector2.new(sectionWidth - 24, 1)
			local cardShown = active and bottom - top > 4
			local headerShown = active and sy >= contentY and sy + 30 <= contentBottom
			S.Back.Visible = cardShown
			S.Border.Visible = cardShown
			S.Header.Visible = headerShown
			S.Line.Visible = headerShown
			local ey = sy + 32
			for _, Element in ipairs(S.Elements) do
				Element.X, Element.Y, Element.Width = sx, ey, sectionWidth
				Element.Shown = active and not Element.Hidden and ey >= contentY and ey + Element.Height <= contentBottom
				setVisible(Element.Draws, Element.Shown)
				if Element.Shown then Element:Place(sx, ey, sectionWidth) end
				if Element.ShowLines then Element:ShowLines(Element.Shown) end
				if not Element.Hidden then ey += Element.Height end
			end
		end
	end
	if Library.Typing and Library.Typing.Kind and not Library.Typing.Shown then Library:StopTyping(false) end
	if Library.Popup then
		if Library.Popup.Owner.Shown == false then
			Library:ClosePopup()
		else
			Library.Popup:Place()
		end
	end
end

function Window:ClampToScreen()
	local camera = workspace.CurrentCamera
	local ok, viewport = pcall(function() return camera.ViewportSize end)
	if not (ok and viewport and viewport.X > 0 and viewport.Y > 0) then return end
	local height = self.Minimized and topbarHeight or self.Size.Y
	local x = math.clamp(self.Position.X, 0, math.max(viewport.X - self.Size.X, 0))
	local y = math.clamp(self.Position.Y, 0, math.max(viewport.Y - height, 0))
	self.Position = Vector2.new(math.floor(x), math.floor(y))
end

function Window:Destroy()
	local Doomed = {}
	for _, Object in pairs(self.Chrome) do Doomed[Object] = true end
	for _, TabItem in ipairs(self.Tabs) do
		for _, Object in ipairs({TabItem.Back, TabItem.Indicator, TabItem.Text}) do Doomed[Object] = true end
		for _, Bar in pairs(TabItem.Bars) do
			Doomed[Bar.Track] = true
			Doomed[Bar.Thumb] = true
		end
		for _, S in ipairs(TabItem.Sections) do
			for _, Object in ipairs({S.Back, S.Border, S.Header, S.Line}) do Doomed[Object] = true end
			for _, Element in ipairs(S.Elements) do
				for _, Object in ipairs(Element.Draws) do Doomed[Object] = true end
				if Element.Id and Library.Options[Element.Id] == Element then Library.Options[Element.Id] = nil end
				if Library.Typing == Element then Library:StopTyping(true) end
				if Library.Popup and Library.Popup.Owner == Element then Library:ClosePopup() end
				local position = table.find(Library.Keybinds, Element)
				if position then table.remove(Library.Keybinds, position) end
			end
		end
	end
	if Library.Dragging == self or (type(Library.Dragging) == "table" and (Library.Dragging.Window == self or (Library.Dragging.Bar and Library.Dragging.Bar.Window == self))) then Library.Dragging = nil end
	if Library.Binding == self then Library.Binding = nil end
	local Kept = {}
	for _, Object in ipairs(Library.Drawings) do
		if Doomed[Object] then
			pcall(function() Object:Remove() end)
		else
			Kept[#Kept + 1] = Object
		end
	end
	Library.Drawings = Kept
	local index = table.find(Library.Windows, self)
	if index then table.remove(Library.Windows, index) end
	self.Visible = false
	self.Destroyed = true
end

function Window:HideChildren()
	for _, Other in ipairs(Library.Windows) do
		if Other ~= self and Other.MenuKey == nil and not Other.StayOpen and Other.Visible then Other:SetVisible(false) end
	end
end

function Window:SetVisible(visible)
	self.Visible = visible
	if visible then self:ClampToScreen() end
	if not visible then
		Library:ClosePopup()
		Library:StopTyping(true)
		if Library.Binding and Library.Binding ~= self then Library.Binding = nil end
	end
	self:Refresh()
end

function Window:SetMinimized(minimized)
	if self.Minimized == minimized then return end
	self.Minimized = minimized
	Library:ClosePopup()
	if minimized then Library:StopTyping(true) end
	self:Refresh()
end

local function popupRows(count)
	Library.Rows = Library.Rows or {}
	for i = #Library.Rows + 1, count do
		Library.Rows[i] = {
			Back = box(21, Theme.Element, 0),
			Check = box(22, Theme.CheckOff, 3),
			CheckBorder = outline(23, Theme.Border, 3),
			Text = label(23, "", Theme.Text),
			Line = box(22, Theme.Line, 0),
		}
	end
	return Library.Rows
end

function Library:ClosePopup()
	local Popup = self.Popup
	if not Popup then return end
	if self.Typing and self.Typing.InPopup then self:StopTyping(false) end
	self.Popup = nil
	setVisible(Popup.Draws, false)
	if Popup.Rows then
		for _, Row in ipairs(Popup.Rows) do setVisible({Row.Back, Row.Check, Row.CheckBorder, Row.Text, Row.Line}, false) end
	end
	if Popup.Owner.Paint then Popup.Owner:Paint() end
	if self.Dragging == Popup then self.Dragging = nil end
end

function Library:OpenList(Owner)
	self:ClosePopup()
	local maxRows = 8
	local Rows = popupRows(maxRows)
	local Frame = self.ListFrame or box(20, Theme.Section, 5)
	local Border = self.ListBorder or outline(24, Theme.Accent, 5)
	self.ListFrame, self.ListBorder = Frame, Border
	local Track = self.ListTrack or box(22, Theme.Element, 2)
	local Thumb = self.ListThumb or box(23, Theme.ElementHover, 2)
	self.ListTrack, self.ListThumb = Track, Thumb
	local Items = Owner.Items
	local Popup = {Owner = Owner, Draws = {Frame, Border, Track, Thumb}, Rows = {}, Offset = 0}
	local count = math.min(#Items, maxRows)
	local scrollable = #Items > count
	local maximum = #Items - count
	for i = 1, count do Popup.Rows[i] = Rows[i] end
	if not Owner.Multi then
		for i, Item in ipairs(Items) do
			if Item.Value ~= nil and Item.Value == Owner.Value then Popup.Offset = math.clamp(i - count, 0, maximum) end
		end
	end

	function Popup:Place()
		local x, y = Owner.X + 12, Owner.Y + 50
		local width = Owner.Width - 24
		self.X, self.Y, self.Width, self.Height = x, y, width, count * 24 + 4
		Frame.Position = Vector2.new(x, y)
		Frame.Size = Vector2.new(width, self.Height)
		Border.Position = Frame.Position
		Border.Size = Frame.Size
		local rowWidth = scrollable and width - 12 or width
		self.TrackX = x + width - 9
		self.TrackY = y + 4
		self.TrackHeight = self.Height - 8
		self.ThumbHeight = math.max(self.TrackHeight * count / #Items, 16)
		self.ThumbY = self.TrackY + (maximum > 0 and (self.TrackHeight - self.ThumbHeight) * self.Offset / maximum or 0)
		Track.Position = Vector2.new(self.TrackX, self.TrackY)
		Track.Size = Vector2.new(4, self.TrackHeight)
		Thumb.Position = Vector2.new(self.TrackX, self.ThumbY)
		Thumb.Size = Vector2.new(4, self.ThumbHeight)
		Thumb.Color = (Library.Dragging == self or self.OverBar) and Theme.Accent or Theme.ElementHover
		Track.Visible = scrollable
		Thumb.Visible = scrollable
		for i, Row in ipairs(self.Rows) do
			local Item = Items[i + self.Offset]
			local ry = y + 2 + (i - 1) * 24
			Row.Back.Position = Vector2.new(x + 2, ry)
			Row.Back.Size = Vector2.new(rowWidth - 4, 24)
			Row.Back.Visible = true
			Row.Text.Visible = true
			if Item.Header then
				Row.Back.Color = Theme.Section
				Row.Check.Visible = false
				Row.CheckBorder.Visible = false
				local text = fit(Item.Header, Library.TextSize - 1, rowWidth - 60)
				Row.Text.Text = text
				Row.Text.Size = Library.TextSize - 1
				Row.Text.Color = Theme.Accent
				Row.Text.Position = Vector2.new(x + 10, ry + 6)
				local lineX = x + 18 + Library.TextWidth(text, Library.TextSize - 1)
				Row.Line.Position = Vector2.new(lineX, ry + 12)
				Row.Line.Size = Vector2.new(math.max(x + rowWidth - 10 - lineX, 0), 1)
				Row.Line.Visible = true
			else
				local value = Item.Value
				local selected = Owner.Multi and Owner.Value[value] or (not Owner.Multi and Owner.Value == value)
				Row.Line.Visible = false
				Row.Text.Size = Library.TextSize
				Row.Back.Color = self.HoverRow == i and Theme.ElementHover or Theme.Section
				local indent = Owner.Grouped and 8 or 0
				local textX = x + 12 + indent
				if Owner.Multi then
					Row.Check.Position = Vector2.new(x + 10 + indent, ry + 5)
					Row.Check.Size = Vector2.new(14, 14)
					Row.Check.Color = selected and Theme.Accent or Theme.CheckOff
					Row.CheckBorder.Position = Row.Check.Position
					Row.CheckBorder.Size = Row.Check.Size
					Row.CheckBorder.Color = selected and Theme.Accent or Theme.Border
					Row.Check.Visible = true
					Row.CheckBorder.Visible = true
					textX = x + 32 + indent
				else
					Row.Check.Visible = false
					Row.CheckBorder.Visible = false
				end
				Row.Text.Text = fit(value, Library.TextSize, rowWidth - (textX - x) - 10)
				Row.Text.Position = Vector2.new(textX, ry + 5)
				Row.Text.Color = selected and Theme.Accent or Theme.Text
			end
		end
	end
	function Popup:Hit(mx, my)
		return inside(mx, my, self.X, self.Y, self.Width, self.Height)
	end
	function Popup:Pulse()
		local Row = self.HoverRow and self.Rows[self.HoverRow]
		if Row then Row.Back.Color = pulse(Theme.PulseBright, Theme.PulseDark) end
		if scrollable and self.GlowStart then
			local normal = (Library.Dragging == self or self.OverBar) and Theme.Accent or Theme.ElementHover
			local color = glowColor(self.GlowStart, normal)
			Thumb.Color = color or normal
			if not color then self.GlowStart = nil end
		end
	end
	function Popup:Hover(mx, my)
		local row = math.floor((my - self.Y - 2) / 24) + 1
		local overBar = scrollable and self:Hit(mx, my) and mx >= self.TrackX - 4
		local Item = Items[row + self.Offset]
		local hovered = self:Hit(mx, my) and not overBar and row >= 1 and row <= #self.Rows and Item and not Item.Header and row or nil
		if overBar ~= self.OverBar then
			self.OverBar = overBar
			self:Place()
		end
		if hovered ~= self.HoverRow then
			Library.PulseStart = tick()
			self.HoverRow = hovered
			self:Place()
		end
	end
	function Popup:Scroll(steps)
		if not scrollable then return false end
		local offset = math.clamp(self.Offset + steps, 0, maximum)
		if offset == self.Offset then return true end
		self.Offset = offset
		self.HoverRow = nil
		self:Place()
		return true
	end
	function Popup:Drag(mx, my)
		if self.Grab == "Rows" then
			local moved = my - self.PressY
			if math.abs(moved) > 6 then self.Moved = true end
			if self.Moved and scrollable then
				local offset = math.clamp(self.PressOffset - math.floor(moved / 24 + 0.5), 0, maximum)
				if offset ~= self.Offset then
					self.Offset = offset
					self.HoverRow = nil
					self:Place()
				end
			end
			return
		end
		local range = math.max(self.TrackHeight - self.ThumbHeight, 1)
		local ratio = math.clamp((my - self.GrabOffset - self.TrackY) / range, 0, 1)
		self.Offset = math.floor(ratio * maximum + 0.5)
		self:Place()
	end
	function Popup:Release()
		local grab = self.Grab
		self.Grab = nil
		if grab ~= "Rows" or self.Moved then
			if self == Library.Popup then self:Place() end
			return
		end
		local Item = Items[self.PressRow + self.PressOffset]
		if self.PressRow >= 1 and self.PressRow <= #self.Rows and Item and not Item.Header then
			Owner:Choose(Item.Value)
			if self == Library.Popup then self:Place() end
		end
	end
	function Popup:Click(mx, my)
		if scrollable and mx >= self.TrackX - 4 then
			if my >= self.ThumbY and my <= self.ThumbY + self.ThumbHeight then
				self.GrabOffset = my - self.ThumbY
			else
				self.GrabOffset = self.ThumbHeight / 2
			end
			self.Grab = "Bar"
			Library.Dragging = self
			self:Drag(mx, my)
			return
		end
		self.Grab = "Rows"
		self.PressY = my
		self.PressOffset = self.Offset
		self.PressRow = math.floor((my - self.Y - 2) / 24) + 1
		self.Moved = false
		Library.Dragging = self
	end
	self.Popup = Popup
	if scrollable then Popup.GlowStart = tick() end
	setVisible(Popup.Draws, true)
	Popup:Place()
	Owner:Paint()
end

local gridSize = 12
local gridCell = 12
local hueSegments = 24

local function colorBytes(color)
	return math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5)
end

local function pickerField(kind)
	local Field = {
		InPopup = true,
		Field = kind,
		Back = box(24, Theme.CheckOff, 4),
		Border = outline(25, Theme.Border, 4),
		Text = label(26, "", Theme.Text, 12),
		Prefix = label(27, kind == "Hex" and "#" or kind, Theme.SubText, 12),
		MaxLength = kind == "Hex" and 7 or 3,
		Numeric = kind ~= "Hex",
		Filter = kind == "Hex" and "[%x#]" or nil,
	}
	function Field:Current()
		local r, g, b = colorBytes(self.Owner.Value)
		if self.Field == "Hex" then return ("%02X%02X%02X"):format(r, g, b) end
		return tostring(({R = r, G = g, B = b})[self.Field])
	end
	function Field:EditText()
		return self:Current()
	end
	function Field:Paint()
		local Popup = Library.Popup
		if Popup and Popup.Owner == self.Owner and Popup.Place then Popup:Place() end
	end
	function Field:Commit(text)
		if text then
			local r, g, b = colorBytes(self.Owner.Value)
			if self.Field == "Hex" then
				local hex = text:gsub("#", "")
				if #hex == 3 then hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2) end
				if #hex == 6 and hex:match("^%x+$") then
					r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
					self.Owner:Set(Color3.fromRGB(r, g, b))
				end
			else
				local number = tonumber(text)
				if number then
					number = math.clamp(math.floor(number + 0.5), 0, 255)
					if self.Field == "R" then r = number elseif self.Field == "G" then g = number else b = number end
					self.Owner:Set(Color3.fromRGB(r, g, b))
				end
			end
		end
		self:Paint()
	end
	return Field
end

function Library:OpenPicker(Owner)
	self:ClosePopup()
	if not self.Picker then
		local Picker = {Cells = {}, Hues = {}}
		Picker.Frame = box(20, Theme.Section, 6)
		Picker.Border = outline(27, Theme.Accent, 6)
		for i = 1, gridSize * gridSize do Picker.Cells[i] = box(21, Color3.new(1, 1, 1), 0) end
		for i = 1, hueSegments do Picker.Hues[i] = box(21, Color3.new(1, 1, 1), 0) end
		Picker.Cursor = outline(24, Color3.new(1, 1, 1), 3)
		Picker.HueCursor = outline(24, Color3.new(1, 1, 1), 2)
		Picker.Preview = box(22, Color3.new(1, 1, 1), 4)
		Picker.PreviewBorder = outline(23, Theme.Border, 4)
		Picker.Fields = {pickerField("Hex"), pickerField("R"), pickerField("G"), pickerField("B")}
		self.Picker = Picker
	end
	local P = self.Picker
	local Draws = {P.Frame, P.Border, P.Cursor, P.HueCursor, P.Preview, P.PreviewBorder}
	for _, Cell in ipairs(P.Cells) do Draws[#Draws + 1] = Cell end
	for _, Hue in ipairs(P.Hues) do Draws[#Draws + 1] = Hue end
	for _, Field in ipairs(P.Fields) do
		Field.Owner = Owner
		Draws[#Draws + 1] = Field.Back
		Draws[#Draws + 1] = Field.Border
		Draws[#Draws + 1] = Field.Text
		Draws[#Draws + 1] = Field.Prefix
	end
	local Popup = {Owner = Owner, Draws = Draws, Fields = P.Fields}
	local squareSize = gridSize * gridCell
	local fieldHeight = 22

	function Popup:Place()
		local width = squareSize + 44
		local height = 8 + squareSize + 8 + fieldHeight + 6 + fieldHeight + 8
		local x = Owner.X + Owner.Width - 12 - width
		local y = Owner.Y + 28
		self.X, self.Y, self.Width, self.Height = x, y, width, height
		P.Frame.Position = Vector2.new(x, y)
		P.Frame.Size = Vector2.new(width, height)
		P.Border.Position = P.Frame.Position
		P.Border.Size = P.Frame.Size
		self.SquareX, self.SquareY = x + 8, y + 8
		for row = 0, gridSize - 1 do
			for column = 0, gridSize - 1 do
				local Cell = P.Cells[row * gridSize + column + 1]
				Cell.Position = Vector2.new(self.SquareX + column * gridCell, self.SquareY + row * gridCell)
				Cell.Size = Vector2.new(gridCell, gridCell)
				Cell.Color = Color3.fromHSV(Owner.Hue, column / (gridSize - 1), 1 - row / (gridSize - 1))
			end
		end
		self.HueX = self.SquareX + squareSize + 8
		local segment = squareSize / hueSegments
		for i, Hue in ipairs(P.Hues) do
			Hue.Position = Vector2.new(self.HueX, self.SquareY + (i - 1) * segment)
			Hue.Size = Vector2.new(16, segment + 1)
			Hue.Color = Color3.fromHSV((i - 1) / hueSegments, 1, 1)
		end
		P.Cursor.Position = Vector2.new(self.SquareX + Owner.Saturation * squareSize - 4, self.SquareY + (1 - Owner.Brightness) * squareSize - 4)
		P.Cursor.Size = Vector2.new(8, 8)
		P.HueCursor.Position = Vector2.new(self.HueX - 2, self.SquareY + Owner.Hue * squareSize - 2)
		P.HueCursor.Size = Vector2.new(20, 4)

		local rowY = self.SquareY + squareSize + 8
		P.Preview.Position = Vector2.new(self.SquareX, rowY)
		P.Preview.Size = Vector2.new(fieldHeight, fieldHeight)
		P.Preview.Color = Owner.Value
		P.PreviewBorder.Position = P.Preview.Position
		P.PreviewBorder.Size = P.Preview.Size
		local inner = width - 16
		local channelWidth = (inner - 12) / 3
		local Boxes = {
			Hex = {self.SquareX + fieldHeight + 6, rowY, inner - fieldHeight - 6},
			R = {self.SquareX, rowY + fieldHeight + 6, channelWidth},
			G = {self.SquareX + channelWidth + 6, rowY + fieldHeight + 6, channelWidth},
			B = {self.SquareX + (channelWidth + 6) * 2, rowY + fieldHeight + 6, channelWidth},
		}
		for _, Field in ipairs(P.Fields) do
			local Spot = Boxes[Field.Field]
			local typing = Library.Typing == Field
			Field.X, Field.Y, Field.Width = Spot[1], Spot[2], Spot[3]
			Field.Back.Position = Vector2.new(Spot[1], Spot[2])
			Field.Back.Size = Vector2.new(Spot[3], fieldHeight)
			Field.Border.Position = Field.Back.Position
			Field.Border.Size = Field.Back.Size
			Field.Border.Color = typing and Theme.Accent or (self.HoverField == Field and Theme.AccentDark or Theme.Border)
			local prefix = Field.Field == "Hex" and "#" or Field.Field
			Field.Prefix.Text = prefix
			Field.Prefix.Position = Vector2.new(Spot[1] + 7, Spot[2] + 5)
			local textX = Spot[1] + 7 + Library.TextWidth(prefix, 12) + (Field.Field == "Hex" and 1 or 6)
			if typing then
				Field.Text.Color = Theme.Text
				Library:RenderEdit(Field.Text, textX, Spot[2] + 5, Spot[1] + Spot[3] - 6 - textX, 26)
			else
				Field.Text.Text = Field:Current()
				Field.Text.Color = Theme.SubText
				Field.Text.Position = Vector2.new(textX, Spot[2] + 5)
			end
		end
	end
	function Popup:Hit(mx, my)
		return inside(mx, my, self.X, self.Y, self.Width, self.Height)
	end
	function Popup:FieldAt(mx, my)
		for _, Field in ipairs(P.Fields) do
			if Field.X and inside(mx, my, Field.X, Field.Y, Field.Width, fieldHeight) then return Field end
		end
		return nil
	end
	function Popup:Hover(mx, my)
		local Field = self:FieldAt(mx, my)
		if Field ~= self.HoverField then
			self.HoverField = Field
			self:Place()
		end
	end
	function Popup:Drag(mx, my)
		if self.Grab == "Square" then
			local saturation = math.clamp((mx - self.SquareX) / squareSize, 0, 1)
			local brightness = 1 - math.clamp((my - self.SquareY) / squareSize, 0, 1)
			Owner:SetHSV(Owner.Hue, saturation, brightness)
		elseif self.Grab == "Hue" then
			local hue = math.clamp((my - self.SquareY) / squareSize, 0, 0.999)
			Owner:SetHSV(hue, Owner.Saturation, Owner.Brightness)
		end
		self:Place()
	end
	function Popup:Click(mx, my)
		local Field = self:FieldAt(mx, my)
		if Library.Typing and Library.Typing ~= Field then Library:StopTyping(false) end
		if Field then
			if Library.Typing ~= Field then Library:StartTyping(Field) end
			Library:EditClick(mx)
			return
		end
		if inside(mx, my, self.SquareX, self.SquareY, squareSize, squareSize) then
			self.Grab = "Square"
		elseif inside(mx, my, self.HueX, self.SquareY, 16, squareSize) then
			self.Grab = "Hue"
		else
			return
		end
		Library.Dragging = self
		self:Drag(mx, my)
	end
	self.Popup = Popup
	setVisible(Draws, true)
	Popup:Place()
	Owner:Paint()
end

function Library:StartBinding(Target)
	self:ClosePopup()
	self:StopTyping(false)
	self.Binding = Target
	self.BindHeld = {}
	for _, code in ipairs(scanCodes) do self.BindHeld[code] = keyDown(code) end
	for _, W in ipairs(self.Windows) do W:Refresh() end
end

function Library:FinishBinding(code)
	local Target = self.Binding
	self.Binding = nil
	if not Target then return end
	if Target.Chrome then
		if code and code ~= 0x1B then Target.MenuKey = code end
		Target.MenuHeld = true
		Target:Refresh()
		return
	end
	if code == 0x1B then
		Target:Paint()
		return
	end
	if code == 0x08 or code == 0x2E then code = nil end
	Target:Bind(code)
	Target.Held = code and true or false
end

function Library:EnsureEditDraws()
	if self.CaretLine then return end
	self.CaretLine = box(30, Theme.Text, 0)
	self.SelectBox = box(28, Theme.AccentDark, 2)
	self.EditDragger = {}
	function self.EditDragger:Drag(mx)
		local L = Library
		if not L.Typing then return end
		L.Caret = L:EditIndexAt(mx)
		L.CaretMoved = tick()
		L.Typing:Paint()
	end
end

function Library:Selection()
	local anchor, caret = self.Anchor, self.Caret
	if not anchor or anchor == caret then return caret, caret, false end
	return math.min(anchor, caret), math.max(anchor, caret), true
end

function Library:RenderEdit(TextObject, x, y, width, z)
	self:EnsureEditDraws()
	local size = TextObject.Size or self.TextSize
	local text = self.TypingText
	local caret = math.clamp(self.Caret or #text, 0, #text)
	self.Caret = caret
	local scroll = math.clamp(self.EditScroll or 0, 0, #text)
	if caret < scroll then scroll = caret end
	while scroll < caret and Library.TextWidth(text:sub(scroll + 1, caret), size) > width - 2 do scroll += 1 end
	while scroll > 0 and Library.TextWidth(text:sub(scroll, #text), size) <= width - 2 do scroll -= 1 end
	self.EditScroll = scroll
	local visible = text:sub(scroll + 1)
	while #visible > 0 and Library.TextWidth(visible, size) > width do visible = visible:sub(1, -2) end
	self.EditX, self.EditSize = x, size
	TextObject.Text = visible
	TextObject.Position = Vector2.new(x, y)
	TextObject.ZIndex = z + 1
	local Caret, Select = self.CaretLine, self.SelectBox
	local caretX = x + Library.TextWidth(text:sub(scroll + 1, caret), size)
	Caret.Position = Vector2.new(math.floor(caretX), y - 1)
	Caret.Size = Vector2.new(1, size + 3)
	Caret.ZIndex = z + 2
	Caret.Visible = (tick() - (self.CaretMoved or 0)) % 1 < 0.55
	local first, last, has = self:Selection()
	local visibleFirst, visibleLast = math.max(first, scroll), math.min(last, scroll + #visible)
	if has and visibleLast > visibleFirst then
		local startX = x + Library.TextWidth(text:sub(scroll + 1, visibleFirst), size)
		Select.Position = Vector2.new(startX, y - 1)
		Select.Size = Vector2.new(Library.TextWidth(text:sub(visibleFirst + 1, visibleLast), size), size + 3)
		Select.ZIndex = z
		Select.Visible = true
	else
		Select.Visible = false
	end
end

function Library:HideEdit()
	if not self.CaretLine then return end
	self.CaretLine.Visible = false
	self.SelectBox.Visible = false
end

function Library:EditIndexAt(mx)
	local text = self.TypingText or ""
	local scroll = self.EditScroll or 0
	local best, bestDistance = scroll, math.huge
	for i = scroll, #text do
		local distance = math.abs(self.EditX + Library.TextWidth(text:sub(scroll + 1, i), self.EditSize) - mx)
		if distance < bestDistance then best, bestDistance = i, distance end
	end
	return best
end

function Library:EditClick(mx)
	if not self.Typing or not self.EditX then return end
	self:EnsureEditDraws()
	local index = self:EditIndexAt(mx)
	local now = tick()
	if self.LastEditClick and now - self.LastEditClick < 0.35 and math.abs(mx - self.LastEditX) < 6 then
		local text = self.TypingText
		local first, last = index, index
		while first > 0 and text:sub(first, first):match("[%w_]") do first -= 1 end
		while last < #text and text:sub(last + 1, last + 1):match("[%w_]") do last += 1 end
		self.Anchor, self.Caret = first, last
		self.LastEditClick = nil
	else
		self.Anchor, self.Caret = index, index
		self.LastEditClick, self.LastEditX = now, mx
		self.Dragging = self.EditDragger
	end
	self.CaretMoved = now
	self.Typing:Paint()
end

function Library:StartTyping(Target)
	if not Target.InPopup then self:ClosePopup() end
	self:StopTyping(false)
	self:EnsureEditDraws()
	self.Typing = Target
	self.TypingText = tostring(Target.EditText and Target:EditText() or Target.Value or "")
	self.Caret = #self.TypingText
	self.Anchor = nil
	self.EditScroll = 0
	self.EditX = nil
	self.CaretMoved = tick()
	self.TypeHeld = {}
	self.RepeatAt = {}
	for _, code in ipairs(scanCodes) do self.TypeHeld[code] = keyDown(code) end
	Target:Paint()
end

function Library:StopTyping(cancel)
	local Target = self.Typing
	if not Target then return end
	self.Typing = nil
	self:HideEdit()
	if self.Dragging == self.EditDragger then self.Dragging = nil end
	if Target.Commit then
		Target:Commit(not cancel and (self.TypingText or "") or nil)
		return
	end
	if cancel then
		Target:Paint()
		return
	end
	local text = self.TypingText or ""
	if Target.Numeric and not tonumber(text) then text = Target.Value end
	Target.Value = text
	Target:Paint()
	fire(Target, text)
end

local function typedCharacter(code, shift)
	if code >= 0x41 and code <= 0x5A then
		local character = string.char(code)
		return shift and character or character:lower()
	end
	if code >= 0x30 and code <= 0x39 then return shift and shiftDigits[code] or string.char(code) end
	if code >= 0x60 and code <= 0x69 then return tostring(code - 0x60) end
	if code == 0x20 then return " " end
	if code == 0x6E then return "." end
	local Pair = punctuation[code]
	if Pair then return shift and Pair[2] or Pair[1] end
	return nil
end

local function allowed(Target, character)
	if Target.Filter and not character:match(Target.Filter) then return false end
	if Target.Numeric and not character:match("[%d%.%-]") then return false end
	return true
end

local function insertText(Target, text)
	local L = Library
	local first, last = L:Selection()
	local clean = ""
	for character in text:gmatch(".") do
		if allowed(Target, character) then clean ..= character end
	end
	local current = L.TypingText:sub(1, first) .. L.TypingText:sub(last + 1)
	local room = (Target.MaxLength or 64) - #current
	clean = clean:sub(1, math.max(room, 0))
	L.TypingText = current:sub(1, first) .. clean .. current:sub(first + 1)
	L.Caret = first + #clean
	L.Anchor = nil
end

local requestFile = "VantaUI/paste_request.txt"
local responseFile = "VantaUI/paste_response.txt"

local function cleanPaste(text)
	text = tostring(text or ""):gsub("[\r\n\t]", " ")
	return (text:gsub("[^\32-\126]", ""))
end

local function pasteInto(Target, text)
	insertText(Target, text)
	Library.CaretMoved = tick()
	Target:Paint()
end

function Library:RequestPaste(Target)
	local token = tostring(math.floor(tick() * 1000)) .. tostring(math.random(1000, 9999))
	local ok = pcall(function()
		if not isfolder("VantaUI") then makefolder("VantaUI") end
		if isfile(responseFile) then delfile(responseFile) end
		writefile(requestFile, token)
	end)
	if not ok then
		if self.Clipboard then pasteInto(Target, self.Clipboard) end
		return
	end
	self.PasteWait = {Target = Target, Token = token, Deadline = tick() + 0.6}
end

local function pastePoll()
	local Wait = Library.PasteWait
	if not Wait then return end
	if Library.Typing ~= Wait.Target then
		Library.PasteWait = nil
		pcall(delfile, requestFile)
		return
	end
	local ok, content = pcall(function()
		return isfile(responseFile) and readfile(responseFile) or nil
	end)
	if ok and content then
		local token, text = content:match("^([^\n]*)\n(.*)$")
		if token and token:gsub("%s", "") == Wait.Token then
			pcall(delfile, responseFile)
			Library.PasteWait = nil
			pasteInto(Wait.Target, cleanPaste(text))
			return
		end
	end
	if tick() < Wait.Deadline then return end
	Library.PasteWait = nil
	pcall(delfile, requestFile)
	if Library.Clipboard then pasteInto(Wait.Target, Library.Clipboard) end
end

local function wordJump(text, index, direction)
	if direction < 0 then
		while index > 0 and not text:sub(index, index):match("[%w_]") do index -= 1 end
		while index > 0 and text:sub(index, index):match("[%w_]") do index -= 1 end
	else
		while index < #text and not text:sub(index + 1, index + 1):match("[%w_]") do index += 1 end
		while index < #text and text:sub(index + 1, index + 1):match("[%w_]") do index += 1 end
	end
	return index
end

local function moveCaret(index, shift)
	local L = Library
	index = math.clamp(index, 0, #L.TypingText)
	if shift then
		L.Anchor = L.Anchor or L.Caret
	else
		L.Anchor = nil
	end
	L.Caret = index
end

local repeatable = {[0x08] = true, [0x2E] = true, [0x25] = true, [0x27] = true}
for code = 0x30, 0x39 do repeatable[code] = true end
for code = 0x41, 0x5A do repeatable[code] = true end
repeatable[0x20] = true

local function editKey(Target, code, shift, ctrl)
	local L = Library
	local text = L.TypingText
	local first, last, has = L:Selection()
	if code == 0x0D then L:StopTyping(false) return false end
	if code == 0x1B then L:StopTyping(true) return false end
	if ctrl then
		if code == 0x41 then
			L.Anchor, L.Caret = 0, #text
		elseif (code == 0x43 or code == 0x58) and has then
			L.Clipboard = text:sub(first + 1, last)
			pcall(setclipboard, L.Clipboard)
			if code == 0x58 then insertText(Target, "") end
		elseif code == 0x56 then
			L:RequestPaste(Target)
		elseif code == 0x25 then
			moveCaret(wordJump(text, L.Caret, -1), shift)
		elseif code == 0x27 then
			moveCaret(wordJump(text, L.Caret, 1), shift)
		elseif code == 0x08 then
			if has then insertText(Target, "") else L.Anchor = wordJump(text, L.Caret, -1) insertText(Target, "") end
		end
	elseif code == 0x25 then
		if has and not shift then moveCaret(first, false) else moveCaret(L.Caret - 1, shift) end
	elseif code == 0x27 then
		if has and not shift then moveCaret(last, false) else moveCaret(L.Caret + 1, shift) end
	elseif code == 0x24 then
		moveCaret(0, shift)
	elseif code == 0x23 then
		moveCaret(#text, shift)
	elseif code == 0x08 then
		if not has then L.Anchor = math.max(L.Caret - 1, 0) end
		insertText(Target, "")
	elseif code == 0x2E then
		if not has then L.Anchor = math.min(L.Caret + 1, #text) end
		insertText(Target, "")
	else
		local character = typedCharacter(code, shift)
		if not character then return true end
		insertText(Target, character)
	end
	L.CaretMoved = tick()
	Target:Paint()
	return true
end

local function typingStep()
	local Target = Library.Typing
	local shift = keyDown(0xA0) or keyDown(0xA1)
	local ctrl = keyDown(0xA2) or keyDown(0xA3)
	local now = tick()
	for _, code in ipairs(scanCodes) do
		local down = keyDown(code)
		local was = Library.TypeHeld[code]
		Library.TypeHeld[code] = down
		local press = false
		if down and not was then
			press = true
			Library.RepeatAt[code] = now + 0.42
		elseif down and repeatable[code] and now >= (Library.RepeatAt[code] or math.huge) then
			press = true
			Library.RepeatAt[code] = now + 0.035
		end
		if press and not editKey(Target, code, shift, ctrl) then return end
		if Library.Typing ~= Target then return end
	end
end

local function bindingStep()
	for _, code in ipairs(scanCodes) do
		local down = keyDown(code)
		local was = Library.BindHeld[code]
		Library.BindHeld[code] = down
		if down and not was then
			Library:FinishBinding(code)
			return
		end
	end
end

Library.ChatCursor = 0x0CE8

function Library.MemoryAccess(recheck)
	if Library.MemoryAllowed ~= nil and not recheck then return Library.MemoryAllowed end
	local allowed = false
	if type(getbase) == "function" and type(memory_read) == "function" then
		local okBase, base = pcall(getbase)
		if okBase and type(base) == "number" and base > 0 then
			local okRead, header = pcall(memory_read, "byte", base)
			allowed = okRead and header == 0x4D
		end
	end
	Library.MemoryAllowed = allowed
	return allowed
end

Library.FocusMap = 0x02A0
Library.FocusRecord = 0x48

local function focusedAddress()
	if not Library.MemoryAccess() then return false end
	local input = Library.InputAddress
	if not input then
		local now = tick()
		if now < (Library.InputRetry or 0) then return false end
		Library.InputRetry = now + 5
		for _, Service in ipairs(game:GetChildren()) do
			if Service.ClassName == "UserInputService" then input = tonumber(Service.Address) break end
		end
		Library.InputAddress = input
		if not input then return false end
	end
	local ok, valid, address = pcall(function()
		local head = memory_read("uintptr_t", input + Library.FocusMap)
		if not head or head == 0 or memory_read("byte", head + 0x19) ~= 1 then return false end
		local node = memory_read("uintptr_t", head)
		if not node or node == 0 or node == head then return true, 0 end
		if memory_read("byte", node + 0x19) ~= 0 or memory_read("uintptr_t", node + 0x30) ~= 0 then return false end
		local record = memory_read("uintptr_t", node + 0x40)
		if not record or record == 0 then return true, 0 end
		return true, memory_read("uintptr_t", record + Library.FocusRecord) or 0
	end)
	if not (ok and valid) then Library.InputAddress = nil return false end
	return true, address
end

function Library.FocusedTextBox()
	local valid, address = focusedAddress()
	if not valid or address == 0 then return nil end
	return address
end

function Library.GameTyping()
	local now = tick()
	if now < (Library.ChatAt or 0) then return Library.ChatTyping == true end
	Library.ChatAt = now + 0.05
	Library.ChatTyping = false
	if not Library.MemoryAccess() then return false end
	local valid, address = focusedAddress()
	if valid then
		Library.ChatTyping = address ~= 0
		return Library.ChatTyping
	end
	local Box = Library.ChatBox
	local ok, alive = pcall(function() return Box and Box.Parent ~= nil end)
	if not (ok and alive) then
		Box = nil
		local Chat = game:GetService("CoreGui"):FindFirstChild("ExperienceChat")
		for _, Item in ipairs(Chat and Chat:GetDescendants() or {}) do
			if Item.ClassName == "TextBox" then Box = Item end
		end
		Library.ChatBox = Box
	end
	if not Box then return false end
	local okAddress, address = pcall(function() return tonumber(Box.Address) end)
	if not (okAddress and address) then return false end
	local okCursor, cursor = pcall(memory_read, "int", address + Library.ChatCursor)
	if not okCursor then return false end
	Library.ChatTyping = type(cursor) == "number" and cursor >= 0
	return Library.ChatTyping
end

local function keybindStep()
	local blocked
	for _, Element in ipairs(Library.Keybinds) do
		if Element.Key then
			local down = keyDown(Element.Key)
			if down ~= (Element.Held == true) then
				Element.Held = down
				if down and blocked == nil then blocked = Library.Typing ~= nil or Library.GameTyping() end
				if not (blocked and down) then Element:Pressed(down) end
			end
		end
	end
end

function Window:HoverTarget(mx, my)
	local x, y = self.Position.X, self.Position.Y
	local C = self.Chrome
	if inside(mx, my, C.Close.Position.X, C.Close.Position.Y, 24, 22) then return "Close" end
	if inside(mx, my, C.Minimize.Position.X, C.Minimize.Position.Y, 24, 22) then return "Minimize" end
	if self.MenuKey and inside(mx, my, C.MenuChip.Position.X, C.MenuChip.Position.Y, C.MenuChip.Size.X, 20) then return "Menu" end
	if self.Resizable and not self.Minimized and inside(mx, my, x + self.Size.X - 22, y + self.Size.Y - 22, 22, 22) then return "Resize" end
	if inside(mx, my, x, y, self.Size.X, topbarHeight) then return "Topbar" end
	if self.Minimized then return nil end
	for _, TabItem in ipairs(self.Tabs) do
		if self.SidebarWidth > 0 and TabItem.Top and inside(mx, my, x + 8, TabItem.Top, self.SidebarWidth - 16, 28) then return TabItem end
	end
	if self.ActiveTab then
		for _, Bar in pairs(self.ActiveTab.Bars) do
			if Bar.Shown and inside(mx, my, Bar.X - 3, Bar.Y, 10, Bar.Height) then return Bar end
		end
		for _, S in ipairs(self.ActiveTab.Sections) do
			for _, Element in ipairs(S.Elements) do
				if Element.Shown and Element.Click and inside(mx, my, Element.X, Element.Y, Element.Width, Element.Height) then return Element end
			end
		end
		local Bar = self:ColumnAt(mx, my)
		if Bar and Bar.Shown then return Bar.Pan end
	end
	return nil
end

function Window:ColumnAt(mx, my)
	local TabItem = self.ActiveTab
	if not (self.Visible and TabItem and self.ContentX) or self.Minimized then return nil end
	if my < self.ContentY or my > self.ContentBottom then return nil end
	if TabItem.Unified then
		if mx >= self.ContentX and mx <= self.ContentX + self.ColumnWidth * 2 + gap + 8 then return TabItem.Bars.Left end
		return nil
	end
	if mx >= self.ContentX and mx <= self.ContentX + self.ColumnWidth + 8 then return TabItem.Bars.Left end
	local rightX = self.ContentX + self.ColumnWidth + gap
	if mx >= rightX and mx <= rightX + self.ColumnWidth + 8 then return TabItem.Bars.Right end
	return nil
end

function Window:Step(mx, my, down, clicked)
	if not self.Visible then return end
	local P = Library.Popup
	if Library.Dragging == self then
		if down then
			if self.DragMode == "Resize" then
				local width = math.max(mx + self.DragOffset.X - self.Position.X, self.MinSize.X)
				local height = math.max(my + self.DragOffset.Y - self.Position.Y, self.MinSize.Y)
				self.Size = Vector2.new(math.floor(width), math.floor(height))
			else
				self.Position = Vector2.new(mx - self.DragOffset.X, my - self.DragOffset.Y)
			end
			self:Refresh()
		else
			Library.Dragging = nil
			self:Refresh()
		end
		return
	end
	if Library.Dragging then
		if getmetatable(Library.Dragging) == Window then return end
		if down then
			Library.Dragging:Drag(mx, my)
		else
			local Released = Library.Dragging
			Library.Dragging = nil
			if Released.Release then Released:Release(mx, my) end
			if Released.Paint then Released:Paint() end
		end
		return
	end

	local target = self:HoverTarget(mx, my)
	if P and P:Hit(mx, my) then target = nil end
	if target ~= self.Hovered then
		local previous = self.Hovered
		self.Hovered = target
		Library.PulseStart = tick()
		if isElement(previous) then
			previous.Hovered = false
			if previous.Paint then previous:Paint() end
		end
		if isElement(target) then
			target.Hovered = true
			if target.Paint then target:Paint() end
		end
		if (previous ~= nil and not isElement(previous)) or (target ~= nil and not isElement(target)) then self:Refresh() end
	end
	if P and P.Hover then P:Hover(mx, my) end

	if not clicked then return end
	if P then
		if P:Hit(mx, my) then
			P:Click(mx, my)
			return
		end
		Library:ClosePopup()
		if target == P.Owner then return end
	end
	if Library.Typing and target ~= Library.Typing then Library:StopTyping(false) end
	if target == "Close" then
		self:SetVisible(false)
		if self.OnClose then pcall(self.OnClose) end
		if self.MenuKey then self:HideChildren() end
		if self.MenuKey then pcall(notify, self.Title, "Menu hidden. Press " .. Library.KeyName(self.MenuKey) .. " to open it.", 4) end
	elseif target == "Minimize" then
		self:SetMinimized(not self.Minimized)
	elseif target == "Menu" then
		if Library.Binding == self then
			Library.Binding = nil
			self:Refresh()
		else
			Library:StartBinding(self)
		end
	elseif target == "Resize" then
		Library:ClosePopup()
		Library.Dragging = self
		self.DragMode = "Resize"
		self.DragOffset = Vector2.new(self.Position.X + self.Size.X - mx, self.Position.Y + self.Size.Y - my)
	elseif target == "Topbar" then
		Library.Dragging = self
		self.DragMode = "Move"
		self.DragOffset = Vector2.new(mx - self.Position.X, my - self.Position.Y)
	elseif type(target) == "table" and target.IsPan then
		Library:ClosePopup()
		target.StartY = my
		target.StartScroll = target.Bar.Tab.Scroll[target.Bar.Side]
		Library.Dragging = target
	elseif type(target) == "table" and target.IsBar then
		Library:ClosePopup()
		if my >= target.ThumbY and my <= target.ThumbY + target.ThumbHeight then
			target.GrabOffset = my - target.ThumbY
		else
			target.GrabOffset = target.ThumbHeight / 2
		end
		Library.Dragging = target
		target:Drag(mx, my)
	elseif type(target) == "table" and target.Sections then
		self:SelectTab(target)
	elseif isElement(target) then
		target:Click(mx, my)
	end
end

function Window:Animate()
	local target = self.Hovered
	if not self.Visible then return end
	local TabItem = self.ActiveTab
	if TabItem then
		for _, Bar in pairs(TabItem.Bars) do
			if Bar.GlowStart then
				local normal = (Library.Dragging == Bar or self.Hovered == Bar) and Theme.Accent or Theme.ElementHover
				local color = Bar.Shown and glowColor(Bar.GlowStart, normal)
				Bar.Thumb.Color = color or normal
				if not color then Bar.GlowStart = nil end
			end
		end
	end
	local Popup = Library.Popup
	if Popup and Popup.Pulse and Popup.Owner and Popup.Owner.Section and Popup.Owner.Section.Tab.Window == self then Popup:Pulse() end
	if target == nil then return end
	if isElement(target) then
		if target.Pulse and target.Shown then target:Pulse() end
		return
	end
	local C = self.Chrome
	if target == "Close" then
		C.Close.Color = pulse(Theme.CloseBright, Theme.CloseDark)
	elseif target == "Minimize" then
		C.Minimize.Color = pulse(Theme.PulseBright, Theme.PulseDark)
	elseif target == "Menu" then
		C.MenuChip.Color = pulse(Theme.PulseBright, Theme.PulseDark)
	elseif type(target) == "table" and target.Sections and target ~= self.ActiveTab then
		target.Back.Color = pulse(Theme.PulseBright, Theme.PulseDark)
	end
end

local function updateBlocking()
	local block = Library.Typing ~= nil or Library.Binding ~= nil
	if not block and not Library.Unloaded and Library.BlockMode == "Screen" then
		for _, W in ipairs(Library.Windows) do
			if W.Visible and not W.Minimized and W.BlockInput then block = true end
		end
	end
	if Library.Unloaded then block = false end
	if block == Library.Blocked then return end
	Library.Blocked = block
	pcall(setrobloxinput, not block)
	task.spawn(function()
		task.wait(0.1)
		pcall(mouse1click)
	end)
end

function Library:SetBlockMode(mode)
	self.BlockMode = mode == "Screen" and "Screen" or "Typing"
	return self.BlockMode
end

local scrollKeys = {[0x26] = -1, [0x28] = 1, [0x21] = -6, [0x22] = 6}

function Library:ScrollAt(mx, my, steps)
	local Popup = self.Popup
	if Popup and Popup.Scroll and Popup:Hit(mx, my) then
		Popup:Scroll(steps)
		return true
	end
	for _, W in ipairs(self.Windows) do
		local Bar = W:ColumnAt(mx, my)
		if Bar and Bar.Shown then
			Bar:Scroll(steps * 28)
			return true
		end
	end
	return false
end

local function scrollKeysStep(mx, my)
	Library.ScrollHeld = Library.ScrollHeld or {}
	local now = tick()
	for code, steps in pairs(scrollKeys) do
		local down = keyDown(code)
		local nextAt = Library.ScrollHeld[code]
		if not down then
			Library.ScrollHeld[code] = nil
		elseif not nextAt then
			Library.ScrollHeld[code] = now + 0.35
			Library:ScrollAt(mx, my, steps)
		elseif now >= nextAt then
			Library.ScrollHeld[code] = now + 0.05
			Library:ScrollAt(mx, my, steps)
		end
	end
end

local function step()
	if Library.Unloaded then return end
	local active = focused()
	local mx, my = Mouse.X, Mouse.Y
	local down = false
	if active then pcall(function() down = ismouse1pressed() end) end
	local clicked = down and not Library.WasDown
	Library.WasDown = down
	if Library.Dirty then
		Library.Dirty = false
		for _, W in ipairs(Library.Windows) do W:Refresh() end
	end

	if active then
		if Library.Binding then
			bindingStep()
		elseif Library.Typing then
			typingStep()
		else
			for _, W in ipairs(Library.Windows) do
				local menuDown = W.MenuKey ~= nil and keyDown(W.MenuKey)
				if menuDown and not W.MenuHeld and not Library.GameTyping() then
					W:SetVisible(not W.Visible)
					if not W.Visible then W:HideChildren() end
				end
				W.MenuHeld = menuDown
			end
			keybindStep()
			scrollKeysStep(mx, my)
		end
	end

	Library.Mouse = Vector2.new(mx, my)
	local Top
	if not Library.Dragging then
		for _, W in ipairs(Library.Windows) do
			local height = W.Minimized and topbarHeight or W.Size.Y
			if W.Visible and inside(mx, my, W.Position.X, W.Position.Y, W.Size.X, height) and (not Top or W.Layer >= Top.Layer) then Top = W end
		end
	end
	for _, W in ipairs(Library.Windows) do
		if not Top or W == Top then
			W:Step(mx, my, down, clicked)
		else
			W:Step(-100000, -100000, down, false)
		end
	end
	for _, W in ipairs(Library.Windows) do W:Animate() end
	if Library.Typing and Library.Typing.InPopup then Library.Typing:Paint() end
	if Library.PasteWait then pastePoll() end
	updateBlocking()
	for _, W in ipairs(Library.Windows) do
		if W.Visible and W.ActiveTab then
			for _, S in ipairs(W.ActiveTab.Sections) do
				for _, Element in ipairs(S.Elements) do
					if Element.Tick and Element.Shown then Element:Tick() end
				end
			end
		end
	end
end

function Library:Notify(title, text, duration)
	pcall(notify, title, text, duration or 4)
end

function Library:Unload()
	if self.Unloaded then return end
	self.Unloaded = true
	pcall(setrobloxinput, true)
	self.Blocked = false
	for _, Connection in ipairs(self.Connections) do pcall(function() Connection:Disconnect() end) end
	for _, Object in ipairs(self.Drawings) do pcall(function() Object:Remove() end) end
	self.Drawings = {}
	if _G.VantaUI == self then _G.VantaUI = nil end
end

Library.Connections[#Library.Connections + 1] = runs.RenderStepped:Connect(function()
	local ok, err = pcall(step)
	if not ok and not Library.StepError then
		Library.StepError = true
		warn("[VantaUI] " .. tostring(err))
	end
end)

_G.VantaUI = Library
VantaUI = Library
