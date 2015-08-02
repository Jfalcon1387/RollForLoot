-- Comm Variables
local ACECommPrefix = "RollForLoot"
local libS = LibStub:GetLibrary("AceSerializer-3.0")
local libC = LibStub:GetLibrary("LibCompress")
local libCE = libC:GetAddonEncodeTable()

local CurrentRollRequest = 0;

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
	
	CurrentRollRequest = CurrentRollRequest + 1;
	
	local msgLootRequest = {};
	msgLootRequest["Type"] = "LootRollRequest";
	msgLootRequest["ID"] = lootUI;
	msgLootRequest["Body"] = RFL_LootRollHistory[lootUI];
	
	local one = libS:Serialize(msgLootRequest)
	local two = libC:CompressHuffman(one)
	local final = libCE:Encode(two)
	
	RollForLoot:SendCommMessage(ACECommPrefix, final, "RAID", nil, "NORMAL") -- Send Roll Request to the raid
	
	-- Hide Loot Window and Show roll windows
	displayedItems = displayedItems -1;
	RollForLoot:Print("Displayed Items: " .. displayedItems);
	if displayedItems <= 0 then
		RollForLoot:RFL_Hide()
		RollForLoot:DisplayLootRoll(DisplayedRTID+1);
	end
end

-- Send Addon Message to the raid that will build roll ui and allow raid members to submit loot requests.
function RollForLoot:SubmitRollsRequest()
	--RollForLoot:Print("RollForLoot:SubmitRollsRequest");

	CurrentRollRequest = CurrentRollRequest + 1;

	--Serialize and compress the data
	local msgLootRequest = {};
	msgLootRequest["Type"] = "LootRequest";
	msgLootRequest["ID"] = CurrentRollRequest;
	msgLootRequest["Body"] = LootMsgBody;

	local one = libS:Serialize(msgLootRequest)
	local two = libC:CompressHuffman(one)
	local final = libCE:Encode(two)


    RollForLoot:SendCommMessage(ACECommPrefix, final, "RAID", nil, "NORMAL")
	--RollForLoot:Print("RollForLoot:RollsRequestSent");
	
	LootMsgBody = nil;
end

function RollForLoot:SubmitRollsResponse(LootID, RollResponse)
	local msgLootRequest = {};
	msgLootRequest["Type"] = "LootRollResponse";
	msgLootRequest["ID"] = LootID;
	msgLootRequest["Body"] = RollResponse;

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
		--RollForLoot:Print("Loot Request Received");
		
		--Build Loot Roll Window if you arn't the master looter
		if IsInRaid() then
			if (not (RollForLoot:isMasterLooter())) then
				displayedItems = 0;
				
				--RollForLoot:Print("Show Main Loot Frame");
				RollForLoot:BuildMainLootFrame();
			
				--clear loot frames
				RollForLoot:ClearLootFrames();

				--RollForLoot:Print(type(final["Body"]));
				
				for index, lootItem in pairs(final["Body"]) do
					--RollForLoot:Print("Loot Item Type: " .. type(lootItem) .. " Loot Item Name: " .. lootItem["Item"]);
					
					lootslot = final["Body"][index]["LootSlot"];
					corpseGUID = final["Body"][index]["CorpseGUID"];
					texture = final["Body"][index]["Texture"];
					item = final["Body"][index]["Item"];
					lootlink = final["Body"][index]["Hyperlink"];
					quality = final["Body"][index]["Quality"];
					uniqueID = final["Body"][index]["LootID"]
					
					--RollForLoot:Print("Found Valid LootLink: " .. lootlink)
					--RollForLoot:Print("With a Unique ID of: " .. final["Body"][index]["LootID"])

					local addVal = RollForLoot:AddLootItem(index, final["Body"][index])
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
			local msgRollResponse = RollForLoot:CalculateLootRoll(final["Body"], sender)
			RollForLoot:SubmitRollsResponse(final["ID"], msgRollResponse)
		end
	elseif (final["Type"] == "LootRollResponse") then
		--RollForLoot:Print("Loot Roll Received!");
		RollForLoot:AddLootRoll(final["ID"], final["Body"]);
	elseif (final["Type"] == "LootRollAward") then
		RollForLoot:UpdateLootAwards(lootID, playername, rollspec)
	else
		RollForLoot:Print("Unreconized Message: " .. final["Type"]);
	end
	--RollForLoot:Print("Distribution: " .. distribution);
	--RollForLoot:Print("Sender: " .. sender);
end