-- Soldaki menü pencerelerinin (Shop, Rebirth, Settings, Backpack > Trails/Auras, Pets, Gifts) ortak yöneticisi:
--  * Bir pencere açılınca açık olan diğeri kapanır (aynı anda tek pencere).
--  * Pencere soldan kayarak gelir, kapanırken sola kayarak gider.
-- Pencereler artık `panel.Visible` ile değil PanelManager.show / hide / toggle ile açılıp kapanır; açık mı sorusu için `PanelManager.isOpen(panel)`
-- kullanılır (kapanma animasyonu sürerken panel.Visible hâlâ true olduğu için ona bakma). Mantıksal durum ayrıca panelin "PanelOpen" özniteliğindedir.
local TweenService = game:GetService("TweenService")

local PanelManager = {}

local SLIDE_IN = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLIDE_OUT = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local MARGIN = 60 -- ekranın dışına çıkarken pencerenin sağ kenarı sol kenardan bu kadar ötede biter
local SWAP_DELAY = 0.12 -- başka pencere kapanırken yenisi biraz geç gelir (ikisi üst üste kaymasın)

-- [Frame] = { home = asıl konum, open = mantıksal durum, token = animasyon sırası, exclusive = diğerlerini kapatır mı }
local entries = {}

-- Pencereyi ilk kullanışta kaydeder; asıl konumu (home) o anki Position'dır. exclusive = false: diğer pencereleri kapatmaz/onlarla kapanmaz (Backpack sekmeleri gibi)
function PanelManager.register(frame, exclusive)
	local entry = entries[frame]
	if not entry then
		entry = { home = frame.Position, open = frame.Visible, token = 0, exclusive = true }
		entries[frame] = entry
		frame:SetAttribute("PanelOpen", entry.open)
	end
	if exclusive ~= nil then
		entry.exclusive = exclusive
	end
	return entry
end

-- Ekranın solunun dışındaki konum (pencerenin Y konumu aynı kalır)
local function offscreen(frame, home)
	local width = frame.AbsoluteSize.X
	if width <= 0 then
		width = frame.Size.X.Offset
	end
	return UDim2.new(0, -(width * (1 - frame.AnchorPoint.X)) - MARGIN, home.Y.Scale, home.Y.Offset)
end

function PanelManager.isOpen(frame)
	return PanelManager.register(frame).open
end

function PanelManager.hide(frame)
	local entry = PanelManager.register(frame)
	if not entry.open then
		return
	end
	entry.open = false
	frame:SetAttribute("PanelOpen", false)
	entry.token += 1
	local token = entry.token
	if not frame.Visible then
		return -- henüz görünmemiş (gecikmeli açılış beklerken kapatıldı)
	end
	local tween = TweenService:Create(frame, SLIDE_OUT, { Position = offscreen(frame, entry.home) })
	tween.Completed:Connect(function()
		-- Bu arada yeniden açıldıysa (token değiştiyse) dokunma
		if entry.token == token then
			frame.Visible = false
			frame.Position = entry.home
		end
	end)
	tween:Play()
end

function PanelManager.show(frame)
	local entry = PanelManager.register(frame)
	if entry.open then
		return
	end
	entry.open = true
	frame:SetAttribute("PanelOpen", true)
	entry.token += 1
	local token = entry.token

	-- Aynı gruptaki açık pencereleri kapat
	local closedOther = false
	if entry.exclusive then
		for other, otherEntry in entries do
			if other ~= frame and otherEntry.exclusive and otherEntry.open then
				PanelManager.hide(other)
				closedOther = true
			end
		end
	end

	local function slideIn()
		if entry.token ~= token then
			return
		end
		if not frame.Visible then
			frame.Position = offscreen(frame, entry.home)
			frame.Visible = true
		end
		TweenService:Create(frame, SLIDE_IN, { Position = entry.home }):Play()
	end
	if closedOther then
		task.delay(SWAP_DELAY, slideIn)
	else
		slideIn()
	end
end

function PanelManager.toggle(frame)
	if PanelManager.isOpen(frame) then
		PanelManager.hide(frame)
	else
		PanelManager.show(frame)
	end
end

return PanelManager
