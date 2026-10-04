-- Oyuncuların başının üstünde isim + güç etiketi (referans oyundaki gibi): "🦵 92K" ve altında oyuncu adı.
-- Roblox'un kendi isim yazısı kapatılır, yerine bu etiket gelir. Sadece görsel: değerler leaderstats'tan okunur.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

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
	gui.Size = UDim2.fromScale(6, 2.4) -- stud cinsinden: uzaktayken küçülür
	gui.MaxDistance = 70
	gui.Adornee = head
	gui.Parent = head

	local power = styledLabel(gui, 0, 0.55, Color3.fromRGB(255, 225, 90))
	local nameLabel = styledLabel(gui, 0.55, 0.45, Color3.new(1, 1, 1))
	nameLabel.Text = targetPlayer.DisplayName

	local muscle = leaderstats:WaitForChild(Config.StatLegMuscle, 10)
	local level = leaderstats:WaitForChild(Config.StatLevel, 10)

	local function refresh()
		if not gui.Parent then
			return
		end
		-- Karakter büyüdükçe etiket de başın üstünde kalsın
		gui.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + 1.6, 0)
		local text = if muscle then Format.compact(muscle.Value) else "0"
		power.Text = `🦵 {text}`
		if level then
			nameLabel.Text = `Lv.{level.Value} {targetPlayer.DisplayName}`
		end
	end
	refresh()

	for _, stat in { muscle, level } do
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
