-- Author      : jfalcon
-- Create Date : 8/19/2014 8:59:05 PM

local L = LibStub("AceLocale-3.0"):NewLocale("RollForLoot", "enUS", true)

if L then
	L["Title"] = "Roll For Loot"
	L["Description"] = "A Tiered Base Raid Loot Management Addon for World of Warcraft"
	L["Disabled"] = "Roll For Loot has been disabled."
	L["Loaded"] = function(x) return "Roll For Loot v" .. x .. " Loaded" end
	L["Version"] = function(x) return "Roll For Loot v" .. x end
	L["raidRefresh"] = "Refreshing Raid Roster ..."
	L["printRoster"] = "Printing Raid Roster ..."
	L["printLootMethod"] = function(x) return "Raid Loot Method is " .. x .. "." end
	L["printLootThreshold"] = function(x) return "Raid Loot Threshold is " .. x .. "." end
	L["WoWClientID"] = "WoW"
	L["raidRefresh_complete"] = "Raid Roster refresh completed."
	L["raidRefresh_failed_NotInRaid"] = "Raid Roster refresh failed. You are not in a raid group."
	L["RFLLootItem_btnPassTooltip"] = "Pass on this loot item"
	L["RFLLootItem_btnGreedTooltip"] = "Greed this loot item"
	L["RFLLootItem_btnMajorTooltip"] = "Major upgrade for your Main Spec"
	L["RFLLootItem_btnMinorTooltip"] = "Minor upgrade for your Main Spec"
	L["RFLLootItem_btnBISTooltip"] = "Best in slot upgrade for your Main Spec"
	L["RFLLootItem_btnTierTooltip"] = "Tier Piece will give you a 2pc or 4pc bonus for your Main Spec"
	L["RFLLootItem_btnOSMajorTooltip"] = "Major upgrade for your Off Spec"
	L["RFLLootItem_btnOSMinorTooltip"] = "Minor upgrade for your Off Spec"
	L["RFLLootItem_btnOSBISTooltip"] = "Best in slot upgrade for your Off Spec"
	L["RFLLootItem_btnOSTierTooltip"] = "Tier Piece will give you a 2pc or 4pc bonus for your Off Spec"
	L["frmRFLMain_btnRequestRollTooltip"] = "Request Rolls for loot items from the raid team"
	L["RFLLootRoll_btnPreTooltip"] = "Move to the previous loot roll"
	L["RFLLootRoll_btnNexTooltip"] = "Move to the next loot roll"
	L['RFL_LOOTHISTORYCLEAR_CONFIRM'] = "Roll For Loot: Do you want to clear your loot roll history?"
	L['RFL_LOOTHISTORYCLEARED'] = "Loot history cleared."
	L['RFL_MiniMapUsage'] = "Left Click - Show Roll Window\nRight Click - View Settings\nCtrl-Left Click - Display Version Info\nCtrl-Right Click - Clear Loot History"
	L["Usage"] = [[
 
  Usage:
  
  /RollForLoot <command>  or  /rfl <command> or  /RFL <command>
  
  Commands:
  
  Help 
        -- Print this message.
  Version
        -- Print the add-on version.
  RefreshRoster
        -- Forces a refresh of the raid's roster. This may help if you having problems distributing loot.
  ToggleUI
        -- Toggles Roll For Loot's UI to show or hide.
  HideUI
        -- Forces Roll For Loot's UI to hide.
  ShowUI
        -- Forces Roll For Loot's UI to show.
  ShowRoll
        -- Displays the Roll Tracker UI Windows.
  Clear
        -- Forces a clear of loot and roll history.
  Settings
        -- Displays the Roll For Loot settings page.

]];
end