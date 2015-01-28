function Player:onBrowseField(position)
	return true
end

function Player:onLook(thing, position, distance)
	local description = "You see " .. thing:getDescription(distance)
	if self:getGroup():getAccess() then
		if thing:isItem() then
			description = string.format("%s\nItemID: [%d]", description, thing:getId())

			local actionId = thing:getActionId()
			if actionId ~= 0 then
				description = string.format("%s, ActionID: [%d]", description, actionId)
			end
			
			local uniqueId = thing:getAttribute(ITEM_ATTRIBUTE_UNIQUEID)
			if uniqueId > 0 and uniqueId < 65536 then
				description = string.format("%s, UniqueId: [%d]", description, uniqueId)
			end
			
			description = description .. "."
			local itemType = thing:getType()
			
			local transformEquipId = itemType:getTransformEquipId()
			local transformDeEquipId = itemType:getTransformDeEquipId()
			if transformEquipId ~= 0 then
				description = string.format("%s\nTransformTo: [%d] (onEquip).", description, transformEquipId)
			elseif transformDeEquipId ~= 0 then
				description = string.format("%s\nTransformTo: [%d] (onDeEquip).", description, transformDeEquipId)
			end

			local decayId = itemType:getDecayId()
			if decayId ~= -1 then
				description = string.format("%s\nDecayTo: [%d]", description, decayId)
			end
		elseif thing:isCreature() then
			local str = "%s\nHealth: [%d / %d]"
			if thing:getMaxMana() > 0 then
				str = string.format("%s, Mana: [%d / %d]", str, thing:getMana(), thing:getMaxMana())
			end
			description = string.format(str, description, thing:getHealth(), thing:getMaxHealth()) .. "."
		end
		
		local position = thing:getPosition()
		description = string.format(
			"%s\nPosition: [X: %d] [Y: %d] [Z: %d].",
			description, position.x, position.y, position.z
		)
		
		if thing:isCreature() then
			if thing:isPlayer() then
				description = string.format("%s\nIP: [%s].", description, Game.convertIpToString(thing:getIp()))
			end
		end
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInBattleList(creature, distance)
	local description = "You see " .. creature:getDescription(distance)
	if self:getGroup():getAccess() then
		local str = "%s\nHealth: [%d / %d]"
		if creature:getMaxMana() > 0 then
			str = string.format("%s, Mana: [%d / %d]", str, creature:getMana(), creature:getMaxMana())
		end
		description = string.format(str, description, creature:getHealth(), creature:getMaxHealth()) .. "."

		local position = creature:getPosition()
		description = string.format(
			"%s\nPosition: [X: %d] [Y: %d] [Z: %d].",
			description, position.x, position.y, position.z
		)
		
		if creature:isPlayer() then
			description = string.format("%s\nIP: [%s].", description, Game.convertIpToString(creature:getIp()))
		end
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInTrade(partner, item, distance)
	self:sendTextMessage(MESSAGE_INFO_DESCR, "You see " .. item:getDescription(distance))
end

function Player:onLookInShop(itemType, count)
	return true
end

function Player:onMoveItem(item, count, fromPosition, toPosition)
	return true
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
	return true
end

function Player:onTurn(direction)
	return true
end

function Player:onTradeRequest(target, item)
	return true
end

function Player:onTradeAccept(target, item, targetItem)
	return true
end

function Player:onGainExperience(source, exp, rawExp)
	return exp
end

function Player:onLoseExperience(exp)
	return exp
end

function Player:onGainSkillTries(skill, tries)
	if skill == SKILL_MAGLEVEL then
		return tries * configManager.getNumber(configKeys.RATE_MAGIC)
	end
	return tries * configManager.getNumber(configKeys.RATE_SKILL)
end

local function returnRank(id)
	local rank = ''
	if id == 3 then
		rank = 'a God'
	else
		rank = 'a GameMaster'
	end
	return rank
end

function Player:getDescription(lookDistance)
	local str = {}
	if lookDistance == -1 then
		table.insert(str, " yourself.")
		if self:getGroup():getAccess() then
			table.insert(str, " You are " .. returnRank(self:getGroup():getId()) .. '.')
		elseif self:getVocation():getId() ~= VOCATION_NONE then
			table.insert(str, " You are " .. self:getVocation():getDescription() .. '.')
		else 
			table.insert(str, " You have no vocation.")
		end
	else
		table.insert(str, self:getName())
		if not self:getGroup():getAccess() then
			table.insert(str, " (Level " .. self:getLevel() .. ')')
		end
		table.insert(str, '.')

		if self:getSex() == PLAYERSEX_FEMALE then
			table.insert(str, " She")
		else
			table.insert(str, " He")
		end

		if self:getGroup():getAccess() then
			table.insert(str, " is " .. returnRank(self:getGroup():getId()) .. '.')
		elseif self:getVocation():getId() ~= VOCATION_NONE then
			table.insert(str, " is " .. self:getVocation():getDescription() .. '.')
		else 
			table.insert(str, " has no vocation.")
		end
	end

	if self:getParty() then
		if lookDistance == -1 then
			table.insert(str, " Your party has ")
		elseif self:getSex() == PLAYERSEX_FEMALE then
			table.insert(str, " She is in a party with ")
		else
			table.insert(str, " He is in a party with ")
		end

		if #self:getParty():getMembers() == 0 then
			table.insert(str, "1 member and ")
		else
			table.insert(str, (#self:getParty():getMembers() + 1) .. " members and ")
		end

		if #self:getParty():getInvitees() == 1 then
			table.insert(str, "1 pending invitation.")
		else
			table.insert(str, #self:getParty():getInvitees() .. " pending invitations.")
		end
	end
	
	local guild = self:getGuild()
	if (guild) then
		local rank = guild:getRankByLevel(self:getGuildLevel());
		if rank then
			if lookDistance == -1 then
				table.insert(str, " You are ")
			elseif self:getSex() == PLAYERSEX_FEMALE then
				table.insert(str, " She is ")
			else
				table.insert(str, " He is ")
			end

			table.insert(str, rank.name .. " of the " .. self:getGuild():getName())
			if self:getGuildNick() then
				table.insert(str, " (" .. self:getGuildNick() .. ")")
			end

			local memberCount = #guild:getMembersOnline()
			if memberCount == 1 then
				table.insert(str, ", which has 1 member, " .. guild:getMembersOnline() .. " of them online.")
			else
				table.insert(str, ", which has " .. memberCount .. " members, " .. guild:getMembersOnline() .. " of them online.")
			end
		end
	end
	return table.concat(str)
end

