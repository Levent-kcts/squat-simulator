-- Oyuncuların başının üstünde isim + güç etiketi (referans oyundaki gibi): "🦵 92K" ve altında oyuncu adı.
-- Roblox'un kendi isim yazısı kapatılır, yerine bu etiket gelir. Sadece görsel: değerler leaderstats'tan okunur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Progression = require(Shared:WaitForChild("Progression"))

local OverheadTags = {}

local TAG_NAME = "StatTag"

local function styledLabel(parent, yScale, heightScale, color)
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromScale(0, yScale)
	label.Size = UDim2.fromScale(1, heightScale)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	return label
end

-- Rebirth sayısına göre yıldız rengi (RichText onaltılık)
local function starColor(count)
	if count >= 20 then
		return "#FF6FB0"
	elseif count >= 10 then
		return "#C58BFF"
	elseif count >= 5 then
		return "#FFD23C"
	end
	return "#E6EEF8"
end

local function attach(targetPlayer, character)
	local head = character:WaitForChild("Head", 10)
	local leaderstats = targetPlayer:WaitForChild("leaderstats", 30)
	if not head or not leaderstats or not character.Parent then
		return
	end

	-- Roblox'un kendi isim/can göstergesi kapatılır (sadece bu istemcide)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local old = head:FindFirstChild(TAG_NAME)
	if old then
		old:Destroy()
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = TAG_NAME
	gui.Size = UDim2.fromScale(6, 3.1) -- stud cinsinden: uzaktayken küçülür (3 satır: güç, ad, rütbe unvanı)
	gui.MaxDistance = 70
	gui.Adornee = head
	gui.Parent = head

	-- Settings'te "Name tags" kapalıysa etiket görünmez (bu oyuncunun ekranında)
	local viewer = Players.LocalPlayer
	local function applyVisibility()
		gui.Enabled = viewer:GetAttribute("NameTags") ~= false
	end
	applyVisibility()
	local visibilityConnection = viewer:GetAttributeChangedSignal("NameTags"):Connect(applyVisibility)
	gui.Destroying:Connect(function()
		visibilityConnection:Disconnect()
	end)


	local power = styledLabel(gui, 0, 0.42, Color3.fromRGB(255, 225, 90))
	local nameLabel = styledLabel(gui, 0.42, 0.34, Color3.new(1, 1, 1))
	nameLabel.Text = targetPlayer.DisplayName
	-- RÜTBE UNVANI (Config.Titles, rebirth sayısına göre; sadece rebirth yapmış oyuncuda): kalıcı statü, adın altında küçük
	local titleLabel = styledLabel(gui, 0.76, 0.24, Color3.fromRGB(190, 196, 215))
	titleLabel.Text = ""

	local muscle = leaderstats:WaitForChild(Config.StatLegMuscle, 10)
	local level = leaderstats:WaitForChild(Config.StatLevel, 10)
	local rebirths = leaderstats:WaitForChild(Config.StatRebirths, 10)
	nameLabel.RichText = true

	local function refresh()
		if not gui.Parent then
			return
		end
		-- Karakter büyüdükçe etiket de başın üstünde kalsın
		gui.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + 1.6, 0)
		local text = if muscle then Format.compact(muscle.Value) else "0"
		power.Text = `🦵 {text}`
		-- KALICI STATÜ (2026-10-14 tasarım incelemesi: 'Lv.N' ve kas rebirth'te sıfırlanır, 40 rebirth'lik oyuncu yeni oyuncuyla aynı görünüyordu): rebirth yapmış oyuncuda
		-- '★N' rozeti (rebirth sayısı, renk kademesi: 1+ gümüş, 5+ altın, 10+ mor, 20+ pembe), yapmamışta 'Lv.N'
		local rebirthCount = if rebirths then rebirths.Value else 0
		if rebirthCount > 0 then
			local title = Progression.title(rebirthCount)
			titleLabel.Text = title.name
			titleLabel.TextColor3 = title.color
		else
			titleLabel.Text = ""
		end
		if rebirthCount > 0 then
			nameLabel.Text = `<font color="{starColor(rebirthCount)}">★{rebirthCount}</font> {targetPlayer.DisplayName}`
		elseif level then
			nameLabel.Text = `Lv.{level.Value} {targetPlayer.DisplayName}`
		end
	end
	refresh()

	for _, stat in { muscle, level, rebirths } do
		if stat then
			stat:GetPropertyChangedSignal("Value"):Connect(refresh)
		end
	end
end

local function track(targetPlayer)
	targetPlayer.CharacterAdded:Connect(function(character)
		task.spawn(attach, targetPlayer, character)
	end)
	if targetPlayer.Character then
		task.spawn(attach, targetPlayer, targetPlayer.Character)
	end
end

function OverheadTags.init()
	for _, other in Players:GetPlayers() do
		track(other)
	end
	Players.PlayerAdded:Connect(track)
end

return OverheadTags
