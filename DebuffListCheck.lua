DLC = {}
DLC.DebuffList = {
	["Curse of Recklessness"] = "WARLOCK",
	["Curse of Elements"] = "WARLOCK",
	["Curse of Shadows"] = "WARLOCK",
	["Demoralizing Shout"] = "WARRIOR",
	["Gift of Arthas"] = "WARRIOR",
	["Nightfall"] = "WARRIOR",
	["Crystal Yield"] = "WARRIOR",
	["Thunder Clap"] = "WARRIOR",
	["Sunder Armor"] = "WARRIOR",
	["Fairy Fire"] = "DRUID",
}
DLC.DebuffListIcons = {
	["Curse of Recklessness"] = "spell_shadow_unholystrength",
	["Curse of Elements"] = "spell_shadow_chilltouch",
	["Curse of Shadows"] = "spell_shadow_curseofachimonde",
	["Demoralizing Shout"] = "ability_warrior_warcry",
	["Gift of Arthas"] = "spell_shadow_fingerofdeath",
	["Nightfall"] = "spell_holy_elunesgrace",
	["Crystal Yield"] = "inv_misc_gem_amethyst_01",
	["Thunder Clap"] = "spell_nature_thunderclap",
	["Sunder Armor"] = "ability_warrior_sunder",
	["Fairy Fire"] = "spell_nature_faeriefire",
}
DLC.ClassColor = {
	["WARRIOR"] = {0.78,0.61,0.43},
	["WARLOCK"] = {0.58,0.51,0.79},
	["DRUID"] = {1,0.49,0.04},
}
DLC.Target = "Target"
DLC.Host = "Host"
DLC.CurList = {}
DLC.t1 = 0
DLC.t2 = 0
DLC.t1u = 0.3
DLC.t2u = 1.2
DLC.castcheck = false

local t = {}
local tinsert = table.insert
local tremove = table.remove
local _G = getglobal
local strgsub = string.gsub
local func = function(c) tinsert(t,c) end
local player = UnitName("player")
local _,class = UnitClass("player")

function DLC:OnLoad()
	SLASH_DLC1 = "/dlc"
	SlashCmdList["DLC"] = function(msg) 
		cmd = strlower(msg)
		if cmd == "toggle" then
			if DLCToggle then
				DLCToggle = false
				DLC:SendMessage("You can only see the debuffs regarding your class now.")
			else
				DLCToggle = true
				DLC:SendMessage("You can see all missing debuffs now.")
			end
			DLC:UpdateList()
		elseif cmd == "show" then
			DLC_Frame:Show()
			self:SendMessage("The frame is now shown.")
		elseif cmd == "hide" then
			DLC_Frame:Hide()
			self:SendMessage("The frame is now hidden.")
		else
			self:SendMessage("does provide the following commands:")
			self:SendMessage(" - toggle - only see your or all debuffs")
			self:SendMessage(" - show - Show the frame")
			self:SendMessage(" - hide - Hide the frame")
		end
	end
end

function DLC:OnEvent(event)
	if event == "PLAYER_TARGET_CHANGED" then
		if self.Host == player then
			self.Host = "Host"
			self.Target = "Target"
			SendAddonMessage("DebuffListCheck_Reset", "NaN,", "RAID")
			self:Reset()
		end
	elseif event == "CHAT_MSG_ADDON" then
		self:GetAddonMessage(arg1, arg2, arg4)
	end
end

function DLC:ShowTooltip()
	GameTooltip:SetOwner(DLC_Frame, "TOPLEFT")
	GameTooltip:AddLine("Hold Mouse to move it.")
	GameTooltip:Show()
end

function DLC:SendAddonMessage()
	local msg = ""
	for cat, val in self.CurList do
		msg = msg..val..","
	end
	SendAddonMessage("DebuffListCheck_List", msg, "RAID")
end

function DLC:GetAddonMessage(prefix, msg, host)
	if host==player then return end
	t = {}
	strgsub(msg, "(.-),", func)
	if prefix == "DebuffListCheck_List" then
		if host == self.Host then
			self.CurList = {}
			for cat, val in t do
				tinsert(self.CurList, val)
			end
			self:UpdateList()
		end
	elseif prefix == "DebuffListCheck_Host" then
		self.Host = t[1]
		self.Target = t[2]
	elseif prefix == "DebuffListCheck_Reset" then
		self.Host = "Host"
		self.Target = "Target"
		self:Reset()
	elseif prefix == "DebuffListCheck_Cast" then
		if self.Host == player then
			self.t1 = 0
			self.castcheck = true
		end
	end
	_G("DLC_Frame_Name"):SetText(self.Target)
	_G("DLC_Frame_SubName"):SetText(self.Host.."'s Target")
end

function DLC:ScanTarget()
	if self.Target == UnitName("target") and UnitCanAttack("player", "target") and self.Host == player then
		self.CurList = {}
		for i=1, 16 do
			DLCTT:ClearLines()
			DLCTT:SetUnitDebuff("target", i)
			local name = DLCTTTextLeft1:GetText()
			if name then
				if self:TContains(self.DebuffList, name) then
					tinsert(self.CurList, name)
				end
			else
				break
			end
		end
		self:SendAddonMessage()
		self:UpdateList()
	end
end

function DLC:TContains(arr, obj)
	for cat,val in arr do
		if cat==obj or val==obj then
			return true
		end
	end
	return false
end

function DLC:SetTarget()
	if IsRaidLeader() or IsRaidOfficer() then
		if UnitName("target") and UnitCanAttack("player", "target") and not UnitIsDead("target") then
			self.Target = UnitName("target")
			self.Host = player
			SendAddonMessage("DebuffListCheck_Host", self.Host..","..self.Target..",", "RAID")
			self:ScanTarget()
		end
	else
		self:SendMessage("You must be the raidleader or an assistant in order to do this.")
	end
end

function DLC:SendMessage(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080DebuffListCheck|r: "..msg)
end

function DLC:FilterClass(bool, req)
	if not bool then
		return true
	else
		if class==req then
			return true
		end
	end
	return false
end

function DLC:Reset()
	for i=1, 10 do
		_G("DLC_Frame_Button"..i):Hide()
	end
	_G("DLC_Frame"):SetHeight(50)
	_G("DLC_Frame_Name"):SetText("Target")
	_G("DLC_Frame_SubName"):SetText("Host's Target")
end

function DLC:Sort(obj)
	local t = {}
	for cat, val in obj do
		if val == "WARRIOR" then
			tinsert(t, 1, {cat, val})
		elseif val == "WARLOCK" then
			tinsert(t, 15, {cat, val})
		else
			tinsert(t, 60, {cat, val})
		end
	end
	return t
end

function DLC:UpdateList()
	local temp, p, con = {
		["Curse of Recklessness"] = "WARLOCK",
		["Curse of Elements"] = "WARLOCK",
		["Curse of Shadows"] = "WARLOCK",
		["Demoralizing Shout"] = "WARRIOR",
		["Gift of Arthas"] = "WARRIOR",
		["Nightfall"] = "WARRIOR",
		["Crystal Yield"] = "WARRIOR",
		["Thunder Clap"] = "WARRIOR",
		["Sunder Armor"] = "WARRIOR",
		["Fairy Fire"] = "DRUID",
	}, 1, true
	for cat, val in self.CurList do
		for ca, _ in temp do
			if ca==val then
				temp[ca] = nil
			end
		end
	end
	if DLCToggle then con=false end
	self:Reset()
	for cat, val in self:Sort(temp) do
		if DLC:FilterClass(con, val) then
			_G("DLC_Frame_Button"..p.."_Name"):SetText(val[1])
			_G("DLC_Frame_Button"..p.."_Name"):SetTextColor(self.ClassColor[val[2]][1],self.ClassColor[val[2]][2],self.ClassColor[val[2]][3])
			_G("DLC_Frame_Button"..p.."_Icon"):SetTexture("Interface\\Icons\\"..self.DebuffListIcons[val[1]])
			_G("DLC_Frame_Button"..p).name = val[1]
			_G("DLC_Frame_Button"..p):Show()
			p = p + 1
		end
	end
	_G("DLC_Frame"):SetHeight(20+p*30)
	_G("DLC_Frame_Name"):SetText(self.Target)
	_G("DLC_Frame_SubName"):SetText(self.Host.."'s Target")
end

function DLC:GetHostUnit()
	local num = GetNumRaidMembers()
	local type = "raid"
	if num<=0 then
		num = GetNumPartyMembers()
		type = "party"
	end
	for i=1, num do
		if UnitName(type..i)==self.Host then
			return type..i
		end
	end
end

function DLC:CastSpell(obj)
	local spell = obj.name
	local targetunit = self:GetHostUnit().."target"
	if spell == "Nightfall" then
		local bool
		for i=0, 4 do
			for p=1, 18 do
				local texture = GetContainerItemInfo(i, p)
				if texture == "Interface\\Icons\\inv_axe_12" then
					UseContainerItem(i,p)
					bool = true
				end
			end
		end
		if bool then
			self:SendMessage("Nightfall has been equiped!")
		else
			self:SendMessage("You do not have Nightfall in your inventory.")
		end
	elseif spell == "Gift of Arthas" or spell == "Crystal Yield" then
		local bool
		for i=0, 4 do
			for p=1, 18 do
				local texture = GetContainerItemInfo(i, p)
				if texture == "Interface\\Icons\\inv_potion_28"
					UseContainerItem(i,p)
					SpellTargetUnit("player")
					bool = true
				elseif texture == "Interface\\Icons\\inv_misc_gem_amethyst_01" then
					UseContainerItem(i,p)
					SpellTargetUnit(targetunit)
					bool = true
				end
			end
		end
		if not bool then
			self:SendMessage("You do not have any Crystal Yield or Gift of Arthas in your inventory.")
		end
	else
		CastSpellByName(spell)
		SpellTargetUnit(targetunit)
	end
	SendAddonMessage("DebuffListCheck_Cast", spell, "RAID")
end

function DLC:TargetHost()
	local unit = DLC:GetHostUnit()
	if unit then
		TargetUnit(unit.."target")
	else
		self:SendMessage("Couldnt find the host.")
	end
end

function DLC:OnUpdate(elapsed)
	if self.Host == player then
		if self.castcheck then
			self.t1 = self.t1 + elapsed
			if self.t1 >= self.t1u then
				self:ScanTarget()
				self.t1 = 0
				self.castcheck = false
			end
		end
		self.t2 = self.t2 + elapsed
		if self.t2 >= self.t2u then
			self:ScanTarget()
			self.t2 = 0
		end
	end
end