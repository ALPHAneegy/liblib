--[[
    MUSCLE LEGENDS UI  |  v1.0.0
    Libreria visual independiente de un solo archivo para Roblox/Luau.
    Incluye ventanas movibles, tabs, secciones, controles, temas y notificaciones.

    Carga local:
        ModuleScript: local MLUI = require(ruta.MuscleLegendsUI)
        Executor:     local MLUI = loadfile("MuscleLegendsUI.lua")()
        Alternativa:  local MLUI = loadstring(readfile("MuscleLegendsUI.lua"))()

    Ejemplo:
        local window = MLUI:CreateWindow({ Title = "MUSCLE LEGENDS" })
        local tab = window:AddTab("Training")
        local section = tab:AddSection("Settings")
        section:AddToggle("Enabled", { Default = false, Callback = function(value) end })
        section:AddSlider("Intensity", { Min = 0, Max = 100, Default = 50 })
        section:AddDropdown("Mode", { Options = { "Power", "Speed" }, Default = "Power" })
        window:SetKeybind(Enum.KeyCode.RightControl)

    Los callbacks son puntos de extensión de la interfaz; este archivo solo crea UI.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local floor, min, max = math.floor, math.min, math.max

local function clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

local function copyTable(source)
	local result = {}
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end

local function normalizeOptions(nameOrOptions, extra)
	if type(nameOrOptions) == "string" then
		local options = { Name = nameOrOptions }
		if type(extra) == "table" then
			for key, value in pairs(extra) do
				options[key] = value
			end
			options.Name = nameOrOptions
		elseif type(extra) == "function" then
			options.Callback = extra
		end
		return options
	elseif type(nameOrOptions) == "table" then
		local options = copyTable(nameOrOptions)
		if type(extra) == "function" then
			options.Callback = options.Callback or extra
		end
		return options
	elseif type(extra) == "table" then
		return copyTable(extra)
	elseif type(extra) == "function" then
		return { Callback = extra }
	end
	return {}
end

local Config = {
	Accent = Color3.fromRGB(174, 255, 67),
	Accent2 = Color3.fromRGB(81, 225, 131),
	Background = Color3.fromRGB(8, 12, 13),
	Panel = Color3.fromRGB(14, 20, 21),
	Surface = Color3.fromRGB(24, 32, 32),
	Stroke = Color3.fromRGB(55, 72, 67),
	Text = Color3.fromRGB(239, 246, 232),
	Muted = Color3.fromRGB(139, 157, 143),
	Font = Enum.Font.GothamMedium,
	MonoFont = Enum.Font.Code,
	TextSize = 13,
	Radius = 8,
	Animation = 0.16,
}

local Themes = {
	Power = {
		Accent = Color3.fromRGB(174, 255, 67),
		Accent2 = Color3.fromRGB(81, 225, 131),
		Background = Color3.fromRGB(8, 12, 13),
		Panel = Color3.fromRGB(14, 20, 21),
		Surface = Color3.fromRGB(24, 32, 32),
		Stroke = Color3.fromRGB(55, 72, 67),
	},
	Inferno = {
		Accent = Color3.fromRGB(255, 151, 54),
		Accent2 = Color3.fromRGB(255, 75, 70),
		Background = Color3.fromRGB(15, 10, 10),
		Panel = Color3.fromRGB(24, 15, 14),
		Surface = Color3.fromRGB(39, 23, 20),
		Stroke = Color3.fromRGB(91, 52, 38),
	},
	Frost = {
		Accent = Color3.fromRGB(85, 224, 255),
		Accent2 = Color3.fromRGB(123, 151, 255),
		Background = Color3.fromRGB(8, 11, 17),
		Panel = Color3.fromRGB(14, 19, 28),
		Surface = Color3.fromRGB(23, 31, 44),
		Stroke = Color3.fromRGB(49, 68, 91),
	},
	Violet = {
		Accent = Color3.fromRGB(196, 125, 255),
		Accent2 = Color3.fromRGB(105, 133, 255),
		Background = Color3.fromRGB(11, 9, 17),
		Panel = Color3.fromRGB(19, 15, 28),
		Surface = Color3.fromRGB(30, 24, 43),
		Stroke = Color3.fromRGB(68, 53, 94),
	},
}

local registeredColors = {
	Accent = {}, Accent2 = {}, Background = {}, Panel = {}, Surface = {},
	Stroke = {}, Text = {}, Muted = {}, Gradient = {},
}

local function register(object, role)
	if role and registeredColors[role] then
		table.insert(registeredColors[role], object)
	end
	return object
end

local function make(className, properties, parent, role)
	local object = Instance.new(className)
	if properties then
		for key, value in pairs(properties) do
			local ok = pcall(function()
				object[key] = value
			end)
			if not ok then
				-- Ignora propiedades opcionales no soportadas por ciertas versiones.
			end
		end
	end
	if role then
		register(object, role)
	end
	if parent then
		object.Parent = parent
	end
	return object
end

local function round(object, radius)
	return make("UICorner", {
		CornerRadius = UDim.new(0, radius or Config.Radius),
	}, object)
end

local function outline(object, color, transparency)
	local border = make("UIStroke", {
		Color = color or Config.Stroke,
		Thickness = 1,
		Transparency = transparency == nil and 0.25 or transparency,
	}, object)
	register(border, "Stroke")
	return border
end

local function gradient(object)
	local item = make("UIGradient", {
		Color = ColorSequence.new(Config.Accent, Config.Accent2),
		Rotation = 0,
	}, object)
	register(item, "Gradient")
	return item
end

local function textLabel(parent, properties, role)
	properties = properties or {}
	properties.BackgroundTransparency = 1
	properties.Font = properties.Font or Config.Font
	properties.TextSize = properties.TextSize or Config.TextSize
	properties.TextColor3 = properties.TextColor3 or Config.Text
	if properties.TextXAlignment == nil then
		properties.TextXAlignment = Enum.TextXAlignment.Left
	end
	local object = make("TextLabel", properties, parent)
	register(object, role or "Text")
	return object
end

local function textButton(parent, properties)
	properties = properties or {}
	properties.AutoButtonColor = false
	properties.BorderSizePixel = 0
	properties.Font = properties.Font or Config.Font
	properties.TextSize = properties.TextSize or Config.TextSize
	properties.TextColor3 = properties.TextColor3 or Config.Text
	properties.BackgroundColor3 = properties.BackgroundColor3 or Config.Surface
	local object = make("TextButton", properties, parent)
	register(object, "Surface")
	register(object, "Text")
	return object
end

local function tween(object, properties, duration)
	local animation = TweenService:Create(
		object,
		TweenInfo.new(duration or Config.Animation, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		properties
	)
	animation:Play()
	return animation
end

local function formatNumber(value)
	if value % 1 == 0 then
		return tostring(value)
	end
	local text = string.format("%.2f", value)
	text = text:gsub("0+$", "")
	return text:gsub("%.$", "")
end

local function resolveGuiParent()
	if LocalPlayer then
		local ok, playerGui = pcall(function()
			return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 8)
		end)
		if ok and playerGui then
			return playerGui
		end
	end
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok then
		return coreGui
	end
	return nil
end

local guiParent = resolveGuiParent()
assert(guiParent, "MuscleLegendsUI necesita PlayerGui o CoreGui")

local oldGui = guiParent:FindFirstChild("MuscleLegendsUI")
if oldGui then
	oldGui:Destroy()
end

local screen = make("ScreenGui", {
	Name = "MuscleLegendsUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 700,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local notificationHost = make("Frame", {
	Name = "Notifications",
	Size = UDim2.new(0, 310, 1, -30),
	Position = UDim2.new(1, -18, 0, 15),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	ZIndex = 80,
}, screen)
make("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
}, notificationHost)

local lib = {
	Version = "1.0.0",
	Build = "muscle-legends-ui-1.0.0",
	Config = Config,
	Themes = Themes,
	Windows = {},
}
lib.__index = lib

local function applyThemeRole(object, role)
	if not object or not object.Parent then
		return
	end
	if role == "Gradient" and object:IsA("UIGradient") then
		object.Color = ColorSequence.new(Config.Accent, Config.Accent2)
		return
	end
	local color = Config[role]
	if not color then
		return
	end
	if object:IsA("UIStroke") then
		object.Color = color
	elseif object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
		if role == "Text" or role == "Muted" or role == "Accent" or role == "Accent2" then
			object.TextColor3 = color
		end
	else
		object.BackgroundColor3 = color
	end
end

function lib:Theme(theme)
	if type(theme) == "string" then
		local wanted = string.lower(theme)
		for name, values in pairs(Themes) do
			if string.lower(name) == wanted then
				theme = values
				break
			end
		end
	end
	if type(theme) ~= "table" then
		return false
	end
	for key, value in pairs(theme) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
	for role, objects in pairs(registeredColors) do
		for index = 1, #objects do
			applyThemeRole(objects[index], role)
		end
	end
	return true
end

local function makeControlApi(frame)
	local api = { Frame = frame, _cleanup = {} }

	function api:AddCleanup(callback)
		table.insert(self._cleanup, callback)
	end

	function api:Destroy()
		for index = #self._cleanup, 1, -1 do
			pcall(self._cleanup[index])
		end
		self._cleanup = {}
		if self.Frame and self.Frame.Parent then
			self.Frame:Destroy()
		end
	end

	return api
end

local createControl

local function installControlMethods(target, getSection)
	local kinds = { "Button", "Toggle", "Slider", "Dropdown", "Input", "Label" }
	for index = 1, #kinds do
		local kind = kinds[index]
		target["Add" .. kind] = function(_, nameOrOptions, extra)
			return createControl(kind, getSection(), nameOrOptions, extra)
		end
	end
	return target
end

local function createSection(page, name)
	local sectionFrame = make("Frame", {
		Name = "Section",
		Size = UDim2.new(1, -6, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Config.Panel,
		BorderSizePixel = 0,
		LayoutOrder = page._sectionOrder,
	}, page.Container, "Panel")
	page._sectionOrder = page._sectionOrder + 1
	round(sectionFrame, 7)
	outline(sectionFrame, Config.Stroke, 0.5)

	local heading = textLabel(sectionFrame, {
		Size = UDim2.new(1, -32, 0, 22),
		Position = UDim2.fromOffset(14, 9),
		Text = string.upper(tostring(name or "SECTION")),
		Font = Config.MonoFont,
		TextSize = 11,
		TextColor3 = Config.Accent,
	}, "Accent")
	local marker = make("Frame", {
		Size = UDim2.fromOffset(4, 14),
		Position = UDim2.fromOffset(8, 13),
		BackgroundColor3 = Config.Accent,
		BorderSizePixel = 0,
	}, sectionFrame, "Accent")
	round(marker, 2)

	local body = make("Frame", {
		Name = "Controls",
		Size = UDim2.new(1, -20, 0, 0),
		Position = UDim2.fromOffset(10, 36),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, sectionFrame)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 7),
	}, body)
	make("UIPadding", {
		PaddingBottom = UDim.new(0, 11),
	}, body)

	local section = {
		Frame = sectionFrame,
		Heading = heading,
		Body = body,
		Window = page.Window,
		_order = 0,
	}
	installControlMethods(section, function()
		return section
	end)
	return section
end

local function makeRow(section, height)
	section._order = section._order + 1
	return make("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = section._order,
	}, section.Body)
end

local function createButton(section, options)
	local row = makeRow(section, 36)
	local settings = normalizeOptions(options)
	local control = textButton(row, {
		Size = UDim2.fromScale(1, 1),
		Text = tostring(settings.Name or "Action"),
		BackgroundColor3 = Config.Surface,
		TextColor3 = Config.Text,
	})
	round(control, 6)
	outline(control, Config.Stroke, 0.45)
	local api = makeControlApi(row)
	control.MouseEnter:Connect(function()
		tween(control, { BackgroundColor3 = Config.Accent, TextColor3 = Config.Background })
	end)
	control.MouseLeave:Connect(function()
		tween(control, { BackgroundColor3 = Config.Surface, TextColor3 = Config.Text })
	end)
	control.Activated:Connect(function()
		if settings.Callback then
			settings.Callback(api)
		end
	end)
	function api:SetText(text)
		control.Text = tostring(text or "")
	end
	return api
end

local function createToggle(section, options)
	local row = makeRow(section, 36)
	local settings = normalizeOptions(options)
	textLabel(row, {
		Size = UDim2.new(1, -66, 1, 0),
		Text = tostring(settings.Name or "Toggle"),
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "Text")

	local track = textButton(row, {
		Size = UDim2.fromOffset(44, 22),
		Position = UDim2.new(1, -44, 0.5, -11),
		Text = "",
		BackgroundColor3 = Config.Surface,
	})
	round(track, 11)
	outline(track, Config.Stroke, 0.5)
	local knob = make("Frame", {
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 11, 0.5, 0),
		BackgroundColor3 = Config.Muted,
		BorderSizePixel = 0,
	}, track, "Muted")
	round(knob, 8)

	local value = settings.Default and true or false
	local api = makeControlApi(row)
	local function render(animated)
		local position = value and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
		local color = value and Config.Accent or Config.Surface
		local knobColor = value and Color3.fromRGB(255, 255, 255) or Config.Muted
		if animated then
			tween(track, { BackgroundColor3 = color })
			tween(knob, { Position = position, BackgroundColor3 = knobColor })
		else
			track.BackgroundColor3 = color
			knob.Position = position
			knob.BackgroundColor3 = knobColor
		end
	end
	local function setValue(newValue, callCallback)
		value = newValue and true or false
		render(true)
		if callCallback and settings.Callback then
			settings.Callback(value)
		end
	end
	track.Activated:Connect(function()
		setValue(not value, true)
	end)
	render(false)
	function api:SetValue(newValue)
		setValue(newValue, false)
	end
	function api:GetValue()
		return value
	end
	function api:Toggle()
		setValue(not value, true)
	end
	return api
end

local function createSlider(section, options)
	local settings = normalizeOptions(options)
	local minimum = tonumber(settings.Min) or 0
	local maximum = tonumber(settings.Max) or 100
	if maximum <= minimum then
		maximum = minimum + 1
	end
	local step = tonumber(settings.Step) or 1
	local suffix = tostring(settings.Suffix or "")
	local value = clamp(tonumber(settings.Default) or minimum, minimum, maximum)
	local row = makeRow(section, 58)
	local title = textLabel(row, {
		Size = UDim2.new(1, -84, 0, 19),
		Text = tostring(settings.Name or "Slider"),
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "Text")
	local valueLabel = textLabel(row, {
		Size = UDim2.new(0, 78, 0, 19),
		Position = UDim2.new(1, -78, 0, 0),
		Text = "",
		Font = Config.MonoFont,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, "Accent")
	local track = make("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.fromOffset(0, 36),
		BackgroundColor3 = Config.Surface,
		BorderSizePixel = 0,
		Active = true,
	}, row, "Surface")
	round(track, 3)
	local fill = make("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Config.Accent,
		BorderSizePixel = 0,
	}, track, "Accent")
	round(fill, 3)
	gradient(fill)
	local knob = make("Frame", {
		Size = UDim2.fromOffset(14, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(250, 255, 247),
		BorderSizePixel = 0,
		ZIndex = 3,
	}, track)
	round(knob, 7)
	outline(knob, Config.Accent, 0.1)
	local hitbox = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 27),
		BackgroundTransparency = 1,
		Text = "",
		Active = true,
		ZIndex = 4,
	}, row)

	local api = makeControlApi(row)
	local function render(animated)
		local ratio = clamp((value - minimum) / (maximum - minimum), 0, 1)
		valueLabel.Text = formatNumber(value) .. suffix
		local fillSize = UDim2.new(ratio, 0, 1, 0)
		local knobPosition = UDim2.new(ratio, 0, 0.5, 0)
		if animated then
			tween(fill, { Size = fillSize, BackgroundColor3 = Config.Accent }, 0.1)
			tween(knob, { Position = knobPosition }, 0.1)
		else
			fill.Size = fillSize
			knob.Position = knobPosition
		end
	end
	local function setValue(newValue, callCallback)
		newValue = clamp(tonumber(newValue) or minimum, minimum, maximum)
		if step > 0 then
			newValue = minimum + floor((newValue - minimum) / step + 0.5) * step
			newValue = clamp(newValue, minimum, maximum)
		end
		local changed = value ~= newValue
		value = newValue
		render(true)
		if changed and callCallback and settings.Callback then
			settings.Callback(value)
		end
	end
	local function valueFromX(x)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return value
		end
		local ratio = clamp((x - track.AbsolutePosition.X) / width, 0, 1)
		return minimum + ratio * (maximum - minimum)
	end
	local function pointerX(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			return input.Position.X
		end
		local mousePosition = UserInputService:GetMouseLocation()
		return mousePosition.X
	end
	local function beginDrag(input)
		setValue(valueFromX(pointerX(input)), true)
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		local moveConnection = UserInputService.InputChanged:Connect(function(move)
			if (isTouch and move.UserInputType == Enum.UserInputType.Touch)
				or (not isTouch and move.UserInputType == Enum.UserInputType.MouseMovement) then
				setValue(valueFromX(pointerX(move)), true)
			end
		end)
		local endConnection = UserInputService.InputEnded:Connect(function(ended)
			if (isTouch and ended.UserInputType == Enum.UserInputType.Touch)
				or (not isTouch and ended.UserInputType == Enum.UserInputType.MouseButton1) then
				moveConnection:Disconnect()
				endConnection:Disconnect()
			end
		end)
		api:AddCleanup(function()
			moveConnection:Disconnect()
			endConnection:Disconnect()
		end)
	end
	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)
	render(false)
	function api:SetValue(newValue)
		setValue(newValue, false)
	end
	function api:GetValue()
		return value
	end
	api.Label = title
	return api
end

local function createDropdown(section, options)
	local settings = normalizeOptions(options)
	local choices = settings.Options or { "Option 1", "Option 2" }
	local selected = settings.Default or choices[1]
	local row = makeRow(section, 42)
	local control = textButton(row, {
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
		BackgroundColor3 = Config.Surface,
	})
	round(control, 6)
	outline(control, Config.Stroke, 0.45)
	textLabel(control, {
		Size = UDim2.new(0.48, -10, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Text = tostring(settings.Name or "Dropdown"),
		TextColor3 = Config.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "Muted")
	local valueLabel = textLabel(control, {
		Size = UDim2.new(0.48, -34, 1, 0),
		Position = UDim2.new(0.52, 0, 0, 0),
		Text = tostring(selected or "Choose..."),
		TextColor3 = Config.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = Config.MonoFont,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "Accent")
	local arrow = textLabel(control, {
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(1, -25, 0.5, -9),
		Text = "+",
		TextColor3 = Config.Accent,
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Config.MonoFont,
		TextSize = 16,
	}, "Accent")

	local maxVisible = min(#choices, 5)
	local menuHeight = maxVisible * 27 + 4
	local menu = make("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, menuHeight),
		Position = UDim2.fromOffset(0, 40),
		BackgroundColor3 = Config.Surface,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Config.Accent,
		CanvasSize = UDim2.new(0, 0, 0, #choices * 27),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 10,
	}, row, "Surface")
	round(menu, 6)
	outline(menu, Config.Stroke, 0.25)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 1),
	}, menu)
	local api = makeControlApi(row)
	local isOpen = false
	local optionButtons = {}
	local function closeMenu()
		if not isOpen then
			return
		end
		isOpen = false
		menu.Visible = false
		row.Size = UDim2.new(1, 0, 0, 42)
		arrow.Text = "+"
	end
	local function setValue(newValue, callCallback)
		selected = newValue
		valueLabel.Text = tostring(newValue or "")
		for index = 1, #optionButtons do
			local option = optionButtons[index]
			option.TextColor3 = tostring(choices[index]) == tostring(selected) and Config.Accent or Config.Text
		end
		if callCallback and settings.Callback then
			settings.Callback(selected)
		end
	end
	local function refresh()
		for index = #optionButtons, 1, -1 do
			optionButtons[index]:Destroy()
			optionButtons[index] = nil
		end
		for index = 1, #choices do
			local choice = choices[index]
			local option = textButton(menu, {
				Size = UDim2.new(1, -4, 0, 26),
				Position = UDim2.fromOffset(2, 0),
				LayoutOrder = index,
				Text = tostring(choice),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = tostring(choice) == tostring(selected) and Config.Accent or Config.Text,
				BackgroundTransparency = 1,
				ZIndex = 11,
			}, menu)
			make("UIPadding", { PaddingLeft = UDim.new(0, 9) }, option)
			option.Activated:Connect(function()
				setValue(choice, true)
				closeMenu()
			end)
			table.insert(optionButtons, option)
		end
		maxVisible = min(#choices, 5)
		menuHeight = maxVisible * 27 + 4
		menu.Size = UDim2.new(1, 0, 0, menuHeight)
		menu.CanvasSize = UDim2.new(0, 0, 0, #choices * 27)
	end
	control.Activated:Connect(function()
		isOpen = not isOpen
		menu.Visible = isOpen
		row.Size = UDim2.new(1, 0, 0, isOpen and (42 + menuHeight) or 42)
		arrow.Text = isOpen and "-" or "+"
	end)
	refresh()
	function api:SetValue(newValue)
		setValue(newValue, false)
	end
	function api:GetValue()
		return selected
	end
	function api:SetOptions(newChoices)
		choices = newChoices or {}
		if selected == nil or #choices == 0 then
			selected = choices[1]
		end
		refresh()
		if isOpen then
			row.Size = UDim2.new(1, 0, 0, 42 + menuHeight)
		end
	end
	function api:GetOptions()
		return choices
	end
	function api:Close()
		closeMenu()
	end
	local ownerWindow = section.Window
	if ownerWindow then
		table.insert(ownerWindow._dropdowns, api)
		api:AddCleanup(function()
			for index = #ownerWindow._dropdowns, 1, -1 do
				if ownerWindow._dropdowns[index] == api then
					table.remove(ownerWindow._dropdowns, index)
				end
			end
		end)
	end
	api:AddCleanup(closeMenu)
	return api
end

local function createInput(section, options)
	local settings = normalizeOptions(options)
	local row = makeRow(section, 57)
	textLabel(row, {
		Size = UDim2.new(1, 0, 0, 18),
		Text = string.upper(tostring(settings.Name or "INPUT")),
		Font = Config.MonoFont,
		TextSize = 10,
		TextColor3 = Config.Muted,
	}, "Muted")
	local boxFrame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 31),
		Position = UDim2.fromOffset(0, 23),
		BackgroundColor3 = Config.Surface,
		BorderSizePixel = 0,
	}, row, "Surface")
	round(boxFrame, 5)
	local border = outline(boxFrame, Config.Stroke, 0.35)
	local box = make("TextBox", {
		Size = UDim2.new(1, -18, 1, 0),
		Position = UDim2.fromOffset(9, 0),
		BackgroundTransparency = 1,
		Text = tostring(settings.Default or ""),
		PlaceholderText = tostring(settings.Placeholder or "Type here..."),
		PlaceholderColor3 = Config.Muted,
		TextColor3 = Config.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Config.MonoFont,
		TextSize = 12,
		ClearTextOnFocus = false,
		MultiLine = false,
	}, boxFrame, "Text")
	local api = makeControlApi(row)
	box.Focused:Connect(function()
		tween(border, { Color = Config.Accent, Transparency = 0.05 }, 0.1)
	end)
	box.FocusLost:Connect(function(enterPressed)
		tween(border, { Color = Config.Stroke, Transparency = 0.35 }, 0.1)
		if settings.Callback then
			settings.Callback(box.Text, enterPressed)
		end
	end)
	function api:SetValue(value)
		box.Text = tostring(value or "")
	end
	function api:GetValue()
		return box.Text
	end
	function api:Focus()
		box:CaptureFocus()
	end
	return api
end

local function createLabel(section, options)
	local settings = normalizeOptions(options)
	local row = makeRow(section, tonumber(settings.Height) or 28)
	local label = textLabel(row, {
		Size = UDim2.new(1, 0, 1, 0),
		Text = tostring(settings.Text or settings.Name or "Label"),
		TextWrapped = true,
		TextSize = tonumber(settings.TextSize) or 12,
		TextColor3 = settings.Color or Config.Muted,
		Font = Config.MonoFont,
	}, settings.Color and "Custom" or "Muted")
	local api = makeControlApi(row)
	function api:SetValue(value)
		label.Text = tostring(value or "")
	end
	function api:GetValue()
		return label.Text
	end
	return api
end

createControl = function(kind, section, nameOrOptions, extra)
	local settings = normalizeOptions(nameOrOptions, extra)
	if kind == "Button" then
		return createButton(section, settings)
	elseif kind == "Toggle" then
		return createToggle(section, settings)
	elseif kind == "Slider" then
		return createSlider(section, settings)
	elseif kind == "Dropdown" then
		return createDropdown(section, settings)
	elseif kind == "Input" then
		return createInput(section, settings)
	elseif kind == "Label" then
		return createLabel(section, settings)
	end
	return nil
end

local function pointerPosition(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		return input.Position
	end
	return UserInputService:GetMouseLocation()
end

function lib:CreateWindow(nameOrOptions, extra)
	local options = normalizeOptions(nameOrOptions, extra)
	local width = tonumber(options.Width) or 590
	local height = tonumber(options.Height) or 450
	local window = {
		_tabs = {},
		_connections = {},
		_dropdowns = {},
		_activeTab = nil,
		_destroyed = false,
	}
	local count = #self.Windows
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local frame = make("Frame", {
		Name = "MLWindow",
		Size = UDim2.fromOffset(width, height),
		Position = UDim2.fromOffset((viewport.X - width) / 2 + count * 22, (viewport.Y - height) / 2 + count * 18),
		BackgroundColor3 = Config.Panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
	}, screen, "Panel")
	window.Frame = frame
	round(frame, 10)
	outline(frame, Config.Stroke, 0.08)

	local topbar = make("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Config.Background,
		BorderSizePixel = 0,
		Active = true,
	}, frame, "Background")
	local accentLine = make("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = Config.Accent,
		BorderSizePixel = 0,
	}, topbar, "Accent")
gradient(accentLine)

	local logo = make("Frame", {
		Size = UDim2.fromOffset(23, 23),
		Position = UDim2.fromOffset(15, 12),
		BackgroundColor3 = Config.Accent,
		BorderSizePixel = 0,
	}, topbar, "Accent")
	round(logo, 6)
local logoText = textLabel(logo, {
		Size = UDim2.fromScale(1, 1),
		Text = "M",
		Font = Enum.Font.GothamBlack,
		TextSize = 15,
		TextColor3 = Config.Background,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, nil)

	local title = textLabel(topbar, {
		Size = UDim2.new(0.55, -48, 0, 19),
		Position = UDim2.fromOffset(47, 7),
		Text = tostring(options.Title or "MUSCLE LEGENDS"),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "Text")
	local subtitle = textLabel(topbar, {
		Size = UDim2.new(0.55, -48, 0, 14),
		Position = UDim2.fromOffset(47, 26),
		Text = tostring(options.Subtitle or "TRAINING CONSOLE"),
		Font = Config.MonoFont,
		TextSize = 9,
		TextColor3 = Config.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "Muted")

	local closeButton = textButton(topbar, {
		Size = UDim2.fromOffset(28, 26),
		Position = UDim2.new(1, -37, 0.5, -13),
		Text = "×",
		Font = Enum.Font.GothamMedium,
		TextSize = 18,
		BackgroundColor3 = Config.Surface,
		TextColor3 = Config.Muted,
	})
	round(closeButton, 5)
	local hideButton = textButton(topbar, {
		Size = UDim2.fromOffset(48, 26),
		Position = UDim2.new(1, -91, 0.5, -13),
		Text = "HIDE",
		Font = Config.MonoFont,
		TextSize = 10,
		BackgroundColor3 = Config.Surface,
		TextColor3 = Config.Muted,
	})
	round(hideButton, 5)

	local sidebar = make("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 148, 1, -48),
		Position = UDim2.fromOffset(0, 48),
		BackgroundColor3 = Config.Background,
		BorderSizePixel = 0,
	}, frame, "Background")
	local sidebarHeading = textLabel(sidebar, {
		Size = UDim2.new(1, -22, 0, 15),
		Position = UDim2.fromOffset(12, 13),
		Text = "WORKOUT MENU",
		Font = Config.MonoFont,
		TextSize = 9,
		TextColor3 = Config.Muted,
	}, "Muted")
	local tabList = make("ScrollingFrame", {
		Name = "Tabs",
		Size = UDim2.new(1, -12, 1, -64),
		Position = UDim2.fromOffset(6, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Config.Accent,
	}, sidebar)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, 3),
		PaddingRight = UDim.new(0, 3),
		PaddingBottom = UDim.new(0, 6),
	}, tabList)
	make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, tabList)
	local sideFooter = textLabel(sidebar, {
		Size = UDim2.new(1, -22, 0, 16),
		Position = UDim2.new(0, 12, 1, -23),
		Text = "ML  /  UI 1.0",
		Font = Config.MonoFont,
		TextSize = 9,
		TextColor3 = Config.Accent,
	}, "Accent")

	local body = make("Frame", {
		Name = "Pages",
		Size = UDim2.new(1, -148, 1, -48),
		Position = UDim2.new(0, 148, 0, 48),
		BackgroundColor3 = Config.Panel,
		BorderSizePixel = 0,
	}, frame, "Panel")
	window.Content = body

	local dock = textButton(screen, {
		Name = "MLReopen",
		Size = UDim2.fromOffset(52, 52),
		Position = UDim2.new(1, -22, 1, -24),
		AnchorPoint = Vector2.new(1, 1),
		Text = "ML",
		Font = Enum.Font.GothamBlack,
		TextSize = 15,
		TextColor3 = Config.Background,
		BackgroundColor3 = Config.Accent,
		Visible = false,
		ZIndex = 30,
	})
	round(dock, 16)
	outline(dock, Config.Accent2, 0.05)
	gradient(dock)
	window.Dock = dock

	local function closeDropdowns()
		for index = 1, #window._dropdowns do
			local dropdown = window._dropdowns[index]
			if dropdown and dropdown.Close then
				dropdown:Close()
			end
		end
	end

	function window:AddTab(name)
		local page = make("ScrollingFrame", {
			Name = "Page_" .. tostring(name),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Config.Accent,
			Visible = false,
		}, body)
		make("UIPadding", {
			PaddingLeft = UDim.new(0, 13),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 13),
			PaddingBottom = UDim.new(0, 16),
		}, page)
		make("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 11),
		}, page)

		local tabButton = textButton(tabList, {
			Size = UDim2.new(1, 0, 0, 34),
			Text = tostring(name),
			TextColor3 = Config.Muted,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			LayoutOrder = #window._tabs + 1,
		})
		round(tabButton, 5)
		make("UIPadding", {
			PaddingLeft = UDim.new(0, 29),
			PaddingRight = UDim.new(0, 5),
		}, tabButton)
		local indicator = make("Frame", {
			Size = UDim2.fromOffset(3, 18),
			Position = UDim2.fromOffset(8, 8),
			BackgroundColor3 = Config.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, tabButton, "Accent")
		round(indicator, 2)

		local tab = {
			Name = tostring(name),
			Window = window,
			Page = page,
			Container = page,
			Button = tabButton,
			Indicator = indicator,
			_sectionOrder = 0,
		}
		local entry = { Tab = tab }
		table.insert(window._tabs, entry)

		function tab:AddSection(sectionName)
			local section = createSection(tab, sectionName)
			return section
		end

		function tab:_GetDefaultSection()
			if not self._defaultSection then
				self._defaultSection = createSection(self, "CONTROLS")
			end
			return self._defaultSection
		end

		installControlMethods(tab, function()
			return tab:_GetDefaultSection()
		end)

		function tab:Select()
			window:SelectTab(self)
		end

		function tab:SetName(newName)
			self.Name = tostring(newName)
			self.Button.Text = self.Name
		end

		tabButton.Activated:Connect(function()
			window:SelectTab(tab)
		end)

		if not window._activeTab then
			window:SelectTab(tab)
		end
		return tab
	end

	function window:SelectTab(tab)
		closeDropdowns()
		for index = 1, #self._tabs do
			local current = self._tabs[index].Tab
			local active = current == tab
			current.Page.Visible = active
			tween(current.Button, {
				BackgroundTransparency = active and 0 or 1,
				TextColor3 = active and Config.Accent or Config.Muted,
			})
			tween(current.Indicator, { BackgroundTransparency = active and 0 or 1 })
		end
		self._activeTab = tab
	end

	function window:SetTitle(newTitle, newSubtitle)
		title.Text = tostring(newTitle or "")
		if newSubtitle ~= nil then
			subtitle.Text = tostring(newSubtitle)
		end
	end

	function window:SetVisible(isVisible)
		local visible = isVisible and true or false
		frame.Visible = visible
		dock.Visible = not visible
		if not visible then
			closeDropdowns()
		end
	end

	function window:Toggle()
		self:SetVisible(not frame.Visible)
		return frame.Visible
	end

	function window:IsVisible()
		return frame.Visible
	end

	function window:Center()
		local currentViewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		frame.Position = UDim2.fromOffset((currentViewport.X - width) / 2, (currentViewport.Y - height) / 2)
	end

	function window:SetKeybind(key)
		if self._keyConnection then
			self._keyConnection:Disconnect()
			self._keyConnection = nil
		end
		if not key then
			return
		end
		self._key = key
		self._keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed or UserInputService:GetFocusedTextBox() then
				return
			end
			if input.KeyCode == self._key then
				self:Toggle()
			end
		end)
	end

	function window:Destroy()
		if self._destroyed then
			return
		end
		self._destroyed = true
		if self._keyConnection then
			self._keyConnection:Disconnect()
			self._keyConnection = nil
		end
		for index = 1, #self._connections do
			self._connections[index]:Disconnect()
		end
		for index = #self._dropdowns, 1, -1 do
			local item = self._dropdowns[index]
			if item and item.Destroy then
				item:Destroy()
			end
		end
		for index = #lib.Windows, 1, -1 do
			if lib.Windows[index] == self then
				table.remove(lib.Windows, index)
			end
		end
		if frame.Parent then
			frame:Destroy()
		end
		if dock.Parent then
			dock:Destroy()
		end
	end

	local dragCleanup
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if dragCleanup then
			dragCleanup()
		end
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		local startPointer = pointerPosition(input)
		local startPosition = frame.Position
		local moveConnection = UserInputService.InputChanged:Connect(function(move)
			if (isTouch and move.UserInputType == Enum.UserInputType.Touch)
				or (not isTouch and move.UserInputType == Enum.UserInputType.MouseMovement) then
				local delta = pointerPosition(move) - startPointer
				frame.Position = UDim2.new(
					startPosition.X.Scale,
					startPosition.X.Offset + delta.X,
					startPosition.Y.Scale,
					startPosition.Y.Offset + delta.Y
				)
			end
		end)
		local endConnection = UserInputService.InputEnded:Connect(function(ended)
			if (isTouch and ended.UserInputType == Enum.UserInputType.Touch)
				or (not isTouch and ended.UserInputType == Enum.UserInputType.MouseButton1) then
				moveConnection:Disconnect()
				endConnection:Disconnect()
				dragCleanup = nil
			end
		end)
		dragCleanup = function()
			moveConnection:Disconnect()
			endConnection:Disconnect()
		end
	end)
	closeButton.Activated:Connect(function()
		window:Destroy()
	end)
	hideButton.Activated:Connect(function()
		window:SetVisible(false)
	end)
	dock.Activated:Connect(function()
		window:SetVisible(true)
	end)
	window:SetKeybind(options.Keybind or Enum.KeyCode.RightControl)

	local originalDestroy = window.Destroy
	function window:Destroy()
		if dragCleanup then
			dragCleanup()
			dragCleanup = nil
		end
		originalDestroy(self)
	end

	table.insert(self.Windows, window)
	return window
end

local function delay(seconds, callback)
	if type(task) == "table" and type(task.delay) == "function" then
		task.delay(seconds, callback)
	else
		spawn(function()
			wait(seconds)
			callback()
		end)
	end
end

function lib:Notify(nameOrOptions, text)
	local options
	if type(nameOrOptions) == "string" then
		options = { Title = nameOrOptions, Text = text }
	else
		options = nameOrOptions or {}
	end
	local toast = make("Frame", {
		Size = UDim2.new(1, 0, 0, 66),
		BackgroundColor3 = Config.Panel,
		BorderSizePixel = 0,
		LayoutOrder = floor(os.clock() * 1000),
		ZIndex = 81,
	}, notificationHost, "Panel")
	round(toast, 7)
	outline(toast, Config.Stroke, 0.2)
	local stripe = make("Frame", {
		Size = UDim2.new(0, 3, 1, -18),
		Position = UDim2.fromOffset(8, 9),
		BackgroundColor3 = Config.Accent,
		BorderSizePixel = 0,
		ZIndex = 82,
	}, toast, "Accent")
	round(stripe, 2)
	textLabel(toast, {
		Size = UDim2.new(1, -34, 0, 20),
		Position = UDim2.fromOffset(20, 9),
		Text = tostring(options.Title or "Muscle Legends"),
		TextSize = 12,
		ZIndex = 82,
	}, "Text")
	textLabel(toast, {
		Size = UDim2.new(1, -34, 0, 28),
		Position = UDim2.fromOffset(20, 31),
		Text = tostring(options.Text or ""),
		TextSize = 11,
		TextColor3 = Config.Muted,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 82,
	}, "Muted")
	toast.Position = UDim2.new(1, 40, 0, 0)
	tween(toast, { Position = UDim2.new(0, 0, 0, 0) }, 0.2)
	local removed = false
	local function close()
		if removed then
			return
		end
		removed = true
		if toast.Parent then
			tween(toast, { BackgroundTransparency = 1 }, 0.15)
			delay(0.17, function()
				if toast.Parent then
					toast:Destroy()
				end
			end)
		end
	end
	delay(tonumber(options.Duration) or 3, close)
	return { Close = close, Frame = toast }
end

function lib:Unload()
	for index = #self.Windows, 1, -1 do
		self.Windows[index]:Destroy()
	end
	if screen and screen.Parent then
		screen:Destroy()
	end
end

function lib:ToggleAll()
	local show = false
	for index = 1, #self.Windows do
		if not self.Windows[index]:IsVisible() then
			show = true
			break
		end
	end
	for index = 1, #self.Windows do
		self.Windows[index]:SetVisible(show)
	end
end

if type(getgenv) == "function" then
	local ok, environment = pcall(getgenv)
	if ok and type(environment) == "table" then
		environment.MLUI = lib
	end
end

print("[MuscleLegendsUI] " .. lib.Build .. " loaded")
return lib
