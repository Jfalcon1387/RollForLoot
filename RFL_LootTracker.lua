local frmRFL_LootTracker = nil;
local rflLootTrackerRefreshTime = 2;

function RollForLoot:BuildLootTrackerFrame()
	if(frmRFL_LootTracker == nil) then
		frmRFL_LootTracker = CreateFrame("Frame", "frmRFL_LootTracker", UIParent, "BasicFrameTemplate");

		-- Build Loot Tracker Frame
		frmRFL_LootTracker:SetWidth(400);
		frmRFL_LootTracker:SetHeight(550);
		frmRFL_LootTracker:SetFrameStrata("DIALOG");
		frmRFL_LootTracker:SetPoint("CENTER",0,0)
		frmRFL_LootTracker:SetMovable(true)
		frmRFL_LootTracker:EnableMouse(true)
		frmRFL_LootTracker:RegisterForDrag("LeftButton")
		frmRFL_LootTracker:SetScript("OnDragStart", frmRFL_LootTracker.StartMoving)
		frmRFL_LootTracker:SetScript("OnDragStop", frmRFL_LootTracker.StopMovingOrSizing)
		frmRFL_LootTracker:SetScript("OnUpdate", function(self, elapsed) RollForLoot:RefreshLootTracker(self,elapsed) end)
		
		-- Build Loot Tracker Title
		local frmRFL_LTTitleText = frmRFL_LootTracker:CreateFontString("$parentTitle", "Overlay", "GameFontNormal")
		frmRFL_LTTitleText:SetText("Roll For Loot: Loot Tracker")
		frmRFL_LTTitleText:SetPoint("TOP", frmRFL_LootTracker, 0, -6)
		
		-- Build seperator frame
		local frmRFL_LTSeperatorTexture = frmRFL_LootTracker:CreateTexture("textureRFLLootSeperator", "ARTWORK" , nil, nil )
		textureRFLLootSeperator:SetTexture("Interface\\AddOns\\RollForLoot\\Media\\seperator") 
		textureRFLLootSeperator:SetSize(frmRFL_LootTracker:GetWidth()-6, 50)
		textureRFLLootSeperator:SetPoint("CENTER", frmRFL_LootTracker, "CENTER", 0, 0)
		
		-- Build Raid Player Background
		
		-- Build Assigned Loot Background
	end
	
	frmRFL_LootTracker:Hide();
end

function RollForLoot:DisplayLoot()
	if frmRFL_LootTracker == nil then
		RollForLoot:BuildLootTrackerFrame();
	end
	
	frmRFL_LootTracker:Show();
end

function RollForLoot:RefreshLootTracker(self,elapsed)
    rflLootTrackerRefreshTime = rflLootTrackerRefreshTime + elapsed;
    if rflLootTrackerRefreshTime >= 2 then
        if frmRFL_LootTracker:IsShown() then
			RollForLoot:DisplayLoot()
		end
		RollTrackerRefreshTime = 0
    end
end

