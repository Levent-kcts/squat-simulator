-- DÜNYA ETİKETLERİ İÇİN MESAFE ÖLÇEĞİ (QA 2026-10-15): BillboardGui'ler piksel boyutludur (yakınlaşınca ekranı kaplamasın) ama sabit piksel UZAKTA da büyük kalıp birbirine biniyordu.
-- Bu modül kayıtlı etiketlerin boyutunu kameraya uzaklığa göre ayarlar: RefDistance stud'a kadar tam piksel boyutu, daha uzakta orantılı küçülür (en az MinScale), MaxDistance'ta Roblox zaten gizler.
-- Her 0.1 sn'de bir çalışır (performans kuralı: her karede döngü yok). Hata verirse etiketler sabit kalır, oyun etkilenmez.
local Workspace = game:GetService("Workspace")

local LabelScaler = {}

local REF_DISTANCE = 20 -- bu mesafeye kadar tam boyut (stud)
local MIN_SCALE = 0.3
local INTERVAL = 0.1

local entries = {} -- { gui, width, height, ref }
local running = false

-- gui: BillboardGui (Adornee dolu), width/height: tam piksel boyutu, ref: isteğe bağlı tam boyut mesafesi
function LabelScaler.register(gui, width, height, ref)
	table.insert(entries, { gui = gui, width = width, height = height, ref = ref or REF_DISTANCE })
	LabelScaler.start()
	return gui
end

local function update()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local origin = camera.CFrame.Position
	for index = #entries, 1, -1 do
		local entry = entries[index]
		local gui = entry.gui
		if not gui.Parent then
			table.remove(entries, index)
		else
			local adornee = gui.Adornee
			if adornee then
				local target = adornee.Position + gui.StudsOffsetWorldSpace
				local distance = (target - origin).Magnitude
				local scale = math.clamp(entry.ref / math.max(distance, 1), MIN_SCALE, 1)
				gui.Size = UDim2.fromOffset(entry.width * scale, entry.height * scale)
			end
		end
	end
end

function LabelScaler.start()
	if running then
		return
	end
	running = true
	task.spawn(function()
		while true do
			pcall(update)
			task.wait(INTERVAL)
		end
	end)
end

LabelScaler.update = update
LabelScaler.REF_DISTANCE = REF_DISTANCE
LabelScaler.MIN_SCALE = MIN_SCALE

return LabelScaler
