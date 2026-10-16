-- KONUŞMA BALONU (client/SpeechBubble): bilgi kutusuna kuyruk (BubbleTail + örtüler) ekler, show() açar (açılış animasyonu), hide() kapatır; kenar değiştirilebilir.
local S = require("../cstubs")
local SpeechBubble = require("./SpeechBubble")

local root = S.newInstance("Frame")
local box = S.newInstance("Frame")
box.Visible = false
box.ZIndex = 30
box.Parent = root
local stroke = S.newInstance("UIStroke")
stroke.Thickness = 3
stroke.Parent = box

local bubble = SpeechBubble.decorate(box, { side = "bottom", at = 0.2 })
local function child(name)
	for _, c in rawget(box, "_children") do
		if rawget(c, "Name") == name then
			return c
		end
	end
	return nil
end
assert(child("BubbleTail") and child("BubbleTailCover") and child("BubbleTailJoint"), "kuyruk ve örtüler kurulmalı")
assert(rawget(child("BubbleTail"), "Rotation") == 45, "kuyruk 45 derece dönük kare")
assert(rawget(child("BubbleTail"), "ZIndex") < 30, "kuyruk kutunun altında (iç yarısı gizlensin)")
bubble.show()
assert(rawget(box, "Visible") == true and bubble.isShown(), "show açmalı")
bubble.setSide("top", 0.8)
bubble.hide()
assert(rawget(box, "Visible") == false, "hide kapatmalı")
print("speech bubble ok")
