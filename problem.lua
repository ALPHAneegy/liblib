--[[
    FG100 STYLE UI  |  v1.0.0
    Libreria visual independiente, inspirada en la estetica de FG100 de Young0x:
    panel navy compacto, detalles cyan/violeta, fuente redondeada y tabs horizontales.
    Solo crea controles visuales y callbacks; no incluye automatizacion del juego.

    Carga local:
        ModuleScript: local UI = require(script.Parent.FG100StyleUI)
        Executor:     local UI = loadfile("FG100StyleUI.lua")()
        Alternativa:  local UI = loadstring(readfile("FG100StyleUI.lua"))()

    API estilo FG100:
        local window = UI:CreateWindow({ Name = "Mi Hub", Theme = "Violeta" })
        local tab = window:Tab({ Name = "Main", Width = 88 })
        tab:Section("Generales")
        tab:Button("Accion", function() print("click") end)
        tab:Toggle("Activo", false, function(value) print(value) end)
        tab:Slider("Velocidad", 1, 200, 50, function(value) print(value) end)
        tab:Dropdown("Modo", { "Chill", "Fast" }, "Chill", function(value) end)
        tab:Textbox("Nombre", "escribe aqui", "", function(value) end)
        tab:Label("Estado: listo")
        window:SetKeybind(Enum.KeyCode.RightControl)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local floor, min, max = math.floor, math.min, math.max

local Palette = {
	base = Color3.fromRGB(6, 8, 17),
	panel = Color3.fromRGB(11, 15, 27),
	row = Color3.fromRGB(19, 24, 39),
	rowHover = Color3.fromRGB(29, 37, 58),
	tab = Color3.fromRGB(13, 18, 31),
	tabOn = Color3.fromRGB(28, 39, 65),
	cyan = Color3.fromRGB(105, 205, 255),
	blue = Color3.fromRGB(159, 139, 246),
	green = Color3.fromRGB(126, 224, 175),
	yellow = Color3.fromRGB(238, 206, 111),
	orange = Color3.fromRGB(236, 159, 93),
	red = Color3.fromRGB(255, 75, 98),
	white = Color3.fromRGB(246, 248, 252),
	soft = Color3.fromRGB(225, 230, 239),
	dim = Color3.fromRGB(165, 174, 189),
	black = Color3.fromRGB(0, 0, 0),
}

local ThemePresets = {
	Violeta = {
		cyan = Color3.fromRGB(105, 205, 255),
		blue = Color3.fromRGB(159, 139, 246),
		base = Color3.fromRGB(6, 8, 17),
		panel = Color3.fromRGB(11, 15, 27),
		row = Color3.fromRGB(19, 24, 39),
		rowHover = Color3.fromRGB(29, 37, 58),
		tab = Color3.fromRGB(13, 18, 31),
		tabOn = Color3.fromRGB(28, 39, 65),
	},
	Galaxia = {
		cyan = Color3.fromRGB(80, 228, 229),
		blue = Color3.fromRGB(155, 130, 255),
		base = Color3.fromRGB(7, 8, 20),
		panel = Color3.fromRGB(12, 13, 31),
		row = Color3.fromRGB(20, 21, 45),
		rowHover = Color3.fromRGB(31, 31, 66),
		tab = Color3.fromRGB(14, 15, 35),
		tabOn = Color3.fromRGB(34, 33, 74),
	},
}

local bindings = {}

local function bindColor(object, role, property)
	table.insert(bindings, { Object = object, Role = role, Property = property })
	return object
end

local function new(className, properties, parent)
	local object = Instance.new(className)
	if properties then
		for key, value in pairs(properties) do
			pcall(function()
				object[key] = value
			end)
		end
	end
	if parent then
		object.Parent = parent
	end
	return object
end

local function colorObject(object, role, property)
	bindColor(object, role, property)
	object[property] = Palette[role]
	return object
end

local function corner(object, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, object)
end

local function stroke(object, color, thickness, transparency, role)
	local outline = new("UIStroke", {
		Color = color or Palette.blue,
		Thickness = thickness or 1,
		Transparency = transparency == nil and 0.35 or transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, object)
	if role then bindColor(outline, role, "Color") end
	return outline
end

local gradientBindings = {}
local function gradient(object, colors, rotation, themeAccent)
	local effect = new("UIGradient", {
		Color = colors or ColorSequence.new(Palette.cyan, Palette.blue),
		Rotation = rotation or 0,
	}, object)
	if themeAccent then table.insert(gradientBindings, effect) end
	return effect
end

local function label(parent, properties, role)
	properties = properties or {}
	properties.BackgroundTransparency = 1
	properties.Font = properties.Font or Enum.Font.FredokaOne
	properties.TextSize = properties.TextSize or 12
	properties.TextColor3 = properties.TextColor3 or Palette.soft
	if properties.TextXAlignment == nil then
		properties.TextXAlignment = Enum.TextXAlignment.Left
	end
	local object = new("TextLabel", properties, parent)
	if role then bindColor(object, role, "TextColor3") end
	return object
end

local function textButton(parent, properties)
	properties = properties or {}
	properties.AutoButtonColor = false
	properties.BorderSizePixel = 0
	properties.Font = properties.Font or Enum.Font.FredokaOne
	properties.TextSize = properties.TextSize or 12
	properties.TextColor3 = properties.TextColor3 or Palette.soft
	properties.BackgroundColor3 = properties.BackgroundColor3 or Palette.row
	local object = new("TextButton", properties, parent)
	return object
end

local function tween(object, properties, duration, style)
	local info = TweenInfo.new(
		duration or 0.14,
		style or Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)
	local animation = TweenService:Create(object, info, properties)
	animation:Play()
	return animation
end

local function clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

local function formatNumber(value)
	if value % 1 == 0 then
		return tostring(value)
	end
	local result = string.format("%.2f", value):gsub("0+$", "")
	return result:gsub("%.$", "")
end

local function viewportSize()
	local camera = Workspace.CurrentCamera
	return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function hubSize(options)
	local viewport = viewportSize()
	local isMobile = viewport.X < 760 or (UserInputService.TouchEnabled and viewport.X < 1100)
	if isMobile then
		local minWidth = 276
		local maxWidth = math.min(470, viewport.X - 16)
		local width = math.floor(clamp(viewport.X * 0.9, minWidth, maxWidth))
		local height = math.floor(clamp(viewport.Y * 0.58, 220, math.min(390, viewport.Y - 28)))
		return width, height, true
	end
	return tonumber(options.Width) or 548, tonumber(options.Height) or 360, false
end

local function getGuiParent()
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

local Library = {
	Name = "FG100 Style UI",
	Version = "1.0.0",
	Config = Palette,
	Themes = ThemePresets,
	State = {},
	Windows = {},
}
local screen = nil

function Library:Theme(theme)
	if type(theme) == "string" then
		theme = ThemePresets[theme]
	end
	if type(theme) ~= "table" then
		return false
	end
	for key, value in pairs(theme) do
		if Palette[key] ~= nil then
			Palette[key] = value
		end
	end
	for index = 1, #bindings do
		local binding = bindings[index]
		local object = binding.Object
		if object and object.Parent and Palette[binding.Role] then
			pcall(function()
				object[binding.Property] = Palette[binding.Role]
			end)
		end
	end
	for index = 1, #gradientBindings do
		local object = gradientBindings[index]
		if object and object.Parent then
			pcall(function()
				object.Color = ColorSequence.new(Palette.cyan, Palette.blue)
			end)
		end
	end
	return true
end

local function createElementApi(frame)
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

local function optionsFromArgs(nameOrOptions, default, callback)
	if type(nameOrOptions) == "table" then
		return nameOrOptions
	end
	return { Name = tostring(nameOrOptions or ""), Default = default, Callback = callback }
end

local function createSection(tab, sectionName)
	local page = tab.Page
	tab._sectionOrder = tab._sectionOrder + 1
	local frame = new("Frame", {
		Name = "Section_" .. tostring(sectionName or "Options"),
		Size = UDim2.new(1, -10, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = tab._sectionOrder,
	}, page)
	local heading = label(frame, {
		Size = UDim2.new(1, -8, 0, 20),
		Position = UDim2.fromOffset(3, 0),
		Text = tostring(sectionName or "OPTIONS"),
		Font = Enum.Font.FredokaOne,
		TextSize = 13,
		TextColor3 = Palette.white,
	}, "white")
	local underline = new("Frame", {
		Size = UDim2.new(1, -10, 0, 1),
		Position = UDim2.fromOffset(4, 21),
		BackgroundColor3 = Palette.blue,
		BackgroundTransparency = 0.62,
		BorderSizePixel = 0,
	}, frame)
	colorObject(underline, "blue", "BackgroundColor3")
	local list = new("Frame", {
		Name = "SectionItems",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 27),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, frame)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, list)
	new("UIPadding", { PaddingBottom = UDim.new(0, 8) }, list)
	local section = {
		Name = tostring(sectionName or "OPTIONS"),
		Frame = frame,
		Heading = heading,
		Items = list,
		Window = tab.Window,
		_order = 0,
	}
	return section
end

local function makeRow(section, height, transparent)
	section._order = section._order + 1
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Palette.row,
		BackgroundTransparency = transparent and 1 or 0.12,
		BorderSizePixel = 0,
		LayoutOrder = section._order,
	}, section.Items)
	if not transparent then
		colorObject(row, "row", "BackgroundColor3")
		corner(row, 7)
		stroke(row, Palette.blue, 0.8, 0.70, "blue")
	end
	return row
end

local function titleAndDescription(row, settings, rightSpace)
	local title = label(row, {
		Size = UDim2.new(1, rightSpace or -68, 0, settings.Description and 18 or 26),
		Position = UDim2.fromOffset(11, settings.Description and 5 or 0),
		Text = tostring(settings.Name or "Option"),
		TextSize = 12,
		TextColor3 = Palette.soft,
		TextYAlignment = settings.Description and Enum.TextYAlignment.Bottom or Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, "soft")
	if settings.Description and tostring(settings.Description) ~= "" then
		label(row, {
			Size = UDim2.new(1, rightSpace or -68, 0, 15),
			Position = UDim2.fromOffset(11, 26),
			Text = tostring(settings.Description),
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextColor3 = Palette.dim,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, "dim")
	end
	return title
end

local function installSectionControlMethods(target, section)
	function target:Button(name, callback)
		local settings = optionsFromArgs(name, nil, callback)
		local row = makeRow(section, 34)
		local control = textButton(row, {
			Size = UDim2.fromScale(1, 1),
			Text = tostring(settings.Name or "Button"),
			BackgroundColor3 = Palette.row,
			BackgroundTransparency = 1,
			TextColor3 = Palette.soft,
			TextSize = 12,
		})
		control.TextXAlignment = Enum.TextXAlignment.Left
		colorObject(control, "soft", "TextColor3")
		new("UIPadding", { PaddingLeft = UDim.new(0, 11) }, control)
		control.MouseEnter:Connect(function()
			tween(row, { BackgroundColor3 = Palette.rowHover }, 0.12)
		end)
		control.MouseLeave:Connect(function()
			tween(row, { BackgroundColor3 = Palette.row }, 0.12)
		end)
		local api = createElementApi(row)
		control.Activated:Connect(function()
			if settings.Callback then settings.Callback(api) end
		end)
		return api
	end
	function target:Toggle(name, default, callback)
		local settings
		if type(name) == "table" then
			settings = name
		else
			settings = { Name = name, Default = default, Callback = callback }
		end
		local row = makeRow(section, settings.Description and 48 or 36)
		titleAndDescription(row, settings, -74)
		local track = textButton(row, {
			Size = UDim2.fromOffset(40, 20),
			Position = UDim2.new(1, -50, 0.5, -10),
			Text = "",
			BackgroundColor3 = Palette.panel,
		})
		colorObject(track, "panel", "BackgroundColor3")
		corner(track, 10)
		stroke(track, Palette.blue, 0.8, 0.62, "blue")
		local knob = new("Frame", {
			Size = UDim2.fromOffset(12, 12),
			Position = UDim2.new(0, 4, 0.5, -6),
			BackgroundColor3 = Palette.dim,
			BorderSizePixel = 0,
		}, track)
		colorObject(knob, "dim", "BackgroundColor3")
		corner(knob, 8)
		local value = settings.Default == true
		local api = createElementApi(row)
		local function draw(animated)
			local pos = value and UDim2.new(1, -16, 0.5, -6) or UDim2.new(0, 4, 0.5, -6)
			local background = value and Palette.blue or Palette.panel
			local knobColor = value and Palette.white or Palette.dim
			if animated then
				tween(track, { BackgroundColor3 = background }, 0.12)
				tween(knob, { Position = pos, BackgroundColor3 = knobColor }, 0.12)
			else
				track.BackgroundColor3 = background
				knob.Position = pos
				knob.BackgroundColor3 = knobColor
			end
		end
		local function set(valueNew, invoke)
			value = valueNew == true
			draw(true)
			if invoke and settings.Callback then settings.Callback(value) end
		end
		track.Activated:Connect(function() set(not value, true) end)
		draw(false)
		function api:Set(valueNew, invoke) set(valueNew, invoke == true) end
		function api:Get() return value end
		function api:SetValue(valueNew) set(valueNew, false) end
		function api:GetValue() return value end
		function api:Toggle() set(not value, true) end
		return api
	end
	function target:Slider(name, minimum, maximum, default, callback)
		local settings
		if type(name) == "table" then
			settings = name
		else
			settings = { Name = name, Min = minimum, Max = maximum, Default = default, Callback = callback }
		end
		local low = tonumber(settings.Min or settings.Minimum) or 0
		local high = tonumber(settings.Max or settings.Maximum) or 100
		if high <= low then high = low + 1 end
		local step = tonumber(settings.Step) or 1
		local value = clamp(tonumber(settings.Default) or low, low, high)
		local suffix = tostring(settings.Suffix or "")
		local row = makeRow(section, settings.Description and 56 or 47)
		titleAndDescription(row, settings, -80)
		local valueLabel = label(row, {
			Size = UDim2.new(0, 64, 0, 18),
			Position = UDim2.new(1, -74, 0, 4),
			Text = "",
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = Palette.cyan,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, "cyan")
		local barY = settings.Description and 43 or 34
		local bar = new("Frame", {
			Size = UDim2.new(1, -22, 0, 5),
			Position = UDim2.fromOffset(11, barY),
			BackgroundColor3 = Palette.panel,
			BorderSizePixel = 0,
			Active = true,
		}, row)
		colorObject(bar, "panel", "BackgroundColor3")
		corner(bar, 3)
		local fill = new("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Palette.cyan,
			BorderSizePixel = 0,
		}, bar)
		colorObject(fill, "cyan", "BackgroundColor3")
		corner(fill, 3)
		gradient(fill, ColorSequence.new(Palette.cyan, Palette.blue), 0, true)
		local knob = new("Frame", {
			Size = UDim2.fromOffset(11, 11),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Palette.white,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, bar)
		colorObject(knob, "white", "BackgroundColor3")
		corner(knob, 7)
		stroke(knob, Palette.cyan, 0.6, 0.15, "cyan")
		local hit = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.fromOffset(0, barY - 7),
			BackgroundTransparency = 1,
			Text = "",
			Active = true,
			ZIndex = 4,
		}, row)
		local api = createElementApi(row)
		local function render(animated)
			local ratio = clamp((value - low) / (high - low), 0, 1)
			valueLabel.Text = formatNumber(value) .. suffix
			local fillSize = UDim2.new(ratio, 0, 1, 0)
			local knobPos = UDim2.new(ratio, 0, 0.5, 0)
			if animated then
				tween(fill, { Size = fillSize }, 0.08)
				tween(knob, { Position = knobPos }, 0.08)
			else
				fill.Size = fillSize
				knob.Position = knobPos
			end
		end
		local function set(newValue, invoke)
			newValue = clamp(tonumber(newValue) or low, low, high)
			if step > 0 then newValue = low + floor((newValue - low) / step + 0.5) * step end
			newValue = clamp(newValue, low, high)
			local changed = value ~= newValue
			value = newValue
			render(true)
			if changed and invoke and settings.Callback then settings.Callback(value) end
		end
		local function fromX(x)
			local width = bar.AbsoluteSize.X
			if width <= 0 then return value end
			return low + clamp((x - bar.AbsolutePosition.X) / width, 0, 1) * (high - low)
		end
		local function inputX(input)
			if input.UserInputType == Enum.UserInputType.Touch then return input.Position.X end
			return UserInputService:GetMouseLocation().X
		end
		local function begin(input)
			set(fromX(inputX(input)), true)
			local touch = input.UserInputType == Enum.UserInputType.Touch
			local moveConnection = UserInputService.InputChanged:Connect(function(changed)
				if (touch and changed.UserInputType == Enum.UserInputType.Touch)
					or (not touch and changed.UserInputType == Enum.UserInputType.MouseMovement) then
					set(fromX(inputX(changed)), true)
				end
			end)
			local endConnection = UserInputService.InputEnded:Connect(function(ended)
				if (touch and ended.UserInputType == Enum.UserInputType.Touch)
					or (not touch and ended.UserInputType == Enum.UserInputType.MouseButton1) then
					moveConnection:Disconnect()
					endConnection:Disconnect()
				end
			end)
			api:AddCleanup(function() moveConnection:Disconnect(); endConnection:Disconnect() end)
		end
		hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then begin(input) end
		end)
		render(false)
		function api:Set(valueNew, invoke) set(valueNew, invoke == true) end
		function api:Get() return value end
		function api:SetValue(valueNew) set(valueNew, false) end
		function api:GetValue() return value end
		return api
	end
	function target:Dropdown(name, values, default, callback)
		local settings
		if type(name) == "table" then
			settings = name
		else
			settings = { Name = name, Options = values, Default = default, Callback = callback }
		end
		local choices = settings.Options or settings.Values or {}
		local selected = settings.Default
		if selected == nil then selected = choices[1] end
		local row = makeRow(section, 39, true)
		local control = textButton(row, {
			Size = UDim2.new(1, 0, 0, 34),
			Text = "",
			BackgroundColor3 = Palette.row,
		})
		colorObject(control, "row", "BackgroundColor3")
		corner(control, 7)
		stroke(control, Palette.blue, 0.8, 0.7, "blue")
		label(control, {
			Size = UDim2.new(0.50, -12, 1, 0),
			Position = UDim2.fromOffset(10, 0),
			Text = tostring(settings.Name or "Dropdown"),
			TextSize = 11,
			TextColor3 = Palette.soft,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, "soft")
		local current = label(control, {
			Size = UDim2.new(0.50, -32, 1, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			Text = tostring(selected or "Select"),
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = Palette.cyan,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, "cyan")
		local arrow = label(control, {
			Size = UDim2.fromOffset(19, 22),
			Position = UDim2.new(1, -24, 0.5, -11),
			Text = "⌄",
			TextSize = 15,
			TextColor3 = Palette.blue,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, "blue")
		local menu = new("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, min(#choices, 5) * 25 + 4),
			Position = UDim2.fromOffset(0, 36),
			BackgroundColor3 = Palette.panel,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Palette.cyan,
			CanvasSize = UDim2.new(0, 0, 0, #choices * 26),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false,
			ZIndex = 20,
		}, row)
		colorObject(menu, "panel", "BackgroundColor3")
		corner(menu, 7)
		stroke(menu, Palette.blue, 0.8, 0.45, "blue")
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }, menu)
		local api = createElementApi(row)
		local open = false
		local optionsButtons = {}
		local menuHeight = min(#choices, 5) * 25 + 4
		local function closeMenu()
			if not open then return end
			open = false
			menu.Visible = false
			row.Size = UDim2.new(1, 0, 0, 39)
			arrow.Text = "⌄"
		end
		local function set(value, invoke)
			selected = value
			current.Text = tostring(value or "")
			for index = 1, #optionsButtons do
				optionsButtons[index].TextColor3 = tostring(choices[index]) == tostring(selected) and Palette.cyan or Palette.soft
			end
			if invoke and settings.Callback then settings.Callback(selected) end
		end
		local function refresh()
			for index = #optionsButtons, 1, -1 do
				optionsButtons[index]:Destroy()
				optionsButtons[index] = nil
			end
			for index = 1, #choices do
				local value = choices[index]
				local option = textButton(menu, {
					Size = UDim2.new(1, -4, 0, 24),
					LayoutOrder = index,
					Text = tostring(value),
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = tostring(value) == tostring(selected) and Palette.cyan or Palette.soft,
					BackgroundTransparency = 1,
					ZIndex = 21,
				})
				colorObject(option, "soft", "TextColor3")
				new("UIPadding", { PaddingLeft = UDim.new(0, 9) }, option)
				option.Activated:Connect(function() set(value, true); closeMenu() end)
				table.insert(optionsButtons, option)
			end
			menuHeight = min(#choices, 5) * 25 + 4
			menu.Size = UDim2.new(1, 0, 0, menuHeight)
			menu.CanvasSize = UDim2.new(0, 0, 0, #choices * 26)
		end
		control.Activated:Connect(function()
			open = not open
			menu.Visible = open
			row.Size = UDim2.new(1, 0, 0, open and (39 + menuHeight) or 39)
			arrow.Text = open and "⌃" or "⌄"
		end)
		refresh()
		function api:SetValue(value) set(value, false) end
		function api:GetValue() return selected end
		function api:SetOptions(newValues)
			choices = newValues or {}
			if #choices == 0 then selected = nil elseif selected == nil then selected = choices[1] end
			refresh()
			if open then row.Size = UDim2.new(1, 0, 0, 39 + menuHeight) end
		end
		function api:Close() closeMenu() end
		if section.Window then
			table.insert(section.Window._dropdowns, api)
			api:AddCleanup(function()
				for index = #section.Window._dropdowns, 1, -1 do
					if section.Window._dropdowns[index] == api then table.remove(section.Window._dropdowns, index) end
				end
			end)
		end
		api:AddCleanup(closeMenu)
		return api
	end
	function target:Textbox(name, placeholder, default, callback)
		local settings
		if type(name) == "table" then
			settings = name
		else
			settings = { Name = name, Placeholder = placeholder, Default = default, Callback = callback }
		end
		local row = makeRow(section, 58)
		label(row, {
			Size = UDim2.new(1, -16, 0, 17),
			Position = UDim2.fromOffset(10, 2),
			Text = tostring(settings.Name or "INPUT"),
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			TextColor3 = Palette.dim,
		}, "dim")
		local box = new("TextBox", {
			Size = UDim2.new(1, -18, 0, 29),
			Position = UDim2.fromOffset(9, 24),
			BackgroundColor3 = Palette.panel,
			BorderSizePixel = 0,
			Text = tostring(settings.Default or ""),
			PlaceholderText = tostring(settings.Placeholder or "type here..."),
			PlaceholderColor3 = Palette.dim,
			TextColor3 = Palette.soft,
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			MultiLine = false,
		}, row)
		colorObject(box, "panel", "BackgroundColor3")
		colorObject(box, "soft", "TextColor3")
		corner(box, 6)
		local outline = stroke(box, Palette.blue, 0.8, 0.7, "blue")
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
		local api = createElementApi(row)
		box.Focused:Connect(function() tween(outline, { Transparency = 0.2 }, 0.1) end)
		box.FocusLost:Connect(function(enterPressed)
			tween(outline, { Transparency = 0.7 }, 0.1)
			if settings.Callback then settings.Callback(box.Text, enterPressed) end
		end)
		function api:SetValue(value) box.Text = tostring(value or "") end
		function api:GetValue() return box.Text end
		function api:Focus() box:CaptureFocus() end
		return api
	end
	function target:Label(value, color)
		local row = makeRow(section, 25, true)
		local item = label(row, {
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.fromOffset(4, 0),
			Text = tostring(value or ""),
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = color or Palette.soft,
			TextWrapped = true,
		})
		local api = createElementApi(row)
		api.Label = item
		function api:SetValue(newValue) item.Text = tostring(newValue or "") end
		function api:GetValue() return item.Text end
		return api
	end
	function target:Row(rowName, value, color, indicator, accent)
		local row = makeRow(section, 34)
		label(row, {
			Size = UDim2.new(0.45, -10, 1, 0),
			Position = UDim2.fromOffset(10, 0),
			Text = tostring(rowName or ""),
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = Palette.dim,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, "dim")
		local valueLabel = label(row, {
			Size = UDim2.new(0.55, -30, 1, 0),
			Position = UDim2.new(0.45, 0, 0, 0),
			Text = tostring(value or ""),
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = color or (accent and Palette.cyan or Palette.white),
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		if indicator then
			local dot = new("Frame", {
				Size = UDim2.fromOffset(6, 6),
				Position = UDim2.new(1, -13, 0.5, -3),
				BackgroundColor3 = color or Palette.green,
				BorderSizePixel = 0,
			}, row)
			corner(dot, 4)
		end
		local api = createElementApi(row)
		api.Label = valueLabel
		function api:SetValue(newValue) valueLabel.Text = tostring(newValue or "") end
		function api:GetValue() return valueLabel.Text end
		return api
	end
	return target
end

function Library:CreateWindow(options)
	options = options or {}
	local parent = getGuiParent()
	assert(parent, "FG100StyleUI necesita PlayerGui o CoreGui")
	for index = #Library.Windows, 1, -1 do
		local previousWindow = Library.Windows[index]
		if previousWindow and previousWindow.Destroy then previousWindow:Destroy() end
	end
	if screen and screen.Parent then screen:Destroy() end
	screen = new("ScreenGui", {
		Name = "FG100StyleUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 990,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, parent)
	Library.ScreenGui = screen
	Library.Windows = {}
	Library.Theme(options.Theme or "Violeta")

	local width, height, mobile = hubSize(options)
	local headerHeight = mobile and 46 or 54
	local tabHeight = mobile and 36 or 40
	local window = {
		_tabs = {},
		_pages = {},
		_buttons = {},
		_dropdowns = {},
		_connections = {},
		_minimized = false,
		_destroyed = false,
		_currentTab = nil,
	}

	local animationRoot = new("Frame", {
		Name = "AnimationRoot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	}, screen)
	local scale = new("UIScale", { Scale = 1 }, animationRoot)
	window.AnimationRoot = animationRoot

	local border = new("Frame", {
		Name = "OuterBorder",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Palette.base,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, animationRoot)
	corner(border, 13)
	local borderStroke = stroke(border, Palette.cyan, 1.5, 0.1, "cyan")
	local borderGradient = gradient(borderStroke, ColorSequence.new(Palette.cyan, Palette.blue), 10)
	borderGradient.Name = "BorderGradient"
	local aura = stroke(border, Palette.blue, 4, 0.78, "blue")
	aura.Name = "AuraStroke"

	local main = new("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.fromOffset(1, 1),
		BackgroundColor3 = Palette.base,
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, border)
	colorObject(main, "base", "BackgroundColor3")
	corner(main, 12)
	gradient(main, ColorSequence.new(Palette.base, Palette.panel), 25)
	local backgroundArt = new("ImageLabel", {
		Name = "BackgroundArt",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = tostring(options.BackgroundImage or "rbxassetid://139632902209610"),
		ImageColor3 = Color3.fromRGB(204, 211, 255),
		ImageTransparency = 0.62,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 2,
	}, main)
	corner(backgroundArt, 12)
	local backgroundShade = new("Frame", {
		Name = "BackgroundShade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Palette.base,
		BackgroundTransparency = 0.31,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, main)
	colorObject(backgroundShade, "base", "BackgroundColor3")
	corner(backgroundShade, 12)
	local topSheen = new("Frame", {
		Name = "TopSheen",
		Size = UDim2.new(1, 0, 0, headerHeight + 34),
		BackgroundColor3 = Palette.white,
		BackgroundTransparency = 0.98,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, main)
	gradient(topSheen, ColorSequence.new(Palette.cyan, Palette.blue), 0)

	local header = new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, headerHeight),
		BackgroundColor3 = Palette.panel,
		BackgroundTransparency = 0.28,
		BorderSizePixel = 0,
		ZIndex = 5,
		Active = true,
	}, main)
	colorObject(header, "panel", "BackgroundColor3")
	local headerGradient = gradient(header, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 24, 43)),
		ColorSequenceKeypoint.new(0.52, Palette.panel),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 13, 43)),
	}), 0)

	local title = label(header, {
		Size = UDim2.new(1, -94, 0, mobile and 23 or 28),
		Position = UDim2.fromOffset(11, mobile and 3 or 4),
		Text = tostring(options.Name or "FG100 · Young0x"),
		Font = Enum.Font.FredokaOne,
		TextSize = mobile and 16 or 19,
		TextColor3 = Palette.white,
		TextStrokeColor3 = Palette.black,
		TextStrokeTransparency = 0.72,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 7,
	}, "white")
	local titleGradient = gradient(title, ColorSequence.new(Palette.white, Palette.blue), 0)

	local status = label(header, {
		Size = UDim2.new(1, -20, 0, 13),
		Position = UDim2.new(0, 10, 1, -16),
		Text = tostring(options.Subtitle or "FG100 ONLINE"),
		Font = Enum.Font.GothamBold,
		TextSize = 8,
		TextColor3 = Palette.cyan,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 7,
	}, "cyan")

	local minimizeButton = textButton(header, {
		Size = UDim2.fromOffset(22, 20),
		Position = UDim2.new(1, -51, 0, 7),
		Text = "−",
		Font = Enum.Font.GothamMedium,
		TextSize = 17,
		TextColor3 = Palette.soft,
		BackgroundColor3 = Palette.row,
		ZIndex = 8,
	})
	colorObject(minimizeButton, "row", "BackgroundColor3")
	corner(minimizeButton, 6)
	stroke(minimizeButton, Palette.cyan, 0.8, 0.68, "cyan")
	local closeButton = textButton(header, {
		Size = UDim2.fromOffset(22, 20),
		Position = UDim2.new(1, -25, 0, 7),
		Text = "×",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Palette.soft,
		BackgroundColor3 = Palette.row,
		ZIndex = 8,
	})
	colorObject(closeButton, "row", "BackgroundColor3")
	corner(closeButton, 6)
	stroke(closeButton, Palette.blue, 0.8, 0.68, "blue")
	local headerLine = new("Frame", {
		Size = UDim2.new(1, -26, 0, 1),
		Position = UDim2.new(0, 13, 1, -1),
		BackgroundColor3 = Palette.cyan,
		BackgroundTransparency = 0.52,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, header)
	colorObject(headerLine, "cyan", "BackgroundColor3")
	local headerLineGradient = gradient(headerLine, ColorSequence.new(Palette.cyan, Palette.blue), 0)

	local tabBar = new("ScrollingFrame", {
		Name = "TabBar",
		Size = UDim2.new(1, -22, 0, tabHeight),
		Position = UDim2.fromOffset(0, headerHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		Active = true,
		ZIndex = 8,
	}, main)
	local tabLayout = new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, tabBar)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	}, tabBar)

	local content = new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -(headerHeight + tabHeight)),
		Position = UDim2.fromOffset(0, headerHeight + tabHeight),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 7,
	}, main)
	window.Content = content

	local miniBubble = textButton(screen, {
		Name = "FG100MiniBubble",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -math.floor(width * 0.5 + 93), 0.5, 0),
		Size = UDim2.fromOffset(168, 68),
		BackgroundColor3 = Color3.fromRGB(20, 24, 32),
		Text = "",
		Visible = false,
		ZIndex = 100,
	})
	corner(miniBubble, 12)
	gradient(miniBubble, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 20, 27)),
		ColorSequenceKeypoint.new(0.46, Color3.fromRGB(31, 38, 49)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 24, 32)),
	}), 0)
	stroke(miniBubble, Color3.fromRGB(172, 198, 219), 1.2, 0.18)
	local miniAura = stroke(miniBubble, Palette.cyan, 3, 0.82, "cyan")
	local miniTitle = label(miniBubble, {
		Size = UDim2.new(1, -12, 0, 25),
		Position = UDim2.fromOffset(6, 4),
		Text = tostring(options.MiniTitle or "FG100%"),
		Font = Enum.Font.FredokaOne,
		TextSize = 16,
		TextColor3 = Palette.white,
		TextStrokeTransparency = 0.15,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 102,
	}, "white")
	local miniStats = label(miniBubble, {
		Size = UDim2.new(1, -12, 0, 20),
		Position = UDim2.new(0, 6, 1, -23),
		Text = "READY  •  FG100 STYLE",
		Font = Enum.Font.GothamBold,
		TextSize = 8,
		TextColor3 = Palette.cyan,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 102,
	}, "cyan")
	local miniLine = new("Frame", {
		Size = UDim2.new(1, -16, 0, 2),
		Position = UDim2.new(0, 8, 1, -5),
		BackgroundColor3 = Palette.cyan,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		ZIndex = 103,
	}, miniBubble)
	colorObject(miniLine, "cyan", "BackgroundColor3")
	corner(miniLine, 2)
	window.MiniBubble = miniBubble
	window.MiniStats = miniStats

	local function closeMenus()
		for index = 1, #window._dropdowns do
			local dropdown = window._dropdowns[index]
			if dropdown and dropdown.Close then dropdown:Close() end
		end
	end
	local function updateTabCanvas()
		tabBar.CanvasSize = UDim2.fromOffset(tabLayout.AbsoluteContentSize.X + 14, 0)
	end
	tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateTabCanvas)

	function window:SelectTab(name)
		local tab = type(name) == "table" and name or self._tabs[name]
		if not tab then return false end
		closeMenus()
		self._currentTab = tab.Name
		for tabName, current in pairs(self._tabs) do
			local selected = tabName == tab.Name
			current.Page.Visible = selected
			current.Button:SetAttribute("Selected", selected)
			tween(current.Button, {
				BackgroundColor3 = selected and Palette.tabOn or Palette.tab,
				BackgroundTransparency = selected and 0.34 or 1,
				TextColor3 = selected and Palette.white or Palette.soft,
			})
			tween(current.Line, {
				Size = selected and UDim2.new(1, -14, 0, 3) or UDim2.fromOffset(0, 3),
				BackgroundTransparency = selected and 0 or 1,
			})
			local scaleObject = current.Button:FindFirstChild("TabScale")
			if scaleObject then tween(scaleObject, { Scale = selected and 1.018 or 1 }, 0.14, Enum.EasingStyle.Back) end
		end
		local selectedButton = tab.Button
		task.defer(function()
			if not selectedButton or not selectedButton.Parent then return end
			local currentX = tabBar.CanvasPosition.X
			local left = selectedButton.AbsolutePosition.X - tabBar.AbsolutePosition.X + currentX
			local right = left + selectedButton.AbsoluteSize.X
			local targetX = currentX
			if left < currentX + 6 then
				targetX = left - 6
			elseif right > currentX + tabBar.AbsoluteSize.X - 6 then
				targetX = right - tabBar.AbsoluteSize.X + 6
			end
			local maximumX = max(0, tabBar.AbsoluteCanvasSize.X - tabBar.AbsoluteSize.X)
			if targetX ~= currentX then tween(tabBar, { CanvasPosition = Vector2.new(clamp(targetX, 0, maximumX), 0) }, 0.14) end
		end)
		return true
	end

	function window:Tab(tabOptions)
		local name, tabWidth
		if type(tabOptions) == "table" then
			name = tabOptions.Name or tabOptions.name
			tabWidth = tonumber(tabOptions.Width or tabOptions.width)
		else
			name = tabOptions
		end
		if type(name) ~= "string" or name == "" then return nil end
		if self._tabs[name] then return self._tabs[name].Proxy end
		local order = #self._tabOrder + 1
		local page = new("ScrollingFrame", {
			Name = "Page_" .. name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Palette.cyan,
			Visible = false,
			ZIndex = 8,
		}, content)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 9),
			PaddingRight = UDim.new(0, 9),
			PaddingTop = UDim.new(0, 7),
			PaddingBottom = UDim.new(0, 9),
		}, page)
		local layout = new("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
		}, page)
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 18)
		end)
		local buttonWidth = tabWidth or clamp(#name * (mobile and 6 or 7) + 26, 58, 124)
		local tabButton = textButton(tabBar, {
			Name = "Tab_" .. name,
			Size = UDim2.fromOffset(buttonWidth, tabHeight - 8),
			Text = name,
			TextColor3 = Palette.soft,
			TextSize = 11,
			BackgroundColor3 = Palette.tab,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			ZIndex = 10,
		})
		colorObject(tabButton, "tab", "BackgroundColor3")
		colorObject(tabButton, "soft", "TextColor3")
		corner(tabButton, 7)
		local tabScale = new("UIScale", { Name = "TabScale", Scale = 1 }, tabButton)
		stroke(tabButton, Palette.blue, 0.9, 1, "blue")
		local activeLine = new("Frame", {
			Name = "ActiveLine",
			AnchorPoint = Vector2.new(0.5, 1),
			Size = UDim2.fromOffset(0, 3),
			Position = UDim2.new(0.5, 0, 1, -2),
			BackgroundColor3 = Palette.cyan,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 11,
		}, tabButton)
		colorObject(activeLine, "cyan", "BackgroundColor3")
		corner(activeLine, 2)
		gradient(activeLine, ColorSequence.new(Palette.cyan, Palette.blue), 0, true)
		local tab = {
			Name = name,
			Window = self,
			Page = page,
			Button = tabButton,
			Line = activeLine,
			Sections = {},
			_order = 0,
		}
		self._tabs[name] = tab
		self._tabOrder[order] = name
		tabButton.Activated:Connect(function() self:SelectTab(name) end)
		tabButton.MouseEnter:Connect(function()
			if tabButton:GetAttribute("Selected") then return end
			tween(tabButton, { BackgroundColor3 = Palette.rowHover, BackgroundTransparency = 0.72 }, 0.1)
			tween(tabScale, { Scale = 1.025 }, 0.1, Enum.EasingStyle.Quad)
		end)
		tabButton.MouseLeave:Connect(function()
			if tabButton:GetAttribute("Selected") then return end
			tween(tabButton, { BackgroundColor3 = Palette.tab, BackgroundTransparency = 1 }, 0.1)
			tween(tabScale, { Scale = 1 }, 0.1, Enum.EasingStyle.Quad)
		end)
		local proxy = {}
		setmetatable(proxy, { __index = tab })
		tab.Proxy = proxy
		local methods = { "Section", "AddSection", "Button", "Toggle", "Slider", "Dropdown", "Textbox", "Label", "Row" }
		for index = 1, #methods do
			local method = methods[index]
			proxy[method] = function(_, ...)
				if method == "Section" or method == "AddSection" then
					local section = createSection(tab, ...)
					tab._activeSection = section
					installSectionControlMethods(section, section)
					return section
				end
				local section = tab._activeSection
				if not section then
					section = createSection(tab, "GENERAL")
					tab._activeSection = section
					installSectionControlMethods(section, section)
				end
				return section[method](section, ...)
			end
		end
		function proxy:Select() self.Window:SelectTab(self.Name) end
		if not self._currentTab then self:SelectTab(name) end
		updateTabCanvas()
		return proxy
	end
	function window:AddTab(name, width)
		return self:Tab({ Name = name, Width = width })
	end

	function window:SetTitle(value)
		title.Text = tostring(value or "")
	end
	function window:SetTheme(value)
		return Library:Theme(value)
	end
	function window:SetVisible(visible)
		visible = visible and true or false
		animationRoot.Visible = visible
		miniBubble.Visible = not visible
		self._minimized = not visible
		if not visible then closeMenus() end
	end
	function window:Minimize() self:SetVisible(false) end
	function window:Restore() self:SetVisible(true) end
	function window:SetMinimized(value) self:SetVisible(not (value == true)) end
	function window:IsMinimized() return self._minimized end
	function window:SelectedTab() return self._currentTab end
	function window:SetKeybind(key)
		if self._keyConnection then self._keyConnection:Disconnect(); self._keyConnection = nil end
		if not key then return end
		self._key = key
		self._keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed or UserInputService:GetFocusedTextBox() then return end
			if input.KeyCode == self._key then self:SetVisible(self._minimized) end
		end)
	end
	function window:Center()
		animationRoot.Position = UDim2.fromScale(0.5, 0.5)
	end
	function window:Destroy()
		if self._destroyed then return end
		self._destroyed = true
		if self._keyConnection then self._keyConnection:Disconnect(); self._keyConnection = nil end
		if self._dragCleanup then self._dragCleanup(); self._dragCleanup = nil end
		for index = #self._dropdowns, 1, -1 do
			local dropdown = self._dropdowns[index]
			if dropdown and dropdown.Destroy then dropdown:Destroy() end
		end
		for index = #Library.Windows, 1, -1 do
			if Library.Windows[index] == self then table.remove(Library.Windows, index) end
		end
		if screen and screen.Parent then screen:Destroy() end
	end
	window._tabs = {}
	window._tabOrder = {}
	window._dropdowns = {}
	window._currentTab = nil
	window._minimized = false
	window.Frame = main
	window.Title = title
	window.MiniStats = miniStats

	local function moveFrame(target, startInput, startPosition, setter)
		local start = startInput.Position
		local touch = startInput.UserInputType == Enum.UserInputType.Touch
		local moveConnection
		local endConnection
		local function finish()
			if moveConnection then moveConnection:Disconnect(); moveConnection = nil end
			if endConnection then endConnection:Disconnect(); endConnection = nil end
			window._dragCleanup = nil
		end
		moveConnection = UserInputService.InputChanged:Connect(function(input)
			if (touch and input.UserInputType == Enum.UserInputType.Touch)
				or (not touch and input.UserInputType == Enum.UserInputType.MouseMovement) then
				local delta = input.Position - start
				setter(UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y))
			end
		end)
		endConnection = UserInputService.InputEnded:Connect(function(input)
			if (touch and input.UserInputType == Enum.UserInputType.Touch)
				or (not touch and input.UserInputType == Enum.UserInputType.MouseButton1) then
				finish()
			end
		end)
		window._dragCleanup = finish
	end
	local function dragInput(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	header.InputBegan:Connect(function(input)
		if not dragInput(input) then return end
		if window._dragCleanup then window._dragCleanup() end
		moveFrame(header, input, animationRoot.Position, function(position) animationRoot.Position = position end)
	end)
	miniBubble.InputBegan:Connect(function(input)
		if not dragInput(input) then return end
		if window._dragCleanup then window._dragCleanup() end
		moveFrame(miniBubble, input, miniBubble.Position, function(position) miniBubble.Position = position end)
	end)
	minimizeButton.Activated:Connect(function() window:Minimize() end)
	closeButton.Activated:Connect(function() window:Destroy() end)
	miniBubble.Activated:Connect(function() window:Restore() end)
	miniBubble.MouseEnter:Connect(function()
		tween(miniBubble, { BackgroundTransparency = 0 }, 0.14)
		tween(miniAura, { Transparency = 0.64, Thickness = 4 }, 0.16)
	end)
	miniBubble.MouseLeave:Connect(function()
		tween(miniBubble, { BackgroundTransparency = 0.02 }, 0.16)
		tween(miniAura, { Transparency = 0.82, Thickness = 3 }, 0.18)
	end)
	window:SetKeybind(options.Keybind or Enum.KeyCode.RightControl)
	if type(options.Tabs) == "table" then
		for index = 1, #options.Tabs do
			window:Tab(options.Tabs[index])
		end
	end
	if window._tabOrder[1] then window:SelectTab(window._tabOrder[1]) end
	table.insert(Library.Windows, window)
	Library.WindowObject = window
	return window
end

function Library:Notify(titleText, bodyText, duration)
	local currentScreen = screen
	if not currentScreen then return nil end
	local layer = currentScreen:FindFirstChild("Notifications")
	if not layer then
		layer = new("Frame", {
			Name = "Notifications",
			Size = UDim2.new(0, 280, 1, -20),
			Position = UDim2.new(1, -12, 0, 10),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			ZIndex = 150,
		}, currentScreen)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 7), HorizontalAlignment = Enum.HorizontalAlignment.Right }, layer)
	end
	local toast = new("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Palette.row,
		BorderSizePixel = 0,
		LayoutOrder = floor(os.clock() * 1000),
		ZIndex = 151,
	}, layer)
	colorObject(toast, "row", "BackgroundColor3")
	corner(toast, 8)
	stroke(toast, Palette.cyan, 0.8, 0.34, "cyan")
	label(toast, { Size = UDim2.new(1, -20, 0, 21), Position = UDim2.fromOffset(10, 5), Text = tostring(titleText or "FG100"), Font = Enum.Font.FredokaOne, TextSize = 12, ZIndex = 152 }, "white")
	label(toast, { Size = UDim2.new(1, -20, 0, 21), Position = UDim2.fromOffset(10, 28), Text = tostring(bodyText or ""), Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Palette.dim, ZIndex = 152 }, "dim")
	local closed = false
	local function close()
		if closed then return end
		closed = true
		if toast.Parent then tween(toast, { BackgroundTransparency = 1 }, 0.14); task.delay(0.16, function() if toast.Parent then toast:Destroy() end end) end
	end
	task.delay(tonumber(duration) or 3, close)
	return { Close = close, Frame = toast }
end

function Library:Unload()
	for index = #self.Windows, 1, -1 do
		local window = self.Windows[index]
		if window and window.Destroy then window:Destroy() end
	end
	self.Windows = {}
	if screen and screen.Parent then screen:Destroy() end
end

if type(getgenv) == "function" then
	local ok, environment = pcall(getgenv)
	if ok and type(environment) == "table" then
		environment.FG100StyleUI = Library
	end
end

print("[FG100StyleUI] v" .. Library.Version .. " loaded")
return Library
