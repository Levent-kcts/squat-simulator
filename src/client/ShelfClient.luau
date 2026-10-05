-- Lobi raflarının (ayakkabı, skin) oyuncuya özel görünümü: etiketler ve postament renkleri.
-- Burada yapılan renk/etiket değişiklikleri sadece bu oyuncunun ekranında görünür.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

local ShelfClient = {}

-- Ped renkleri (sahne bunaltmasın diye SADECE işe yarayan pedler parlar, gerisi sönüktür; Win yokken hiçbiri parlamaz):
--   altın parlak = şu an kullanıyorsun, yeşil parlak = alabilirsin (Win yetiyor), mavi sönük = sahipsin (kullanmıyorsun), gri-mavi sönük = alamazsın
local YELLOW = Color3.fromRGB(255, 225, 40)
local BUY = Color3.fromRGB(60, 255, 110)
local OWNED = Color3.fromRGB(105, 160, 235)
local DIM = Color3.fromRGB(150, 157, 196) -- floru boğmayan, yumuşak lavanta gri (eskisi çok koyuydu, delik gibi duruyordu)
local DIM_TEXT = Color3.fromRGB(190, 196, 218)
local NEON = Enum.Material.Neon
local PLASTIC = Enum.Material.SmoothPlastic

-- 1.5 -> "1.5", 100 -> "100", 1500 -> "1.5K"
function ShelfClient.fmtMultiplier(value)
	if value >= 1000 then
		return Format.compact(value)
	end
	return string.format("%g", value)
end

-- Etiket: kutuya sığan, kalın siyah kenarlı yazı. Boyut stud cinsinden olduğu için uzaktayken küçülür.
local function makeLabel(parent, yScale, heightScale, color)
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromScale(0, yScale)
	label.Size = UDim2.fromScale(1, heightScale)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = parent

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	return label
end
ShelfClient.makeLabel = makeLabel

-- options:
--   folderName: Workspace'teki raf klasörü, items: Config listesi, displayPrefix: eşya modelinin ad öneki ("Shoes_"),
--   ownedAttr / equippedAttr: oyuncu öznitelikleri (sahip olunanlar "a,b,c" şeklinde, takılı olan tek id),
--   powerText(item): üst satır yazısı, labelHeight: etiketin postament merkezinden yüksekliği (stud)
function ShelfClient.init(options)
	local player = Players.LocalPlayer
	local folder = Workspace:WaitForChild(options.folderName)
	local winValue = player:WaitForChild("leaderstats"):WaitForChild(Config.StatWins)

	-- Her eşyanın üstünde üç satır: isim (eşyanın renginde), güç çarpanı (beyaz) ve fiyat (sarı)
	local entries = {}
	for _, item in options.items do
		local pad = folder:WaitForChild(`Pad_{item.id}`)

		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(5, 2.6)
		gui.StudsOffsetWorldSpace = Vector3.new(0, options.labelHeight, 0)
		gui.MaxDistance = 35
		gui.Adornee = pad
		gui.Parent = pad

		-- Koyu renkler (Galaxy gibi) siyah kenarlıkla bile okunsun diye isim rengi beyaza doğru açılır
		local name = makeLabel(gui, 0, 0.3, item.color:Lerp(Color3.new(1, 1, 1), 0.55))
		name.Text = item.name
		local power = makeLabel(gui, 0.3, 0.3, Color3.new(1, 1, 1))
		power.Text = options.powerText(item)
		local price = makeLabel(gui, 0.6, 0.4, Color3.fromRGB(255, 235, 40))

		table.insert(entries, { item = item, pad = pad, price = price })
	end

	-- Eşyalar olduğu yerde hafifçe yukarı aşağı süzülür ve çok az sallanır (sadece bu oyuncunun ekranında)
	local spinners = {}
	for index, item in options.items do
		local model = folder:WaitForChild(`{options.displayPrefix}{item.id}`)
		local parts = {}
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(parts, { part = child, cframe = child.CFrame })
			end
		end
		local boundingBox = model:GetBoundingBox()
		table.insert(spinners, { parts = parts, center = boundingBox.Position, phase = index * 0.7 })
	end
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for _, spinner in spinners do
			local angle = math.sin(now * 1.2 + spinner.phase) * 0.12 -- en fazla yaklaşık 7 derece
			local bob = math.sin(now * 2 + spinner.phase) * 0.12
			local transform = CFrame.new(spinner.center + Vector3.new(0, bob, 0))
				* CFrame.Angles(0, angle, 0)
				* CFrame.new(-spinner.center)
			for _, entry in spinner.parts do
				entry.part.CFrame = transform * entry.cframe
			end
		end
	end)

	local function refresh()
		local owned = {}
		for id in string.gmatch(player:GetAttribute(options.ownedAttr) or "", "[^,]+") do
			owned[id] = true
		end
		local equipped = player:GetAttribute(options.equippedAttr) or ""

		local wins = winValue.Value
		for _, entry in entries do
			local item = entry.item
			local pad, price = entry.pad, entry.price
			if equipped == item.id then
				pad.Color, pad.Material = YELLOW, NEON
				price.Text, price.TextColor3 = "Equipped", YELLOW
			elseif owned[item.id] then
				pad.Color, pad.Material = OWNED, PLASTIC
				price.Text, price.TextColor3 = "Owned", Color3.fromRGB(160, 200, 255)
			elseif item.price <= wins then
				pad.Color, pad.Material = BUY, NEON
				price.Text, price.TextColor3 = `{Format.compact(item.price)} Wins`, BUY
			else
				pad.Color, pad.Material = DIM, PLASTIC
				price.Text, price.TextColor3 = `{Format.compact(item.price)} Wins`, DIM_TEXT
			end
		end
	end

	winValue:GetPropertyChangedSignal("Value"):Connect(refresh)
	player:GetAttributeChangedSignal(options.ownedAttr):Connect(refresh)
	player:GetAttributeChangedSignal(options.equippedAttr):Connect(refresh)
	refresh()
end

return ShelfClient
