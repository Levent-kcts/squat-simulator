-- TASARIM SİSTEMİ (client/UIStyle): Theme, panel, header, card, button, label, chip, badge, progressBar, tabs, input, divider, press, pop, countTo, fadeScaleIn/Out, shadow, soften(flat).
-- Her yardımcı kurulur, ClassName/Name doğrulanır, yedeğe (UIStyleFallback) düşülmediği denetlenir; hafif mod (Performance.low) ve bozuk girdi yolları da çalıştırılır.
local S = require("../cstubs")
local UIStyle = require("./UIStyle")
local Performance = require("./Performance")

local function class(instance)
	return rawget(instance, "ClassName")
end
local function findNamed(instance, name)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			return child
		end
		local deeper = findNamed(child, name)
		if deeper then
			return deeper
		end
	end
	return nil
end
local function textsUnder(instance, found)
	found = found or {}
	for _, child in rawget(instance, "_children") do
		if class(child) == "TextLabel" then
			table.insert(found, child.Text)
		end
		textsUnder(child, found)
	end
	return found
end
local function assertReal(instance, what)
	assert(instance, what .. " nil döndü")
	assert(instance:GetAttribute("UIStyleFallback") == nil, what .. " yedeğe düştü")
end
local function click(instance)
	local handlers = rawget(instance, "_handlers")
	assert(handlers and handlers.MouseButton1Click, "MouseButton1Click işleyicisi yok: " .. tostring(rawget(instance, "Name")))
	handlers.MouseButton1Click()
end

local Theme = UIStyle.Theme
-- Theme
assert(type(Theme) == "table", "Theme yok")
for _, key in { "bg", "panel", "panelHigh", "card", "cardHover", "cardDeep", "text", "textDim", "textMute" } do
	assert(Theme.colors[key], "Theme.colors." .. key .. " yok")
end
for _, key in { "primary", "success", "info", "magic", "hot", "danger", "warn" } do
	local accent = Theme.colors[key]
	assert(accent and accent.base and accent.dark and accent.text, "Theme.colors." .. key .. " {base, dark, text} olmalı")
end
local primary = Theme.colors.primary.base
assert(math.floor(primary.R * 255 + 0.5) == 0xFF and math.floor(primary.G * 255 + 0.5) == 0xC8 and math.floor(primary.B * 255 + 0.5) == 0x3D, "primary #FFC83D olmalı")
assert(Theme.fonts.title and Theme.fonts.bold and Theme.fonts.body and Theme.fonts.brand, "Theme.fonts eksik")
assert(Theme.radius.panel == 20 and Theme.radius.card == 14 and Theme.radius.button == 12 and Theme.radius.chip == 8 and Theme.radius.input == 10, "Theme.radius")
assert(#Theme.space == 5 and Theme.space[1] == 4 and Theme.space[5] == 24, "Theme.space 4/8/12/16/24")
for _, key in { "press", "hover", "pop", "panelIn", "panelOut", "count" } do
	assert(Theme.tween[key], "Theme.tween." .. key .. " yok")
end

-- Eski API hâlâ yerinde
for _, name in { "soften", "round", "lighten", "darken", "anchorCenter", "headerIcon", "brickSkin", "petIcon", "safePetIcon", "petModelIcon", "eggModelIcon", "potionIcon" } do
	assert(type(UIStyle[name]) == "function", "eski fonksiyon kayıp: " .. name)
end

-- Yeni API
for _, name in { "panel", "header", "card", "button", "label", "chip", "badge", "progressBar", "tabs", "input", "divider", "press", "pop", "countTo", "fadeScaleIn", "fadeScaleOut", "shadow", "accent" } do
	assert(type(UIStyle[name]) == "function", "yeni fonksiyon yok: " .. name)
end

local function runAll(label)
	local root = S.newInstance("Frame")

	-- panel + gölge
	local panel, shadow = UIStyle.panel(root, { name = "TestPanel", width = 460, height = 520 })
	assertReal(panel, label .. " panel")
	assert(class(panel) == "Frame" and rawget(panel, "Name") == "TestPanel", "panel Frame/Name")
	assert(panel.Active == true and panel.ClipsDescendants == true, "panel Active + ClipsDescendants")
	assert(findNamed(panel, "WidthLimit") and class(findNamed(panel, "WidthLimit")) == "UISizeConstraint", "UISizeConstraint")
	if Performance.low then
		assert(shadow == nil, "hafif modda gölge olmamalı")
	else
		assert(shadow and class(shadow) == "Frame" and rawget(shadow, "Name") == "Shadow", "panel gölgesi")
		assert(shadow.ZIndex < panel.ZIndex, "gölge panelin arkasında")
	end
	local flatPanel, noShadow = UIStyle.panel(root, { size = S.UDim2.new(0, 300, 0, 200), shadow = false })
	assertReal(flatPanel, label .. " panel(size)")
	assert(noShadow == nil, "shadow=false gölge üretmemeli")

	-- header
	local closed = 0
	local head = UIStyle.header(panel, { title = "Shop", subtitle = "Spend your Wins", icon = "", emoji = "S", accent = "primary", chip = "12/50", onClose = function() closed += 1 end })
	assertReal(head.bar, label .. " header")
	assert(class(head.close) == "TextButton" and rawget(head.close, "Name") == "Close", "Close düğmesi")
	assert(head.titleLabel.Text == "SHOP", "başlık büyük harf: " .. tostring(head.titleLabel.Text))
	assert(head.chip and rawget(head.chip, "Name") == "HeaderChip", "header çipi")
	assert(findNamed(head.bar, "HeaderIcon"), "headerIcon çipin içinde")
	click(head.close)
	assert(closed == 1, "Close tıklanınca onClose çağrılmalı")
	UIStyle.setChipText(head.chip, "13/50")
	assert(findNamed(head.chip, "Text").Text == "13/50", "setChipText")
	local bare = UIStyle.header(panel, { title = "Plain" })
	assertReal(bare.bar, label .. " header(ikonsuz)")

	-- card
	local card = UIStyle.card(panel, { name = "Item_1", accent = "magic", selected = true })
	assertReal(card, label .. " card")
	assert(class(card) == "Frame" and rawget(card, "Name") == "Item_1", "card Frame/Name")
	assert(card:GetAttribute("Selected") == true, "seçili kart")
	UIStyle.setCardSelected(card, false)
	assert(card:GetAttribute("Selected") == false, "seçim kalktı")
	assert(findNamed(card, "Padding") and class(findNamed(card, "Padding")) == "UIPadding", "kart UIPadding")

	-- button
	local clicked = 0
	local button = UIStyle.button(panel, { name = "BuyButton", text = "Claim", kind = "success", size = "lg", onClick = function() clicked += 1 end })
	assertReal(button, label .. " button")
	assert(class(button) == "TextButton" and rawget(button, "Name") == "BuyButton", "button gerçek TextButton olmalı")
	local texts = textsUnder(button)
	assert(#texts == 1 and texts[1] == "Claim", "düğme yazısı iç TextLabel'da: " .. table.concat(texts, ","))
	assert(findNamed(button, "Body") and findNamed(button, "Label"), "Body + Label")
	click(button)
	assert(clicked == 1, "onClick çağrılmalı")
	UIStyle.setButtonEnabled(button, false)
	assert(button:GetAttribute("Disabled") == true, "devre dışı öznitelik")
	click(button)
	assert(clicked == 1, "devre dışı düğme onClick çağırmamalı")
	UIStyle.setButtonEnabled(button, true)
	click(button)
	assert(clicked == 2, "tekrar açılınca çalışmalı")
	UIStyle.setButtonText(button, "Done")
	assert(findNamed(button, "Label").Text == "Done", "setButtonText")
	UIStyle.setButtonKind(button, "danger")
	assert(button:GetAttribute("ButtonKind") == "danger", "setButtonKind")
	for _, kind in { "primary", "success", "secondary", "danger", "ghost", "bilinmeyen" } do
		for _, size in { "sm", "md", "lg" } do
			local made = UIStyle.button(panel, { text = kind, kind = kind, size = size, layout = true, icon = "+" })
			assertReal(made, label .. " button " .. kind .. "/" .. size)
			assert(class(made) == "TextButton", "TextButton")
		end
	end
	local iconButton = UIStyle.button(panel, { text = "Go", icon = "rbxassetid://1", disabled = true })
	assertReal(iconButton, label .. " ikonlu düğme")
	assert(class(findNamed(iconButton, "Icon")) == "ImageLabel", "rbxassetid ikonu ImageLabel")

	-- label / chip / badge / divider
	for _, role in { "title", "bold", "body", "caption", "number", "bilinmeyen" } do
		local made = UIStyle.label(panel, { text = role, role = role })
		assertReal(made, label .. " label " .. role)
		assert(class(made) == "TextLabel" and made.Text == role, "label")
	end
	local chip = UIStyle.chip(panel, { text = "OWNED", accent = "success", icon = "rbxassetid://2" })
	assertReal(chip, label .. " chip")
	assert(class(chip) == "Frame" and class(findNamed(chip, "Icon")) == "ImageLabel", "chip")
	local badge = UIStyle.badge(panel, { text = 3 })
	assertReal(badge, label .. " badge")
	assert(findNamed(badge, "Count").Text == "3", "rozet sayısı")
	UIStyle.setBadge(badge, "9+")
	assert(findNamed(badge, "Count").Text == "9+", "setBadge")
	local divider = UIStyle.divider(panel)
	assertReal(divider, label .. " divider")
	assert(class(divider) == "Frame" and rawget(divider, "Name") == "Divider", "divider")

	-- progressBar
	local bar = UIStyle.progressBar(panel, { accent = "info", value = 0.4, text = "40%" })
	assertReal(bar.frame, label .. " progressBar")
	assert(type(bar.set) == "function" and bar.label.Text == "40%", "progressBar")
	bar.set(1.7, "MAX")
	bar.set(-3)
	assert(bar.label.Text == "MAX", "progressBar.set yazıyı günceller")

	-- tabs
	local picked = nil
	local tabs = UIStyle.tabs(panel, { items = { "DAILY", { id = "new", text = "NEW PLAYER" } }, accent = "info", onSelect = function(id) picked = id end })
	assertReal(tabs.frame, label .. " tabs")
	assert(tabs.current() == "DAILY", "ilk sekme seçili")
	assert(class(tabs.buttons.new) == "TextButton" and rawget(tabs.buttons.new, "Name") == "Tab_new", "Tab_<id>")
	click(tabs.buttons.new)
	assert(picked == "new" and tabs.current() == "new", "sekme seçimi")

	-- input
	local box, frame = UIStyle.input(panel, { placeholder = "Enter code" })
	assertReal(frame, label .. " input")
	assert(class(box) == "TextBox" and box.PlaceholderText == "Enter code", "input TextBox")

	-- animasyonlar
	local target = S.newInstance("Frame")
	UIStyle.press(target)
	UIStyle.press(target) -- ikinci çağrı bir şey değiştirmez
	UIStyle.pop(target)
	assert(findNamed(target, "PressScale") and findNamed(target, "PopScale"), "UIScale çocukları")
	local counter = S.newInstance("TextLabel")
	UIStyle.countTo(counter, 0, 1500, function(value) return "W" .. math.floor(value) end)
	if Performance.low then
		assert(counter.Text == "W1500", "hafif modda sayma hemen biter: " .. tostring(counter.Text))
	else
		assert(counter.Text == "W0", "sayma başlangıç değerinden başlar: " .. tostring(counter.Text))
		for _, entry in S.delayed do
			entry[2]()
		end
		assert(counter.Text == "W1500", "sayma son değerde biter: " .. tostring(counter.Text))
	end
	local modal = S.newInstance("Frame")
	modal.Visible = false
	UIStyle.fadeScaleIn(modal)
	assert(modal.Visible == true and findNamed(modal, "ModalScale"), "fadeScaleIn")
	local done = false
	UIStyle.fadeScaleOut(modal, function() done = true end)
	if not Performance.low then
		for _, entry in S.delayed do
			entry[2]()
		end
	end
	assert(modal.Visible == false and done, "fadeScaleOut kapatır ve onDone çağırır")

	-- soften flat + eski varsayılan
	local flat = S.newInstance("Frame")
	UIStyle.soften(flat, { style = "flat" })
	assert(not findNamed(flat, "Shine"), "flat: parlak şerit olmamalı")
	assert(flat:FindFirstChildOfClass("UIStroke") and flat:FindFirstChildOfClass("UIStroke").Thickness == 1, "flat: 1 px çerçeve")
	local old = S.newInstance("Frame")
	UIStyle.soften(old, { radius = 8 })
	assert(findNamed(old, "Shine"), "eski varsayılan: parlak şerit kalmalı")

	-- bozuk girdi çökertmemeli
	local ok = pcall(function()
		UIStyle.panel(nil, nil)
		UIStyle.card(nil, nil)
		UIStyle.button(nil, nil)
		UIStyle.button(root, { text = nil, kind = 5 })
		UIStyle.header(nil, nil)
		UIStyle.label(nil, nil)
		UIStyle.chip(nil, nil)
		UIStyle.badge(nil, nil)
		UIStyle.progressBar(nil, nil)
		UIStyle.tabs(nil, nil)
		UIStyle.input(nil, nil)
		UIStyle.divider(nil, nil)
		UIStyle.press(nil)
		UIStyle.pop(nil)
		UIStyle.countTo(nil, 0, 1)
		UIStyle.fadeScaleIn(nil)
		UIStyle.fadeScaleOut(nil)
		UIStyle.shadow(S.newInstance("Frame"))
		UIStyle.accent(nil)
		UIStyle.accent("yok")
	end)
	assert(ok, label .. ": bozuk girdi hata fırlattı")
	assert(UIStyle.accent("hot") == Theme.colors.hot and UIStyle.accent("yok") == Theme.colors.primary, "accent çözümü")
end

runAll("normal")
Performance.low = true
runAll("hafif")
Performance.low = false
print("uistyletest ok")
