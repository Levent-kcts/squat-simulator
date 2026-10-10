local M = {}
-- ---- Color3 / Vector3 / Enum / Random
local function lerp(a, b, t)
	return a + (b - a) * t
end
local ColorMT = {}
ColorMT.__index = {
	Lerp = function(self, o, t)
		return setmetatable({ R = lerp(self.R, o.R, t), G = lerp(self.G, o.G, t), B = lerp(self.B, o.B, t) }, ColorMT)
	end,
}
local function c(r, g, b)
	return setmetatable({ R = r, G = g, B = b }, ColorMT)
end
M.Color3 = {
	fromRGB = function(r, g, b)
		return c(r / 255, g / 255, b / 255)
	end,
	new = function(r, g, b)
		return c(r, g, b)
	end,
	fromHSV = function(h, s, v)
		return c(v, v, v)
	end,
}
M.Vector3 = {
	new = function(x, y, z)
		return { X = x, Y = y, Z = z }
	end,
	zero = { X = 0, Y = 0, Z = 0 },
}
M.Vector2 = M.Vector3
M.Enum = setmetatable({}, {
	__index = function()
		return setmetatable({}, {
			__index = function(_, k)
				return k
			end,
		})
	end,
})
M.Random = {
	new = function(seed)
		local state = ((seed or 1) * 1103515245 + 12345) % 2147483648
		local r = {}
		function r:NextInteger(a, b)
			state = (state * 1103515245 + 12345) % 2147483648
			return a + (state // 65536) % (b - a + 1)
		end
		function r:NextNumber()
			state = (state * 1103515245 + 12345) % 2147483648
			return (state // 65536) / 32768
		end
		return r
	end,
}

-- Genel amaçlı: her çağrıda boş tablo veren Roblox kurucuları (arayüz/CFrame değerleri testte önemsiz)
local function blank()
	return setmetatable({}, {
		__mul = function(a) return a end,
		__index = function() return function() return blank() end end,
	})
end
local generic = setmetatable({}, { __index = function() return function() return blank() end end })
M.UDim2 = generic
M.UDim = generic
M.CFrame = generic
M.NumberSequence = generic
M.NumberSequenceKeypoint = generic
M.ColorSequence = generic
M.NumberRange = generic
M.TweenInfo = generic
M.G = generic
-- ---- Instance
local InstanceMT = {}
local function newInstance(className)
	local inst = { ClassName = className, _children = {}, _attrs = {}, Name = className }
	return setmetatable(inst, InstanceMT)
end
InstanceMT.__index = function(self, key)
	local methods = {
		FindFirstChild = function(s, name)
			return rawget(s, "_children")[name]
		end,
		FindFirstChildOfClass = function()
			return nil
		end,
		SetAttribute = function(s, k, v)
			rawget(s, "_attrs")[k] = v
		end,
		GetAttribute = function(s, k)
			return rawget(s, "_attrs")[k]
		end,
		Destroy = function() end,
	}
	return methods[key]
end
InstanceMT.__newindex = function(self, key, value)
	rawset(self, key, value)
	if key == "Parent" and value ~= nil and type(value) == "table" and rawget(value, "_children") then
		rawget(value, "_children")[rawget(self, "Name")] = self
	end
end
M.Instance = { new = newInstance }
M.newInstance = newInstance
-- ---- task
local delayed = {}
M.delayed = delayed
M.task = {
	spawn = function(f, ...)
		local ok, err = pcall(f, ...)
		if not ok and not string.find(tostring(err), "__stop__") then
			print("task.spawn error:", err)
		end
	end,
	delay = function(t, f)
		table.insert(delayed, { t, f })
	end,
	wait = function()
		error("__stop__")
	end,
	defer = function(f, ...)
		f(...)
	end,
}
M.warn = function(...)
	print("WARN", ...)
end
-- ---- game servisleri
local events = {}
M.events = events
local function signal(name)
	return {
		Connect = function(_, f)
			events[name] = f
			return { Disconnect = function() end }
		end,
	}
end
local datastore = {}
M.datastore = datastore
M.datastoreFailures = 0
local function encode(x)
	local t = type(x)
	if t == "table" then
		local parts = {}
		if #x > 0 then
			for _, y in x do
				table.insert(parts, encode(y))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		for k, y in x do
			table.insert(parts, '"' .. tostring(k) .. '":' .. encode(y))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	elseif t == "string" then
		return '"' .. x .. '"'
	end
	return tostring(x)
end
-- Roblox PolicyService taklidi: M.policy.restricted = true ise 'ArePaidRandomItemsRestricted' döner (test için)
M.policy = { restricted = false }
local services = {
	PolicyService = {
		GetPolicyInfoForPlayerAsync = function()
			return { ArePaidRandomItemsRestricted = M.policy.restricted, IsPaidItemTradingAllowed = true }
		end,
	},
	DataStoreService = {
		GetDataStore = function()
			return {
				GetAsync = function(_, key)
					return datastore[key]
				end,
				UpdateAsync = function(_, key, fn)
					if M.datastoreFailures > 0 then -- test: DataStore geçici hatası
						M.datastoreFailures -= 1
						error("mock datastore failure")
					end
					local updated = fn(datastore[key])
					if updated ~= nil then -- Roblox'ta işlev nil dönerse güncelleme İPTAL olur, eski değer kalır
						datastore[key] = updated
					end
					return datastore[key]
				end,
			}
		end,
	},
	Players = {
		PlayerAdded = signal("PlayerAdded"),
		PlayerRemoving = signal("PlayerRemoving"),
		GetPlayers = function()
			return {}
		end,
		GetPlayerFromCharacter = function()
			return nil
		end,
	},
	HttpService = {
		JSONEncode = function(_, v)
			return encode(v)
		end,
		GenerateGUID = function()
			return "mock-server-guid"
		end,
	},
	ReplicatedStorage = setmetatable({}, {
		__index = function(_, k)
			if k == "WaitForChild" then
				return function(self)
					return self
				end
			end
		end,
	}),
}
M.game = {
	GetService = function(_, name)
		return services[name] or setmetatable({}, {
			__index = function()
				return function() end
			end,
		})
	end,
	BindToClose = function() end,
}
M.workspace = {
	GetServerTimeNow = function()
		return os.time() + 0.0
	end,
}
return M
