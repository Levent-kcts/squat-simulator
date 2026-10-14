-- SEZONLUK ETKİNLİK: SPOOKY GYM (Config.Event; 2026-10-14 büyüme planı 2.1). Etkinlik penceresi içinde duvar kırınca ve aşama bitirince CANDY kazanılır (satılmaz); Candy ile DETERMİNİSTİK mağazadan (rastgele ürün yok) iksir, Win, kas, unvan ve iz alınır;
-- toplam Candy kilometre taşları ücretsiz ödül verir. Durum PlayerStats profilinde kayıtlıdır (profile.event); bu modül mantığı yürütür ve istemciye öznitelik olarak yayınlar:
--   Candy, CandyTotal (sayı), EventClaimed ('1,2' alınan kilometre taşları), EventBought ('rainbow:2,title:1'), EventPerks ('title,trail'), EventTitle (unvan yazısı ya da boş; isim etiketi okur).
-- Etkinlik kimliği (Config.Event.Id) değişince Candy/kilometre taşları/alımlar sıfırlanır, unvan ve iz (perks) KALIR. Zaman penceresi ServerEvents.seasonActive'dedir.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local ServerEvents = require(script.Parent.ServerEvents)

local SeasonEvent = {}

local PlayerStats -- init'te verilir (PlayerStats bu modülü yüklemez: dairesel bağımlılık olmasın)

local function settings()
	return Config.Event
end

local function itemById(itemId)
	for _, item in settings().Items do
		if item.id == itemId then
			return item
		end
	end
	return nil
end

-- Oyuncunun etkinlik durumu; etkinlik kimliği değiştiyse Candy kısmı sıfırlanır (perks kalıcı)
local function ensure(player)
	local state = PlayerStats.eventState(player)
	if not state then
		return nil
	end
	if state.id ~= settings().Id then
		state.id = settings().Id
		state.candy = 0
		state.total = 0
		state.claimed = {}
		state.bought = {}
	end
	return state
end

local function keysToString(set)
	local list = {}
	for key in set do
		table.insert(list, tostring(key))
	end
	table.sort(list)
	return table.concat(list, ",")
end

local function publish(player)
	local state = ensure(player)
	if not state then
		return
	end
	player:SetAttribute("Candy", state.candy)
	player:SetAttribute("CandyTotal", state.total)
	player:SetAttribute("EventClaimed", keysToString(state.claimed))
	local bought = {}
	for itemId, count in state.bought do
		table.insert(bought, `{itemId}:{count}`)
	end
	table.sort(bought)
	player:SetAttribute("EventBought", table.concat(bought, ","))
	player:SetAttribute("EventPerks", keysToString(state.perks))
	player:SetAttribute("EventTitle", if state.perks.title then settings().Title else "")
end

function SeasonEvent.active()
	return ServerEvents.seasonActive()
end

-- Candy ekler (etkinlik açıksa). Yeni bir kilometre taşına ulaşıldıysa küçük bir bildirim gider. Dönüş: eklendi mi
function SeasonEvent.addCandy(player, amount)
	if not settings() or not SeasonEvent.active() or type(amount) ~= "number" or amount <= 0 then
		return false
	end
	local state = ensure(player)
	if not state then
		return false
	end
	local before = state.total
	state.candy += amount
	state.total += amount
	for index, milestone in settings().Milestones do
		if before < milestone.candy and state.total >= milestone.candy and not state.claimed[index] then
			PlayerStats.toast(player, `{settings().Emoji} Candy milestone reached! Open {settings().Name} to claim your reward.`)
			break
		end
	end
	publish(player)
	PlayerStats.markDirty(player)
	return true
end

-- Mağazadan ürün al. Dönüş: başarılı mı, mesaj
function SeasonEvent.buy(player, itemId)
	if not settings() or not SeasonEvent.active() then
		return false, `{settings() and settings().Name or "The event"} has ended.`
	end
	local state = ensure(player)
	local item = itemById(itemId)
	if not state or not item then
		return false, "That item does not exist."
	end
	local count = state.bought[item.id] or 0
	if count >= item.limit then
		return false, if item.limit == 1 then "You already have this." else `Limit reached ({item.limit}).`
	end
	if item.perk and state.perks[item.perk] then
		return false, "You already have this."
	end
	if state.candy < item.price then
		return false, `Not enough {settings().CurrencyName} (need {item.price}).`
	end
	state.candy -= item.price
	state.bought[item.id] = count + 1
	local message
	if item.reward then
		local text = PlayerStats.giveReward(player, item.reward, "event_" .. item.id)
		message = `Bought {item.name}: {text or "done"}!`
		if item.reward.potions then
			message ..= " Potions are in Shop > Potions."
		end
	elseif item.perk == "title" then
		state.perks.title = true
		message = `You are now the {settings().Title}! See your name tag.`
	elseif item.perk == "trail" then
		state.perks.trail = true
		PlayerStats.grantTrail(player, settings().Trail.id)
		PlayerStats.equipTrail(player, settings().Trail.id)
		message = `Bought {item.name}! It is equipped (Backpack > Trails).`
	else
		message = `Bought {item.name}!`
	end
	publish(player)
	PlayerStats.markDirty(player)
	return true, message
end

-- Kilometre taşı ödülünü al. Dönüş: başarılı mı, mesaj
function SeasonEvent.claim(player, index)
	if not settings() or not SeasonEvent.active() then
		return false, `{settings() and settings().Name or "The event"} has ended.`
	end
	local state = ensure(player)
	local milestone = settings().Milestones[index]
	if not state or not milestone then
		return false, "That reward does not exist."
	end
	if state.claimed[index] then
		return false, "You already claimed this reward."
	end
	if state.total < milestone.candy then
		return false, `Collect {milestone.candy} {settings().CurrencyName} to unlock this reward.`
	end
	state.claimed[index] = true
	local text = PlayerStats.giveReward(player, milestone.reward, "event_milestone_" .. index)
	publish(player)
	PlayerStats.markDirty(player)
	return true, `Reward claimed: {text or "done"}!{if milestone.reward.potions then " Potions are in Shop > Potions." else ""}`
end

function SeasonEvent.init(stats)
	PlayerStats = stats
	if not settings() then
		return
	end
	PlayerStats.listen("walls", function(player, count)
		SeasonEvent.addCandy(player, count * settings().CandyPerWall)
	end)
	PlayerStats.listen("stagewin", function(player)
		SeasonEvent.addCandy(player, settings().CandyPerStage)
	end)
	PlayerStats.onLoaded(publish)
end

return SeasonEvent
