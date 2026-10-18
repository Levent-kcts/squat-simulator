-- Tıklama hareketleri: duvara yakınken tekme, uzakken squat.
-- Hazır animasyon dosyası (asset) gerekmesin diye eklemlerin (Motor6D) C0 değerleri kodla oynatılır.
-- Bu sadece görseldir: her istemci hareketi kendi ekranında oynatır (diğer oyuncularınki sunucudan haber gelince).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Moves = {}

-- Hareketler çalışmıyorsa true yap: Output penceresine ne olduğunu yazar
local DEBUG = false

-- Pozlar derece cinsindendir. Anahtar eksikse eklem dinlenme pozisyonunda kalır.
-- Bacak/kol için + = öne doğru, belden + = geriye yaslanma, - = öne eğilme. Drop = gövdenin çökme oranı (0-1).
-- '<eklem>Y' anahtarı aynı eklemi dikey eksende döndürür (omuzlarda: + sağ kolu, - sol kolu gövdenin ortasına çeker).
-- TEKME (2026-10-18, sahibi 'duvara vurma animasyonunu geliştir, iki el birbirine birleşsin ve tekme atsın' dedi): kollar öne kalkıp elleri göğsün
-- önünde birleştirir (dövüş duruşu), sağ diz kalkar, sonra bacak duvara uzanır; eller tekme boyunca birleşik kalır.
-- tools/animations/make_kick.py HANDS ile AYNI değerler (gerçek animasyon ve yedek aynı görünsün)
local HANDS_TOGETHER = { RightShoulder = 70, RightShoulderY = 65, LeftShoulder = 70, LeftShoulderY = -65, RightElbow = 40, LeftElbow = 40 }
local KICK_CHAMBER = {
	RightHip = 70, RightKnee = -95, LeftHip = 6, LeftKnee = -14, Waist = 6,
	RightShoulder = HANDS_TOGETHER.RightShoulder, RightShoulderY = HANDS_TOGETHER.RightShoulderY,
	LeftShoulder = HANDS_TOGETHER.LeftShoulder, LeftShoulderY = HANDS_TOGETHER.LeftShoulderY,
	RightElbow = HANDS_TOGETHER.RightElbow, LeftElbow = HANDS_TOGETHER.LeftElbow,
}
local KICK_END = {
	RightHip = 95, RightKnee = 0, LeftHip = 8, LeftKnee = -12, Waist = 12,
	RightShoulder = HANDS_TOGETHER.RightShoulder, RightShoulderY = HANDS_TOGETHER.RightShoulderY,
	LeftShoulder = HANDS_TOGETHER.LeftShoulder, LeftShoulderY = HANDS_TOGETHER.LeftShoulderY,
	RightElbow = HANDS_TOGETHER.RightElbow, LeftElbow = HANDS_TOGETHER.LeftElbow,
}
Moves.KICK_END = KICK_END -- testler poza bakar
local SQUAT_DOWN = {
	RightHip = 85, LeftHip = 85, RightKnee = -95, LeftKnee = -95,
	Waist = -20, RightShoulder = 80, LeftShoulder = 80, Drop = 1,
}

local MOVES = {
	Kick = {
		duration = 0.4,
		keys = {
			{ t = 0, pose = {} },
			{ t = 0.10, pose = KICK_CHAMBER },
			{ t = 0.20, pose = KICK_END },
			{ t = 0.28, pose = KICK_END },
			{ t = 0.40, pose = {} },
		},
	},
	Squat = {
		duration = 0.5,
		keys = {
			{ t = 0, pose = {} },
			{ t = 0.18, pose = SQUAT_DOWN },
			{ t = 0.30, pose = SQUAT_DOWN },
			{ t = 0.50, pose = {} },
		},
	},
}

-- Süreleri Config.MoveDuration belirler (sunucu da aynı süreyi kullanır). Anahtar kare zamanları bu süreye göre ölçeklenir.
for name, move in MOVES do
	local last = move.keys[#move.keys].t
	local duration = Config.MoveDuration[name]
	for _, key in move.keys do
		key.t = key.t / last * duration
	end
	move.duration = duration
end

-- Eklem adları: R15 adı önce, R6 adı sonra denenir
local JOINTS = {
	Root = { "RootJoint" },
	Waist = { "Waist" },
	RightHip = { "RightHip", "Right Hip" },
	LeftHip = { "LeftHip", "Left Hip" },
	RightKnee = { "RightKnee" },
	LeftKnee = { "LeftKnee" },
	RightShoulder = { "RightShoulder", "Right Shoulder" },
	LeftShoulder = { "LeftShoulder", "Left Shoulder" },
	RightElbow = { "RightElbow" },
	LeftElbow = { "LeftElbow" },
}

local active = {} -- [character] = { move, start, rig }

-- YÜRÜRKEN HAREKETLER SÜRER (2026-10-18, sahibi 'yürürken squat yapmaya devam etsin' dedi; sonra 'duvara giderken squat yapıyorsak tekme atmıyor' dedi:
-- duvara doğru hâlâ hareket eden oyuncunun tekmesi sessizce atlanıyordu, eller-önde pozu da bu yüzden hiç görünmedi). WALK_STOPS boş: hiçbir hareket yürüyünce kesilmez.
-- Niyete (MoveDirection) DEĞİL gerçek hıza bakılır: duvara dayanıp ileri tuşuna basan oyuncu durduğu için tekmesi kesilmez. Kendi karakterimizde de diğerlerinde de aynı ölçü (kök parçanın yatay hızı).
local WALK_SPEED_LIMIT = 4 -- stud/sn; yürüme hızı 16, dururken ~0
local WALK_STOPS = {} -- yürürken oynamayan hareketler (şimdilik yok)
local function isWalking(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	-- pcall: hız okunamazsa (ör. test taklidi) 'yürümüyor' say, hareket oynasın
	local ok, speed = pcall(function()
		local velocity = root.AssemblyLinearVelocity
		return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	end)
	return ok and type(speed) == "number" and speed > WALK_SPEED_LIMIT
end

local function heightScaleOf(humanoid)
	local height = humanoid and humanoid:FindFirstChild("BodyHeightScale")
	return height and height.Value or 1
end

-- Eklem bilgileri her harekette yeniden okunur (karakter boyutu değişmiş olabilir, eski değerler geçersiz kalır)
local function getRig(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rig = {
		heightScale = heightScaleOf(humanoid),
		joints = {},
		drop = 0.3,
		humanoid = humanoid,
		hip = humanoid and humanoid.HipHeight or 0,
		isLocal = character == Players.LocalPlayer.Character,
	}
	for key, names in JOINTS do
		for _, name in names do
			local joint = character:FindFirstChild(name, true)
			-- Yeni avatarlar AnimationConstraint, eski avatarlar Motor6D kullanır; ikisinde de C0 vardır
			if joint and joint:IsA("Motor6D") then
				rig.joints[key] = { motor = joint, c0 = joint.C0 }
				break
			elseif joint and joint:IsA("AnimationConstraint") and joint.Attachment0 then
				-- AnimationConstraint.C0 salt okunurdur; asıl değer Attachment0.CFrame'dedir
				rig.joints[key] = { attachment = joint.Attachment0, c0 = joint.Attachment0.CFrame }
				break
			end
		end
	end

	-- R15'te dizler bükülür, gövde uyluk boyuna yakın çöker. R6'da bacaklar sabit, az çöker.
	local upperLeg = character:FindFirstChild("RightUpperLeg")
	if rig.joints.RightKnee and upperLeg then
		rig.drop = upperLeg.Size.Y * 0.9
	end

	return rig
end

local function smooth(x)
	return x * x * (3 - 2 * x)
end

-- Zaman t'deki pozu iki anahtar kare arasında yumuşakça hesaplar
local function sample(move, t)
	local keys = move.keys
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if t <= b.t then
			local s = smooth(math.clamp((t - a.t) / (b.t - a.t), 0, 1))
			local pose = {}
			for key, value in a.pose do
				pose[key] = value * (1 - s)
			end
			for key, value in b.pose do
				pose[key] = (pose[key] or 0) + value * s
			end
			return pose
		end
	end
	return {}
end

-- Eklemin Part0'a göre dönüş/konum ayarı: Motor6D için C0, AnimationConstraint için Attachment0.CFrame
local function setBase(joint, cframe)
	if joint.motor then
		joint.motor.C0 = cframe
	else
		joint.attachment.CFrame = cframe
	end
end

-- Eklemin ŞU ANKİ taban değeri: karakter hareket sırasında büyürse/küçülürse (level atlama, rebirth) Roblox eklem konumlarını yeni ölçüye göre günceller;
-- konum her karede buradan okunur, böylece hareket SIFIRLANMADAN yeni ölçüde kaldığı yerden sürer
local function currentBase(joint)
	return if joint.motor then joint.motor.C0 else joint.attachment.CFrame
end

-- Hareket başladığından beri boy ölçeği kaç katına çıktı (1 = değişmedi); HipHeight ve çökme miktarı bununla ölçeklenir
local function ratioOf(rig)
	return heightScaleOf(rig.humanoid) / rig.heightScale
end

local function apply(rig, pose)
	-- Gövdenin çökmesi: kendi karakterimizde HipHeight azaltılır (ayaklar yerde kalır, gerçek fizikle iner).
	-- Diğer oyuncuların karakterinin konumu bizde simüle edilmediği için orada sadece kök eklem oynatılır.
	local ratio = ratioOf(rig)
	local dropAmount = rig.drop * ratio * (pose.Drop or 0)
	if rig.isLocal and rig.humanoid then
		rig.humanoid.HipHeight = math.max(0, rig.hip * ratio - dropAmount)
	end

	for key, joint in rig.joints do
		if key == "Root" then
			if not rig.isLocal then
				setBase(joint, CFrame.new(0, -dropAmount, 0) * joint.c0)
			end
		else
			local angle = math.rad(pose[key] or 0)
			local turn = math.rad(pose[key .. "Y"] or 0)
			-- Eklem konumu (güncel) sabit kalır: önce X ekseninde (öne/arkaya), sonra dikey eksende (içe/dışa) döner
			setBase(joint, CFrame.new(currentBase(joint).Position) * CFrame.Angles(0, turn, 0) * CFrame.Angles(angle, 0, 0) * joint.c0.Rotation)
		end
	end
end

-- Hareket bitince eklemler dinlenme dönüşüne döner; KONUMLAR güncel (ölçek hareket sırasında değiştiyse yeni ölçüdeki) değerdir. HipHeight de güncel boya göre asıl değerine döner.
local function restore(rig)
	if rig.isLocal and rig.humanoid then
		rig.humanoid.HipHeight = rig.hip * ratioOf(rig)
	end
	for key, joint in rig.joints do
		if key == "Root" then
			setBase(joint, joint.c0)
		else
			setBase(joint, CFrame.new(currentBase(joint).Position) * joint.c0.Rotation)
		end
	end
end

-- GERÇEK ANİMASYON (Config.Animations[name] > 0): Animator ile oynatılır, hızı MoveDuration'a ölçeklenir. Kendi karakterimizde oynatılan iz Roblox tarafından
-- diğer oyunculara kendiliğinden iletilir; bu yüzden başkasının karakterinde (MoveEvent) tekrar oynatılmaz. Yüklenemezse yedek (kodla çizilen) hareket oynar.
local tracks = {} -- [humanoid] = { [ad] = AnimationTrack }
local function playAnimation(character, humanoid, name)
	local id = Config.Animations and Config.Animations[name]
	if type(id) ~= "number" or id <= 0 then
		return false
	end
	if character ~= Players.LocalPlayer.Character then
		return true -- başkasının animasyonu Roblox'tan zaten geliyor
	end
	local ok, played = pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
		tracks[humanoid] = tracks[humanoid] or {}
		local track = tracks[humanoid][name]
		if not track then
			local animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. id
			track = animator:LoadAnimation(animation)
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = false
			tracks[humanoid][name] = track
		end
		local length = track.Length
		local speed = if length and length > 0 then length / Config.MoveDuration[name] else 1
		track:Play(0.05, 1, speed)
		return true
	end)
	return ok and played
end

function Moves.play(character, name)
	local move = MOVES[name]
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not move or not humanoid or humanoid.Health <= 0 then
		return
	end
	if playAnimation(character, humanoid, name) then
		-- Kodla çizilen bir hareket (ör. yürürken squat) sürüyorsa bırak: eklemler gerçek animasyonla çakışmasın
		local running = active[character]
		if running then
			restore(running.rig)
			active[character] = nil
		end
		return
	end

	local state = active[character]
	if state and state.name == name then
		return -- aynı hareket zaten oynuyor, bitince yenisi başlar
	end
	if WALK_STOPS[name] and isWalking(character) then
		return -- yürürken tekme başlamaz (görsel; kas ve hasar sunucuda yine sayılır)
	end

	local rig = getRig(character)
	if DEBUG then
		local count = 0
		for _ in rig.joints do
			count += 1
		end
		print(`[Moves] {name} on {character.Name}: {count} joints found, drop {rig.drop}`)
		if count == 0 then
			warn("[Moves] No joints found, the animation cannot play on this character")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			print(`[Moves] RigType: {humanoid and humanoid.RigType.Name}, children: {#character:GetChildren()}, descendants: {#character:GetDescendants()}`)
			for _, descendant in character:GetDescendants() do
				if descendant:IsA("JointInstance") or descendant:IsA("Constraint") then
					print(`[Moves] joint-like: {descendant.ClassName} "{descendant.Name}" in {descendant.Parent and descendant.Parent.Name}`)
				end
			end
		end
	end

	active[character] = { name = name, move = move, start = os.clock(), rig = rig }
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for character, state in active do
		local t = now - state.start
		local humanoid = state.rig.humanoid
		if state.rig.isLocal and humanoid and humanoid.FloorMaterial == Enum.Material.Air then
			-- Hareket sırasında zıpladı: bacak sallanması karakteri döndürmesin diye hareketi hemen bırak
			restore(state.rig)
			active[character] = nil
		elseif character.Parent and WALK_STOPS[state.name] and isWalking(character) then
			-- Tekme sırasında yürümeye başladı: hareketi hemen bırak (squat yürürken sürer)
			restore(state.rig)
			active[character] = nil
		elseif t >= state.move.duration or not character.Parent then
			restore(state.rig)
			active[character] = nil
		else
			local ok, err = pcall(apply, state.rig, sample(state.move, t))
			if not ok then
				warn(`[Moves] Animation stopped: {err}`)
				active[character] = nil
			end
		end
	end
end)

return Moves
