RollForLoot = LibStub("AceAddon-3.0"):NewAddon("RollForLoot", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceBucket-3.0", "AceTimer-3.0" );
local L = LibStub("AceLocale-3.0"):GetLocale("RollForLoot", true);
local rlVersion = GetAddOnMetadata('RollForLoot', 'Version');
local rlAddonLoaded = nil;


local RollForLootLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Roll For Loot", {
 type = "launcher",
 text = "Roll For Loot",
 icon = "Interface\\Icons\\inv_misc_dice_01",
 OnClick = function(self, button)
-- Add a click handler here
	RollForLoot:MiniMapBtnClick(self, button, IsControlKeyDown())
 end,
 OnTooltipShow = function(tt)
            tt:AddLine(L["Title"], 0, 1, 0.59);  -- Roll for Loot Title color |c00FF96|r
            tt:AddLine(" ");
            tt:AddLine(L['RFL_MiniMapUsage'])
        end
})

local icon = LibStub("LibDBIcon-1.0")

-- Variables
local bnetFriends = {};
RFLRaidRoster = {};
local lootItemHyperlinks = {};
local LootMsgBody = nil;
local intPlayerRaidIndex;

-- Loot Variables
local TotalRollRequests = 0;
local displayedItems = 0;
local firstRaidUpdate = true;
local AutoSetLootMethodInProgress = false;
local CurrentRollRequest = 0;

-- Frame Variables
local frmRFLMain = nil;
local iLootFrameHeight = 85;

-- Comm Variables
local ACECommPrefix = "RollForLoot"
local libS = LibStub:GetLibrary("AceSerializer-3.0")
local libC = LibStub:GetLibrary("LibCompress")
local libCE = libC:GetAddonEncodeTable()

-- Debug Variable
local RFLDEBUG = false;

-- Interface Options Panel

RollForLoot.panel = CreateFrame( "Frame", "RollForLootIOPanel", UIParent );
RollForLoot.panel.name = L["Title"];
InterfaceOptions_AddCategory(RollForLoot.panel);


function RollForLoot:OnInitialize()
	-- Called when the addon is loaded

	-- Register for Game Events
	self:RegisterBucketEvent("LOOT_READY",.25,"LootOpened");
	self:RegisterEvent("LOOT_CLOSED","LootClosed");
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED","LootMethodChanged");
	self:RegisterBucketEvent("GROUP_ROSTER_UPDATE", 1,"GroupRosterUpdate");

	-- Register for Chat Slash Commands
	self:RegisterChatCommand("RollForLoot", "rlSlashHandler");
	self:RegisterChatCommand("rfl", "rlSlashHandler");
	self:RegisterChatCommand("RFL", "rlSlashHandler");
	
	-- Register Addon Communications
	self:RegisterComm(ACECommPrefix)
	
	self.db = LibStub("AceDB-3.0"):New("RollForLootDB", {
	 profile = {
	 minimap = {
	 hide = false,
	 },
	 },
	 })
	 icon:Register("Roll For Loot", RollForLootLDB, self.db.profile.minimap)
end

function RollForLoot:OnEnable()
	-- Called when the addon is enabled

	-- Print a message to the chat frame
	self:Print(L['Title']);
	self:Print(L['Description']);
	self:Print(L['Loaded'](rlVersion));
	
	if RFL_LootRollHistory == nil then
		RFL_LootRollHistory = {};
	end
	
	if RFL_AwardedLoot == nil then
		RFL_AwardedLoot = {};
	end

	if RFLSettings == nil then
		RFLSettings = {};
		RFLSettings["LootMethod"] = 'master';
		RFLSettings["LootThreshold"] = 4;
		RFLSettings["LootHistoryTimespan"] = 0;
		RFLSettings["DisplayRT"] = true;
		RFLSettings["RollTimer"] = 120; -- How long is a loot roll active in seconds.
		RFLSettings["SortRollType"] = "Spec";
		RFLSettings["AutoClearHistory"] = true;
	end
	
	if RFLRaidRoster == nil then
		RFLRaidRoster = {};
	end
	
	if DisplayedRTID == nil then
		DisplayedRTID = 1;
	end
	
	if IsInRaid() then
		firstRaidUpdate = false;
	end
	
	if RFLSettings["AutoClearHistory"] == nil then   -- New Setting Added Default
		RFLSettings["AutoClearHistory"] = true;
	end 
	
	-- Setup Confirmation Dialog
	
	StaticPopupDialogs["RFL_CLEARLOOTHISTORY_CONFIRM"] = {
		text = L['RFL_LOOTHISTORYCLEAR_CONFIRM'],
		-- YES, NO, ACCEPT, CANCEL, etc, are global WoW variables containing localized
		-- strings, and should be used wherever possible.
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function ()
					RollForLoot:ClearHistory()
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

function RollForLoot:OnDisable()
		-- Called when the addon is disabled
		self:UnregisterAllEvents()
		self:Print(L["Disabled"]);
end

function RollForLoot:rlSlashHandler(input)
	local cmd = string.lower(input);

	if (cmd == "version") then
		RollForLoot:Print(L['Version'](rlVersion));
	elseif (cmd == "refreshroster") then
		RollForLoot:refreshRaidRoster();
	elseif (cmd == "printroster") then
		RollForLoot:printRaidRoster();
	elseif (cmd == "toggleui") then
		RollForLoot:RFL_Toggle();
	elseif (cmd == "hideui") then
		RollForLoot:RFL_Hide();
	elseif (cmd == "showui") then
		RollForLoot:RFL_Show();
	elseif (cmd == "showroll") then
		--RollForLoot:Print("Display Loot Roll");
		RollForLoot:DisplayLootRoll(DisplayedRTID);
	elseif (cmd == "showloot") then
		RollForLoot:DisplayLoot();
	elseif (cmd == "clear") then
		local dialog = StaticPopup_Show("RFL_CLEARLOOTHISTORY_CONFIRM")
	elseif (cmd == "settings") then
		RollForLoot:DisplaySettings();
	elseif (cmd == "debug") then
		if (RFLDEBUG == true) then
			RFLDEBUG = false;
		else
			RFLDEBUG = true;
		end
		RollForLoot:Print("Debug: " .. tostring(RFLDEBUG));
	else 
		for line in string.gmatch(L['Usage'], '([^\n]*)\n') do
            RollForLoot:Print(line);
        end
	end 

end

function RollForLoot:LootClosed(eventname, ...)
	if (RollForLoot:isMasterLooter()) then
		if frmRFLMain ~= nil then
			frmRFLMain:Hide();
		end
		if frmRFLRollTracker ~= nil then
			frmRFLRollTracker:Hide()
			DisplayedRTID = DisplayedRTID - 1;
		end
	end
end

function RollForLoot:LootOpened(eventname, arg1, ...)
	--RollForLoot:Print("LOOT_READY");
	if IsInRaid() or RFLDEBUG  then
		if (RollForLoot:isMasterLooter()) or RFLDEBUG  then
			
			--RollForLoot:Print("Show Main Loot Frame");
			RollForLoot:BuildMainLootFrame();
			
			--clear loot frames
			RollForLoot:ClearLootFrames();

			local numLootItems = GetNumLootItems();
			local numValidLootItems = 0;
			displayedItems = 0;
			--RollForLoot:Print("Number of Loot Items: " .. numLootItems)

			for i=1, numLootItems do
				local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
				
				if (RFLDEBUG and GetLootSlotType(i) == 1) or (quality >= RFLSettings["LootThreshold"] and GetLootSlotType(i) == 1 and locked == false) then
					numValidLootItems = numValidLootItems + 1; 	-- number of valid items may be greater than number of displayed items if a duplicate item is on the boss.
																-- This line intentionally left blank. :D
					local lootlink = GetLootSlotLink(i); 		-- Get the loot hyperlink
					local corpseGUID = GetLootSourceInfo(i); 	-- Get Corpse Info.
					
					-- Calculate Unique Loot ID
					local justID = string.gsub(lootlink,".-\124H([^\124]*)\124h.*", "%1")
					local _, itemID, _, _, _, _, _, _, uniqueId = strsplit(":",justID)
					local _, _, _, _, _, mobID, spawnID = strsplit("-", corpseGUID);
					local lootID = mobID .. ":" .. spawnID .. ":" .. justID;  -- Create an Id which will be unique unless there is a completely identical item on the same mob.
					
					if numValidLootItems == 1 then
						LootMsgBody = {}; -- Reset the on the first valid loot item found.
					end 
					
					if LootMsgBody[lootID] == nil then
						LootMsgBody[lootID] = {};
						LootMsgBody[lootID]["Qty"] = 0
					end
					
					LootMsgBody[lootID]["CorpseGUID"] = corpseGUID; --[Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[Spawn UID]
					LootMsgBody[lootID]["Texture"] = texture;
					LootMsgBody[lootID]["Item"] = item;
					LootMsgBody[lootID]["Hyperlink"] = lootlink;
					LootMsgBody[lootID]["Quality"] = quality;
					LootMsgBody[lootID]["Qty"] = LootMsgBody[lootID]["Qty"] + 1;
					LootMsgBody[lootID]["LootID"] = lootID;
				end
			end

			if numValidLootItems > 0 then
			
				local lootIdx = 0;
				for _, lootMsg in pairs(LootMsgBody) do
					lootIdx = lootIdx + 1;
					local addVal = RollForLoot:AddLootItem(lootIdx,lootMsg)
					displayedItems = displayedItems + addVal;
				end
			
				if displayedItems > 0 then
					RollForLoot:RFL_Show()
				else
					RollForLoot:RFL_Hide()
					RollForLoot:DisplayLootRoll(DisplayedRTID+1);
				end
				RollForLoot:SubmitRollsRequest(LootMsgBody);
				LootMsgBody=nil;
			else
				RollForLoot:RFL_Hide()
			end

		end
	end
end

function RollForLoot:ChatMsgWhisper(eventname, message, sender, ...)
	-- not implmented yet
end

function RollForLoot:ChatMsgWhisperBN(eventname, message, sender, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, counter, arg11, BNpresenceID, arg12)	
	local toonFound = false;

	if (bnetFriends[BNpresenceID] ~= nil) then
		toonFound = true;
	else
		local friendIndexBN = BNGetNumFriends()
		--RollForLoot:Print(friendIndexBN);

		for i=1, friendIndexBN do
			local TNpresenceID, _, _, _, _, _, _, isOnline = BNGetFriendInfo(i);
			--RollForLoot:Print("Toon PresenceID Search: " .. TNpresenceID)
			if (isOnline and (BNpresenceID == TNpresenceID))  then
				for j=1, BNGetNumFriendToons(i) do
					--RollForLoot:Print("Toon Search: " .. j .. " For Friend: " .. i)
					
					local _, toonName, client, realmName = BNGetFriendToonInfo(i,j)
					--RollForLoot:Print("Client: " .. client);

					if (client == L["WoWClientID"]) then
						bnetFriends[BNpresenceID] = toonName .. "-" .. realmName;
						toonFound = true;
					end
				end
				--RollForLoot:Print("Toon Seach Complete");
			end
		end
		--RollForLoot:Print("Seach Complete");
	end

	--RollForLoot:Print(toonFound);

	if (toonFound) then
		--RollForLoot:Print("Message From " .. bnetFriends[BNpresenceID])
		--RollForLoot:Print(message)
	else
		--RollForLoot:Print("Message From NoWoWToon")
		--RollForLoot:Print(message)
	end
end

function RollForLoot:GroupRosterUpdate(eventname)
	--RollForLoot:Print("Event: " .. eventname)
	
	RollForLoot:refreshRaidRoster()
	
	if IsInRaid() then		
		if firstRaidUpdate then
	
			firstRaidUpdate = false;
		
			if UnitIsGroupLeader("player") then
				local currentLootMethod = GetLootMethod();
			
				if currentLootMethod ~= RFLSettings["LootMethod"] then
					AutoSetLootMethodInProgress = true;
					SetLootMethod(RFLSettings["LootMethod"], UnitName("player"), RFLSettings["LootThreshold"]);
					RollForLoot:ScheduleTimer("RFLSetLootThreshold", 1.5)
				end
			end
			
			if not(RFLLootRollIdxByIndex == nil) and RFLSettings["AutoClearHistory"] then
				local dialog = StaticPopup_Show("RFL_CLEARLOOTHISTORY_CONFIRM")
			end
			
			firstRaidUpdate = false;
		end
	else
		counter = 0;
		firstRaidUpdate = true;
	end
	
end

function RollForLoot:RFLSetLootThreshold()
	RollForLoot:Print("Threshold: " .. RFLSettings["LootThreshold"]);
	SetLootThreshold(RFLSettings["LootThreshold"]);
	AutoSetLootMethodInProgress = false;
end

function RollForLoot:LootMethodChanged(eventname, arg1, ...)	
	if IsInRaid() and not(AutoSetLootMethodInProgress) then
		--Update Loot Method
		RFLSettings["LootMethod"] = GetLootMethod()

		--Update Loot Threshold
		RFLSettings["LootThreshold"] = GetLootThreshold();
		
		RollForLoot:Print("Loot Method and Threshold Set.");
	end
end

function RollForLoot:GetUnitName(unitID)

	local shortname, realm = UnitName(unitID)

	if realm == nil then
		realm = string.gsub(GetRealmName() , "%s", "");
	end

	local name = shortname .. "-" .. realm;
	
	return shortname, name; -- character name, charactername-realm;
		
end

function RollForLoot:refreshRaidRoster()
	--RollForLoot:Print(L["raidRefresh"]);
	--Clear Previous Roster
	RFLRaidRoster = {};

	if (IsInRaid() == true) then
		-- Update Raid Roster
		for i=1, GetNumGroupMembers() do
			local name, rank, subGroup, _, _, fileName, _, _, _, role, isML = GetRaidRosterInfo(i);
						
			--Create Roster Array
			RFLRaidRoster[i] = {};

			RFLRaidRoster[i]["name"] = name;
			RFLRaidRoster[i]["rank"] = rank;
			RFLRaidRoster[i]["subGroup"] = subGroup;
			RFLRaidRoster[i]["fileName"] = fileName;
			RFLRaidRoster[i]["role"] = role;
			RFLRaidRoster[i]["isML"] = isML;
		end
	
		-- Clear Player Raid Index. Player may have been moved.
		RollForLoot:clearPlayerRaidIndex();

		--RollForLoot:Print(L["raidRefresh_complete"]);
	--else
		--RollForLoot:Print(L["raidRefresh_failed_NotInRaid"]);
	end

end

function RollForLoot:printRaidRoster()
	RollForLoot:Print(L["printLootMethod"](RFLSettings["LootMethod"]))
	RollForLoot:Print(L["printLootThreshold"](RFLSettings["LootThreshold"]))
	
	RollForLoot:Print(L["printRoster"]);
	for i=1, GetNumGroupMembers() do
		RollForLoot:Print("Name: " .. RFLRaidRoster[i]["name"])
	end
end

function RollForLoot:isMasterLooter()
	--RollForLoot:Print("isMasterLooter");
	local isML;
	
	if RFLDEBUG == true then
		return true
	end
	
	if IsInRaid() then
		local index = RollForLoot:getPlayerRaidIndex("player")
		local _, _, _, _, _, _, _, _, _, _, bML = GetRaidRosterInfo(index);
		isML = bML;
	end
	
	if isML == nil then
		isML = false;
	end
	-- RollForLoot:Print("isML: " .. tostring(isML));
	return isML;
end

function RollForLoot:getRaidIndex(playerName)
	local raidIndex = 0;
	
	for i=1, table.maxn(RFLRaidRoster) do
		if (RFLRaidRoster[i]["name"] == playerName) then
			raidIndex = i;
			break;
		end
	end
	
	if raidIndex == 0 then -- I didn't find the player in the raid, this is odd, check crossrealm
		for j=1, table.maxn(RFLRaidRoster) do
			if ((string.find(playerName, RFLRaidRoster[j]["name"]) ~= nil) or (string.find(RFLRaidRoster[j]["name"], playerName) ~= nil)) then
				raidIndex = j;
				break;
			end
		end
	end
	return raidIndex;
end

function RollForLoot:getPlayerRaidIndex(unitID)
	if intPlayerRaidIndex == nil then
		local playername = UnitName(unitID)

		for i=1, table.maxn(RFLRaidRoster) do
			if (RFLRaidRoster[i]["name"] == playername) then
				intPlayerRaidIndex = i;
				break;
			end
		end
	end

	return intPlayerRaidIndex;
end

function RollForLoot:clearPlayerRaidIndex()
	intPlayerRaidIndex = nil;
end

function RollForLoot:RFL_Toggle()
	if (frmRFLMain:IsShown()) then
		RollForLoot:RFL_Hide();
	else
		RollForLoot:RFL_Show();
	end
end

function RollForLoot:MiniMapBtnClick(self, button, modifier)
	--RollForLoot:Print("Minimap Button Clicked: " .. tostring(modifier) .. "-" .. button);

	if button == "LeftButton" then
		if modifier then
			RollForLoot:Print(L['Title']);
			RollForLoot:Print(L['Description']);
			RollForLoot:Print(L['Loaded'](rlVersion));
		else
			RollForLoot:DisplayLootRoll(DisplayedRTID);
		end
	end
	
	if button == "RightButton" then
		if modifier then
			local dialog = StaticPopup_Show("RFL_CLEARLOOTHISTORY_CONFIRM")
		else
			RollForLoot:DisplaySettings();
		end
	end
end

function RollForLoot:DisplaySettings()
	-- Called Twice to work around a Blizzard Bug that opens the option window to the wrong panel the first time.
	InterfaceOptionsFrame_OpenToCategory(RollForLoot.panel);
	InterfaceOptionsFrame_OpenToCategory(RollForLoot.panel);
end

function RollForLoot:RFL_Hide()
	frmRFLMain:Hide();
	--RollForLoot:Print("Hide RFL Frame");
end

function RollForLoot:RFL_Show()
	frmRFLMain:Show();
	--RollForLoot:Print("Show RFL Frame");
end

function RollForLoot:BuildMainLootFrame()
	if(frmRFLMain == nil) then
		frmRFLMain = CreateFrame("Frame", "frmRFLMain", UIParent, "BasicFrameTemplate");
		
		-- Build Main Frame
		frmRFLMain:SetWidth(600)
		frmRFLMain:SetHeight(400)
		frmRFLMain:SetFrameStrata("High")
		frmRFLMain:SetPoint("CENTER",0,0)
		frmRFLMain:SetMovable(true)
		frmRFLMain:EnableMouse(true)
		frmRFLMain:RegisterForDrag("LeftButton")
		frmRFLMain:SetScript("OnDragStart", frmRFLMain.StartMoving)
		frmRFLMain:SetScript("OnDragStop", frmRFLMain.StopMovingOrSizing)

		local frmRFLMainTitleText = frmRFLMain:CreateFontString("$parentTitle", "Overlay", "GameFontNormal")
		frmRFLMainTitleText:SetText(L["Title"] .. " - " .. L["Description"])
		frmRFLMainTitleText:SetPoint("TOP", frmRFLMain, 0, -6)

		-- Add LootMaster Control buttons
		frmRFLMain_btnRequestRolls = CreateFrame("Button", "frmRFLMain_btnRequestRolls", frmRFLMain, "UIPanelButtonTemplate");
		frmRFLMain_btnRequestRolls:SetPoint("TOPLEFT" , 25, -30);
		frmRFLMain_btnRequestRolls:SetWidth(100);
		frmRFLMain_btnRequestRolls:SetText("Request Rolls");
		frmRFLMain_btnRequestRolls:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		frmRFLMain_btnRequestRolls:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		frmRFLMain_btnRequestRolls:SetScript("OnClick", function(self) RollForLoot:SubmitRollsRequest() end)
		
		if ( not (RollForLoot:isMasterLooter())) then
			frmRFLMain_btnRequestRolls:Disable();
		end
		
		-- Build Loot Scroll Frame
		local frmRFLScroll = CreateFrame("ScrollFrame", "frmRFLScroll", frmRFLMain, "UIPanelScrollFrameTemplate")
		frmRFLScroll:SetWidth(550)
		frmRFLScroll:SetHeight(frmRFLMain:GetHeight() - 80)
		frmRFLScroll:SetPoint("TOPRIGHT", -28, -75)
	end
end

function RollForLoot:AddLootItemFrame(i, texture, item, lootlink, quality, uniqueID)
	--RollForLoot:Print("BEGIN ADD LOOT ITEM FRAME")
	frmLootPanel = _G["frmLootPanel"]
	
	if(frmLootPanel == nil) then
		--RollForLoot:Print("Setup Loot Frame Background")
		RollForLoot:SetupLootFrameBackground()
	end

	frmLootItem_i = _G["frmLootItem" .. i]
	
	if (frmLootItem_i == nil) then
		--RollForLoot:Print("Create New Loot Frame")
		frmLootItem_i = CreateFrame("Frame", "frmLootItem" .. i, frmLootPanel, nil )

		frmLootItem_i:SetWidth(frmLootPanel:GetWidth() - 10)
		frmLootItem_i:SetHeight(iLootFrameHeight)
		frmLootItem_i:SetPoint("TOPLEFT", 5, (iLootFrameHeight * (i-1) * -1) - 5)

		frmLootItem_i:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = {left = 1, right = 1, top = 1, bottom = 1}}
		);
		
		frmRFLLootIcon_i = CreateFrame("Button", "frmRFLLootIcon" .. i, frmLootItem_i, "ItemButtonTemplate")
		frmRFLLootIcon_i:SetPoint("TOPLEFT", 10, -10)
		textureRFLLootIconName_i = frmRFLLootIcon_i:CreateTexture("textureRFLLootIconName" .. i, "ARTWORK" , nil, nil )
		textureRFLLootIconName_i:SetTexture("Interface\\QUESTFRAME\\UI-QuestItemNameFrame") 
		textureRFLLootIconName_i:SetSize(130, 62)
		textureRFLLootIconName_i:SetPoint("LEFT", 30, 0)
		fsRFLLootIconName_i = frmRFLLootIcon_i:CreateFontString("fsRFLLootIconName" .. i, "ARTWORK" , "GameFontNormal")
		fsRFLLootIconName_i:SetPoint("LEFT", frmRFLLootIcon_i, "RIGHT", 8, 0)
		fsRFLLootIconName_i:SetSize(93, 38)
		fsRFLLootIconName_i:SetJustifyH("LEFT")

		-- Add Main and Off Spec Labels
		MSLabel = frmLootItem_i:CreateFontString("$parentMainSpec", "ARTWORK", "GameFontNormalLarge");
		MSLabel:SetPoint("TOPLEFT" , 170, -10);
		MSLabel:SetText("Main Spec");

		OSLabel = frmLootItem_i:CreateFontString("$parentOffSpecSpec", "ARTWORK", "GameFontNormalLarge")
		OSLabel:SetPoint("TOPLEFT" , 335, -10);
		OSLabel:SetText("Off Spec");
		
		-- Add UniqueId Hidden FontString to support button clicks
		fsUIDLabel = frmLootItem_i:CreateFontString("fsRFLLootUID" .. i, "ARTWORK", "GameFontNormalLarge")
		fsUIDLabel:SetPoint("TOPRIGHT", frmLootItem_i, "TOPRIGHT" , 0, 0);
		fsUIDLabel:SetText("UNIQUEID");
		
		if (RFLDEBUG == true) then
			fsUIDLabel:SetAlpha(0.5);
		else
			fsUIDLabel:SetAlpha(0.0);
		end
		
		RFLLootItem_btnPass_i = CreateFrame("Button", "RFLLootItem_btnPass" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnPass_i:SetPoint("BOTTOMLEFT" , 10, 10);
		RFLLootItem_btnPass_i:SetWidth(75);
		RFLLootItem_btnPass_i:SetText("Pass");
		RFLLootItem_btnPass_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnPass_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnPass_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		RFLLootItem_btnGreed_i = CreateFrame("Button", "RFLLootItem_btnGreed" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnGreed_i:SetPoint("BOTTOMLEFT" , 85, 10);
		RFLLootItem_btnGreed_i:SetWidth(75);
		RFLLootItem_btnGreed_i:SetText("Greed");
		RFLLootItem_btnGreed_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnGreed_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnGreed_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		-- Main Spec Need Buttons		
		RFLLootItem_btnMajor_i = CreateFrame("Button", "RFLLootItem_btnMajor" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnMajor_i:SetPoint("TOPLEFT" , 170, -32);
		RFLLootItem_btnMajor_i:SetWidth(75);
		RFLLootItem_btnMajor_i:SetText("Major");
		RFLLootItem_btnMajor_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnMajor_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnMajor_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		RFLLootItem_btnBIS_i = CreateFrame("Button", "RFLLootItem_btnBIS" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnBIS_i:SetPoint("TOPLEFT" , 170, -54);
		RFLLootItem_btnBIS_i:SetWidth(75);
		RFLLootItem_btnBIS_i:SetText("BiS");
		RFLLootItem_btnBIS_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnBIS_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnBIS_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		RFLLootItem_btnMinor_i = CreateFrame("Button", "RFLLootItem_btnMinor" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnMinor_i:SetPoint("TOPLEFT" , 245, -32);
		RFLLootItem_btnMinor_i:SetWidth(75);
		RFLLootItem_btnMinor_i:SetText("Minor");
		RFLLootItem_btnMinor_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnMinor_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnMinor_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		RFLLootItem_btnTier_i = CreateFrame("Button", "RFLLootItem_btnTier" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnTier_i:SetPoint("TOPLEFT" , 245, -54);
		RFLLootItem_btnTier_i:SetWidth(75);
		RFLLootItem_btnTier_i:SetText("2pc / 4pc");
		RFLLootItem_btnTier_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnTier_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnTier_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		-- Off Spec Need Buttons
		RFLLootItem_btnOSMajor_i = CreateFrame("Button", "RFLLootItem_btnOSMajor" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnOSMajor_i:SetPoint("TOPLEFT" , 335, -32);
		RFLLootItem_btnOSMajor_i:SetWidth(75);
		RFLLootItem_btnOSMajor_i:SetText("Major");
		RFLLootItem_btnOSMajor_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnOSMajor_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnOSMajor_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		RFLLootItem_btnOSBIS_i = CreateFrame("Button", "RFLLootItem_btnOSBIS" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnOSBIS_i:SetPoint("TOPLEFT" , 335, -54);
		RFLLootItem_btnOSBIS_i:SetWidth(75);
		RFLLootItem_btnOSBIS_i:SetText("BiS");
		RFLLootItem_btnOSBIS_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnOSBIS_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnOSBIS_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		RFLLootItem_btnOSMinor_i = CreateFrame("Button", "RFLLootItem_btnOSMinor" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnOSMinor_i:SetPoint("TOPLEFT" , 410, -32);
		RFLLootItem_btnOSMinor_i:SetWidth(75);
		RFLLootItem_btnOSMinor_i:SetText("Minor");
		RFLLootItem_btnOSMinor_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnOSMinor_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnOSMinor_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

		RFLLootItem_btnOSTier_i = CreateFrame("Button", "RFLLootItem_btnOSTier" .. i, frmLootItem_i, "UIPanelButtonTemplate");
		RFLLootItem_btnOSTier_i:SetPoint("TOPLEFT" , 410, -54);
		RFLLootItem_btnOSTier_i:SetWidth(75);
		RFLLootItem_btnOSTier_i:SetText("2pc / 4pc");
		RFLLootItem_btnOSTier_i:SetScript("OnEnter", function(self) RollForLoot:ButtonMouseOverTooltip(self) end)
		RFLLootItem_btnOSTier_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
		RFLLootItem_btnOSTier_i:SetScript("OnClick", function(self) RollForLoot:SubmitLootRequest(self) end)

	else
		--RollForLoot:Print("Reuse Loot Frame")
		
		-- gather loot icon
		frmRFLLootIcon_i = _G["frmRFLLootIcon" .. i]
		fsRFLLootIconName_i = _G["fsRFLLootIconName" .. i]
		fsUIDLabel = _G["fsRFLLootUID" .. i]

--		-- gather buttons
--		RFLLootItem_btnPass_i = _G["RFLLootItem_btnPass" .. i]
--		RFLLootItem_btnGreed_i = _G["RFLLootItem_btnGreed" .. i]

--		-- Main Spec Buttons
--		RFLLootItem_btnMajor_i = _G["RFLLootItem_btnMajor" .. i]
--		RFLLootItem_btnBIS_i = _G[]
--		RFLLootItem_btnMinor_i = _G[]
--		RFLLootItem_btnTier_i = _G[]

--		-- Off Spec Buttons
--		RFLLootItem_btnOSMajor_i = _G["RFLLootItem_btnMajor" .. i]
--		RFLLootItem_btnOSBIS_i = _G[]
--		RFLLootItem_btnOSMinor_i = _G[]
--		RFLLootItem_btnOSTier_i = _G[]
	end

	frmRFLLootIcon_i.icon:SetTexture(texture);
	--local label = _G["frmRFLLootIcon" .. i .. "Text"]
	--label:SetText(item);

	-- Set font color of the item name to match the quality
	local redComponent, greenComponent, blueComponent = GetItemQualityColor(quality)
	fsRFLLootIconName_i:SetText(item);
	fsRFLLootIconName_i:SetTextColor(redComponent, greenComponent, blueComponent, 1)
	
	-- Set Unique ID
	fsUIDLabel:SetText(uniqueID);
		
	-- Store Hyperlink to loot for the tooltip to use
	lootItemHyperlinks[frmLootItem_i:GetName() .. "Link"] = lootlink
    frmRFLLootIcon_i:SetScript("OnEnter", function(self) RollForLoot:MouseOverTooltip(self) end)
	frmRFLLootIcon_i:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	frmRFLLootIcon_i:RegisterForClicks("RightButtonDown")
	frmRFLLootIcon_i:SetScript("OnClick", function(self) if IsControlKeyDown() then RollForLoot:TransmogDisplayItemLink(self) end end)
	
	frmLootPanel:SetHeight(100*i);
	frmLootItem_i:Show()
end

function RollForLoot:SetupLootFrameBackground()
	local frmLootPanel = CreateFrame("Frame", "frmLootPanel", nil, nil);
	frmLootPanel:SetWidth(frmRFLScroll:GetWidth());
	frmLootPanel:SetHeight(iLootFrameHeight + 5);
	frmLootPanel:SetBackdrop({bgFile = "",
			edgeFile = "",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = {left = 1, right = 1, top = 1, bottom = 1}}
		);
	
	frmRFLScroll:SetScrollChild(frmLootPanel);
end

function RollForLoot:ClearLootFrames()
	--RollForLoot:Print("Begin ClearLootFrames")
	if (frmLootPanel ~= nil) then
		local kids = { frmLootPanel:GetChildren() };

		for _, child in ipairs(kids) do
			if string.sub(child:GetName(), 0, -2) == "frmLootItem" then
				child:Hide()
			end
		end
	end
	--RollForLoot:Print("End ClearLootFrames")
end

function RollForLoot:MouseOverTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT");

	frmParent = self:GetParent()
	GameTooltip:SetHyperlink(lootItemHyperlinks[frmParent:GetName() .. "Link"])
end

function RollForLoot:TransmogDisplayItemLink(self)
	frmParent = self:GetParent()
	DressUpItemLink(lootItemHyperlinks[frmParent:GetName() .. "Link"])
end

function RollForLoot:ButtonMouseOverTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT");

	tooltipname = string.sub(self:GetName(), 0, -2)
	GameTooltip:SetText(L[tooltipname .. "Tooltip"]);
end

function RollForLoot:AddLootItem(index,LootMsg)
	if (not (RollForLoot:HasPreviousRoll(LootMsg["LootID"]))) then
		RollForLoot:AddLootItemHistory(LootMsg["Texture"], LootMsg["Item"], LootMsg["Hyperlink"], LootMsg["Quality"], LootMsg["Qty"], LootMsg["LootID"])
		RollForLoot:AddLootItemFrame(index, LootMsg["Texture"], LootMsg["Item"], LootMsg["Hyperlink"], LootMsg["Quality"], LootMsg["LootID"])
		return 1;
	else
		RollForLoot:Print(LootMsg["Hyperlink"] .. " has already been rolled on once.");
		return 0;
	end
end

function RollForLoot:HasPreviousRoll(lootID)
	local boolPrevRoll = true;
		
	if RFL_LootRollHistory == nil then
		return false;
	end
	
	if RFL_LootRollHistory[lootID] == nil then
		boolPrevRoll = false;
	elseif RFL_LootRollHistory[lootID]["RollType"] == nil then
		boolPrevRoll = false;
	elseif RFL_LootRollHistory[lootID]["RollType"] == "" then
		boolPrevRoll = false;	
	end
	
	return boolPrevRoll;
end

function RollForLoot:AddLootItemHistory(texture, item, lootLink, quality, qty, lootID)
	if RFL_LootRollHistory == nil then
		RFL_LootRollHistory ={}
	end
	
	if RFL_LootRollHistory[lootID] == nil then
		RFL_LootRollHistory[lootID] = {}
	end
	
--	RFL_LootRollHistory[lootID]["LootSlot"] = lootSlot;
	RFL_LootRollHistory[lootID]["Texture"] = texture;
	RFL_LootRollHistory[lootID]["Item"] = item;
	RFL_LootRollHistory[lootID]["Hyperlink"] = lootLink;
	RFL_LootRollHistory[lootID]["Quality"] = quality;
	RFL_LootRollHistory[lootID]["Qty"] = qty;
	RFL_LootRollHistory[lootID]["LootID"] = lootID;
	RFL_LootRollHistory[lootID]["RollSpec"] = "";
	RFL_LootRollHistory[lootID]["RollType"] = "";
	RFL_LootRollHistory[lootID]["Time"] = time();
end

function RollForLoot:ClearHistory()
	RFLLootRollIdxByIndex = nil;
	RFLLootRollIdxByValue = nil;
	RFLLootRolls = nil;
	RFL_LootRollHistory = {};
	RFL_AwardedLoot = {};
	DisplayedRTID = 1;
	
	RollForLoot:Print(L['RFL_LOOTHISTORYCLEARED']);
end

-- Request loot be rolled for
function RollForLoot:SubmitLootRequest(self)
	frmParent = self:GetParent();
	frmParent:Hide();
	
	local lootUI = _G["fsRFLLootUID" .. string.sub(frmParent:GetName(), -1)]:GetText();

	--RollForLoot:Print(string.sub(self:GetName(),0,strlen(self:GetName())-1));
	
	if (string.sub(self:GetName(),0,strlen(self:GetName())-1) == 'RFLLootItem_btnPass' or string.sub(self:GetName(),0,strlen(self:GetName())-1) == 'RFLLootItem_btnGreed') then
		RFL_LootRollHistory[lootUI]["RollSpec"] = "NA";
		RFL_LootRollHistory[lootUI]["RollType"] = self:GetText();
	elseif (string.sub(self:GetName(),16,17) == "OS") then
		RFL_LootRollHistory[lootUI]["RollSpec"] = "Off";
		RFL_LootRollHistory[lootUI]["RollType"] = self:GetText();
	else
		RFL_LootRollHistory[lootUI]["RollSpec"] = "Main";
		RFL_LootRollHistory[lootUI]["RollType"] = self:GetText();
	end
	
	local msgLootRequest = {};
	msgLootRequest["Type"] = "LootRollRequest";
	msgLootRequest["ID"] = lootUI;
	msgLootRequest["Body"] = RFL_LootRollHistory[lootUI];
	
	local one = libS:Serialize(msgLootRequest)
	local two = libC:CompressHuffman(one)
	local final = libCE:Encode(two)
	
	RollForLoot:SendCommMessage(ACECommPrefix, final, "RAID", nil, "NORMAL") -- Send Roll Request to the raid
	
	-- Hide Loot Window and Show roll windows
	displayedItems = displayedItems - 1;
	RollForLoot:Print("Displayed Items: " .. displayedItems);
	if displayedItems <= 0 then
		RollForLoot:RFL_Hide()
		RollForLoot:DisplayLootRoll(DisplayedRTID+1);
	end
end

-- Send Addon Message to the raid that will build roll ui and allow raid members to submit loot requests.
function RollForLoot:SubmitRollsRequest(msg)
	RollForLoot:Print("RollForLoot:SubmitRollsRequest");

	CurrentRollRequest = CurrentRollRequest + 1;

	--Serialize and compress the data
	local msgLootRequest = {};
	msgLootRequest["Type"] = "LootRequest";
	msgLootRequest["ID"] = CurrentRollRequest;
	msgLootRequest["Body"] = msg;

	local one = libS:Serialize(msgLootRequest)
	local two = libC:CompressHuffman(one)
	local final = libCE:Encode(two)

    RollForLoot:SendCommMessage(ACECommPrefix, final, "RAID", nil, "NORMAL")
	--RollForLoot:Print("RollForLoot:RollsRequestSent");
end

function RollForLoot:SubmitRollsResponse(LootID, RollResponse, LootQtyNo)
	local msgLootRequest = {};
	msgLootRequest["Type"] = "LootRollResponse";
	msgLootRequest["ID"] = LootID;
	msgLootRequest["Body"] = RollResponse;
	msgLootRequest["LootQtyNo"] = LootQtyNo;

	local one = libS:Serialize(msgLootRequest)
	local two = libC:CompressHuffman(one)
	local final = libCE:Encode(two)

    RollForLoot:SendCommMessage(ACECommPrefix, final, "RAID", nil, "NORMAL")
	--RollForLoot:Print("RollForLoot:RollsRequestSent");
end

function RollForLoot:SubmitLootAwardMessage(LootID, PlayerName, RollSpec)
	local msgLootRequest = {};
	msgLootRequest["Type"] = "LootRollAward";
	msgLootRequest["ID"] = LootID;
	msgLootRequest["Body"] = { ["Player"] = PlayerName, ["RollSpec"] = RollSpec};

	local one = libS:Serialize(msgLootRequest)
	local two = libC:CompressHuffman(one)
	local final = libCE:Encode(two)
	
	 RollForLoot:SendCommMessage(ACECommPrefix, final, "RAID", nil, "NORMAL");
	 --RollForLoot:Print("RollForLoot:LootRollAwardSent");
end

-- Receive and process addon message being sent from other players
function RollForLoot:OnCommReceived(prefix, data, distribution, sender)
	--RollForLoot:Print("RollForLoot:CommReceived");
	--RollForLoot:Print("Prefix: " .. prefix);

	-- Decode the compressed data
	local one = libCE:Decode(data)

	--Decompress the decoded data
	local two, message = libC:Decompress(one)
	if(not two) then
		print("YourAddon: error decompressing: " .. message)
		return
	end

	-- Deserialize the decompressed data
	local success, final = libS:Deserialize(two)
	if (not success) then
		print("YourAddon: error deserializing " .. final)
		return
	end

	if (final["Type"] == "Debug") then
		--RollForLoot:Print("Debug Received");
	elseif (final["Type"] == "LootRequest") then
		RollForLoot:Print("Loot Request Received");
		
		--Build Loot Roll Window if you arn't the master looter
		if IsInRaid() then
			if (not (RollForLoot:isMasterLooter())) then
				displayedItems = 0;
				
				--RollForLoot:Print("Show Main Loot Frame");
				RollForLoot:BuildMainLootFrame();
			
				--clear loot frames
				RollForLoot:ClearLootFrames();

				--RollForLoot:Print(type(final["Body"]));
				local index = 0;
				for _, lootItem in pairs(final["Body"]) do
					RollForLoot:Print("Loot Item Type: " .. type(lootItem) .. " Loot Item Name: " .. lootItem["Item"]);
					index = index + 1;
--					lootslot = final["Body"][index]["LootSlot"];
--					corpseGUID = final["Body"][index]["CorpseGUID"];
--					texture = final["Body"][index]["Texture"];
--					item = final["Body"][index]["Item"];
--					lootlink = final["Body"][index]["Hyperlink"];
--					quality = final["Body"][index]["Quality"];
--					uniqueID = final["Body"][index]["LootID"]
					
					--RollForLoot:Print("Found Valid LootLink: " .. lootlink)
					--RollForLoot:Print("With a Unique ID of: " .. final["Body"][index]["LootID"])

					local addVal = RollForLoot:AddLootItem(index, lootItem)
					displayedItems = displayedItems + addVal;
				end
				
				if displayedItems > 0 then
					RollForLoot:RFL_Show();
				end
			end
		end
	elseif (final["Type"] == "LootRollRequest") then
		if RollForLoot:isMasterLooter() then
			--RollForLoot:Print("LootRollRequest Sender: "  .. sender);
			for i=1, final["Body"]["Qty"] do
				local msgRollResponse = RollForLoot:CalculateLootRoll(final["Body"], sender)
				RollForLoot:SubmitRollsResponse(final["ID"], msgRollResponse, i)
			end
		end
	elseif (final["Type"] == "LootRollResponse") then
		--RollForLoot:Print("Loot Roll Received!");
		RollForLoot:AddLootRoll(final["ID"], final["Body"], final["LootQtyNo"]);
	elseif (final["Type"] == "LootRollAward") then
		RollForLoot:UpdateLootAwards(lootID, playername, rollspec)
	else
		RollForLoot:Print("Unreconized Message: " .. final["Type"]);
	end
	--RollForLoot:Print("Distribution: " .. distribution);
	--RollForLoot:Print("Sender: " .. sender);
end