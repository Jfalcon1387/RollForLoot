local frmRFLRollTracker = nil;
RFLLootRollIdxByIndex = nil;
RFLLootRollIdxByValue = nil;
RFLLootRolls = nil;
DisplayedRTID = 1;
DisplayedLootQty = 1;

-- Loot Roll Sort Functions
local SpecOrder = {};
SpecOrder["Main"] = 1;
SpecOrder["Off"] = 2;
SpecOrder["NA"] = 3;

local TypeOrder = {};
TypeOrder["2pc / 4pc"] = 1;
TypeOrder["BiS"] = 2;
TypeOrder["Major"] = 3;
TypeOrder["Minor"] = 4;
TypeOrder["Greed"] = 5;
TypeOrder["Pass"] = 6;

function RollForLoot:BuildRollTrackerFrame()
	if(frmRFLRollTracker == nil) then
		frmRFLRollTracker = CreateFrame("Frame", "frmRFLRollTracker", UIParent, "BasicFrameTemplate");

		-- Build Roll Tracker Frame
		frmRFLRollTracker:SetWidth(390);
		frmRFLRollTracker:SetHeight(300);
		frmRFLRollTracker:SetFrameStrata("DIALOG");
		frmRFLRollTracker:SetPoint("CENTER",0,0)
		frmRFLRollTracker:SetMovable(true)
		frmRFLRollTracker:EnableMouse(true)
		frmRFLRollTracker:RegisterForDrag("LeftButton")
		frmRFLRollTracker:SetScript("OnDragStart", frmRFLRollTracker.StartMoving)
		frmRFLRollTracker:SetScript("OnDragStop", frmRFLRollTracker.StopMovingOrSizing)
		frmRFLRollTracker:SetScript("OnUpdate", function(self, elapsed) RollForLoot:RefreshRollTracker(self,elapsed) end)

		-- Build Roll Tracker Title
		local frmRFLRTTitleText = frmRFLRollTracker:CreateFontString("$parentTitle", "Overlay", "GameFontNormal")
		frmRFLRTTitleText:SetText("Roll For Loot: Roll Tracker")
		frmRFLRTTitleText:SetPoint("TOP", frmRFLRollTracker, 0, -6)

		-- Build Loot Icon
		local frmRFLRTLootIcon = CreateFrame("Button", "frmRFLLootIcon", frmRFLRollTracker, "ItemButtonTemplate")
		frmRFLRTLootIcon:SetPoint("TOPLEFT", 10, -30)
		frmRFLRTLootIcon:RegisterForClicks("RightButtonDown")
		frmRFLRTLootIcon:SetScript("OnClick", function(self) if IsControlKeyDown() then RollForLoot:TransmogDisplayItemLink(self) end end)
		textureRFLLootIconName = frmRFLRTLootIcon:CreateTexture("textureRFLLootIconName", "ARTWORK" , nil, nil )
		textureRFLLootIconName:SetTexture("Interface\\QUESTFRAME\\UI-QuestItemNameFrame") 
		textureRFLLootIconName:SetSize(130, 62)
		textureRFLLootIconName:SetPoint("LEFT", 30, 0)
		fsRFLLootIconName = frmRFLRTLootIcon:CreateFontString("fsRFLLootIconName", "ARTWORK" , "GameFontNormal")
		fsRFLLootIconName:SetPoint("LEFT", frmRFLRTLootIcon, "RIGHT", 8, 0)
		fsRFLLootIconName:SetSize(93, 38)
		fsRFLLootIconName:SetJustifyH("LEFT")

		-- Build Loot Roll Next Button
		local RFLLootRoll_btnNext = CreateFrame("Button", "RFLLootRoll_btnNext", frmRFLRollTracker, "UIPanelButtonTemplate");
		RFLLootRoll_btnNext:SetPoint("TOPRIGHT", frmRFLRollTracker, -50, -30);
		RFLLootRoll_btnNext:SetWidth(75);
		RFLLootRoll_btnNext:SetText("Next");
		RFLLootRoll_btnNext:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootRoll_btnNext:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootRoll_btnNext:SetScript("OnClick", function(self) RollForLoot:MoveToLootRoll("Next") end)
		
		-- Build Loot Roll Previous Button
		local RFLLootRoll_btnPrev = CreateFrame("Button", "RFLLootRoll_btnPrev", frmRFLRollTracker, "UIPanelButtonTemplate");
		RFLLootRoll_btnPrev:SetPoint("RIGHT", RFLLootRoll_btnNext, -75, 0);
		RFLLootRoll_btnPrev:SetWidth(75);
		RFLLootRoll_btnPrev:SetText("Previous");
		RFLLootRoll_btnPrev:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootRoll_btnPrev:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootRoll_btnPrev:SetScript("OnClick", function(self) RollForLoot:MoveToLootRoll("Previous") end)
		
		-- Build Loot Qty Frames
		local RFLLootRoll_btnQty1 = CreateFrame("Button", "RFLLootRoll_btnQty1", frmRFLRollTracker, "UIPanelButtonTemplate");
		RFLLootRoll_btnQty1:SetPoint("TOPRIGHT", frmRFLRollTracker, -10, -75);
		RFLLootRoll_btnQty1:SetWidth(32);
		RFLLootRoll_btnQty1:SetText("1");
		RFLLootRoll_btnQty1:Disable();
		RFLLootRoll_btnQty1:SetScript("OnClick", function(self) RollForLoot:MoveToLootRoll("Same", 1) end)
		
		local RFLLootRoll_btnQty2 = CreateFrame("Button", "RFLLootRoll_btnQty2", frmRFLRollTracker, "UIPanelButtonTemplate");
		RFLLootRoll_btnQty2:SetPoint("TOPRIGHT", RFLLootRoll_btnQty1, 0, -32);
		RFLLootRoll_btnQty2:SetWidth(32);
		RFLLootRoll_btnQty2:SetText("2");
		RFLLootRoll_btnQty2:Disable();
		RFLLootRoll_btnQty2:Hide();
		RFLLootRoll_btnQty2:SetScript("OnClick", function(self) RollForLoot:MoveToLootRoll("Same", 2) end)
		
		local RFLLootRoll_btnQty3 = CreateFrame("Button", "RFLLootRoll_btnQty3", frmRFLRollTracker, "UIPanelButtonTemplate");
		RFLLootRoll_btnQty3:SetPoint("TOPRIGHT", RFLLootRoll_btnQty2, 0, -32);
		RFLLootRoll_btnQty3:SetWidth(32);
		RFLLootRoll_btnQty3:SetText("3");
		RFLLootRoll_btnQty3:Disable();
		RFLLootRoll_btnQty3:Hide();
		RFLLootRoll_btnQty3:SetScript("OnClick", function(self) RollForLoot:MoveToLootRoll("Same", 3) end)
		
		local RFLLootRoll_btnQty4 = CreateFrame("Button", "RFLLootRoll_btnQty4", frmRFLRollTracker, "UIPanelButtonTemplate");
		RFLLootRoll_btnQty4:SetPoint("TOPRIGHT", RFLLootRoll_btnQty3, 0, -32);
		RFLLootRoll_btnQty4:SetWidth(32);
		RFLLootRoll_btnQty4:SetText("4");
		RFLLootRoll_btnQty4:Disable();
		RFLLootRoll_btnQty4:Hide();
		RFLLootRoll_btnQty4:SetScript("OnClick", function(self) RollForLoot:MoveToLootRoll("Same", 4) end)
		
		-- Build Loot Scroll Frame
		local frmRFLRTScroll = CreateFrame("ScrollFrame", "frmRFLRTScroll", frmRFLRollTracker, "UIPanelScrollFrameTemplate")
		frmRFLRTScroll:SetWidth(frmRFLRollTracker:GetWidth() - 80);
		frmRFLRTScroll:SetHeight(frmRFLRollTracker:GetHeight() - 85);
		frmRFLRTScroll:SetPoint("TOPLEFT", 8, -75);
		
		-- Roll Background Frame
		local frmRFLRollTrackerBackground = CreateFrame("Frame", "frmRFLRollTrackerBackground", nil, nil );
		frmRFLRollTrackerBackground:SetPoint("TOPLEFT", 8, -75);
		frmRFLRollTrackerBackground:SetHeight(frmRFLRTScroll:GetHeight());
		frmRFLRollTrackerBackground:SetWidth(frmRFLRTScroll:GetWidth());
		frmRFLRollTrackerBackground:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = {left = 1, right = 1, top = 1, bottom = 1}}
		);
		
		frmRFLRTScroll:SetScrollChild(frmRFLRollTrackerBackground);
		
		-- Loot Roll Header Font Strings
		fsRFL_RT_PlayerName = frmRFLRollTrackerBackground:CreateFontString("fsRFL_RT_PlayerName", "ARTWORK" , "GameFontNormalSmall")
		fsRFL_RT_PlayerName:SetPoint("TOPLEFT", frmRFLRollTrackerBackground, "TOPLEFT", 10, -5)
		fsRFL_RT_PlayerName:SetSize(125, 15)
		fsRFL_RT_PlayerName:SetJustifyH("LEFT")
		fsRFL_RT_PlayerName:SetText("Player Name")
		
		fsRFL_RT_RollValue = frmRFLRollTrackerBackground:CreateFontString("fsRFL_RT_RollValue", "ARTWORK" , "GameFontNormalSmall")
		fsRFL_RT_RollValue:SetPoint("LEFT", fsRFL_RT_PlayerName, "RIGHT", 0, 0)
		fsRFL_RT_RollValue:SetSize(50, 15)
		fsRFL_RT_RollValue:SetJustifyH("LEFT")
		fsRFL_RT_RollValue:SetText("Roll")
		
		fsRFL_RT_RollSpec = frmRFLRollTrackerBackground:CreateFontString("fsRFL_RT_RollSpec", "ARTWORK" , "GameFontNormalSmall")
		fsRFL_RT_RollSpec:SetPoint("LEFT", fsRFL_RT_RollValue, "RIGHT", 0, 0)
		fsRFL_RT_RollSpec:SetSize(50, 15)
		fsRFL_RT_RollSpec:SetJustifyH("LEFT")
		fsRFL_RT_RollSpec:SetText("Spec")
		
		fsRFL_RT_RollType = frmRFLRollTrackerBackground:CreateFontString("fsRFL_RT_Rol`lType", "ARTWORK" , "GameFontNormalSmall")
		fsRFL_RT_RollType:SetPoint("LEFT", fsRFL_RT_RollSpec, "RIGHT", 0, 0)
		fsRFL_RT_RollType:SetSize(75, 15)
		fsRFL_RT_RollType:SetJustifyH("LEFT")
		fsRFL_RT_RollType:SetText("Type")
		
--		fsRFL_RT_RollItemsRcv = frmRFLRollTrackerBackground:CreateFontString("fsRFL_RT_RollItemsRcv", "ARTWORK" , "GameFontNormalSmall")
--		fsRFL_RT_RollItemsRcv:SetPoint("LEFT", fsRFL_RT_RollType, "RIGHT", 0, 0)
--		fsRFL_RT_RollItemsRcv:SetSize(100, 15)
--		fsRFL_RT_RollItemsRcv:SetJustifyH("LEFT")
--		fsRFL_RT_RollItemsRcv:SetText("Items Received")
	
		-- Build Loot Award Confirmation Dialog
		StaticPopupDialogs["RFL_AWARDLOOT_CONFIRM"] = {
			text = "Are you sure you wish to award this item to %s?",
			-- YES, NO, ACCEPT, CANCEL, etc, are global WoW variables containing localized
			-- strings, and should be used wherever possible.
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept =  function (self, data, data2)
					RollForLoot:AwardLoot(data, data2)
				end,
			OnCancel = function (_,reason)
				end,
			sound = "levelup2",
			timeout = 30,
			whileDead = true,
			hideOnEscape = true,
			showAlert = true,
			}
	end
	
	frmRFLRollTracker:Hide();
end

function RollForLoot:TransmogDisplayItemLink(self)
	local lootID = RFLLootRollIdxByIndex[DisplayedRTID];
	local LootLink = RFL_LootRollHistory[lootID]["Hyperlink"];
	
	DressUpItemLink(LootLink);
end

function RollForLoot:ClearRTHistory()
	RFLLootRollIdxByIndex = nil;
	RFLLootRollIdxByValue = nil;
	RFLLootRolls = nil;
	DisplayedRTID = 0;
end

function RollForLoot:ClearRollToRTFrames()
	if frmRFLRollTrackerBackground == nil then
		return;
	end
	
	local kids = { frmRFLRollTrackerBackground:GetChildren() };
	for _, child in ipairs(kids) do
		if string.find(child:GetName(), "frmRFL_RT_Player") ~= nil  then
			child:Hide()
		end
	end
end

function RollForLoot:AddRollToRTFrame(i, playerName, rollValue, rollSpec, rollType)
		local frmRFL_RT_Player_i = _G["frmRFL_RT_Player" .. i];
		local fsRFL_RT_PlayerName_i;
		local fsRFL_RT_PlayerRoll_i;
		local fsRFL_RT_RollSpec_i;
		local fsRFL_RT_RollType_i;
		local fsRFL_RT_RollItemsRcv_i;
		
		if frmRFL_RT_Player_i == nil then
			frmRFL_RT_Player_i = CreateFrame("Frame", "frmRFL_RT_Player" .. i, frmRFLRollTrackerBackground, nil);
			frmRFL_RT_Player_i:SetPoint("TOPLEFT", 10, -20*(i-1)-20);
			frmRFL_RT_Player_i:SetHeight(20);
			frmRFL_RT_Player_i:SetWidth(frmRFLRTScroll:GetWidth());
			frmRFL_RT_Player_i:EnableMouse(true);
			
			if (RollForLoot:isMasterLooter() or RFLDEBUG)  then -- only allow loot assignment click if you are the master looter
				frmRFL_RT_Player_i:SetScript("OnMouseDown", function(self,button) RollForLoot:AssignLoot(self) end);
			end
			
			fsRFL_RT_PlayerName_i = frmRFL_RT_Player_i:CreateFontString("fsRFL_RT_PlayerName" .. i, "ARTWORK" , "GameFontWhiteSmall")
			fsRFL_RT_PlayerName_i:SetPoint("LEFT", frmRFL_RT_Player_i, "LEFT", 0, 0)
			fsRFL_RT_PlayerName_i:SetSize(125, 15)
			fsRFL_RT_PlayerName_i:SetJustifyH("LEFT")
			
			fsRFL_RT_PlayerRoll_i = frmRFL_RT_Player_i:CreateFontString("fsRFL_RT_PlayerRoll" .. i, "ARTWORK" , "GameFontWhiteSmall")
			fsRFL_RT_PlayerRoll_i:SetPoint("LEFT", fsRFL_RT_PlayerName_i, "RIGHT", 0, 0)
			fsRFL_RT_PlayerRoll_i:SetSize(50, 15)
			fsRFL_RT_PlayerRoll_i:SetJustifyH("LEFT")
			
			fsRFL_RT_RollSpec_i = frmRFL_RT_Player_i:CreateFontString("fsRFL_RT_RollSpec" .. i, "ARTWORK" , "GameFontWhiteSmall")
			fsRFL_RT_RollSpec_i:SetPoint("LEFT", fsRFL_RT_PlayerRoll_i, "RIGHT", 0, 0)
			fsRFL_RT_RollSpec_i:SetSize(50, 15)
			fsRFL_RT_RollSpec_i:SetJustifyH("LEFT")
			fsRFL_RT_RollSpec_i:SetText("Main")
			
			fsRFL_RT_RollType_i = frmRFL_RT_Player_i:CreateFontString("fsRFL_RT_RollType" .. i, "ARTWORK" , "GameFontWhiteSmall")
			fsRFL_RT_RollType_i:SetPoint("LEFT", fsRFL_RT_RollSpec_i, "RIGHT", 0, 0)
			fsRFL_RT_RollType_i:SetSize(75, 15)
			fsRFL_RT_RollType_i:SetJustifyH("LEFT")
			fsRFL_RT_RollType_i:SetText("BIS")
			
--			fsRFL_RT_RollItemsRcv_i = frmRFL_RT_Player_i:CreateFontString("fsRFL_RT_RollItemsRcv" .. i, "ARTWORK" , "GameFontWhiteSmall")
--			fsRFL_RT_RollItemsRcv_i:SetPoint("LEFT", fsRFL_RT_RollType_i, "RIGHT", 0, 0)
--			fsRFL_RT_RollItemsRcv_i:SetSize(100, 15)
--			fsRFL_RT_RollItemsRcv_i:SetJustifyH("LEFT")
--			fsRFL_RT_RollItemsRcv_i:SetText("MS[2] / OS[3]")
		else
			fsRFL_RT_PlayerName_i = _G["fsRFL_RT_PlayerName" .. i];
			fsRFL_RT_PlayerRoll_i = _G["fsRFL_RT_PlayerRoll" .. i];
			fsRFL_RT_RollSpec_i = _G["fsRFL_RT_RollSpec" .. i];
			fsRFL_RT_RollType_i = _G["fsRFL_RT_RollType" .. i];
--			fsRFL_RT_RollItemsRcv_i = _G["fsRFL_RT_RollItemsRcv" .. i];
		end
		
		fsRFL_RT_PlayerName_i:SetText(playerName);
		
		if RollForLoot:getRaidIndex(playerName) ~= 0 then
			local color = RAID_CLASS_COLORS[RFLRaidRoster[RollForLoot:getRaidIndex(playerName)]["fileName"]];
			fsRFL_RT_PlayerName_i:SetTextColor(color.r, color.g, color.b, 1);
		else
			fsRFL_RT_PlayerName_i:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1); -- Set color to gray if the player is not longer in the raid roster.
		end
		
		--Modify Background Height to be relative to the number of rolls if greater than the scroll field height.
		-- i is zero indexed, add one to account for at least one roll which we know will be there becuase it takes more than 1 roll to be greater than the height of the scroll box.
		
		if (frmRFL_RT_Player_i:GetHeight() * (i+1)) > frmRFLRTScroll:GetHeight() then
			frmRFLRollTrackerBackground:SetHeight(frmRFL_RT_Player_i:GetHeight() * (i+1) + 10);  -- Add some extra spacing at the end for appearances
		else
			frmRFLRollTrackerBackground:SetHeight(frmRFLRTScroll:GetHeight());
		end

		fsRFL_RT_PlayerRoll_i:SetText(rollValue);
		fsRFL_RT_RollSpec_i:SetText(rollSpec);
		fsRFL_RT_RollType_i:SetText(rollType);
		frmRFL_RT_Player_i:Show();
end

-- Move to Loot Roll
function RollForLoot:MoveToLootRoll(cmd, lootQty)
	--RollForLoot:Print("MoveToLootRoll: " .. cmd)
	
	if cmd == "Next" then
		return RollForLoot:DisplayLootRoll(DisplayedRTID + 1, 1);
	elseif cmd == "Previous" then
		if DisplayedRTID > 1 then
			return RollForLoot:DisplayLootRoll(DisplayedRTID - 1, 1);
		end
	else
		if lootQty <= 0 then
			lootQty = 1;
		end
		
		return RollForLoot:DisplayLootRoll(DisplayedRTID, lootQty)
	end
end

function RollForLoot:GetLastRollIndex()
	local currentIndex = 0;
	if (not(RFLLootRollIdxByIndex == nil)) then
		currentIndex = table.getn(RFLLootRollIdxByIndex);
	end 
	
	if currentIndex == nil then
		--RollForLoot:Print("currentIndex was nil")
		currentIndex = 0;
	end
	
	return currentIndex;
end

function RollForLoot:CalculateLootRoll(message, sender)
	if RollForLoot:isMasterLooter() then
		message["RollVal"] = random(100);
		message["Player"] = sender;
	end

	return message
end

function RollForLoot:AddLootRoll(LootID, RFLRoll, LootQtyNo)
	--RollForLoot:Print("AddLootRoll ID: " .. LootID);
	
	if frmRFLRollTracker == nil then
		RollForLoot:BuildRollTrackerFrame();
	end
	
	if LootQtyNo == nil then
		LootQtyNo = 1;
	end
	
	if RFLLootRolls == nil then
		RFLLootRolls = {};
	end
	
	if RFLLootRollIdxByIndex == nil or RFLLootRollIdxByValue == nil then
		RFLLootRollIdxByIndex = {};
		RFLLootRollIdxByValue = {};
	end 

	if RFLLootRollIdxByValue[LootID] == nil then
		local LastIdx = RollForLoot:GetLastRollIndex() + 1;
		
		RFLLootRollIdxByIndex[LastIdx] = LootID;
		RFLLootRollIdxByValue[LootID] = LastIdx;
	end
	
	if RFLLootRolls[LootID] == nil then
		RFLLootRolls[LootID] = {};
	end
	if RFLLootRolls[LootID][LootQtyNo] == nil then
		RFLLootRolls[LootID][LootQtyNo] = {};
	end
	
	local noOfRolls = table.getn(RFLLootRolls[LootID][LootQtyNo])
	if (noOfRolls == nil) then
		noOfRolls = 0
	end
	
	RFLLootRolls[LootID][LootQtyNo][noOfRolls+1] = {};
	RFLLootRolls[LootID][LootQtyNo][noOfRolls+1]["RollVal"] = RFLRoll["RollVal"];
	RFLLootRolls[LootID][LootQtyNo][noOfRolls+1]["Player"] = RFLRoll["Player"];
	RFLLootRolls[LootID][LootQtyNo][noOfRolls+1]["RollSpec"] = RFLRoll["RollSpec"];
	RFLLootRolls[LootID][LootQtyNo][noOfRolls+1]["RollType"] = RFLRoll["RollType"];
end

function RollForLoot:DisplayLootRoll(RollNo, LootQtyNo)
	if RFLSettings["DisplayRT"] == true then
		if RFLLootRollIdxByIndex == nil then -- No Rolls yet!
			RollForLoot:Print("No loot has been rolled on yet!");
			return;
		elseif frmRFLRollTracker == nil then
			RollForLoot:BuildRollTrackerFrame();
		end
		
		if LootQtyNo == nil then
			LootQtyNo = 1;
		end
		
		-- Only Update Displayed if the roll set exisits.
		if RFLLootRollIdxByIndex[RollNo] ~= nil then
			DisplayedRTID = RollNo;
		else
			local maxRolls = table.maxn(RFLLootRollIdxByIndex);
			if (RollNo >= maxRolls) then
				DisplayedRTID = maxRolls
			else
				DisplayedRTID = 1;
			end
		end
			
		local lootID = RFLLootRollIdxByIndex[DisplayedRTID];
		local LootItem = RFL_LootRollHistory[lootID]["Item"];
		local LootTexture = RFL_LootRollHistory[lootID]["Texture"];
		local LootQuality = RFL_LootRollHistory[lootID]["Quality"];
			
		if LootQtyNo > RFL_LootRollHistory[lootID]["Qty"] then
			LootQtyNo = RFL_LootRollHistory[lootID]["Qty"];
		end
		
		DisplayedLootQty = LootQtyNo;
		
		-- Set Font Icon
		_G["frmRFLLootIcon"].icon:SetTexture(RFL_LootRollHistory[lootID]["Texture"]);
		
		-- Set font color of the item name to match the quality
		local redComponent, greenComponent, blueComponent = GetItemQualityColor(RFL_LootRollHistory[lootID]["Quality"])
		_G["fsRFLLootIconName"]:SetText(RFL_LootRollHistory[lootID]["Item"]);
		_G["fsRFLLootIconName"]:SetTextColor(redComponent, greenComponent, blueComponent, 1)
		
		_G["frmRFLLootIcon"]:SetScript("OnEnter", function(self) RollForLoot:RTHyperlinkToolTip(self) end)
		_G["frmRFLLootIcon"]:SetScript("OnLeave", function() GameTooltip:Hide() end)
		
		-- Update Duplicate Item Buttons
		if RFL_LootRollHistory[lootID]["Qty"] > 1 then
			for l=1, RFL_LootRollHistory[lootID]["Qty"] do
				local button = _G["RFLLootRoll_btnQty" .. l];
				button:Show();
				button:Enable();
			end
		else
			_G["RFLLootRoll_btnQty1"]:Disable();
			for k=2,4 do
				local button = _G["RFLLootRoll_btnQty" .. k];
				button:Hide();
				button:Disable();
			end
		end
		
		-- Hide Previous Roll Frames
		RollForLoot:ClearRollToRTFrames();
		
		-- Sort Table
		
		if RFLSettings["SortRollType"] == "SpecType" then
			table.sort(RFLLootRolls[lootID][LootQtyNo], SortBySpecType); -- sort by spec, type and roll
		else
			table.sort(RFLLootRolls[lootID][LootQtyNo], RFLSortBySpec); -- sort by spec and roll'
			-- RFLLootRolls[LootID][LootQtyNo][noOfRolls+1]["Player"]
		end

		-- Display All Received Rolls
		for i, roll in ipairs (RFLLootRolls[lootID][LootQtyNo]) do
			RollForLoot:AddRollToRTFrame(i, roll["Player"], roll["RollVal"], roll["RollSpec"], roll["RollType"])
		end
		
		frmRFLRollTracker:Show()
	else
		--RollForLoot:Print("Don't Display Loot Rolls: " .. DisplayedRTID);
		frmRFLRollTracker:Hide()
	end
	return true;
end

local RollTrackerRefreshTime = 0;

function RollForLoot:RefreshRollTracker(self,elapsed)
    RollTrackerRefreshTime = RollTrackerRefreshTime + elapsed;
    if RollTrackerRefreshTime >= 2 then
        if frmRFLRollTracker:IsShown() then
			RollForLoot:DisplayLootRoll(DisplayedRTID, DisplayedLootQty)
		end
		RollTrackerRefreshTime = 0
    end
end

function RollForLoot:RTHyperlinkToolTip(self)
	local lootID = RFLLootRollIdxByIndex[DisplayedRTID];
	local LootLink = RFL_LootRollHistory[lootID]["Hyperlink"];
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink(LootLink);
end

function RollForLoot:AssignLoot(self)

	if RollForLoot:isMasterLooter() then
	
		local idStart, idStop = string.find(self:GetName(), "%d+")
		
		local playerName = _G["fsRFL_RT_PlayerName" .. string.sub(self:GetName(),idStart, idStop)]:GetText();
		local rollSpec = _G["fsRFL_RT_RollSpec" .. string.sub(self:GetName(),idStart, idStop)]:GetText();
		local raidIndex = RollForLoot:getRaidIndex(playerName);
		
		-- Loot slots can move, detect loot slots
		local lootSlot = 0;
		for i=1, GetNumLootItems() do
			local lootlink = GetLootSlotLink(i);
			
			if lootlink == RFL_LootRollHistory[RFLLootRollIdxByIndex[DisplayedRTID]]["Hyperlink"] then
				lootSlot = i;
				break;
			end
		end	
			
		--RollForLoot:Print("Assign Loot: " .. playerName);
		--RollForLoot:Print("Raid Index: " .. raidIndex);
		--RollForLoot:Print("LootSlot: " .. lootSlot);
		
		candidate = GetMasterLootCandidate(lootSlot, raidIndex);
		--RollForLoot:Print("Loot Candidate: " .. tostring(candidate));
		
		if (candidate == playerName) then

		-- Build Loot Assignment Message
		local RFL_AssignLoot = {};
		RFL_AssignLoot["Player"] = candidate;
		RFL_AssignLoot["RaidIndex"] = raidIndex;
		RFL_AssignLoot["LootID"] = RFLLootRollIdxByIndex[DisplayedRTID];
		RFL_AssignLoot["RollSpec"] = rollSpec;

		local dialog = StaticPopup_Show("RFL_AWARDLOOT_CONFIRM", playerName)
			if (dialog) then
				dialog.data  = lootSlot;
				dialog.data2 = RFL_AssignLoot;
			end
		else -- search raid for the player
			local playerfound = false;
			for i = 1, GetNumGroupMembers() do
				local candidate = GetMasterLootCandidate(lootSlot,i);
				--RollForLoot:Print("LootCandidateSearch: " .. tostring(candidate) .. "i: " .. i);
				if candidate == playerName then
					
					local RFL_AssignLoot = {};
					RFL_AssignLoot["Player"] = candidate;
					RFL_AssignLoot["RaidIndex"] = i;
					RFL_AssignLoot["LootID"] = RFLLootRollIdxByIndex[DisplayedRTID];
					RFL_AssignLoot["RollSpec"] = rollSpec;
				
					local dialog = StaticPopup_Show("RFL_AWARDLOOT_CONFIRM", playerName)
						if (dialog) then
							dialog.data  = lootSlot;
							dialog.data2 = RFL_AssignLoot;
						end
					playerfound = true;
					break;
				end
			end
			
			if not(playerfound) then
				RollForLoot:Print(playerName .. " is not eligible for loot");
			end
		end
	end
end

function RollForLoot:AwardLoot(lootSlot, RFL_AssignLoot)
	
	GiveMasterLoot(lootSlot, RFL_AssignLoot["RaidIndex"]);
	RollForLoot:UpdateLootAwards(RFL_AssignLoot["LootID"], RFL_AssignLoot["Player"], RFL_AssignLoot["RollSpec"]);
	
	if not( RollForLoot:MoveToLootRoll("Next")) then
		frmRFLRollTracker:Hide();
	end
	--RollForLoot:SubmitLootAwardMessage(RFLLootRollIdxByIndex[DisplayedRTID], playerName, rollSpec)
end

function RollForLoot:UpdateLootAwards(lootID, playerName, rollSpec)
	if RFL_AwardedLoot[playerName] == nil then
		RFL_AwardedLoot[playerName] = {};
		RFL_AwardedLoot[playerName].LootCount = 0;
	end
	
	RFL_AwardedLoot[playerName].LootCount = RFL_AwardedLoot[playerName].LootCount + 1;
	
	if  RFL_AwardedLoot[playerName][RFL_AwardedLoot[playerName].LootCount] == nil then
		RFL_AwardedLoot[playerName][RFL_AwardedLoot[playerName].LootCount] = {};
	end

	RFL_AwardedLoot[playerName][RFL_AwardedLoot[playerName].LootCount]["LootID"] = lootID;
	RFL_AwardedLoot[playerName][RFL_AwardedLoot[playerName].LootCount]["RollSpec"] = rollSpec;
end

function RFLSortBySpec(lhs, rhs)
	if lhs ~= nil and rhs ~= nil then
		if lhs["RollSpec"] ~= rhs["RollSpec"] then
			if SpecOrder[lhs["RollSpec"]] < SpecOrder[rhs["RollSpec"]] then
				return true;
			else
				return false;
			end
		elseif lhs["RollVal"] > rhs["RollVal"] then
			return true;
		elseif lhs["RollVal"] == rhs["RollVal"] then
			if lhs["Player"] < rhs["Player"] then
				return true;
			else
				return false;
			end
		end
	else
		return false;
	end
end

function RollForLoot:SortBySpecType(lhs, rhs)
	if lhs ~= nil and rhs ~= nil then
		if lhs["RollSpec"] ~= rhs["RollSpec"] then
			if SpecOrder[lhs["RollSpec"]] <= SpecOrder[rhs["RollSpec"]] then
				return true;
			else
				return false;
			end
		elseif lhs["RollType"] ~= rhs["RollType"] then
			if TypeOrder[lhs["RollType"]] <= TypeOrder[rhs["RollType"]] then
				return true;
			else
				return false;
			end
		elseif  lhs["RollVal"] > rhs["RollVal"] then
			return true;
		elseif lhs["RollVal"] == rhs["RollVal"] then
			if lhs["Player"] < rhs["Player"] then
				return true;
			else
				return false;
			end
		end
	else
		return false;
	end
end