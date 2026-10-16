-- MASTERY penceresi (Config.Mastery; server: PlayerStats.buyMastery): üç dal (Iron Legs, Brick Breaker, Win Magnet), her biri Win ile alınan kalıcı kademeler. Her kartta kademe çubuğu, şimdiki ve sonraki bonus, maliyet ve BUY.
-- Durum 'MasteryLevels' ('power:3,smash:0,fortune:1') özniteliğinden ve Wins sayacından gelir. İlk rebirth'ten sonra sol menüdeki Mastery düğmesiyle açılır (PanelManager).
-- Döner: pencereyi açıp kapatan fonksiyon, pencere.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Layout = require(Shared:WaitForChild("Layout"))
local UIStyle = require(script.Parent.UIStyle)
local PanelManager = require(script.Parent.PanelManager)

local MasteryPanel = {}

local Theme = UIStyle.Theme
local COLORS = Theme.colors
local WIDTH, ROW_H, GAP = 460, 104, 8

local ACCENTS = { power = "hot", smash = "warn", fortune = "primary" }

function MasteryPanel.init(screenGui, showToast)
	local player = Players.LocalPlayer
	local shop = ReplicatedStorage:WaitForChild("Shop")
	local settings = Config.Mastery
	if not settings then
		return nil
	end
	local height = 76 + #settings.Branches * (ROW_H + GAP) + 28

	local panel = UIStyle.panel(screenGui, {
		name = "MasteryPanel",
		width = WIDTH,
		size = UDim2.fromOffset(WIDTH, height),
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.48),
		accent = "primary",
	})
	panel.Visible = false
	UIStyle.header(panel, {
		title = "Mastery",
		subtitle = "Permanent upgrades, kept after Rebirth",
		emoji = "🎓",
		accent = "primary",
		onClose = function()
			PanelManager.hide(panel)
		end,
	})

	local rows = {}
	for index, branch in settings.Branches do
		local accent = ACCENTS[branch.id] or "info"
		local card = UIStyle.card(panel, {
			name = "Mastery_" .. branch.id,
			position = UDim2.fromOffset(16, 70 + (index - 1) * (ROW_H + GAP)),
			size = UDim2.new(1, -32, 0, ROW_H),
			accent = accent,
			padding = false,
		})
		UIStyle.label(card, { text = branch.emoji, role = "title", size = 34, align = "center", props = { Position = UDim2.fromOffset(10, 12), Size = UDim2.fromOffset(46, 46) } })
		UIStyle.label(card, { text = branch.name, role = "bold", color = COLORS.text, props = { Position = UDim2.fromOffset(64, 8), Size = UDim2.new(1, -190, 0, 22) } })
		local effect = UIStyle.label(card, { name = "Effect", text = "", role = "caption", color = COLORS.textDim, props = { Position = UDim2.fromOffset(64, 30), Size = UDim2.new(1, -190, 0, 18) } })
		local bar = UIStyle.progressBar(card, { accent = accent, value = 0, text = "", name = "Bar", props = { Position = UDim2.fromOffset(64, 56), Size = UDim2.new(1, -190, 0, 22) } })
		local nextLabel = UIStyle.label(card, { name = "Next", text = "", role = "caption", color = COLORS.textDim, props = { Position = UDim2.fromOffset(64, 80), Size = UDim2.new(1, -190, 0, 16) } })
		local buy = UIStyle.button(card, {
			name = "BuyButton",
			text = "BUY",
			kind = "success",
			size = "md",
			width = 108,
			anchor = Vector2.new(1, 0.5),
			position = UDim2.new(1, -10, 0.5, 0),
			onClick = function()
				task.spawn(function()
					local ok, success, message = pcall(shop.InvokeServer, shop, "BuyMastery", branch.id)
					if not ok then
						success, message = false, "Could not buy that. Try again."
					end
					if showToast then
						showToast(success, message or "")
					end
				end)
			end,
		})
		rows[branch.id] = { branch = branch, effect = effect, bar = bar, nextLabel = nextLabel, buy = buy }
	end

	local winsChip = UIStyle.label(panel, { name = "WinsLabel", text = "", role = "bold", color = COLORS.primary.base, align = "right", props = { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -6), Size = UDim2.fromOffset(200, 20) } })

	local function levelsOf()
		local levels = {}
		for id, level in string.gmatch(tostring(player:GetAttribute("MasteryLevels") or ""), "(%w+):(%d+)") do
			levels[id] = tonumber(level)
		end
		return levels
	end

	local function render()
		local levels = levelsOf()
		local leaderstats = player:FindFirstChild("leaderstats")
		local winsStat = leaderstats and leaderstats:FindFirstChild(Config.StatWins)
		local wins = if winsStat then winsStat.Value else 0
		winsChip.Text = `🏆 {Format.compact(wins)} Wins`
		for _, row in rows do
			local branch = row.branch
			local level = levels[branch.id] or 0
			local maxed = level >= settings.MaxLevel
			row.effect.Text = `+{level * branch.perLevel}% {branch.detail}`
			row.bar.set(level / settings.MaxLevel, `{level}/{settings.MaxLevel}`)
			if maxed then
				row.nextLabel.Text = "MAX LEVEL"
				UIStyle.setButtonText(row.buy, "MAXED")
				UIStyle.setButtonKind(row.buy, "secondary")
				UIStyle.setButtonEnabled(row.buy, false)
			else
				local cost = Layout.masteryCost(branch, level, settings.CostMult)
				row.nextLabel.Text = `Next: +{(level + 1) * branch.perLevel}%`
				UIStyle.setButtonText(row.buy, `🏆 {Format.compact(cost)}`)
				UIStyle.setButtonKind(row.buy, if wins >= cost then "success" else "secondary")
				UIStyle.setButtonEnabled(row.buy, true)
			end
		end
	end

	local function onChange()
		if PanelManager.isOpen(panel) then
			render()
		end
	end
	player:GetAttributeChangedSignal("MasteryLevels"):Connect(onChange)
	local leaderstats = player:FindFirstChild("leaderstats")
	local winsStat = leaderstats and leaderstats:FindFirstChild(Config.StatWins)
	if winsStat then
		winsStat:GetPropertyChangedSignal("Value"):Connect(onChange)
	end

	local function toggle()
		if PanelManager.isOpen(panel) then
			PanelManager.hide(panel)
		else
			PanelManager.show(panel)
			render()
		end
	end
	return toggle, panel
end

return MasteryPanel
