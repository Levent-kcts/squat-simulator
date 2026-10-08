-- Karakterin AYAĞINDAKİ ayakkabı: takılı ayakkabının Blender modeli (shoe_<id>, raftakiyle aynı) iki ayağa da oturtulur, ayak parçası gizlenir
-- (sahibi 'ayakkabıyı alınca ayak rengimizin değişmesini beğenmedim, son büyüme evresinde bile kötü durmasın, modelle' dedi).
-- Model ayağın o anki ölçüsüne göre EKSEN EKSEN ölçeklenir (R15 Foot referansı 1 x 0.3 x 1; Config.Models.ShoeWear: genişlik/uzunluk/boy ölçeği): level atlayınca
-- ve rebirth'te ayak büyüyüp küçüldükçe ayakkabı da orantılı kalır, son büyüme evresinde de bacağa göre aynı oranda durur. Bacak ayakkabının ağzından girer
-- (ayak giriş merkezi bacağın merkezine gelir; önizleme: tools/blender/shoe_wear_preview.py). Parçalar ayağa Weld ile bağlıdır, yani tekme/squat sırasında ayakla birlikte oynar.
-- Model yoksa (GameModels'a aktarılmamış) apply false döner ve çağıran eski yönteme düşer (ayağı boyamak).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ModelLibrary = require(Shared:WaitForChild("ModelLibrary"))

local ShoeWear = {}

local FOLDER_NAME = "ShoeParts"
local FOOT_REF = Vector3.new(1, 0.3, 1) -- R15 ayak parçasının standart ölçüsü; ölçek bu ölçüye oranlanır
local FEET = { "LeftFoot", "RightFoot" }
local HIDDEN_ATTRIBUTE = "ShoeOriginalTransparency" -- ayak gizlenince asıl şeffaflığı burada durur

-- [karakter] = { folder, fits = { yeniden oturt işlevleri }, connections = { Size dinleyicileri } }
local active = setmetatable({}, { __mode = "k" })

-- Bacağın (LowerLeg) ayağa göre merkezi ve derinliği: ayak ile bacak normalde aynı merkezde durur, rig farklıysa ayakkabı yine BACAĞIN altına oturur.
-- Bulunamazsa nil (ayak ölçüsü kullanılır).
local function legAlignment(foot, leg)
	if not leg or not leg:IsA("BasePart") then
		return nil
	end
	local ok, relative = pcall(function()
		return foot.CFrame:PointToObjectSpace(leg.Position)
	end)
	if ok and relative and type(relative.X) == "number" and type(relative.Z) == "number" then
		return relative, leg.Size.Z
	end
	return nil
end

-- Ayağın o anki ölçüsüne göre ayakkabının boyutu ve ayağa göre CFrame'i. baseSize/baseOffset: ölçeksiz (1x) model boyutu ve orijine göre kutu merkezi.
-- Roblox'ta modelin eksenleri: x genişlik, y boy, z uzunluk. Orijin tabanın ortası. Topuk, bacağın arka yüzünden 'heel' kadar geride; ayakkabı öne (-Z) uzanır.
local function fitFor(foot, leg, baseSize, baseOffset)
	local wear = Config.Models.ShoeWear
	local size = foot.Size
	local widthRatio, heightRatio, depthRatio = size.X / FOOT_REF.X, size.Y / FOOT_REF.Y, size.Z / FOOT_REF.Z
	local scale = Vector3.new(wear.sx * widthRatio, wear.sh * heightRatio, wear.sl * depthRatio)
	local shoeSize = baseSize * scale
	local offset = baseOffset * scale
	local centerX, centerZ, legDepth = 0, 0, size.Z
	local relative, depth = legAlignment(foot, leg)
	if relative then
		centerX, centerZ, legDepth = relative.X, relative.Z, depth
	end
	local flip = Config.Models.FlipFront
	local originZ = centerZ
	if flip then
		-- Parçanın merkezi origin + (-offset.x, offset.y, -offset.z) (180 derece dönük); arka ucu merkez + yarı uzunluk = topuk
		local heelZ = centerZ + legDepth / 2 + wear.heel * depthRatio
		originZ = heelZ - shoeSize.Z / 2 + offset.Z
	end
	local origin = Vector3.new(centerX, -size.Y / 2, originZ)
	local center = origin + (if flip then Vector3.new(-offset.X, offset.Y, -offset.Z) else offset)
	local cframe = CFrame.new(center)
	if flip then
		cframe = cframe * CFrame.Angles(0, math.pi, 0)
	end
	return shoeSize, cframe
end

local reported = false -- ilk oturtmada ölçüleri bir kez yazar (Studio'da uyumsuzluk olursa Output'tan bakılır)

-- Tek ayağa ayakkabı parçasını kurar. Döner: başarılı mı
local function attach(folder, foot, leg, modelName, record)
	local part, baseOffset = ModelLibrary.create(modelName, 1)
	if not part then
		return false
	end
	local baseSize = part.Size
	part.Name = "Shoe"
	part.Anchored = false
	part.Material = Enum.Material.SmoothPlastic
	pcall(function()
		part.CollisionFidelity = Enum.CollisionFidelity.Box -- sadece görsel: hafif tut
	end)

	local weld = Instance.new("Weld")
	weld.Name = "ShoeWeld"
	weld.Part0 = foot
	weld.Part1 = part

	local function fit()
		if not foot.Parent or not part.Parent then
			return
		end
		local shoeSize, cframe = fitFor(foot, leg, baseSize, baseOffset)
		part.Size = shoeSize
		weld.C0 = cframe
	end
	local shoeSize, cframe = fitFor(foot, leg, baseSize, baseOffset)
	part.Size = shoeSize
	weld.C0 = cframe
	if not reported then
		reported = true
		print(`[ShoeWear] {foot.Name} size {foot.Size}, lower leg size {if leg then leg.Size else "none"}, shoe size {shoeSize}, shoe offset {cframe.Position}`)
	end
	part.CFrame = foot.CFrame * cframe
	weld.Parent = part
	part.Parent = folder
	-- ayak parçası ayakkabının içinde kalır, görünmez; asıl şeffaflığı clear geri verir
	if foot:GetAttribute(HIDDEN_ATTRIBUTE) == nil then
		foot:SetAttribute(HIDDEN_ATTRIBUTE, foot.Transparency)
	end
	foot.Transparency = 1

	table.insert(record.fits, fit)
	-- Ayak büyüyüp küçülünce (Humanoid ölçeği) ayakkabı yeniden oturur; aynı karede birden çok değişim tek oturtmaya indirilir
	local pending = false
	table.insert(
		record.connections,
		foot:GetPropertyChangedSignal("Size"):Connect(function()
			if pending then
				return
			end
			pending = true
			task.defer(function()
				pending = false
				fit()
			end)
		end)
	)
	return true
end

-- Karakterdeki ayakkabı parçalarını ve dinleyicilerini kaldırır
function ShoeWear.clear(character)
	local record = active[character]
	if record then
		for _, connection in record.connections do
			connection:Disconnect()
		end
		active[character] = nil
	end
	local folder = character:FindFirstChild(FOLDER_NAME)
	if folder then
		folder:Destroy()
	end
	for _, footName in FEET do
		local foot = character:FindFirstChild(footName)
		local original = foot and foot:GetAttribute(HIDDEN_ATTRIBUTE)
		if foot and original ~= nil then
			foot.Transparency = original
			foot:SetAttribute(HIDDEN_ATTRIBUTE, nil)
		end
	end
end

-- Takılı ayakkabıyı (Config.Items kaydı; nil = yok) ayaklara oturtur. Döner: model giyildi mi
-- (false: ayakkabı yok, model yok ya da R6 gibi ayak parçası yok; çağıran eski yönteme düşebilir)
function ShoeWear.apply(character, shoe)
	ShoeWear.clear(character)
	if not shoe then
		return false
	end
	local modelName = "shoe_" .. shoe.id
	if not ModelLibrary.has(modelName) then
		return false
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	local record = { folder = folder, fits = {}, connections = {} }
	local count = 0
	for _, footName in FEET do
		local foot = character:FindFirstChild(footName)
		local leg = character:FindFirstChild((string.gsub(footName, "Foot", "LowerLeg")))
		if foot and foot:IsA("BasePart") and attach(folder, foot, leg, modelName, record) then
			count += 1
		end
	end
	if count == 0 then
		folder:Destroy()
		return false
	end
	folder.Parent = character
	active[character] = record
	return true
end

-- Ayak ölçüsü değişmiş olabilir (level / rebirth): ayakkabıları yeniden oturtur (Size dinleyicisine ek güvence; LegGrowth çağırır)
function ShoeWear.refit(character)
	local record = active[character]
	if record then
		for _, fit in record.fits do
			fit()
		end
	end
end

return ShoeWear
