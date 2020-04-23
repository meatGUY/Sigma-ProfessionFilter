function GetTradeSkillName()
	local skillName = GetTradeSkillLine();
	if skillName == "Mining" then skillName = "Smelting" end;
	
	return skillName;
end

function SPF2:SavedData()
	if not Sigma_ProfessionFilter then
		Sigma_ProfessionFilter = {};
	end
	if not Sigma_ProfessionFilter[GetTradeSkillName()] then
		Sigma_ProfessionFilter[GetTradeSkillName()] = {};
	end
	return Sigma_ProfessionFilter[GetTradeSkillName()];
end

function SPF2:GetTitle(side)
	if SPF2[GetTradeSkillName()] and SPF2[GetTradeSkillName()][side.."Title"] then
		return SPF2[GetTradeSkillName()][side.."Title"];
	end
	if SPF2["Default"] then
		return SPF2["Default"][side.."Title"] or "";
	end
end

function SPF2:GetMenu(side)
	if SPF2[GetTradeSkillName()] and SPF2[GetTradeSkillName()][side] then
		return SPF2[GetTradeSkillName()][side];
	end
	if SPF2["Default"] then
		return SPF2["Default"][side];
	end
end

function SPF2:GetSelected(side)
	if not SPF2[GetTradeSkillName()] then
		SPF2[GetTradeSkillName()] = {};
	end
	if SPF2:GetMenu(side) and SPF2[GetTradeSkillName()]["Selected"] then
		return SPF2[GetTradeSkillName()]["Selected"][side] or 0;
	end
	return 0;
end

function SPF2:SetSelected(side, id)
	if not SPF2[GetTradeSkillName()] then
		SPF2[GetTradeSkillName()] = {};
	end
	if SPF2:GetMenu(side) then
		if not SPF2[GetTradeSkillName()]["Selected"] then
			SPF2[GetTradeSkillName()]["Selected"] = {};
		end
		SPF2[GetTradeSkillName()]["Selected"][side] = id;
	end
end

function SPF2:Custom(target)
	if SPF2[GetTradeSkillName()] then
		if SPF2[GetTradeSkillName()][target] then
			return SPF2[GetTradeSkillName()][target];
		end
	end
	if SPF2["Default"] then
		return SPF2["Default"][target] or {};
	end
	return {};
end

function SPF2.trim(str)
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end

-- Return the group index if the skill matches the filter
-- Return 0 when to disable the filter
-- Otherwise return nil
function SPF2:GetGroup(side, skillIndex, groupIndex)
	if (SPF2:GetMenu(side)) then
		local targetValue = SPF2.baseGetTradeSkillInfo(skillIndex);
		for i = 1, #SPF2:GetMenu(side), 1 do
			if groupIndex > 0 then
				i = groupIndex;
			end
			
			local button = SPF2:GetMenu(side)[i];
			
			if string.find(button.filter, ";") then
				for f in string.gmatch(button.filter, "[^%;]+") do
					if string.find(targetValue, f) then
						return i;
					end
				end
			else
				if (string.find(targetValue, button.filter)) then
					return i;
				end
			end
			
			if groupIndex > 0 then
				return nil;
			end
		end
	elseif SPF2:Custom(side.."Menu")["disabled"] then
		return 0;
	end
	return nil;
end

function SPF2:FilterWithSearchBox(skillIndex)
	
	if SPF2.SearchBox ~= nil then
		local searchFilter = SPF2.trim(SPF2.SearchBox:GetText():lower());
		local skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = SPF2.baseGetTradeSkillInfo(skillIndex);
		
		-- Check the Name
		if (SPF2:SavedData()["SearchNames"] ~= false) then
			if strmatch(skillName:lower(), searchFilter) ~= nil then
				return true;
			end
		end
		
		-- Check the Headers
		if (SPF2:SavedData()["SearchHeaders"] ~= false) then
			
			-- Check the LeftMenu
			if not SPF2:Custom("LeftMenu")["disabled"] then
				if SPF2:GetMenu("Left") then
					for	i,button in ipairs(SPF2:GetMenu("Left")) do
						local groupIndex = SPF2.LeftMenu:Filter(skillIndex, i);
						if groupIndex > 0 then
							if strmatch(button.name:lower(), searchFilter) ~= nil then
								return true;
							end
						end
					end
				else
					if SPF2.OriginalHeaders then
						if strmatch(SPF2.OriginalHeaders[skillIndex]:lower(), searchFilter) ~= nil then
							return true;
						end
					end
				end
			end
			
			-- Check the RightMenu
			if not SPF2:Custom("RightMenu")["disabled"] then
				if SPF2:GetMenu("Right") then
					for	i,button in ipairs(SPF2:GetMenu("Right")) do
						local groupIndex = SPF2.RightMenu:Filter(skillIndex, i);
						if groupIndex > 0 then
							if strmatch(button.name:lower(), searchFilter) ~= nil then
								return true;
							end
						end
					end
				else
					local groupIndex = SPF2.RightMenu:Filter(skillIndex, 0);
					local groupName = select(groupIndex, GetTradeSkillInvSlots());						
					if strmatch(groupName:lower(), searchFilter) ~= nil then
						return true;
					end
				end
			end
		end
		
		-- Check the Reagents
		if (SPF2:SavedData()["SearchReagents"] ~= false) then
			for i = 1, SPF2.baseGetTradeSkillNumReagents(skillIndex), 1 do
				local reagentName, reagentTexture, reagentCount, playerReagentCount = SPF2.baseGetTradeSkillReagentInfo(skillIndex, i);
				
				if (reagentName and strmatch(reagentName:lower(), searchFilter)) then
					return true
				end
			end
		end
	end
	
	return false;
end

function SPF2.TradeSkillFrame_PostUpdate()
	
	-- Update the TradeSkillInputBox
	SPF2.GetTradeskillRepeatCount();
	
	-- Check if there are any headers
	if SPF2.Headers then
		-- If has headers show the expand all button
		if #SPF2.Headers > 0 then
			-- If has headers then move all the names to the right
			for i=1, TRADE_SKILLS_DISPLAYED, 1 do
				getglobal("TradeSkillSkill"..i.."Text"):SetPoint("TOPLEFT", "TradeSkillSkill"..i, "TOPLEFT", 21, 0);
			end
			TradeSkillExpandButtonFrame:Show();
		else
			-- If no headers then move all the names to the left
			for i=1, TRADE_SKILLS_DISPLAYED, 1 do
				getglobal("TradeSkillSkill"..i.."Text"):SetPoint("TOPLEFT", "TradeSkillSkill"..i, "TOPLEFT", 3, 0);
			end
			TradeSkillExpandButtonFrame:Hide();
		end
	end
	
	if not SPF2.FIRST then
		SPF2.ClearTradeSkill();
	end
	
	--LeatrixPlus compatibility
    if (LeaPlusDB and LeaPlusDB["EnhanceProfessions"] == "On" and TradeSkillSkill23) then
		if SPF2.Headers and #SPF2.Headers == 0 and SPF2.FIRST then
			TradeSkillSkill1:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 22, -81);
			if SPF2.Data and #SPF2.Data > 22  then
				TradeSkillSkill23:Show();
			end
		else
			TradeSkillSkill23:Hide();
			TradeSkillSkill1:SetPoint("TOPLEFT", TradeSkillFrame, "TOPLEFT", 22, -96);
		end
    end
end

hooksecurefunc("TradeSkillFrame_Update", SPF2.TradeSkillFrame_PostUpdate);

function SPF2.ClearTradeSkill()
	TradeSkillSkillName:Hide();
	TradeSkillSkillIcon:Hide();
	TradeSkillRequirementLabel:Hide();
	TradeSkillRequirementText:SetText("");
	for i=1, MAX_TRADE_SKILL_REAGENTS, 1 do
		getglobal("TradeSkillReagent"..i):Hide();
	end
	TradeSkillDetailScrollFrameScrollBar:Hide();
	TradeSkillDetailScrollFrameTop:Hide();
	TradeSkillDetailScrollFrameBottom:Hide();
	TradeSkillHighlightFrame:Hide();
	TradeSkillCreateButton:Disable();
	TradeSkillCreateAllButton:Disable();
end

function SPF2.FullUpdate()
	SPF2.GetNumTradeSkills();
	TradeSkillListScrollFrameScrollBar:SetValue(0);
	if SPF2.FIRST then
		FauxScrollFrame_SetOffset(TradeSkillListScrollFrame, 0);
		SPF2.TradeSkillFrame_SetSelection(SPF2.FIRST);
	end
	TradeSkillFrame_Update();
end
