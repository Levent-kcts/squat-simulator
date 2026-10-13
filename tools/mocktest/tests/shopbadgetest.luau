-- YENİ İKSİR ROZETİ (client/ShopPanel; sahibi 'alınan potionlar markete gittiğinde marketin köşesinde kırmızı bir yuvarlak olsun, yeni potion geldiğini göstermek için' dedi):
-- Shop düğmesinin köşesinde kırmızı yuvarlak (yeni iksir sayısı). Girişte envanterde zaten olan iksirler yeni sayılmaz (DataLoaded'dan sonra ölçülür),
-- sonradan gelen iksir sayıyla gösterilir, Shop açılınca kalkar, iksir içmek (azalma) rozet çıkarmaz.
local S = require("../cstubs")
local ShopPanel = require("./ShopPanel")

local function find(instance, name)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "Name") == name then
			return child
		end
		local deeper = find(child, name)
		if deeper then
			return deeper
		end
	end
	return nil
end
local function childText(instance)
	for _, child in rawget(instance, "_children") do
		if rawget(child, "ClassName") == "TextLabel" then
			return rawget(child, "Text")
		end
	end
	return nil
end

local player = S.localPlayer
player:SetAttribute("PotionItems", "luck15:2") -- kayıt henüz yüklenmedi (DataLoaded yok); envanterde iksir var
local root = S.newInstance("Frame")
local shopButton = S.newInstance("TextButton")
shopButton.Parent = root
local ok, toggle = pcall(ShopPanel.init, root, function() end, shopButton)
assert(ok, "ShopPanel.init hata verdi: " .. tostring(toggle))
local badge = find(shopButton, "PotionBadge")
assert(badge, "Shop düğmesinde yeni iksir rozeti olmalı")
local function visible()
	return rawget(badge, "Visible") == true
end
local hasCorner = false
for _, child in rawget(badge, "_children") do
	hasCorner = hasCorner or rawget(child, "ClassName") == "UICorner"
end
assert(hasCorner, "rozet yuvarlak (UICorner) olmalı")
assert(not visible(), "kayıt yüklenmeden rozet görünmemeli")

player:SetAttribute("DataLoaded", true)
assert(not visible(), "girişte envanterde zaten olan iksir rozet çıkarmamalı")
player:SetAttribute("PotionItems", "luck15:5")
assert(visible() and childText(badge) == "3", "çarktan/Gifts'ten gelen 3 yeni iksir rozette '3' yazmalı: " .. tostring(childText(badge)))
player:SetAttribute("PotionItems", "luck15:5,wins15:1")
assert(visible() and childText(badge) == "4", "rozet güncellenmeli: " .. tostring(childText(badge)))
player:SetAttribute("PotionItems", "luck15:5,wins15:12")
assert(childText(badge) == "9+", "9'dan fazlasında '9+' yazmalı: " .. tostring(childText(badge)))

toggle() -- Shop açılır: iksirleri gördü
assert(not visible(), "Shop açılınca rozet kalkmalı")
toggle() -- kapanır
player:SetAttribute("PotionItems", "luck15:5,wins15:13")
assert(visible() and childText(badge) == "1", "Shop kapandıktan sonra gelen iksir yeniden rozet çıkarmalı: " .. tostring(childText(badge)))
player:SetAttribute("PotionItems", "luck15:4,wins15:12") -- iksir içildi (azaldı)
assert(not visible(), "iksir içmek rozet çıkarmamalı")
player:SetAttribute("PotionItems", "luck15:4,wins15:12,rainbow15:1")
assert(visible() and childText(badge) == "1", "içtikten sonra yeni iksir yine rozet çıkarmalı")
player:SetAttribute("PotionItems", "")
assert(not visible(), "envanter boşalınca rozet kalkmalı")
print("shop potion badge ok")
