if not lib then return end

local Items = require 'modules.items.shared' --[[@as table<string, OxClientItem>]]

local function sendDisplayMetadata(data)
    SendNUIMessage({
		action = 'displayMetadata',
		data = data
	})
end

--- use array of single key value pairs to dictate order
---@param metadata string | table<string, string> | table<string, string>[]
---@param value? string
local function displayMetadata(metadata, value)
	local data = {}

	if type(metadata) == 'string' then
        if not value then return end

        data = { { metadata = metadata, value = value } }
	elseif table.type(metadata) == 'array' then
		for i = 1, #metadata do
			for k, v in pairs(metadata[i]) do
				data[i] = {
					metadata = k,
					value = v,
				}
			end
		end
	else
		for k, v in pairs(metadata) do
			data[#data + 1] = {
				metadata = k,
				value = v,
			}
		end
	end

    if client.uiLoaded then
        return sendDisplayMetadata(data)
    end

    CreateThread(function()
        repeat Wait(100) until client.uiLoaded

        sendDisplayMetadata(data)
    end)
end

exports('displayMetadata', displayMetadata)

---@param _ table?
---@param name string?
---@return table?
local function getItem(_, name)
    if not name then return Items end

	if type(name) ~= 'string' then return end

    name = name:lower()

    if name:sub(0, 7) == 'weapon_' then
        name = name:upper()
    end

    return Items[name]
end

setmetatable(Items --[[@as table]], {
	__call = getItem
})

---@cast Items +fun(itemName: string): OxClientItem
---@cast Items +fun(): table<string, OxClientItem>

local function Item(name, cb)
	local item = Items[name]
	if item then
		if not item.client?.export and not item.client?.event then
			item.effect = cb
		end
	end
end

local ox_inventory = exports[shared.resource]
-----------------------------------------------------------------------------------------------
-- Clientside item use functions
-----------------------------------------------------------------------------------------------

Item('bandage', function(data, slot)
	local maxHealth = GetEntityMaxHealth(cache.ped)
	local health = GetEntityHealth(cache.ped)
	ox_inventory:useItem(data, function(data)
		if data then
			SetEntityHealth(cache.ped, math.min(maxHealth, math.floor(health + maxHealth / 16)))
			lib.notify({ description = 'You feel better already' })
		end
	end)
end)

Item('armour', function(data, slot)
	if GetPedArmour(cache.ped) < 100 then
		ox_inventory:useItem(data, function(data)
			if data then
				SetPlayerMaxArmour(PlayerData.id, 100)
				SetPedArmour(cache.ped, 100)
			end
		end)
	end
end)

client.parachute = false
Item('parachute', function(data, slot)
	if not client.parachute then
		ox_inventory:useItem(data, function(data)
			if data then
				local chute = `GADGET_PARACHUTE`
				SetPlayerParachuteTintIndex(PlayerData.id, -1)
				GiveWeaponToPed(cache.ped, chute, 0, true, false)
				SetPedGadget(cache.ped, chute, true)
				lib.requestModel(1269906701)
				client.parachute = {CreateParachuteBagObject(cache.ped, true, true), slot?.metadata?.type or -1}
				if slot.metadata.type then
					SetPlayerParachuteTintIndex(PlayerData.id, slot.metadata.type)
				end
			end
		end)
	end
end)

Item('phone', function(data, slot)
	local success, result = pcall(function()
		return exports.npwd:isPhoneVisible()
	end)

	if success then
		exports.npwd:setPhoneVisible(not result)
	end
end)

Item('clothing', function(data, slot)
	local metadata = slot.metadata

	if not metadata.drawable then return print('Clothing is missing drawable in metadata') end
	if not metadata.texture then return print('Clothing is missing texture in metadata') end

	if metadata.prop then
		if not SetPedPreloadPropData(cache.ped, metadata.prop, metadata.drawable, metadata.texture) then
			return print('Clothing has invalid prop for this ped')
		end
	elseif metadata.component then
		if not IsPedComponentVariationValid(cache.ped, metadata.component, metadata.drawable, metadata.texture) then
			return print('Clothing has invalid component for this ped')
		end
	else
		return print('Clothing is missing prop/component id in metadata')
	end

	ox_inventory:useItem(data, function(data)
		if data then
			metadata = data.metadata

			if metadata.prop then
				local prop = GetPedPropIndex(cache.ped, metadata.prop)
				local texture = GetPedPropTextureIndex(cache.ped, metadata.prop)

				if metadata.drawable == prop and metadata.texture == texture then
					return ClearPedProp(cache.ped, metadata.prop)
				end

				SetPedPropIndex(cache.ped, metadata.prop, metadata.drawable, metadata.texture, false);
			elseif metadata.component then
				local drawable = GetPedDrawableVariation(cache.ped, metadata.component)
				local texture = GetPedTextureVariation(cache.ped, metadata.component)

				if metadata.drawable == drawable and metadata.texture == texture then
					return
				end

				SetPedComponentVariation(cache.ped, metadata.component, metadata.drawable, metadata.texture, 0);
			end

			local appearance = exports['illenium-appearance']:getPedAppearance(cache.ped)
			TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
		end
	end)
end)

local clothingItems = {
	'clothing_mask', 'clothing_hat', 'clothing_glasses', 'clothing_ear',
	'clothing_shirt', 'clothing_torso', 'clothing_pants', 'clothing_shoes',
	'clothing_bag', 'clothing_vest', 'clothing_accessory', 'clothing_decals',
	'clothing_watch', 'clothing_bracelet',
}

for _, itemName in pairs(clothingItems) do
	Item(itemName, function(data, slot)
		local metadata = slot.metadata
		if not metadata or not metadata.drawable then return end
		if not metadata.texture then metadata.texture = 0 end

		local isProp = metadata.prop ~= nil
		local isComponent = metadata.component ~= nil

		if isProp then
			if not SetPedPreloadPropData(cache.ped, metadata.prop, metadata.drawable, metadata.texture) then
				return
			end
		elseif isComponent then
			if not IsPedComponentVariationValid(cache.ped, metadata.component, metadata.drawable, metadata.texture) then
				return
			end
		else
			return
		end

		ox_inventory:useItem(data, function(data)
			if not data then return end
			metadata = data.metadata

			if isProp then
				local current = GetPedPropIndex(cache.ped, metadata.prop)
				local curTex = GetPedPropTextureIndex(cache.ped, metadata.prop)

				if metadata.drawable == current and metadata.texture == curTex then
					ClearPedProp(cache.ped, metadata.prop)
				else
					SetPedPropIndex(cache.ped, metadata.prop, metadata.drawable, metadata.texture, false)
				end
			elseif isComponent then
				local current = GetPedDrawableVariation(cache.ped, metadata.component)
				local curTex = GetPedTextureVariation(cache.ped, metadata.component)

				if metadata.drawable == current and metadata.texture == curTex then
					SetPedComponentVariation(cache.ped, metadata.component, 0, 0, 0)
				else
					SetPedComponentVariation(cache.ped, metadata.component, metadata.drawable, metadata.texture, 0)
				end
			end

			local appearance = exports['illenium-appearance']:getPedAppearance(cache.ped)
			TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
		end)
	end)
end

Item('clothing_outfit', function(data, slot)
	local metadata = slot.metadata
	if not metadata or not metadata.pieces then return end

	ox_inventory:useItem(data, function(data)
		if not data then return end
		metadata = data.metadata

		local appearance = exports['illenium-appearance']:getPedAppearance(cache.ped)
		local isWearing = true

		for i = 1, #metadata.pieces do
			local piece = metadata.pieces[i]
			if piece.component then
				local cur = GetPedDrawableVariation(cache.ped, piece.component)
				local curT = GetPedTextureVariation(cache.ped, piece.component)
				if cur ~= piece.drawable or curT ~= (piece.texture or 0) then
					isWearing = false
					break
				end
			elseif piece.prop then
				local cur = GetPedPropIndex(cache.ped, piece.prop)
				local curT = GetPedPropTextureIndex(cache.ped, piece.prop)
				if cur ~= piece.drawable or curT ~= (piece.texture or 0) then
					isWearing = false
					break
				end
			end
		end

		for i = 1, #metadata.pieces do
			local piece = metadata.pieces[i]
			if isWearing then
				if piece.component then
					SetPedComponentVariation(cache.ped, piece.component, 0, 0, 0)
				elseif piece.prop then
					ClearPedProp(cache.ped, piece.prop)
				end
			else
				if piece.component then
					SetPedComponentVariation(cache.ped, piece.component, piece.drawable, piece.texture or 0, 0)
				elseif piece.prop then
					SetPedPropIndex(cache.ped, piece.prop, piece.drawable, piece.texture or 0, false)
				end
			end
		end

		appearance = exports['illenium-appearance']:getPedAppearance(cache.ped)
		TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
	end)
end)

-----------------------------------------------------------------------------------------------

exports('Items', function(item) return getItem(nil, item) end)
exports('ItemList', function(item) return getItem(nil, item) end)

return Items
