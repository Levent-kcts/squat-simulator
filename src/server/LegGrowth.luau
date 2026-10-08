-- Karakter büyümesi: level arttıkça boy ve genişlik büyür (Roblox'un Humanoid ölçek değerleriyle, kıyafetler de uyar)
-- ve bacaklara kas parçaları eklenir (Blender kasları 'muscle_s<aşama>_thigh|calf', yoksa yuvarlak küre kaslar). Level Body.MaxLevel'e ulaşınca görüntü sabitlenir.
-- Bu işlem sunucuda yapılır ki tüm oyuncular aynı görüntüyü görsün.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Progression = require(Shared:WaitForChild("Progression"))
local ModelLibrary = require(Shared:WaitForChild("ModelLibrary"))
local ShoeWear = require(script.Parent.ShoeWear)

local LegGrowth = {}

local MODEL_STAGES = 6 -- Blender kas aşaması sayısı (tools/blender/muscles.py); Config.Legs.StageLevels ile aynı olmalı

-- Yuvarlak kas parçası: küre mesh'li, bacağa kaynaklı, çarpışmasız. Bacak hareket ederken onunla birlikte oynar.
local function addMuscle(folder, leg, size, offset, color)
	local part = Instance.new("Part")
	part.Name = "Muscle"
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.CFrame = leg.CFrame * CFrame.new(offset)

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = leg
	weld.Part1 = part
	weld.Parent = part

	part.Parent = folder
end

-- Blender kası (shared/ModelLibrary 'muscle_s<aşama>_thigh' / '_glute' / '_calf'): mesh, bacak parçasının merkezine göre çizilmiştir ve gerçek bacak ölçüsünün
-- referansa (Config.Models.LegRef) oranıyla ölçeklenir (Humanoid boy/genişlik ölçeği ne olursa olsun). Meshlerde DOKU YOK: renk MeshPart.Color ile verilir
-- (Roblox dokulu MeshPart'ta Color'ı dokuyla çarpmaz, Studio'da gri çıktı). Model yoksa false döner ve çağıran yer küre kaslara düşer.
local function addMuscleModel(folder, leg, modelName, reference, color, material)
	local models = Config.Models
	local size = leg.Size
	local scale = Vector3.new(size.X / reference.X, size.Y / reference.Y, size.Z / reference.Z) * models.MuscleScale
	local part, offset = ModelLibrary.create(modelName, scale)
	if not part then
		return false
	end
	part.Name = "Muscle"
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = false -- ModelLibrary sabit verir; kas bacakla birlikte oynamalı
	part.CFrame = ModelLibrary.cframe(leg.CFrame, offset)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = leg
	weld.Part1 = part
	weld.Parent = part

	part.Parent = folder
	return true
end

local SHORTS_COLOR = Color3.fromRGB(20, 20, 25)

-- Siyah şort parçası: bacağa/gövdeye kaynaklı, çarpışmasız. cylinder = true ise uzun ekseni parçanın Y'si boyunca uzanır.
-- Şort vücuda yapışık (dar) olmalı: şişkin parçalar bez gibi görünür, bu yüzden bacağın kendi ölçüsünden sadece biraz büyük tutulur.
local function addShortsPart(folder, base, size, offset, cylinder)
	local part = Instance.new("Part")
	part.Name = "Shorts"
	part.Size = size
	part.Color = SHORTS_COLOR
	part.Material = Enum.Material.Fabric
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	if cylinder then
		part.Shape = Enum.PartType.Cylinder
		part.CFrame = base.CFrame * CFrame.new(offset) * CFrame.Angles(0, 0, math.pi / 2)
	else
		part.CFrame = base.CFrame * CFrame.new(offset)
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = part
	weld.Parent = part

	part.Parent = folder
end

-- Kalça bölgesini kapatan dar siyah şort (boxer): her uyluğun üst kısmında bacağı saran bir tüp (belde ayrı kuşak yok).
-- Boyutlar bacağın kendi ölçüsüne bağlıdır (kasların büyümesinden bağımsız), yani kas ne kadar büyürse büyüsün
-- kalça ve kasık bölgesi her zaman kapalı kalır. İki uyluk tüpü ortada üst üste bindiği için aralarında boşluk kalmaz.
local function buildShorts(folder, character)
	for _, side in { "Left", "Right" } do
		local upper = character:FindFirstChild(side .. "UpperLeg")
		local single = character:FindFirstChild(side .. " Leg") -- R6
		if upper then
			local w, y = upper.Size.X, upper.Size.Y
			addShortsPart(folder, upper, Vector3.new(y * 0.62, w * 1.07, w * 1.07), Vector3.new(0, y * 0.29, 0), true)
		elseif single then
			addShortsPart(folder, single, Vector3.new(single.Size.Y * 0.4, single.Size.X * 1.12, single.Size.X * 1.12), Vector3.new(0, single.Size.Y * 0.3, 0), true)
		end
	end
end

-- Kas grupları: popo (her aşamada, küçükten başlar), ön uyluk, arka uyluk ve baldır (aşama 1'den itibaren).
-- Boyutlar bacak parçasının o anki ölçüsüne göre hesaplanır, yani karakter büyüdükçe kaslar da orantılı büyür.
-- Yanlara az, öne-arkaya fazla büyürler ki iki bacak birbirine girmesin.
local function buildMuscles(character, stage)
	local old = character:FindFirstChild("LegMuscles")
	if old then
		old:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "LegMuscles"
	folder.Parent = character

	-- Renk: elle verilmişse o, standart pantolon açıksa pantolon/skin/ten rengi, yoksa bacağın kendi rengi.
	-- Takılı skin rengi doğrudan okunur (karakterin boyanmasını beklemeye gerek kalmaz).
	local forcedColor = Config.Legs.MuscleColor
	if forcedColor == nil and Config.Appearance.StandardPants then
		local head = character:FindFirstChild("Head")
		local player = Players:GetPlayerFromCharacter(character)
		local skin = player and Catalog.SkinById[player:GetAttribute("EquippedSkin") or ""]
		forcedColor = Config.Appearance.PantsColor or (skin and skin.color) or (head and head.Color)
	end

	if Config.Appearance.Shorts then
		buildShorts(folder, character)
	end

	local g = stage * Config.Legs.MuscleGrowth
	local muscular = stage > 0 -- oyun başında hiç kas yok

	for _, side in { "Left", "Right" } do
		local upper = character:FindFirstChild(side .. "UpperLeg")
		local lower = character:FindFirstChild(side .. "LowerLeg")
		local single = character:FindFirstChild(side .. " Leg") -- R6

		if upper and lower then
			local w = upper.Size.X
			local y = upper.Size.Y
			local skin = forcedColor or upper.Color
			if muscular then
				-- Blender kasları: uyluk, popo (şort renginde) ve baldır; model yoksa o grup küre kaslara düşer
				local modelStage = math.clamp(stage, 1, MODEL_STAGES)
				local refs = Config.Models.LegRef
				local shortsLook = if Config.Appearance.Shorts then SHORTS_COLOR else skin
				local gluteMaterial = if Config.Appearance.Shorts then Enum.Material.Fabric else nil
				if addMuscleModel(folder, upper, `muscle_s{modelStage}_thigh`, refs.Upper, skin) then
					if not addMuscleModel(folder, upper, `muscle_s{modelStage}_glute`, refs.Upper, shortsLook, gluteMaterial) then
						addMuscle(folder, upper, Vector3.new(w * (1.2 + 0.05 * g), y * 0.6, w * (1.0 + 0.12 * g)), Vector3.new(0, y * 0.3, w * 0.4), shortsLook)
					end
				else
					-- popo: uyluğun üst-arka kısmında
					addMuscle(folder, upper, Vector3.new(w * (1.2 + 0.05 * g), y * 0.6, w * (1.0 + 0.12 * g)), Vector3.new(0, y * 0.3, w * 0.4), shortsLook)
					-- ön uyluk
					addMuscle(folder, upper, Vector3.new(w * (1.0 + 0.03 * g), y * (0.62 + 0.015 * g), w * (1.05 + 0.07 * g)), Vector3.new(0, -y * 0.1, -w * (0.25 + 0.01 * g)), skin)
					-- arka uyluk
					addMuscle(folder, upper, Vector3.new(w * (0.95 + 0.03 * g), y * (0.5 + 0.03 * g), w * (1.0 + 0.14 * g)), Vector3.new(0, -y * 0.17, w * 0.3), skin)
				end
				-- baldır
				local lw = lower.Size.X
				local calfColor = forcedColor or lower.Color
				if not addMuscleModel(folder, lower, `muscle_s{modelStage}_calf`, refs.Lower, calfColor) then
					addMuscle(folder, lower, Vector3.new(lw * (1.0 + 0.04 * g), lower.Size.Y * (0.55 + 0.03 * g), lw * (1.1 + 0.16 * g)), Vector3.new(0, lower.Size.Y * 0.12, lw * 0.32), calfColor)
				end
			end
		elseif single then
			local w = single.Size.X
			local y = single.Size.Y
			local skin = forcedColor or single.Color
			if muscular then
				addMuscle(folder, single, Vector3.new(w * (1.2 + 0.05 * g), y * 0.3, w * (1.0 + 0.12 * g)), Vector3.new(0, y * 0.38, w * 0.4), if Config.Appearance.Shorts then SHORTS_COLOR else skin)
				addMuscle(folder, single, Vector3.new(w * (1.0 + 0.03 * g), y * 0.4, w * (1.05 + 0.07 * g)), Vector3.new(0, y * 0.15, -w * 0.25), skin)
				addMuscle(folder, single, Vector3.new(w * (1.0 + 0.04 * g), y * 0.3, w * (1.1 + 0.16 * g)), Vector3.new(0, -y * 0.15, w * 0.32), skin)
			end
		end
	end
end

local function levelOf(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local level = leaderstats and leaderstats:FindFirstChild(Config.StatLevel)
	return level and level.Value or 1
end

-- Boy ve genişlik: Humanoid'in ölçek değerleri (sadece R15'te var)
local function applyBodyScale(character, level)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local width, height = Progression.bodyScale(level)
	local function set(name, value)
		local scale = humanoid:FindFirstChild(name)
		if scale and scale:IsA("NumberValue") then
			scale.Value = value
		end
	end
	set("BodyWidthScale", width)
	set("BodyDepthScale", width)
	set("BodyHeightScale", height)
end

local tokens = setmetatable({}, { __mode = "k" }) -- [character] = son planlanan kas kurulumu

local function apply(player)
	local character = player.Character
	if not character then
		return
	end
	local level = levelOf(player)
	applyBodyScale(character, level)

	-- Şort hemen kurulur (karakter hiçbir an çıplak görünmesin), boyut değişimi oturunca bir kez daha kurulur
	buildMuscles(character, Progression.legStage(level))
	ShoeWear.refit(character)

	-- Humanoid parçaları yeniden boyutlandırdıktan sonra kasları ve ayakkabıları yeniden kur (parça ölçüleri değişmiş olur)
	local token = (tokens[character] or 0) + 1
	tokens[character] = token
	task.delay(0.3, function()
		if tokens[character] == token and character.Parent then
			buildMuscles(character, Progression.legStage(level))
			ShoeWear.refit(character)
		end
	end)
end

local function watch(player, notifyEvent)
	local lastStage = 0

	-- Karakter doğunca (ve görünümü yüklenince) boyutu ve kasları kur
	local function onCharacter(character)
		-- Parçalar birkaç an içinde yüklenir
		character:WaitForChild("RightFoot", 10)
		character:WaitForChild("Right Leg", 0.1)
		apply(player)
	end
	player.CharacterAdded:Connect(function(character)
		task.spawn(onCharacter, character)
	end)
	player.CharacterAppearanceLoaded:Connect(function()
		apply(player)
	end)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	-- Skin değişince kaslar yeni renkle yeniden kurulur
	player:GetAttributeChangedSignal("EquippedSkin"):Connect(function()
		apply(player)
	end)

	-- Level veya rebirth değişince boyutu güncelle, aşama değişince mesaj ver
	local leaderstats = player:WaitForChild("leaderstats")
	local function onChange()
		local stage = Progression.legStage(levelOf(player))
		apply(player)
		-- Giriş sırasında kayıtlı veri yüklenirken mesaj gösterme
		if player:GetAttribute("DataLoaded") then
			if stage > lastStage then
				if stage >= #Config.Legs.StageLevels then
					notifyEvent:FireClient(player, true, "Max size reached! You keep getting stronger.")
				else
					notifyEvent:FireClient(player, true, "You grew bigger!")
				end
			elseif stage < lastStage then
				notifyEvent:FireClient(player, true, "Rebirth! You are small again. Grow back!")
			end
		end
		lastStage = stage
	end
	for _, name in { Config.StatLevel, Config.StatRebirths } do
		leaderstats:WaitForChild(name):GetPropertyChangedSignal("Value"):Connect(onChange)
	end
	onChange()
end

-- Test için: bir karaktere verilen aşamanın kaslarını kurar (apply bunu level'dan çağırır)
LegGrowth.buildMuscles = buildMuscles

function LegGrowth.init(notifyEvent)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(watch, player, notifyEvent)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(watch, player, notifyEvent)
	end
end

return LegGrowth
