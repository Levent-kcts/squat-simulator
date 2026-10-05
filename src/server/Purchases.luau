-- Robux satın almalarının sunucu tarafı: MarketplaceService.ProcessReceipt. Ürün ID'leri Config'ten gelir (0 = tanımsız, yok sayılır):
--   * Config.Shop.Products[].productId (boost, Win/kas paketleri)
--   * Config.Trails[].robuxProductId, Config.Auras[].robuxProductId (Backpack > Trails/Auras'taki R$ butonları)
--   * Config.Rebirth.SkipProductId (Rebirth penceresindeki SKIP? butonu)
--   * Config.Offline.DoubleProductId (Offline Earnings penceresindeki DOUBLE IT! butonu)
-- Ödülü PlayerStats.processPurchase verir: aynı satın alma iki kez ödül vermez, verisi kaydedilemeyen oyuncuya verilmez (Roblox daha sonra tekrar dener).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerStats = require(script.Parent.PlayerStats)

local Purchases = {}

-- wallService: rebirth atlatma satın alınırsa duvarları sıfırlamak için; notifyEvent: oyuncuya kısa mesaj
function Purchases.init(wallService, notifyEvent)
	local products = {} -- [productId] = { name, product }

	local function add(productId, name, product)
		if type(productId) == "number" and productId > 0 then
			if products[productId] then
				warn(`[Purchases] Product id {productId} is used twice ({products[productId].name} / {name})`)
			end
			products[productId] = { name = name, product = product }
		end
	end

	for _, trail in Config.Trails do
		add(trail.robuxProductId, trail.name, { kind = "trail", id = trail.id })
	end
	for _, aura in Config.Auras do
		add(aura.robuxProductId, aura.name, { kind = "aura", id = aura.id })
	end
	add(Config.Rebirth.SkipProductId, "Rebirth Skip", { kind = "skip" })
	add(Config.Offline.DoubleProductId, "Double Offline Earnings", { kind = "offlineDouble" })
	for _, product in Config.Shop.Products do
		add(product.productId, product.name, product)
	end

	MarketplaceService.ProcessReceipt = function(receipt)
		local entry = products[receipt.ProductId]
		if not entry then
			warn(`[Purchases] Unknown product id {receipt.ProductId}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- oyuncu çıkmış: bir sonraki girişinde Roblox tekrar dener
		end

		local ok, granted = pcall(PlayerStats.processPurchase, player, tostring(receipt.PurchaseId), entry.product)
		if not ok or not granted then
			if not ok then
				warn(`[Purchases] Could not process receipt: {granted}`)
			end
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		if entry.product.kind == "skip" then
			wallService.resetPlayer(player)
		end
		if entry.product.kind == "offlineDouble" then
			notifyEvent:FireClient(player, true, "Doubled! Your offline earnings were multiplied by 2.")
		else
			notifyEvent:FireClient(player, true, `Thank you! {entry.name} unlocked.`)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Purchases
