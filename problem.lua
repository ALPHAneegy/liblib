--[[
    ENCHANTED HUB UI  |  visual recreation, v1.0.0
    Estilo basado en referencias publicas de Enchanted Hub para Muscle Legends:
    panel burdeos compacto, barra lateral de categorias y controles en tarjetas.
    Libreria visual de un solo archivo; los callbacks quedan a cargo del usuario.

    Carga local:
        ModuleScript: local Enchanted = require(script.Parent.EnchantedHubUI)
        Executor:     local Enchanted = loadfile("EnchantedHubUI.lua")()
        Alternativa:  local Enchanted = loadstring(readfile("EnchantedHubUI.lua"))()

    Ejemplo:
        local window = Enchanted:CreateWindow()
        local tab = window:AddTab("Auto Farm", "♧")
        local section = tab:AddSection("Main Options")
        section:AddToggle("Fast Punch", { Description = "Training option", Callback = function(on) end })
        section:AddSlider("Power", { Min = 0, Max = 100, Default = 50, Suffix = "%" })
        section:AddDropdown("Location", { Options = { "Tiny Island", "Starter Island" } })
        window:SetKeybind(Enum.KeyCode.RightControl)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local floor, min, max = math.floor, math.min, math.max

local Colors = {
	Background = Color3.fromRGB(44, 5, 8),
	Sidebar = Color3.fromRGB(55, 7, 10),
	Panel = Color3.fromRGB(69, 8, 12),
	Card = Color3.fromRGB(83, 11, 16),
	CardHover = Color3.fromRGB(100, 16, 22),
	Selected = Color3.fromRGB(101, 17, 22),
	Accent = Color3.fromRGB(220, 47, 58),
	AccentSoft = Color3.fromRGB(152, 34, 42),
	Border = Color3.fromRGB(129, 32, 39),
	Text = Color3.fromRGB(248, 239, 238),
	Muted = Color3.fromRGB(195, 164, 165),
	Dim = Color3.fromRGB(132, 101, 104),
}

local function clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

local function copy(source)
	local result = {}
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end

local function optionsFor(nameOrOptions, extra)
	if type(nameOrOptions) == "string" then
		local result = { Name = nameOrOptions }
		if type(extra) == "table" then
			for key, value in pairs(extra) do
				result[key] = value
			end
			result.Name = nameOrOptions
		elseif type(extra) == "function" then
			result.Callback = extra
		end
		return result
	elseif type(nameOrOptions) == "table" then
		local result = copy(nameOrOptions)
		if type(extra) == "function" then
			result.Callback = result.Callback or extra
		end
		return result
	elseif type(extra) == "table" then
		return copy(extra)
	elseif type(extra) == "function" then
		return { Callback = extra }
	end
	return {}
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

local function rounded(object, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius or 5) }, object)
	return object
end

local function bordered(object, color, transparency)
	return new("UIStroke", {
		Color = color or Colors.Border,
		Thickness = 1,
		Transparency = transparency == nil and 0.25 or transparency,
	}, object)
end

local function text(parent, properties)
	properties = properties or {}
	properties.BackgroundTransparency = 1
	properties.Font = properties.Font or Enum.Font.GothamMedium
	properties.TextSize = properties.TextSize or 13
	properties.TextColor3 = properties.TextColor3 or Colors.Text
	if properties.TextXAlignment == nil then
		properties.TextXAlignment = Enum.TextXAlignment.Left
	end
	return new("TextLabel", properties, parent)
end

local function button(parent, properties)
	properties = properties or {}
	properties.AutoButtonColor = false
	properties.BorderSizePixel = 0
	properties.Font = properties.Font or Enum.Font.GothamMedium
	properties.TextSize = properties.TextSize or 13
	properties.TextColor3 = properties.TextColor3 or Colors.Text
	properties.BackgroundColor3 = properties.BackgroundColor3 or Colors.Card
	return new("TextButton", properties, parent)
end

local function animate(object, properties, duration)
	local tween = TweenService:Create(
		object,
		TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		properties
	)
	tween:Play()
	return tween
end

local function formatNumber(value)
	if value % 1 == 0 then
		return tostring(value)
	end
	local valueText = string.format("%.2f", value):gsub("0+$", "")
	return valueText:gsub("%.$", "")
end

local function getGuiParent()
	if Player then
		local ok, playerGui = pcall(function()
			return Player:FindFirstChildOfClass("PlayerGui") or Player:WaitForChild("PlayerGui", 8)
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

local guiParent = getGuiParent()
assert(guiParent, "EnchantedHubUI necesita PlayerGui o CoreGui")

local previous = guiParent:FindFirstChild("EnchantedHubUI")
if previous then
	previous:Destroy()
end

local screen = new("ScreenGui", {
	Name = "EnchantedHubUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 650,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local toastContainer = new("Frame", {
	Name = "Notifications",
	Size = UDim2.new(0, 300, 1, -24),
	Position = UDim2.new(1, -16, 0, 12),
	AnchorPoint = Vector2.new(1, 0),
	BackgroundTransparency = 1,
	ZIndex = 60,
}, screen)
new("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 7),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
}, toastContainer)

local Library = {
	Version = "1.0.0",
	Name = "Enchanted Hub UI",
	Config = Colors,
	Windows = {},
}

local function createControlApi(frame)
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

local buildControl

local function addControlMethods(target, getSection)
	local kinds = { "Button", "Toggle", "Slider", "Dropdown", "Input", "Label", "Keybind" }
	for index = 1, #kinds do
		local kind = kinds[index]
		target["Add" .. kind] = function(_, nameOrOptions, extra)
			return buildControl(kind, getSection(), nameOrOptions, extra)
		end
	end
	return target
end

local function makeSection(tab, sectionName)
	local sectionFrame = new("Frame", {
		Name = "Section",
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = tab._sectionOrder,
	}, tab.Page)
	tab._sectionOrder = tab._sectionOrder + 1

	local heading = text(sectionFrame, {
		Size = UDim2.new(1, -8, 0, 19),
		Position = UDim2.fromOffset(2, 0),
		Text = string.upper(tostring(sectionName or "OPTIONS")),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Colors.Muted,
	})
	local underline = new("Frame", {
		Size = UDim2.new(1, -6, 0, 1),
		Position = UDim2.fromOffset(2, 21),
		BackgroundColor3 = Colors.Border,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
	}, sectionFrame)

	local body = new("Frame", {
		Name = "Items",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 29),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, sectionFrame)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 7),
	}, body)
	new("UIPadding", { PaddingBottom = UDim.new(0, 8) }, body)

	local section = {
		Name = tostring(sectionName or "OPTIONS"),
		Frame = sectionFrame,
		Heading = heading,
		Underline = underline,
		Body = body,
		Window = tab.Window,
		_order = 0,
	}
	addControlMethods(section, function()
		return section
	end)
	return section
end

local function makeRow(section, height, cardStyle)
	section._order = section._order + 1
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = cardStyle == false and Colors.Panel or Colors.Card,
		BackgroundTransparency = cardStyle == false and 1 or 0,
		BorderSizePixel = 0,
		LayoutOrder = section._order,
	}, section.Body)
	if cardStyle ~= false then
		rounded(row, 5)
		bordered(row, Colors.Border, 0.52)
	end
	return row
end

local function addTextAndDescription(row, settings, titleWidth)
	text(row, {
		Size = UDim2.new(1, titleWidth or -82, 0, 19),
		Position = UDim2.fromOffset(12, settings.Description and 6 or 0),
		Text = tostring(settings.Name or "Option"),
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextYAlignment = settings.Description and Enum.TextYAlignment.Bottom or Enum.TextYAlignment.Center,
	})
	if settings.Description and tostring(settings.Description) ~= "" then
		text(row, {
			Size = UDim2.new(1, titleWidth or -82, 0, 16),
			Position = UDim2.fromOffset(12, 26),
			Text = tostring(settings.Description),
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextColor3 = Colors.Muted,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
end

local function makeToggle(section, settings)
	local row = makeRow(section, settings.Description and 51 or 40)
	addTextAndDescription(row, settings, -75)
	local track = button(row, {
		Size = UDim2.fromOffset(42, 21),
		Position = UDim2.new(1, -54, 0.5, -10),
		Text = "",
		BackgroundColor3 = Colors.Panel,
	})
	rounded(track, 11)
	bordered(track, Colors.Border, 0.25)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(13, 13),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 11, 0.5, 0),
		BackgroundColor3 = Colors.Muted,
		BorderSizePixel = 0,
	}, track)
	rounded(knob, 7)

	local value = settings.Default and true or false
	local api = createControlApi(row)
	local function render(shouldAnimate)
		local position = value and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
		local trackColor = value and Colors.AccentSoft or Colors.Panel
		local knobColor = value and Colors.Text or Colors.Muted
		if shouldAnimate then
			animate(track, { BackgroundColor3 = trackColor }, 0.12)
			animate(knob, { Position = position, BackgroundColor3 = knobColor }, 0.12)
		else
			track.BackgroundColor3 = trackColor
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

local function makeButton(section, settings)
	local row = makeRow(section, 39)
	local action = button(row, {
		Size = UDim2.fromScale(1, 1),
		Text = "",
		BackgroundTransparency = 1,
	})
	local actionLabel = text(action, {
		Size = UDim2.new(1, -35, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Text = tostring(settings.Name or "Button"),
		TextSize = 12,
	})
	text(action, {
		Size = UDim2.fromOffset(20, 28),
		Position = UDim2.new(1, -28, 0.5, -14),
		Text = "›",
		TextColor3 = Colors.Muted,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local api = createControlApi(row)
	action.MouseEnter:Connect(function()
		animate(row, { BackgroundColor3 = Colors.CardHover })
	end)
	action.MouseLeave:Connect(function()
		animate(row, { BackgroundColor3 = Colors.Card })
	end)
	action.Activated:Connect(function()
		if settings.Callback then
			settings.Callback(api)
		end
	end)
	function api:SetText(value)
		actionLabel.Text = tostring(value or "")
	end
	return api
end

local function makeSlider(section, settings)
	local minimum = tonumber(settings.Min) or 0
	local maximum = tonumber(settings.Max) or 100
	if maximum <= minimum then
		maximum = minimum + 1
	end
	local step = tonumber(settings.Step) or 1
	local suffix = tostring(settings.Suffix or "")
	local value = clamp(tonumber(settings.Default) or minimum, minimum, maximum)
	local row = makeRow(section, 62)
	if settings.Description then
		addTextAndDescription(row, settings, -90)
	else
		text(row, {
			Size = UDim2.new(1, -95, 0, 20),
			Position = UDim2.fromOffset(12, 4),
			Text = tostring(settings.Name or "Slider"),
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end
	local valueLabel = text(row, {
		Size = UDim2.new(0, 72, 0, 18),
		Position = UDim2.new(1, -84, 0, 5),
		Text = "",
		Font = Enum.Font.Code,
		TextSize = 11,
		TextColor3 = Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = new("Frame", {
		Size = UDim2.new(1, -24, 0, 5),
		Position = UDim2.fromOffset(12, 43),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		Active = true,
	}, row)
	rounded(track, 3)
	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Colors.Accent,
		BorderSizePixel = 0,
	}, track)
	rounded(fill, 3)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(11, 11),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Colors.Text,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, track)
	rounded(knob, 6)
	bordered(knob, Colors.Accent, 0.12)
	local hitbox = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.fromOffset(0, 33),
		BackgroundTransparency = 1,
		Text = "",
		Active = true,
		ZIndex = 4,
	}, row)
	local api = createControlApi(row)
	local function render(shouldAnimate)
		local ratio = clamp((value - minimum) / (maximum - minimum), 0, 1)
		valueLabel.Text = formatNumber(value) .. suffix
		local fillSize = UDim2.new(ratio, 0, 1, 0)
		local knobPosition = UDim2.new(ratio, 0, 0.5, 0)
		if shouldAnimate then
			animate(fill, { Size = fillSize }, 0.1)
			animate(knob, { Position = knobPosition }, 0.1)
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
	local function xToValue(x)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return value
		end
		return minimum + clamp((x - track.AbsolutePosition.X) / width, 0, 1) * (maximum - minimum)
	end
	local function xPosition(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			return input.Position.X
		end
		return UserInputService:GetMouseLocation().X
	end
	local function startDrag(input)
		setValue(xToValue(xPosition(input)), true)
		local touch = input.UserInputType == Enum.UserInputType.Touch
		local moveConnection = UserInputService.InputChanged:Connect(function(changed)
			if (touch and changed.UserInputType == Enum.UserInputType.Touch)
				or (not touch and changed.UserInputType == Enum.UserInputType.MouseMovement) then
				setValue(xToValue(xPosition(changed)), true)
			end
		end)
		local endConnection = UserInputService.InputEnded:Connect(function(ended)
			if (touch and ended.UserInputType == Enum.UserInputType.Touch)
				or (not touch and ended.UserInputType == Enum.UserInputType.MouseButton1) then
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
			startDrag(input)
		end
	end)
	render(false)
	function api:SetValue(newValue)
		setValue(newValue, false)
	end
	function api:GetValue()
		return value
	end
	return api
end

local function makeDropdown(section, settings)
	local choices = settings.Options or { "Option 1", "Option 2" }
	local selected = settings.Default or choices[1]
	local row = makeRow(section, 42, false)
	local control = button(row, {
		Size = UDim2.new(1, 0, 0, 36),
		Text = "",
		BackgroundColor3 = Colors.Card,
	})
	rounded(control, 5)
	bordered(control, Colors.Border, 0.48)
	text(control, {
		Size = UDim2.new(0.5, -10, 1, 0),
		Position = UDim2.fromOffset(11, 0),
		Text = tostring(settings.Name or "Dropdown"),
		TextSize = 12,
		TextColor3 = Colors.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local current = text(control, {
		Size = UDim2.new(0.5, -35, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Text = tostring(selected or "Select"),
		TextSize = 11,
		Font = Enum.Font.Code,
		TextColor3 = Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local arrow = text(control, {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -26, 0.5, -10),
		Text = "⌄",
		TextColor3 = Colors.Accent,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local menu = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, min(#choices, 5) * 26 + 4),
		Position = UDim2.fromOffset(0, 40),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Colors.Accent,
		CanvasSize = UDim2.new(0, 0, 0, #choices * 27),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 12,
	}, row)
	rounded(menu, 5)
	bordered(menu, Colors.Border, 0.18)
	new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1) }, menu)
	local api = createControlApi(row)
	local open = false
	local itemButtons = {}
	local menuHeight = min(#choices, 5) * 26 + 4
	local function closeMenu()
		if not open then
			return
		end
		open = false
		menu.Visible = false
		row.Size = UDim2.new(1, 0, 0, 42)
		arrow.Text = "⌄"
	end
	local function setValue(value, callCallback)
		selected = value
		current.Text = tostring(value or "")
		for index = 1, #itemButtons do
			itemButtons[index].TextColor3 = tostring(choices[index]) == tostring(selected) and Colors.Accent or Colors.Text
		end
		if callCallback and settings.Callback then
			settings.Callback(selected)
		end
	end
	local function refreshItems()
		for index = #itemButtons, 1, -1 do
			itemButtons[index]:Destroy()
			itemButtons[index] = nil
		end
		for index = 1, #choices do
			local optionValue = choices[index]
			local item = button(menu, {
				Size = UDim2.new(1, -4, 0, 25),
				LayoutOrder = index,
				Text = tostring(optionValue),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = tostring(optionValue) == tostring(selected) and Colors.Accent or Colors.Text,
				BackgroundTransparency = 1,
				ZIndex = 13,
			})
			item.Parent = menu
			new("UIPadding", { PaddingLeft = UDim.new(0, 9) }, item)
			item.Activated:Connect(function()
				setValue(optionValue, true)
				closeMenu()
			end)
			table.insert(itemButtons, item)
		end
		menuHeight = min(#choices, 5) * 26 + 4
		menu.Size = UDim2.new(1, 0, 0, menuHeight)
		menu.CanvasSize = UDim2.new(0, 0, 0, #choices * 27)
	end
	control.Activated:Connect(function()
		open = not open
		menu.Visible = open
		row.Size = UDim2.new(1, 0, 0, open and (42 + menuHeight) or 42)
		arrow.Text = open and "⌃" or "⌄"
	end)
	refreshItems()
	function api:SetValue(value)
		setValue(value, false)
	end
	function api:GetValue()
		return selected
	end
	function api:SetOptions(newOptions)
		choices = newOptions or {}
		if #choices == 0 then
			selected = nil
		elseif selected == nil then
			selected = choices[1]
		end
		refreshItems()
		if open then
			row.Size = UDim2.new(1, 0, 0, 42 + menuHeight)
		end
	end
	function api:Close()
		closeMenu()
	end
	if section.Window then
		local windows = section.Window._dropdowns
		table.insert(windows, api)
		api:AddCleanup(function()
			for index = #windows, 1, -1 do
				if windows[index] == api then
					table.remove(windows, index)
				end
			end
		end)
	end
	api:AddCleanup(closeMenu)
	return api
end

local function makeInput(section, settings)
	local row = makeRow(section, 58)
	text(row, {
		Size = UDim2.new(1, -18, 0, 17),
		Position = UDim2.fromOffset(11, 3),
		Text = string.upper(tostring(settings.Name or "INPUT")),
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextColor3 = Colors.Muted,
	})
	local box = new("TextBox", {
		Size = UDim2.new(1, -18, 0, 27),
		Position = UDim2.fromOffset(9, 25),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		Text = tostring(settings.Default or ""),
		PlaceholderText = tostring(settings.Placeholder or "Enter a value..."),
		PlaceholderColor3 = Colors.Dim,
		TextColor3 = Colors.Text,
		TextSize = 11,
		Font = Enum.Font.Code,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		MultiLine = false,
	}, row)
	rounded(box, 4)
	local border = bordered(box, Colors.Border, 0.48)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}, box)
	local api = createControlApi(row)
	box.Focused:Connect(function()
		animate(border, { Color = Colors.Accent, Transparency = 0.05 }, 0.1)
	end)
	box.FocusLost:Connect(function(enterPressed)
		animate(border, { Color = Colors.Border, Transparency = 0.48 }, 0.1)
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

local function makeLabel(section, settings)
	local row = makeRow(section, tonumber(settings.Height) or 25, false)
	local label = text(row, {
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.fromOffset(5, 0),
		Text = tostring(settings.Text or settings.Name or "Label"),
		Font = Enum.Font.Gotham,
		TextSize = tonumber(settings.TextSize) or 11,
		TextColor3 = settings.Color or Colors.Muted,
		TextWrapped = true,
	})
	local api = createControlApi(row)
	function api:SetValue(value)
		label.Text = tostring(value or "")
	end
	function api:GetValue()
		return label.Text
	end
	return api
end

local function makeKeybind(section, settings)
	local row = makeRow(section, 39)
	text(row, {
		Size = UDim2.new(1, -112, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		Text = tostring(settings.Name or "Keybind"),
		TextSize = 12,
	})
	local keyButton = button(row, {
		Size = UDim2.fromOffset(92, 26),
		Position = UDim2.new(1, -104, 0.5, -13),
		Text = "",
		BackgroundColor3 = Colors.Panel,
		TextColor3 = Colors.Accent,
		Font = Enum.Font.Code,
		TextSize = 10,
	})
	rounded(keyButton, 4)
	bordered(keyButton, Colors.Border, 0.45)
	local key = settings.Key or Enum.KeyCode.Unknown
	local waiting = false
	local api = createControlApi(row)
	local function updateText()
		if waiting then
			keyButton.Text = "PRESS KEY"
		elseif key == Enum.KeyCode.Unknown then
			keyButton.Text = "NONE"
		else
			keyButton.Text = key.Name
		end
	end
	keyButton.Activated:Connect(function()
		if waiting then
			return
		end
		waiting = true
		updateText()
		local connection
		connection = UserInputService.InputBegan:Connect(function(input, processed)
			if processed or UserInputService:GetFocusedTextBox() then
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				key = input.KeyCode
				waiting = false
				connection:Disconnect()
				updateText()
				if settings.Callback then
					settings.Callback(key)
				end
			end
		end)
		api:AddCleanup(function()
			if connection then
				connection:Disconnect()
			end
		end)
	end)
	function api:SetValue(value)
		key = value or Enum.KeyCode.Unknown
		updateText()
	end
	function api:GetValue()
		return key
	end
	updateText()
	return api
end

buildControl = function(kind, section, nameOrOptions, extra)
	local settings = optionsFor(nameOrOptions, extra)
	if kind == "Button" then
		return makeButton(section, settings)
	elseif kind == "Toggle" then
		return makeToggle(section, settings)
	elseif kind == "Slider" then
		return makeSlider(section, settings)
	elseif kind == "Dropdown" then
		return makeDropdown(section, settings)
	elseif kind == "Input" then
		return makeInput(section, settings)
	elseif kind == "Label" then
		return makeLabel(section, settings)
	elseif kind == "Keybind" then
		return makeKeybind(section, settings)
	end
	return nil
end

local function inputPosition(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		return input.Position
	end
	return UserInputService:GetMouseLocation()
end

function Library:CreateWindow(nameOrOptions, extra)
	local settings = optionsFor(nameOrOptions, extra)
	local width = tonumber(settings.Width) or 590
	local height = tonumber(settings.Height) or 360
	local sidebarWidth = tonumber(settings.SidebarWidth) or 190
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local offset = #self.Windows * 18
	local window = {
		_tabs = {},
		_dropdowns = {},
		_connections = {},
		_sectionCount = 0,
		_destroyed = false,
	}

	local frame = new("Frame", {
		Name = "EnchantedWindow",
		Size = UDim2.fromOffset(width, height),
		Position = UDim2.fromOffset((viewport.X - width) / 2 + offset, (viewport.Y - height) / 2 + offset),
		BackgroundColor3 = Colors.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
	}, screen)
	window.Frame = frame
	rounded(frame, 5)
	bordered(frame, Colors.AccentSoft, 0.12)

	local topbar = new("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 29),
		BackgroundColor3 = Colors.Background,
		BorderSizePixel = 0,
		Active = true,
	}, frame)
	local title = text(topbar, {
		Size = UDim2.new(1, -86, 1, 0),
		Position = UDim2.fromOffset(9, 0),
		Text = tostring(settings.Title or "Enchanted Hub | Muscle Legends | v1.0.0 PC Version || By iblameaabis"),
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = Colors.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local hideButton = button(topbar, {
		Size = UDim2.fromOffset(20, 19),
		Position = UDim2.new(1, -48, 0.5, -9),
		Text = "□",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Colors.Muted,
		BackgroundColor3 = Colors.Card,
	})
	rounded(hideButton, 3)
	bordered(hideButton, Colors.Border, 0.5)
	local closeButton = button(topbar, {
		Size = UDim2.fromOffset(20, 19),
		Position = UDim2.new(1, -24, 0.5, -9),
		Text = "×",
		Font = Enum.Font.Gotham,
		TextSize = 15,
		TextColor3 = Colors.Muted,
		BackgroundColor3 = Colors.Card,
	})
	rounded(closeButton, 3)
	bordered(closeButton, Colors.Border, 0.5)

	local shell = new("Frame", {
		Name = "Shell",
		Size = UDim2.new(1, 0, 1, -29),
		Position = UDim2.fromOffset(0, 29),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
	}, frame)

	local sidebar = new("Frame", {
		Name = "Navigation",
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		BackgroundColor3 = Colors.Sidebar,
		BorderSizePixel = 0,
	}, shell)
	local navList = new("ScrollingFrame", {
		Name = "CategoryList",
		Size = UDim2.new(1, -10, 1, -34),
		Position = UDim2.fromOffset(5, 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Colors.AccentSoft,
	}, sidebar)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 3),
		PaddingRight = UDim.new(0, 3),
		PaddingBottom = UDim.new(0, 4),
	}, navList)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
	}, navList)
	local navFooter = text(sidebar, {
		Size = UDim2.new(1, -16, 0, 15),
		Position = UDim2.new(0, 10, 1, -20),
		Text = tostring(settings.Footer or "ENCHANTED  /  ML"),
		Font = Enum.Font.Code,
		TextSize = 8,
		TextColor3 = Colors.Dim,
	})
	local sidebarLine = new("Frame", {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = Colors.Border,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
	}, sidebar)

	local pageHost = new("Frame", {
		Name = "PageHost",
		Size = UDim2.new(1, -sidebarWidth, 1, 0),
		Position = UDim2.new(0, sidebarWidth, 0, 0),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
	}, shell)
	window.Content = pageHost

	local dock = button(screen, {
		Name = "EnchantedReopen",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(1, -18, 1, -20),
		AnchorPoint = Vector2.new(1, 1),
		Text = "E",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Colors.Text,
		BackgroundColor3 = Colors.AccentSoft,
		Visible = false,
		ZIndex = 30,
	})
	rounded(dock, 5)
	bordered(dock, Colors.Accent, 0.05)
	window.Dock = dock

	local function closeDropdowns()
		for index = 1, #window._dropdowns do
			local dropdown = window._dropdowns[index]
			if dropdown and dropdown.Close then
				dropdown:Close()
			end
		end
	end

	function window:AddTab(name, icon)
		local tabIndex = #self._tabs + 1
	local page = new("ScrollingFrame", {
			Name = "Page_" .. tostring(name),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Colors.AccentSoft,
		Visible = false,
	}, pageHost)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 15),
			PaddingBottom = UDim.new(0, 15),
		}, page)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 11),
	}, page)
	local pageHeading = text(page, {
		Name = "PageHeading",
		Size = UDim2.new(1, -6, 0, 34),
		Text = tostring(name),
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		TextColor3 = Colors.Text,
		LayoutOrder = 0,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

		local navButton = button(navList, {
			Size = UDim2.new(1, 0, 0, 34),
			Text = "",
			BackgroundColor3 = Colors.Selected,
			BackgroundTransparency = 1,
			LayoutOrder = tabIndex,
		})
		rounded(navButton, 4)
		local navIndicator = new("Frame", {
			Size = UDim2.new(0, 3, 1, -12),
			Position = UDim2.fromOffset(0, 6),
			BackgroundColor3 = Colors.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, navButton)
		rounded(navIndicator, 2)
		text(navButton, {
			Size = UDim2.fromOffset(23, 26),
			Position = UDim2.fromOffset(10, 4),
			Text = tostring(icon or "◈"),
			TextSize = 15,
			TextColor3 = Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		local navLabel = text(navButton, {
			Size = UDim2.new(1, -48, 1, 0),
			Position = UDim2.fromOffset(40, 0),
			Text = tostring(name),
			TextSize = 12,
			TextColor3 = Colors.Muted,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local tab = {
		Name = tostring(name),
		Icon = tostring(icon or "◈"),
		Window = window,
		Page = page,
		Heading = pageHeading,
			Button = navButton,
			Label = navLabel,
			Indicator = navIndicator,
		_sectionOrder = 1,
		}
		table.insert(self._tabs, { Tab = tab })

		function tab:AddSection(sectionName)
			return makeSection(self, sectionName)
		end
		function tab:_DefaultSection()
			if not self._defaultSection then
				self._defaultSection = makeSection(self, "OPTIONS")
			end
			return self._defaultSection
		end
		addControlMethods(tab, function()
			return tab:_DefaultSection()
		end)
		function tab:Select()
			window:SelectTab(self)
		end
		function tab:SetName(newName)
			self.Name = tostring(newName)
			self.Label.Text = self.Name
			self.Heading.Text = self.Name
		end
		navButton.Activated:Connect(function()
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
			animate(current.Button, {
				BackgroundTransparency = active and 0 or 1,
			})
			animate(current.Label, {
				TextColor3 = active and Colors.Text or Colors.Muted,
			})
			animate(current.Indicator, {
				BackgroundTransparency = active and 0 or 1,
			})
		end
		self._activeTab = tab
	end

	function window:SetTitle(newTitle)
		title.Text = tostring(newTitle or "")
	end
	function window:SetVisible(visible)
		frame.Visible = visible and true or false
		dock.Visible = not frame.Visible
		if not frame.Visible then
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
		local size = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		frame.Position = UDim2.fromOffset((size.X - width) / 2, (size.Y - height) / 2)
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
		if self._dragCleanup then
			self._dragCleanup()
			self._dragCleanup = nil
		end
		for index = #self._dropdowns, 1, -1 do
			local dropdown = self._dropdowns[index]
			if dropdown and dropdown.Destroy then
				dropdown:Destroy()
			end
		end
		for index = #Library.Windows, 1, -1 do
			if Library.Windows[index] == self then
				table.remove(Library.Windows, index)
			end
		end
		if frame.Parent then frame:Destroy() end
		if dock.Parent then dock:Destroy() end
	end

	local function finishDrag()
		if window._dragCleanup then
			window._dragCleanup()
			window._dragCleanup = nil
		end
	end
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		finishDrag()
		local touch = input.UserInputType == Enum.UserInputType.Touch
		local startPointer = inputPosition(input)
		local startFrame = frame.Position
		local moveConnection = UserInputService.InputChanged:Connect(function(changed)
			if (touch and changed.UserInputType == Enum.UserInputType.Touch)
				or (not touch and changed.UserInputType == Enum.UserInputType.MouseMovement) then
				local delta = inputPosition(changed) - startPointer
				frame.Position = UDim2.new(
					startFrame.X.Scale,
					startFrame.X.Offset + delta.X,
					startFrame.Y.Scale,
					startFrame.Y.Offset + delta.Y
				)
			end
		end)
		local endConnection = UserInputService.InputEnded:Connect(function(ended)
			if (touch and ended.UserInputType == Enum.UserInputType.Touch)
				or (not touch and ended.UserInputType == Enum.UserInputType.MouseButton1) then
				finishDrag()
			end
		end)
		window._dragCleanup = function()
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
	window:SetKeybind(settings.Keybind or Enum.KeyCode.RightControl)

	table.insert(self.Windows, window)
	return window
end

local function defer(seconds, callback)
	if type(task) == "table" and type(task.delay) == "function" then
		task.delay(seconds, callback)
	else
		spawn(function()
			wait(seconds)
			callback()
		end)
	end
end

function Library:Notify(nameOrOptions, message)
	local settings
	if type(nameOrOptions) == "string" then
		settings = { Title = nameOrOptions, Text = message }
	else
		settings = nameOrOptions or {}
	end
	local toast = new("Frame", {
		Size = UDim2.new(1, 0, 0, 61),
		BackgroundColor3 = Colors.Panel,
		BorderSizePixel = 0,
		LayoutOrder = floor(os.clock() * 1000),
		ZIndex = 61,
	}, toastContainer)
	rounded(toast, 5)
	bordered(toast, Colors.Border, 0.2)
	local stripe = new("Frame", {
		Size = UDim2.new(0, 3, 1, -14),
		Position = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Colors.Accent,
		BorderSizePixel = 0,
		ZIndex = 62,
	}, toast)
	rounded(stripe, 2)
	text(toast, {
		Size = UDim2.new(1, -28, 0, 19),
		Position = UDim2.fromOffset(17, 7),
		Text = tostring(settings.Title or "Enchanted Hub"),
		TextSize = 12,
		ZIndex = 62,
	})
	text(toast, {
		Size = UDim2.new(1, -28, 0, 24),
		Position = UDim2.fromOffset(17, 29),
		Text = tostring(settings.Text or ""),
		TextSize = 10,
		TextColor3 = Colors.Muted,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 62,
	})
	local closed = false
	local function close()
		if closed then return end
		closed = true
		if toast.Parent then
			animate(toast, { BackgroundTransparency = 1 }, 0.12)
			defer(0.14, function()
				if toast.Parent then toast:Destroy() end
			end)
		end
	end
	defer(tonumber(settings.Duration) or 3, close)
	return { Close = close, Frame = toast }
end

function Library:Unload()
	for index = #self.Windows, 1, -1 do
		self.Windows[index]:Destroy()
	end
	if screen and screen.Parent then
		screen:Destroy()
	end
end

if type(getgenv) == "function" then
	local ok, environment = pcall(getgenv)
	if ok and type(environment) == "table" then
		environment.EnchantedUI = Library
	end
end

print("[EnchantedHubUI] v" .. Library.Version .. " loaded")
return Library
