-- GÜNLÜK GİRİŞ PENCERESİ (client/LoginPanel): 7 gün kartı, hazırken 'CLAIM DAY n', değilken geri sayım; durum LoginNext/LoginReady özniteliklerinden okunur.
local S = require("../cstubs")
local Config = require("./Config")
local LoginPanel = require("./LoginPanel")

local function findText(instance, wanted)
	if rawget(instance, "Text") ~= nil and string.find(tostring(rawget(instance, "Text")), wanted, 1, true) then
		return true
	end
	for _, child in rawget(instance, "_children") do
		if findText(child, wanted) then
			return true
		end
	end
	return false
end
local function countNamed(instance, prefix)
	local total = 0
	for _, child in rawget(instance, "_children") do
		if string.sub(tostring(rawget(child, "Name")), 1, #prefix) == prefix then
			total += 1
		end
		total += countNamed(child, prefix)
	end
	return total
end

S.localPlayer:SetAttribute("LoginNext", 3)
S.localPlayer:SetAttribute("LoginReady", true)
local root = S.newInstance("Frame")
local ok, toggle, panel = pcall(LoginPanel.init, root, function() end)
assert(ok, "LoginPanel.init hata verdi: " .. tostring(toggle))
assert(countNamed(root, "LoginDay_") == #Config.Login.Rewards, "her gün için bir kart olmalı")
assert(findText(root, "CLAIM DAY 3"), "hazırken 'CLAIM DAY 3' yazmalı")
assert(findText(root, "CLAIMED") and findText(root, "TODAY!"), "geçen günler 'CLAIMED', bugün 'TODAY!' olmalı")
S.localPlayer:SetAttribute("LoginReady", false)
assert(findText(root, "NEXT REWARD IN") and findText(root, "TOMORROW"), "alınınca geri sayım ve 'TOMORROW' görünmeli")
assert(findText(root, "no streak loss"), "seri kopmaz notu yazmalı")
print("login panel ok")
