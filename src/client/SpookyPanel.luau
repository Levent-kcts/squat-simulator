-- SEZONLUK ETKİNLİK penceresi: SPOOKY GYM (Config.Event; server/SeasonEvent). Üstte Candy sayısı + kalan süre, ortada Candy kilometre taşları (CLAIM), altta DETERMİNİSTİK etkinlik mağazası (rastgele ürün yok).
-- Durum sunucudan öznitelik olarak gelir: Candy, CandyTotal, EventClaimed ('1,2'), EventBought ('rainbow:2'), EventPerks ('title,trail'), + Workspace 'SeasonActive' / 'SeasonEnds' (UTC saniye). Sol menüdeki 🎃 düğmesiyle açılır (PanelManager).
-- GÖRÜNÜM: UIStyle tasarım sistemi (panel/header/card/button/chip/progressBar); etkinlik kimliği için panel ve kartlara mor-kahve ton, vurgu turuncu (warn).
-- Döner: pencereyi açıp kapatan fonksiyon, pencere.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)

local SpookyPanel = {}

local Theme = UIStyle.Theme
local COLORS = Theme.colors
-- Etkinlik teması: yalnız bu pencerede mor-kahve zemin
local TINT_PANEL = Color3.fromRGB(0x26, 0x1B, 0x33)
local TINT_CARD = Color3.fromRGB(0x35, 0x26, 0x4A)
local WIDTH = 460
local PAD = 16
local CHIP_GAP = 6
local CHIP_H = 108
local ROW_H, ROW_GAP = 64, 6

local function create(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- 'a,b' ya da 'a:2,b:1' metnini tabloya çevirir
local function parseSet(value)
	local set = {}
	for entry in string.gmatch(value or "", "[^,]+") do
		local key, count = string.match(entry, "^(.-):(%d+)$")
		if key then
			set[key] = tonumber(count)
		else
			set[entry] = true
		end
	end
	return set
end

-- Ödülün kısa yazısı: '4x Win', 'Muscle', 'Luck 15m' ...
local function describe(reward)
	local parts = {}
	if reward.winsStage then
		table.insert(parts, `{reward.winsStage}x Win`)
	end
	if reward.muscleClicks then
		table.insert(parts, "Muscle")
	end
	for _, potion in reward.potions or {} do
		local name = string.gsub(potion.kind, "^boost", "")
		table.insert(parts, `{name} {potion.minutes}m`)
	end
	return table.concat(parts, " + ")
end

local function timeLeft(seconds)
	seconds = math.max(0, math.floor(seconds))
	local days = seconds // 86400
	local hours = (seconds % 86400) // 3600
	if days > 0 then
		return `{days}d {hours}h`
	end
	return `{hours}h {(seconds % 3600) // 60}m`
end

function SpookyPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shop = ReplicatedStorage:WaitForChild("Shop")
	local event = Config.Event
	if not event then
		return nil
	end
	local milestones = #event.Milestones
	local items = #event.Items
	local chipW = math.floor((WIDTH - PAD * 2 - (milestones - 1) * CHIP_GAP) / math.max(milestones, 1))
	-- içerik koordinatları (başlığın altından): bilgi satırı 8, çubuk 62, kartlar 86, mağaza başlığı, satırlar
	local shopY = 86 + CHIP_H + 14
	local height = 60 + shopY + 26 + items * (ROW_H + ROW_GAP) + 10

	local panel = UIStyle.panel(screenGui, {
		name = "SpookyPanel",
		width = WIDTH,
		size = UDim2.fromOffset(WIDTH, height),
		accent = "warn",
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.48),
	})
	panel.BackgroundColor3 = TINT_PANEL
	panel.Visible = false

	UIStyle.header(panel, {
		title = event.Name,
		emoji = event.Emoji,
		accent = "warn",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	local content = create("Frame", { Name = "Content", Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1 }, panel)

	-- Candy sayısı ve kalan süre çipleri (CandyLabel / EndsLabel adları sözleşme; içeriği render sonrası da yaşar)
	local candyLabel = UIStyle.chip(panel, {
		name = "CandyLabel",
		text = "",
		accent = "primary",
		props = { Position = UDim2.fromOffset(PAD, 68), Size = UDim2.fromOffset(0, 28) },
	})
	local endsLabel = UIStyle.chip(panel, {
		name = "EndsLabel",
		text = "",
		accent = "warn",
		props = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -PAD, 0, 68), Size = UDim2.fromOffset(0, 28) },
	})

	local function invoke(action, id)
		task.spawn(function()
			local ok, success, message = pcall(shop.InvokeServer, shop, action, id)
			if not ok then
				success, message = false, "Could not complete that. Try again."
			end
			showToast(success, message or "")
		end)
	end

	local function render()
		for _, child in content:GetChildren() do
			child:Destroy()
		end
		local candy = player:GetAttribute("Candy") or 0
		local total = player:GetAttribute("CandyTotal") or 0
		local claimed = parseSet(player:GetAttribute("EventClaimed"))
		local bought = parseSet(player:GetAttribute("EventBought"))
		local perks = parseSet(player:GetAttribute("EventPerks"))
		local active = Workspace:GetAttribute("SeasonActive") == true
		UIStyle.setChipText(candyLabel, `{event.CurrencyEmoji} {Format.compact(candy)} {event.CurrencyName}`)

		-- Kilometre taşları: ilerleme çubuğu + kartlar
		local lastGoal = if milestones > 0 then event.Milestones[milestones].candy else 1
		local progress = `{Format.compact(total)} / {Format.compact(lastGoal)}`
		UIStyle.progressBar(content, {
			accent = "warn",
			value = math.clamp(total / lastGoal, 0, 1),
			text = progress,
			name = "MilestoneBar",
			props = { Position = UDim2.fromOffset(PAD, 62), Size = UDim2.new(1, -PAD * 2, 0, 16) },
		})
		UIStyle.label(content, { text = "Milestones", role = "bold", color = COLORS.warn.base, size = 14, props = { Position = UDim2.fromOffset(PAD, 40), Size = UDim2.fromOffset(160, 18) } })
		for index, milestone in event.Milestones do
			local done = claimed[tostring(index)] == true
			local ready = not done and total >= milestone.candy
			local chip = UIStyle.card(content, {
				name = `Milestone_{index}`,
				accent = if ready then "success" else "warn",
				selected = ready,
				padding = false,
				position = UDim2.fromOffset(PAD + (index - 1) * (chipW + CHIP_GAP), 86),
				size = UDim2.fromOffset(chipW, CHIP_H),
			})
			if chip then
				if not ready then
					chip.BackgroundColor3 = TINT_CARD
				end
				UIStyle.label(chip, { text = `{event.CurrencyEmoji} {milestone.candy}`, role = "bold", size = 13, color = COLORS.primary.base, align = "center", props = { Position = UDim2.fromOffset(2, 6), Size = UDim2.new(1, -4, 0, 16) } })
				UIStyle.label(chip, { text = describe(milestone.reward), role = "caption", size = 11, color = COLORS.text, align = "center", wrap = true, props = { Position = UDim2.fromOffset(4, 24), Size = UDim2.new(1, -8, 0, 32) } })
				local state = UIStyle.button(chip, {
					name = "ClaimButton",
					text = if done then "✓" elseif ready then "CLAIM" else "🔒",
					kind = if ready then "success" else "secondary",
					size = "sm",
					disabled = not ready,
					width = chipW - 12,
					position = UDim2.new(0.5, 0, 1, -24),
					onClick = function()
						if ready and active then
							invoke("EventClaim", index)
						end
					end,
				})
				if ready and state then
					UIStyle.pop(state)
				end
			end
		end

		-- Mağaza
		UIStyle.label(content, { text = `{event.Emoji} Event Shop (no random items!)`, role = "bold", color = COLORS.warn.base, size = 14, props = { Position = UDim2.fromOffset(PAD, shopY), Size = UDim2.new(1, -PAD * 2, 0, 18) } })
		for index, item in event.Items do
			local row = UIStyle.card(content, {
				name = `EventItem_{item.id}`,
				accent = "warn",
				padding = false,
				position = UDim2.fromOffset(PAD, shopY + 26 + (index - 1) * (ROW_H + ROW_GAP)),
				size = UDim2.new(1, -PAD * 2, 0, ROW_H),
			})
			if row then
				row.BackgroundColor3 = TINT_CARD
				local iconBox = create("Frame", { Name = "ItemIcon", Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(44, 44), BackgroundColor3 = TINT_PANEL, BorderSizePixel = 0 }, row)
				UIStyle.round(iconBox, Theme.radius.button)
				UIStyle.label(iconBox, { text = item.emoji, role = "bold", size = 24, align = "center", props = { Size = UDim2.fromScale(1, 1) } })
				UIStyle.label(row, { text = item.name, role = "bold", props = { Position = UDim2.fromOffset(64, 10), Size = UDim2.new(1, -184, 0, 22) } })
				UIStyle.label(row, { text = item.detail, role = "caption", props = { Position = UDim2.fromOffset(64, 34), Size = UDim2.new(1, -184, 0, 18) } })

				local count = bought[item.id] or 0
				local owned = (item.perk ~= nil and perks[item.perk] == true) or (item.limit == 1 and count >= 1)
				local label, kind, disabled, onClick = "", "primary", false, nil
				if owned and item.perk == "trail" then
					local equipped = player:GetAttribute("EquippedTrail") == event.Trail.id
					label = if equipped then "EQUIPPED" else "EQUIP"
					kind = if equipped then "secondary" else "success"
					disabled = equipped
					onClick = function()
						invoke("EquipTrail", if equipped then "" else event.Trail.id)
					end
				elseif owned then
					label, kind, disabled = "OWNED ✓", "secondary", true
				elseif count >= item.limit then
					label, kind, disabled = "SOLD OUT", "secondary", true
				else
					label = `{event.CurrencyEmoji} {item.price}`
					disabled = candy < item.price
					onClick = function()
						invoke("EventBuy", item.id)
					end
				end
				UIStyle.button(row, {
					name = "BuyButton",
					text = label,
					kind = kind,
					size = "sm",
					disabled = disabled,
					width = 104,
					anchor = Vector2.new(1, 0.5),
					position = UDim2.new(1, -10, 0.5, if item.limit > 1 then -6 else 0),
					onClick = function()
						if onClick and active then
							onClick()
						end
					end,
				})
				if item.limit > 1 then
					UIStyle.label(row, { text = `{count}/{item.limit}`, role = "caption", size = 11, align = "center", props = { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -4), Size = UDim2.fromOffset(104, 14) } })
				end
			end
		end
	end

	local function refreshTimer()
		local ends = Workspace:GetAttribute("SeasonEnds")
		if Workspace:GetAttribute("SeasonActive") ~= true or type(ends) ~= "number" then
			UIStyle.setChipText(endsLabel, "Event ended")
			return
		end
		local now = Workspace:GetServerTimeNow()
		UIStyle.setChipText(endsLabel, `Ends in {timeLeft(ends - (if type(now) == "number" then now else os.time()))}`)
	end

	local function onChange()
		if PanelManager.isOpen(panel) then
			render()
			refreshTimer()
		end
	end
	for _, name in { "Candy", "CandyTotal", "EventClaimed", "EventBought", "EventPerks", "EquippedTrail" } do
		player:GetAttributeChangedSignal(name):Connect(onChange)
	end
	Workspace:GetAttributeChangedSignal("SeasonActive"):Connect(onChange)

	local function show()
		PanelManager.show(panel)
		render()
		refreshTimer()
		task.spawn(function()
			while PanelManager.isOpen(panel) do
				task.wait(30)
				refreshTimer()
			end
		end)
	end
	local function toggle()
		if PanelManager.isOpen(panel) then
			PanelManager.hide(panel)
		else
			show()
		end
	end
	return toggle, panel
end

return SpookyPanel
