-- Oyuncunun kendi skini (ten, gömlek, pantolon) kalır; üstteki katmanlı kıyafet ve aksesuarlar kaldırılır.
-- Böylece katmanlı kıyafetler, pantolonlar, sırt çantaları vb. bacak kaslarının ve oyunun görüntüsünü bozmaz.
-- Sunucuda yapılır, bu yüzden tüm oyuncular aynı temiz görüntüyü görür.
-- Skin rafından alınan skin (EquippedSkin) varsa tüm vücut o renge boyanır, skin kalkınca (rebirth) asıl renkler geri gelir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local ShoeModel = require(Shared:WaitForChild("ShoeModel"))

local AppearanceCleaner = {}

local keep = {}
for _, name in Config.Appearance.KeepAccessoryTypes do
	keep[name] = true
end

-- Bu parça kaldırılmalı mı?
local function shouldRemove(instance)
	-- Klasik kıyafetler (üst/alt giysi, grafik)
	-- Standart mavi pantolon için oyuncunun kendi pantolonu (doku) kalkar
	if Config.Appearance.StandardPants and instance:IsA("Pants") then
		return true
	end
	if Config.Appearance.RemoveClassicClothing then
		if instance:IsA("Shirt") or instance:IsA("Pants") or instance:IsA("ShirtGraphic") then
			return true
		end
	end
	if instance:IsA("Accessory") then
		-- Katmanlı kıyafetler ve çanta, şapka gibi aksesuarlar kalkar; saç ve yüz detayları kalır
		return not keep[instance.AccessoryType.Name]
	end
	return false
end

-- Oyuncunun takılı skin rengi (yoksa nil)
local function skinOverride(character)
	local player = Players:GetPlayerFromCharacter(character)
	local skin = player and Catalog.SkinById[player:GetAttribute("EquippedSkin") or ""]
	return skin and skin.color
end

local BODY_COLOR_PROPERTIES = { "HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3" }

-- Skin boyamadan önceki asıl renkler: [karakter] = { body = { özellik = renk }, parts = { [parça] = renk } }
local originals = setmetatable({}, { __mode = "k" })

local function captureOriginals(character)
	if originals[character] then
		return
	end
	local record = { body = {}, parts = {}, materials = {}, textures = {} }
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		for _, property in BODY_COLOR_PROPERTIES do
			record.body[property] = bodyColors[property]
		end
	end
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") then
			record.parts[part] = part.Color
			record.materials[part] = part.Material
			if part:IsA("MeshPart") then
				record.textures[part] = part.TextureID
			end
		end
	end
	originals[character] = record
end

-- Kaydedilmiş asıl renklere/malzemelere döner. clear = true ise kayıt da silinir (artık skin/ayakkabı yok).
local function restoreOriginals(character, clear)
	local record = originals[character]
	if not record then
		return
	end
	if clear then
		originals[character] = nil
	end
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		for property, color in record.body do
			bodyColors[property] = color
		end
	end
	for part, color in record.parts do
		if part.Parent == character then
			part.Color = color
			part.Material = record.materials[part]
			if record.textures[part] ~= nil then
				part.TextureID = record.textures[part]
			end
		end
	end
end

-- Tüm vücut parçalarını verilen renge boyar (skin ya da oyuncunun kendi ten rengi).
local function paintBody(character, skin)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors.HeadColor3 = skin
		bodyColors.TorsoColor3 = skin
		bodyColors.LeftArmColor3 = skin
		bodyColors.RightArmColor3 = skin
		bodyColors.LeftLegColor3 = skin
		bodyColors.RightLegColor3 = skin
	end
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = skin
		end
	end
end

-- Herkesin bacakları ve kalçası aynı mavi pantolon rengine boyanır
local PANTS_PARTS = { "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg", "LowerTorso", "Left Leg", "Right Leg" }

local function applyPants(character)
	local head = character:FindFirstChild("Head")
	local color = Config.Appearance.PantsColor or (head and head.Color)
	if not color then
		return
	end
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if bodyColors then
		bodyColors.LeftLegColor3 = color
		bodyColors.RightLegColor3 = color
	end
	for _, name in PANTS_PARTS do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
end

-- Skin takılıyken gömlek dokusu gizlenir ki skin rengi görünsün; skin kalkınca doku geri gelir.
local function applyShirt(character, hidden)
	if not Config.Appearance.HideShirtWithSkin then
		return
	end
	for _, child in character:GetChildren() do
		local property = if child:IsA("Shirt") then "ShirtTemplate" elseif child:IsA("ShirtGraphic") then "Graphic" else nil
		if property then
			local original = child:GetAttribute("OriginalTexture")
			if hidden then
				if original == nil then
					child:SetAttribute("OriginalTexture", child[property])
				end
				child[property] = ""
			elseif original ~= nil then
				child[property] = original
				child:SetAttribute("OriginalTexture", nil)
			end
		end
	end
end

-- Oyuncunun takılı ayakkabısı (yoksa nil)
local function equippedShoe(character)
	local player = Players:GetPlayerFromCharacter(character)
	return player and Catalog.ItemById[player:GetAttribute("EquippedShoe") or ""]
end

-- Ayakkabı: ayak parçasının kendisi ayakkabının renginde ve parlak (Neon) boyanır (dışarıdan parça eklenmez).
-- Parlaklık güçle artar: neon renk yoğunluğu (ShoeModel.neonColor) + ayakta yanan ışık (parlaklığı ve menzili kademeyle büyür).
-- Sadece R15'te ayak parçası var; R6'da bacak tek parça olduğu için ayakkabı görünmez.
-- Neon malzeme şart: mat malzemede bu avatarın ayak/bacak rengi ekranda değişmedi (parça rengi doğru yazılsa bile, nedeni bulunamadı).
local GLOW_NAME = "ShoeGlow"
local TRAIL_NAME = "ShoeTrail"
local trailConnections = setmetatable({}, { __mode = "k" }) -- [karakter] = Humanoid.Running bağlantısı (izi yürüyüşe göre açıp kapatır)

local function clearShoeGlow(character)
	local connection = trailConnections[character]
	if connection then
		connection:Disconnect()
		trailConnections[character] = nil
	end
	for _, name in { "LeftFoot", "RightFoot" } do
		local foot = character:FindFirstChild(name)
		if foot then
			for _, childName in { GLOW_NAME, TRAIL_NAME } do
				local old = foot:FindFirstChild(childName)
				if old then
					old:Destroy()
				end
			end
		end
	end
end

-- En güçlü ayakkabılar (Config.ShoeTrail): yürürken ayaklardan geriye doğru ayakkabının renginde parçacık akar. Emitter'lar hep vardır ama
-- sadece koşarken açıktır (Humanoid.Running); parçacıkları istemciler kendi ekranında oynatır.
local function addShoeTrail(character, shoe)
	local level = ShoeModel.trailLevel(shoe)
	if not level then
		return
	end
	local trail = Config.ShoeTrail
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1
	local emitters = {}
	for _, name in { "LeftFoot", "RightFoot" } do
		local foot = character:FindFirstChild(name)
		if foot and foot:IsA("BasePart") then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = TRAIL_NAME
			emitter.Color = ColorSequence.new(shoe.color, shoe.color:Lerp(Color3.new(1, 1, 1), 0.5))
			emitter.LightEmission = 0.9
			emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, trail.Size[level]), NumberSequenceKeypoint.new(1, 0) })
			emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
			emitter.Lifetime = NumberRange.new(0.5, 0.9)
			emitter.Speed = NumberRange.new(1, 3)
			emitter.SpreadAngle = Vector2.new(25, 25)
			emitter.EmissionDirection = Enum.NormalId.Back -- ayağın arkasına doğru
			emitter.Acceleration = Vector3.new(0, 1.5, 0)
			emitter.RotSpeed = NumberRange.new(-120, 120)
			emitter.Rate = trail.Rate[level]
			emitter.Enabled = moving
			emitter.Parent = foot
			table.insert(emitters, emitter)
		end
	end
	if humanoid and #emitters > 0 then
		trailConnections[character] = humanoid.Running:Connect(function(speed)
			local isMoving = speed > 2
			for _, emitter in emitters do
				emitter.Enabled = isMoving
			end
		end)
	end
end

local function applyShoes(character, shoe)
	clearShoeGlow(character)
	if not shoe then
		return
	end
	local tier = ShoeModel.tier(shoe)
	for _, name in { "LeftFoot", "RightFoot" } do
		local foot = character:FindFirstChild(name)
		if foot and foot:IsA("BasePart") then
			foot.Color = ShoeModel.neonColor(shoe)
			foot.Material = Enum.Material.Neon

			local light = Instance.new("PointLight")
			light.Name = GLOW_NAME
			light.Color = shoe.color
			local glow = Config.ShoeGlow
			light.Brightness = glow.FootLightBrightness[1] + (glow.FootLightBrightness[2] - glow.FootLightBrightness[1]) * tier
			light.Range = glow.FootLightRange[1] + (glow.FootLightRange[2] - glow.FootLightRange[1]) * tier
			if ShoeModel.isTop(shoe) then
				-- En güçlü ayakkabı biraz daha parlak ve geniş ışık verir (kör edecek kadar değil)
				light.Brightness += glow.TopBonus.LightBrightness
				light.Range += glow.TopBonus.LightRange
			end
			light.Shadows = false
			light.Parent = foot
		end
	end
	addShoeTrail(character, shoe)
end

-- Renkleri uygular: skin varsa tüm vücut skin rengi, yoksa asıl renkler (UnifySkinColor açıksa düz ten); sonra pantolon,
-- gömlek ve ayakkabı (ayaklar). Her seferinde asıl renklerden başlanır, böylece eski skin/ayakkabı rengi kalmaz.
local function paint(character)
	local override = skinOverride(character)
	local shoe = equippedShoe(character)
	if override or shoe then
		captureOriginals(character)
		restoreOriginals(character, false)
	else
		restoreOriginals(character, true)
	end
	if override then
		paintBody(character, override)
	elseif Config.Appearance.UnifySkinColor then
		local head = character:FindFirstChild("Head")
		if head then
			paintBody(character, head.Color)
		end
	end
	if Config.Appearance.StandardPants then
		applyPants(character)
	end
	applyShirt(character, override ~= nil)
	applyShoes(character, shoe)
end

local function clean(character)
	for _, child in character:GetChildren() do
		if shouldRemove(child) then
			child:Destroy()
		end
	end
	paint(character)
end

local function onCharacter(character)
	clean(character)
	-- Görünüm sonradan yüklenir veya yenilenirse eklenenleri de temizle
	character.ChildAdded:Connect(function(child)
		if child:IsA("BodyColors") then
			-- Yeni görünüm yüklendi: eski asıl renk kaydı geçersiz, yeniden yakalanır
			originals[character] = nil
			task.defer(paint, character)
		elseif child:IsA("Shirt") or child:IsA("ShirtGraphic") then
			task.defer(applyShirt, character, skinOverride(character) ~= nil)
		elseif shouldRemove(child) then
			-- Accessory'nin tipi eklendiği anda henüz okunamayabilir, bir kare bekle
			task.defer(function()
				if child.Parent == character and shouldRemove(child) then
					child:Destroy()
				end
			end)
		end
	end)
end

local function watch(player)
	player.CharacterAdded:Connect(onCharacter)
	player.CharacterAppearanceLoaded:Connect(clean)
	-- Skin/ayakkabı satın alınınca, değişince ya da rebirth ile kalkınca karakter yeniden boyanır (veri yüklenince de çalışır)
	for _, attribute in { "EquippedSkin", "EquippedShoe" } do
		player:GetAttributeChangedSignal(attribute):Connect(function()
			if player.Character then
				paint(player.Character)
			end
		end)
	end
	if player.Character then
		onCharacter(player.Character)
	end
end

function AppearanceCleaner.init()
	if not Config.Appearance.Enabled then
		return
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return AppearanceCleaner
