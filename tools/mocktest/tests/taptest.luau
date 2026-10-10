-- Dokunmatik 'tap' ile 'kaydırma' ayrımı (client/TapFilter): kaydırma tıklama sayılmaz, kısa ve hareketsiz dokunuş sayılır
local S = require("../cstubs")
local TapFilter = require("./TapFilter")

local filter = TapFilter.new(0.6, 14)
local finger = {} -- (Roblox'ta aynı parmağın InputObject'i)

-- 1) Kısa, hareketsiz dokunuş = tıklama (parmak kalkınca)
filter:began(finger, 100, 200, 10)
assert(filter:ended(finger, 10.12) == true, "kısa dokunuş tıklama sayılmalı")
assert(filter:ended(finger, 10.2) == false, "aynı dokunuş ikinci kez sayılmamalı")

-- 2) Küçük titreme (<= 14 px) hâlâ tap
filter:began(finger, 100, 200, 20)
filter:moved(finger, 106, 205)
assert(filter:ended(finger, 20.1) == true, "küçük titreme tap'i bozmamalı")

-- 3) Kaydırma (kamera döndürme): 14 pikselden fazla kayarsa tıklama DEĞİL, geri dönse bile
filter:began(finger, 100, 200, 30)
filter:moved(finger, 180, 210)
filter:moved(finger, 101, 200)
assert(filter:ended(finger, 30.2) == false, "kaydırma tıklama sayılmamalı")

-- 4) Uzun basış (0.6 sn'den fazla) tıklama değil
filter:began(finger, 100, 200, 40)
assert(filter:ended(finger, 41) == false, "uzun basış tıklama sayılmamalı")

-- 5) İki parmak birbirinden bağımsız: biri kaydırır, öteki dokunur
local a, b = {}, {}
filter:began(a, 50, 50, 50)
filter:began(b, 400, 300, 50.05)
filter:moved(a, 200, 50)
assert(filter:ended(b, 50.1) == true, "dokunan parmak tıklama sayılmalı")
assert(filter:ended(a, 50.3) == false, "kaydıran parmak sayılmamalı")

-- 6) İptal edilen dokunuş sayılmaz; bilinmeyen parmak sayılmaz
filter:began(finger, 1, 1, 60)
filter:cancel(finger)
assert(filter:ended(finger, 60.1) == false)
assert(filter:ended({}, 61) == false)

-- 7) Kalkma olayı hiç gelmeyen eski kayıtlar yeni dokunuşta temizlenir
local lost = {}
filter:began(lost, 1, 1, 100)
filter:began(finger, 1, 1, 200)
assert(rawget(filter.touches, lost) == nil, "5 sn'den eski kayıt silinmeli")
print("tap filter ok")
print("DONE")
